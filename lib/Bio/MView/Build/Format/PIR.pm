# Copyright (C) 1998-2015 Nigel P. Brown
# $Id: PIR.pm,v 1.10 2005/12/12 20:42:48 brown Exp $

###########################################################################
package Bio::MView::Build::Format::PIR;

use Bio::MView::Build::Align;
use Bio::MView::Build::Row;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Align);

#the name of the underlying NPB::Parse::Format parser
sub parser { 'PIR' }

sub parse {
    my $self = shift;
    my ($rank, $use, $rec, @hit) = (0);

    return  unless defined $self->{scheduler}->next;

    foreach $rec ($self->{'entry'}->parse(qw(SEQ))) {

	$rank++;

	#check row wanted, by rank OR identifier OR row count limit
	$use = $self->use_row($rank, $rank, $rec->{'id'});

	last  if $use < 0;
	next  if $use < 1;

	#warn "KEEP: ($rank,$id)\n";

	push @hit, new Bio::MView::Build::Simple_Row($rank,
                                                     $rec->{'id'},
                                                     $rec->{'desc'},
                                                     $rec->{'seq'},
            );
    }
    #map { $_->print } @hit;

    #free objects
    $self->{'entry'}->free(qw(SEQ));

    return \@hit;
}


###########################################################################
1;
