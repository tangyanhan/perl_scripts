#!/usr/bin/perl

$count =0;

my %lineMap;
while(<>)
{
	chomp;
	if( exists $lineMap{$_} ) {
		die "Duplicate at line $count dup with line $lineMap{$_}\n";
	}
	$lineMap{ $_ } = $count++;
}
