#!/usr/bin/perl
use strict;
require ( "./about_common.pl" );
#This script is used to check resources related to an item
#Maybe we should add a function to check resource overload ?

my $capResFile = './data/mbpinput/MSLD_CAP_RES.dat';
my $resFile = './data/mbpinput/MSLD_RESOURCES.dat';
my $resAvlFile = './data/mbpinput/MSLD_RES_AVL.dat';
my $resReqFile = './data/mbpoutput/MSLD_RES_REQS.dat';

#die "Argument error!\n" unless ( $#ARGV eq 1 or $#ARGV eq 0 );
# Seems that we should not check whether any file above actually exists.

my $itemId = $ARGV[0];
my $orgId = $ARGV[1];
my $date = $ARGV[2];

my $recordArray;
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
################# MSLD_RESOURCES.dat ########################
$columns = 'department_id,org_id,resource_id,bottleneck_flag';
$recordArray = pawk("1",$columns,$resFile);

foreach my $values( @$recordArray )
{
	my $resKey = $values->[0].' '.$values->[1].' '.$values->[2];
	$bottleNeckRes{$resKey} = $values->[3];
}

undef $recordArray;

################# MSLD_CAP_RES.dat ##########################
$columns = 'org_id,source_item_id,resource_id,routing_seq_id,op_seq_id,res_seq_num,alt_num,basis,department_id';
if( defined $orgId ){
	$recordArray = pawk("item_id==$itemId&&org_id==$orgId",$columns,$capResFile);
}else{
	$recordArray = pawk("item_id==$itemId",$columns,$capResFile);
}

# use @ before the ref of array so it will be array again.
foreach my $values( @$recordArray )
{
	# use ->[] to let perl know it's a ref to an array
	my $resOrgId = $values->[0];
	my $sourceItemId = $values->[1];
	my $resourceId = $values->[2];
	my $routingSeqId = $values->[3];
	my $opSeqId = $values->[4];
	my $resSeqNum = $values->[5];
	my $altNum = $values->[6];
	my $basis = $values->[7];
	my $deptId = $values->[8];
	
	my $resKey = $resourceId.' '.$deptId.' '.$resOrgId;
	$altResMap{ $resKey } = 0 if ( $altNum gt 0 );
	$resAvlMap{ $resKey } = 0;
	$basisMap{ $resKey } = $basis;
	#$resAvlMap{$resourceId} += $dailyHours;
}

undef $recordArray;


################# MSLD_RES_AVL.dat ##########################
# Pre-combine conditions and use || in awk so we can retrive the file only once
# for many keys in resAvlMap, and deal them later.
# Some files are rather large, it not practical to retrive it every time we want
# info of a resource-org
my $condition = 1;

# Avoid using condition combination for that will cause problems when it's making command too long
#foreach my $resKey ( keys %resAvlMap )
#{
	#my @res = split( /\s/, $resKey );
	##We need to append a || if there's condition before
	#if( defined $condition )
	#{
		#$condition = $condition.'||';
	#}
	#$condition = $condition."(resource_id==$res[0]&&department_id==$res[1]&&org_id==$res[2])"
#}

my $recordArray = pawk( $condition, "resource_id,department_id,org_id,cap_units*daily_res_hours,shift_date", $resAvlFile );
foreach my $values( @$recordArray )
{
	my $resKey = $values->[0].' '.$values->[1].' '.$values->[2];
	my $avlHours = $values->[3];
	my $shiftDate = $values->[4];
	
	next if ( not exists $resAvlMap{ $resKey } );
	
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
# item id related to this resource
# as item_id and resource is in M-M relation, this map is :
# resKey => a hash ref of item_id
my %resItemMap;

undef $condition;
$condition = 1;
#Avoid using combination
#foreach my $resKey ( keys %resAvlMap )
#{
	#my @res = split( /\s/, $resKey );
	##We need to append a || if there's condition before
	#if( defined $condition )
	#{
		#$condition = $condition.'||';
	#}
	#$condition = $condition."(res_id==$res[0]&&dept_id==$res[1]&&org_id==$res[2])";
#}

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
	
	$resItemMap{ $resKey } ->{$itemId} = 1;
	$resTransMap{ $transId } = $resKey;
	$resReqsMap{ $resKey } += $resHours;
	if( $dailyResAvlMap{ $resKey }->{$resDate} lt $resHours )
	{
		my $resStr = resKeyToString($resKey);
		my $overload = $resHours - $dailyResAvlMap{ $resKey }->{$resDate};
		print "$resStr on day $resDate overload=$overload hours \n";
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
		$usageRate = "Expect $reqHours on zero res" if ( (not defined $avlHours  or $avlHours eq 0) and $reqHours ne 0 );
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
