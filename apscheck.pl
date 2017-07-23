#!/usr/local/bin/perl

# Tool to check patch level in apscheck.txt,
# Can find out dependent checkins as well
# 2013/06/08
# yanhan.tang@oracle.com

use strict;
use DBI;
use Env;
use Time::Local;
##############  Global Variables  ########################

our @latestFileInfo; # 0-fileName, 1-RCS version
our @recentFileInfo; # 2D: 0-fileName, 1-RCS version
our $latestPatchNumber;
##########################################################

&usage unless ( $#ARGV eq 0 );

BEGIN {
$ENV{'ORACLE_HOME'} =  '/local/db/8.0.6' ;
}

# prepare ARU DB connection
our $aruDesc = "(DESCRIPTION =(LOAD_BALANCE=off)(FAILOVER=on)(ADDRESS_LIST=(ADDRESS = (PROTOCOL = TCP)(HOST = aarudbp03-vip.us.oracle.com)(PORT = 1551)))(ADDRESS_LIST=(ADDRESS= (PROTOCOL = TCP)(HOST = aarudbp02-vip.us.oracle.com)(PORT = 1551)))(CONNECT_DATA = (SERVER= DEDICATED)(SERVICE_NAME= RURO_APPS.US.ORACLE.COM)))";
our $dataSrc = "dbi:Oracle:$aruDesc"; #@arudb.us.oracle.com:1521' ;
our $dbConnection = DBI->connect($dataSrc,'nevertellyou','nevertellyou`') or die "Connection Error: $DBI::errstr\n";
&findFreshFile( $ARGV[0] );
print "Patch number found in $ARGV[0]: $latestPatchNumber\n";
&getPatchInfo( $latestPatchNumber );
print "Latest file version: $latestFileInfo[0] version= $latestFileInfo[1]\n";

my $recentFileCnt = $#recentFileInfo + 1;
print "Collected $recentFileCnt files checked in within two hours\n";
my %latestCheckinMap = &findAvlPatch( $latestFileInfo[0], $latestFileInfo[1] );
# my %checkinMap;
# my %lastCheckinMap;
# foreach( my $i =0; $i < $recentFileCnt; $i++ )
# {
	# my %avlCheckins = &findAvlPatch( $recentFileInfo[$i][0], $recentFileInfo[$i][1] );
	# my $matchCnt = 0;
	# foreach my $checkin ( keys %latestCheckinMap )
	# {
		# next unless ( defined $latestCheckinMap{$checkin} );
		# if( not exists $avlCheckins{ $checkin } )
		# {
			# undef $latestCheckinMap{ $checkin };
		# }
	# }
# }

print "\nEngine Checkin found according to latest file:\n";
my $patchCnt = 0;
foreach my $checkin ( keys %latestCheckinMap )
{
	next unless ( defined $latestCheckinMap{ $checkin } );
	my $record  = $latestCheckinMap{ $checkin };
	print "Checkin:$checkin\n\tAbstract:$record->[0]\n\tRelease Date:$record->[1]\n";
	my $includeCnt = &includeCount( $record->[2] );
	print "\tIncluded by $includeCnt checkins";
	print "\tMaybe this is not a real top patch" unless ( $includeCnt == 0 );
	print "\n";
	$patchCnt ++;
	if( $patchCnt > 5 ) {
		print "#Too many patches found, skip\n";
		last;
	}
}

######################################
# Functions
######################################

sub usage
{
	print <<END;
Usage: apscheck.pl apscheck.txt
by <yanhan.tang\@oracle.com>
END
	exit 0;
}

# brief: get full patch name and other info of a patch
# param0: patch number
# return: 0-bugfix_name 1-abstract 2-released_date 3- bugfix_id
sub getPatchInfo
{
	my $patchNumber = $_[0];
	
	my $sql =<<END_SQL;
	SELECT
		distinct 
		ab.bugfix_id,
		ab.bugfix_name,
		ab.abstract,
		ab.released_date
	FROM aru_bugfixes ab
	WHERE
		ab.bugfix_name like '$patchNumber%'
	AND ab.released_date IS NOT NULL
END_SQL
	my $dbExec = $dbConnection->prepare($sql);
	$dbExec->execute or die "SQL Error: $DBI::errstr\n";
	my $patchCnt = 0;
	print "Patch Info:\n";
	while (my @row = $dbExec->fetchrow_array) {
	   print "$row[1]\n\t$row[2]\n\tReleaseDate:$row[3]\n";
	   ++$patchCnt;
	   if( $patchCnt > 1 ) {
			print "More than 1 similar patches found, skip display\n";
			last;
		}
	}
	
	print "Warning: There's not relevant checkin!\n" if( not $patchCnt );
}

# brief: find all patches related to this 
# return: { bugfix_name => [abstract released_date]}
sub findAvlPatch
{
	my $fileName = $_[0];
	my $fileVersion = $_[1];
	
	my %avlCheckins;
	my $sql =<<END_SQL;
	SELECT  
			distinct ab.bugfix_id,
			ab.bugfix_name,
			ab.abstract,
			ab.released_date,
			ab.release_id,
			ab.product_id
	FROM	aru_objects ao,
			aru_bugfixes ab,
			aru_product_releases apr,
			aru_products ap,
			aru_bugfix_object_versions abov,
			aru_object_versions aov
	WHERE
			ao.object_name like '$fileName%'
		AND	ab.released_date IS NOT NULL
		AND ab.product_id = 724
		AND	abov.bugfix_id=ab.bugfix_id 
	    AND abov.object_id=ao.object_id
		AND ao.product_release_id=apr.product_release_id
		AND apr.product_id=ap.product_id
		AND abov.rcs_version like '$fileVersion'
		AND abov.source like 'D%' 
		AND ao.filetype_id <> 1156 
		AND abov.object_version_id = aov.object_version_id
	ORDER BY ab.released_date
END_SQL

	my $dbExec = $dbConnection->prepare($sql);
	$dbExec->execute or die "SQL Error: $DBI::errstr\n";
	my $patchCnt = 0;
	#print "##########File: $fileName Version:$fileVersion\n";
	while (my @row = $dbExec->fetchrow_array) {
	   #print "$patchCnt: $row[1]\n\t$row[2]\n\tReleaseDate:$row[3]\n\tReleaseId:$row[4]\tProductId:$row[5]\n";
	   $avlCheckins{ $row[1] } = [ $row[2], $row[3], $row[0] ];
	#   ++$patchCnt;
	}

	%avlCheckins;
}

# brief: check newest ppc/lcc file version
# param0: apscheck file
# return: array: 0-fileName  1-RCS version
sub findFreshFile
{
	my $apsFile = $_[0];
	
	#$Header: msopomdemand.lcc 120.66.12010000.164 2012/07/27 23:19:17 utsingh ship $
	my $patchReg = '([\d]+)\s+(ONE-OFF)\s+([\d]+)\s+([\d]+)-([A-Z]{3})-([\d]+)\s+(msc)';
	my $fileVersionReg = 'Header:\s(\b[\S]+\.(lcc|ppc|opp))[\s]+(\b[\S]+)[\s]+([0-9]{4})\/([0-9]+)\/([0-9]+)[\s]+([\d]+):([\d]+):([\d]+)';
	open APS, $apsFile or die "Unable to open $apsFile:$!\n";
	
	my $freshTime;
	my $freshTxtTime;
	my @records; #1D: record index 2D:0-timestamp 1-filename, 2-version
	my $freshPatchDate;
	my $freshPatchNumber;
	while( <APS> )
	{
		if( /$patchReg/ )
		{
			my %monthMap = ( JAN =>1, FEB =>2, MAR =>3, APR =>4, MAY =>5, JUN =>6, JUL =>7, AUG =>8, SEP =>9, OCT =>10, NOV =>11, DEC =>12 );
			
			my $patchNumber = $1;
			my $patchType = $2;
			my $patchId = $3;
			my $day = $4;
			my $month = $monthMap{ $5 };
			next unless ( defined $month );
			my $year = $6;
			
			my $dateStamp = $year*10000 + $month*100 + $day;
			if( $freshPatchDate lt $dateStamp )
			{
				$freshPatchDate = $dateStamp;
				$freshPatchNumber = $patchNumber;
			}
			next;
		}
		if( /$fileVersionReg/ )
		{
			#print "$4/$5/$6 $7:$8:$9\n";
			
			my $timeStamp = timelocal( $9,$8,$7,$6,$5-1,$4 );
			#print "$4/$5/$6 $7:$8:$9  $timeStamp\n";
			push @records, [ $timeStamp, $1, $3 ];
			if( $timeStamp gt $freshTime )
			{
				$freshTime = $timeStamp;
				$freshTxtTime = "$4/$5/$6 $7:$8:$9";
				$latestFileInfo[0] = $1;
				$latestFileInfo[1] = $3;
			}
			next;
		}
	}
	
	close APS;
	
	my $recentCnt = 0;
	foreach my $record ( @records )
	{
		my $timeStamp = $record->[0];
		my $fileName  = $record->[1];
		my $rcsVersion = $record->[2];
		# If it's within two hours, push it to a recent file list.
		my $checkinElapse = int($freshTime - $timeStamp);
		if( $checkinElapse < 7200 )
		{
			#print "$timeStamp, $freshTime\n";
			push @recentFileInfo, [ $fileName, $rcsVersion ];
			++ $recentCnt;
		}
		last unless ( $recentCnt lt 5 );
	}
	
	$latestPatchNumber = $freshPatchNumber;
}

# brief:  find out what checkins that this checkin includes
# param0: bugfix_name
# return: relevant checkin
sub prereq
{
	
}
# brief:  find out how many checkins include given checkin
# param0: bugfix_id
# return: number of checkins that include this bugfix
sub includeCount
{
	my $fixId = $_[0];
	my $sql = <<END_SQL;
	SELECT 
		count(bugfix_id)
	FROM
		aru_bugfix_relationships
	WHERE
		related_bugfix_id = $fixId
	AND relation_type = 601
END_SQL
	my $dbExec = $dbConnection->prepare($sql);
	$dbExec->execute or die "SQL Error: $DBI::errstr\n";
	my @row = $dbExec->fetchrow_array;
	# We can still consider output them if there's less than 5 checkins
	if( $row[0] < 5 )
	{
		$sql = <<END_SQL;
		SELECT
			distinct ab.bugfix_name,
			ab.abstract,
			ab.released_date,
			ab.last_updated_date
		FROM
			aru_bugfixes ab,
			aru_bugfix_relationships abr
		WHERE
			abr.related_bugfix_id = $fixId
		AND abr.relation_type = 601
		AND abr.bugfix_id = ab.bugfix_id
		ORDER BY ab.last_updated_date
END_SQL
		my $dbExec = $dbConnection->prepare($sql);
		$dbExec->execute or die "SQL Error: $DBI::errstr\n";
		my $dependCnt = 0;
		while( my @row = $dbExec->fetchrow_array )
		{
			my $fixName = $row[0];
			my $abstract = $row[1];
			my $releasedDate = $row[2];
			my $lastUpdateDate = $row[3];
			
			my $dependentCheckinInfo = <<END;
			[Dependent Checkin]  [$dependCnt]
			Checkin: $fixName
			Abstract: $abstract
			LastUpdate: $lastUpdateDate
			Release Date: $releasedDate
			
END
			print $dependentCheckinInfo;
			++ $dependCnt;
		}
	}
	$row[0];
}
