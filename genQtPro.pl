#!/usr/bin/perl

#######################################################################
# This script is used to scan header/source files in current directory
# and generate .pro file for Qt Creator, as qmake cannot get customed to
# ppc/lcc source files
#######################################################################

use strict;
use warnings;
use Cwd;

our %hdrFileType = ( 'h'=>1, 'hpp'=>1, 'h++'=>1 );
our %srcFileType = ( 'lcc'=>1, 'ppc'=>1, 'cpp'=>1, 'c++'=>1, 'cc'=>1, 'c'=>1, 'java'=>1 );
our $curDir = getcwd;


my %incPaths;

my @hdrFiles;
my @srcFiles;
my @othFiles;

sub searchDir
{
	my $dirName = $_[0];
	opendir DIR, $dirName or die "Unable to open directory $dirName:$!\n";
	
	my @files = readdir DIR;
	
	foreach my $entry (@files)
	{
		next if( $entry =~ /^\./ );
		my $entryPath = $dirName.'/'.$entry;
		if( -d $entryPath )
		{
			next if( $entry eq 'RCS' ); #Ignore RCS entry
			searchDir( $entryPath );
		}
		else
		{
			$entry =~ /\.([a-z+]+)$/;
			#print "# $entryPath ";
			if( defined $1 and exists $hdrFileType{ $1 } )
			{
			#	print " Header\n";
				push @hdrFiles, $entryPath;
				$incPaths{ $dirName } = 1 unless ( exists $incPaths{ $dirName } );
			}
			elsif( defined $1 and exists $srcFileType{ $1 } )
			{
			#	print " Source\n";
				push @srcFiles, $entryPath;
			}
			else
			{
			#	print " Other\n";
				push @othFiles, $entryPath;
			}
		}
	}
	
	close DIR;
}

# output file list to a .pro file
sub outputProFile
{
	my $localTime = localtime; # quoted in $solidHeader
	my $solidHeader = <<HEADER;
######################################################################
# Automatically generated by genQtPro(yanhan) $localTime
######################################################################

TEMPLATE = app
TARGET = 
INCLUDEPATH += \.
HEADER
	$curDir =~ /([^\\\/]+)$/;
	my $proFile = $1.'.pro';
	print "Project file for QtCreator will be saved as $proFile\n";
	open PRO, '>'.$proFile or die "Unable to open $proFile for writing: $!\n";
	print PRO $solidHeader;
	
	print PRO 'DEPENDPATH += . ';
	foreach my $incPath ( keys %incPaths )
	{
		print PRO " \\ \n\t$incPath";
	}
	print PRO "\n\n";
	
        print PRO 'INCLUDEPATH += . ';
	foreach my $incPath ( keys %incPaths )
	{
		print PRO " \\ \n\t$incPath";
	}
	print PRO "\n\n";

        
	my $cntFlag = 0;
	print PRO 'HEADERS += ';
	foreach my $hdrFile ( @hdrFiles )
	{
		if( $cntFlag )
		{
			print PRO " \\ \n\t$hdrFile";
		}else{
			$cntFlag = 1;
			print PRO " $hdrFile";
		}
	}
	print PRO "\n\n";
	
	$cntFlag = 0;
	print PRO 'SOURCES +=';
	foreach my $srcFile ( @srcFiles )
	{
		if( $cntFlag )
		{
			print PRO " \\ \n\t$srcFile";
		}else{
			$cntFlag = 1;
			print PRO " $srcFile";
		}
	}
	print PRO "\n\n";
	
	# Donot write other files for the time being
	
	close PRO;
}

searchDir("."); #Windows seems a bit dumb on $curDir
my $totalNum = $#hdrFiles+$#srcFiles+$#othFiles+3;
print "# $totalNum files totally\n";
outputProFile;
