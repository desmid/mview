# Copyright (C) 2018 Nigel P. Brown

######################################################################
package Bio::MView::Option::Types;

use Bio::MView::Option::Arguments;
use NPB::Parse::Regexps;
use strict;
use vars qw($Types);

###########################################################################
$Types = [
    #generic reusable types

    {
        'type'    => "flag",  #no argument
        'label'   => "",
        'default' => "",
        'test'    => sub {
            my ($self, $on, $ov, $e) = @_;
            return 0  if $ov eq '';  #default
            return 0  if $ov eq 'off' or $ov eq '0';
            return 1  if $ov eq 'on'  or $ov eq '1';
        },
    },

    {
        'type'    => "inverter",  #flag, no argument, invert input
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
        'label'   => "{off,on}",
        'test'    => sub {
            my ($self, $on, $ov, $e) = @_;
            return 0  if $ov eq 'off' or $ov eq '0';
            return 1  if $ov eq 'on'  or $ov eq '1';
            push(@$e, "bad argument '$on=$ov', want {off,on} or {0,1}");
            return $ov;
        },
    },

    {
        'type'    => "char",
        'label'   => "char",
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
        'label'   => "{M:N,all}",
        'test'    => sub {
            my ($self, $on, $ov, $e) = @_;
            return []  if $ov eq 'all';
            my @tmp = split(/:/, $ov);
            if (@tmp != 2) {
                push @$e, "bad range '$on=$ov', want {M:N,all}";
                return [];
            }
            $self->test_type('u_int', $on, $tmp[0], $e);
            if (@$e) {
                push @$e, "bad range '$on=$ov', want {M:N,all}";
                return [];
            }
            $self->test_type('u_int', $on, $tmp[1], $e);
            if (@$e) {
                push @$e, "bad range '$on=$ov', want {M:N,all}";
                return [];
            }
            if ($tmp[0] > $tmp[1]) {  #ensure ascending range
                my $tmp = $tmp[0]; $tmp[0] = $tmp[1]; $tmp[1] = $tmp;
            }
            return [ @tmp ];
        },
    },

    ###########################################################################
    #format specific common reusable types

    {
        'type'    => "hsp_mode",
        'label'   => "mode",
        'usage'   => "HSP tiling mode {@{[list_hsp_tiling]}",
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
        'type'    => "maxeval",
        'label'   => "{N,unlimited}",
        'usage'   => "Ignore hits with e-value greater than N",
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
        'type'    => "minbits",
        'label'   => "{N,unlimited}",
        'usage'   => "Ignore hits with bits less than N",
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
        'type'    => "strand",
        'label'   => "strand",
        'usage'   => "Report only these query strand orientations {@{[list_strand_types]}}",
        'default' => "both",
        'test'  => sub {
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
        'type'    => "keepinserts",
        'label'   => "",
        'usage'   => "Keep hit sequence insertions in unaligned output",
        'default' => "off",
        'test'  => sub {
            my ($self, $on, $ov, $e) = @_;
            return $self->test_type('binary', $on, $ov, $e);
        },
    },

    {
        'type'    => "block",
        'label'   => "block",
        'usage'   => "Report only these blocks {@{[list_block_values]}}",
        'default' => "first",
        'test'  => sub {
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

];


###########################################################################
1;
