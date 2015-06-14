# -*- perl -*-
# Copyright (C) 1996-2015 Nigel P. Brown
# $Id: FASTA.pm,v 1.16 2013/09/09 21:31:04 npb Exp $

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

use vars qw(@ISA);
use Bio::MView::Build::Search;
use Bio::MView::Build::Row;
use strict;

@ISA = qw(Bio::MView::Build::Search);

#the name of the underlying NPB::Parse::Format parser
sub parser { 'FASTA' }

my %Known_Parameter = 
    (
     #name        => [ format,             default ]
     'minopt'     => [ '\d+',              undef   ],

     #GCG FASTA (version 2)
     'strand'     => [ [],         	   undef   ],
	
##   'frames'     => [ [],                 undef   ],
    );

sub initialise_parameters {
    my $self = shift;
    $self->SUPER::initialise_parameters;
    $self->SUPER::initialise_parameters(\%Known_Parameter);
    $self->reset_strand;
##  $self->reset_frame;
}

sub set_parameters {
    my $self = shift;
    $self->SUPER::set_parameters(@_);
    $self->SUPER::set_parameters(\%Known_Parameter, @_);
    $self->reset_strand;
##  $self->reset_frame;
}

sub new {
    shift;    #discard type
    my $self = new Bio::MView::Build::Search(@_);
    my ($type, $p, $v, $file);

    #determine the real type from the underlying parser
    ($p, $v) = (lc $self->{'entry'}->{'format'},$self->{'entry'}->{'version'});

    $type = "Bio::MView::Build::Format::FASTA$v";
    ($file = $type) =~ s/::/\//g;
    require "$file.pm";
    
    $type .= "::$p";
    bless $self, $type;

    $self->initialise;
}

#initialise parse iteration scheduler variable(s). just do them all at once
#and don't bother overriding with specific methods. likewise the scheduler
#routines can all be defined here.
sub initialise {
    my $self = shift;
    #may define strand orientation and reading frame filters later

    #GCG FASTA strand orientation
    $self->{'strand_list'} = [ qw(+ -) ];    #strand orientations
    $self->{'do_strand'}   = undef;          #list of required strand
    $self->{'strand_idx'}  = undef;          #current index into 'do_strand'

##  #FASTA reading frame
##  $self->{'frame_list'}  = [ qw(f r) ];    #reading frames
##  $self->{'do_frames'}   = undef;          #list of required frames
##  $self->{'frame_idx'}   = undef;          #current index into 'do_frames'
##  $self->{'frame_mode'}  = undef;          #output format?

    $self->initialise_parameters;      #other parameters done last
   
    $self;
}

sub strand   { $_[0]->{'do_strand'}->[$_[0]->{'strand_idx'}-1] }
##sub frame   { $_[0]->{'do_frames'}->[$_[0]->{'frame_idx'}-1] }

sub reset_strand {
    my $self = shift;
    #warn "strand: [@{$self->{'strand'}}]\n";
    $self->{'do_strand'} = $self->reset_schedule($self->{'strand_list'},
						 $self->{'strand'});
}

##sub reset_frame {
##    my $self = shift;
##
##    #initialise scheduler loops and loop counters
##    if (! defined $self->{'do_frames'}) {
##	if (@{$self->{'frames'}} and $self->{'frames'}->[0] eq '*') {
##	    #do all frames, broken out by frame
##	    $self->{'do_frames'}  = [ @{$self->{'frame_list'}} ];
##	    $self->{'frame_mode'} = 'split';
##	} elsif (@{$self->{'frames'}}) {
##	    #explicit frame range
##	    $self->{'do_frames'}  = [ @{$self->{'frames'}} ];
##	    $self->{'frame_mode'} = 'split';
##	} else {
##	    #default: empty list  - do all frames in one pass
##	    $self->{'do_frames'}  = [ @{$self->{'frame_list'}} ];
##	    $self->{'frame_mode'} = 'flat';
##	}
##    }
##}

sub next_strand {
    my $self = shift;

    #first pass?
    $self->{'strand_idx'} = 0    unless defined $self->{'strand_idx'};
    
    #normal pass: post-increment strand counter
    if ($self->{'strand_idx'} < @{$self->{'do_strand'}}) {
	return $self->{'do_strand'}->[$self->{'strand_idx'}++];
    }

    #finished loop
    $self->{'strand_idx'} = undef;
}

##sub next_frame {
##    my $self = shift;
##
##    #first pass?
##    $self->{'frame_idx'} = 0    unless defined $self->{'frame_idx'};
##    
##    #normal pass: post-increment frame counter
##    if ($self->{'frame_idx'} < @{$self->{'do_frames'}}) {
##	return $self->{'do_frames'}->[$self->{'frame_idx'}++];
##    }
##
##    #finished loop
##    $self->{'frame_idx'} = undef;
##}
##
##sub schedule_by_frame {
##    my ($self, $next) = shift;
##    if (defined ($next = $self->next_frame)) {
##	return $next;
##    }
##    return undef;           #tell parser
##}

sub schedule_by_strand {
    my ($self, $next) = shift;
    if (defined ($next = $self->next_strand)) {
	return $next;
    }
    return undef;           #tell parser
}

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
        #strip query gaps marked as '-'
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

use vars qw(@ISA);
use Bio::MView::Build;
use strict;

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

#convert nucleotide positions to a relative amino acid scale
sub translate_range {
    my ($self, $fm, $to) = @_;
    return (int(($fm+2)/3), int($to/3))   if $fm < $to;  #orientation +
    return (int($fm/3),  int(($to+2)/3))  if $fm > $to;  #orientation -
    die "translate_range: from == to  $fm, $to";
}

#based on assemble_blastn() fragment processing
sub assemble_fasta {
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

sub assemble_fastx {
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

sub assemble_tfasta {
    my $self = shift;

    #query:     protein
    #database:  dna
    #alignment: protein x protein
    #query numbered in protein units
    #sbjct numbered in dna units
    #query orientation: +
    #sbjct orientation: +-

    #processing steps:
    #  (1) assemble frags
    
    $self->SUPER::assemble(@_);
}

sub new {
    my $type = shift;
    my ($num, $id, $desc, $initn, $init1, $opt) = @_;
    my $self = new Bio::MView::Build::Row($num, $id, $desc);
    $self->{'initn'} = $initn;
    $self->{'init1'} = $init1;
    $self->{'opt'}   = $opt;
    bless $self, $type;
}

sub data  {
    return sprintf("%5s %5s %5s", 'initn', 'init1', 'opt') unless $_[0]->num;
    sprintf("%5s %5s %5s", $_[0]->{'initn'}, $_[0]->{'init1'}, $_[0]->{'opt'});
}

sub rdb_info {
    my ($self, $mode) = @_;
    return ($self->{'initn'}, $self->{'init1'}, $self->{'opt'})
	if $mode eq 'data';
    return ('initn', 'init1', 'opt')  if $mode eq 'attr';
    return ('5N', '5N', '5N')  if $mode eq 'form';
}


###########################################################################
1;
