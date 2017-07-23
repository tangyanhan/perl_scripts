#!/usr/bin/perl
use strict;
require ( "./about_common.pl" );

my $transFile = $ARGV[0]; #File to translate

my $fileName = './data/mbpoutput/MSLD_FLAT_ITEMS.dat';
my $records = pawk(1, "item_id,item_name", $fileName );

my %idNameMap;

foreach my $record (@$records)
{
	$idNameMap{ $record->[0] } = $record->[1];
}

open TRANS, $transFile or die "Unable to open file $transFile:$!\n";
open OUT, "> out.$transFile" or die "Unable to create file for writing!:$!\n";
while( <TRANS> )
{
	chomp;
	my @fields = split( /\s+/, $_ );
	for( my $i=0; $i<=$#fields; $i++ )
	{
		if( exists $idNameMap{ $fields[$i] } )
		{
			$fields[$i] = $idNameMap{ $fields[$i] };
			print "$fields[$i] -- > $idNameMap{ $fields[$i] }\n";
		}
		print OUT $fields[$i].' ';
	}
	print OUT "\n";
}
close OUT;
close TRANS;

print "Translation Done!\n";

