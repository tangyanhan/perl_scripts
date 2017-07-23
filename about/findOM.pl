#!/usr/bin/perl
use strict;
require ( "./about_common.pl" );

my %idMap;
foreach my $id( @ARGV )
{
	$idMap{ $id } = 1;
}

my $itmFile = './data/mbpinput/MSLD_ITEMS.dat';
my $cols = 'item_id,org_id,min_order_qty,max_order_qty,fixed_order_qty,fixed_lot_multiplier';

my $records= pawk( 1, $cols, $itmFile );

my $nullValue = -23453;
foreach my $record ( @$records )
{
	if( exists $idMap{ $record->[0] } )
	{
		print "Item/Org: $record->[0] / $record->[1]\t";
		print "MinOQ:$record->[2] " unless ( $record->[2] == $nullValue or $record->[2] <= 1 );
		print "MaxOQ:$record->[3] " unless ( $record->[3] == $nullValue or $record->[3] <= 1 );
		print "FOQ:$record->[4] " unless ( $record->[4] == $nullValue or $record->[4] <= 1 );
		print "FLM:$record->[3] " unless ( $record->[5] == $nullValue or $record->[5] <= 1 );
		print "\n";
	}
}

