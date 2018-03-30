# Copyright (C) 1997-2018 Nigel P. Brown

use strict;

######################################################################
package Bio::MView::Manager;

use Bio::MView::Option::Parameters;  #for $PAR
use Bio::MView::Option::Arguments;
use Bio::MView::Color::ColorMap;
use Bio::MView::Display::Display;
use Bio::MView::Build;
use Bio::MView::Convert;

sub new {
    my $type = shift;
    my $self = {};
    bless $self, $type;

    $self->{'acount'}  = 0;
    $self->{'display'} = [];
    $self->{'file'}    = undef;
    $self->{'format'}  = undef;
    $self->{'stream'}  = undef;
    $self->{'filter'}  = undef;
    $self->{'class'}   = undef;

    $self;
}

######################################################################
# public class methods
######################################################################
sub check_input_file {
    my $file = shift;
    return Bio::MView::Option::Arguments::check_informat($file, 'file');
}

sub load_colormaps { Bio::MView::Color::ColorMap::load_colormaps(@_) }
sub dump_colormaps { Bio::MView::Color::ColorMap::dump_colormaps(@_) }
sub dump_css       { Bio::MView::Color::ColorMap::dump_css1(@_) }

sub load_groupmaps { Bio::MView::GroupMap::load_groupmaps(@_) }
sub dump_groupmaps { Bio::MView::GroupMap::dump_groupmaps(@_) }

######################################################################
# public methods
######################################################################
#Called with the desired format to be parsed: either a string 'X' naming a
#Parse::Format::X or a hint which will be recognised by that class.
sub parse {
    my ($self, $file, $format) = @_;

    $self->{'file'}   = $file;
    $self->{'format'} = lc $format;
    $self->{'class'}  = load_format_library($format);
    $self->{'stream'} = get_parser_stream($file, $self->{'class'});

    # warn $self->{'file'}, "\n";
    # warn $self->{'format'}, "\n";
    # warn $self->{'class'}, "\n";
    # warn $self->{'stream'}, "\n";

    return 0  unless defined $self->{'stream'};

    my ($first, $header1, $header2, $header3) = (1, '', '', '');

    #$header1 = $self->header;

    while (defined (my $bld = $self->next_build)) {

        $bld->reset;

        while (defined (my $aln = $bld->next_align)) {

	    if ($aln < 1) {  #null alignment
                #warn $PAR->get('prog') . ": empty alignment\n";
		next;
	    }

	    $self->{'acount'}++;

            if ($PAR->get('outfmt') ne 'mview') {
                $self->print_format_conversion($PAR, $bld, $aln);
                next;
            }

            my $dis = $self->add_display($bld, $aln);

	    if ($first-- > 0) {
		$header2 = $bld->header . $aln->header;
	    }
	    $header3 = $bld->subheader;

	    #add to display list
	    push @{$self->{'display'}}, [ $dis, $header1, $header2, $header3 ];

	    #display item now?
	    unless ($PAR->get('register')) {
		$self->print_alignment;
		#Universal::vmstat("Manager: print_alignment done");
	    }

	    $header1 = $header2 = $header3 = '';

	    #drop Align object to gc before next iteration
            $aln = undef;  #gc
            #Universal::vmstat("Manager: Align dropped");
        }

	#drop Build object to gc before next iteration
	$bld = undef;  #gc
        #Universal::vmstat("Manager: Build dropped");
    }

    return 1;
}

sub get_alignment_count { return $_[0]->{'acount'} }

sub print_alignment {
    my ($self, $stm) = (@_, \*STDOUT);

    my ($posnwidth, $labelflags, $labelwidths) = $self->initialise_labels;

    #consolidate field widths across multiple Display objects
    foreach my $dis (@{$self->{'display'}}) {

        #numeric left/right position width
        $posnwidth = Universal::max($posnwidth, $dis->[0]->{'posnwidth'});

        #labelwidths
        for (my $i=0; $i < @$labelflags; $i++) {
            if ($labelflags->[$i]) {
                $labelwidths->[$i] =
                    Universal::max($labelwidths->[$i],
                                   $dis->[0]->{'labelwidths'}->[$i]);
            }
        }
    }

    # warn "pw[$posnwidth]\n";
    # warn "lf[@{[join(',', @$labelflags)]}]\n";
    # warn "lw[@{[join(',', @$labelwidths)]}]\n";

    my $pass = 0;
    while (my $dis = shift @{$self->{'display'}}) {
        if ($PAR->get('html')) {
            $self->print_html_alignment($stm, $dis, $pass, $posnwidth,
                                        $labelflags, $labelwidths);
        } else {
            $self->print_text_alignment($stm, $dis, $pass, $posnwidth,
                                        $labelflags, $labelwidths);
        }
        $pass++;
    }
}

sub print_text_alignment {
    my ($self, $stm, $dis, $pass, $posnwidth, $labelflags, $labelwidths) = @_;

    #header
    print $stm "\n"       if $dis->[1] or $dis->[2];
    print $stm $dis->[1]  if $dis->[1];
    print $stm $dis->[2]  if $dis->[2];
    print "\n";

    #subheader
    print $stm $dis->[3], "\n"  if $dis->[3];

    #alignment
    $dis->[0]->display($stm,
                       'html'        => $PAR->get('html'),
                       'bold'        => $PAR->get('bold'),
                       'width'       => $PAR->get('width'),
                       'posnwidth'   => $posnwidth,
                       'labelflags'  => $labelflags,
                       'labelwidths' => $labelwidths,
    );
}

sub print_html_alignment {
    my ($self, $stm, $dis, $pass, $posnwidth, $labelflags, $labelwidths) = @_;

    my $alncolor   = $PAR->get('alncolor');
    my $labcolor   = $PAR->get('labcolor');
    my $linkcolor  = $PAR->get('linkcolor');
    my $alinkcolor = $PAR->get('alinkcolor');
    my $vlinkcolor = $PAR->get('vlinkcolor');

    #body attrs
    my $s = "style=\"border:0px;";
    if (! $PAR->get('css1')) {
        #supported in HTML 4.01:
        $s .= " background-color:$alncolor;"  if defined $alncolor;
        $s .= " color:$labcolor;"             if defined $labcolor;
        $s .= " a:link:$linkcolor;"           if defined $linkcolor;
        $s .= " a:active:$alinkcolor;"        if defined $alinkcolor;
        $s .= " a:visited:$vlinkcolor;"       if defined $vlinkcolor;
    }
    $s .= "\"";

    print $stm "<P>\n"  if $pass > 0;
    print $stm "<TABLE $s>\n";

    #header
    print $stm "<TR><TD><PRE>\n";
    print $stm $dis->[1]  if $dis->[1];
    print $stm $dis->[2]  if $dis->[2];
    print $stm "</PRE></TD></TR>\n";

    #subheader
    if ($dis->[3]) {
        print $stm "<TR><TD><PRE>\n";
        print $stm $dis->[3];
        print $stm "</PRE></TD></TR>\n";
    }

    #alignment
    print $stm "<TR><TD>\n";
    $dis->[0]->display($stm,
                       'html'        => $PAR->get('html'),
                       'bold'        => $PAR->get('bold'),
                       'width'       => $PAR->get('width'),
                       'posnwidth'   => $posnwidth,
                       'labelflags'  => $labelflags,
                       'labelwidths' => $labelwidths,
        );
    print $stm "</TD></TR>\n";

    print $stm "</TABLE>\n";
    print $stm "</P>\n"  if $pass > 0;
}

######################################################################
# private class methods
######################################################################
sub load_format_library {
    my $class = "Bio::MView::Build::Format::$_[0]";
    my $library = $class;
    $library =~ s/::/\//g;
    require "$library.pm";
    return $class;
}

sub get_format_parser {
    my $parser = $_[0] . "::parser";
    no strict 'refs';
    $parser = &$parser();
    use strict 'refs';
    return $parser;
}

sub get_parser_stream {
    my ($file, $class) = @_;
    my $parser = get_format_parser($class);
    return new NPB::Parse::Stream($file, $parser);
}

######################################################################
# private methods
######################################################################
#construct a header string describing this alignment
sub header {
    my ($self, $quiet) = (@_, 0);
    return ''  if $quiet;
    my $s = "File: $self->{'file'}  Format: $self->{'format'}\n";
    return $s;
}

#return next entry worth of parse data as in a Bio::MView::Build object
#ready for parsing, or undef if no more data.
sub next_build {
    my $self = shift;

    #free the last entry and garbage its Bio::MView::Build
    if (defined $self->{'filter'}) {
        $self->{'filter'}->get_entry->free;
        $self->{'filter'} = undef;
    }

    #read the next chunk of data
    my $entry = $self->{'stream'}->get_entry;
    if (! defined $entry) {
        $self->{'stream'}->close;
        return undef;
    }

    #construct a new Bio::MView::Build
    return $self->{'filter'} = $self->{'class'}->new($entry);
}

sub gc_flag {
    return 0  if $PAR->get('consensus');
    return 0  if $PAR->get('conservation');
    return 1;
}

sub initialise_labels {
    my $self = shift;

    my $posnwidth   = 0;   #default width of numeric left/rightpositions
    my $labelflags  = [];  #collected column on/off flags
    my $labelwidths = [];  #collected initial label widths

    push @$labelflags, $PAR->get('label0');
    push @$labelflags, $PAR->get('label1');
    push @$labelflags, $PAR->get('label2');
    push @$labelflags, $PAR->get('label3');
    push @$labelflags, $PAR->get('label4');
    push @$labelflags, $PAR->get('label5');
    push @$labelflags, $PAR->get('label6');
    push @$labelflags, $PAR->get('label7');

    for (my $i=0; $i < @$labelflags; $i++) {
        $labelwidths->[$i] = 0;
    }

    return ($posnwidth, $labelflags, $labelwidths);
}

sub add_display {
    my ($self, $bld, $aln) = @_;

    my $refobj = $bld->get_row_from_id($PAR->get('ref_id'));
    my $refid  = $bld->get_uid_from_id($PAR->get('ref_id'));

    #Universal::vmstat("display constructor");
    my $dis = new Bio::MView::Display::Display(
        [$refobj->display_column_widths],
        $aln->init_display);
    #Universal::vmstat("display constructor DONE");

    #attach a ruler? (may include header text)
    if ($PAR->get('ruler')) {
        my $tmp = $aln->build_ruler($refobj);
	$tmp->append_display($dis);
        #Universal::vmstat("ruler added");
    }

    #attach the alignment
    if ($PAR->get('alignment')) {
        $aln->set_color_scheme($refid);
        #Universal::vmstat("set_color_scheme done");
	$aln->append_display($dis, $self->gc_flag);
        #Universal::vmstat("alignment added");
    }

    #attach conservation line?
    if ($PAR->get('conservation')) {
	my $tmp = $aln->build_conservation_row;
	$tmp->append_display($dis);
        #Universal::vmstat("conservation added");
    }

    #attach consensus alignments?
    if ($PAR->get('consensus')) {
	my $tmp = $aln->build_consensus_rows;
        $tmp->set_consensus_color_scheme($aln, $refid);
	$tmp->append_display($dis);
        #Universal::vmstat("consensi added");
    }

    #garbage collect if not already done piecemeal
    if (!$self->gc_flag) {
	$aln->do_gc;
	#Universal::vmstat("final garbage collect");
    }
    return $dis;
}

sub print_format_conversion {
    my ($self, $par, $bld, $aln, $stm) = (@_, \*STDOUT);
    my $conv = new Bio::MView::Convert($bld, $aln, $par->get('moltype'));
    my $outfmt = $par->get('outfmt');
    my $s;
    while (1) {
        $s = $conv->clustal,  last  if $outfmt eq 'clustal';
        $s = $conv->msf,      last  if $outfmt eq 'msf';
        $s = $conv->pearson,  last  if $outfmt eq 'pearson';
        $s = $conv->pir,      last  if $outfmt eq 'pir';
        $s = $conv->plain,    last  if $outfmt eq 'plain';
        $s = $conv->rdb,      last  if $outfmt eq 'rdb';
        last;
    }
    print $stm $$s  if defined $s;
}

###########################################################################
1;
