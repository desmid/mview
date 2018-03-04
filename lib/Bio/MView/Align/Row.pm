# Copyright (C) 1997-2018 Nigel P. Brown

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
	    $Colour_Cream $Colour_Brown $Colour_Comment $KWARGS);

$Colour_Black      = '#000000';
$Colour_White      = '#FFFFFF';
$Colour_DarkGray   = '#666666';
$Colour_LightGray  = '#999999';
$Colour_Cream      = '#FFFFCC';
$Colour_Brown      = '#aa6666';

$Colour_Comment    = $Colour_Brown;

$KWARGS = {
    'css1'     => 0,
    'gapcolor' => $Colour_Black,
    'symcolor' => $Colour_Black,
};

#sub DESTROY { warn "DESTROY $_[0]\n" }

sub set_kwargs {
    my $self = shift;
    my $kw = {};
    #warn "set_kwargs: (@_)\n";
    $self->_set_kwargs_search($kw, ref $self, @_);
    return $kw;
}

sub _set_kwargs_search {
    my ($self, $kw, $class) = (shift, shift, shift);

    #warn "entering: $class\n";

    #do base case?
    if ($class eq 'Bio::MView::Align::Row' or !$class) {
        #warn "  base case\n";
        $self->_do_base_kwargs($kw, $class, @_);
        return;
    }

    #do inner
    #warn "  inner case\n";
    @_ = $self->_do_inner_kwargs($kw, $class, @_);

    #search parent
    my @isa = eval '@' . $class . '::ISA';
    $class = pop @isa;

    #warn "  trying: $class\n";
    $self->_set_kwargs_search($kw, $class, @_);
}

sub _do_base_kwargs {
    my ($self, $kw, $class) = (shift, shift, shift);

    #warn "  do base: $class (@_)\n";
    my $kwargs = eval '$' . $class . '::KWARGS';

    if (defined $kwargs) {

        #set own defaults
        map { $kw->{$_} = $kwargs->{$_} } keys %$kwargs;

        my $caller = ref $self;

        while (@_) {
            my ($k, $v) = (shift, shift);

            die "${caller}: unknown keyword '$k'\n"
                unless exists $kw->{$k};

            die "${caller}: keyword '$k' has undefined value\n"
                unless defined $v;

            #warn "  saving $k: $v\n";
            $kw->{$k} = $v;  #override default
        }
    }
}

sub _do_inner_kwargs {
    my ($self, $kw, $class) = (shift, shift, shift);

    #warn "  do inner: $class (@_)\n";
    my $kwargs = eval '$' . $class . '::KWARGS';

    my @rest = ();

    if (defined $kwargs) {

        #set own defaults
        map { $kw->{$_} = $kwargs->{$_} } keys %$kwargs;

        my $caller = ref $self;

        while (@_) {
            my ($k, $v) = (shift, shift);

            die "${caller}: keyword '$k' has undefined value\n"
                unless defined $v;

            if (!exists $kw->{$k}) {
                push @rest, $k, $v;  #replace for parent
                next;
            }

            #warn "  saving $k: $v\n";
            $kw->{$k} = $v;  #override default
        }

        return @rest;
    }

    return @_;
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
