# Copyright (C) 2018 Nigel P. Brown

######################################################################
package Bio::MView::Option::Types;

use Bio::MView::Option::Arguments;
use NPB::Parse::Regexps;
use strict;
use vars qw($Types);

######################################################################
sub get_default_alignment_colormap {
    Bio::MView::Align::get_default_alignment_colormap(@_)
}
sub get_default_consensus_colormap {
    Bio::MView::Align::get_default_consensus_colormap(@_)
}
sub get_default_groupmap {
    Bio::MView::Align::Consensus::get_default_groupmap(@_)
}

######################################################################
$Types = [

    #### REUSABLE TYPES ####

    {
        'type'    => "flag",  #no argument
        'label'   => "",
        'default' => "unset",
        'test'    => sub {
            my ($self, $on, $ov, $e) = @_;
            return 0  if $ov eq 'unset';  #default
            return 1  if $ov eq 'set';
            return 0  if $ov eq '0';
            return 1  if $ov eq '1';
        },
    },

    {
        'type'    => "flag::silent",  #no argument, empty default
        'label'   => "",
        'default' => "",
        'test'    => sub {
            my ($self, $on, $ov, $e) = @_;
            return 0  if $ov eq '';  #default
            return 0  if $ov eq '0';
            return 1  if $ov eq '1';
        },
    },

    {
        'type'    => "flag::invert",  #no argument, invert input
        'label'   => "",
        'default' => "set",  #preset
        'test'    => sub {
            my ($self, $on, $ov, $e) = @_;
            return 0  if $ov eq 'unset';  #confirm preset
            return 1  if $ov eq 'set';    #confirm preset
            return 1  if $ov eq '0';      #invert input
            return 0  if $ov eq '1';      #invert input
            return 1;  #same as default
        },
    },

    {
        'type'    => "binary",
        'label'   => "on|off",
        'default' => "off",
        'test'    => sub {
            my ($self, $on, $ov, $e) = @_;
            return 0  if $ov eq 'off' or $ov eq '0';
            return 1  if $ov eq 'on'  or $ov eq '1';
            push(@$e, "bad argument '$on=$ov', want on|off");
            return $ov;
        },
    },

    {
        'type'    => "char",
        'label'   => "char",
        'default' => "",
        'test'    => sub {
            my ($self, $on, $ov, $e) = @_;
            push(@$e, "bad argument '$on=$ov', want character"),
                unless length($ov) == 1;
            return $ov;
        },
    },

    {
        'type'    => "string",
        'label'   => "string",
        'default' => "",
    },

    {
        'type'    => "color",  #really just a string
        'label'   => "color",
        'default' => "",
    },

    {
        'type'    => "u_int",
        'label'   => "integer",
        'test'    => sub {
            my ($self, $on, $ov, $e) = @_;
            push(@$e, "bad argument '$on=$ov', want integer >= 0"),
                unless $ov =~ /^$RX_Uint$/;
            return $ov;
        },
    },

    {
        'type'    => "u_numeric",
        'label'   => "number",
        'test'    => sub {
            my ($self, $on, $ov, $e) = @_;
            push(@$e, "bad argument '$on=$ov', want numeric >= 0"),
                unless $ov =~ /^$RX_Ureal$/;
            return $ov;
        },
    },

    {
        'type'    => "numeric_gt_0",
        'label'   => "N",
        'test'    => sub {
            my ($self, $on, $ov, $e) = @_;
            my $pv = $self->test_type('u_numeric', $on, $ov, $e);
            if (! defined $pv) {
                pop @$e;
                push(@$e, "bad value '$ov', want numeric > 0");
                return undef;
            }
            if ($pv <= 0) {
                push(@$e, "bad value '$ov', want numeric > 0");
                return undef;
            }
            return $pv;
        },
    },

    {
        'type'    => "percentage",
        'label'   => "N",
        'test'    => sub {
            my ($self, $on, $ov, $e) = @_;
            my $pv = $self->test_type('u_numeric', $on, $ov, $e);
            return $pv  if 0 <= $pv and $pv <= 100;
            push(@$e, "bad percentage '$on=$ov', want value in 0..100");
            return $ov;
        },
    },

    {
        'type'    => "percentage_ge_50",
        'label'   => "N",
        'test'    => sub {
            my ($self, $on, $ov, $e) = @_;
            my $pv = $self->test_type('percentage', $on, $ov, $e);
            return $pv  if 50 <= $pv and $pv <= 100;
            push(@$e, "bad percentage '$on=$ov', want value in 50..100");
            return $ov;
        },
    },

    {
        'type'    => "infile",
        'label'   => "file",
        'default' => "",
        'test'    => sub {
            my ($self, $on, $ov, $e) = @_;
            if (defined $ov and $ov ne '') {
                local *TMP;
                open(TMP, "< $ov") or
                    push(@$e, "can't open $on file '$ov'");
                close TMP;
            }
            return $ov;
        },
    },

    {
        'type'    => "string_list",
        'label'   => "str[,str]",
        'default' => "",
        'test'    => sub {
            my ($self, $on, $ov, $e) = @_;
            return []  unless defined $ov;
            my @tmp = ();
            local $_;
            #warn "type: string_list($on, $ov) in\n";
            foreach (split /[,\s]+/, $ov) {
                next  unless length($_);
                #integer range M..N or M:N
                if (/^($RX_Uint)(?:\.\.|:)($RX_Uint)$/) {
                    if ($2 < $1) {
                        push @tmp, $2..$1;
                    } else {
                        push @tmp, $1..$2;
                    }
                    next;
                }
                #non-range: take whole string
                push @tmp, $_;
            }
            #warn "type: string_list(@tmp) out\n";
            #return [ sort @tmp ];
            return [ @tmp ];
        },
    },

    {
        'type'    => "u_int_list",
        'label'   => "int[,int]",
        'test'    => sub {
            my ($self, $on, $ov, $e) = @_;
            return []  unless defined $ov;
            my @tmp = ();
            local $_;
            #warn "type: u_int_list($on, $ov)\n";
            foreach (split /[,\s]+/, $ov) {
                next  unless length($_);
                #positive integer range M..N or M:N
                if (/^($RX_Uint)(?:\.\.|:)($RX_Uint)$/) {
                    if ($2 < $1) {
                        push @tmp, $2..$1;
                    } else {
                        push @tmp, $1..$2;
                    }
                    next;
                }
                #non-range
                if (/^($RX_Uint)$/ and ! /\.\./ and ! /:/) {
                    push @tmp, $1;
                    next;
                }
                push @$e, "bad integer list value '$_'";
                return [];
            }
            #warn "test: u_int_list(@tmp)\n";
            #return [ sort @tmp ];
            return [ @tmp ];
        },
    },

    {
        'type'    => "u_numeric_list",
        'label'   => "num[,num]",
        'test'    => sub {
            my ($self, $on, $ov, $e) = @_;
            return []  unless defined $ov;
            my @tmp = ();
            local $_;
            #warn "type: u_numeric_list($on, $ov)\n";
            foreach (split /[,\s]+/, $ov) {
                next  unless length($_);
                #non-range
                if (/^($RX_Ureal)$/ and ! /\.\./ and ! /:/) {
                    push @tmp, $1;
                    next;
                }
                push @$e, "bad numeric list value '$_'";
                return [];
            }
            #warn "type: u_numeric_list(@tmp)\n";
            #return [ sort @tmp ];
            return [ @tmp ];
        },
    },

    {
        'type'    => "integer_range",
        'label'   => "M:N,all",
        'test'    => sub {
            my ($self, $on, $ov, $e) = @_;
            return []  if $ov eq 'all';
            my @tmp = split(/:/, $ov);
            if (@tmp != 2) {
                push @$e, "bad range '$on=$ov', want M:N,all";
                return [];
            }
            $self->test_type('u_int', $on, $tmp[0], $e);
            if (@$e) {
                push @$e, "bad range '$on=$ov', want M:N,all";
                return [];
            }
            $self->test_type('u_int', $on, $tmp[1], $e);
            if (@$e) {
                push @$e, "bad range '$on=$ov', want M:N,all";
                return [];
            }
            if ($tmp[0] > $tmp[1]) {  #ensure ascending range
                my $tmp = $tmp[0]; $tmp[0] = $tmp[1]; $tmp[1] = $tmp;
            }
            return [ @tmp ];
        },
    },

    #### MVIEW TYPES ####

    {
        'type'    => "formats::in",
        'usage'   => "Input {@{[list_informats]}}",
        'label'   => "format",
        'default' => "",
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

    {
        'type'    => "formats::out",
        'usage'   => "Output {@{[list_outformats]}}",
        'label'   => "format",
        'default' => "new",
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

    {
        'type'    => "content::width",
        'usage'   => "Paginate alignment in blocks of N columns",
        'label'   => "N,flat",
        'default' => "flat",
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

    {
        'type'    => "identity::pcid",
        'usage'   => "Compute percent identities with respect to {@{[list_identity_modes]}}",
        'label'   => "mode",
        'default' => "aligned",
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

    {
        'type'    => "filter::top",
        'usage'   => "Report top N hits",
        'label'   => "N,all",
        'default' => "all",
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

    {
        'type'    => "moltype::type",
        'usage'   => "Affects coloring and format converions {@{[list_molecule_types]}}",
        'label'   => "mol",
        'default' => "aa",
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
            $self->update_option('ALIGNMENT::colormap',
                                 get_default_alignment_colormap($pv));

            $self->update_option('CONSENSUS::con_colormap',
                                 get_default_consensus_colormap($pv));

            $self->update_option('ALIGNMENT::groupmap',
                                 get_default_groupmap($pv));

            $self->update_option('CONSENSUS::con_groupmap',
                                 get_default_groupmap($pv));  #same
            return $pv;
        },
    },

    {
        'type'    => "alignment::coloring",
        'usage'   => "Basic style of coloring {@{[list_alignment_color_schemes]}}",
        'label'   => "mode",
        'default' => "none",
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

    {
        'type'    => "alignment::colormap",
        'usage'   => "Name of colormap to use",
        'label'   => "name",
        'default' => get_default_alignment_colormap,
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

    {
        'type'    => "alignment::groupmap",
        'usage'   => "Name of groupmap to use if coloring by consensus",
        'label'   => "name",
        'default' => get_default_groupmap,
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

    {
        'type'    => "alignment::ignore",
        'usage'   => "Ignore singleton or class groups {@{[list_ignore_classes]}}",
        'label'   => "mode",
        'default' => "none",
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

    {
        'type'    => "consensus::coloring",
        'usage'   => "Basic style of coloring {@{[list_consensus_color_schemes]}}",
        'label'   => "mode",
        'default' => "none",
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

    {
        'type'    => "consensus::colormap",
        'usage'   => "Name of colormap to use",
        'label'   => "name",
        'default' => get_default_consensus_colormap,
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

    {
        'type'    => "consensus::groupmap",
        'usage'   => "Name of groupmap to use if coloring by consensus",
        'label'   => "name",
        'default' => get_default_groupmap,
        'test'    => sub {
            my ($self, $on, $ov, $e) = @_;
            my $pv = check_groupmap($ov);
            if (! defined $pv) {
                push @$e, "consensus groupmap '$ov' unrecognised";
                push @$e, "known consensus groupmaps are: ",
                    join(",", list_groupmap_names);
            }
            return $pv;
        },
    },

    {
        'type'    => "consensus::threshold",
        'usage'   => "Consensus line thresholds",
        'label'   => "N[,N]",
        'default' => '100,90,80,70',
        'test'    => sub {
            my ($self, $on, $ov, $e) = @_;
            my $pv = $self->test_type('u_numeric_list', $on, $ov, $e);
            foreach my $v (@$pv) {
                if ($v < 50 or $v > 100) {
                    push @$e, ("bad percentage in '$ov', must be in range 50..100");
                }
            }
            return $pv;
        },
    },

    {
        'type'    => "consensus::ignore",
        'usage'   => "Ignore singleton or class groups {@{[list_ignore_classes]}}",
        'label'   => "mode",
        'default' => "none",
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

    {
        'type'    => "html::html_mode",
        'usage'   => "Controls amount of HTML markup {@{[list_html_modes]}}",
        'label'   => "mode",
        'default' => "off",
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

    {
        'type'    => "html::css_mode",
        'usage'   => "Use Cascading Style Sheets {@{[list_css_modes]}}",
        'label'   => "mode",
        'default' => "off",
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

    {
        'type'    => "srs::mode",
        'usage'   => "Try to use sequence database links",
        'label'   => "on|off",
        'default' => "off",
        'test'    => sub {
            my ($self, $on, $ov, $e) = @_;
            my $pv = $self->test_type('binary', $on, $ov, $e);
            return $Bio::MView::SRS::Type = 1  if $pv eq "1";
            return $Bio::MView::SRS::Type = 0  if $pv eq "0";
            return $ov;
        },
    },

    #### FORMAT SPECIFIC TYPES ####

    {
        'type'    => "blast::hsp_mode",
        'usage'   => "HSP tiling mode {@{[list_hsp_tiling]}",
        'label'   => "mode",
        'default' => "ranked",
        'test'    => sub {
            my ($self, $on, $ov, $e) = @_;
            my $pv = check_hsp_tiling($ov);
            if (! defined $pv) {
                push @$e, "bad hsp mode '$ov'";
                push @$e, "known hsp modes are: {" . list_hsp_tiling . "}";
            }
            return $pv;
        },
    },

    {
        'type'    => "blast::maxpval",
        'usage'   => "Ignore hits with p-value greater than N",
        'default' => "unlimited",
        'label'   => "N,unlimited",
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

    {
        'type'    => "blast::minscore",
        'usage'   => "Ignore hits with score less than N",
        'label'   => "N,unlimited",
        'default' => "unlimited",
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

    {
        'type'    => "blast::maxeval",
        'usage'   => "Ignore hits with e-value greater than N",
        'label'   => "N,unlimited",
        'default' => "unlimited",
        'test'    => sub {
            my ($self, $on, $ov, $e) = @_;
            return undef  if $ov eq 'unlimited';
            my $pv = $self->test_type('numeric_gt_0', $on, $ov, $e);
            if (! defined $pv) {
                pop @$e;
                push(@$e, "bad maxeval value '$ov', want numeric > 0");
            }
            return $pv;
        },
    },

    {
        'type'    => "blast::minbits",
        'usage'   => "Ignore hits with bits less than N",
        'label'   => "N,unlimited",
        'default' => "unlimited",
        'test'    => sub {
            my ($self, $on, $ov, $e) = @_;
            return undef  if $ov eq 'unlimited';
            my $pv = $self->test_type('numeric_gt_0', $on, $ov, $e);
            if (! defined $pv) {
                pop @$e;
                push(@$e, "bad minbits value '$ov', want numeric > 0");
            }
            return $pv;
        },
    },

    {
        'type'    => "blast::keepinserts",
        'usage'   => "Keep hit sequence insertions in unaligned output",
        'label'   => "on|off",
        'default' => "off",
        'test'    => sub {
            my ($self, $on, $ov, $e) = @_;
            return $self->test_type('binary', $on, $ov, $e);
        },
    },

    {
        'type'    => "psiblast::cycle",
        'usage'   => "Process the N'th cycle of a multipass search {@{[list_cycle_types]}}",
        'label'   => "cycles",
        'default' => "last",
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


    {
        'type'    => "search::strand",
        'usage'   => "Report only these query strand orientations {@{[list_strand_types]}}",
        'label'   => "strands",
        'default' => "both",
        'test'    => sub {
            my ($self, $on, $ov, $e) = @_;
            my $pv = check_strand_type($ov);
            if (! defined $pv) {
                push @$e, "bad strand orientation in '$ov'";
                push @$e, "valid strand orientations are: {"
                    . list_strand_types . "}";
            }
            return $pv;
        },
    },

    {
        'type'    => "align::block",
        'usage'   => "Report only these blocks {@{[list_block_values]}}",
        'label'   => "blocks",
        'default' => "first",
        'test'    => sub {
            my ($self, $on, $ov, $e) = @_;
            my $pv = check_block_value($ov);
            if (! defined $pv) {
                push @$e, "bad block value in '$ov'";
                push @$e, "valid block values are: {"
                    . list_block_values . "}";
            }
            return $pv;
        },
    },

    {
        'type'    => "hssp::chain",
        'usage'   => "Report only these chain names/numbers {@{[list_chain_values]}}",
        'label'   => "chains",
        'default' => "*",
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

    {
        'type'    => "fasta::minopt",
        'usage'   => "Ignore hits with opt score less than N",
        'label'   => "N,unlimited",
        'default' => "unlimited",
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

];

###########################################################################
1;
