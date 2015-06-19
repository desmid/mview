# -*- perl -*-
# Copyright (C) 1996-2015 Nigel P. Brown
# $Id: FASTA.pm,v 1.18 2015/06/14 20:26:51 npb Exp $

###########################################################################
#
# FASTA 1, 2, 3
#
# The fasta programs can produce different gapped alignments for the same
# database hit. These have the same identifier in the RANK section. Here,
# they are resolved by building a (unique?) key from identifier, initn, and
# init1. This Build doesn't attempt to merge such fragments as done for
# gapped BLAST, ie., each FASTA alignment is taken as a complete solution.
#
###########################################################################
package Bio::MView::Build::Format::FASTA;

use Bio::MView::Build::Search;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Search);

#the name of the underlying NPB::Parse::Format parser
sub parser { 'FASTA' }

my %Known_Parameters = 
    (
     #name        => [ format  default ]
     'minopt'     => [ '\d+',  undef   ],

     #GCG FASTA (version 2)
     'strand'     => [ [],     undef   ],
    );

#tell the parent
sub known_parameters { \%Known_Parameters }

#our own constructor since this is the entry point for different subtypes
sub new {
    shift;  #discard our own type
    my $self = new Bio::MView::Build::Search(@_);
    my ($type, $p, $v, $file);

    #determine the real type from the underlying parser
    ($p, $v) = (lc $self->{'entry'}->{'format'}, $self->{'entry'}->{'version'});

    $type = "Bio::MView::Build::Format::FASTA$v";
    ($file = $type) =~ s/::/\//g;
    require "$file.pm";

    $type .= "::$p";
    bless $self, $type;

    $self->initialise_parameters;
    $self->initialise_child;

    $self;
}

#called by the constructor
sub initialise_child {
    my $self = shift;
    #warn "initialise_child\n";
    #schedule by strand orientation
    $self->{scheduler} = new Bio::MView::Build::Scheduler([qw(+ -)]);
    $self;
}

#called on each iteration
sub reset_child {
    my $self = shift;
    #warn "reset_child [@{$self->{'strand'}}]\n";
    $self->{scheduler}->filter($self->{'strand'});
    $self;
}

#current strand being processed
sub strand { $_[0]->{scheduler}->item }

#compare argument with current strand
sub use_strand { $_[0]->{scheduler}->use_item($_[1]) }

#row filter
sub use_row {
    my ($self, $rank, $nid, $sid, $opt) = @_;
    my $use = $self->SUPER::use_row($rank, $nid, $sid);
    $use = $self->use_frag($opt)  if $use == 1;
    #warn "FASTA::use_row($rank, $nid, $sid, $opt) = $use\n";
    return $use;
}

#minopt filter
sub use_frag {
    my ($self, $opt) = @_;
    return 0  if defined $self->{'minopt'} and $opt < $self->{'minopt'};
    return 1;
}

#remove query and hit columns at gaps and frameshifts in the query sequence;
#downcase the bounding hit symbols in the hit sequence thus affected and,
#for frameshifts, downcase the bounding symbols in the query too. remove
#leading/trailing space from the query.
sub strip_query_gaps {
    my ($self, $query, $sbjct, $leader, $trailer) = @_;

    my $gapper = sub {
        my ($query, $sbjct, $char, $doquery) = @_;

        while ( (my $i = index($$query, $char)) >= 0 ) {

            #downcase preceding symbol
            if (defined substr($$query, $i-1, 1)) {
                substr($$query, $i-1, 1) = lc substr($$query, $i-1, 1)
                    if $doquery;
                substr($$sbjct, $i-1, 1) = lc substr($$sbjct, $i-1, 1);
            }

            #consume more of same in query and hit
            while (substr($$query, $i, 1) eq $char) {
                substr($$query, $i, 1) = '';
                substr($$sbjct, $i, 1) = '';
            }

            #downcase succeeding symbol
            if (defined substr($$query, $i, 1)) {
                substr($$query, $i, 1) = lc substr($$query, $i, 1)
                    if $doquery;
                substr($$sbjct, $i, 1) = lc substr($$sbjct, $i, 1);
            }
        }
    };
    
    #warn "sqg(in  q)=[$$query]\n";
    #warn "sqg(in  h)=[$$sbjct]\n";

    &$gapper($query, $sbjct, '-',  0);  #mark gaps in sbjct only
    &$gapper($query, $sbjct, '/',  1);  #mark frameshifts in both
    &$gapper($query, $sbjct, '\\', 1);  #mark frameshifts in both

    #strip query terminal white space
    $trailer = length($$query) - $leader - $trailer;
    $$query  = substr($$query, $leader, $trailer);
    $$sbjct  = substr($$sbjct, $leader, $trailer);
	
    #replace sbjct leading/trailing white space with gaps
    $$sbjct =~ s/\s/-/g;

    #warn "sqg(out q)=[$$query]\n";
    #warn "sqg(out h)=[$$sbjct]\n";

    $self;
}


###########################################################################
###########################################################################
package Bio::MView::Build::Row::FASTA;

use Bio::MView::Build::Row;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row);

sub posn1 {
    my $qfm = $_[0]->{'seq'}->fromlabel1;
    my $qto = $_[0]->{'seq'}->tolabel1;
    return "$qfm:$qto"  if defined $qfm and defined $qto;
    return '';
}

sub posn2 {
    my $hfm = $_[0]->{'seq'}->fromlabel2;
    my $hto = $_[0]->{'seq'}->tolabel2;
    return "$hfm:$hto"  if defined $hfm and defined $hto;
    return '';
}

#based on assemble_blastn() fragment processing
sub assemble {
    my $self = shift;

    #query:     protein|dna
    #database:  protein|dna
    #alignment: protein|dna x protein|dna
    #query numbered in protein|dna units
    #sbjct numbered in protein|dna units
    #query orientation: +/-
    #sbjct orientation: +/-

    #processing steps:
    #if query -
    #  (1) reverse assembly position numbering
    #  (2) reverse each frag
    #  (3) assemble frags
    #  (4) reverse assembly
    #if query +
    #  (1) assemble frags

    $self->SUPER::assemble(@_);
}

sub new {
    my $type = shift;
    my ($num, $id, $desc) = (shift, shift, shift);

    my $self = new Bio::MView::Build::Row($num, $id, $desc);

    bless $self, $type;

    $self->save_info(@_);
    $self;
}


###########################################################################
package Bio::MView::Build::Row::FASTX;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA);

sub range {
    my $self = shift;
    my ($lo, $hi) = $self->SUPER::range;
    $self->translate_range($lo, $hi);
}

sub assemble {
    my $self = shift;

    #query:     dna
    #database:  protein
    #alignment: protein x protein
    #query numbered in dna units
    #sbjct numbered in protein units
    #query orientation: +-
    #sbjct orientation: +

    #processing steps:
    #if query -
    #  (1) convert to protein units
    #  (2) reverse assembly position numbering
    #  (3) reverse each frag
    #  (4) assemble frags
    #  (5) reverse assembly
    #if query +
    #  (1) convert to protein units
    #  (2) assemble frags
    
    foreach my $frag (@{$self->{'frag'}}) {
        ($frag->[1], $frag->[2]) =
            $self->translate_range($frag->[1], $frag->[2]);
    }
    $self->SUPER::assemble(@_);
}


###########################################################################
1;
