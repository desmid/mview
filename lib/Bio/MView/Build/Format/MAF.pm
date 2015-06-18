# Copyright (C) 2013-2015 Nigel P. Brown
# $Id: MAF.pm,v 1.2 2015/06/14 17:09:04 npb Exp $

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

use Bio::MView::Build::Align;
use Bio::MView::Build::Row;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Align);

#the name of the underlying NPB::Parse::Format parser
sub parser { 'MAF' }

my %Known_Parameters = 
    (
     #name        => [ format  default ]
     'block'      => [ [],     undef   ],
    );

#tell the parent
sub known_parameters { \%Known_Parameters }

#called by the constructor
sub initialise_child {
    my $self = shift;

    #MAF ordinal block number: counted 1..N whereas the actual
    #block has its own 'number' field which is reported by subheader().
    my $last = $self->{'entry'}->count(qw(BLOCK));

    #free object
    $self->{'entry'}->free(qw(BLOCK));

    $self->{scheduler} = new Bio::MView::Build::Scheduler([1..$last]);

    $self->{'parsed'} = undef;  #ref to parsed block

    $self;
}

#called on each iteration
sub reset_child {
    my $self = shift;
    #warn "reset_child [@{$self->{'block'}}]\n";
    $self->{scheduler}->filter($self->{'block'});
    $self;
}

#current block being processed
sub block { $_[0]->{scheduler}->item }

sub subheader {
    my ($self, $quiet) = (@_, 0);
    my $s = '';
    return $s  if $quiet;
    $s .= "Block: " . $self->block;
    $s .= "  score: $self->{'parsed'}->{'score'}"
	if $self->{'parsed'}->{'score'} ne '';
    $s .= "  pass: $self->{'parsed'}->{'pass'}"
	if $self->{'parsed'}->{'pass'} ne '';
    $s .= "\n";
}

sub parse {
    my $self = shift;
    my ($rank, $use, $desc, $seq, @hit) = (0);

    return  unless defined $self->{scheduler}->next;

    $self->{'parsed'} = $self->{'entry'}->parse("BLOCK[@{[$self->block]}]");

    #block doesn't exist?
    return  unless defined $self->{'parsed'};

    foreach my $row (@{$self->{'parsed'}->{'row'}}) {

	$rank++;
        
	#check row wanted, by rank OR identifier OR row count limit
        $use = $self->use_row($rank, $rank, $row->{'id'});

	last  if $use < 0;
	next  if $use < 1;

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

    #free objects
    $self->{'entry'}->free(qw(BLOCK));

    return \@hit;
}


###########################################################################
1;
