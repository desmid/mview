# -*- perl -*-
# Copyright (C) 2015 Nigel P. Brown
# $Id: BLAST2_OF6.pm $

###########################################################################
#
# Base classes for NCBI BLAST2 family.
#
# Handles: BLAST+ -outfmt 7
#
# BLAST (NCBI version 2) iterated searching uses 3 main record types:
#
#   HEADER        the header text
#   SEARCH        passes of the search engine
#
#   SEARCH is further subdivied into:
#     RANK        the list of ordered high scoring hits
#     MATCH       the set of alignments for a given hit
#
#   MATCH is further subdivided into:
#     SUM         the summary lines for each hit
#     ALN         each aligned fragment: score + alignment
#
###########################################################################
package NPB::Parse::Format::BLAST2_OF7;

use NPB::Parse::Format::BLAST;
use NPB::Parse::Format::BLAST2;
use NPB::Parse::Regexps;

use strict;

use vars qw(@ISA

	    @VERSIONS

	    $ENTRY_START
	    $ENTRY_END

	    $HEADER_START
	    $HEADER_END
	   );

@ISA   = qw(NPB::Parse::Format::BLAST);

@VERSIONS = ( 
	     '2of7' => [
                     #'BLASTP',
		     #'BLASTN',
		     #'BLASTX',
		     #'TBLASTN',
		     #'TBLASTX',
		     'PSIBLAST',
		    ],
	    );

my $NULL = '^\s*$';

my $PROGRAMS = "(?:" . join("|", @{$VERSIONS[1]}) . ")";

# Header format is like this:
#  # PSIBLAST 2.2.28+
#  # Iteration: 1
#  # Query: test
#  # Database: mito.1000.aa
#  # Fields: query id, subject id, % identity, alignment length, mismatches, gap opens, q. start, q. end, s. start, s. end, evalue, bit score, query seq, subject seq
#  # 65 hits found
# <data>\t<data>\t...
# <data>\t<data>\t...
# ...
# repeated in case of psiblast before each search cycle and terminated with:
#  <blank>
#  Search has CONVERGED!
#  # BLAST processed 2 queries
#  <eof>

$ENTRY_START   = "^\# $PROGRAMS";
$ENTRY_END     = '^\# .*processed';

$HEADER_START  = $ENTRY_START;
$HEADER_END    = '^[^\#]';

my $SEARCH_START    = "^[^\#][^\t]*\t";
my $SEARCH_END      = "^(?:$HEADER_START|$NULL)";

my $FIELD_SKIP = '-';
my $FIELD_MAP = {
    'subject id'        => 'id',
    'q. start'          => 'query_start',
    'q. end'            => 'query_stop',
    's. start'          => 'sbjct_start',
    's. end'            => 'sbjct_stop',
    'evalue'            => 'expect',
    'bit score'         => 'bits',
    'query seq'         => 'query',
    'subject seq'       => 'sbjct',
};
my $RANK_FIELDS = [ qw(id expect bits) ];
my $SUM_FIELDS  = [ qw(id) ];
my $ALN_FIELDS  = [ qw(expect bits
                       query query_start query_stop
                       sbjct sbjct_start sbjct_stop)
    ];

#Given a string in 'line' of tab-separated fields as described in 'all',
#extract those named in 'wanted' storing each such key/value into 'hash';
#returns number of fields read or -1 on error.
my $extract_fields = sub {
    my ($line, $all, $wanted, $hash, $debug) = (@_, 0);
    chomp $line;
    my @list = split("\t", $line);
    warn "[@$all] -> [@$wanted]"  if $debug;
    warn "[$line]"  if $debug;
    return -1  if scalar @list != scalar @$all;
    my $c = 0;
    foreach my $key (@$all) {
        my $val = shift @list;
        next  unless grep {/^$key$/} @$wanted;
        $val =~ s/^\s+|\s+$//g;
        $hash->{$key} = $val;
        warn "[$key] => [$val]\n"  if $debug;
        $c++;
    }
    return $c;
};

sub new {
    my $type = shift;
    if (@_ < 2) {
	#at least two args, ($offset, $bytes are optional).
	NPB::Message::die($type, "new() invalid arguments (@_)");
    }
    my ($parent, $text, $offset, $bytes) = (@_, -1, -1);
    my ($self, $line, $record);
    
    $self = new NPB::Parse::Record($type, $parent, $text, $offset, $bytes);
    $text = new NPB::Parse::Record_Stream($self);

    while (defined ($line = $text->next_line)) {

	#blank line or empty record: ignore
	next    if $line =~ /$NULL/o;

	#HEADER block
	if ($line =~ /$HEADER_START/o) {
	    my $t = $text->scan_until($HEADER_END, 'HEADER');
            #warn "H=[$t]\n"; #NIGE
	    next;
	}

	#SEARCH block
	if ($line =~ /$SEARCH_START/o) {
	    my $t = $text->scan_until($SEARCH_END, 'SEARCH');
            #warn "S=[$t]\n"; #NIGE
	    next;
	}

        #stop at convergence message
        last  if $line =~ /^Search has CONVERGED/;

	#default
	$self->warn("unknown field: $line");
    }

    $self;#->examine;
}


###########################################################################
package NPB::Parse::Format::BLAST2_OF7::HEADER;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Record);

sub new {
    my $type = shift;
    if (@_ < 2) {
	#at least two args, ($offset, $bytes are optional).
	NPB::Message::die($type, "new() invalid arguments (@_)");
    }
    my ($parent, $text, $offset, $bytes) = (@_, -1, -1);
    my ($self, $line, $record);

    $self = new NPB::Parse::Record($type, $parent, $text, $offset, $bytes);
    $text = new NPB::Parse::Record_Stream($self);

    #BLAST
    $self->{'full_version'} = '';
    $self->{'version'}      = '';
    $self->{'query'}        = '';
    $self->{'summary'}      = '';

    #BLAST2_OF7
    $self->{'fields'}       = [];

    while ($line = $text->next_line) {

	#blast version info
	if ($line =~ /^# ($PROGRAMS\s+(\S+))/o) {
	    $self->test_args($line, $1, $2);
	    (
	     $self->{'full_version'},
	     $self->{'version'},
	    ) = ($1, $2);
	    next;
	} 

        if ($line =~ /^# Query:\s+(.*)/o) {
            $self->{'query'} = $1;
            $self->{'summary'} = '';  #never set
            next;
        }

        if ($line =~ /^# Fields:\s+(.*)/o) {
            my @tmp = split(/,\s+/, $1);
            foreach my $f (@tmp) {
                $f = exists $FIELD_MAP->{$f} ? $FIELD_MAP->{$f} : $FIELD_SKIP;
                push @{$self->{'fields'}}, $f;
            }
            next;
        }

        next  if $line =~ /^# Iteration:\s+(\d+)/o;
        next  if $line =~ /^# Database:/o;
        next  if $line =~ /^# \d+ hits found/o;

	#default
	$self->warn("unknown field: $line");
    }
    $self;
}

sub print_data {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    printf "$x%20s -> %s\n", 'version',      $self->{'version'};
    printf "$x%20s -> %s\n", 'full_version', $self->{'full_version'};
    printf "$x%20s -> %s\n", 'query',        $self->{'query'};
    printf "$x%20s -> %s\n", 'summary',      $self->{'summary'};
    printf "$x%20s -> %s\n", 'fields',       "@{$self->{'fields'}}";
}


###########################################################################
package NPB::Parse::Format::BLAST2_OF7::SEARCH;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST2::SEARCH);

sub new {
    my $type = shift;
    if (@_ < 2) {
        #at least two args, ($offset, $bytes are optional).
        NPB::Message::die($type, "new() invalid arguments (@_)");
    }
    my ($parent, $text, $offset, $bytes) = (@_, -1, -1);
    my ($self, $line, $record);
    
    $self = new NPB::Parse::Record($type, $parent, $text, $offset, $bytes);
    $text = new NPB::Parse::Record_Stream($self);

    #create dummy RANK object
    $self->add_record('RANK', $offset, $bytes);

    #create dummy MATCH objects
    while (defined ($line = $text->next_line)) {
        chomp $line;
        #warn "[$line]\n"; #NIGE

        if ($line =~ /$SEARCH_START/) {
	    my $t = $text->scan_lines(1, 'MATCH');
            #warn "M=[$t]\n"; #NIGE
	    next;
        }

	#default
	$self->warn("unknown field: $line");
    }

    $self;#->examine;
}


###########################################################################
package NPB::Parse::Format::BLAST2_OF7::SEARCH::RANK;

use vars qw(@ISA);
use NPB::Parse::Regexps;

@ISA = qw(NPB::Parse::Format::BLAST::RANK);

sub new {
    my $type = shift;
    if (@_ < 2) {
	#at least two args, ($offset, $bytes are optional).
	NPB::Message::die($type, "new() invalid argument list (@_)");
    }
    my ($parent, $text, $offset, $bytes) = (@_, -1, -1);
    my ($self, $line, $record);
    $self = new NPB::Parse::Record($type, $parent, $text, $offset, $bytes);
    $text = new NPB::Parse::Record_Stream($self);

    #warn "SEARCH::RANK\n";#NIGE

    #column headers
    $self->{'header'} = '';

    #ranked search hits
    $self->{'hit'}    = [];

    my %seen = ();

    my $fields = $self->get_parent(2)->get_record('HEADER')->{'fields'};
    my $fcount = scalar @$fields;
    #warn "[@{[scalar @$fields]}] @{$fields}\n";

    while (defined ($line = $text->next_line)) {
        chomp $line;
        #warn "[$line]\n"; #NIGE

        my $tmp = {};

        if ($line =~ /$SEARCH_START/) {

            #BLAST2
            $tmp->{'id'}      = '';
            $tmp->{'bits'}    = '';
            $tmp->{'expect'}  = '';
            $tmp->{'n'}       = '';
            $tmp->{'summary'} = '';

            #extract fields into tmp
            my $c = $extract_fields->($line, $fields, $RANK_FIELDS, $tmp);

            if ($c < 0) {
                $self->die("field count mismatch (expect $fcount, got $c)\n");
            }

            #seen this id already? RANK should only contain the best hit:
            #assume it is the first one encountered
            next  if exists $seen{$tmp->{'id'}};
            $seen{$tmp->{'id'}}++;

            $tmp->{'id'} = NPB::Parse::Record::clean_identifier($tmp->{'id'});

            push @{$self->{'hit'}}, $tmp;
            next;
        }

	#default
	$self->warn("unknown field: $line");
    }

    $self;#->examine;
}


###########################################################################
package NPB::Parse::Format::BLAST2_OF7::SEARCH::MATCH;

use vars qw(@ISA);
use NPB::Parse::Regexps;

@ISA = qw(NPB::Parse::Format::BLAST::MATCH);

sub new {
    my $type = shift;
    if (@_ < 2) {
	#at least two args, ($offset, $bytes are optional).
	NPB::Message::die($type, "new() invalid argument list (@_)");
    }
    my ($parent, $text, $offset, $bytes) = (@_, -1, -1);
    my ($self, $line, $record);

    $self = new NPB::Parse::Record($type, $parent, $text, $offset, $bytes);

    #warn "SEARCH::MATCH\n";#NIGE

    #create dummy objects
    $self->add_record('SUM', $offset, $bytes);
    $self->add_record('ALN', $offset, $bytes);

    $self;#->examine;
}


###########################################################################
package NPB::Parse::Format::BLAST2_OF7::SEARCH::MATCH::SUM;

use vars qw(@ISA);
use NPB::Parse::Regexps;

@ISA = qw(NPB::Parse::Format::BLAST2::SEARCH::MATCH::SUM);

sub new {
    my $type = shift;
    if (@_ < 2) {
	#at least two args, ($offset, $bytes are optional).
	NPB::Message::die($type, "new() invalid argument list (@_)");
    }
    my ($parent, $text, $offset, $bytes) = (@_, -1, -1);
    my ($self, $line, $record);

    $self = new NPB::Parse::Record($type, $parent, $text, $offset, $bytes);
    $text = new NPB::Parse::Record_Stream($self);

    #warn "SEARCH::MATCH::SUM\n";#NIGE

    #BLAST
    $self->{'id'}     = '';
    $self->{'desc'}   = '';
    $self->{'length'} = '';

    #extract fields into self
    my $fields = $self->get_parent(3)->get_record('HEADER')->{'fields'};
    $extract_fields->($text->next_line, $fields, $SUM_FIELDS, $self);
    
    $self->{'id'} = NPB::Parse::Record::clean_identifier($self->{'id'});

    $self;#->examine;
}


###########################################################################
package NPB::Parse::Format::BLAST2_OF7::SEARCH::MATCH::ALN;

use vars qw(@ISA);
use NPB::Parse::Regexps;

@ISA = qw(NPB::Parse::Format::BLAST2::SEARCH::MATCH::ALN);

sub new {
    my $type = shift;
    if (@_ < 2) {
	#at least two args, ($offset, $bytes are optional).
	NPB::Message::die($type, "new() invalid argument list (@_)");
    }
    my ($parent, $text, $offset, $bytes) = (@_, -1, -1);
    my ($self, $line, $record);

    $self = new NPB::Parse::Record($type, $parent, $text, $offset, $bytes);
    $text = new NPB::Parse::Record_Stream($self);

    #warn "SEARCH::MATCH::ALN\n";#NIGE

    #BLAST
    $self->{'query'}        = '';
    $self->{'align'}        = '';
    $self->{'sbjct'}        = '';
    $self->{'query_orient'} = '';
    $self->{'query_start'}  = '';
    $self->{'query_stop'}   = '';
    $self->{'sbjct_orient'} = '';
    $self->{'sbjct_start'}  = '';
    $self->{'sbjct_stop'}   = '';

    #BLAST2
    $self->{'bits'}         = '';
    $self->{'score'}        = '';
    $self->{'n'}            = '';
    $self->{'expect'}       = '';
    $self->{'id_fraction'}  = '';
    $self->{'id_percent'}   = '';
    $self->{'pos_fraction'} = '';
    $self->{'pos_percent'}  = '';
    $self->{'gap_fraction'} = '';
    $self->{'gap_percent'}  = '';
    #frame?

    #extract fields into self
    my $fields = $self->get_parent(3)->get_record('HEADER')->{'fields'};
    $extract_fields->($text->next_line, $fields, $ALN_FIELDS, $self);
    
    #use sequence numbering to get orientations
    $self->{'query_orient'} =
        $self->{'query_start'} > $self->{'query_stop'} ? '-' : '+';
    $self->{'sbjct_orient'} =
        $self->{'sbjct_start'} > $self->{'sbjct_stop'} ? '-' : '+';

    $self;#->examine;
}


###########################################################################
1;
