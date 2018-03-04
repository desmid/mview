# Copyright (C) 1997-2016 Nigel P. Brown

###########################################################################
package Bio::MView::Align::Row;

use Bio::MView::Align;
use Bio::MView::Display;
use Bio::MView::Align::Ruler;
use Bio::MView::Align::Sequence;
use Bio::MView::Align::Consensus;
use Bio::MView::Align::Conservation;

use strict;
use vars qw($Colour_Black $Colour_White $Colour_DarkGray $Colour_LightGray
	    $Colour_Cream $Colour_Comment);

$Colour_Black   	    	= '#000000';
$Colour_White   	    	= '#FFFFFF';
$Colour_DarkGray    	    	= '#666666';
$Colour_LightGray   	    	= '#999999';
$Colour_Cream            	= '#FFFFCC';
$Colour_Comment                 = '#aa6666';  #brown

#sub DESTROY { warn "DESTROY $_[0]\n" }

sub dump {
    my $self = shift;
    foreach my $k (sort keys %$self) {
	printf "%15s => %s\n", $k, $self->{$k};
    }
    $self;
}

sub set_display {
    my $self = shift;
    my ($key, $val, @tmp, %tmp);
    #$self->dump;
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
