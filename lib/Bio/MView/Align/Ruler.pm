# Copyright (C) 1997-2017 Nigel P. Brown

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

    my $self = {};

    bless $self, $type;

    $self->{'type'}   = 'ruler';
    $self->{'length'} = $length;

    $self->reset_display($refobj);

    $self;
}

sub id     { $_[0] }
sub string { '' }
sub length { $_[0]->{'length'} }

sub reset_display {
    my ($self, $refobj) = @_;

    my $labels = ['', '', '', '', '', '', '', ''];
    $labels = [ $refobj->display_column_labels ]  if defined $refobj;

    $self->{'display'} =
    {
        'type'   => $self->{type},
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
    };
}


###########################################################################
1;
