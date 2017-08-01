# Copyright (C) 1997-2017 Nigel P. Brown

###########################################################################
package Bio::MView::Align::Ruler;

use Bio::MView::Align;
use Bio::MView::Display;
use Bio::MView::Align::Row;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Align::Row);

sub new {
    my $type = shift;
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
    my ($data, $covr, $pcid) = ('', '', '');
    if (defined $refobj) {
        $data = $refobj->lbl_data;
        $covr = $refobj->lbl_covr;
        $pcid = $refobj->lbl_pcid;
    }
    $self->{'display'} =
    {
        'type'     => $self->{type},
        'range'    => [],
        'number'   => 1,
        'label0'   => '',
        'label1'   => '',
        'label2'   => '',
        'label3'   => $data,
        'label4'   => $covr,
        'label5'   => $pcid,
        'label6'   => 'query',
        'label7'   => 'sbjct',
    };
    $self;
}


###########################################################################
1;
