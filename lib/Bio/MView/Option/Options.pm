# Copyright (C) 2018 Nigel P. Brown

######################################################################
package Bio::MView::Option::Options;

use Bio::MView::Option::Arguments;
use Bio::MView::Option::Types;
use strict;
use vars qw($Header $Groups $Options);

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
sub get_default_alignment_colormap {
    Bio::MView::Align::get_default_alignment_colormap(@_)
}
sub get_default_consensus_colormap {
    Bio::MView::Align::get_default_consensus_colormap(@_)
}
sub get_default_groupmap {
    Bio::MView::Align::Consensus::get_default_groupmap(@_)
}

sub get_default_gap { Bio::MView::Build::get_default_gap }

###########################################################################
$Groups = [
    {
        'group'  => "HIDDEN",
        'usage'  => -1,
    },

    {
        'group'  => "MAPFILES",
        'header' => "User defined colormap and consensus group definition:",
        'usage'  => 990,   #usage group: before last
    },

    {
        'group'  => "INFO",
        'header' => "More information and help:",
        'usage'  => 1000,  #usage group: last
    },

    {
        'group'  => 'FORMATS',
        'header' => "Input/output formats:",
        'usage'  => 10,
    },

    {
        'group'  => "CONTENT",
        'header' => "Main formatting options:",
        'usage'  => 20,
    },

    {
        'group'  => "IDENTITY",
        'header' => "Percent identity calculations and filters:",
        'usage'  => 30,
    },

    {
        'group'  => "FILTER",
        'header' => "General row/column filters:",
        'usage'  => 40,
    },

    {
        'group'  => "MOLTYPE",
        'header' => "Molecule type:",
        'usage'  => 50,
    },

    {
        'group'  => "ALIGNMENT_COLORING",
        'header' => "Alignment coloring:",
        'usage'  => 60,
    },

    {
        'group'  => "CONSENSUS_COLORING",
        'header' => "Consensus coloring:",
        'usage'  => 70,
    },

    {
        'group'  => "PATTERNS",
        'header' => "Motif colouring:",
        'usage'  => 80,
    },

    {
        'group'  => "MISC_FORMATTING",
        'header' => "Miscellaneous formatting:",
        'usage'  => 90,
    },

    {
        'group'  => "HTML",
        'header' => "HTML markup:",
        'usage'  => 100,
    },

    {
        'group'  => "SRS_LINKS",
        'header' => "Database links:",
        'usage'  => 110,
    },

    ##################################################
    # formats
    ##################################################

    {
        'group'  => "BLAST1",
        'header' => "NCBI BLAST (series 1), WashU-BLAST:",
        'usage'  => 200,
    },

    {
        'group'  => "BLAST2",
        'header' => "NCBI BLAST (series 2), BLAST+:",
        'usage'  => 210,
    },

    {
        'group'  => "PSIBLAST",
        'header' => "NCBI PSI-BLAST:",
        'usage'  => 220,
    },

    {
        'group'  => "FASTA",
        'header' => "FASTA (U. of Virginia):",
        'usage'  => 230,
    },

    {
        'group'  => "HSSP",
        'header' => "HSSP/Maxhom:",
        'usage'  => 240,
    },

    {
        'group'  => "MAF",
        'header' => "UCSC MAF:",
        'usage'  => 250,
    },

    {
        'group'  => "MULTAL",
        'header' => "MULTAL/MULTAS:",
        'usage'  => 260,
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
      'default' => "",
    },

    { 'group'   => "MAPFILES",
      'option'  => "groupfile",
      'usage'   => "Load more groupmaps from file",
      'type'    => "infile",
      'default' => "",
    },

    #### INFO ##################################################

    { 'group'   => "INFO",
      'option'  => "help",
      'usage'   => "This help",
      'type'    => 'flag',
    },

    { 'group'   => "INFO",
      'option'  => "listcolors",
      'usage'   => "Print listing of known colormaps",
      'type'    => 'flag',
    },

    { 'group'   => "INFO",
      'option'  => "listgroups",
      'usage'   => "Print listing of known consensus groups",
      'type'    => 'flag',
    },

    { 'group'   => "INFO",
      'option'  => "listcss",
      'usage'   => "Print style sheet",
      'type'    => 'flag',
    },

    #### FORMATS ##################################################

    { 'group'   => "FORMATS",
      'option'  => "in",
      'usage'   => "Input {@{[list_informats]}}",
      'default' => "",
      'label'   => "format",
      'type'    => "",
      'test'    => sub {
          my ($self, $on, $ov, $e) = @_;
          my $pv = check_informat($ov);
          if (! defined $pv) {
              push @$e, "input format '$ov' unrecognised";
              push @$e, "known formats are: {". list_informats . "}";
          }
          return $pv;
      },
    },

    { 'group'   => "FORMATS",
      'option'  => "out",
      'param'   => "mode",
      'usage'   => "Output {@{[list_outformats]}}",
      'default' => "new",
      'label'   => "format",
      'type'    => "",
      'test'    => sub {
          my ($self, $on, $ov, $e) = @_;
          my $pv = check_outformat($ov);
          if (! defined $pv) {
              push @$e, "output format '$ov' unrecognised";
              push @$e, "known formats are: {",
                  join(",", list_outformats) . "}";
          }
          return $pv;
      },
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
      'usage'   => "Paginate alignment in blocks of N columns",
      'label'   => "{N,flat}",
      'default' => "flat",
      'type'    => "",
      'test'    => sub {
          my ($self, $on, $ov, $e) = @_;
          return 0  if $ov eq "flat";
          my $pv = $self->test_type('u_int', $on, $ov, $e);
          if (@$e) {
              pop @$e;
              push @$e, "width '$ov' unrecognised";
              push @$e, "known formats are: {N,flat} where N is an integer";
          }
          return $pv;
      },
    },

    #### IDENTITY ##################################################

    { 'group'   => "IDENTITY",
      'option'  => "pcid",
      'usage'   => "Compute percent identities with respect to {@{[list_identity_modes]}}",
      'default' => "aligned",
      'label'   => "mode",
      'type'    => "",
      'test'    => sub {
          my ($self, $on, $ov, $e) = @_;
          my $pv = check_identity_mode($ov);
          if (! defined $pv) {
              push @$e, "percent identity mode '$ov' unrecognised";
              push @$e, "known percent identity modes are: {",
                  join(",", list_identity_modes) . "}";
          }
          return $pv;
      },
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
      'usage'   => "Report top N hits",
      'default' => "all",
      'label'   => "{N,all}",
      'type'    => "",
      'test'    => sub {
          my ($self, $on, $ov, $e) = @_;
          return 0  if $ov eq "all";
          my $pv = $self->test_type('u_int', $on, $ov, $e);
          if (@$e) {
              pop @$e;
              push @$e, "topn value '$ov' unrecognised";
              push @$e, "known values are: {N,all} where N is an integer";
          }
          return $pv;
      },
    },

    { 'group'   => "FILTER",
      'option'  => "show",
      'param'   => "keeplist",
      'usage'   => "Keep rows 1..N or identifiers",
      'type'    => "string_list",
      'default' => "",
    },

    { 'group'   => "FILTER",
      'option'  => "hide",
      'param'   => "skiplist",
      'usage'   => "Hide rows 1..N or identifiers",
      'type'    => "string_list",
      'default' => "",
    },

    { 'group'   => "FILTER",
      'option'  => "nops",
      'param'   => "nopslist",
      'usage'   => "No operation: exclude rows 1..N or identifiers from calculations",
      'type'    => "string_list",
      'default' => "",
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
      'usage'   => "Affects coloring and format converions {@{[list_molecule_types]}}",
      'default' => "aa",
      'label'   => "string",
      'type'    => "",
      'test'    => sub {
          my ($self, $on, $ov, $e) = @_;
          my $pv = check_molecule_type($ov);
          if (! defined $pv) {
              push @$e, "molecule type '$ov' unrecognised";
              push @$e, "known molecule types are: {",
                  join(",", list_molecule_types) . "}";
              return $ov;
          }
          #warn "Setting moltype: $pv";
          #reset the default coloring schemes for subsequent options
          $self->update_option('ALIGNMENT_COLORING::colormap',
                               get_default_alignment_colormap($pv));

          $self->update_option('CONSENSUS_COLORING::con_colormap',
                               get_default_consensus_colormap($pv));

          $self->update_option('ALIGNMENT_COLORING::groupmap',
                               get_default_groupmap($pv));

          $self->update_option('CONSENSUS_COLORING::con_groupmap',
                               get_default_groupmap($pv));  #same
          return $pv;
      },
    },

    #### ALIGNMENT_COLORING ##################################################

    { 'group'   => "ALIGNMENT_COLORING",
      'option'  => "coloring",
      'param'   => "aln_coloring",
      'usage'   => "Basic style of coloring {@{[list_alignment_color_schemes]}}",
      'default' => "none",
      'label'   => "string",
      'type'    => "",
      'test'    => sub {
          my ($self, $on, $ov, $e) = @_;
          my $pv = check_alignment_color_scheme($ov);
          if (! defined $pv) {
              push @$e, "alignment coloring scheme '$ov' unrecognised";
              push @$e, "known color schemes are: {",
                  join(",", list_alignment_color_schemes) . "}";
          }
          return $pv;
      },
    },

    { 'group'   => "ALIGNMENT_COLORING",
      'option'  => "colormap",
      'param'   => "aln_colormap",
      'usage'   => "Name of colormap to use",
      'default' => get_default_alignment_colormap,
      'label'   => "string",
      'type'    => "",
      'test'    => sub {
          my ($self, $on, $ov, $e) = @_;
          my $pv = check_colormap($ov);
          if (! defined $pv) {
              push @$e, "alignment colormap '$ov' unrecognised";
              push @$e, "known colormaps are: ",
                  join(",", list_colormap_names);
          }
          return $pv;
      },
    },

    { 'group'   => "ALIGNMENT_COLORING",
      'option'  => "groupmap",
      'param'   => "aln_groupmap",
      'usage'   => "Name of groupmap to use if coloring by consensus",
      'default' => get_default_groupmap,
      'label'   => "string",
      'type'    => "",
      'test'    => sub {
          my ($self, $on, $ov, $e) = @_;
          my $pv = check_groupmap($ov);
          if (! defined $pv) {
              push @$e, "alignment groupmap '$ov' unrecognised";
              push @$e, "known groupmaps are: ",
                  join(",", list_groupmap_names);
          }
          return $pv;
      },
    },

    { 'group'   => "ALIGNMENT_COLORING",
      'option'  => "threshold",
      'param'   => "aln_threshold",
      'usage'   => "Threshold percentage for consensus coloring",
      'type'    => 'percentage_ge_50',
      'default' => 70,
    },

    { 'group'   => "ALIGNMENT_COLORING",
      'option'  => "ignore",
      'param'   => "aln_ignore",
      'usage'   => "Ignore singleton or class groups {@{[list_ignore_classes]}}",
      'default' => "none",
      'label'   => "string",
      'type'    => "",
      'test'    => sub {
          my ($self, $on, $ov, $e) = @_;
          my $pv = check_ignore_class($ov);
          if (! defined $pv) {
              push @$e, "ignore class '$ov' unrecognised";
              push @$e, "known ignore classes are: ",
                  join(",", list_ignore_classes);
          }
          return $pv;
      },
     },

    #### CONSENSUS_COLORING ##################################################

    { 'group'   => "CONSENSUS_COLORING",
      'option'  => "con_coloring",
      'usage'   => "Basic style of coloring {@{[list_consensus_color_schemes]}}",
      'default' => "none",
      'label'   => "string",
      'type'    => "",
      'test'    => sub {
          my ($self, $on, $ov, $e) = @_;
          my $pv = check_consensus_color_scheme($ov);
          if (! defined $pv) {
              push @$e, "consensus coloring scheme '$ov' unrecognised";
              push @$e, "known color schemes are: {",
                  join(",", list_consensus_color_schemes) . "}";
          }
          return $pv;
      },
    },

    { 'group'   => "CONSENSUS_COLORING",
      'option'  => "con_colormap",
      'usage'   => "Name of colormap to use",
      'default' => get_default_consensus_colormap,
      'label'   => "string",
      'type'    => "",
      'test'    => sub {
          my ($self, $on, $ov, $e) = @_;
          my $pv = check_colormap($ov);
          if (! defined $pv) {
              push @$e, "consensus colormap '$ov' unrecognised";
              push @$e, "known consensus colormaps are: ",
                  join(",", list_colormap_names);
          }
          return $pv;
      },
    },

    { 'group'   => "CONSENSUS_COLORING",
      'option'  => "con_groupmap",
      'usage'   => "Name of groupmap to use if coloring by consensus",
      'default' => get_default_groupmap,
      'label'   => "string",
      'type'    => "",
      'test'    => sub {
          my ($self, $on, $ov, $e) = @_;
          my $pv = check_groupmap($ov);
          if (! defined $pv) {
              push @$e, "consensus groupmap '$ov' unrecognised";
              push @$e, "known consensus groupmaps are: ",
                  join(",", list_groupmap_names);
          }
          return $pv;
      }
    },

    { 'group'   => "CONSENSUS_COLORING",
      'option'  => "con_threshold",
      'usage'   => "Consensus line thresholds",
      'default' => '100,90,80,70',
      'label'   => "string",
      'type'    => "",
      'test'    => sub {
          my ($self, $on, $ov, $e) = @_;
          my $pv = $self->test_type('u_numeric_list', $on, $ov, $e);
          foreach my $v (@$pv) {
              if ($v < 50 or $v > 100) {
                  push @$e, ("bad percentage in '$ov', must be in range 50..100");
              }
          }
          return $pv;
      }
    },

    { 'group'   => "CONSENSUS_COLORING",
      'option'  => "con_ignore",
      'usage'   => "Ignore singleton or class groups {@{[list_ignore_classes]}}",
      'default' => "none",
      'label'   => "string",
      'type'    => "",
      'test'    => sub {
          my ($self, $on, $ov, $e) = @_;
          my $pv = check_ignore_class($ov);
          if (! defined $pv) {
              push @$e, "consensus ignore class '$ov' unrecognised",
              push @$e, "known consensus ignore classes are: ",
                  join(",", list_ignore_classes);
          }
          return  $pv;
      },
    },

    { 'group'   => "CONSENSUS_COLORING",
      'option'  => "con_gaps",
      'usage'   => "Count gaps during consensus computations if set to 'on'",
      'type'    => "binary",
      'default' => "on",
    },

    #### PATTERNS ##################################################

    { 'group'   => "PATTERNS",
      'option'  => "find",
      'usage'   => "Find and highlight exact string or simple regular expression or ':' delimited set of patterns",
      'type'    => "string",
      'default' => "",
      #$par->{'fnd_colormap'} = get_default_find_colormap();
    },

    #### MISC_FORMATTING  ##################################################

    { 'group'   => "MISC_FORMATTING",
      'option'  => "label0",
      'usage'   => "Switch off label {0= row number}",
      'type'    => "inverter",
    },

    { 'group'   => "MISC_FORMATTING",
      'option'  => "label1",
      'usage'   => "Switch off label {1= identifier}",
      'type'    => "inverter",
    },

    { 'group'   => "MISC_FORMATTING",
      'option'  => "label2",
      'usage'   => "Switch off label {2= description}",
      'type'    => "inverter",
    },

    { 'group'   => "MISC_FORMATTING",
      'option'  => "label3",
      'usage'   => "Switch off label {3= scores}",
      'type'    => "inverter",
    },

    { 'group'   => "MISC_FORMATTING",
      'option'  => "label4",
      'usage'   => "Switch off label {4= percent coverage}",
      'type'    => "inverter",
    },

    { 'group'   => "MISC_FORMATTING",
      'option'  => "label5",
      'usage'   => "Switch off label {5= percent identity}",
      'type'    => "inverter",
    },

    { 'group'   => "MISC_FORMATTING",
      'option'  => "label6",
      'usage'   => "Switch off label {6= first sequence positions: query}",
      'type'    => "inverter",
    },

    { 'group'   => "MISC_FORMATTING",
      'option'  => "label7",
      'usage'   => "Switch off label {7= second sequence positions: hit}",
      'type'    => "inverter",
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

    #### HTML ##################################################

    { 'group'   => "HTML",
      'option'  => "html",
      'usage'   => "Controls amount of HTML markup {@{[list_html_modes]}}",
      'default' => "off",
      'label'   => "string",
      'type'    => "",
      'test'    => sub {
          my ($self, $on, $ov, $e) = @_;
          my $pv = check_html_mode($ov);
          if (! defined $pv) {
              push @$e, "html mode '$ov' unrecognised",
              push @$e, "known html modes are: ",
                  join(",", list_html_modes);
          }
          return $pv;
      },
    },

    { 'group'   => "HTML",
      'option'  => "bold",
      'usage'   => "Use bold emphasis for coloring sequence symbols",
      'type'    => 'flag',
      'default' => 'off',
    },

    { 'group'   => "HTML",
      'option'  => "css",
      'param'   => "css1",
      'usage'   => "Use Cascading Style Sheets {@{[list_css_modes]}}",
      'default' => 'off',
      'label'   => "string",
      'type'    => "",
      'test'    => sub {
          my ($self, $on, $ov, $e) = @_;
          my $pv = check_css_mode($ov);
          if (! defined $pv) {
              push @$e, "css mode '$ov' unrecognised",
              push @$e, "known css modes are: ",
                  join(",", list_html_modes);
          }
          return $pv;
      },
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

    #### SRS_LINKS ##################################################

    { 'group'   => "SRS_LINKS",
      'option'  => "srs",
      'usage'   => "Try to use sequence database links",
      'default' => "off",
      'type'    => "",
      'test'    => sub {
          my ($self, $on, $ov, $e) = @_;
          my $pv = $self->test_type('binary', $on, $ov, $e);
          return $Bio::MView::SRS::Type = 1  if $pv eq "1";
          return $Bio::MView::SRS::Type = 0  if $pv eq "0";
          return $ov;
      },
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

    #### BLAST1 ##################################################

    { 'group'   => "BLAST1",
      'option'  => "hsp",
      'type'    => "hsp_mode",
    },

    { 'group'   => "BLAST1",
      'option'  => "maxpval",
      'usage'   => "Ignore hits with p-value greater than N",
      'label'   => "{N,unlimited}",
      'default' => "unlimited",
      'type'    => "",
      'test'    => sub {
          my ($self, $on, $ov, $e) = @_;
          return undef  if $ov eq 'unlimited';
          my $pv = $self->test_type('numeric_gt_0', $on, $ov, $e);
          if (! defined $pv) {
              pop @$e;
              push(@$e, "bad maxpval value '$ov', want numeric > 0");
          }
          return $pv;
      },
    },

    { 'group'   => "BLAST1",
      'option'  => "minscore",
      'usage'   => "Ignore hits with score less than N",
      'label'   => "{N,unlimited}",
      'default' => "unlimited",
      'type'    => "",
      'test'    => sub {
          my ($self, $on, $ov, $e) = @_;
          return undef  if $ov eq 'unlimited';
          my $pv = $self->test_type('numeric_gt_0', $on, $ov, $e);
          if (! defined $pv) {
              pop @$e;
              push(@$e, "bad minscore value '$ov', want numeric > 0");
          }
          return $pv;
      },
    },

    { 'group'   => "BLAST1",
      'option'  => "strand",
      'type'    => "strand",
    },

    { 'group'   => "BLAST1",
      'option'  => "keepinserts",
      'type'    => "keepinserts",
    },

    #### BLAST2 ##################################################

    { 'group'   => "BLAST2",
      'option'  => "hsp",
      'type'    => "hsp_mode",
    },

    { 'group'   => "BLAST2",
      'option'  => "maxeval",
      'type'    => "maxeval",
    },

    { 'group'   => "BLAST2",
      'option'  => "minbits",
      'type'    => "minbits",
    },

    { 'group'   => "BLAST2",
      'option'  => "strand",
      'type'    => "strand",
    },

    { 'group'   => "BLAST2",
      'option'  => "keepinserts",
      'type'    => "keepinserts",
    },

    #### PSIBLAST ##################################################

    { 'group'   => "PSIBLAST",
      'option'  => "hsp",
      'type'    => "hsp_mode",
    },

    { 'group'   => "PSIBLAST",
      'option'  => "maxeval",
      'type'    => "maxeval",
    },

    { 'group'   => "PSIBLAST",
      'option'  => "minbits",
      'type'    => "minbits",
    },

    { 'group'   => "PSIBLAST",
      'option'  => "cycle",
      'label'   => "cycle",
      'usage'   => "Process the N'th cycle of a multipass search {@{[list_cycle_types]}}",
      'default' => "last",
      'type'    => "",
      'test'    => sub {
          my ($self, $on, $ov, $e) = @_;
          my $pv = check_cycle_type($ov);
          if (! defined $pv) {
              push @$e, "bad cycle value in '$ov'";
              push @$e, "valid cycle values are: {"
                  . list_cycle_types . "}";
          }
          return $pv;
      },
    },

    { 'group'   => "PSIBLAST",
      'option'  => "keepinserts",
      'type'    => "keepinserts",
    },

    #### FASTA ##################################################


    { 'group'   => "FASTA",
      'option'  => "minopt",
      'usage'   => "Ignore hits with opt score less than N",
      'label'   => "{N,unlimited}",
      'default' => "unlimited",
      'type'    => "",
      'test'    => sub {
          my ($self, $on, $ov, $e) = @_;
          return undef  if $ov eq 'unlimited';
          my $pv = $self->test_type('numeric_gt_0', $on, $ov, $e);
          if (! defined $pv) {
              pop @$e;
              push(@$e, "bad minscore value '$ov', want numeric > 0");
          }
          return $pv;
      },
    },

    { 'group'   => "FASTA",
      'option'  => "strand",
      'type'    => "strand",
    },

    #### HSSP ##################################################

    { 'group'   => "HSSP",
      'option'  => "chain",
      'usage'   => "Report only these chain names/numbers {@{[list_chain_values]}}",
      'label'   => 'chain',
      'default' => '*',
      'type'    => "",
      'test'    => sub {
          my ($self, $on, $ov, $e) = @_;
          my $pv = check_chain_value($ov);
          if (! defined $pv) {
              push @$e, "bad chain in '$ov'";
              push @$e, "valid chain specifications are: {"
                  . list_chain_values . "}";
          }
          return $pv;
      },
    },

    #### MAF ##################################################

    { 'group'   => "MAF",
      'option'  => "block",
      'type'    => "block",
    },

    #### MULTAL ##################################################

    { 'group'   => "MULTAL",
      'option'  => "block",
      'type'    => "block",
    },

];


###########################################################################
1;
