#!usr/bin/perl;
package ExceptionLog;
use strict;
use warnings;
use DBI;
use MIME::Lite;
use XML::Simple;
use Data::Dumper;
use Switch;
use Sys::Hostname;
use Socket;
use Exporter;
#Global variables
our ($DBtype,$user,$pwd,$filepath,$txtfile,$xmlfile,$jsonfile,$mailFrom,$mailTo,$smtp,$emailuser,$emailpwd);
our $configFile = "ErrorLogConfig.xml";
our $host = hostname();
our $ip = inet_ntoa(scalar(gethostbyname($host)) || 'localhost');
our @ISA = qw(Exporter);
our @EXPORT = qw(logError);
#Constructor
sub new
{
    my $class = shift;
	
    my $self = { 
		_errorString  => shift,
		_logType => shift,
       };
    bless $self, $class;
    return $self;
}

#Methods
sub createLogDirectory
{
	
	my $dirpath = $filepath;
	if(!(-d $dirpath))
	{	
		mkdir ($dirpath) or warn "Error occured in creating Directory:$!";	
	}
	
}
sub readConfig
{
	my $xml = new XML::Simple;
	my $data = $xml->XMLin($configFile);
	#DB variables
	$DBtype = $data->{Database}{DBtype};
	$user = $data->{Database}{User};
	$pwd = $data->{Database}{Password};
	#File variables
	$filepath = $data->{LogFiles}{FilePath};
	$txtfile = $data->{LogFiles}{TEXTFile};
	$xmlfile = $data->{LogFiles}{XMLFile};
	$jsonfile = $data->{LogFiles}{JSONFile};
	#Mail variables
	$mailFrom = $data->{Email}{FROM};
	$mailTo = $data->{Email}{TO};
	$smtp = $data->{Email}{SMTP};
	$emailuser = $data->{Email}{USER};
	$emailpwd = $data->{Email}{PASSWORD};
}
sub logError
{
    my ($errorString,$logTypeString) = @_;
	#my($self) = @_;
	readConfig();
	createLogDirectory();
	my @logArray = split(',',$logTypeString);
	my $argCount = @logArray;
	for( my $i = 0; $i < $argCount; $i++)
	{
		if($logArray[$i] eq '1')
		{
		$i = $i + 0;
		switch($i)
		{
		
		     case 0
		     {		
				#print "$self->{_errorString}";
				print "$errorString";
			 }
		     case 1
			 {  
				logIntoFile($errorString);
				
			 }
			 case 2
			 { 
				logIntoDB($errorString);
			 }
			 case 3
			 {  
				logThroughMail($errorString);
			 }
			 case 4
			 {  
				logIntoXML($errorString);
			 }
			 case 5
			 {  
				logIntoJSON($errorString);
			 }
		}
		}

	}
}

sub logIntoFile
{
	
	my $filename =$filepath .''.$txtfile;
	my $dateTime = gmtime();
	my @errorArray = split ('eval',$_[0]);
	my $error = $errorArray[0];
	
	if (-e $filename) 
	{ 
		open(my $fh, '>>', "$filename") or warn "$!";
		print $fh "\n" .''.$error .''. $dateTime.''.$host.''.$ip;
		close $fh;
	}
	else
	{
		open(my $fh, '>', "$filename") or warn "$!";
		print $fh $error .''. $dateTime.''.$host.''.$ip;
		close $fh;
	}
	
}
sub logIntoDB
{
	readConfig();
	my $dbh = DBI->connect($DBtype,$user,$pwd) or warn "Message: $!";	
	my $sth = $dbh->prepare(qq{INSERT INTO errorlog (ERRORDESC,HostName,IPAddress) VALUES (?,?,?)});
    $sth->execute($_[0],$host,$ip) or warn "Mes:$!";
	print 'Writed to DB';
	
}

sub logIntoXML
{
	print('hi in xml');
    my $filename =$filepath .''. $xmlfile;
	my $dateTime = gmtime();
	my @errorArray = split ('eval',$_[0]);
	my $error = $errorArray[0];
	if (-e $filename) 
	{ 
		removeLastLineOfFile($filename);
		open(my $fh, '>>', "$filename") or warn "Error occured during logging into XML:$!"; 
		writingToXML($fh,$error,$dateTime,$host,$ip);
		close $fh;
	}
	else
	{
		#firstime
		open(my $fh, '>', "$filename") or warn "Error occured during logging into XML:$!"; 
		print $fh "<ErrorLog>";
		writingToXML($fh,$error,$dateTime,$host,$ip);
		close $fh;
	}	
}
sub writingToXML
{ 
        my $fh = $_[0];
		my $error = $_[1];
		my $dateTime = $_[2];
		my $hostname = $_[3];
		my $ipaddress = $_[4];
		
		print $fh "\n" .''. "<Error>";
		print $fh "\n" .''. "    <![CDATA[ " .''. "<Desc>" .''.$error .''. "    </Desc>" .''. "]]>";
		print $fh "\n" .''. "    <Date>" .''.$dateTime .''. "</Date>";
		print $fh "\n" .''. "    <Host>" .''.$hostname .''. "</Host>";
		print $fh "\n" .''. "    <IP>" .''.$ipaddress .''. "</IP>";
		print $fh "\n" .''. "</Error>".''. "\n";
		print $fh "</ErrorLog>";
}


#Pass fh here
sub removeLastLineOfFile
{
	   readConfig();
       my $filename = $_[0];
       open (FH, "+<", $filename) or warn "can't update $filename: $!";
	   my $addr = '';
       while (<FH>) {
           $addr = tell(FH) unless eof(FH);
       }
       truncate(FH, $addr) 

}

sub logIntoJSON
{
=begin
	readConfig();
	logIntoXML($_[0]);
    my $booklist = XMLin($xmlfile);
    #print Dumper($booklist);

	my $filename = $jsonfile;
	if (-e $filename) 
	{ 
		
		open(my $fh, '>>', "$filename") or warn "Error occured during logging into XML:$!"; 
		print $fh Dumper($booklist);
		close $fh;
	}
	else
	{
		#firstime
		open(my $fh, '>', "$filename") or warn "Error occured during logging into XML:$!"; 
		print $fh Dumper($booklist);
		close $fh;
		
	}	
=cut

	readConfig();
    my $filename = $filepath .''.$jsonfile;
	my $dateTime = gmtime();
	my @errorArray = split ('eval',$_[0]);
	my $error = $errorArray[0];
	if (-e $filename) 
	{ 
		removeLastLineOfFile($filename);
		open(my $fh, '>>', "$filename") or warn "Error occured during logging into XML:$!"; 
		writingToJSON($fh,$error,$dateTime,$host,$ip);
		close $fh;
	}
	else
	{
		#firstime
		open(my $fh, '>', "$filename") or warn "Error occured during logging into XML:$!"; 
		print $fh "{".''."\"ErrorLog\"".''.":[";
		writingToJSON($fh,$error,$dateTime,$host,$ip);
		close $fh;
	}

}
sub writingToJSON
{
=begin
	{"employees":[
    {"firstName":"John", 
	 "lastName":"Doe"
	 },
    
]}


=cut
		my $fh = $_[0];
		my $error = $_[1];
		my $dateTime = $_[2];
		my $hostname = $_[3];
		my $ipaddress = $_[4];
		chomp($error);
		print $fh "\n" .''. "     {";
		print $fh "\n" .''. "     		\"Desc\"".''.":".''."\"".''.$error .''."\"".''.",";
		print $fh "\n" .''. "     		\"Date\"".''.":".''."\"".''.$dateTime .''."\"".''.",";
		print $fh "\n" .''. "     		\"HostName\"".''.":".''."\"".''.$hostname .''."\"".''.",";
		print $fh "\n" .''. "     		\"IpAddress\"".''.":".''."\"".''.$ipaddress .''."\"";
		print $fh "\n" .''. "     },";
		print $fh "\n" .''. "]}";
}

sub logThroughMail
{
	readConfig();
	my @errorArray = split ('eval',$_[0]);
	my $error = $errorArray[0];
	my $dateTime = localtime();	
	my $from = $mailFrom;  
	my $to = $mailTo;  
    my $subject = "Error!!";
	my $content = "$error,$_[0],$dateTime,$host,$ip";
    my $msg = MIME::Lite->new(  
    From     => $from, 
    To       => $to,  
    Subject  => $subject,  
    Data     => $content,
    
    );
    eval { 
    $msg->send('smtp', "$smtp", AuthUser=>$emailuser, AuthPass=>$emailpwd);
	print "email sent!!";
    };
    warn "Error sending email: $@" if ($@);
}
1;

