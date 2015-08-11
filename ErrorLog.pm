#!usr/bin/perl;
package ExceptionLog;
use strict;
use warnings;
use DBI;
use MIME::Lite;
use XML::Simple;
use Data::Dumper;
use Switch;
our ($DBtype,$user,$pwd,$filepath,$txtfile,$xmlfile,$jsonfile);
our $configFile = "ErrorLogConfig.xml";
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


sub readConfig
{
	my $xml = new XML::Simple;
	my $data = $xml->XMLin($configFile);
	#our $root = $data->{Database}[0]{Name};
	$DBtype = $data->{Database}[0]{DBType};
	$user = $data->{Database}[0]{User};
	$pwd = $data->{Database}[0]{Password};
	$filepath = $data->{Database}[0]{FilePath};
	$txtfile = $data->{Database}[0]{TEXTFile};
	$xmlfile = $data->{Database}[0]{XMLFile};
	$jsonfile = $data->{Database}[0]{JSONFile};
}
sub logError
{
	my($self) = @_;
	my @logArray = split(',',$self->{_logType});
	my $argCount = @logArray;
	for( my $i = 0; $i < $argCount; $i++)
	{
		if($logArray[$i] eq '1')
		{
		$i = $i + 0;
		#print(@logArray);
		switch($i)
		{
		
		     case 0
		     {		
				print "$self->{_errorString}";
			 }
		     case 1
			 {  
				logIntoFile($self->{_errorString});
				
			 }
			 case 2
			 { 
				logIntoDB($self->{_errorString});
				print'hi';
			 }
			 case 3
			 {  
				logThroughMail($self->{_errorString});
			 }
			 case 4
			 {  
				logIntoXML($self->{_errorString});
			 }
			 case 5
			 {  
				logIntoJSON($self->{_errorString});
			 }
		}
		}

	}
}

sub logIntoFile
{
	readConfig();
	my $filename =$txtfile;
	my $dateTime = gmtime();
	my @errorArray = split ('eval',$_[0]);
	my $error = $errorArray[0];
	if (-e $filename) 
	{ 
		open(my $fh, '>>', "$filename") or die "$!";
		print $fh "\n" .''.$error .''. $dateTime;
		close $fh;
	}
	else
	{
		open(my $fh, '>', "$filename") or die "$!";
		print $fh $error .''. $dateTime;
		close $fh;
	}
}
sub logIntoDB
{
	readConfig();
	my $dbh = DBI->connect($DBtype,$user,$pwd) or die "Message: $!";	
	my $errorId = $dbh->prepare("SELECT MAX(idERRORLOG) FROM errorlog");
	$errorId->execute();
	$errorId = $errorId + 1;
	my $sth = $dbh->prepare(qq{INSERT INTO errorlog (idERRORLOG,ERRORDESC) VALUES (?,?)});
    $sth->execute($errorId,$_[0]) or die "Mes:$!";
	print 'Writed to DB';
	
}

sub logIntoXML
{
	readConfig();
    my $filename = $xmlfile;
	my $dateTime = gmtime();
	my @errorArray = split ('eval',$_[0]);
	my $error = $errorArray[0];
	if (-e $filename) 
	{ 
		removeLastLineOfFile();
		open(my $fh, '>>', "$filename") or die "$!";
		print $fh "\n" .''. "<Error>";
		print $fh "\n" .''. "    <![CDATA[ " .''. "<Desc>" .''.$error .''. "    </Desc>" .''. "]]>";
		print $fh "\n" .''. "    <Date>" .''.$dateTime .''. "</Date>";
		print $fh "\n" .''. "</Error>".''. "\n";
		print $fh "</ErrorLog>";
		
		close $fh;
	}
	else
	{
		#firstime
		open(my $fh, '>', "$filename") or die "$!";
		print $fh "<ErrorLog>";
		print $fh "\n" .''. "<Error>";
		print $fh "\n" .''. "    <![CDATA[" .''. "<Desc>" .''.$error .''. "     </Desc>" .''. "]]>";
		print $fh "\n" .''. "    <Date>" .''.$dateTime .''. "</Date>";
		print $fh "\n" .''. "</Error>" .''. "\n";
		print $fh "</ErrorLog>";
		close $fh;
	}	
}
sub removeLastLineOfFile
{
	readConfig();
       my $filename = $xmlfile;
       open (FH, "+<", $filename) or die "can't update $filename: $!";
	   my $addr = '';
       while (<FH>) {
           $addr = tell(FH) unless eof(FH);
       }
       truncate(FH, $addr) 

}

sub logIntoJSON
{
	readConfig();
	logIntoXML($_[0]);
    my $booklist = XMLin($xmlfile);
    #print Dumper($booklist);

	my $filename = $jsonfile;
	if (-e $filename) 
	{ 
		
		open(my $fh, '>>', "$filename") or die "$!";
		print $fh Dumper($booklist);
		close $fh;
	}
	else
	{
		#firstime
		open(my $fh, '>', "$filename") or die "$!";
		print $fh Dumper($booklist);
		close $fh;
		
	}	

}

sub logThroughMail
{
	my @errorArray = split ('eval',$_[0]);
	my $error = $errorArray[0];
	my $dateTime = localtime();	
	my $from = 'harini.b@smnetserv.com';  
	my $to = 'harini611996@gmail.com';  
    my $subject = "Error!!";
	my $content = "$error,$_[0],$dateTime";
    my $msg = MIME::Lite->new(  
    From     => $from, 
    To       => $to,  
    Subject  => $subject,  
    Data     => $content,
    
    );
    eval { 
    $msg->send('smtp', "ns11.interactivedns.com", AuthUser=>'harini.b@smnetserv.com', AuthPass=>'harini@2015');
	print "email sent!!";
    };
    die "Error sending email: $@" if ($@);
}
1;

