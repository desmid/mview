# Copyright (C) 2013-2015 Nigel P. Brown
# $Id: MAF.pm,v 1.1 2013/12/01 18:56:16 npb Exp $

###########################################################################
package Bio::MView::Build::Row::MAF;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row);

sub new {
    my $type = shift;
    my ($num, $id, $desc, $seq, $start, $size, $strand, $srcsize) = @_;
    my $self = new Bio::MView::Build::Row($num, $id, $desc, $seq);
    $self->{'start'}   = $start;
    $self->{'size'}    = $size;
    $self->{'strand'}  = $strand;
    $self->{'srcsize'} = $srcsize;
    bless $self, $type;
}

sub head {
    sprintf("%8s %8s %6s %10s", 'start', 'size', 'strand', 'srcsize');
}

sub pcid { $_[0]->SUPER::pcid_std }

sub data {
    return sprintf("%8s %8s %6s %10s",
		   $_[0]->{'start'}, $_[0]->{'size'}, $_[0]->{'strand'},
		   $_[0]->{'srcsize'})
	if $_[0]->num;
    $_[0]->head;
}

sub rdb_info {
    my ($self, $mode) = @_;
    return ($self->{'start'}, $self->{'size'}, $self->{'strand'},
	    $self->{'srcsize'})  if $mode eq 'data';
    return ('start', 'size', 'strand', 'srcsize')  if $mode eq 'attr';
    return ('8N', '8N', '6S', '10S')  if $mode eq 'form';
}


###########################################################################
package Bio::MView::Build::Format::MAF;

use vars qw(@ISA %Known_Parameter);
use Bio::MView::Build::Align;
use Bio::MView::Build::Row;
use strict;

@ISA = qw(Bio::MView::Build::Align);

#the name of the underlying NPB::Parse::Format parser
sub parser { 'MAF' }

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

    #MAF ordinal block number: counted 1..N whereas the actual
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
    return $s  if $quiet;
    $s .= "Block: " . $self->block;
    $s .= "  score: $self->{'block_ptr'}->{'score'}"
	if $self->{'block_ptr'}->{'score'} ne '';
    $s .= "  pass: $self->{'block_ptr'}->{'pass'}"
	if $self->{'block_ptr'}->{'pass'} ne '';
    $s .= "\n";
}

sub parse {
    my $self = shift;
    my ($rank, $use, $desc, $seq, @hit) = (0);

    return  unless defined $self->schedule_by_block;

    $self->{'block_ptr'} = $self->{'entry'}->parse("BLOCK[@{[$self->block]}]");

    #block doesn't exist?
    return unless defined $self->{'block_ptr'};

    foreach my $row (@{$self->{'block_ptr'}->{'row'}}) {

	$rank++;

	#check row wanted, by rank OR identifier OR row count limit
	last  if ($use = $self->use_row($rank, $rank, $row->{'id'})) < 0;
	next  unless $use;

	#warn "KEEP: ($rank,$row->{'id'})\n";

	push @hit, new Bio::MView::Build::Row::MAF($rank,
						   $row->{'id'},
						   '',
						   $row->{'seq'},
						   $row->{'start'},
						   $row->{'size'},
						   $row->{'strand'},
						   $row->{'srcsize'},
	    );
    }

    #map { $_->print } @hit;
    
    return \@hit;
}


###########################################################################
1;
