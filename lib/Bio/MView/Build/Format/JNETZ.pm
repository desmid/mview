# Copyright (C) 1998-2018 Nigel P. Brown

###########################################################################
package Bio::MView::Build::Format::JNETZ;

use Bio::MView::Option::Parameters;  #for $PAR
use Bio::MView::Build::Align;
use strict;
use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Align);

#the name of the underlying NPB::Parse::Format parser
sub parser { 'JNETZ' }

sub parse {
    my $self = shift;
    my ($rank, $use, $aln, $id, $seq, $row, @hit) = (0);

    return  unless defined $self->{scheduler}->next;

    $aln = $self->{'entry'}->parse(qw(ALIGNMENT));

    my $i = 1; while ($i--) {
        $rank++; $id  = 'res';
        last  if $self->topn_done($rank);
        next  if $self->skip_row($rank, $rank, $id);
        $seq = $aln->get_query;
        $row = new Bio::MView::Build::Row::JNETZ($rank, $id, '', $seq);
        #no special subtype: use default
        push @hit, $row;

        $rank++; $id  = 'align';
        last  if $self->topn_done($rank);
        next  if $self->skip_row($rank, $rank, $id);
        $seq = $aln->get_align;
        $row = new Bio::MView::Build::Row::JNETZ($rank, $id, '', $seq);
        $row->set_subtype('jnet.pred'); #override the default
        push @hit, $row;

        $rank++; $id  = 'conf';
        last  if $self->topn_done($rank);
        next  if $self->skip_row($rank, $rank, $id);
        $seq = $aln->get_conf;
        $row = new Bio::MView::Build::Row::JNETZ($rank, $id, '', $seq);
        $row->set_subtype('jnet.conf'); #override the default
        push @hit, $row;

        $rank++; $id  = 'final';
        last  if $self->topn_done($rank);
        next  if $self->skip_row($rank, $rank, $id);
        $seq = $aln->get_final;
        $row = new Bio::MView::Build::Row::JNETZ($rank, $id, '', $seq);
        $row->set_subtype('jnet.pred'); #override the default
        push @hit, $row;
    }

    #map { $_->dump } @hit;

    #free objects
    $self->{'entry'}->free(qw(ALIGNMENT));

    return \@hit;
}

#override: set temporary parameters
sub adjust_parameters {
    my ($self, $aln) = @_;
    bless $aln, 'Bio::MView::Build::Format::JNETZ::Align';
    $aln->rebless_align_rows;

    #set parameters for this specific parse
    $PAR->set('label0', 0);  #don't report rank
    $PAR->set('label4', 0);  #don't report %coverage
    $PAR->set('label5', 0);  #don't report %identity
    $PAR->set('label6', 0);  #don't report sequence pos
    $PAR->set('label7', 0);  #don't report sequence pos

    $self;
}

#construct a header string describing this alignment
sub header {
    my ($self, $quiet) = (@_, 0);
    return ''  if $quiet;
    Bio::MView::Display::displaytext('');
}


###########################################################################
package Bio::MView::Build::Row::JNETZ;

use Bio::MView::Build::Row;
use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Simple_Row);

sub ignore_columns { ['desc', 'covr', 'pcid', 'posn1', 'posn2']; }


###########################################################################
package Bio::MView::Build::Format::JNETZ::Align;

use Bio::MView::Option::Parameters;  #for $PAR
use vars qw(@ISA);

@ISA = qw(Bio::MView::Align);

#use our own Align subclass instead of the generic one
sub rebless_align_rows {
    my $self = shift;
    foreach my $row (@{$self->{'index2row'}}) {
	next  unless defined $row;
	bless $row, 'Bio::MView::Build::Format::JNETZ::Align::Sequence';
    }
    $self;
}

#change the header text
sub header {
    my ($self, $quiet) = (@_, 0);
    return ''  if $quiet;
    my $s = '';
    $s .= "Residues colored by:  property\n";
    $s .= "Structure colored by: type\n";
    Bio::MView::Display::displaytext($s);
}

#ignore generic colouring schemes: use our own
sub set_color_scheme {
    my $self = shift;

    return $self  if $PAR->get('aln_coloring') eq 'none';

    $self->color_by_type($PAR);
    $self;
}

#propagate colour scheme to row objects
sub color_by_type {
    my $self = shift;

    foreach my $row (@{$self->{'index2row'}}) {
	next  unless defined $row;

        #sequence row: use default sequence colours, switch off css
	if ($row->{'type'} eq 'sequence') {
            my $kw = $PAR->as_dict('css1' => 0);
	    $row->color_jnetz_row($kw);
	    next;
	}

        #structure row: use our colours
	if ($row->{'type'} eq 'jnet.pred') {
            my $kw = $PAR->as_dict('aln_colormap' => 'JNET.PRED');
	    $row->color_jnetz_row($kw);
	    next;
	}

        #confidence row: use our colours
	if ($row->{'type'} eq 'jnet.conf') {
            my $kw = $PAR->as_dict('aln_colormap' => 'JNET.CONF');
	    $row->color_jnetz_row($kw);
	    next;
	}
    }
    $self;
}


###########################################################################
package Bio::MView::Build::Format::JNETZ::Align::Sequence;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Align::Sequence);

#the 0 here says don't override any colormap of the same name, to
#allow earler loaded user definitions priority - crude, but it'll do.
Bio::MView::Colormap::load_colormaps(\*DATA, 0);

sub color_jnetz_row {
    my ($self, $kw) = (shift, shift);

    my ($color, $end, $i, $c, @tmp) = ($self->{'display'}->{'range'});

    push @$color, 1, $self->length, 'color' => $kw->{'symcolor'};

    for ($end=$self->length+1, $i=1; $i<$end; $i++) {

	$c = $self->{'string'}->raw($i);

	#warn "[$i]= $c\n";

	#white space: no color
	next    if $self->{'string'}->is_space($c);

	#gap: gapcolour
	if ($self->{'string'}->is_non_char($c)) {
	    push @$color, $i, 'color' => $kw->{'gapcolor'};
	    next;
	}

	#use symbol color/wildcard colour
	@tmp = $self->get_color($c, $kw->{'aln_colormap'});

        push @$color,
            $self->color_tag($kw->{'css1'}, $kw->{'symcolor'}, $i, @tmp);
    }

    $self->{'display'}->{'paint'}  = 1;
    $self;
}


###########################################################################
1;

__DATA__

[JNET.PRED]
Hh  =>  bright-red      #helix
Ee  =>  bright-blue     #sheet
Ll  =>  dark-green      #coil

[JNET.CONF]
0   ->  gray0           #bad
1   ->  gray1
2   ->  gray2
3   ->  gray4
4   ->  gray6
5   ->  gray8
6   ->  gray10
7   ->  gray12
8   ->  gray14
9   ->  gray15          #good

###########################################################################
