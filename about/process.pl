#!/usr/bin/perl
use strict;
use warnings;

#This script is used to find out process info around a item-org

my $procFile = './data/mbpinput/MSLD_PROCESS_EFF.dat';
die "Argument error!\n" unless ( $#ARGV eq 1 or $#ARGV eq 0 );
die "Unable to find $procFile!\n" unless ( -e $procFile );

my $itemId = $ARGV[0];
my $orgId = $ARGV[1];

unless ( open PIPE, "-|" ) 
{
	if( defined $orgId ) {
		exec 'slientTak "'."item_id==$itemId&&org_id==$orgId".'"'.' item_id,org_id,bill_seq_id,routing_seq_id,minimum_quantity,maximum_quantity,preference,item_process_cost '.$sourcingFile;
	}else{
		exec 'slientTak "'."item_id==$itemId".'"'.' item_id,org_id,bill_seq_id,routing_seq_id,minimum_quantity,maximum_quantity,preference,item_process_cost '.$sourcingFile;
	}
	exit;
}

while( <PIPE> )
{
	my @values = split( /\s/, $_ );
	die "tak execution error!\n" unless ($#values eq 7);
	my $orgId = $values[1];
	my $billSeqId = $values[2];
	my $routingSeqId = $values[3];
	my $minQty = $values[4];
	my $maxQty = $values[5];
	my $preference = $values[6];
	my $cost = $values[7];
}

close PIPE;

