#!/usr/bin/perl
use strict;
use warnings;

our %orderTypeHash = (PURCHASE_ORDER=>1,PURCH_REQ=>2,WORK_ORDER=>3,REPETITVE_SCHEDULE=>4,PLANNED_ORDER=>5,MATERIAL_TRANSFER=>6,NONSTD_JOB=>7,RECEIPT_PURCH_ORDER=>8,REQUIREMENT=>9,FPO_SUPPLY=>10,SHIPMENT=>11,RECEIPT_SHIPMENT=>12,JOB_BY_PRODUCT_SUPPLY=>14,NONSTD_JOB_BY_PRODUCT_SUPPLY=>15,REP_SCHD_BY_PRODUCT_SUPPLY=>16,PLAN_ORD_BY_PRODUCT_SUPPLY=>17,ON_HAND_SUPPLY=>18,FLOW_SCHEDULE=>27,FLOW_SCHED_BY_PRODUCT_SUPPLY=>28,PAYBACK_SUPPLY=>29,CURRENT_REP_SCHEDULE=>30,EXPIRED_LOT=>31,SUPPLY_EAM_WORK_ORDER=>70,AGGR_SUPPLY_EAM_WORK_ORDER=>92,PLANNED_ARRIVAL=>51,DEMAND_PLANNED_ARRIVAL=>99,INTERNAL_REPAIR_ORDER=>73,EXTERNAL_REPAIR_ORDER=>74,REPAIR_WORK_ORDER_DEPOT_ORG=>75,PLANNED_NEW_BUY_ORDER=>76,PLANNED_INTERNAL_REPAIR_ORDER=>77,PLANNED_EXTERNAL_REPAIR_ORDER=>78,PLANNED_REPAIR_WORK_ORDER=>79,RETURNS_FORECAST=>81,RETURNS_DEMAND_SCHEDULE=>82,RETURNS_MANUAL_FORECAST=>83,RETURNS_BEST_FIT_FORECAST=>84,REPAIR_WORK_ORDER_EXTERNAL_REPAIR_ORG=>86,EXTERNAL_REPAIR_REQUISITION=>87,TRANSFER_ORDER=>80,RETURNS=>32);
our %demandTypeHash = (DEMAND_PLANNED_ORDER=>1,DEMAND_NS_JOB=>2,DEMAND_WORK_ORDER=>3,DEMAND_REPETITIVE=>4,DEMAND_LOT_EXPIRATION=>5,DEMAND_SALES_ORDER=>6,DEMAND_FORECAST=>7,DEMAND_MANUAL=>8,DEMAND_OTHER=>9,DEMAND_HARD_RESERVE=>10,DEMND_MDS_IND=>11,DEMND_MPS_COMPILE=>12,DEMAND_COPIED_SCHED=>15,PL_ORD_SCRAP=>16,WO_SCRAP=>17,PO_SCRAP=>18,PURCH_REQ_SCRAP=>19,RECEIPT_PO_SCRAP=>20,REP_SCHED_SCRAP=>21,DEMAND_OPTIONAL=>22,SHIPMENT_SCRAP=>23,DEMAND_INTERPLANT=>24,DEMAND_FLOW_SCHEDULE=>25,FLOW_SCHEDULE_SCRAP=>26,DEMAND_PAYBACK=>27,DEMAND_AGGREGATE=>28,DEMAND_NEW_FORECAST=>29,DEMAND_NEW_SALES_ORDER=>30,DEMAND_SAFETY_STOCK=>31,DEMAND_EAM_WORK_ORDER=>50,DEMAND_EAM_CMRO_WORK_ORDER=>70,AGGR_DEMAND_EAM_CMRO_WORK_ORDER=>92,OUTBOUND_SHIPMENT=>61,OUTBOUND_SHIPMENT_FIELD_ORG=>62,MANUAL_FORECAST=>63,DEMAND_SCHEDULE=>64,BEST_FIT_FORECAST=>65,DEMAND_HISTORY=>66,RETURNS_HISTORY=>67,PART_DEMAND=>77,PLANNED_PART_DEMAND=>78,POPULATION_BASED_FCST=>79,USAGE_FCST=>80,DEMAND_INTERNAL_SO=>54,UNCONSTRAINED_DEMAND=>83);

sub say
{
	print $_[0]."\n";
}

# Return a human-readable string of a resource key
# Resource key should be res_id dept_id org_id
# Return: res:res_id (dept:dept_id org:org_id)
sub resKeyToString
{
	my @ids = split( /\s/, $_[0] );
	my $str = 'res:'.$ids[0].'(dept:'.$ids[1].' org:'.$ids[2].' )';
}

#Index returned begins from 0, so we can use to array easily
sub getColumnIndexHash
{
	my %colIndex;
	my $fileName = $_[0];
	$fileName =~ /([^\/]+)$/;
	my $shortName =$1;
	my $columnFile = $ENV{'PWD'}."/ColumnNames/$shortName";
	if( not -e $columnFile )
	{
		my $msc_top = $ENV{'MSC_TOP'};
		$columnFile = $msc_top."/ColumnNames/$shortName";
		#Output load schema info so usr will know 
		print "Load DEV default schema from $columnFile\n";
		die "Cannot find schema for $shortName" if( not -e $columnFile );
	}
	
	#Comment this to make output cleaner
	#print "Load schema from $columnFile\n";
	
	open COL_FILE , $columnFile or die "##getColumnIndexHash:Unable to open $columnFile :$!\n";
	
	my $index = 0;
	while( <COL_FILE> )
	{
		chomp;
		if( /([0-9]+)\s+(.*)$/ )
		{
			$colIndex{$2} = $1;
			#print "$1\t$2\n";
		}
	}
	
	close COL_FILE;
	return %colIndex;
}



# a awk utility directly inserted into perl so we don't need to create PIPES to call tak
#param0: condition in text format
#param1: columns to get, split by comma
#param2: flat file to be explored

#return: an reference to a double-direction array containing columns expected.
#Errors: when no records found or 
sub pawk
{
	my $condition = $_[0];
	my $action = $_[1];
	my $fileName = $_[2];
	my @dblArray;
	
	my %colIndex = &getColumnIndexHash($fileName);

	# /g returns results of an array matching reg
	foreach my $key( $condition =~ /([a-zA-Z_]+)[+-~=><& ]/g )
	{
		if( exists $colIndex{$key} )
		{
			my $index =  $colIndex{$key};
			$condition =~ s/$key/\$$index/;
		}elsif( exists $colIndex{ 'str_'.$key } )
		{
			my $strKey = 'str_'.$key;
			my $index = $colIndex{ $strKey } ;
			$condition =~ s/$strKey/\$$index/;
		}
	}
	
	my $colCount = 0;
	$colCount++ while( $action =~ /,/g );
	
	foreach my $key( $action =~ /([a-zA-Z_]+)/g )
	{
		if( exists $colIndex{$key} )
		{
			my $index = $colIndex{$key};
			$action =~ s/$key/\$$index/;
		}
	}

	my $command = 'awk -F '. '\'{ if('. $condition . ') print '. $action .'}\'  ' . $fileName;
	#print "Command:$command\n";
	unless ( open PIPE, "-|" )
	{
		exec $command;
		exit;
	}
	
	my $recordCount = 0;
	while( <PIPE> )
	{
		my @values = split( /\s/, $_ );
		#If we encountered error, tell us what awk command we used, and the output as well
		die "##pawk: awk execution error\n##Command:$command\n##Output:$_\n" unless ($#values eq $colCount);
		push @dblArray, [@values];
		++$recordCount;
	}
	
	print STDERR "No output from awk on file $fileName \n" unless ( $recordCount ne 0 );
	close PIPE;
	
	\@dblArray;
}

sub dateConvert
{
    my @monthName = qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;

    my @weekdayName = qw/Mon Tue Wed Thu Fri Sat Sun/;

    my $dateNr =$_[0];
    my $l    = $dateNr + 68569;
    my $n    = int( ( 4 * $l ) / 146097              );
    $l    = int( $l - ( 146097 * $n + 3 ) / 4     );
    my $i    = int( ( 4000 * ( $l + 1 ) ) / 1461001  );
    $l    = int( $l - int(( 1461 * $i ) / 4) + 31 );
    my $j    = int( ( 80 * $l ) / 2447               );
    my $day  = int( $l - int(( 2447 * $j ) / 80)     );
    $l    = int( $j / 11                          );
    my $month= int( $j + 2 - ( 12 * $l )             );
    my $year = 100 * ( $n - 49 ) + $i + $l;

    my $dayOfWeek = $dateNr % 7;  
    my $txtDate= "$weekdayName[$dayOfWeek]-$day-$monthName[$month-1]-$year ";
    $txtDate;
}
1
