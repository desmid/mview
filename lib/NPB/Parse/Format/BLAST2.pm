# -*- perl -*-
# Copyright (C) 1996-2011 Nigel P. Brown
# $Id: BLAST2.pm,v 1.16 2013/09/09 21:31:04 npb Exp $

###########################################################################
#
# Base classes for NCBI BLAST2 family.
#
# Handles: BLAST 2.0.x
#
# BLAST (NCBI version 2) iterated searching uses 3 main record types:
#
#   HEADER        the header text
#   SEARCH        passes of the search engine
#   PARAMETERS    the trailer
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
package NPB::Parse::Format::BLAST2;

use NPB::Parse::Format::BLAST;
use NPB::Parse::Regexps;

use strict;

use vars qw(@ISA

	    @VERSIONS

	    $NULL

	    $ENTRY_START
	    $ENTRY_END

            $WARNING_START
            $WARNING_END

            $WARNINGS_START
            $WARNINGS_END

            $PARAMETERS_START
            $PARAMETERS_END

            $MATCH_START
            $MATCH_END

            $RANK_START
            $RANK_MATCH
            $RANK_END
            $RANK_NONE

            $HEADER_START
            $HEADER_END

            $SEARCH_START
            $SEARCH_END

            $SCORE_START
            $SCORE_END
	   );

@ISA   = qw(NPB::Parse::Format::BLAST);

@VERSIONS = ( 
	     '2' => [
		     'BLASTP',
		     'BLASTN',
		     'BLASTX',
		     'TBLASTN',
		     'TBLASTX',
		    ],
	    );

$NULL  = '^\s*$';#for emacs';

$ENTRY_START      = '(?:'
    . '^BLASTP'
    . '|'
    . '^BLASTN'
    . '|'
    . '^BLASTX'
    . '|'
    . '^TBLASTN'
    . '|'
    . '^TBLASTX'
    . ')';
$ENTRY_END        = '^  WARNINGS\s+ISSUED:';    #blast1 behavior, but blast2?


$SEARCH_START     = "(?:^Searching|^\\s+High\\s+E|^\\s+Score\\s+E)";
$SEARCH_END       = "(?:$SEARCH_START|  Database|CPU time:|^Lambda +)";

$WARNING_START    = '^WARNING';
$WARNING_END      = "(?:done|$NULL)";    #'done' keyword in phi-blast SEARCH block

$WARNINGS_START   = '^WARNINGS\s+ISSUED:';
$WARNINGS_END     = $NULL;

$PARAMETERS_START = "^(?:  Database|CPU time:|^Lambda +)";
$PARAMETERS_END   = "(?:$WARNINGS_START|$ENTRY_START)";

#$MATCH_START	  = '(?:^>|^[^\|:\s]+\|)';  #fails for some long query text
$MATCH_START	  = '^>';                   #fails for web pages
$MATCH_END          = "(?:$MATCH_START|$WARNING_START|$SEARCH_END)";

#$RANK_START       = $SEARCH_START;
$RANK_START       = "(?:^\\s+High\\s+E|^\\s+Score\\s+E)";
$RANK_MATCH	  = "(?:$NULL|^\\s+High|^\\s+Score|^\\s*Sequences|^\\s*CONVERGED|No hits found|^[^>].*$RX_Uint\\s+$RX_Ureal|$NPB::Parse::Format::BLAST::GCG_JUNK)";
$RANK_END         = "(?:$MATCH_START|$SEARCH_END)"; #ignore warnings
$RANK_NONE        = '^\s*\*\*\* NONE';

$HEADER_START     = $ENTRY_START;
$HEADER_END       = "(?:$SEARCH_START|$WARNING_START|$RANK_START|$MATCH_START|$PARAMETERS_START)";

$SCORE_START      = '^\s{0,1}Score';  #exactly 0 or 1 leading spaces
$SCORE_END        = "(?:$SCORE_START|$MATCH_END)";


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

	#Header lines
	if ($line =~ /$HEADER_START/o) {
	    $text->scan_until($HEADER_END, 'HEADER');
	    next;
	}

	#Search lines
	if ($line =~ /$SEARCH_START/o) {
	    if ($line =~ /^Searching/) {
		#can't scan for all fields of $SEARCH_START unfortunately
		$text->scan_until("(?:^Searching|  Database|CPU time:^Lambda +)", 'SEARCH');
	    } else {
		#'Searching' keyword stripped by web server
		$text->scan_until($SEARCH_END, 'SEARCH');
	    }
	    next;
	}

	#Parameter lines
	if ($line =~ /$PARAMETERS_START/o) {       	      
	    $text->scan_until($PARAMETERS_END, 'PARAMETERS');
	    next;			       	      
	}				       	      
	
	#WARNINGS ISSUED line: ignore
	next    if $line =~ /$WARNINGS_START/o;

	#default
	$self->warn("unknown field: $line");
    }

    $self;#->examine;
}

#BLAST2 or PSI-BLAST write  'e10' instead of '1e10', so fix this.
sub fix_expect {
    my $e = shift;
    $e =~ s/^e/1e/;
    $e;
}


###########################################################################
package NPB::Parse::Format::BLAST2::SEARCH;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Record);

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

    while (defined ($line = $text->next_line)) {

	#Rank lines
	if ($line =~ /$NPB::Parse::Format::BLAST2::RANK_START/o) {       	      
	    #$text->scan_while($NPB::Parse::Format::BLAST2::RANK_MATCH, 'RANK');
	    $text->scan_until($NPB::Parse::Format::BLAST2::RANK_END, 'RANK');
	    next;			       	      
	}				       	      
	
	#Hit lines
	if ($line =~ /$NPB::Parse::Format::BLAST2::MATCH_START/o) {       	      
	    $text->scan_until($NPB::Parse::Format::BLAST2::MATCH_END, 'MATCH');
	    next;			       	      
	}				       	      
	
	#WARNING lines
	if ($line =~ /$NPB::Parse::Format::BLAST2::WARNING_START/o) {       	      
	    $text->scan_until($NPB::Parse::Format::BLAST2::WARNING_END, 'WARNING');
	    next;			       	      
	}				       	      
	
	#default: ignore any other text in SEARCH block
    }

    $self;#->examine;
}


###########################################################################
package NPB::Parse::Format::BLAST2::SEARCH::RANK;

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

    #column headers
    #$self->{'header'} = $text->scan_lines(4);    #<= 2.0.5
    #$self->{'header'} = $text->scan_lines(6);    #2.0.6
    $self->{'header'} = $text->scan_until_inclusive('Value(?:\s*N)?\s*$');#'

    #ranked search hits 
    $self->{'hit'}    = [];
    
    while (defined ($line = $text->next_line)) {
	
	next    if $line =~ /^Sequences used in model and found again:/;
	next    if $line =~ /^Sequences not found previously or not previously below threshold:/;
	next    if $line =~ /^CONVERGED!/;
	next    if $line =~ /^Significant /;    #PHI-BLAST

	#blank line or empty record: ignore
        next    if $line =~ /$NPB::Parse::Format::BLAST2::NULL/o;

	#GCG annotation: ignore
        next    if $line =~ /$NPB::Parse::Format::BLAST::GCG_JUNK/o;

	#NCBI web server HTML text-only output: ignore
	next    if $line =~ /^\s*-+\s*$/;        #dashed line
	next    if $line =~ /^\s+Alignments/;    #text

	#empty ranking: done
        last    if $line =~ /$NPB::Parse::Format::BLAST2::RANK_NONE/o;

	chomp $line;

	my $tmp = {};

	#examine suffix
	if ($line =~ /
            \s+
	    ($RX_Ureal)                #bits
	    \s+
	    ($RX_Ureal)                #E value
            (?:\s+($RX_Uint))?         #N (ungapped blast only)
	    \s*$
	    /xo) {

	    $self->test_args($line, $1, $2);
	    
	    $tmp->{'bits'}   = $1;
	    $tmp->{'expect'} = NPB::Parse::Format::BLAST2::fix_expect($2);
	    $tmp->{'n'}      = (defined $3 ? $3 : 0);

	    #examine prefix
	    if ($` =~ /^\s*
		(\S+)                  #id
		\s*
		\!?                    #GCG junk
		\s*
		(.*)?                  #summary
		/xo) {
		    
		$self->test_args($line, $1);    #ignore $2
		
		$tmp->{'id'} = 
		    NPB::Parse::Record::clean_identifier($1);
		$tmp->{'summary'} =
		    NPB::Parse::Record::strip_trailing_space($2);
		
	    } else {
		$self->warn("unknown field: $line");
	    }
	    
	    push @{$self->{'hit'}}, $tmp;
	    
	    next;
	}
	
	#default
	$self->warn("unknown field: $line");
    }
    $self;
}


###########################################################################
package NPB::Parse::Format::BLAST2::SEARCH::MATCH::ALN;

use vars qw(@ISA);
use NPB::Parse::Regexps;

@ISA = qw(NPB::Parse::Format::BLAST::MATCH::ALN);

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

    #Score line
    $line = $text->next_line;

    if ($line =~ /^\s*
	Score\s*=\s*
	($RX_Ureal)                 #bits
	\s+bits\s+
	\(($RX_Ureal)\),            #score
	\s+
	Expect(?:\((\d+)\))?\s*=\s*
	($RX_Ureal)                 #expectation
	/xo) {
	
	$self->test_args($line, $1, $2, $4);

	(
	 $self->{'bits'},
	 $self->{'score'},
	 $self->{'n'},              #substitute 1 unless $3
	 $self->{'expect'},
	) = ($1, $2, defined $3?$3:1, NPB::Parse::Format::BLAST2::fix_expect($4));

    } else {
	$self->warn("expecting 'Score' line: $line");
    }
    
    #Identities line
    $line = $text->next_line;

    if ($line =~ /^\s*
	Identities\s*=\s*
	(\d+\/\d+)                  #identities fraction
	\s+			    
	\((\d+)%\)                  #identities percentage
	(?:                         #not present in (some?) BLASTN 2.0.9
	,\s+			    
	Positives\s*=\s*	    
	(\d+\/\d+)                  #positives fraction
	\s+			    
	\((\d+)%\)                  #positives percentage
	(?:,\s*			    #not always present
	 Gaps\s*=\s*		    
	 (\d+\/\d+)                 #gaps fraction
	 \s+			    
	 \((\d+)%\)                 #gaps percentage
	)?
	)?
	/xo) {
	
	$self->test_args($line, $1, $2);

	(
	 $self->{'id_fraction'},
	 $self->{'id_percent'},
	 $self->{'pos_fraction'},
	 $self->{'pos_percent'},
	 $self->{'gap_fraction'},
	 $self->{'gap_percent'},
	) = ($1, $2, defined $3?$3:'', defined $4?$4:0, defined $5?$5:'', defined $6?$6:0);
	
    } else {
	$self->warn("expecting 'Identities' line: $line");
    }
    
    #optional (Strand|Frame) line
    $line = $text->next_line;

    #Strand orientation (BLASTN)
    if ($line =~ /^\s*Strand\s*=/) {
	#discard
    }

    #Single frame shift (BLASTX, TBLASTN)
    if ($line =~ /^\s*Frame\s*=\s+(\S+)\s*$/) {
	$self->{'frame1'} = $1;
    }

    #Double frame shift (TBLASTX 2.0.9)
    if ($line =~ /^\s*Frame\s*=\s+(\S+)\s*\/\s*(\S+)/) {
	$self->{'frame1'} = $1;
	$self->{'frame2'} = $2;
    }

    $self->parse_alignment($text);

    $self;
}

sub print {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    NPB::Parse::Record::print $self, $indent;
    printf "$x%20s -> %s\n",   'bits',           $self->{'bits'};
    printf "$x%20s -> %s\n",   'score',          $self->{'score'};
    printf "$x%20s -> %s\n",   'n',              $self->{'n'};
    printf "$x%20s -> %s\n",   'expect',         $self->{'expect'};
    printf "$x%20s -> %s\n",   'id_fraction',    $self->{'id_fraction'};
    printf "$x%20s -> %s\n",   'id_percent',     $self->{'id_percent'};
    printf "$x%20s -> %s\n",   'pos_fraction',   $self->{'pos_fraction'};
    printf "$x%20s -> %s\n",   'pos_percent',    $self->{'pos_percent'};
    printf "$x%20s -> %s\n",   'gap_fraction',   $self->{'gap_fraction'};
    printf "$x%20s -> %s\n",   'gap_percent',    $self->{'gap_percent'};
    $self->SUPER::print($indent);
}


###########################################################################
1;
