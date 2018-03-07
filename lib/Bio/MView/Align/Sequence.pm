# Copyright (C) 1997-2018 Nigel P. Brown

###########################################################################
package Bio::MView::Align::Sequence;

use Bio::MView::Option::Parameters;  #for $PAR
use Bio::MView::Colormap;
use Bio::MView::Align::Row;

@ISA = qw(Bio::MView::Align::Row);

use strict;
use vars qw($Wildcard_Sym $Default_PRO_Colormap $Default_DNA_Colormap
            %Template);

$Wildcard_Sym          = '.';     #key for default colouring

$Default_PRO_Colormap  = 'P1';    #default protein colormap name
$Default_DNA_Colormap  = 'D1';    #default nucleotide colormap name

%Template =
    (
     'id'      => undef,     #identifier
     'type'    => undef,     #information about own subtype
     'from'    => undef,     #start number of sequence
     'string'  => undef,     #alignment string
     'display' => undef,     #hash of display parameters
    );

my $FIND_WARNINGS  = 1;       #find block warnings only once
my $FIND_SEPARATOR = ':';     #for multiple find patterns
my $FIND_COLORMAP  = 'FIND';  #hardwired find colormap

sub get_default_sequence_colormap {
    if (! defined $_[0] or $_[0] eq 'aa') {  #default to protein
	return $Bio::MView::Align::Sequence::Default_PRO_Colormap;
    }
    return $Bio::MView::Align::Sequence::Default_DNA_Colormap,
}

sub new {
    my $type = shift;
    #warn "${type}::new(@_)\n";
    if (@_ < 2) {
	die "${type}::new: missing arguments\n";
    }
    my ($id, $string, $subtype) = (@_, 'sequence');

    my $self = { %Template };

    $self->{'id'}     = $id;
    $self->{'type'}   = $subtype;
    $self->{'from'}   = $string->lo;
    $self->{'string'} = $string;

    bless $self, $type;

    $self->reset_display;

    $FIND_WARNINGS = 1;   #reset

    $self;
}

#sub DESTROY { warn "DESTROY $_[0]\n" }

sub id       { $_[0]->{'id'} }
sub seqobj   { $_[0]->{'string'} }
sub string   { $_[0]->{'string'}->string }
sub sequence { $_[0]->{'string'}->sequence }
sub from     { $_[0]->{'from'} }
sub length   { $_[0]->{'string'}->length }
sub seqlen   { $_[0]->{'string'}->seqlen }

sub reset_display {
    $_[0]->{'display'} = {
        'type'     => 'sequence',
        'label1'   => $_[0]->{'id'},
        'sequence' => $_[0]->{'string'},
        'range'    => [],
    };
    $_[0];
}

sub get_color {
    my ($self, $c, $map) = @_;
    my ($index, $color, $trans);

    #warn "get_color: $c, $map";

    #set transparent(T)/solid(S)
    if (exists $Bio::MView::Colormap::Colormaps->{$map}->{$c}) {

	$trans = $Bio::MView::Colormap::Colormaps->{$map}->{$c}->[1];
	$index = $Bio::MView::Colormap::Colormaps->{$map}->{$c}->[0];
	$color = $Bio::MView::Colormap::Palette->[1]->[$index];

	#warn "CL $c $map\{$c} [$index] [$color] [$trans]\n";
	
	return ($color, "$trans$index");
    }

    #wildcard colour
    if (exists $Bio::MView::Colormap::Colormaps->{$map}->{$Wildcard_Sym}) {

	$trans = $Bio::MView::Colormap::Colormaps->{$map}->{$Wildcard_Sym}->[1];
	$index = $Bio::MView::Colormap::Colormaps->{$map}->{$Wildcard_Sym}->[0];
	$color = $Bio::MView::Colormap::Palette->[1]->[$index];

	#warn "WC $c $map\{$Wildcard_Sym} [$index] [$color] [$trans]\n";

	return ($color, "$trans$index");
    }

    #preset colour name in $map, used for string searches or plain
    #colouring where all matches should be same colour
    if (exists $Bio::MView::Colormap::Palette->[0]->{$map}) {

	$trans = 'S';
	$index = $Bio::MView::Colormap::Palette->[0]->{$map};
        $color = $Bio::MView::Colormap::Palette->[1]->[$index];

	#warn "FD $c $map\{$c} [$index] [$color] [$trans]\n";

	return ($color, "$trans$index");
    }

    return 0;    #no match
}

sub color_none {
    my $self = shift;

    return  unless $self->{'type'} eq 'sequence';

    my $kw = $PAR->as_dict;

    my ($color, $end, $i, $c, @tmp) = ($self->{'display'}->{'range'});

    push @$color, 1, $self->length, 'color' => $kw->{'symcolor'};

    for ($end=$self->length+1, $i=1; $i<$end; $i++) {

	$c = $self->{'string'}->raw($i);

	#warn "[$i]= $c\n";

	#white space: no color
	next    if $self->{'string'}->is_space($c);

	#gap or frameshift: gapcolour
	if ($self->{'string'}->is_non_char($c)) {
	    push @$color, $i, 'color' => $kw->{'gapcolor'};
	    next;
	}

        push @$color, $i, 'color' => $kw->{'symcolor'};
    }

    $self->{'display'}->{'paint'}  = 1;
    $self;
}

sub color_special {
    my $self = shift;

    my $kw = $PAR->as_dict;

    #locate a 'special' colormap'
    my ($size, $map) = (0);
    foreach $map (keys %$Bio::MView::Colormap::Colormaps) {
	if ($self->{'id'} =~ /$map/i) {
	    if (length($&) > $size) {
		$kw->{'aln_colormap'} = $map;
		$size = length($&);
	    }
	}
    }
    return unless $size;

    my ($color, $end, $i, $c, @tmp) = ($self->{'display'}->{'range'});

    push @$color, 1, $self->length, 'color' => $kw->{'symcolor'};

    for ($end=$self->length+1, $i=1; $i<$end; $i++) {

	$c = $self->{'string'}->raw($i);
	
	#warn "$self->{'id'}  [$i]= $c\n";

	#white space: no color
	next    if $self->{'string'}->is_space($c);

	#gap: gapcolour
	if ($self->{'string'}->is_non_char($c)) {
	    push @$color, $i, 'color' => $kw->{'gapcolor'};
	    next;
	}
	
	#use symbol color/wildcard colour
	@tmp = $self->get_color($c, $kw->{'aln_colormap'});

	if (@tmp) {
	    if ($kw->{'css1'}) {
		push @$color, $i, 'class' => $tmp[1];
	    } else {
		push @$color, $i, 'color' => $tmp[0];
	    }
	} else {
	    push @$color, $i, 'color' => $kw->{'symcolor'};
	}
    }

    $self->{'display'}->{'paint'}  = 1;
    $self;
}

sub find_blocks {
    my ($self, $find, $colormap) = @_;

    my $mapsize = Bio::MView::Colormap::get_colormap_length($colormap);

    my @patterns = split($FIND_SEPARATOR, $find);

    if (@patterns > $mapsize and $FIND_WARNINGS) {
        warn "find: @{[scalar @patterns]} pattern blocks but only $mapsize color@{[$mapsize gt 1 ? 's' : '']} in colormap '$colormap' - recycling\n";
        $FIND_WARNINGS--;
    }

    my $matches = $self->{string}->findall(\@patterns, $mapsize);
    my $index = {};

    foreach my $block (@$matches) {
        $index->{$block->[1]} = $block->[0];
    }

    return $index;
}

sub color_by_find_block {
    my $self = shift;

    return  unless $self->{'type'} eq 'sequence';

    my $kw = $PAR->as_dict;

    my ($color, $end, $i, $c, @tmp) = ($self->{'display'}->{'range'});

    push @$color, 1, $self->length, 'color' => $kw->{'symcolor'};

    my $block = $self->find_blocks($kw->{'find'}, $FIND_COLORMAP);

    for ($end=$self->length+1, $i=1; $i<$end; $i++) {

	$c = $self->{'string'}->raw($i);
	
	#warn "[$i]= $c\n";

	#white space: no color
	next    if $self->{'string'}->is_space($c);

	#gap or frameshift: gapcolour
	if ($self->{'string'}->is_non_char($c)) {
	    push @$color, $i, 'color' => $kw->{'gapcolor'};
	    next;
	}
	
        if (exists $block->{$i}) {
            #use symbol color/wildcard colour
            @tmp = $self->get_color($block->{$i}, $FIND_COLORMAP);
        } else {
            @tmp = ();
        }
	
	if (@tmp) {
	    if ($kw->{'css1'}) {
		push @$color, $i, 'class' => $tmp[1];
	    } else {
		push @$color, $i, 'color' => $tmp[0];
	    }
	} else {
	    push @$color, $i, 'color' => $kw->{'symcolor'};
	}
    }

    $self->{'display'}->{'paint'} = 1;
    $self;
}

sub color_by_type {
    my $self = shift;

    return  unless $self->{'type'} eq 'sequence';

    my $kw = $PAR->as_dict;

    my ($color, $end, $i, $c, @tmp) = ($self->{'display'}->{'range'});

    push @$color, 1, $self->length, 'color' => $kw->{'symcolor'};

    for ($end=$self->length+1, $i=1; $i<$end; $i++) {

	$c = $self->{'string'}->raw($i);
	
	#warn "[$i]= $c\n";

	#white space: no color
	next    if $self->{'string'}->is_space($c);

	#gap or frameshift: gapcolour
	if ($self->{'string'}->is_non_char($c)) {
	    push @$color, $i, 'color' => $kw->{'gapcolor'};
	    next;
	}
	
	#use symbol color/wildcard colour
	@tmp = $self->get_color($c, $kw->{'aln_colormap'});

	if (@tmp) {
	    if ($kw->{'css1'}) {
		push @$color, $i, 'class' => $tmp[1];
	    } else {
		push @$color, $i, 'color' => $tmp[0];
	    }
	} else {
	    push @$color, $i, 'color' => $kw->{'symcolor'};
	}
    }

    $self->{'display'}->{'paint'}  = 1;
    $self;
}

sub color_by_identity {
    my ($self, $othr) = (shift, shift);
    return $self->color_by_identity_body($othr, 1, @_);
}

sub color_by_mismatch {
    my ($self, $othr) = (shift, shift);
    return $self->color_by_identity_body($othr, 0, @_);
}

sub color_by_identity_body {
    my ($self, $othr, $byidentity) = @_;

    return  unless $self->{'type'} eq 'sequence';
    return  unless defined $othr;

    die "${self}::color_by_identity: length mismatch\n"
	unless $self->length == $othr->length;

    my $kw = $PAR->as_dict;

    my ($color, $end) = ($self->{'display'}->{'range'}, $self->length+1);

    push @$color, 1, $self->length, 'color' => $kw->{'symcolor'};

    for (my $i=1; $i<$end; $i++) {

	my $c1 = $self->{'string'}->raw($i);
        my $c2 = $othr->{'string'}->raw($i);

	#warn "[$i]= $c1 <=> $c2\n";

	#white space: no color
	next  if $self->{'string'}->is_space($c1);

	#gap or frameshift: gapcolour
	if ($self->{'string'}->is_non_char($c1)) {
	    push @$color, $i, 'color' => $kw->{'gapcolor'};
	    next;
	}

        my @tmp = ();

        #compare symbols, case-insensitive
        if ($byidentity) { #mismatch coloring mode
            @tmp = $self->get_color($c1, $kw->{'aln_colormap'})
                if uc $c1 eq uc $c2; #same symbol or symcolor
        } else { #identity coloring mode
            @tmp = $self->get_color($c1, $kw->{'aln_colormap'})
                if uc $c1 ne uc $c2; #different symbol or symcolor
        }

        if (@tmp) {
            if ($kw->{'css1'}) {
                push @$color, $i, 'class' => $tmp[1];
            } else {
                push @$color, $i, 'color' => $tmp[0];
            }
        } else { #default color
            push @$color, $i, 'color' => $kw->{'symcolor'};
        }
    }

    $self->{'display'}->{'paint'}  = 1;
    $self;
}

sub set_coverage {
    #warn "Bio::MView::Align::Sequence::set_coverage(@_)\n";
    my ($self, $ref) = @_;
    my $val = $self->compute_coverage_wrt($ref);
    $self->set_display('label4'=>sprintf("%.1f%%", $val));
}

sub get_coverage {
    if (exists $_[0]->{'display'}->{'label4'} and
        defined $_[0]->{'display'}->{'label4'}) {
        return $_[0]->{'display'}->{'label4'};
    }
    return '';
}

# Compute the percent coverage of a row with respect to a reference row.
#
# \frac{\mathrm{number~of~residues~in~row~aligned~with~reference~row}}
#      {\mathrm{length~of~ungapped~reference~row}}
# \times 100
#
sub compute_coverage_wrt {
    #warn "Bio::MView::Align::Sequence::compute_coverage_wrt(@_)\n";
    my ($self, $othr) = @_;

    return 0      unless defined $othr;
    return 100.0  if $self == $othr;  #always 100% coverage of self

    die "${self}::compute_coverage_wrt: length mismatch\n"
	unless $self->length == $othr->length;

    my ($sc, $oc) = (0, 0);
    my $end = $self->length +1;

    for (my $i=1; $i<$end; $i++) {

	my $c2 = $othr->{'string'}->raw($i);

	#reference must be a sequence character
	next  unless $self->{'string'}->is_char($c2);

	my $c1 = $self->{'string'}->raw($i);

	#count sequence characters
	$sc++  if $self->{'string'}->is_char($c1);
	$oc++  if $self->{'string'}->is_char($c2);
    }

    #compute percent coverage
    return 100.0 * $sc/$oc;
}

sub set_identity {
    #warn "Bio::MView::Align::Sequence::set_identity(@_)\n";
    my ($self, $ref, $mode) = @_;
    my $val = $self->compute_identity_to($ref, $mode);
    $self->set_display('label5'=>sprintf("%.1f%%", $val));
}

sub get_identity {
    if (exists $_[0]->{'display'}->{'label5'} and
        defined $_[0]->{'display'}->{'label5'}) {
        return $_[0]->{'display'}->{'label5'};
    }
    return '';
}

#Compute percent identity to a reference row.
#Normalisation depends on the mode argument:
#  'reference' divides by the reference sequence length,
#  'aligned' divides by the aligned region length (like blast),
#  'hit' divides by the hit sequence.
#The last is the same as 'aligned' for blast, but different for
#multiple alignments like clustal.
#
# Default (mode: 'aligned'):
#
# \frac{\mathrm{number~of~identical~residues}}
#      {\mathrm{length~of~ungapped~reference~row~over~aligned~region}}
# \times 100
#
sub compute_identity_to {
    #warn "Bio::MView::Align::Sequence::compute_identity_to(@_)\n";
    my ($self, $othr, $mode) = (@_, 'aligned');

    return 0      unless defined $othr;
    return 100.0  if $self == $othr;  #always 100% identical to self

    die "${self}::compute_identity_to: length mismatch\n"
	unless $self->length == $othr->length;

    my ($sum, $len) = (0, 0);
    my $end = $self->length +1;

    for (my $i=1; $i<$end; $i++) {
	my $cnt = 0;
	
	my $c1 = $self->{'string'}->raw($i);
	my $c2 = $othr->{'string'}->raw($i);

	#at least one must be a sequence character
	$cnt++  if $self->{'string'}->is_char($c1);
	$cnt++  if $self->{'string'}->is_char($c2);
	next  if $cnt < 1;

        #standardize case
        $c1 = uc $c1; $c2 = uc $c2;

	#ignore terminal gaps in the *first* sequence
	$len++  unless $self->{'string'}->is_terminal_gap($c1);

        #ignore unknown character: contributes to length only
        next  if $c1 eq 'X' or $c2 eq 'X';

	$sum++  if $c1 eq $c2;
	#warn "[$i] $c1 $c2 : $cnt => $sum / $len\n";
    }

    #normalise identities
    my $norm = 0;
    if ($mode eq 'aligned') {
	$norm = $len;
    } elsif ($mode eq 'reference') {
	$norm = $othr->seqlen;
    } elsif ($mode eq 'hit') {
	$norm = $self->seqlen;
    }
    #warn "normalization mode: $mode, value= $norm\n";
    #warn "identity $self->{'id'} = $sum/$norm\n";

    return ($sum = 100 * ($sum + 0.0) / $norm)    if $norm > 0;
    return 0;
}

###########################################################################
1;
