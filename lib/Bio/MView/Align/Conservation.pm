# Copyright (C) 2015-2018 Nigel P. Brown

###########################################################################
package Bio::MView::Align::Conservation;

use Bio::MView::Align::Sequence;

@ISA = qw(Bio::MView::Align::Sequence);

use strict;

sub new {
    my $type = shift;
    #warn "${type}::new(@_)\n";
    die "${type}::new: missing arguments\n"  if @_ < 3;
    my ($from, $to, $string) = @_;

    my $self = new Bio::MView::Align::Row('sequence', 'clustal');

    bless $self, $type;

    $self->{'from'} = $from;
    $self->{'to'}   = $to;

    #encode the new "sequence"
    $self->{'string'} = new Bio::MView::Sequence;
    $self->{'string'}->set_find_pad(' ');
    $self->{'string'}->set_find_pad(' ');
    $self->{'string'}->set_pad(' ');
    $self->{'string'}->set_gap(' ');
    $self->{'string'}->insert([$string, $from, $to]);

    $self->reset_display;

    $self;
}

#override
sub is_sequence { 0 }


###########################################################################
1;
