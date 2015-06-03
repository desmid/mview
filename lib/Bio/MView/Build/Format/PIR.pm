# Copyright (C) 1998-2006 Nigel P. Brown
# $Id: PIR.pm,v 1.10 2005/12/12 20:42:48 brown Exp $

###########################################################################
package Bio::MView::Build::Format::PIR;

use vars qw(@ISA);
use Bio::MView::Build::Align;
use Bio::MView::Build::Row;
use strict;

@ISA = qw(Bio::MView::Build::Align);

#the name of the underlying NPB::Parse::Format parser
sub parser { 'PIR' }

sub parse {
    my $self = shift;
    my ($rank, $use, $rec, @hit) = (0);

    return  unless defined $self->schedule;

    foreach $rec ($self->{'entry'}->parse(qw(SEQ))) {

	$rank++;

	#check row wanted, by rank OR identifier OR row count limit
	last  if ($use = $self->use_row($rank, $rank, $rec->{'id'})) < 0;
	next  unless $use;

	#warn "KEEP: ($rank,$id)\n";

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
