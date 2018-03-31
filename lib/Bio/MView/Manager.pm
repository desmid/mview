# Copyright (C) 1997-2018 Nigel P. Brown

use strict;

######################################################################
package Bio::MView::Manager;

use Universal qw(max vmstat);
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

    my $pass = 0;
    while (my $bld = $self->next_build) {

        last  unless defined $bld;  #all done

        $bld->reset;

        while (defined (my $aln = $bld->next_align)) {

	    if ($aln < 1) {  #empty alignment
                #warn $PAR->get('prog') . ": empty alignment\n";
		next;
	    }

            $self->{'acount'}++;

            if ($PAR->get('outfmt') ne 'mview') {

                $self->print_format_conversion($PAR, $bld, $aln);

            } else {

                $self->add_alignment_display($bld, $aln, $pass++);

                #display item now?
                unless ($PAR->get('register')) {
                    $self->print_alignment_display;
                    #vmstat("Manager: print_alignment done");
                }
            }

            $aln = undef;  #gc
            #vmstat("Manager: Align dropped");
        }

	$bld = undef;  #gc
        #vmstat("Manager: Build dropped");
    }

    return 1;
}

sub get_alignment_count { return $_[0]->{'acount'} }

sub print_alignment_display {
    my ($self, $stm) = (@_, \*STDOUT);

    my ($posnwidth, $labelflags, $labelwidths) = $self->initialise_labels;

    #consolidate field widths across multiple Display objects
    foreach my $dis (@{$self->{'display'}}) {

        #numeric left/right position width
        $posnwidth = max($posnwidth, $dis->{'posnwidth'});

        #labelwidths
        for (my $i=0; $i < @$labelflags; $i++) {
            if ($labelflags->[$i]) {
                $labelwidths->[$i] =
                    max($labelwidths->[$i],
                                   $dis->{'labelwidths'}->[$i]);
            }
        }
    }

    # warn "pw[$posnwidth]\n";
    # warn "lf[@{[join(',', @$labelflags)]}]\n";
    # warn "lw[@{[join(',', @$labelwidths)]}]\n";

    my $pass = 0;
    while (my $dis = shift @{$self->{'display'}}) {
        if ($PAR->get('html')) {
            print $stm "<P>\n"   if $pass > 0;
            $self->print_html_alignment($stm, $dis, $posnwidth,
                                        $labelflags, $labelwidths);
            print $stm "</P>\n"  if $pass > 0;
        } else {
            print $stm "\n"  if $dis->{'headers'}->[0] or $dis->{'headers'}->[1];
            $self->print_text_alignment($stm, $dis, $posnwidth,
                                        $labelflags, $labelwidths);
        }
        $pass++;
    }
}

sub print_text_alignment {
    my ($self, $stm, $dis, $posnwidth, $labelflags, $labelwidths) = @_;

    #header
    print $stm $dis->{'headers'}->[0]  if $dis->{'headers'}->[0];
    print $stm $dis->{'headers'}->[1]  if $dis->{'headers'}->[1];
    print "\n";

    #subheader
    print $stm $dis->{'headers'}->[2], "\n"  if $dis->{'headers'}->[2];

    #alignment
    $dis->display($stm,
                  'html'        => $PAR->get('html'),
                  'bold'        => $PAR->get('bold'),
                  'width'       => $PAR->get('width'),
                  'posnwidth'   => $posnwidth,
                  'labelflags'  => $labelflags,
                  'labelwidths' => $labelwidths,
    );
}

sub print_html_alignment {
    my ($self, $stm, $dis, $posnwidth, $labelflags, $labelwidths) = @_;

    my $alncolor   = $PAR->get('alncolor');
    my $labcolor   = $PAR->get('labcolor');
    my $linkcolor  = $PAR->get('linkcolor');
    my $alinkcolor = $PAR->get('alinkcolor');
    my $vlinkcolor = $PAR->get('vlinkcolor');

    #table attrs
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

    print $stm "<TABLE $s>\n";

    #header
    if ($dis->{'headers'}->[0]) {
        print $stm "<TR><TD><PRE>\n";
        print $stm $dis->{'headers'}->[0];
        print $stm "</PRE></TD></TR>\n";
    }
    if ($dis->{'headers'}->[1]) {
        print $stm "<TR><TD><PRE>\n";
        print $stm $dis->{'headers'}->[1];
        print $stm "</PRE></TD></TR>\n";
    }

    #subsubheader
    if ($dis->{'headers'}->[2]) {
        print $stm "<TR><TD><PRE>\n";
        print $stm $dis->{'headers'}->[2];
        print $stm "</PRE></TD></TR>\n";
    }

    #alignment
    print $stm "<TR><TD>\n";
    $dis->display($stm,
                  'html'        => $PAR->get('html'),
                  'bold'        => $PAR->get('bold'),
                  'width'       => $PAR->get('width'),
                  'posnwidth'   => $posnwidth,
                  'labelflags'  => $labelflags,
                  'labelwidths' => $labelwidths,
    );
    print $stm "</TD></TR>\n";

    print $stm "</TABLE>\n";
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

sub add_alignment_display {
    my ($self, $bld, $aln, $pass) = @_;

    my $refobj = $bld->get_row_from_id($PAR->get('ref_id'));
    my $refid  = $bld->get_uid_from_id($PAR->get('ref_id'));

    my ($header0, $header1, $header2) = ('', '', '');

    if ($pass < 1) {
        #$header0 = $self->header;
        $header1 = $bld->header . $aln->header;
    }
    $header2 = $bld->subheader;

    #vmstat("display constructor");
    my $dis = new Bio::MView::Display::Display(
        [$refobj->display_column_widths],
        [$header0, $header1, $header2],
        $aln->init_display,
        );
    #vmstat("display constructor DONE");

    #attach a ruler? (may include header text)
    if ($PAR->get('ruler')) {
        my $tmp = $aln->build_ruler($refobj);
	$tmp->append_display($dis);
        #vmstat("ruler added");
    }

    #attach the alignment
    if ($PAR->get('alignment')) {
        $aln->set_color_scheme($refid);
        #vmstat("set_color_scheme done");
	$aln->append_display($dis, $self->gc_flag);
        #vmstat("alignment added");
    }

    #attach conservation line?
    if ($PAR->get('conservation')) {
	my $tmp = $aln->build_conservation_row;
	$tmp->append_display($dis);
        #vmstat("conservation added");
    }

    #attach consensus alignments?
    if ($PAR->get('consensus')) {
	my $tmp = $aln->build_consensus_rows;
        $tmp->set_consensus_color_scheme($aln, $refid);
	$tmp->append_display($dis);
        #vmstat("consensi added");
    }

    #garbage collect if not already done piecemeal
    if (!$self->gc_flag) {
	$aln->do_gc;
	#vmstat("final garbage collect");
    }

    #save this display
    push @{$self->{'display'}}, $dis;
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
