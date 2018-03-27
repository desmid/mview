# Copyright (C) 2018 Nigel P. Brown

###########################################################################
package Bio::MView::Align::Special;

use Bio::MView::Option::Parameters;  #for $PAR
use Bio::MView::Align::Sequence;
use Bio::MView::Color::ColorMap;

@ISA = qw(Bio::MView::Align::Sequence);

use strict;

#override
sub is_sequence { 0 }

#override
sub is_special { 1 }

#override
sub adjust_display {
    $_[0]->set_display('label0' => '',
                       'label4' => '', 'label5' => '',
                       'label6' => '', 'label7' => '',
    );
}

#override
sub color_special {
    my $self = shift;

    my $kw = $PAR->as_dict;

    my $map = $self->get_special_colormap_for_id($kw, $self->{'id'});

    return  unless defined $map;

    $kw->{'aln_colormap'} = $map;

    $self->color_by_type($kw);
}

#Match row identifier like /#MAP/ or /#MAP:/ or /#MAP:stuff/
#where MAP is some known colormap, and return the colormap;
#note: the internal id may have leading text before the hash.
sub get_special_colormap_for_id {
    my ($self, $kw, $id) = @_;
    my ($size, $map) = (0, undef);
    foreach my $m ($COLORMAP->colormap_names) {
	if ($id =~ /\#$m(|:|:.*)$/i) {
	    if (length($&) > $size) {
		$size = length($&);
                $map = $m;
	    }
	}
    }
    return $map;
}


###########################################################################
1;
