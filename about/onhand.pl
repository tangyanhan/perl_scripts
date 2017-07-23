#!/usr/bin/perl
use strict;
use warnings;
require('./about_common.pl');

my $ohFile = './data/mbpinput/MSLD_QOH.dat';
die "Argument error!\n" unless ( $#ARGV eq 1 or $#ARGV eq 0 );

my $itemId = $ARGV[0];
my $orgId = $ARGV[1];

my $recordArray;
my $columns = "org_id,trans_id,net_qty,part_condition";
if( defined $orgId )
{
	$recordArray = pawk( "item_id==$itemId&&org_id==$orgId", $columns, $ohFile );
}else{
	$recordArray = pawk( "item_id==$itemId", $columns, $ohFile );
}

print "[OnHands]:\n";
foreach my $values( @$recordArray )
{
	my $orgId = $values->[0];
	my $transId = $values->[1];
	my $netQty = $values->[2];
	my $partCondition = $values->[3];
	
	print "transId=$transId orgId=$orgId  netQty=$netQty";
	print "Defective" if ($partCondition ne 1);
	print "\n";
}
