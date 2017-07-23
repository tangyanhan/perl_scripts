#!/usr/bin/perl
use strict;
use warnings;
require ( "./about_common.pl" );

my $sourcingFile = './data/mbpinput/MSLD_SOURCING.dat';
die "sourcing.pl: Arguments error!" unless ($#ARGV eq 1 or $#ARGV eq 0);
die "Cannot find $sourcingFile!" unless ( -e $sourcingFile );

my $itemId = $ARGV[0];
my $orgId = $ARGV[1];

our %sourcingRuleHash = ( 1=>'TransferFrom',2=>'MakeAt',3=>'BuyFrom','ReturnTo'=>4,5=>'RepairAt' );
our %partConditionHash = ( 1=>'USABLE', 2=>'DEFECTIVE' );

my $columns = 'item_id,org_id,source_type,source_org_id,vendor_id,vendor_site_id,alloc_percent,part_condition,lead_time';
my $recordArray;
if( defined $orgId ) {
	$recordArray = pawk("item_id==$itemId&&org_id==$orgId",$columns,$sourcingFile);
}else{
	$recordArray = pawk("item_id==$itemId",$columns,$sourcingFile);
}

print "[SourcingRule]:\n";
foreach my $values( @$recordArray )
{
	my $orgId = $values->[1];
	my $sourceType = $values->[2];
	my $sourceOrgId = $values->[3];
	my $vendorId = $values->[4];
	my $vendorSiteId = $values->[5];
	my $allocPct = $values->[6];
	my $partCondition = $values->[7];
        my $lt = $values->[8];
	
	print $sourcingRuleHash{$sourceType}."  ";
	print $sourceOrgId unless ( $sourceOrgId eq -23453 );
	print "Vendor($vendorId-$vendorSiteId)" unless ($vendorId eq -23453);
	print " => $orgId" unless ( $orgId eq $sourceOrgId and $sourcingRuleHash{$sourceType} eq 'MakeAt' );
	print "alloc=$allocPct% " unless (int($allocPct) eq 100);
	print $partConditionHash{$partCondition} unless ($partCondition eq 1);
        print " LT=$lt" unless ( $lt eq -23453 );
	print "\n";
}
