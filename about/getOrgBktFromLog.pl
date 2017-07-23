#!/usr/bin/perl

$orgBegin = 0;
$bktBegin = 0;

open FILE, ">orgBkt" or die "Unable to write file";
while( <> )
{
    if( /^#SCO\ org\ mapping/ ) {
        $orgBegin = 1;
        next;
    }
    
    print FILE $_ if ($orgBegin);
    
    if( /^#BKT/ ) {
        $bktBegin = 1;
    }else{
        last if( $bktBegin );
    }
}

close FILE;
