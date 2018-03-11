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

    while (1) {
        $rank++; last  if $self->topn_done($rank);

        $seq = $aln->get_query;
        $row = new Bio::MView::Build::Row::JNETZ($rank, 'res', '', $seq);
        push @hit, $row;

        $rank++; last  if $self->topn_done($rank);

        $seq = $aln->get_align;
        $row = new Bio::MView::Build::Row::JNETZ($rank, 'align', '', $seq);
        $row->set_subtype('jnet.pred'); #override default
        push @hit, $row;

        $rank++; last  if $self->topn_done($rank);

        $seq = $aln->get_conf;
        $row = new Bio::MView::Build::Row::JNETZ($rank, 'conf', '', $seq);
        $row->set_subtype('jnet.conf'); #override default
        push @hit, $row;

        $rank++; last  if $self->topn_done($rank);

        $seq = $aln->get_final;
        $row = new Bio::MView::Build::Row::JNETZ($rank, 'final', '', $seq);
        $row->set_subtype('jnet.pred'); #override default
        push @hit, $row;

        last;
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
    return Bio::MView::Display::displaytext('');
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

#change the header text
sub header {
    my ($self, $quiet) = (@_, 0);
    return ''  if $quiet;
    my $s = '';
    $s .= "Residues colored by:  property\n";
    $s .= "Structure colored by: type\n";
    return Bio::MView::Display::displaytext($s);
}

#ignore generic colouring schemes: use our own
sub set_color_scheme {
    my $self = shift;

    return $self  if $PAR->get('aln_coloring') eq 'none';

    $self->color_special;
}

#propagate colour scheme to row objects
sub color_special {
    my $self = shift;

    foreach my $row (@{$self->{'index2row'}}) {
	next  unless defined $row;

        #sequence row: use default sequence colours, switch off css
	if ($row->{'type'} eq 'sequence') {
            my $kw = $PAR->as_dict('css1' => 0);
            $row->color_special_body($kw);
	    next;
	}

        #structure row: use our colours
	if ($row->{'type'} eq 'jnet.pred') {
            my $kw = $PAR->as_dict('aln_colormap' => 'JNET.PRED');
            $row->color_special_body($kw);
	    next;
	}

        #confidence row: use our colours
	if ($row->{'type'} eq 'jnet.conf') {
            my $kw = $PAR->as_dict('aln_colormap' => 'JNET.CONF');
            $row->color_special_body($kw);
	    next;
	}
    }
}


###########################################################################
package Bio::MView::Build::Format::JNETZ::Align::Sequence;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Align::Sequence);


###########################################################################
#the 0 here says don't override any colormap of the same name, to
#allow earler loaded user definitions priority - crude, but it'll do.
Bio::MView::Colormap::load_colormaps(\*DATA, 0);

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
