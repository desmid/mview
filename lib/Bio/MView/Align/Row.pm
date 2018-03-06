# Copyright (C) 1997-2018 Nigel P. Brown

###########################################################################
package Bio::MView::Align::Row;

use Kwargs;
use Bio::MView::Colormap;

use strict;
use vars qw($KWARGS);

$KWARGS = {
    ''         => 1,  #sentinel: terminate kwargs search
    'css1'     => 0,
    'gapcolor' => $Bio::MView::Colormap::Colour_Black,
    'symcolor' => $Bio::MView::Colormap::Colour_Black,
};

#sub DESTROY { warn "DESTROY $_[0]\n" }

sub set_display {
    my $self = shift;
    my ($key, $val, @tmp, %tmp);

    while ($key = shift @_) {

	$val = shift @_;

	#have to copy referenced data in case caller iterates over
	#many instances of self and passes the same data to each!
	if (ref $val eq 'HASH') {
	    %tmp = %$val;
	    $val = \%tmp;
	} elsif (ref $val eq 'ARRAY') {
	    @tmp = @$val;
	    $val = \@tmp;
	}
	#warn "($key) $self->{'display'}->{$key} --> $val\n";
	$self->{'display'}->{$key} = $val;
    }

    $self;
}

sub get_display { $_[0]->{'display'} }

sub color_special {}
sub color_by_type {}
sub color_by_identity {}
sub color_by_mismatch {}
sub color_by_consensus_sequence {}
sub color_by_consensus_group {}


###########################################################################
1;
