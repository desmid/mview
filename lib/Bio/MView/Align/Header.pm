# Copyright (C) 2015-2017 Nigel P. Brown

###########################################################################
package Bio::MView::Align::Header;

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

    $self->{'type'}   = 'header';
    $self->{'length'} = $length;

    $self->reset_display($refobj);

    $self;
}

sub id     { $_[0] }
sub string { '' }
sub length { $_[0]->{'length'} }

sub reset_display {
    my ($self, $refobj) = @_;
    my ($data, $pcid) = ('', '');
    if (defined $refobj) {
	$data = $refobj->head;
	$pcid = $refobj->pcid;
    }
    $self->{'display'} =
	{
	 'type'     => $self->{type},
	 'label0'   => '',
	 'label1'   => '',
	 'label2'   => '',
	 'label3'   => $data,
	 'label4'   => '',
	 'label5'   => $pcid,
	 'label6'   => '',
	 'label7'   => '',
	 'range'    => [],
	 'number'   => 0,
	};
    $self;
}


###########################################################################
1;
