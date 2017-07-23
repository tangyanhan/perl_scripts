#!/usr/bin/perl
use strict;
require ( "./about_common.pl" );

my $dmdFileA = $ARGV[0];
my $dmdFileB = $ARGV[1];

# item_id-org_id => count
my %dmdCntA;
my %dmdCntB;

my $cols = 'item_id,org_id';
my $recordsA = pawk( 1, $cols, $dmdFileA );
my $recordsB = pawk( 1, $cols, $dmdFileB );

foreach my $recordA ( @$recordsA )
{
	my $ioKey = $recordA->[0].'/'.$recordA->[1];
	$dmdCntA{ $ioKey } ++;
}

foreach my $recordB ( @$recordsB )
{
	my $ioKey = $recordB->[0].'/'.$recordB->[1];
	$dmdCntB{ $ioKey } ++;
}

foreach my $keyA ( keys %dmdCntA )
{
	print "No records in another one:$keyA" unless ( exists $dmdCntB{ $keyA } );
	
	my $cntA = $dmdCntA{ $keyA };
	my $cntB = $dmdCntB{ $keyA };
	if( $cntA != $cntB )
	{
		print "keyA diff: $cntA   $cntB\n";
	}
}



