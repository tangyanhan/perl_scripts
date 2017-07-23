#!/usr/bin/perl

$snapFile = $ARGV[0];
$grepResID = $ARGV[1];

open SNAP, $snapFile or die "Unable to open snap file $snapFile:$!\n";

$resBegin = 0;
$curID;
$curPhase;
$curBkt;
$curCap;
$curUsage;

%itemUsage;
while( <SNAP> )
{
	if( /<resFrame>/ )
	{
		$resBegin = 1;
	}
	
	if( /<\/resFrame>/ )
	{
		$resBegin = 0;
	}
	
	next unless ( $resBegin );
	
	if( /<id>(.*)<\/id>/ )
	{
		$curID = $1;
	}
	
	if( /<desc>(.*)<\/desc>/ )
	{
		$curPhase = $1;
	}
	
	if( /<T>(\d+)<\/T>/ )
	{
		$curBkt = $1;
	}
	
	if( /<cap>(.*)<\/cap>/ )
	{
		$curCap = $1;
	}
	
	if( /<usage>(.*)<\/usage>/ )
	{
		$curUsage = $1;
	}
	
	if( /<p id=.*item="(\d+)"\suse="(.*)"\/>/ )
	{
	#	$itemUsage{ $1 } = $2;
	}
	
	if( /<\/bkt>/ )
	{
		print "$curPhase:B$curBkt cap=$curCap usage=$curUsage\t";
	#	print "[";
	#	foreach $key( keys %itemUsage )
	#	{
	#		print "$key=$itemUsage[$key],";
	#	}
		print "]\n";
		
	#	undef %itemUsage;
	}
}


close SNAP;

