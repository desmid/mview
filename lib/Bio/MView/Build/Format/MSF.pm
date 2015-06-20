# Copyright (C) 1997-2015 Nigel P. Brown
# $Id: MSF.pm,v 1.12 2015/06/14 17:09:04 npb Exp $

###########################################################################
package Bio::MView::Build::Row::MSF;

use Bio::MView::Build::Row;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row);

sub schema {[
    # use?   key              label         format   default 
    [ 0,     'weight',        'weight',     '5N',       '' ],
    ]
}

sub new {
    my $type = shift;
    my ($num, $id, $desc, $seq) = splice @_, 0, 4;
    my $self = new Bio::MView::Build::Row($num, $id, $desc, $seq);
    bless $self, $type;
    $self->save_info(@_);
}


###########################################################################
package Bio::MView::Build::Format::MSF;

use Bio::MView::Build::Align;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Align);

#the name of the underlying NPB::Parse::Format parser
sub parser { 'MSF' }

sub parse {
    my $self = shift;
    my ($rank, $use, $id, $wgt, $seq, @hit) = (0);

    return  unless defined $self->{scheduler}->next;

    foreach $id (@{$self->{'entry'}->parse(qw(NAME))->{'order'}}) {

	$rank++;

	#check row wanted, by rank OR identifier OR row count limit
	$use = $self->use_row($rank, $rank, $id);

	last  if $use < 0;
	next  if $use < 1;

	#warn "KEEP: ($rank,$id)\n";

	$wgt = $self->{'entry'}->parse(qw(NAME))->{'seq'}->{$id}->{'weight'};
	$seq = $self->{'entry'}->parse(qw(ALIGNMENT))->{'seq'}->{$id};

	push @hit, new Bio::MView::Build::Row::MSF($rank,
						   $id,
						   '',
						   $seq,
						   $wgt,
						  );
    }
    #map { $_->print } @hit;

    #free objects
    $self->{'entry'}->free(qw(NAME ALIGNMENT));

    return \@hit;
}


###########################################################################
1;
