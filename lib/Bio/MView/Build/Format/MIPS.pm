# Copyright (C) 1997-2015 Nigel P. Brown
# $Id: MIPS.pm,v 1.8 2005/12/12 20:42:48 brown Exp $

###########################################################################
package Bio::MView::Build::Format::MIPS;

use Bio::MView::Build::Align;
use Bio::MView::Build::Row;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Align);

#the name of the underlying NPB::Parse::Format parser
sub parser { 'MIPS' }

sub parse {
    my $self = shift;
    my ($rank, $use, $id, $des, $seq, @hit) = (0);

    return  unless defined $self->{scheduler}->next;

    foreach $id (@{$self->{'entry'}->parse(qw(NAME))->{'order'}}) {

	$rank++;

	#check row wanted, by rank OR identifier OR row count limit
	$use = $self->use_row($rank, $rank, $id);

	last  if $use < 0;
	next  if $use < 1;

	#warn "KEEP: ($rank,$id)\n";

	$des = $self->{'entry'}->parse(qw(NAME))->{'seq'}->{$id};
	$seq = $self->{'entry'}->parse(qw(ALIGNMENT))->{'seq'}->{$id};

	push @hit, new Bio::MView::Build::Simple_Row($rank, $id, $des, $seq);
    }
    #map { $_->print } @hit;

    #free objects
    $self->{'entry'}->free(qw(NAME ALIGNMENT));

    return \@hit;
}


###########################################################################
1;
