# Copyright (C) 2015-2017 Nigel P. Brown

###########################################################################
package Bio::MView::Align::Conservation;

use Bio::MView::Align::Sequence;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::MView::Align::Sequence);

sub new {
    my $type = shift;
    #warn "${type}::new(@_)\n";
    if (@_ < 1) {
	die "${type}::new: missing arguments\n";
    }
    my ($from, $to, $string) = @_;

    my $self = { %Bio::MView::Align::Sequence::Template };

    $self->{'id'}   = "clustal";
    $self->{'type'} = 'conservation';
    $self->{'from'} = $from;
    $self->{'to'}   = $to;
   
    #encode the new "sequence"
    $self->{'string'} = new Bio::MView::Sequence;
    $self->{'string'}->set_find_pad(' ');
    $self->{'string'}->set_find_pad(' ');
    $self->{'string'}->set_pad(' ');
    $self->{'string'}->set_gap(' ');
    $self->{'string'}->insert([$string, $from, $to]);

    bless $self, $type;

    $self->reset_display;

    $self;
}


###########################################################################
1;
