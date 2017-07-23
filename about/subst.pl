#!/usr/bin/perl
use strict;
use warnings;
require ('./about_common.pl');

# This script is  used to explore substitution relationship related to an item
my $itemId = $ARGV[0];
my $substFile = './data/mbpinput/MSLD_ITEM_SUBSTITUTION.dat';

my $recordArray = pawk( 1, "lower_rev_id,higher_rev_id,highest_rev_id,relationship_type", $substFile);

# low,high,highest,relationType
my @relativeRecord;
my %relatedMap;

$relatedMap{ $itemId } = 1;

my $newAddedFlag = 0;
do{
	my $index =0;
	$newAddedFlag = 0;
	foreach my $record( @$recordArray )
	{
		next if ( not defined $recordArray->[$index] );
		my $lowRev = $record->[0];
		my $highRev = $record->[1];
		my $highestRev = $record->[2];
		my $relationType = $record->[3];
		
		if( exists $relatedMap{$lowRev} or exists $relatedMap{$highRev} )
		{
			push @relativeRecord, [qw/ $lowRev $highRev $highestRev $relationType/];
			$relatedMap{$lowRev} = 1;
			$relatedMap{$highRev} = 1;
			$newAddedFlag = 1;
			undef $recordArray->[$index];
		}
		$index++;
	}
}while( $newAddedFlag );

my %substTypeHash = { 2=>'REL_SUBSTITUTION', 8=>'REL_SUPERSESSION', 18=>'REL_REPAIRTO' };
print "[Substitution]:\n";
foreach my $record ( @relativeRecord )
{
	print $record->[0].' -> '.$record->[1]." highest= $record->[2] type=$record->[3] $substTypeHash{$record->[3]} \n";
}

