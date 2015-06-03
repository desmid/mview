# Copyright (C) 1997-2006 Nigel P. Brown
# $Id: MIPS.pm,v 1.8 2005/12/12 20:42:48 brown Exp $

###########################################################################
package Bio::MView::Build::Row::MIPS;

use vars qw(@ISA);
use Bio::MView::Build;
use strict;

@ISA = qw(Bio::MView::Build::Row);


###########################################################################
package Bio::MView::Build::Format::MIPS;

use vars qw(@ISA);
use Bio::MView::Build::Align;
use Bio::MView::Build::Row;
use strict;

@ISA = qw(Bio::MView::Build::Align);

#the name of the underlying NPB::Parse::Format parser
sub parser { 'MIPS' }

sub parse {
    my $self = shift;
    my ($rank, $use, $id, $des, $seq, @hit) = (0);

    return  unless defined $self->schedule;

    foreach $id (@{$self->{'entry'}->parse(qw(NAME))->{'order'}}) {

	$rank++;

	#check row wanted, by rank OR identifier OR row count limit
	last  if ($use = $self->use_row($rank, $rank, $id)) < 0;
	next  unless $use;

	#warn "KEEP: ($rank,$id)\n";

	$des = $self->{'entry'}->parse(qw(NAME))->{'seq'}->{$id};
	$seq = $self->{'entry'}->parse(qw(ALIGNMENT))->{'seq'}->{$id};

	push @hit, new Bio::MView::Build::Row::MIPS($rank, $id, $des, $seq);
    }

    #map { $_->print } @hit;

    return \@hit;
}


###########################################################################
1;
