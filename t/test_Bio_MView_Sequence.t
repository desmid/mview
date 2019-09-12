#!/usr/bin/env perl
# Copyright (C) 2015-2018 Nigel P. Brown

use Test::More;
use lib 'lib';
use strict;

use_ok('Bio::MView::Sequence::Base');

sub main {
    my @args = @_;

    test__create_empty();
    test__forward_insert();
    test__reverse_insert();
    test__set_special_chars();
    test__special_chars_behaviour();
    test__toy_cases();

    done_testing;
    return 0;
}

exit main(@ARGV);

###########################################################################
TODO: { local $TODO = "not implemented"; };

#used repeatedly by other tests
sub test_state {
    my ($tname, $S, $h) = @_;
    if ($h->{reverse}) {
        isa_ok($S, 'Bio::MView::Sequence::Reverse');
        is($S->is_forwards, 0, "is_forwards = 0");
    } else {
        isa_ok($S, 'Bio::MView::Sequence::Forward');
        is($S->is_forwards, 1, "is_forwards = 1");
    }
    is($S->frameshifts, $h->{fs},       "$tname: frameshifts is $h->{fs}");
    is($S->lo,          $h->{lo},       "$tname: lo is $h->{lo}");
    is($S->hi,          $h->{hi},       "$tname: hi is $h->{hi}");
    is($S->reflo,       $h->{reflo},    "$tname: reflo is $h->{reflo}");
    is($S->refhi,       $h->{refhi},    "$tname: refhi is $h->{refhi}");
    is($S->leader,      $h->{leader},   "$tname: leader is $h->{leader}");
    is($S->trailer,     $h->{trailer},  "$tname: trailer is $h->{trailer}");
    is($S->length,      $h->{length},   "$tname: length is $h->{length}");
    is($S->seqlen,      $h->{seqlen},   "$tname: seqlen is $h->{seqlen}");
    is($S->lablen,      $h->{lablen},   "$tname: lablen is $h->{lablen}");
    is($S->string,      $h->{string},   "$tname: string is '$h->{string}'");
    is($S->sequence,    $h->{sequence}, "$tname: sequence is '$h->{sequence}'");
}

sub test_labels {
    my ($tname, $S, $h) = @_;
    is($S->fromlabel1, $h->{fromlabel1}, "$tname: fromlabel1 is $h->{fromlabel1}");
    is($S->tolabel1,   $h->{tolabel1},   "$tname: tolabel1   is $h->{tolabel1}");
    is($S->fromlabel2, $h->{fromlabel2}, "$tname: fromlabel2 is $h->{fromlabel2}");
    is($S->tolabel2,   $h->{tolabel2},   "$tname: tolabel2   is $h->{tolabel2}");
}

###########################################################################
sub test__create_empty {
    my $tname = "create_empty";

    my $h = {
        'lo'       => 0,     'hi'          => 0,
        'reflo'    => 0,     'refhi'       => 0,
        'leader'   => 0,     'trailer'     => 0,
        'string'   => '',    'length'      => 0,
                             'lablen'      => 0,
        'sequence' => '',    'seqlen'      => 0,
        'reverse'  => undef, 'fs' => 0,
    };
    my $S;

    $S = new Bio::MView::Sequence::Forward;
    ok(defined $S, "$tname: new Sequence");
    $h->{reverse} = 0; test_state($tname, $S, $h);

    $S = new Bio::MView::Sequence::Reverse;
    ok(defined $S, "$tname: new reverse Sequence");
    $h->{reverse} = 1; test_state($tname, $S, $h);
}

sub test__forward_insert {
    my ($S, $s, $f, $h);
    my $tbase = "forward_insert: B AB ABC X-ABC X-ABC-Y";
    my $tname;

    $tname = "$tbase: insert(empty)";
    $S = new Bio::MView::Sequence();
    $h = {
        'lo'       => 0,        'hi'             => 0,
        'reflo'    => 0,        'refhi'          => 0,
        'leader'   => 0,        'trailer'        => 0,
        'string'   => '',       'length'         => 0,
                                'lablen'         => 0,
        'sequence' => '',       'seqlen'         => 0,
        'reverse'  => 0,        'fs' => 0,
    };
    $S->insert(); test_state($tname, $S, $h);

    $tname = "$tbase: insert character at [20]";
    $S = new Bio::MView::Sequence();
    $s = 'B'; $f = [\$s, 20, 20]; $h = {
        'lo'       => 20,       'hi'             => 20,
        'reflo'    => 20,       'refhi'          => 20,
        'leader'   => 0,        'trailer'        => 0,
        'string'   => 'B',      'length'         => 1,
                                'lablen'         => 1,
        'sequence' => 'B',      'seqlen'         => 1,
        'reverse'  => 0,        'fs' => 0,
    };
    $S->insert($f); test_state($tname, $S, $h);

    $tname = "$tbase: rewrite same character at [20]";
    $S->insert($f); test_state($tname, $S, $h);

    $tname = "$tbase: prepend character at [19]";
    $s = 'A'; $f = [\$s, 19, 19]; $h = {
        'lo'       => 19,       'hi'             => 20,
        'reflo'    => 19,       'refhi'          => 20,
        'leader'   => 0,        'trailer'        => 0,
        'string'   => 'AB',     'length'         => 2,
                                'lablen'         => 2,
        'sequence' => 'AB',     'seqlen'         => 2,
        'reverse'  => 0,        'fs' => 0,
    };
    $S->insert($f); test_state($tname, $S, $h);

    $tname = "$tbase: insert character at [21]";
    $s = 'C'; $f = [\$s, 21, 21]; $h = {
        'lo'       => 19,       'hi'             => 21,
        'reflo'    => 19,       'refhi'          => 21,
        'leader'   => 0,        'trailer'        => 0,
        'string'   => 'ABC',    'length'         => 3,
                                'lablen'         => 3,
        'sequence' => 'ABC',    'seqlen'         => 3,
        'reverse'  => 0,        'fs' => 0,
    };
    $S->insert($f); test_state($tname, $S, $h);

    $tname = "$tbase: prepend character at [17] with a gap";
    $s = 'X'; $f = [\$s, 17, 17]; $h = {
        'lo'       => 17,       'hi'             => 21,
        'reflo'    => 17,       'refhi'          => 21,
        'leader'   => 0,        'trailer'        => 0,
        'string'   => 'X-ABC',  'length'         => 5,
                                'lablen'         => 5,
        'sequence' => 'XABC',   'seqlen'         => 4,
        'reverse'  => 0,        'fs' => 0,
    };
    $S->insert($f); test_state($tname, $S, $h);

    $tname = "$tbase: apppend character at [23] with a gap";
    $s = 'Y'; $f = [\$s, 23, 23]; $h = {
        'lo'       => 17,        'hi'             => 23,
        'reflo'    => 17,        'refhi'          => 23,
        'leader'   => 0,         'trailer'        => 0,
        'string'   => 'X-ABC-Y', 'length'         => 7,
                                 'lablen'         => 7,
        'sequence' => 'XABCY',   'seqlen'         => 5,
        'reverse'  => 0,         'fs' => 0,
    };
    $S->insert($f); test_state($tname, $S, $h);
}

sub test__reverse_insert {
    my ($S, $s, $f, $h);
    my $tbase = "reverse_insert: B AB ABC X-ABC X-ABC-Y";
    my $tname;

    $tname = "$tbase: insert empty";
    $S = new Bio::MView::Sequence::Reverse();
    $h = {
        'lo'       => 0,        'hi'             => 0,
        'reflo'    => 0,        'refhi'          => 0,
        'leader'   => 0,        'trailer'        => 0,
        'string'   => '',       'length'         => 0,
                                'lablen'         => 0,
        'sequence' => '',       'seqlen'         => 0,
        'reverse'  => 1,        'fs' => 0,
    };
    $S->insert();  test_state($tname, $S, $h);

    $tname = "$tbase: insert character at [20]";
    $S = new Bio::MView::Sequence::Reverse();
    $s = 'B'; $f = [\$s, 20, 20]; $h = {
        'lo'       => 20,       'hi'             => 20,
        'reflo'    => 20,       'refhi'          => 20,
        'leader'   => 0,        'trailer'        => 0,
        'string'   => 'B',      'length'         => 1,
                                'lablen'         => 1,
        'sequence' => 'B',      'seqlen'         => 1,
        'reverse'  => 1,        'fs' => 0,
    };
    $S->insert($f); test_state($tname, $S, $h);

    $tname = "$tbase: rewrite same character at [20]";
    $S->insert($f); test_state($tname, $S, $h);

    $tname = "$tbase: prepend character at [19]";
    $s = 'A'; $f = [\$s, 19, 19]; $h = {
        'lo'       => 19,       'hi'             => 20,
        'reflo'    => 20,       'refhi'          => 19,
        'leader'   => 0,        'trailer'        => 0,
        'string'   => 'BA',     'length'         => 2,
                                'lablen'         => 2,
        'sequence' => 'BA',     'seqlen'         => 2,
        'reverse'  => 1,        'fs' => 0,
    };
    $S->insert($f); test_state($tname, $S, $h);

    $tname = "$tbase: insert character at [21]";
    $s = 'C'; $f = [\$s, 21, 21]; $h = {
        'lo'       => 19,       'hi'             => 21,
        'reflo'    => 21,       'refhi'          => 19,
        'leader'   => 0,        'trailer'        => 0,
        'string'   => 'CBA',    'length'         => 3,
                                'lablen'         => 3,
        'sequence' => 'CBA',    'seqlen'         => 3,
        'reverse'  => 1,        'fs' => 0,
    };
    $S->insert($f); test_state($tname, $S, $h);

    $tname = "$tbase: prepend character at [17] with a gap";
    $s = 'X'; $f = [\$s, 17, 17]; $h = {
        'lo'       => 17,       'hi'             => 21,
        'reflo'    => 21,       'refhi'          => 17,
        'leader'   => 0,        'trailer'        => 0,
        'string'   => 'CBA-X',  'length'         => 5,
                                'lablen'         => 5,
        'sequence' => 'CBAX',   'seqlen'         => 4,
        'reverse'  => 1,        'fs' => 0,
    };
    $S->insert($f); test_state($tname, $S, $h);

    $tname = "$tbase: apppend character at [23] with a gap";
    $s = 'Y'; $f = [\$s, 23, 23]; $h = {
        'lo'       => 17,        'hi'             => 23,
        'reflo'    => 23,        'refhi'          => 17,
        'leader'   => 0,         'trailer'        => 0,
        'string'   => 'Y-CBA-X', 'length'         => 7,
                                 'lablen'         => 7,
        'sequence' => 'YCBAX',   'seqlen'         => 5,
        'reverse'  => 1,         'fs' => 0,
    };
    $S->insert($f); test_state($tname, $S, $h);
}

sub test__set_special_chars {
    my $tname = "set_special_chars";

    my $S = new Bio::MView::Sequence::Forward;
    my $c = {
        'pad' => qw(.), 'gap' => qw(-), 'spc' => ' ',
        'fs1' => qw(/), 'fs2' => qw(\\),
    };

    is($S->get_pad, $c->{pad},  "$tname: get_pad is '$c->{pad}'");
    is($S->get_gap, $c->{gap},  "$tname: get_gap is '$c->{gap}'");
    is($S->get_spc, $c->{spc},  "$tname: get_spc is '$c->{spc}'");
    is($S->get_fs1, $c->{fs1},  "$tname: get_fs1 is '$c->{fs1}'");
    is($S->get_fs2, $c->{fs2},  "$tname: get_fs2 is '$c->{fs2}'");
}

sub test__special_chars_behaviour {
    my ($S, $s, $f, $h);
    my $tbase = "special_chars_behaviour";
    my $tname;

    $tname = "$tbase: pad";
    $S = new Bio::MView::Sequence();
    $S->set_pad('~');
    $s = '.P..'; $f = [\$s, 20, 23]; $h = {
        'lo'       => 20,       'hi'             => 23,
        'reflo'    => 21,       'refhi'          => 21,
        'leader'   => 1,        'trailer'        => 2,
        'string'   => '~P~~',   'length'         => 4,
                                'lablen'         => 4,
        'sequence' => 'P',      'seqlen'         => 1,
        'reverse'  => 0,        'fs' => 0,
    };
    $S->insert($f); test_state($tname, $S, $h);

    $tname = "$tbase: gap";
    $S = new Bio::MView::Sequence();
    $S->set_gap('?');
    $s = 'A-B'; $f = [\$s, 20, 22]; $h = {
        'lo'       => 20,       'hi'             => 22,
        'reflo'    => 20,       'refhi'          => 22,
        'leader'   => 0,        'trailer'        => 0,
        'string'   => 'A?B',    'length'         => 3,
                                'lablen'         => 3,
        'sequence' => 'AB',     'seqlen'         => 2,
        'reverse'  => 0,        'fs' => 0,
    };
    $S->insert($f); test_state($tname, $S, $h);

    $tname = "$tbase: spc";
    $S = new Bio::MView::Sequence();
    $S->set_gap('?');
    $s = ' A B '; $f = [\$s, 20, 24]; $h = {
        'lo'       => 20,       'hi'             => 24,
        'reflo'    => 20,       'refhi'          => 24,
        'leader'   => 0,        'trailer'        => 0,
        'string'   => ' A B ',  'length'         => 5,
                                'lablen'         => 5,
        'sequence' => 'AB',     'seqlen'         => 2,
        'reverse'  => 0,        'fs' => 0,
    };
    $S->insert($f); test_state($tname, $S, $h);

    $tname = "$tbase: fs1";
    $S = new Bio::MView::Sequence();
    $s = 'PES/GRP'; $f = [\$s, 20, 27]; $h = {
        'lo'       => 20,        'hi'             => 27,
        'reflo'    => 20,        'refhi'          => 27,
        'leader'   => 0,         'trailer'        => 0,
        'string'   => 'PES/GRP', 'length'         => 8,
                                 'lablen'         => 8,
        'sequence' => 'PESGRP',  'seqlen'         => 6,
        'reverse'  => 0,         'fs' => 1,
    };
    $S->insert($f); test_state($tname, $S, $h);

    $tname = "$tbase: fs2";
    $S = new Bio::MView::Sequence();
    $s = 'PES\GRP'; $f = [\$s, 20, 26]; $h = {
        'lo'       => 20,        'hi'             => 26,
        'reflo'    => 20,        'refhi'          => 26,
        'leader'   => 0,         'trailer'        => 0,
        'string'   => 'PES\GRP', 'length'         => 7,
                                 'lablen'         => 7,
        'sequence' => 'PESGRP',  'seqlen'         => 6,
        'reverse'  => 0,         'fs' => 1,
    };
    $S->insert($f); test_state($tname, $S, $h);

    $tname = "$tbase: fastx_3.4t23.dat (simple)";
    my $frg = [1, 115, 'TDQLEDEKSALQTEIANLLKEKEKLEFILAAHRPACKIPDDLGFPEEMSVASLDLTGGLPEVATPESEEAFTLPLLNDPEPKPSVEPVKSISSMELKTEPFDDFLFPASSRPSG'];
    my $ungapped = $frg->[2]; $ungapped =~ s/\///g;
    $S = new Bio::MView::Sequence();
    $f = [\$frg->[2], $frg->[0], $frg->[1]]; $h = {
        'lo'       => 1,         'hi'             => 115,
        'reflo'    => 1,         'refhi'          => 115,
        'leader'   => 0,         'trailer'        => 0,
        'string'   => $frg->[2], 'length'         => 115,
                                 'lablen'         => 115,
        'sequence' => $ungapped, 'seqlen'         => length($ungapped),
        'reverse'  => 0,         'fs' => 0,
    };
    $S->insert($f); test_state($tname, $S, $h);

    $tname = "$tbase: fastx_3.4t23.dat (frameshift)";
    my $frg = [18, 194, 'PAEGEGKTRVHPGSSPTCLQDP**PGLPRRDVCGFP*SDWGPARGCHPGV*GGLHPASPQ*P*AQ/SPQWNLSRASAAWS*RPSPLMTSCSQHHPGPVALRQPAPCQTWTYLGPSMQQTGSLCTVAPWGWGPWPQSWSPCALRWSPVLPAALLTRLPSSSPTPRLTPSPAVQLPTA'];
    my $ungapped = $frg->[2]; $ungapped =~ s/\///g;
    $S = new Bio::MView::Sequence();
    $f = [\$frg->[2], $frg->[0], $frg->[1]]; $h = {
        'lo'       => 18,        'hi'             => 194,
        'reflo'    => 18,        'refhi'          => 194,
        'leader'   => 0,         'trailer'        => 0,
        'string'   => $frg->[2], 'length'         => 177,
                                 'lablen'         => 177,
        'sequence' => $ungapped, 'seqlen'         => length($ungapped),
        'reverse'  => 0,         'fs' => 1,
    };
    $S->insert($f); test_state($tname, $S, $h);
}

sub test__toy_cases {
    my ($S, $s, $f, $h);
    my $tbase = "toy_cases";
    my $tname;

    $tname = "case 1: forward query";
    $S = new Bio::MView::Sequence();
    $s = '23456'; $f = [\$s, 2, 6]; $h = {
        'lo'       => 2,        'hi'             => 6,
        'reflo'    => 2,        'refhi'          => 6,
        'leader'   => 0,        'trailer'        => 0,
        'string'   => '23456',  'length'         => 5,
                                'lablen'         => 5,
        'sequence' => '23456',  'seqlen'         => 5,
        'reverse'  => 0,        'fs' => 0,
    };
    $S->insert($f); test_state($tname, $S, $h);

    $tname = "case 1: forward query + forward hit";
    $S = new Bio::MView::Sequence();
    $S->set_pad('-');
    $s = '-23--'; $f = [\$s, 2, 6]; $h = {
        'lo'       => 2,        'hi'             => 6,
        'reflo'    => 3,        'refhi'          => 4,
        'leader'   => 1,        'trailer'        => 2,
        'string'   => '-23--',  'length'         => 5,
                                'lablen'         => 5,
        'sequence' => '23',     'seqlen'         => 2,
        'reverse'  => 0,        'fs' => 0,
    };
    $S->insert($f); test_state($tname, $S, $h);

    $tname = "case 1: reverse query";
    $S = new Bio::MView::Sequence::Reverse();
    $s = '65432'; $f = [\$s, 6, 2]; $h = {
        'lo'       => 2,        'hi'             => 6,
        'reflo'    => 6,        'refhi'          => 2,
        'leader'   => 0,        'trailer'        => 0,
        'string'   => '65432',  'length'         => 5,
                                'lablen'         => 5,
        'sequence' => '65432',  'seqlen'         => 5,
        'reverse'  => 1,        'fs' => 0,
    };
    $S->insert($f); test_state($tname, $S, $h);

    $tname = "case 1: reverse query + forward hit";
    $S = new Bio::MView::Sequence::Reverse();
    $S->set_pad('-');
    $s = '-23--'; $f = [\$s, 6, 2]; $h = {
        'lo'       => 2,        'hi'             => 6,
        'reflo'    => 5,        'refhi'          => 4,
        'leader'   => 1,        'trailer'        => 2,
        'string'   => '-23--',  'length'         => 5,
                                'lablen'         => 5,
        'sequence' => '23',     'seqlen'         => 2,
        'reverse'  => 1,        'fs' => 0,
    };
    $S->insert($f); test_state($tname, $S, $h);
}

# TODO
#
# test raw, col  (easy - use the tests I just did on X-ABC-Y)
#
# test longer segments and al classes of overlap
#
# 1. ---- ----
#
# 2. -----           3.       -----
#       -----              -----
#
# 4. ------------    5.     ----
#        ----           -------------
#
# (6.   ------     ------   ------   and the 3 opposites)
# (     ------     -----     -----                      )
#
# test negative? positions: should/does it fail?
#
# test overwrite really does keep original character(s)
#
# test labels:
#     labels1  for the reference sequence
#     labels2  for the dependent sequence
#
# test special characters insertion/removal, especially frameshifts
#
# test is_X predicates
#
# repeat everything for Sequence::Reverse
#
# subclass a Forward_Sequence
#
# test _substr
#
# implement a true substr
#
# (test findall) - should it be here?
