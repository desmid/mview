# Copyright (C) 1998-2006 Nigel P. Brown
# $Id: MULTAS.pm,v 1.12 2015/06/14 17:09:04 npb Exp $

###########################################################################
package Bio::MView::Build::Format::MULTAS;

use vars qw(@ISA);
use Bio::MView::Build::Align;
use Bio::MView::Build::Row;
use strict;

@ISA = qw(Bio::MView::Build::Align);

#the name of the underlying NPB::Parse::Format parser
sub parser { 'MULTAS' }

my %Known_Parameter = 
    (
     #name        => [ format,               default ]
     'block'      => [ [],                   undef   ],
    );

sub initialise_parameters {
    my $self = shift;
    $self->SUPER::initialise_parameters;
    $self->SUPER::initialise_parameters(\%Known_Parameter);

    $self->reset_block;
}

sub set_parameters {
    my $self = shift;
    $self->SUPER::set_parameters(@_);
    $self->SUPER::set_parameters(\%Known_Parameter, @_);

    $self->reset_block;
}

sub new {
    my $type = shift;
    my $self = new Bio::MView::Build::Align(@_);

    #MULTAL/MULTAS ordinal block number: counted 1..N whereas the actual
    #block has its own 'number' field which is reported by subheader().
    $self->{'do_block'}  = undef;    #required list of block numbers
    $self->{'block_idx'} = undef;    #current index into 'do_block'
    $self->{'block_ptr'} = undef;    #current block parse object ref

    bless $self, $type;
}

sub block   { $_[0]->{'do_block'}->[$_[0]->{'block_idx'}-1] }

sub reset_block {
    my $self = shift;
    #initialise scheduler loops and loop counters
    #warn "blocks/1: [@{$self->{'block'}}]\n";

    my $last = $self->{'entry'}->count(qw(BLOCK));

    $self->{'do_block'} = $self->reset_schedule([1..$last], $self->{'block'});

    if (defined $self->{'block_ptr'}) {
	#flag previous block parse for garbage collection
	$self->{'block_ptr'}->free;
	$self->{'block_ptr'} = undef;
    }
}

sub next_block {
    my $self = shift;

    #first pass?
    $self->{'block_idx'} = 0    unless defined $self->{'block_idx'};
    
    #normal pass: post-increment block counter
    if ($self->{'block_idx'} < @{$self->{'do_block'}}) {
	return $self->{'do_block'}->[$self->{'block_idx'}++];
    }

    #finished loop
    $self->{'block_idx'} = undef;
}

sub schedule_by_block {
    my ($self, $next) = shift;

    if (defined ($next = $self->next_block)) {
	return $next;
    }
    return undef;           #tell parser    
}

sub subheader {
    my ($self, $quiet) = (@_, 0);
    my $s = '';
    return $s    if $quiet;
    $s .= "Block: " . $self->block . " (rank=$self->{'block_ptr'}->{'number'})\n";
    $s;    
}

sub parse {
    my $self = shift;
    my ($rank, $use, $list, $align, $id, $desc, $seq, @hit) = ();

    return  unless defined $self->schedule_by_block;

    $self->{'block_ptr'} = $self->{'entry'}->parse("BLOCK[@{[$self->block]}]");

    #block doesn't exist?
    return unless defined $self->{'block_ptr'};

    $list  = $self->{'block_ptr'}->parse(qw(LIST));
    $align = $self->{'block_ptr'}->parse(qw(ALIGNMENT));
    
    if ($list->{'count'} != $align->{'count'}) {
	die "${self}::parser() different alignment and identifier counts\n";
    }
    
    for ($rank=0; $rank < $list->{'count'}; $rank++) {
	
	$id   = $list->{'hit'}->[$rank]->{'id'};
	$desc = $list->{'hit'}->[$rank]->{'desc'};
	$seq  = $align->{'seq'}->[$rank];

	#check row wanted, by rank OR identifier OR row count limit
	last  if ($use = $self->use_row($rank+1, $rank+1, $id)) < 0;
	next  unless $use;

	#warn "KEEP: ($rank,$id)\n";

	push @hit, new Bio::MView::Build::Row($rank+1, $id, $desc, $seq);
    }

    #map { $_->print } @hit;
    
    return \@hit;
}


###########################################################################
1;
