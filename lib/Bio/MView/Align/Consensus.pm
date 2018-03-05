# Copyright (C) 1997-2018 Nigel P. Brown

###########################################################################
package Bio::MView::Align::Consensus;

use Kwargs;
use Bio::MView::Groupmap;
use Bio::MView::Align;
use Bio::MView::Display;
use Bio::MView::Align::Row;

@ISA = qw(Bio::MView::Align::Sequence);

use strict;
use vars qw($Default_PRO_Colormap $Default_DNA_Colormap $Default_Colormap
	    $Group_Any $Default_Group_Any $Default_Ignore $KWARGS);

$Default_PRO_Colormap = 'PC1';    #default colormap name
$Default_DNA_Colormap = 'DC1';    #default colormap name
$Default_Colormap     = $Default_PRO_Colormap;  #NIGE

$Default_Ignore       = 'none';   #default ignore classes setting  #NIGE

$KWARGS = {
    'colormapc' => $Default_Colormap,
};

my $Group             = $Bio::MView::Groupmap::Group;
my $Group_Any         = $Bio::MView::Groupmap::Group_Any;
my $Default_Group_Any = $Bio::MView::Groupmap::Default_Group_Any;

my %Known_Ignore_Class =
    (
     #name
     'none'       => 1,    #don't ignore
     'singleton'  => 1,    #ignore singleton, ie., self-only consensi
     'class'      => 1,    #ignore non-singleton, ie., class consensi
    );

sub list_ignore_classes { return join(",", sort keys %Known_Ignore_Class) }

sub check_ignore_class {
    if (exists $Known_Ignore_Class{lc $_[0]}) {
        return lc $_[0];
    }
    return undef;
}

sub get_color_identity { my $self = shift; $self->SUPER::get_color(@_) }

#colours a row of consensus sequence.
#philosophy:
#  1. the consensus colormap is just one colour name, use that and ignore CSS.
#  2. give consensus symbols their own colour.
#  3. the consensus may be a residue name: use prevailing residue colour.
#  4. use the prevailing wildcard residue colour.
#  5. give up.
sub get_color_type {
    my ($self, $c, $mapS, $mapG) = @_;
    my ($index, $color, $trans);

    #warn "get_color_type($self, $c, $mapS, $mapG)\n";

    my @tmp = keys %{$Bio::MView::Colormap::Colormaps->{$mapG}};

    #colormap is preset colorname
    if (@tmp < 1) {
        if (exists $Bio::MView::Colormap::Palette->[0]->{$mapG}) {
            $trans = 'T';  #ignore CSS setting
            $index = $Bio::MView::Colormap::Palette->[0]->{$mapG};
            $color = $Bio::MView::Colormap::Palette->[1]->[$index];

            #warn "$c $mapG\{$c} [$index] [$color] [$trans]\n";

            return ($color, "$trans$index");
        }
    }

    #look in group colormap
    if (exists $Bio::MView::Colormap::Colormaps->{$mapG}->{$c}) {

	#set transparent(T)/solid(S)
	$trans = $Bio::MView::Colormap::Colormaps->{$mapG}->{$c}->[1];
	$index = $Bio::MView::Colormap::Colormaps->{$mapG}->{$c}->[0];
	$color = $Bio::MView::Colormap::Palette->[1]->[$index];

	#warn "$c $mapG\{$c} [$index] [$color] [$trans]\n";
	
	return ($color, "$trans$index");
    }

    #look in sequence colormap
    if (exists $Bio::MView::Colormap::Colormaps->{$mapS}->{$c}) {

	#set transparent(T)/solid(S)
	$trans = $Bio::MView::Colormap::Colormaps->{$mapS}->{$c}->[1];
	$index = $Bio::MView::Colormap::Colormaps->{$mapS}->{$c}->[0];
	$color = $Bio::MView::Colormap::Palette->[1]->[$index];

	#warn "$c $mapS\{$c} [$index] [$color] [$trans]\n";
	
	return ($color, "$trans$index");
    }

    #look for wildcard in sequence colormap
    if (exists $Bio::MView::Colormap::Colormaps->{$mapS}->{$Group_Any}) {

	#set transparent(T)/solid(S)
	$trans = $Bio::MView::Colormap::Colormaps->{$mapS}->{$Group_Any}->[1];
	$index = $Bio::MView::Colormap::Colormaps->{$mapS}->{$Group_Any}->[0];
	$color = $Bio::MView::Colormap::Palette->[1]->[$index];

	#warn "$c $mapS\{$Group_Any} [$index] [$color] [$trans]\n";
	
	return ($color, "$trans$index");
    }

    return 0;    #no match
}

#colours a row of 'normal' sequence only where there is a consensus symbol.
#philosophy:
#  1. give residues their own colour.
#  2. use the prevailing wildcard residue colour.
#  3. give up.
sub get_color_consensus_sequence {
    my ($self, $cs, $cg, $mapS, $mapG) = @_;
    my ($index, $color, $trans);

    #warn "get_color_consensus_sequence($self, $cs, $cg, $mapS, $mapG)\n";

    #lookup sequence symbol in sequence colormap
    if (exists $Bio::MView::Colormap::Colormaps->{$mapS}->{$cs}) {

	#set transparent(T)/solid(S)
	$trans = $Bio::MView::Colormap::Colormaps->{$mapS}->{$cs}->[1];
	$index = $Bio::MView::Colormap::Colormaps->{$mapS}->{$cs}->[0];
	$color = $Bio::MView::Colormap::Palette->[1]->[$index];

	#warn "$cs/$cg $mapS\{$cs} [$index] [$color] [$trans]\n";
	
	return ($color, "$trans$index");
    }

    #lookup wildcard in sequence colormap
    if (exists $Bio::MView::Colormap::Colormaps->{$mapS}->{$Group_Any}) {

	#set transparent(T)/solid(S)
	$trans = $Bio::MView::Colormap::Colormaps->{$mapS}->{$Group_Any}->[1];
	$index = $Bio::MView::Colormap::Colormaps->{$mapS}->{$Group_Any}->[0];
	$color = $Bio::MView::Colormap::Palette->[1]->[$index];

	#warn "$cs/$cg $mapS\{$Group_Any} [$index] [$color] [$trans]\n";
	
	return ($color, "$trans$index");
    }

    return 0;    #no match
}

#colours a row of 'normal' sequence using colour of consensus symbol.
#philosophy:
#  1. give residues the colour of the consensus symbol.
#  2. the consensus may be a residue name: use prevailing residue colour.
#  3. use the prevailing wildcard residue colour.
#  4. give up.
sub get_color_consensus_group {
    my ($self, $cs, $cg, $mapS, $mapG) = @_;
    my ($index, $color, $trans);

    #warn "get_color_consensus_group($self, $cs, $cg, $mapS, $mapG)\n";

    #lookup group symbol in group colormap
    if (exists $Bio::MView::Colormap::Colormaps->{$mapG}->{$cg}) {

	#set transparent(T)/solid(S)/color from GROUP colormap
	$trans = $Bio::MView::Colormap::Colormaps->{$mapG}->{$cg}->[1];
	$index = $Bio::MView::Colormap::Colormaps->{$mapG}->{$cg}->[0];
	$color = $Bio::MView::Colormap::Palette->[1]->[$index];
	#warn "$cs/$cg $mapG\{$cg} [$index] [$color] [$trans]\n";

	return ($color, "$trans$index");
    }

    #lookup group symbol in sequence colormap
    if (exists $Bio::MView::Colormap::Colormaps->{$mapS}->{$cg}) {

	#set transparent(T)/solid(S)/color from SEQUENCE colormap
	$trans = $Bio::MView::Colormap::Colormaps->{$mapS}->{$cg}->[1];
	$index = $Bio::MView::Colormap::Colormaps->{$mapS}->{$cg}->[0];
	$color = $Bio::MView::Colormap::Palette->[1]->[$index];
	#warn "$cs/$cg $mapS\{$cg} [$index] [$color] [$trans]\n";
	
	return ($color, "$trans$index");
    }

    #lookup wildcard in SEQUENCE colormap
    if (exists $Bio::MView::Colormap::Colormaps->{$mapS}->{$Group_Any}) {

	#set transparent(T)/solid(S)/color from SEQUENCE colormap
	$trans = $Bio::MView::Colormap::Colormaps->{$mapS}->{$Group_Any}->[1];
	$index = $Bio::MView::Colormap::Colormaps->{$mapS}->{$Group_Any}->[0];
	$color = $Bio::MView::Colormap::Palette->[1]->[$index];
	#warn "$cs/$cg $mapS\{$Group_Any} [$index] [$color] [$trans]\n";
	
	return ($color, "$trans$index");
    }

    return 0;    #no match
}

sub tally {
    my ($group, $col, $gaps) = (@_, 1);
    my ($score, $class, $sym, $depth) = ({});

    if (! exists $Group->{$group}) {
	die "Bio::MView::Align::Consensus::tally() unknown consensus set\n";
    }

    #warn "tally: $group\n";

    $group = $Group->{$group}->[0];

    #initialise tallies
    foreach $class (keys %$group) { $score->{$class} = 0 }

    #select score normalization
    if ($gaps) {
	#by total number of rows (sequence + non-sequence)
	$depth = @$col;
    } else {
	#by rows containing sequence in this column
	$depth = 0;
	map { $depth++ if Bio::MView::Sequence::is_char(0, $_) } @$col;
    }
    #warn "($group, [@$col], $gaps, $depth)\n";

    #empty column? use gap symbol
    if ($depth < 1) {
	$score->{''} = 100;
	return $score;
    }

    #tally class scores by column symbol (except gaps), which is upcased
    foreach $class (keys %$group) {
	foreach $sym (@$col) {
	    next    unless Bio::MView::Sequence::is_char(0, $sym) or $gaps;
	    $score->{$class}++    if exists $group->{$class}->[1]->{uc $sym};
	}
	$score->{$class} = 100.0 * $score->{$class} / $depth;
    }
    $score;
}

sub consensus {
    my ($tally, $group, $threshold, $ignore) = @_;
    my ($class, $bstclass, $bstscore, $consensus, $i, $score);

    if (! exists $Group->{$group}) {
	die "Bio::MView::Align::Consensus::consensus() unknown consensus set\n";
    }

    $group = $Group->{$group}->[0];

    $consensus = '';

    #iterate over all columns
    for ($i=0; $i<@$tally; $i++) {
	
	($score, $class, $bstclass, $bstscore) = ($tally->[$i], "", undef, 0);
	
	#iterate over all allowed subsets
	foreach $class (keys %$group) {

	    next    if $class eq $Group_Any; #wildcard
	
	    if ($class ne '') {
		#non-gap classes: may want to ignore certain classes
		next if $ignore eq 'singleton' and $class eq $group->{$class}->[0];
		
		next if $ignore eq 'class'     and $class ne $group->{$class}->[0];
	    }
	
	    #choose smallest class exceeding threshold and
	    #highest percent when same size
	
	    #warn "[$i] $class, $score->{$class}\n";

	    if ($score->{$class} >= $threshold) {
		
		#first pass
		if (! defined $bstclass) {
		    $bstclass = $class;
		    $bstscore = $score->{$class};
		    next;
		}
		
		#larger? this set should be rejected
		if (keys %{$group->{$class}->[1]} >
		    keys %{$group->{$bstclass}->[1]}) {
		    next;
		}
		
		#smaller? this set should be kept
		if (keys %{$group->{$class}->[1]} <
		    keys %{$group->{$bstclass}->[1]}) {
		    $bstclass = $class;
		    $bstscore = $score->{$class};
		    next;
		}
		
		#same size: new set has better score?
		if ($score->{$class} > $bstscore) {
		    $bstclass = $class;
		    $bstscore = $score->{$class};
		    next;
		}
	    }
	}

	if (defined $bstclass) {
	    if ($bstclass eq '' and $bstscore < 100) {
		$bstclass = $Group_Any #some non-gaps
	    }
	} else {
	    $bstclass = $Group_Any #wildcard
	}
	#warn "DECIDE [$i] '$bstclass' $bstscore [$group->{$bstclass}->[0]]\n";
	$consensus .= $group->{$bstclass}->[0];
    }
    \$consensus;
}

sub new {
    my $type = shift;
    #warn "${type}::new() (@_)\n";
    if (@_ < 5) {
	die "${type}::new() missing arguments\n";
    }
    my ($from, $to, $tally, $group, $threshold, $ignore) = @_;

    if ($threshold < 50 or $threshold > 100) {
	die "${type}::new() threshold '$threshold\%' outside valid range [50..100]\n";
    }

    my $self = { %Bio::MView::Align::Sequence::Template };

    $self->{'id'}        = "consensus/$threshold\%";
    $self->{'type'}      = 'consensus';
    $self->{'from'}      = $from;
    $self->{'to'}        = $to;
    $self->{'threshold'} = $threshold;
    $self->{'group'}     = $group;

    my $string = consensus($tally, $group, $threshold, $ignore);

    #encode the new "sequence"
    $self->{'string'} = new Bio::MView::Sequence;
    $self->{'string'}->set_find_pad('\.');
    $self->{'string'}->set_find_gap('\.');
    $self->{'string'}->set_pad('.');
    $self->{'string'}->set_gap('.');
    $self->{'string'}->insert([$string, $from, $to]);

    bless $self, $type;

    $self->reset_display;

    $self;
}

sub color_by_type {
    my $self = shift;

    return unless $self->{'type'} eq 'consensus';

    my $kw = Kwargs::set(@_);

    my ($color, $end, $i, $cg, @tmp) = ($self->{'display'}->{'range'});

    push @$color, 1, $self->length, 'color' => $kw->{'symcolor'};

    #warn "color_by_type($self) 1=$kw->{'colormap'} 2=$kw->{'colormapc'}\n";

    for ($end=$self->length+1, $i=1; $i<$end; $i++) {

	$cg = $self->{'string'}->raw($i);
	
	#warn "[$i]= $cg\n";

	#white space: no color
	next    if $self->{'string'}->is_space($cg);

	#gap: gapcolour
	if ($self->{'string'}->is_non_char($cg)) {
	    push @$color, $i, 'color' => $kw->{'gapcolor'};
	    next;
	}
	
	#use symbol color/wildcard colour
	@tmp = $self->get_color_type($cg,
				     $kw->{'colormap'},
				     $kw->{'colormapc'});
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
    my ($self, $othr) = (shift, shift);    #ignore second arg

    return unless $self->{'type'} eq 'consensus';

    my $kw = Kwargs::set(@_);

    my ($color, $end, $i, $cg, @tmp) = ($self->{'display'}->{'range'});

    push @$color, 1, $self->length, 'color' => $kw->{'symcolor'};

    #warn "color_by_identity($self, $othr) 1=$kw->{'colormap'} 2=$kw->{'colormapc'}\n";

    for ($end=$self->length+1, $i=1; $i<$end; $i++) {

       $cg = $self->{'string'}->raw($i);

       #white space: no colour
       next    if $self->{'string'}->is_space($cg);

       #gap: gapcolour
       if ($self->{'string'}->is_non_char($cg)) {
           push @$color, $i, 'color' => $kw->{'gapcolor'};
           next;
       }

       #consensus group symbol is singleton: choose colour
       if (exists $Group->{$self->{'group'}}->[2]->{$cg}) {
           if (keys %{$Group->{$self->{'group'}}->[2]->{$cg}} == 1) {

               #refer to reference colormap NOT the consensus colormap
               @tmp = $self->get_color_identity($cg, $kw->{'colormap'});

               if (@tmp) {
                   if ($kw->{'css1'}) {
                       push @$color, $i, 'class' => $tmp[1];
                   } else {
                       push @$color, $i, 'color' => $tmp[0];
                   }
               } else {
                   push @$color, $i, 'color' => $kw->{'symcolor'};
               }

               next;
           }
       }

       #symbol not in consensus group: use contrast colour
       push @$color, $i, 'color' => $kw->{'symcolor'};
    }

    $self->{'display'}->{'paint'} = 1;
    $self;
}

sub color_by_mismatch { die "function undefined\n"; }

#this is analogous to Bio::MView::Align::Row::Sequence::color_by_identity()
#but the roles of self (consensus) and other (sequence) are reversed.
sub color_by_consensus_sequence {
    my ($self, $othr) = (shift, shift);

    return unless $othr;
    return unless $othr->{'type'} eq 'sequence';

    die "${self}::color_by_consensus_sequence() length mismatch\n"
	unless $self->length == $othr->length;

    my $kw = Kwargs::set(@_);

    my ($color, $end, $i, $cg, $cs, $c, @tmp) = ($othr->{'display'}->{'range'});

    push @$color, 1, $self->length, 'color' => $kw->{'symcolor'};

    #warn "color_by_consensus_sequence($self, $othr) 1=$kw->{'colormap'} 2=$kw->{'colormapc'}\n";

    for ($end=$self->length+1, $i=1; $i<$end; $i++) {

	$cg = $self->{'string'}->raw($i); $cs = $othr->{'string'}->raw($i);

	#warn "[$i]= $cg <=> $cs\n";

	#white space: no colour
	next    if $self->{'string'}->is_space($cs);
					
	#gap: gapcolour
	if ($self->{'string'}->is_non_char($cs)) {
	    push @$color, $i, 'color' => $kw->{'gapcolor'};
	    next;
	}
	
	#symbols in consensus group are stored upcased
	$c = uc $cs;

	#symbol in consensus group: choose colour
	if (exists $Group->{$self->{'group'}}->[1]->{$c}) {
	    if (exists $Group->{$self->{'group'}}->[1]->{$c}->{$cg}) {

		#colour by sequence symbol
		@tmp = $self->get_color_consensus_sequence($cs, $cg,
							   $kw->{'colormap'},
							   $kw->{'colormapc'});
		if (@tmp) {
		    if ($kw->{'css1'}) {
			push @$color, $i, 'class' => $tmp[1];
		    } else {
			push @$color, $i, 'color' => $tmp[0];
		    }
		} else {
		    push @$color, $i, 'color' => $kw->{'symcolor'};
		}

		next;
	    }
	}

        #symbol not in consensus group: use contrast colour
	push @$color, $i, 'color' => $kw->{'symcolor'};
    }

    $othr->{'display'}->{'paint'} = 1;
    $self;
}


#this is analogous to Bio::MView::Align::Row::Sequence::color_by_identity()
#but the roles of self (consensus) and other (sequence) are reversed.
sub color_by_consensus_group {
    my ($self, $othr) = (shift, shift);

    return unless $othr;
    return unless $othr->{'type'} eq 'sequence';

    die "${self}::color_by_consensus_group() length mismatch\n"
	unless $self->length == $othr->length;

    my $kw = Kwargs::set(@_);

    my ($color, $end, $i, $cg, $cs, $c, @tmp) = ($othr->{'display'}->{'range'});

    push @$color, 1, $self->length, 'color' => $kw->{'symcolor'};

    #warn "color_by_consensus_group($self, $othr) 1=$kw->{'colormap'} 2=$kw->{'colormapc'}\n";

    for ($end=$self->length+1, $i=1; $i<$end; $i++) {

	$cg = $self->{'string'}->raw($i); $cs = $othr->{'string'}->raw($i);

	#warn "[$i]= $cg <=> $cs\n";
	
	#no sequence symbol: whitespace: no colour
	next    if $self->{'string'}->is_space($cs);

	#gap or frameshift: gapcolour
	if ($self->{'string'}->is_non_char($cs)) {
	    push @$color, $i, 'color' => $kw->{'gapcolor'};
	    next;
	}
	
	#symbols in consensus group are stored upcased
	$c = uc $cs;

	#symbol in consensus group: choose colour
	if (exists $Group->{$self->{'group'}}->[1]->{$c}) {
	    if (exists $Group->{$self->{'group'}}->[1]->{$c}->{$cg}) {

		#colour by consensus group symbol
		#note: both symbols passed; colormaps swapped
		@tmp = $self->get_color_consensus_group($cs, $cg,
							$kw->{'colormap'},
							$kw->{'colormapc'});
		if (@tmp) {
		    if ($kw->{'css1'}) {
			push @$color, $i, 'class' => $tmp[1];
		    } else {
			push @$color, $i, 'color' => $tmp[0];
		    }
		} else {
		    push @$color, $i, 'color' => $kw->{'symcolor'};
		}

		next;
	    }
	}
	
	#symbol not in consensus group: use contrast colour
	push @$color, $i, 'color' => $kw->{'symcolor'};
    }

    $othr->{'display'}->{'paint'} = 1;
    $self;
}


###########################################################################
1;
