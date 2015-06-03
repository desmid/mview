# -*- perl -*-
# Copyright (C) 2013 Nigel P. Brown
# $Id: fastm.pm,v 1.2 2013/10/20 22:01:51 npb Exp $

###########################################################################
package NPB::Parse::Format::FASTA3X::fastm;

use NPB::Parse::Format::FASTA3X;
use NPB::Parse::Format::FASTA3X::fasta;
use strict;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::FASTA3X);

sub new { my $self=shift; $self->SUPER::new(@_) }


###########################################################################
package NPB::Parse::Format::FASTA3X::fastm::HEADER;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::FASTA3X::fasta::HEADER);


###########################################################################
package NPB::Parse::Format::FASTA3X::fastm::RANK;

use vars qw(@ISA);

@ISA   = qw(NPB::Parse::Format::FASTA::RANK);

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

    #ranked search hits
    while (defined ($line = $text->next_line)) {
	
	next    if $line =~ /$NPB::Parse::Format::FASTA3X::RANK_START/o;

	#fasta3X behaviour
	if ($line =~ /^
	    \s*
	    (\S+)                #id
	    \s+
	    (.*)                 #description (may be empty)
	    \s+
	    (?:\[[^]]+\])?       #don't know - reported by rls@ebi.ac.uk
	    \s*
	    \(\s*(\d+)\)         #aa
	    \s*
	    (?:\[(\S)\])?        #frame
	    \s+
	    (\d+)                #initn
	    \s+
	    (\d+)                #init1
	    \s+
	    (\S+)                #bits
	    \s+
	    (\S+)                #E(205044)
	    \s+
	    (\S+)                #sn
	    \s+
	    (\S+)?               #sl
	    \s*
	    $/xo) {

	    $self->test_args($line, $1, $3, $5,$6,$7); #not $2,$4
	    
	    push(@{$self->{'hit'}},
		 { 
		  'id'     => NPB::Parse::Record::clean_identifier($1),
		  'desc'   => $2,
		  'length' => $3,
		  'frame'  => NPB::Parse::Format::FASTA::parse_frame($4),
		  'initn'  => $5,
		  'init1'  => $6,
		  'bits'   => $7,
		  'expect' => $8,
		  'sn'     => $9,
		  'sl'     => $10,
		 });
	    next;
	}
     
   	#blank line or empty record: ignore
	next    if $line =~ /$NPB::Parse::Format::FASTA3X::NULL/o;
	 
	#default
	$self->warn("unknown field: $line");
    }
    $self;
}


###########################################################################
package NPB::Parse::Format::FASTA3X::fastm::TRAILER;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::FASTA3X::fasta::TRAILER);


###########################################################################
package NPB::Parse::Format::FASTA3X::fastm::MATCH;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::FASTA3X::fasta::MATCH);


###########################################################################
package NPB::Parse::Format::FASTA3X::fastm::MATCH::SUM;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::FASTA3X::fasta::MATCH::SUM);


###########################################################################
package NPB::Parse::Format::FASTA3X::fastm::MATCH::ALN;

use vars qw(@ISA);

@ISA   = qw(NPB::Parse::Format::FASTA3X::MATCH::ALN);

#well, although this a S-W alignment, the sequence range numbers look more
#like those of a global/global alignment: query sequence range is complete;
#sbjct depends on it
sub get_align_padding {
    my ($self, $query, $align) = @_;
    my ($leader, $trailer) = (0, 0);
    return ($leader, $trailer);
}


###########################################################################
1;
