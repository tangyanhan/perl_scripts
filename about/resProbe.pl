#!/usr/bin/perl
use strict;
require ( "./about_common.pl" );

die "Usage: ./resAvl.pl res_id begin_date end_date" unless ($#ARGV == 2);

my $resID = $ARGV[0];
my $begin = $ARGV[1];
my $end = $ARGV[2];

my $resAvlFile = './data/mbpoutput/MSLD_RES_AVL.dat';

my $recordArray;
my $condition = "resource_id==$resID && shift_date>=$begin && shift_date<=$end";
my $columns = 'cap_units,daily_res_hours';
my $recordArray = pawk( $condition, $columns, $resAvlFile );

my $totalAvl = 0;
foreach my $record ( @$recordArray )
{
	my $resAvl = $record->[0] * $record->[1];
	$totalAvl += $resAvl;
}

print " Resource $resID  from $begin  to $end\n";
print "Capacity = $totalAvl\n";

my $resReqFile = './data/mbpoutput/MSLD_RES_REQS.dat';
$condition="res_id==$resID && resource_date>=$begin && resource_date<=$end";
$columns = 'daily_res_hours,capacity_units,detail_flag';
$recordArray = pawk( $condition, $columns, $resReqFile );
my $totalUsage = 0;
foreach my $record ( @$recordArray )
{
        next unless ( $record->[2] == 1 );

	my $resReq = $record->[0] ;
	$totalUsage += $resReq;
}

print "Usage = $totalUsage\n";
