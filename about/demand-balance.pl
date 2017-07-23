#!/usr/bin/perl
use strict;
require ( "./about_common.pl" );
# This script is used to check demand-supply balance for given items

my $dmdFile = './data/mbpoutput/MSLD_DEMANDS.dat';
my $peggingFile = './data/mbpoutput/MSLD_FULL_PEGGING.dat';

our %orderTypeHash = (1=>'PURCHASE_ORDER',2=>'PURCH_REQ',3=>'WORK_ORDER',4=>'REPETITVE_SCHEDULE',5=>'PLANNED_ORDER',6=>'MATERIAL_TRANSFER',7=>'NONSTD_JOB',8=>'RECEIPT_PURCH_ORDER',9=>'REQUIREMENT',10=>'FPO_SUPPLY',11=>'SHIPMENT',12=>'RECEIPT_SHIPMENT',14=>'JOB_BY_PRODUCT_SUPPLY',15=>'NONSTD_JOB_BY_PRODUCT_SUPPLY',16=>'REP_SCHD_BY_PRODUCT_SUPPLY',17=>'PLAN_ORD_BY_PRODUCT_SUPPLY',18=>'ON_HAND_SUPPLY',27=>'FLOW_SCHEDULE',28=>'FLOW_SCHED_BY_PRODUCT_SUPPLY',29=>'PAYBACK_SUPPLY',30=>'CURRENT_REP_SCHEDULE',31=>'EXPIRED_LOT',70=>'SUPPLY_EAM_WORK_ORDER',92=>'AGGR_SUPPLY_EAM_WORK_ORDER',51=>'PLANNED_ARRIVAL',99=>'DEMAND_PLANNED_ARRIVAL',73=>'INTERNAL_REPAIR_ORDER',74=>'EXTERNAL_REPAIR_ORDER',75=>'REPAIR_WORK_ORDER_DEPOT_ORG',76=>'PLANNED_NEW_BUY_ORDER',77=>'PLANNED_INTERNAL_REPAIR_ORDER',78=>'PLANNED_EXTERNAL_REPAIR_ORDER',79=>'PLANNED_REPAIR_WORK_ORDER',81=>'RETURNS_FORECAST',82=>'RETURNS_DEMAND_SCHEDULE',83=>'RETURNS_MANUAL_FORECAST',84=>'RETURNS_BEST_FIT_FORECAST',86=>'REPAIR_WORK_ORDER_EXTERNAL_REPAIR_ORG',87=>'EXTERNAL_REPAIR_REQUISITION',80=>'TRANSFER_ORDER',32=>'RETURNS');
our %demandTypeHash = (1=>'DEMAND_PLANNED_ORDER',2=>'DEMAND_NS_JOB',3=>'DEMAND_WORK_ORDER',4=>'DEMAND_REPETITIVE',5=>'DEMAND_LOT_EXPIRATION',6=>'DEMAND_SALES_ORDER',7=>'DEMAND_FORECAST',8=>'DEMAND_MANUAL',9=>'DEMAND_OTHER',10=>'DEMAND_HARD_RESERVE',11=>'DEMND_MDS_IND',12=>'DEMND_MPS_COMPILE',15=>'DEMAND_COPIED_SCHED',16=>'PL_ORD_SCRAP',17=>'WO_SCRAP',18=>'PO_SCRAP',19=>'PURCH_REQ_SCRAP',20=>'RECEIPT_PO_SCRAP',21=>'REP_SCHED_SCRAP',22=>'DEMAND_OPTIONAL',23=>'SHIPMENT_SCRAP',24=>'DEMAND_INTERPLANT',25=>'DEMAND_FLOW_SCHEDULE',26=>'FLOW_SCHEDULE_SCRAP',27=>'DEMAND_PAYBACK',28=>'DEMAND_AGGREGATE',29=>'DEMAND_NEW_FORECAST',30=>'DEMAND_NEW_SALES_ORDER',31=>'DEMAND_SAFETY_STOCK',50=>'DEMAND_EAM_WORK_ORDER',70=>'DEMAND_EAM_CMRO_WORK_ORDER',92=>'AGGR_DEMAND_EAM_CMRO_WORK_ORDER',61=>'OUTBOUND_SHIPMENT',62=>'OUTBOUND_SHIPMENT_FIELD_ORG',63=>'MANUAL_FORECAST',64=>'DEMAND_SCHEDULE',65=>'BEST_FIT_FORECAST',66=>'DEMAND_HISTORY',67=>'RETURNS_HISTORY',77=>'PART_DEMAND',78=>'PLANNED_PART_DEMAND',79=>'POPULATION_BASED_FCST',80=>'USAGE_FCST',54=>'DEMAND_INTERNAL_SO',83=>'UNCONSTRAINED_DEMAND');

my @itemIds = @ARGV;
my $checkAll = 0;

#If no res ids given, check all item id 
$checkAll = 1 if( $#itemIds lt 0 );

# To be used by pawk
my $condition;
my $columns;
if( not $checkAll )
{
	for( my $i=0; $i<=$#itemIds; $i++ )
	{
		$condition .= "item_id==$itemIds[$i]";
		$condition .= '||' if ( $i ne $#itemIds );
	}
}else{
	$condition = 1;
}

# item_id/org_id => [ dmd1 dmd2 dmd3 ]
my %itemFcstDmdMap;
# dmd_id => [ item_id org_id source_org_id demand_qty orig_type ]
my %fcstDmdMap;
# dmd_id => total supply qty, this is used to check unmet
my %supplyQtyMap;

my $recordArray;
$columns = 'demand_id,item_id,org_id,source_org_id,demand_qty,orig_type,demand_start_date';
$recordArray = pawk( $condition, $columns, $dmdFile );

foreach my $record ( @$recordArray )
{
	my $dmdId = $record -> [0];
	my $itemId = $record -> [1];
	my $orgId = $record -> [2];
	my $srcOrgId = $record -> [3];
	my $dmdQty = $record -> [4];
	my $origType = $record -> [5];
        my $dmdDate = $record->[6];
        
	next if( $orgId < 0 );

	my $ioKey = $itemId.'/'.$orgId;
	my $dmds = $itemFcstDmdMap{ $ioKey };
	push @$dmds, $dmdId;
	$itemFcstDmdMap{ $ioKey } = $dmds;
	$fcstDmdMap{ $dmdId } = $record;
}

foreach my $ioKey (keys %itemFcstDmdMap)
{
	print "Demands on item/org: $ioKey:\n";
	my $dmds = $itemFcstDmdMap{ $ioKey };
	foreach my $dmd( @$dmds )
	{
		print $dmd."\t";
	}
	print "\n";
}

print "Demands info:\n";
foreach my $dmd (keys %fcstDmdMap )
{
	my $record = $fcstDmdMap{ $dmd };
	my $dmdId = $record -> [0];
	my $itemId = $record -> [1];
	my $orgId = $record -> [2];
	my $srcOrgId = $record -> [3];
	my $dmdQty = $record -> [4];
	my $origType = $record -> [5];	
	print "dmd=$dmdId item/org=$itemId/$orgId ";
	print "from $srcOrgId " if ( $srcOrgId ne -23453 );
	print "qty=$dmdQty $demandTypeHash{$origType}\n";
}

$condition = 1;
$columns = 'demand_id,item_id,org_id,demand_qty,alloc_qty,supply_date,demand_date,trans_id,supply_qty';
my %lateDmdMap;
#dmd_id => [ trans 1 , trans 2 ]
my %transMap;
my $recordArray = pawk( $condition, $columns, $peggingFile );

foreach my $record( @$recordArray )
{
	my $demandId = $record->[0];
	
	my $itemId = $record->[1];
	my $orgId = $record->[2];
	my $dmdQty = $record->[3];
	my $allocQty = $record->[4];
	my $supplyDate = $record->[5];
	my $dmdDate = $record->[6];
	my $transId = $record->[7];
	my $supplyQty = $record->[8];
	
	my $ioKey = $itemId.'/'.$orgId;
	next if ( not exists $itemFcstDmdMap{ $ioKey } );
	if( $demandId == -1 )
	{
		print "excess on item/org:$itemId/$orgId  day=$supplyDate trans_id=$transId ";
		print " supply not used, qty= $supplyQty" if ($dmdQty == -23453);
		print " alloc= $allocQty" if ( $allocQty != -23453 );
		print "\n";
	}
	next if ( not exists $fcstDmdMap{$demandId} );
	
	$transMap{ $demandId } .= $transId.' ';
	$supplyQtyMap{ $demandId } += $allocQty;
	my $lateDays = $supplyDate - $dmdDate;
	if( $lateDays > 0 )
	{
		$lateDmdMap{$demandId} = $lateDays if( not defined $lateDmdMap{ $demandId } or $lateDmdMap{ $demandId } lt $lateDays );			
	}
	

}

foreach my $dmd( keys %fcstDmdMap )
{
	my $record = $fcstDmdMap{ $dmd };
	my $dmdId = $record -> [0];
	my $itemId = $record -> [1];
	my $orgId = $record -> [2];
	my $srcOrgId = $record -> [3];
	my $dmdQty = $record -> [4];
	my $origType = $record -> [5];	
        my $dmdDate = $record->[6];
        my $txtDate = dateConvert( $dmdDate );
	print "dmd=$dmdId item/org=$itemId/$orgId ";
	print "from $srcOrgId " if ( $srcOrgId != -23453 );
        print "day= $dmdDate ($txtDate) ";
	print "qty=$dmdQty $demandTypeHash{$origType} ";
	print " late=$lateDmdMap{$dmdId} days" if ( exists $lateDmdMap{$dmdId} );
	my $unmetQty = $dmdQty - $supplyQtyMap{ $dmdId };
	print " unmet qty=$unmetQty" if( $unmetQty >= 0.001 );
        print " Fcst expire" if ( $unmetQty eq $dmdQty and $demandTypeHash{$origType} eq 'DEMAND_NEW_FORECAST' );
	my $excessQty = 0 - $unmetQty;
	print " excess qty=$excessQty" if ( $excessQty >= 0.001 );
        print "\n";
}




