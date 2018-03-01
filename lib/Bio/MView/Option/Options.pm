# Copyright (C) 2018 Nigel P. Brown

######################################################################
package Bio::MView::Option::Options;

use Bio::MView::Option::Arguments;
use Bio::MView::Option::Types;
use strict;
use vars qw($Header $Groups $Options);

###########################################################################
sub get_default_gap { Bio::MView::Build::get_default_gap }

###########################################################################
$Header = "usage: <PROG> [options] [file...]

Option names and parameter values can generally be abbreviated. Alternative
parameter values are listed in braces {}, followed by the default value in
square brackets [].

Some options take multiple arguments which must be supplied as a comma
separated list, like '1,8,9,10'. Subranges are allowed, so you could also
write that as '1,8:10' or even '1,8..10'. Any argument must be quoted if it
contains whitespace or a wildcard that might be expanded by the shell.

";

###########################################################################
$Groups = [
    {
        'group'  => "HIDDEN",
    },

    {
        'group'  => 'FORMATS',
        'header' => "Input/output formats:",
    },

    {
        'group'  => "CONTENT",
        'header' => "Main formatting options:",
    },

    {
        'group'  => "IDENTITY",
        'header' => "Percent identity calculations and filters:",
    },

    {
        'group'  => "FILTER",
        'header' => "General row/column filters:",
    },

    {
        'group'  => "MOLTYPE",
        'header' => "Molecule type:",
    },

    {
        'group'  => "ALIGNMENT",
        'header' => "Alignment coloring:",
    },

    {
        'group'  => "CONSENSUS",
        'header' => "Consensus coloring:",
    },

    {
        'group'  => "PATTERNS",
        'header' => "Motif colouring:",
    },

    {
        'group'  => "MISC_FORMATTING",
        'header' => "Miscellaneous formatting:",
    },

    {
        'group'  => "HTML",
        'header' => "HTML markup:",
    },

    {
        'group'  => "SRS_LINKS",
        'header' => "Database links:",
    },

    ##################################################
    # formats
    ##################################################

    { 'group'  => "BLAST1",
      'header' => "NCBI BLAST (series 1), WashU-BLAST:",
    },

    { 'group'  => "BLAST2",
      'header' => "NCBI BLAST (series 2), BLAST+:",
    },

    { 'group'  => "PSIBLAST",
      'header' => "NCBI PSI-BLAST:",
    },

    { 'group'  => "FASTA",
      'header' => "FASTA (U. of Virginia):",
    },

    { 'group'  => "HSSP",
      'header' => "HSSP/Maxhom:",
    },

    { 'group'  => "MAF",
      'header' => "UCSC MAF:",
    },

    { 'group'  => "MULTAL",
      'header' => "MULTAL/MULTAS:",
    },

    { 'group'  => "MAPFILES",
      'header' => "User defined colormap and consensus group definition:",
    },

    { 'group'  => "INFO",
      'header' => "More information and help:",
    },

];

$Options = [

    #### HIDDEN ##################################################

    { 'group'   => "HIDDEN",
      'option'  => "verbose",
      'type'    => "u_int",
      'default' =>  0,
    },

    #### MAPFILES ##################################################

    { 'group'   => "MAPFILES",
      'option'  => "colorfile",
      'usage'   => "Load more colormaps from file",
      'type'    => "infile",
    },

    { 'group'   => "MAPFILES",
      'option'  => "groupfile",
      'usage'   => "Load more groupmaps from file",
      'type'    => "infile",
    },

    #### INFO ##################################################

    { 'group'   => "INFO",
      'option'  => "help",
      'usage'   => "This help",
      'type'    => "flag::silent",
    },

    { 'group'   => "INFO",
      'option'  => "listcolors",
      'usage'   => "Print listing of known colormaps",
      'type'    => "flag::silent",
    },

    { 'group'   => "INFO",
      'option'  => "listgroups",
      'usage'   => "Print listing of known consensus groups",
      'type'    => "flag::silent",
    },

    { 'group'   => "INFO",
      'option'  => "listcss",
      'usage'   => "Print style sheet",
      'type'    => "flag::silent",
    },

    #### FORMATS ##################################################

    { 'group'   => "FORMATS",
      'option'  => "in",
      'type'    => "formats::in",
    },

    { 'group'   => "FORMATS",
      'option'  => "out",
      'param'   => "mode",
      'type'    => "formats::out",
    },

    #### CONTENT  ##################################################

    { 'group'   => "CONTENT",
      'option'  => "ruler",
      'usage'   => "Show ruler",
      'type'    => "binary",
      'default' => "on",
    },

    { 'group'   => "CONTENT",
      'option'  => "alignment",
      'usage'   => "Show alignment",
      'type'    => "binary",
      'default' => "on",
    },

    { 'group'   => "CONTENT",
      'option'  => "conservation",
      'usage'   => "Show clustal conservation line",
      'type'    => "binary",
      'default' => "off",
    },

    { 'group'   => "CONTENT",
      'option'  => "consensus",
      'usage'   => "Show consensus",
      'type'    => "binary",
      'default' => "off",
    },

    { 'group'   => "CONTENT",
      'option'  => "width",
      'type'    => "content::width",
    },

    #### IDENTITY ##################################################

    { 'group'   => "IDENTITY",
      'option'  => "pcid",
      'type'    => "identity::pcid",
    },

    { 'group'   => "IDENTITY",
      'option'  => "reference",
      'param'   => "ref_id",
      'usage'   => "Use row N or row identifier as %identity reference",
      'type'    => "string",
      'default' => "query",
    },

    { 'group'   => "IDENTITY",
      'option'  => "minident",
      'usage'   => "Only report sequences with percent identity >= N compared to reference",
      'type'    => "percentage",
      'default' => 0
    },

    { 'group'   => "IDENTITY",
      'option'  => "maxident",
      'usage'   => "Only report sequences with percent identity <= N compared to reference",
      'type'    => "percentage",
      'default' => 100,
    },

    #### FILTER ##################################################

    { 'group'   => "FILTER",
      'option'  => "top",
      'param'   => "topn",
      'type'    => "filter::top",
    },

    { 'group'   => "FILTER",
      'option'  => "show",
      'param'   => "keeplist",
      'usage'   => "Keep rows 1..N or identifiers",
      'type'    => "string_list",
    },

    { 'group'   => "FILTER",
      'option'  => "hide",
      'param'   => "skiplist",
      'usage'   => "Hide rows 1..N or identifiers",
      'type'    => "string_list",
    },

    { 'group'   => "FILTER",
      'option'  => "nops",
      'param'   => "nopslist",
      'usage'   => "Exclude rows 1..N or identifiers from calculations",
      'type'    => "string_list",
    },

    { 'group'   => "FILTER",
      'option'  => "range",
      'usage'   => "Display column range M:N as numbered by ruler",
      'type'    => "integer_range",
      'default' => "all",
    },

    #### MOLTYPE  ##################################################

    { 'group'   => "MOLTYPE",
      'option'  => "moltype",
      'type'    => "moltype::type",
    },

    #### ALIGNMENT ##################################################

    { 'group'   => "ALIGNMENT",
      'option'  => "coloring",
      'param'   => "aln_coloring",
      'type'    => "alignment::coloring",
    },

    { 'group'   => "ALIGNMENT",
      'option'  => "colormap",
      'param'   => "aln_colormap",
      'type'    => "alignment::colormap",
    },

    { 'group'   => "ALIGNMENT",
      'option'  => "groupmap",
      'param'   => "aln_groupmap",
      'type'    => "alignment::groupmap",
    },

    { 'group'   => "ALIGNMENT",
      'option'  => "threshold",
      'param'   => "aln_threshold",
      'usage'   => "Threshold percentage for consensus coloring",
      'type'    => "percentage_ge_50",
      'default' => 70,
    },

    { 'group'   => "ALIGNMENT",
      'option'  => "ignore",
      'param'   => "aln_ignore",
      'type'    => "alignment::ignore",
    },

    #### CONSENSUS ####

    { 'group'   => "CONSENSUS",
      'option'  => "con_coloring",
      'type'    => "consensus::coloring",
    },

    { 'group'   => "CONSENSUS",
      'option'  => "con_colormap",
      'type'    => "consensus::colormap",
    },

    { 'group'   => "CONSENSUS",
      'option'  => "con_groupmap",
      'type'    => "consensus::groupmap",
    },

    { 'group'   => "CONSENSUS",
      'option'  => "con_threshold",
      'type'    => "consensus::threshold",
    },

    { 'group'   => "CONSENSUS",
      'option'  => "con_ignore",
      'type'    => "consensus::ignore",
    },

    { 'group'   => "CONSENSUS",
      'option'  => "con_gaps",
      'usage'   => "Count gaps during consensus computations if set to 'on'",
      'type'    => "binary",
      'default' => "on",
    },

    #### PATTERNS ####

    { 'group'   => "PATTERNS",
      'option'  => "find",
      'usage'   => "Find and highlight exact string or simple regular expression or ':' delimited set of patterns",
      'type'    => "string",
      'label'   => "pattern",
    },

    #### MISC_FORMATTING  ####

    { 'group'   => "MISC_FORMATTING",
      'option'  => "label0",
      'usage'   => "Switch off label {0= row number}",
      'type'    => "flag::invert",
    },

    { 'group'   => "MISC_FORMATTING",
      'option'  => "label1",
      'usage'   => "Switch off label {1= identifier}",
      'type'    => "flag::invert",
    },

    { 'group'   => "MISC_FORMATTING",
      'option'  => "label2",
      'usage'   => "Switch off label {2= description}",
      'type'    => "flag::invert",
    },

    { 'group'   => "MISC_FORMATTING",
      'option'  => "label3",
      'usage'   => "Switch off label {3= scores}",
      'type'    => "flag::invert",
    },

    { 'group'   => "MISC_FORMATTING",
      'option'  => "label4",
      'usage'   => "Switch off label {4= percent coverage}",
      'type'    => "flag::invert",
    },

    { 'group'   => "MISC_FORMATTING",
      'option'  => "label5",
      'usage'   => "Switch off label {5= percent identity}",
      'type'    => "flag::invert",
    },

    { 'group'   => "MISC_FORMATTING",
      'option'  => "label6",
      'usage'   => "Switch off label {6= first sequence positions: query}",
      'type'    => "flag::invert",
    },

    { 'group'   => "MISC_FORMATTING",
      'option'  => "label7",
      'usage'   => "Switch off label {7= second sequence positions: hit}",
      'type'    => "flag::invert",
    },

    { 'group'   => "MISC_FORMATTING",
      'option'  => "gap",
      'usage'   => "Use this gap character",
      'type'    => "char",
      'default' => get_default_gap,
    },

    { 'group'   => "MISC_FORMATTING",
      'option'  => "register",
      'usage'   => "Output multi-pass alignments with columns in register",
      'type'    => "binary",
      'default' => "on",
    },

    #### HTML ####

    { 'group'   => "HTML",
      'option'  => "html",
      'usage'   => "Controls amount of HTML markup {@{[list_html_modes]}}",
      'type'    => "html::html_mode",
    },

    { 'group'   => "HTML",
      'option'  => "bold",
      'usage'   => "Use bold emphasis for coloring sequence symbols",
      'type'    => "flag",
    },

    { 'group'   => "HTML",
      'option'  => "css",
      'param'   => "css1",
      'type'    => "html::css_mode",
    },

    { 'group'   => "HTML",
      'option'  => "title",
      'usage'   => "Page title string",
      'type'    => "string",
    },

    { 'group'   => "HTML",
      'option'  => "pagecolor",
      'usage'   => "Page backgound color",
      'type'    => "color",
      'default' => "white",
    },

    { 'group'   => "HTML",
      'option'  => "textcolor",
      'usage'   => "Page text color",
      'type'    => "color",
      'default' => "black",
    },

    { 'group'   => "HTML",
      'option'  => "alncolor",
      'usage'   => "Alignment background color",
      'type'    => "color",
      'default' => "white",
    },

    { 'group'   => "HTML",
      'option'  => "labcolor",
      'usage'   => "Alignment label color",
      'type'    => "color",
      'default' => "black",
    },

    { 'group'   => "HTML",
      'option'  => "symcolor",
      'usage'   => "Alignment symbol default color",
      'type'    => "color",
      'default' => "#666666",
    },

    { 'group'   => "HTML",
      'option'  => "gapcolor",
      'usage'   => "Alignment gap color",
      'type'    => "color",
      'default' => "#666666",
    },

    #### SRS_LINKS ####

    { 'group'   => "SRS_LINKS",
      'option'  => "srs",
      'type'    => "srs::mode",
    },

    { 'group'   => "SRS_LINKS",
      'option'  => "linkcolor",
      'usage'   => "Link color",
      'type'    => "color",
      'default' => "blue",
    },

    { 'group'   => "SRS_LINKS",
      'option'  => "alinkcolor",
      'usage'   => "Active link color",
      'type'    => "color",
      'default' => "red",
    },

    { 'group'   => "SRS_LINKS",
      'option'  => "vlinkcolor",
      'usage'   => "Visited link color",
      'type'    => "color",
      'default' => "purple",
    },

    ##################################################
    # formats
    ##################################################

    #### BLAST1 ####

    { 'group'   => "BLAST1",
      'option'  => "hsp",
      'type'    => "blast::hsp_mode",
    },

    { 'group'   => "BLAST1",
      'option'  => "maxpval",
      'type'    => "blast::maxpval",
    },

    { 'group'   => "BLAST1",
      'option'  => "minscore",
      'type'    => "blast::minscore",
    },

    { 'group'   => "BLAST1",
      'option'  => "strand",
      'type'    => "search::strand",
    },

    { 'group'   => "BLAST1",
      'option'  => "keepinserts",
      'type'    => "blast::keepinserts",
    },

    #### BLAST2 ####

    { 'group'   => "BLAST2",
      'option'  => "hsp",
      'type'    => "blast::hsp_mode",
    },

    { 'group'   => "BLAST2",
      'option'  => "maxeval",
      'type'    => "blast::maxeval",
    },

    { 'group'   => "BLAST2",
      'option'  => "minbits",
      'type'    => "blast::minbits",
    },

    { 'group'   => "BLAST2",
      'option'  => "strand",
      'type'    => "search::strand",
    },

    { 'group'   => "BLAST2",
      'option'  => "keepinserts",
      'type'    => "blast::keepinserts",
    },

    #### PSIBLAST ####

    { 'group'   => "PSIBLAST",
      'option'  => "hsp",
      'type'    => "blast::hsp_mode",
    },

    { 'group'   => "PSIBLAST",
      'option'  => "maxeval",
      'type'    => "blast::maxeval",
    },

    { 'group'   => "PSIBLAST",
      'option'  => "minbits",
      'type'    => "blast::minbits",
    },

    { 'group'   => "PSIBLAST",
      'option'  => "cycle",
      'type'    => "psiblast::cycle",
    },

    { 'group'   => "PSIBLAST",
      'option'  => "keepinserts",
      'type'    => "blast::keepinserts",
    },

    #### FASTA ####

    { 'group'   => "FASTA",
      'option'  => "minopt",
      'type'    => "fasta::minopt",
    },

    { 'group'   => "FASTA",
      'option'  => "strand",
      'type'    => "search::strand",
    },

    #### HSSP ####

    { 'group'   => "HSSP",
      'option'  => "chain",
      'type'    => "hssp::chain",
    },

    #### MAF ####

    { 'group'   => "MAF",
      'option'  => "block",
      'type'    => "align::block",
    },

    #### MULTAL ####

    { 'group'   => "MULTAL",
      'option'  => "block",
      'type'    => "align::block",
    },

];


###########################################################################
1;
