# Copyright (C) 1997-2018 Nigel P. Brown

###########################################################################
package Bio::MView::Align::Consensus;

use Bio::MView::Colormap;
use Bio::MView::Groupmap;
use Bio::MView::Align::Sequence;

@ISA = qw(Bio::MView::Align::Sequence);

use strict;

#hardwire the consensus line symcolor
my $SYMCOLOR = $Bio::MView::Colormap::Colour_Black;

sub new {
    my $type = shift;
    #warn "${type}::new(@_)\n";
    die "${type}::new: missing arguments\n"  if @_ < 6;
    my ($from, $to, $tally, $group, $threshold, $ignore) = @_;

    if ($threshold < 50 or $threshold > 100) {
	die "${type}::new: threshold '$threshold\%' outside valid range [50..100]\n";
    }

    my $self = {};

    bless $self, $type;

    $self->{'type'}      = 'consensus';
    $self->{'id'}        = "consensus/$threshold\%";
    $self->{'from'}      = $from;
    $self->{'to'}        = $to;
    $self->{'group'}     = $group;
    $self->{'threshold'} = $threshold;

    my $string =
        Bio::MView::Groupmap::consensus($tally, $group, $threshold, $ignore);

    #encode the new "sequence"
    $self->{'string'} = new Bio::MView::Sequence;
    $self->{'string'}->set_find_pad('\.');
    $self->{'string'}->set_find_gap('\.');
    $self->{'string'}->set_pad('.');
    $self->{'string'}->set_gap('.');
    $self->{'string'}->insert([$string, $from, $to]);

    $self->reset_display;

    $self;
}

#override
sub is_sequence { 0 }

#override
sub is_consensus { 1 }

#colours a row of consensus sequence.
# 1. give consensus symbols their own colour.
# 2. the consensus colormap is just one colour name, use that and ignore CSS.
# 3. the consensus may be a residue name: use prevailing residue colour.
# 4. use the prevailing wildcard residue colour.
# 5. give up.
sub get_color_type {
    my ($self, $c, $mapS, $mapG) = @_;
    #warn "get_color_type($self, $c, $mapS, $mapG)\n";

    if ($COLORMAP->has_symbol_color($mapG, $c)) {
        my ($color, $index, $trans) = $COLORMAP->get_symbol_color($mapG, $c);
	return ($color, "$trans$index");
    }

    if ($COLORMAP->has_palette_color($mapG)) {
        my ($color, $index, $trans) = $COLORMAP->get_palette_color($mapG);
        $trans = 'T';  #ignore CSS setting
        return ($color, "$trans$index");
    }

    if ($COLORMAP->has_symbol_color($mapS, $c)) {
        my ($color, $index, $trans) = $COLORMAP->get_symbol_color($mapS, $c);
	return ($color, "$trans$index");
    }

    if ($COLORMAP->has_wildcard_color($mapS)) {
        my ($color, $index, $trans) = $COLORMAP->get_wildcard_color($mapS);
	return ($color, "$trans$index");
    }

    return 0;  #no match
}

#colours a row of 'normal' sequence only where there is a consensus symbol.
# 1. give residues their own colour.
# 2. use the prevailing wildcard residue colour.
# 3. give up.
sub get_color_consensus_sequence {
    my ($self, $cs, $cg, $mapS, $mapG) = @_;
    #warn "get_color_consensus_sequence($self, $cs, $cg, $mapS, $mapG)\n";

    if ($COLORMAP->has_symbol_color($mapS, $cs)) {
        my ($color, $index, $trans) = $COLORMAP->get_symbol_color($mapS, $cs);
	return ($color, "$trans$index");
    }

    if ($COLORMAP->has_wildcard_color($mapS)) {
        my ($color, $index, $trans) = $COLORMAP->get_wildcard_color($mapS);
	return ($color, "$trans$index");
    }

    return 0;  #no match
}

#colours a row of 'normal' sequence using colour of consensus symbol.
# 1. give residues the colour of the consensus symbol.
# 2. the consensus may be a residue name: use prevailing residue colour.
# 3. use the prevailing wildcard residue colour.
# 4. give up.
sub get_color_consensus_group {
    my ($self, $cs, $cg, $mapS, $mapG) = @_;
    #warn "get_color_consensus_group($self, $cs, $cg, $mapS, $mapG)\n";

    if ($COLORMAP->has_symbol_color($mapG, $cg)) {
        my ($color, $index, $trans) = $COLORMAP->get_symbol_color($mapG, $cg);
	return ($color, "$trans$index");
    }

    if ($COLORMAP->has_symbol_color($mapS, $cg)) {
        my ($color, $index, $trans) = $COLORMAP->get_symbol_color($mapS, $cg);
	return ($color, "$trans$index");
    }

    if ($COLORMAP->has_wildcard_color($mapS)) {
        my ($color, $index, $trans) = $COLORMAP->get_wildcard_color($mapS);
	return ($color, "$trans$index");
    }

    return 0;  #no match
}

sub color_by_type {
    my ($self, $kw) = @_;

    my ($color, $end, $i, $cg, @tmp) = ($self->{'display'}->{'range'});

    push @$color, 1, $self->length, 'color' => $SYMCOLOR;

    #warn "color_by_type($self) 1=$kw->{'aln_colormap'} 2=$kw->{'con_colormap'}\n";

    for ($end=$self->length+1, $i=1; $i<$end; $i++) {

	$cg = $self->{'string'}->raw($i);

	#warn "[$i]= $cg\n";

	#white space: no color
	next  if $self->{'string'}->is_space($cg);

	#gap: gapcolour
	if ($self->{'string'}->is_non_char($cg)) {
	    push @$color, $i, 'color' => $kw->{'gapcolor'};
	    next;
	}

	#use symbol color/wildcard colour
	@tmp = $self->get_color_type($cg,
				     $kw->{'aln_colormap'},
				     $kw->{'con_colormap'});

        push @$color, $self->color_tag($kw->{'css1'}, $SYMCOLOR, $i, @tmp);
    }

    $self->{'display'}->{'paint'} = 1;
}

sub color_by_identity {
    my ($self, $kw, $othr) = @_;

    my ($color, $end, $i, $cg, @tmp) = ($self->{'display'}->{'range'});

    push @$color, 1, $self->length, 'color' => $SYMCOLOR;

    #warn "color_by_identity($self, $othr) 1=$kw->{'aln_colormap'} 2=$kw->{'con_colormap'}\n";

    for ($end=$self->length+1, $i=1; $i<$end; $i++) {

       $cg = $self->{'string'}->raw($i);

       #white space: no colour
       next  if $self->{'string'}->is_space($cg);

       #gap: gapcolour
       if ($self->{'string'}->is_non_char($cg)) {
           push @$color, $i, 'color' => $kw->{'gapcolor'};
           next;
       }

       #consensus group symbol is singleton: choose colour
       if ($GROUPMAP->is_singleton($self->{'group'}, $cg)) {

           #refer to reference colormap NOT the consensus colormap
           @tmp = $self->get_color($cg, $kw->{'aln_colormap'});

           push @$color, $self->color_tag($kw->{'css1'}, $SYMCOLOR, $i, @tmp);

           next;
       }

       #symbol not in consensus group: use contrast colour
       push @$color, $i, 'color' => $SYMCOLOR;
    }

    $self->{'display'}->{'paint'} = 1;
}

#this is analogous to Bio::MView::Align::Sequence::color_by_identity()
#but the roles of self (consensus) and other (sequence) are reversed.
sub color_by_consensus_sequence {
    my ($self, $kw, $othr) = @_;

    return  unless $othr;
    return  unless $othr->is_sequence;

    die "${self}::color_by_consensus_sequence: length mismatch\n"
	unless $self->length == $othr->length;

    my ($color, $end, $i, $cg, $cs, $c, @tmp) = ($othr->{'display'}->{'range'});

    push @$color, 1, $self->length, 'color' => $kw->{'symcolor'};

    #warn "color_by_consensus_sequence($self, $othr) 1=$kw->{'aln_colormap'} 2=$kw->{'con_colormap'}\n";

    for ($end=$self->length+1, $i=1; $i<$end; $i++) {

	$cg = $self->{'string'}->raw($i); $cs = $othr->{'string'}->raw($i);

	#warn "[$i]= $cg <=> $cs\n";

	#white space: no colour
	next  if $self->{'string'}->is_space($cs);

	#gap: gapcolour
	if ($self->{'string'}->is_non_char($cs)) {
	    push @$color, $i, 'color' => $kw->{'gapcolor'};
	    next;
	}

	#symbols in consensus group are stored upcased
	$c = uc $cs;

	#symbol in consensus group: choose colour
        if ($GROUPMAP->in_consensus_group($self->{'group'}, $cg, $c)) {

            #colour by sequence symbol
            @tmp = $self->get_color_consensus_sequence($cs, $cg,
                                                       $kw->{'aln_colormap'},
                                                       $kw->{'con_colormap'});

            push @$color,
                $self->color_tag($kw->{'css1'}, $kw->{'symcolor'}, $i, @tmp);

            next;
	}

        #symbol not in consensus group: use contrast colour
	push @$color, $i, 'color' => $kw->{'symcolor'};
    }

    $othr->{'display'}->{'paint'} = 1;
}

#this is analogous to Bio::MView::Align::Sequence::color_by_identity()
#but the roles of self (consensus) and other (sequence) are reversed.
sub color_by_consensus_group {
    my ($self, $kw, $othr) = @_;

    return  unless $othr;
    return  unless $othr->is_sequence;

    die "${self}::color_by_consensus_group: length mismatch\n"
	unless $self->length == $othr->length;

    my ($color, $end, $i, $cg, $cs, $c, @tmp) = ($othr->{'display'}->{'range'});

    push @$color, 1, $self->length, 'color' => $kw->{'symcolor'};

    #warn "color_by_consensus_group($self, $othr) 1=$kw->{'aln_colormap'} 2=$kw->{'con_colormap'}\n";

    for ($end=$self->length+1, $i=1; $i<$end; $i++) {

	$cg = $self->{'string'}->raw($i); $cs = $othr->{'string'}->raw($i);

	#warn "[$i]= $cg <=> $cs\n";

	#no sequence symbol: whitespace: no colour
	next  if $self->{'string'}->is_space($cs);

	#gap or frameshift: gapcolour
	if ($self->{'string'}->is_non_char($cs)) {
	    push @$color, $i, 'color' => $kw->{'gapcolor'};
	    next;
	}

	#symbols in consensus group are stored upcased
	$c = uc $cs;

	#symbol in consensus group: choose colour
        if ($GROUPMAP->in_consensus_group($self->{'group'}, $cg, $c)) {

            #colour by consensus group symbol
            #note: both symbols passed; colormaps swapped
            @tmp = $self->get_color_consensus_group($cs, $cg,
                                                    $kw->{'aln_colormap'},
                                                    $kw->{'con_colormap'});

            push @$color,
                $self->color_tag($kw->{'css1'}, $kw->{'symcolor'}, $i, @tmp);

            next;
	}

	#symbol not in consensus group: use contrast colour
	push @$color, $i, 'color' => $kw->{'symcolor'};
    }

    $othr->{'display'}->{'paint'} = 1;
}


###########################################################################
1;
