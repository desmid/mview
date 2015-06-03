# Copyright (C) 1997-2006 Nigel P. Brown
# $Id: MSF.pm,v 1.11 2005/12/12 20:42:48 brown Exp $

###########################################################################
package Bio::MView::Build::Row::MSF;

use vars qw(@ISA);
use Bio::MView::Build;
use strict;

@ISA = qw(Bio::MView::Build::Row);

sub new {
    my $type = shift;
    my ($num, $id, $desc, $seq, $weight) = @_;
    my $self = new Bio::MView::Build::Row($num, $id, $desc, $seq);
    $self->{'weight'} = $weight;
    bless $self, $type;
}

#could be used in header/ruler
#sub head { 'weight' }
#sub pcid { $_[0]->SUPER::pcid_std }
#sub data  { sprintf("%5s", $_[0]->{'weight'}) }

sub rdb_info {
    my ($self, $mode) = @_;
    return ($self->{'weight'})  if $mode eq 'data';
    return ('weight')  if $mode eq 'attr';
    return ('5N')  if $mode eq 'form';
}


###########################################################################
package Bio::MView::Build::Format::MSF;

use vars qw(@ISA);
use Bio::MView::Build::Align;
use Bio::MView::Build::Row;
use strict;

@ISA = qw(Bio::MView::Build::Align);

#the name of the underlying NPB::Parse::Format parser
sub parser { 'MSF' }

sub parse {
    my $self = shift;
    my ($rank, $use, $id, $wgt, $seq, @hit) = (0);

    return  unless defined $self->schedule;

    foreach $id (@{$self->{'entry'}->parse(qw(NAME))->{'order'}}) {

	$rank++;

	#check row wanted, by rank OR identifier OR row count limit
	last  if ($use = $self->use_row($rank, $rank, $id)) < 0;
	next  unless $use;

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

    return \@hit;
}


###########################################################################
1;
