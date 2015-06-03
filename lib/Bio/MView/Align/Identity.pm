# Copyright (C) 1997-2006 Nigel P. Brown
# $Id: Identity.pm,v 1.9 2005/12/12 20:42:48 brown Exp $

###########################################################################
package Bio::MView::Align::Identity;

use Bio::MView::Align;
use Bio::MView::Display;
use Bio::MView::Align::Row;
use strict;

use vars qw(@ISA $Debug);

@ISA = qw(Bio::MView::Align::Sequence);

$Debug = 0;

sub new {
    my $type = shift;
    warn "${type}::new() (@_)\n"    if $Debug;
    if (@_ < 4) {
	die "${type}::new() missing arguments\n";
    }
    my ($id1, $id2, $string, $identity, $subtype) = (@_, 'identity');

    my $self = new Bio::MView::Align::Sequence($id1 . 'x' . $id2, $string);

    $self->{'identity'} = $identity;
    $self->{'parentid'} = $id1;
    $self->{'type'}     = $subtype;

    bless $self, $type;
}

sub get_identity { $_[0]->{'identity'} }
sub get_parentid { $_[0]->{'parentid'} }


###########################################################################
1;
