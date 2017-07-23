#!/usr/bin/perl
use strict;
require ( "./about_common.pl" );
# This script is used to check resource usage of given resources

my $capResFile = './data/mbpoutput/MSLD_CAP_RES.dat';
my $resFile = './data/mbpinput/MSLD_RESOURCES.dat';
my $resAvlFile = './data/mbpinput/MSLD_RES_AVL.dat';
my $resReqFile = './data/mbpoutput/MSLD_RES_REQS.dat';

my @resIds = @ARGV;
my $checkAll = 0;

#If no res ids given, check all item id 
$checkAll = 1 if( $#resIds lt 0 );

my $recordArray;
my $condition;

my $recordArray;
my $condition;
my $columns;


#"resource_id department_id org_id"=> bottleneck_flag
my %bottleNeckRes;
# "resource_id department_id org_id"=> sum(cap_units*daily_hours)
my %resAvlMap;
# "resource_id department_id org_id"=> sum()
my %resReqMap;
my %altResMap;
# resourceKey => total hours requested
my %resReqsMap;
# resourceKey => basis
my %basisMap;

# resourceKey => { date=>hours }
my %dailyResAvlMap;

# Prepare conditions
if( $checkAll ) {
	$condition = 1;
}else{	
	for( my $i=0; $i<=$#resIds; $i++ )
	{
		$condition .= "resource_id==$resIds[$i]";
		$condition .= '||' if( $i ne $#resIds );
	}
}
################# MSLD_RESOURCES.dat ########################
$columns = 'resource_id,department_id,org_id,bottleneck_flag';

$recordArray = pawk($condition,$columns,$resFile);

foreach my $values( @$recordArray )
{
	my $resKey = $values->[0].' '.$values->[1].' '.$values->[2];
	$resAvlMap{$resKey} = 0;
	$bottleNeckRes{$resKey} = $values->[3];
}

################# MSLD_CAP_RES.dat ##########################
$columns = 'resource_id,department_id,org_id,routing_seq_id,op_seq_id,res_seq_num,alt_num,basis';
my $recordArray = pawk( $condition,$columns, $capResFile );

foreach my $values( @$recordArray )
{
	# use ->[] to let perl know it's a ref to an array
	my $resKey = $values->[0].' '.$values->[1].' '.$values->[2];
	
	my $routingSeqId = $values->[3];
	my $opSeqId = $values->[4];
	my $resSeqNum = $values->[5];
	my $altNum = $values->[6];
	my $basis = $values->[7];
	
	$altResMap{ $resKey } = 0 if ( $altNum gt 0 );
	$resAvlMap{ $resKey } = 0;
	$basisMap{ $resKey } = $basis;
}

################# MSLD_RES_AVL.dat ##########################
my $recordArray = pawk( $condition, "resource_id,department_id,org_id,cap_units*daily_res_hours,shift_date", $resAvlFile );
foreach my $values( @$recordArray )
{
	my $resKey = $values->[0].' '.$values->[1].' '.$values->[2];
	my $avlHours = $values->[3];
	my $shiftDate = $values->[4];
	
	my $dailyAvl = { $shiftDate =>, $avlHours };
	$dailyResAvlMap{ $resKey } = $dailyAvl;
	$resAvlMap{ $resKey } += $avlHours;
}

foreach my $resKey ( keys %resAvlMap )
{
	my $resStr = resKeyToString($resKey);
	print "Resource: $resStr  avail hours : $resAvlMap{$resKey}";
	print " BottleNeck " if ($bottleNeckRes{$resKey} eq 1 );
	print " Alternate" if ( exists $altResMap{$resKey} );
	print " basis=$basisMap{$resKey}" if ( $basisMap{$resKey} ne 1 );
	print "\n";
}

################# MSLD_RES_REQS.dat #####################
# Query resource usage, and compare with resAvlMap
# Only cares resources appeared in $resAvlMap
# Currently have not taken Lot-based resource into consideration
# But we can remind user that it's not item-based.
#########################################################
# transaction id related to this resource
my %resTransMap;
# trans_id => res hours
my %transResMap;
my %dailyResReqMap;
# item id related to this resource
# as item_id and resource is in M-M relation, this map is :
# resKey => a hash ref of item_id
my %resItemMap;

undef $condition;
$condition = 1;

my $columns = "res_id,dept_id,org_id, trans_id,item_id,routing_seq_id,op_seq_id,res_seq_num,res_hours,resource_date,detail_flag";
$recordArray = pawk( $condition, $columns, $resReqFile );
foreach my $values( @$recordArray )
{
	my $resKey = $values->[0].' '.$values->[1].' '.$values->[2];
	next if ( not exists $resAvlMap{ $resKey } );
	
	my $transId = $values->[3];
	my $itemId = $values->[4];
	my $routingSeqId = $values->[5];
	my $opSeqId = $values->[6];
	my $resReqNum = $values->[7];
	my $resHours = $values->[8];
	my $resDate = $values->[9];
        my $detailFlag = $values->[10];
	$resItemMap{ $resKey } ->{$itemId} = 1;
	$resTransMap{ $transId } = $resKey;
        $transResMap{ $transId } = $resHours;
        if( $detailFlag eq 1 )
        {
            $resReqsMap{ $resKey } = $resHours;
        }
        else
        {
            $resReqsMap{ $resKey } += $resHours;
        }
        my $avlHours = $dailyResAvlMap{ $resKey } -> {$resDate} - $resHours;
        $dailyResAvlMap{ $resKey }->{$resDate} = $avlHours;
        
	if( $avlHours < 0 )
	{
		my $resStr = resKeyToString($resKey);
		my $overload = $resHours - $avlHours;
		print "transId=$transId $resStr on day $resDate overload=$overload hours \n";
	}
}

#Resource usage check
foreach my $resKey ( keys %resAvlMap )
{
	my $avlHours = $resAvlMap{ $resKey };
	my $reqHours = $resReqsMap{ $resKey };	
	my $usageRate =0;
	
	if( defined $reqHours )
	{
		$usageRate = $reqHours/$avlHours if( $avlHours ne 0 );
		$usageRate = "Expect $reqHours on zero res" if ( $avlHours eq 0 and $reqHours ne 0 );
	}
	
	my $resStr = resKeyToString($resKey);
	print "$resStr request= $reqHours usageRate=$usageRate";
	print "#Full or Overload" if ( $usageRate ge 1.0 );
	print " Basis = $basisMap{$resKey} " if ( $basisMap{$resKey} ne 1 );
	print "\nUsed by items:";
	foreach my $itemId ( keys %{$resItemMap{$resKey}} )
	{
		print "$itemId ";
	}
	print "\n";
}
