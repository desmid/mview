# Copyright (C) 2018 Nigel P. Brown

###########################################################################
package Bio::MView::Align::Special;

use Bio::MView::Option::Parameters;  #for $PAR
use Bio::MView::Colormap;
use Bio::MView::Align::Sequence;

@ISA = qw(Bio::MView::Align::Sequence);

use strict;

sub new {
    my $type = shift;
    #warn "${type}::new(@_)\n";
    if (@_ < 2) {
	die "${type}::new: missing arguments\n";
    }
    my ($id, $string, $subtype) = (@_, 'special');

    my $self = {};

    bless $self, $type;

    $self->{'id'}     = $id;          #identifier
    $self->{'type'}   = $subtype;     #information about own subtype
    $self->{'from'}   = $string->lo;  #start number of sequence
    $self->{'string'} = $string;      #alignment string

    $self->reset_display;             #hash of display parameters

    $self;
}

#override
sub is_sequence { 0 }

#override
sub is_special { 1 }

sub color_special {
    my $self = shift;

    my $kw = $PAR->as_dict;

    my $map = $self->get_special_colormap_for_id($kw, $self->{'id'});

    return  unless defined $map;

    $kw->{'aln_colormap'} = $map;

    $self->color_special_body($kw);
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

sub color_special_body {
    my ($self, $kw) = (shift, shift);

    my $color = $self->{'display'}->{'range'};

    push @$color, 1, $self->length, 'color' => $kw->{'symcolor'};

    my $end = $self->length + 1;

    for (my $i=1; $i<$end; $i++) {

	my $c = $self->{'string'}->raw($i);

	#warn "[$i]= $c\n";

	#white space: no color
	next  if $self->{'string'}->is_space($c);

	#gap: gapcolour
	if ($self->{'string'}->is_non_char($c)) {
	    push @$color, $i, 'color' => $kw->{'gapcolor'};
	    next;
	}

	#use symbol color/wildcard colour
	my @tmp = $self->get_color($c, $kw->{'aln_colormap'});

        push @$color,
            $self->color_tag($kw->{'css1'}, $kw->{'symcolor'}, $i, @tmp);
    }

    $self->{'display'}->{'paint'} = 1;
}


###########################################################################
1;
