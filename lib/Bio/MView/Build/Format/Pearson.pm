# Copyright (C) 1998-2015 Nigel P. Brown
# $Id: Pearson.pm,v 1.12 2015/01/24 21:22:42 npb Exp $

###########################################################################
package Bio::MView::Build::Format::Pearson;

use vars qw(@ISA);
use Bio::MView::Build::Align;
use Bio::MView::Build::Row;
use strict;

@ISA = qw(Bio::MView::Build::Align);

#the name of the underlying NPB::Parse::Format parser
sub parser { 'Pearson' }

sub parse {
    my $self = shift;
    my ($rank, $use, $rec, @hit) = (0);
    
    return  unless defined $self->schedule;

    foreach $rec ($self->{'entry'}->parse(qw(SEQ))) {

	$rank++;

	#check row wanted, by rank OR identifier OR row count limit
	last  if ($use = $self->use_row($rank, $rank, $rec->{'id'})) < 0;
	next  unless $use;

	#warn "KEEP: ($rank,$rec->{'id'})\n";

	push @hit, new Bio::MView::Build::Row($rank,
					      $rec->{'id'},
					      $rec->{'desc'},
					      $rec->{'seq'},
					     );
    }

    #map { $_->print } @hit;

    return \@hit;
}


###########################################################################
1;
