# Copyright (C) 1997-2018 Nigel P. Brown

use strict;

###########################################################################
package Bio::MView::Align::Ruler;

use Bio::MView::Align::Row;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Align::Row);

sub new {
    my $type = shift;
    #warn "${type}::new(@_)\n";
    die "${type}::new: missing arguments\n"  if @_ < 2;
    my ($length, $refobj) = @_;

    my $self = new Bio::MView::Align::Row('ruler', '');
    bless $self, $type;

    $self->{'length'} = $length;

    $self->reset_display($refobj);

    $self;
}

######################################################################
# public methods
######################################################################
#override
sub length { $_[0]->{'length'} }

######################################################################
# private methods
######################################################################
#override
sub reset_display {
    my ($self, $refobj) = @_;

    my $labels = ['', '', '', '', '', '', '', ''];
    $labels = [ $refobj->display_column_labels ]  if defined $refobj;

    $self->SUPER::reset_display(
        'type'   => $self->display_type,
        'range'  => [],
        'number' => 1,
        'label0' => $labels->[0],
        'label1' => $labels->[1],
        'label2' => $labels->[2],
        'label3' => $labels->[3],
        'label4' => $labels->[4],
        'label5' => $labels->[5],
        'label6' => $labels->[6],
        'label7' => $labels->[7],
    );
}


###########################################################################
1;
