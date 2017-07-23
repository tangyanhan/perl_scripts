#!/usr/bin/perl
use strict;
use warnings;

require ( "./about_common.pl" );

our %planTypeHash = (1=>'MRP_PLAN_TYPE',2=>'MPS_PLAN_TYPE',3=>'DRP_PLAN_TYPE',4=>'IP_PLAN_TYPE',5=>'DYP_PLAN_TYPE',6=>'EAM_PLAN_TYPE',7=>'DS_PLAN_TYPE',8=>'SRP_PLAN_TYPE',9=>'SRP_IO_PLAN_TYPE',10=>'SIM_SET_PLAN_TYPE',101=>'RP_MRP_PLAN_TYPE',102=>'RP_MPS_PLAN_TYPE',103=>'RP_DRP_PLAN_TYPE',105=>'RP_DYP_PLAN_TYPE');
our %constrainedModeHash = ( 0=>'UNCONSTRAINED',1=>'CLASSIC_CONSTRAINED',2=>'CONSTRAINED_WITHOUT_DS',3=>'CONSTRAINED_WITH_DS' );

my $planFile = "./data/mbpoutput/MSLD_FLAT_PLAN.dat";
my %colIndex = getColumnIndexHash( $planFile );

my $plan_id;
my $constrained_mode;
my $plan_type;
my $edd;
my $ecc;

my $recordArray = pawk(1,'plan_id,constrained_mode,plan_type,enforce_dem_due_dates,enforce_cap_constraints,curr_date,cutoff_date ',$planFile);

print "[Plan]\n";
foreach my $values ( @$recordArray )
{
	$plan_id = $values->[0];
	$constrained_mode = $values->[1];
	$plan_type = $values->[2];
	$edd = $values->[3];
	$ecc = $values->[4];
        my $curDate = $values->[5];
        my $lastDate = $values->[6];
	
	say("plan id:".$plan_id);
	say("constrained mode:".$constrainedModeHash{$constrained_mode});
	say("plan type:".$planTypeHash{$plan_type});
	say("ECC plan") if( $ecc eq 1 and $edd ne 1 );
	say("EDD plan") if( $edd eq 1 and $ecc ne 1 );
        my $txtCurDate= dateConvert( $curDate );
        my $txtLastDate = dateConvert( $lastDate );
        my $planDays = $lastDate - $curDate;
        say("Plan Horizon:$curDate ($txtCurDate) - $lastDate ($txtLastDate) $planDays days");
}

