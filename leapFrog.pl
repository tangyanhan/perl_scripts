#!/usr/local/bin/perl
use strict;
use warnings;
use File::Copy;
use File::Path;

#This script is used to do leap frog on multiple files
#arguments: filelist.file  comment

#Prepare dir for top files ( to leap back )
our $topFileDir = 'top_files';

mkdir $topFileDir unless ( -e $topFileDir );
system( 'chmod 777 -R '.$topFileDir );

our $mso_top = $ENV{'MSO_TOP'};

my $listFile = $ARGV[0];
our $prodDir = $ARGV[1];
my $comment = $ARGV[2];

$prodDir =~ /(mso|msc|msr).*/;
my $prod = $1;

open FILELIST, $listFile or die "Unable to open filelist $listFile :$!\n";

open VERSION, '>versions' or die "Unable to open versions for writing:$!\n";

print "File versions will be saved as versions\n";
while(<FILELIST>)
{
    chomp;
    if( /rev-up (.*)/ )
    {
        #justCheckin($1,'leapback');
        leapFrog( $1, 'revup'.$comment );
    }else{
        #justCheckin($_,'leapback');
        leapFrog($_,$comment );
    }
}
close FILELIST;
close VERSION;

print "All jobs done!\n";

sub justCheckin
{
    my $file = $_[0];
    my $comment = $_[1];
    print "Rev up $file\n";
    my $status = system("arcs unlock $file");
    $status = system("arcs lock $file");
    $status = system("arcs in $file ".'\\'.$comment.'\\');
}

sub leapFrog
{
    my $file = $_[0];
    my $comment = $_[1];
    
    my $status = 1;
    
    print "Leap frog : $file comment=$comment ...";
    
    copy( $prodDir.'/'.$file, './') or die "Unable to copy $file";
    
    chdir $topFileDir;
    $status = system( "arcs unlock $file" );
    die" arcs unlock $file failure status:$status" if( $status<0 );
    $status = system("arcs out $file ");
    die "arcs out $file failure status:$status " if ( $status <0);
    
    chdir '..';
    $status = system("arcs in $file ".'\\'.$comment.'\\');
    die "arcs in $file failure :$status" if ($status<0);
    
    my $fileVersion = getFileVersion($mso_top.'/'.$file);
    $file =~ /(.*)\/([^\/]+)$/;
    my $srcDir = $1;
    my $fileName = $2;
    print VERSION "$prod $srcDir $fileName $fileVersion\n";
    
    #Leap back
    chdir $topFileDir;
    $status = system("arcs lock $file");
    die "arcs lock failure $status" if ($status <0);
    Y
    $status = system("arcs in $file ".'\\leapback\\' );
    die "arcs in failure while rev up $status" if ($status < 0);
    
    chdir '..';
    
    print " [Done]\n";
}

sub getFileVersion
{
    my $fileName = $_[0];
    my $fileVersion;
    
    unless ( open IDENT_PIPE, "-|" )
    {
        exec "ident $fileName";
        exit;
    }

    while ( <IDENT_PIPE> )
    {
        chomp;
        if( /\s([0-9.]+)\s/ )
        {
            $fileVersion = $1;
        }
    }

    close IDENT_PIPE;
    
    $fileVersion;
}

