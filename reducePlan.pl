#!/usr/bin/perl
use warnings;
use strict;
use File::Path;
use File::Copy;

my $dataDir = './data/';
my $dstDataDir = './small/';
my $bomCompFile = './data/mbpoutput/MSLD_BOM_COMP.dat';
my $processEffFile = './data/mbpoutput/MSLD_PROCESS_EFF.dat';
my $profFile = './data/mbpoutput/MSLD_FLAT_PROFILE_VAL.dat';

my $justItems = 0;
my $justShow = 0; # Just show 

BEGIN{
    if( defined $ENV{'ReducePlan'} and $ENV{'ReducePlan'} eq 'JustItem' )
    {
        print "#Just expand given items\n";
        $justItems = 1;
    }
        if( defined $ENV{'ReducePlan'} and $ENV{'ReducePlan'} eq 'JustShow' )
        {
            print "#Just show expansion\n";
            $justShow =1 ;
        }
}

my %itemRelatedFiles = (
    'mbpoutput/MSLD_BOM_COMP.dat'=>1,
    'mbpoutput/MSLD_BOM.dat'=>'assembly_item_id',
    'mbpoutput/MSLD_CAP_RES.dat'=>1,
    'mbpoutput/MSLD_COMPONENTS.dat'=>1,
    'mbpoutput/MSLD_ITEMS.dat'=>1,
    'mbpoutput/MSLD_ROUTINGS.dat'=>1,
    'mbpoutput/MSLD_QOH.dat'=>1,
    'mbpoutput/MSLD_REQS.dat'=>1,
    'mbpoutput/MSLD_FLAT_ITEMS.dat'=>1,
    'mbpoutput/MSLD_PURCH_SUPPLY.dat'=>1,
    'mbpoutput/MSLD_JOBS.dat'=>1,
    'mbpoutput/MSLD_ITEM_SUPPLIERS.dat'=>1,
    'mbpoutput/MSLD_JOB_RES.dat'=>1,
    'mbpoutput/MSLD_PROCESS_EFF.dat'=>1,
    'mbpoutput/MSLD_SOURCING.dat'=>1,
    'mbpoutput/MSLD_SUPPLIER_CAPACITIES.dat'=>1,
    'mbpoutput/MSLD_JOB_ROUTING_OPERNS.dat'=>1,
    'mbpoutput/MSLD_JOB_OPERATION_NETWORKS.dat'=>1,
    'mbpoutput/MSLD_JOB_OPER_NETWORK.dat'=>1,
    'mbpoutput/MSLD_JOB_REQUIREMENT_OPS.dat'=>'component_item_id',
    'mbpoutput/MSLD_JOB_COMPONENTS.dat'=>'assembly_item_id',
    'mbpoutput/MSLD_LJOB_OPER_RES_INST.dat'=>1,
    'mbpoutput/MSLD_SUPPLIER_FLEX_FENCES.dat'=>1,
    'mbpoutput/MSLD_FCST_UPDATES.dat'=>1,
    'mbpoutput/MSLD_AGG_RATES.dat'=>1,
    'mbpoutput/MSLD_LL_CODES.dat'=>1,
    'mbpoutput/MSLD_FULL_PEG_ALLOC.dat'=>1,
    'mbpoutput/MSLD_SUPPLIES.dat'=>1,
    'mbpoutput/MSLD_DEMANDS.dat'=>1,
    'mbpoutput/MSLD_FULL_PEGGING.dat'=>1,
    'mbpoutput/MSLD_SAFETY_STOCK.dat'=>1,
    'mbpoutput/MSLD_SUBSTITUTE_ITEMS.dat'=>'assembly_item_id',
    'mbpoutput/MSLD_RESERVATIONS.dat'=>1,
    'mbpoutput/MSLD_MRP_FPO_SUPPLY.dat'=>1,
    'mbpoutput/MSLD_EXPIRED_LOTS.dat'=>1,
    'mbpoutput/MSLD_SNAP_SS.dat'=>1,
    'mbpinput/MSLD_CAP_RES.dat'=>1,
    'mbpinput/MSLD_COMPONENTS.dat'=>1,
    'mbpinput/MSLD_FCST_DEMANDS.dat'=>1,
    'mbpinput/MSLD_FCST_UPDATES.dat'=>1,
    'mbpinput/MSLD_INFERRED_PATH.dat'=>1,
    'mbpinput/MSLD_ITEMS.dat'=>1,
    'mbpinput/MSLD_ITEM_SUPPLIERS.dat'=>1,
    'mbpinput/MSLD_JOB_RES.dat'=>1,
    'mbpinput/MSLD_JOB_ROUTING_OPERNS.dat'=>1,
    'mbpinput/MSLD_JOBS.dat'=>1,
    'mbpinput/MSLD_LL_CODES.dat'=>1,
    'mbpinput/MSLD_PROCESS_EFF.dat'=>1,
    'mbpinput/MSLD_PURCH_SUPPLY.dat'=>1,
    'mbpinput/MSLD_QOH.dat'=>1,
    'mbpinput/MSLD_REQS.dat'=>1,
    'mbpinput/MSLD_SOURCING.dat'=>1,
    'mbpinput/MSLD_SUPPLIER_CAPACITIES.dat'=>1,
    'mbpinput/MSLD_MRP_FPO_SUPPLY.dat'=>1,
    'mbpinput/MSLD_SUBSTITUTE_ITEMS.dat'=>'assembly_item_id',
    'mbpinput/MSLD_RESERVATIONS.dat'=>1,
    'mbpinput/MSLD_JOB_OPER_NETWORK.dat'=>1,
    'mbpinput/MSLD_EXPIRED_LOTS.dat'=>1,
    'mbpinput/MSLD_SNAP_SS.dat'=>1,
    'mbpinput/MSLD_JOB_COMPONENTS.dat'=>'assembly_item_id',
    'mbpinput/MSLD_IN_SOURCE_MPS_ITEMS.dat'=>1,
    'mbpinput/MSLD_SRP_ITEM_EXCEPTIONS.dat'=>1,
    'mbpinput/MSLD_GLOBAL_RETURN_FCST.dat'=>1,
    'mbpinput/MSLD_DYP_ITEM_ALLOCATION.dat'=>'inventory_item_id',
    'mbpinput/MSLD_IMM_ITEM_ZONE_INFO.dat'=>1,
    'mbpinput/MSLD_UOM_CLASS_LIST.dat'=>'inv_item_id',
    'mbpoutput/MSLD_BOR_REQS.dat'=>1,
    'mbpoutput/MSLD_IMM_ITEM_ZONE_INFO.dat'=>1,
    'mbpoutput/MSLD_INFERRED_PATH.dat'=>1,
    'mbpoutput/MSLD_IN_SOURCE_FPO_ITEMS.dat'=>1,
    'mbpoutput/MSLD_IN_SOURCE_MPS_ITEMS.dat'=>1,
    'mbpoutput/MSLD_JOB_RES_INST.dat'=>1,
    'mbpoutput/MSLD_MPS_SUPPLY.dat'=>1,
    'mbpoutput/MSLD_PS_SUPPLY.dat'=>1,
    'mbpoutput/MSLD_RES_INST_REQ.dat'=>1,
    'mbpoutput/MSLD_SEG_ALLOCS.dat'=>1,
    'mbpoutput/MSLD_WAREHOUSE_REQUIREMENTS.dat'=>1,
    'mbpoutput/MSLD_WO_SUB_COMP.dat'=>'primary_component_id'
);

my %routingRelatedFiles = (
    'mbpoutput/MSLD_ROUTING_OPERNS.dat'=>1,
    'mbpoutput/MSLD_OPER_COMP.dat'=>1,
    'mbpoutput/MSLD_OPER_RES_SEQS.dat'=>1,
    'mbpoutput/MSLD_OPER_RES.dat'=>1,
    'mbpoutput/MSLD_OPER_NETWORK.dat'=>1,
);

my %skipFiles = (
    'mbpoutput/MSLD_FLAT_SCO_SUPPLY.dat'=>1,
    'mbpoutput/MSLD_SUPPLIES.dat'=>1,
    'mbpoutput/MSLD_RES_REQS.dat'=>1,
    'mbpoutput/MSLD_DEMANDS.dat'=>1,
    'mbpoutput/MSLD_FULL_PEGGING.dat'=>1
);


my %relatedItemIdMap;
# routing sequence ids
my %relatedRoutingSeqIdMap;
#When debugging big plans with multi-process and multi-group,
#say, SUN plans, these plans consumes up lots memory.
#Even if we know that there are issues with a certain group.
#With JUST_SOLVE_GROUP, we can reduce the TIME, but not for
#the MEMORY consumed by MBP.
#Noticing that plans memory should be reduced for one group,
#This program intends to reduce flat files for certain items.

sub prepareDirs
{
    if( -e $dstDataDir )
    {
        print "\nRemove $dstDataDir\n";
        system( "rm -rf $dstDataDir" );
    }
    mkpath($dstDataDir.'mbpinput', 0, 0755);
    mkpath($dstDataDir.'mbpoutput', 0, 0755);
}

# Previous verion of expanding item relationship by dealing
# with BOM/SUBST/RES relation respectively, this actually donot
# provide any warranity to get a complete minimal subset from
# a lot of items.
# The right way to do this is to merge all these tables into one,
# and keep on probing into the list until no new elements
# are introduced. This will cause performace problems,
# but well worthy the cost if we are lucky enough to get a small dataset
sub expandItemRelation
{
    foreach my $item ( @_ )
    {
        $relatedItemIdMap{ $item } = 'original input';
    }
    
    my $bomCompFile = './data/mbpoutput/MSLD_BOM_COMP.dat';
    my $endItemSubstFile = './data/mbpinput/MSLD_ITEM_SUBSTITUTION.dat';
    my $compSubstFile = './data/mbpinput/MSLD_SUBSTITUTE_ITEMS.dat';
    my $capResFile = './data/mbpinput/MSLD_CAP_RES.dat';
    my $resReqFile = './data/mbpoutput/MSLD_RES_REQS.dat';
    
    # A simple a-b list
    my @relationList;
    
    my $recordCount = 0;
    my $bomEnd = 0;
    my $endSubstEnd = 0;
    my $compSubstEnd = 0;
    my $capResEnd = 0;
    my %relatedResourceIdMap;
    # BOM relation
    my $ret = open BOM_COMP, $bomCompFile;
    if( $ret )
    {
        my %indexHash = getColumnIndexHash($bomCompFile);
        my $itemIndex = $indexHash{ 'inventory_item_id' } -1;
        my $assyIndex = $indexHash{ 'using_assembly_id' } -1;
        while( <BOM_COMP> )
        {
            chomp;
            my @values = split( //, $_ );
            my @records;
            $records[0] = $values[$itemIndex];
            $records[1] = $values[$assyIndex];
            push @relationList, \@records;
            ++ $recordCount;
        }
        close BOM_COMP;
    }else{
        print  "#Ignore bom relation in $bomCompFile:$!\n";
    }
    
    $bomEnd = $recordCount;
    
    # End-item substitution
    $ret = open ITM_SUBST, $endItemSubstFile;
    if( $ret )
    {
        my %indexHash = getColumnIndexHash($endItemSubstFile);
        my $lowIndex = $indexHash{ 'lower_rev_id' } -1;
        my $highIndex = $indexHash{ 'higher_rev_id' } -1;
        while( <ITM_SUBST> )
        {
            chomp;
            my @values = split( //, $_ );
            my @records;
            $records[0] = $values[$lowIndex];
            $records[1] = $values[$highIndex];
            push @relationList, \@records;
            ++ $recordCount;
        }
        close ITM_SUBST;
    }else{
        print  "#Ignore end item substitution in $endItemSubstFile:$!\n";
    }
    
    $endSubstEnd = $recordCount;
    
    # Component substitution
    $ret = open COMP_SUBST, $compSubstFile;
    if( $ret )
    {
        my %indexHash = getColumnIndexHash($compSubstFile);
        my $lowIndex = $indexHash{ 'subst_item_id' } -1;
        my $highIndex = $indexHash{ 'assembly_item_id' } -1;
        while( <COMP_SUBST> )
        {
            chomp;
            my @values = split( //, $_ );
            my @records;
            $records[0] = $values[$lowIndex];
            $records[1] = $values[$highIndex];
            push @relationList, \@records;
            ++ $recordCount;
        }
        close COMP_SUBST;
    }else{
        print  "#Ignore component item substitution in $endItemSubstFile:$!\n";
    }
    $compSubstEnd = $recordCount;
    
    $ret = open CAP_RES, $capResFile;
    if( $ret )
    {
        my %indexHash = getColumnIndexHash( $capResFile );
        my $resIndex = $indexHash{ 'resource_id' } - 1;
        my $itemIndex = $indexHash{ 'item_id' } - 1;
        while( <CAP_RES> )
        {
            chomp;
            my @values = split( //, $_ );
            my @records;
            $records[0] = $values[ $resIndex ];
            $records[1] = $values[ $itemIndex ];
            push @relationList, \@records;
            ++ $recordCount;
        }
        close CAP_RES ;
    }else{
        print "#Ignore resource relation in $capResFile:$!\n";
    }
    $capResEnd = $recordCount;
    
    #$ret = open RES_REQ, $resReqFile;
    # if( $ret )
    # {
        # my %indexHash = getColumnIndexHash( $resReqFile );
        # my $resIndex = $indexHash{ 'res_id' } - 1;
        # my $itemIndex = $indexHash{ 'item_id' } - 1;
        # while( <RES_REQ> )
        # {
            # chomp;
            # my @values = split( //, $_ );
            # my @records;
            # $records[0] = $values[ $resIndex ];
            # $records[1] = $values[ $itemIndex ];
            # push @relationList, \@records;
            # ++ $recordCount;
        # }
        # close RES_REQ;
    # }else{
        # print "#Ignore resource relation in $resReqFile:$!\n";
    # }
    #$capResEnd = $recordCount;

    
        #foreach my $rec ( @relationList )
        #{
        #    print "== $rec->[0] $rec->[1]\n";
        #}
    # Begin expanding
    print "Expanding item relation ship\n";
    my $newAddFlag = 0;
    my $reason;
    do
    {
        $newAddFlag = 0;
        #foreach my $record ( @relationList )
        for( my $i=0; $i<= $#relationList; $i++ )
        {
            my $record = $relationList[$i];
            next unless ( defined $record );
                        
            if( $i > $compSubstEnd and $i <= $capResEnd )
            {
                if( exists $relatedResourceIdMap{ $record->[0] } or exists $relatedItemIdMap{ $record->[1] } )
                {
                    $reason = "Resource relation  resId/itemId: $record->[0]/$record->[1]";
                    $relatedResourceIdMap{ $record->[0] } = $reason;
                    $relatedItemIdMap{ $record->[1] } = $reason;
                    undef $relationList[$i];
                    $newAddFlag = 1;
                    next;
                }
            }
            elsif( exists $relatedItemIdMap{ $record->[0] } or exists $relatedItemIdMap{ $record->[1] } )
            {
                $reason = "";
                
                if( $i <= $bomEnd ) {
                    $reason = "Bom relation ";
                }elsif( $i <= $endSubstEnd ) {
                    $reason = "End-Item subst relation ";
                }elsif( $i <= $compSubstEnd ) {
                    $reason = "Comp subst relation ";
                }elsif( $i <= $capResEnd ) {
                    $reason = "Resource relation ";
                }
                                
                $reason .= $record->[0].' -> '.$record->[1];
                $relatedItemIdMap { abs($record->[0]) } = $reason unless ( exists $relatedItemIdMap{ $record->[0] } );
                $relatedItemIdMap { abs($record->[1]) } = $reason unless ( exists $relatedItemIdMap{ $record->[1] } );

                undef $relationList[$i];
                $newAddFlag = 1;
            }
        }
    }while( $newAddFlag !=0 );
}

# brief: get all items related to a group of item id given
# input: array of a group of item id 
# return : operating on a global hash table
sub exploreBomRelation
{
    #my $condition = 1;
    #my $columns = 'inventory_item_id,using_assembly_id';
    
    foreach my $item ( @_ )
    {
        $relatedItemIdMap{ $item } = 1;
    }
    
    #my $recordArray = pawk( $condition, $columns, $bomCompFile );
    my %indexHash = getColumnIndexHash($bomCompFile);
    my $itemIndex = $indexHash{ 'inventory_item_id' } -1;
    my $assyIndex = $indexHash{ 'using_assembly_id' } -1;
    
    my $ret = open BOM_COMP, $bomCompFile;
    if( !$ret )
    {
        print  "#Ignore bom relation in $bomCompFile:$!\n";
        return;
    }
    
    my $recordArray;
    while( <BOM_COMP> )
    {
        chomp;
        my @values = split( //, $_ );
        my $results = [ $values[$itemIndex], $values[$assyIndex] ];
        #print "$results->[0] - $results->[1]\n";
        push @$recordArray, $results;
    }
    
    close BOM_COMP;
    
    my %doneMap;
    my $newAddedFlag = 0;
    do{
        $newAddedFlag = 0;
        foreach my $record ( @$recordArray )
        {
            next if ( exists $doneMap{$record} );
            
            my $idA = $record->[0];
            my $idB = $record->[1];
            
            if( exists $relatedItemIdMap{$idA} or exists $relatedItemIdMap{$idB} )
            {
                $relatedItemIdMap{$idA} = 1;
                $relatedItemIdMap{$idB} = 1;
                $doneMap{ $record } =1;
                $newAddedFlag = 1;
                next;
            }
        }
    }while( $newAddedFlag );
    
    #foreach my $item ( keys %relatedItemIdMap )
    #{
        #print "=$item\n";
    #}
}

sub exploreSubstitutionRelation
{
    my $substFile = './data/mbpinput/MSLD_ITEM_SUBSTITUTION.dat';
    my $compSubstFile = './data/mbpinput/MSLD_SUBSTITUTION_ITEMS.dat';
    
    if( not -e $substFile )
    {
        print  "#Ignore substitution relation in $substFile: File doesn't exist\n";
        return;
    }
    
    my $recordArray = pawk( 1, "lower_rev_id,higher_rev_id,highest_rev_id,relationship_type", $substFile);

    # low,high,highest,relationType
    my @relativeRecord;

    my $newAddedFlag = 0;
    do{
        my $index =0;
        $newAddedFlag = 0;
        foreach my $record( @$recordArray )
        {
            next if ( not defined $recordArray->[$index] );
            my $lowRev = $record->[0];
            my $highRev = $record->[1];
            my $highestRev = $record->[2];
            my $relationType = $record->[3];
            
            if( exists $relatedItemIdMap{$lowRev} or exists $relatedItemIdMap{$highRev} )
            {
                push @relativeRecord, [qw/ $lowRev $highRev $highestRev $relationType/];
                $relatedItemIdMap{$lowRev} = 1;
                $relatedItemIdMap{$highRev} = 1;
                $newAddedFlag = 1;
                undef $recordArray->[$index];
            }
            $index++;
        }
    }while( $newAddedFlag );
}

sub getRelatedRoutingSeqIds
{
    #Avoid using pawk because the combined condition may be too long for command line
    #my $condition;
    #my $columns='routing_seq_id';
    #my @items = keys %relatedItemIdMap;
    
    #for( my $i=0; $i<=$#items; $i++ )
    #{
        #$condition .= "item_id==$items[$i]";
        #$condition .= '||' if ( $i ne $#items );
    #}
    
    #my $recordArray = pawk( $condition, $columns, $processEffFile );
    my $recordArray;
    
    my $ret = open PROCESS_EFF, $processEffFile;
    if( !$ret )
    {
        print  "#Ignore process relation in $processEffFile:$!\n";
        return;
    }
    
    my %indexHash = getColumnIndexHash( $processEffFile );
    my $itemIndex = $indexHash{ 'item_id' } -1;
    my $routingIndex = $indexHash{ 'routing_seq_id' } -1;
    
    while( <PROCESS_EFF> )
    {
        chomp;
        my @values = split( //, $_ );
        if( exists $relatedItemIdMap{ $values[$itemIndex] } )
        {
            my $results = [ $values[$routingIndex] ];
            #print "$results->[0] - $results->[1]\n";
            push @$recordArray, $results;
        }
    }
    
    close PROCESS_EFF;
    
    foreach my $record (@$recordArray)
    {
        my $routingSeqId = $record->[0];
        $relatedRoutingSeqIdMap{ $routingSeqId } = 1;
    }
    
    #print "Related routing seq ids:";
    #foreach my $routId (keys %relatedRoutingSeqIdMap)
    #{
        #print "$routId ";
    #}
}

# param0: file to reduce
# param1: key to use
# param2: dest dir
sub reduceFileByItemId
{
    reduceFile($_[0],$_[1],$_[2],1);
}

# param0: file to reduce
# param1: key to use
# param2: dest dir
sub reduceFileByRoutingSeqId
{
    reduceFile($_[0],$_[1],$_[2],0);
}

# param0: file to copy
# param1: dst dir
sub flatCopy
{
    #return if ( -e $_[1].$_[0] );
    my $fileName = $dataDir.$_[0];
    print "#Flatcopy:$fileName => $_[1]$_[0]\n";
    if( -e $fileName )
    {
        copy( $fileName, $_[1].$_[0] ) or die "Unable to copy $_[0]:$!\n";
    }else{
        print  "#Ignore $fileName:file doesn't exist\n";
    }
}

# param0: file to reduce
# param1: key to use
# param2: dest dir
# param3: which map to use, 0: relatedItemIdMap non-zero: relatedRoutingSeqIdMap
sub reduceFile
{
    my $fileName = $_[0];
    my $keyword = $_[1];
    my $dstDir = $_[2];
    my $useItemIdMap = $_[3];
    my $dstFileName = $dstDir.$fileName;
    
    if( $useItemIdMap and $itemRelatedFiles{ $fileName } ne '1' )
    {
        $keyword = $itemRelatedFiles{ $fileName };
    }
    
    #return if ( -e $dstFileName );
    $fileName = $dataDir.$fileName;
    
    if( not -e $fileName )
    {
        print  "#Ignore $fileName: file doesn't exist\n";
        return;
    }
    
    open FILE, $fileName or die "#Unable to open $fileName for reading!\n";
    open DST_FILE, ">$dstFileName" or die "Unable to open $dstFileName for write!\n";
    
    my %indexHash = getColumnIndexHash($fileName);
    
    # In some files, multi keys may exist in a same file,
    # Yet only some of them should be used.
    my @indexes;
    my $index = -1;
    foreach my $key ( keys %indexHash )
    {
        if( $key =~ /^$keyword$/ )
        {
            #Use the first match with keyword
            $index = $indexHash{ $key } -1;
            push @indexes, $index;
        }
    }
    die "#No key for column $keyword in $fileName!\n" unless ( $index ge 0  );
    
    print "$fileName";
    my $lineCount = 0;
    my $remainCount = 0;
    while( <FILE> )
    {
        my @values = split( //, $_ );
        
        ++$lineCount;
        if( $useItemIdMap )
        {
            foreach my $index( @indexes )
            {
                if( exists $relatedItemIdMap{ $values[$index] } )
                {
                    ++$remainCount;
                    print DST_FILE $_;
                    last;
                }
            }
        }
        else
        {
            foreach my $index( @indexes )
            {
                if( exists $relatedRoutingSeqIdMap{ $values[$index] } )
                {
                    ++$remainCount;
                    print DST_FILE $_;
                    last;
                }
            }
        }
    }
    if( $lineCount eq 0 )
    {
        print  "#Ignore $fileName:No content in file\n";
    }else{
        my $reducedPct = int(100*(1.0 - $remainCount/$lineCount));
        print  "$fileName:Reduced by $reducedPct %\n";
    }
    
    close FILE;
    close DST_FILE;    
}

sub getColumnIndexHash
{
    my %colIndex;
    my $fileName = $_[0];
    $fileName =~ /([^\/]+)$/;
    my $shortName =$1;
    my $currDir = $ENV{'PWD'};
    $currDir = '.' unless ( defined $currDir );
    my $columnFile = $currDir."/ColumnNames/$shortName";
    if( not -e $columnFile )
    {
        my $msc_top = $ENV{'MSC_TOP'};
		die "Cannot find Dev env MSC_TOP" unless( defined $msc_top );
		
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

# Function pawk is no longer used ( Only used by some discarded functions )

# a awk utility directly inserted into perl so we don't need to create PIPES to call tak
# we cannot use a very long condition for that will exceed the commandline limit.
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
    print "Command:$command\n";
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
    
    print  "No output from awk on file $fileName \n" unless ( $recordCount ne 0 );
    close PIPE;
    
    \@dblArray;
}

# Read item_id/res_id from a file named as non-numeric
# ids should be seperated by space or EOL
sub readIdFromFile
{
    print "#load item id from $_[0]...\n";
    my %ids;
    open FILE, $_[0] or die "Unable to open $_[0]:$!\n";
    
    print  "Items:";
    while( <FILE> )
    {
        chomp;
        my @a = split( /\s+/, $_ );
        foreach my $value( @a )
        {
            if( $value =~ /^[0-9]+$/ )
            {
                $ids{$value}++;
            }
        }
    }
    
    close FILE;
    
    my @idArray;
    foreach my $key ( keys %ids )
    {
        print  "$key ";
        push @idArray, $key;
    }
    die "No item id given in file $_[0]\n" if ( $#idArray < 0 );
    @idArray;
}

# Collect related item ids related to the given resource id,
# from res-reqs and cap-res files
sub collectItemIdFromRes
{
    my @resIds = @_;
    my %resIdMap;
    my %itemIdMap;
    
    foreach my $resId (@resIds)
    {
        $resIdMap{ $resId } = 1;
    }
    my $resReqFile = './data/mbpoutput/MSLD_RES_REQS.dat';
    open RES_REQ, $resReqFile or die "Fail to open $resReqFile:$!\n. It's required to find item_id/res_id relationship!\n";
    my %indexHash = getColumnIndexHash( $resReqFile );
    my $itemIndex = $indexHash{ 'item_id' } - 1;
    my $resIndex = $indexHash{ 'res_id' } - 1;
    while( <RES_REQ> )
    {
        my @values = split( //, $_ );
        my $itemId = $values[ $itemIndex ];
        my $resId = $values[ $resIndex ];
        
        next if( $itemId == -23453 );
        
        $itemIdMap{ $itemId } = 1 if( exists $resIdMap{ $resId } );
    }
    
    close RES_REQ;
    
    my $capResFile = './data/mbpinput/MSLD_CAP_RES.dat';
    open CAP_RES, $capResFile or die "Fail to open $capResFile:$!\n. It's required to find item_id/res_id relationship!\n";
    %indexHash = getColumnIndexHash( $capResFile );
    $itemIndex = $indexHash{ 'item_id' } - 1;
    $resIndex = $indexHash{ 'resource_id' } - 1;
    while( <CAP_RES> )
    {
        my @values = split( //, $_ );
        my $itemId = $values[ $itemIndex ];
        my $resId = $values[ $resIndex ];
        
        next if( $itemId == -23453 );
        
        $itemIdMap{ $itemId } = 1 if( exists $resIdMap{ $resId } );
    }
    
    close CAP_RES;
        
    my @idArray;
    print "For @resIds , Item Ids related to given res ids:\n";
    foreach my $key ( keys %itemIdMap )
    {
        print "$key ";
        push @idArray, $key;
    }
    print "\n";
    @idArray;
}

sub usage
{
my $usage = <<END_USAGE;
============       reducePlan      =======================
A tool to reduce data files for big plans. 

[Requirement]
Original data should be named 'data' under current dir,
and it's recommended to have a dir 'ColumnNames' containing
column index for flat files under current dir.

[Output]
The reduced data files will be put to dir named 'small'.

[Usage]
Usage1: reducePlan 30128 49273 3315 ...
        This will reduce data according to given item ids
Usage2: reducePlan idCollection
        Item ids are stored in file idCollection
        seperated by a space or EOL
Usage3: reducePlan res 4040 4083 ...
        Reduce data according to res ids. 
Usage4: reducePlan res resIds
        Resource ids are stored in file resIds
        seperated by a space or EOL

[Special Usage]
We can access special usage by setting environment var 'ReducePlan':
Set to 'JustItem': Donot expand item relationship, just use input ids. It applies to res ids as well.
Set to 'JustShow': Donot reduce any files, just print item expansion to console
=========================================================
<yanhan.tang\@oracle.com>
END_USAGE
    print "$usage";
    exit 0;
}
################# MAIN ##########################

my @input;

#No arguments given, print usage
if( $#ARGV < 0 )
{
    usage;
}

# We suppose that they are item ids, when only numeric ids or a single filename given, 
# Suppose that they are resource ids when it starts with param 'res'

if( $#ARGV == 0 and $ARGV[0] =~ /[^\d]/ ) #A single file name is given
{
    @input = readIdFromFile( $ARGV[0] );
}
elsif( $#ARGV >0 and $ARGV[0] eq 'res' )
{
    my @resIds;
    if( $ARGV[1] =~ /[^\d]/ )
    {
        @resIds = readIdFromFile( $ARGV[1] );
    }
    else
    {
        shift @ARGV;
        @resIds = @ARGV;
    }
    @input = collectItemIdFromRes( @resIds );
}
else
{
    @input = @ARGV;
}


#convert input to map
my %inputItemIdMap;
foreach my $itmId ( @input )
{
    $inputItemIdMap{ $itmId }=1;
}

if( $justItems == 1 )
{
    print "#Skip expand item relation\n";
}else{
    expandItemRelation( @input );
}

#exploreBomRelation( @input );
#exploreSubstitutionRelation;
getRelatedRoutingSeqIds;

if( $justShow )
{
    goto PRINT_ITEM;
}

prepareDirs;

my @dirEntrys = ('mbpinput', 'mbpoutput' );

my %inputFileMap;
my %outputFileMap;

for( my $i = 0; $i<=$#dirEntrys; $i++ )
{
    my $dirEntry = $dirEntrys[$i];
    print "#Processing $dirEntry\n";
        
    my $useInput = 0;
    if( $dirEntry eq 'mbpinput' )
    {
        $useInput = 1;
    }
    
    my $dirPath = $dataDir.'/'.$dirEntry;
    next unless ( -d $dirPath );
    
    opendir DIR, $dirPath or die "Unable to open dir $dirPath:$!\n";
    my @files = readdir DIR;
    foreach my $file (@files)
    {
        if( $file =~ /\.dat$/ )
        {
            if( $useInput )
            {
                $inputFileMap{ $file } = 1;
            }
            else
            {
                next unless ( not exists $inputFileMap{ $file } ); # Forget about files already in mbpinput
            }
			
            $file = $dirEntry.'/'.$file;
			next if( exists $skipFiles{ $file } );
            
			#print "# File: $file\n";
            if( exists $itemRelatedFiles{ $file } )
            {
                reduceFileByItemId( $file, "(item_id|inventory_item_id)", $dstDataDir );
            }
			elsif( exists $routingRelatedFiles { $file } )
            {
                reduceFileByRoutingSeqId( $file, "(routing_seq_id|rout_seq_id)",$dstDataDir );
            }
			else
            {
                flatCopy($file, $dstDataDir);
            }
        }
    }
    closedir DIR;
}

print "# Removing decomposition settings from profile...\n";
# As I do not believe in SCO decomposition, I should remove profiles controling decomposition
open SRC, $dataDir.'mbpoutput/MSLD_FLAT_PROFILE_VAL.dat' or die "No profile data available\n";
open DST, ">".$dstDataDir.'mbpoutput/MSLD_FLAT_PROFILE_VAL.dat' or die "Unable to create profile file for writing\n";
while( <SRC> )
{
	next if( /MSO_DECOMPOSITION_TOTAL_PROCESSES/ );
	next if( /MSO_SCO_DECOMP_GROUPS/ );
	print DST $_;
}
close SRC;
close DST;

# check id expanding
PRINT_ITEM:
print "\nItems:\n";
my $idCnt = 0;
foreach my $itmId ( keys %relatedItemIdMap )
{
    print "$idCnt: $itmId\t:$relatedItemIdMap{$itmId}\n";
    $idCnt++;
}
print "\n";
