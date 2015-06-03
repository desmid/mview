# Copyright (C) 1997-2006 Nigel P. Brown
# $Id: CLUSTAL.pm,v 1.11 2005/12/12 20:42:48 brown Exp $

###########################################################################
package Bio::MView::Build::Format::CLUSTAL;

use vars qw(@ISA);
use Bio::MView::Build::Align;
use Bio::MView::Build::Row;
use strict;

@ISA = qw(Bio::MView::Build::Align);

#the name of the underlying NPB::Parse::Format parser
sub parser { 'CLUSTAL' }

sub parse {
    my $self = shift;
    my ($rank, $use, $id, $seq, @hit) = (0);

    return   unless defined $self->schedule;

    foreach $id (@{$self->{'entry'}->parse(qw(ALIGNMENT))->{'id'}}) {

	$rank++;

	#check row wanted, by rank OR identifier OR row count limit
	last  if ($use = $self->use_row($rank, $rank, $id)) < 0;
	next  unless $use;

	#warn "KEEP: ($rank,$id)\n";

	$seq = $self->{'entry'}->parse(qw(ALIGNMENT))->{'seq'}->{$id};

	push @hit, new Bio::MView::Build::Row($rank, $id, '', $seq);
    }

    #map { $_->print } @hit;

    return \@hit;
}


###########################################################################
1;
