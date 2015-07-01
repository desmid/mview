# Copyright (C) 1997-2015 Nigel P. Brown
# $Id: BLAST.pm,v 1.12 2015/06/14 17:09:04 npb Exp $

###########################################################################
#
# generic BLAST material
#
###########################################################################
package Bio::MView::Build::Format::BLAST;

use Bio::MView::Build::Search;
use NPB::Parse::Regexps;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Search);

#the name of the underlying NPB::Parse::Stream parser
sub parser { 'BLAST' }

my $MISSING_QUERY_CHAR = 'X';  #interpolate this between query fragments

my %Known_Parameters =
    (
     #name        => [ format       default  ]

     #BLAST* display various HSP selections
     'hsp'        => [ '\S+',       'ranked' ],

     #BLAST* (version 1)
     'maxpval'    => [ $RX_Ureal,   undef    ],
     'minscore'   => [ '\d+',       undef    ],

     #BLAST* (version 2)
     'maxeval'    => [ $RX_Ureal,   undef    ],
     'minbits'    => [ '\d+',       undef    ],
     'cycle'      => [ [],          undef    ],

     #BLASTN (version 1, version 2); BLASTX (version 2)
     'strand'     => [ [],          undef    ],

     #BLASTX/TBLASTX (version 1)
    );

#tell the parent
sub known_parameters { \%Known_Parameters }

#our own constructor since this is the entry point for different subtypes
sub new {
    shift;  #discard type
    my $self = new Bio::MView::Build::Search(@_);
    my ($type, $p, $v, $file);

    #determine the real type from the underlying parser
    ($p, $v) = (lc $self->{'entry'}->{'format'}, $self->{'entry'}->{'version'});

    $type = "Bio::MView::Build::Format::BLAST$v";
    ($file = $type) =~ s/::/\//g;
    require "$file.pm";

    $type .= "::$p";
    bless $self, $type;

    $self->initialise_parameters;
    $self->initialise_child;

    $self;
}

#called by the constructor
sub initialise_child {
    my $self = shift;
    my $scheduler = $self->scheduler;
    #warn "initialise_child ($scheduler)\n";
    while (1) {
        $self->{scheduler} = new Bio::MView::Build::Scheduler,
        last if $scheduler eq 'none';

        $self->{scheduler} = new Bio::MView::Build::Scheduler([qw(+ -)]);
        last if $scheduler eq 'strand';

        if ($scheduler eq 'cycle') {
            my $last = $self->{'entry'}->count(qw(SEARCH));
            $self->{scheduler} = new Bio::MView::Build::Scheduler([1..$last]);
            last;
        }

        if ($scheduler eq 'cycle+strand') {
            my $last = $self->{'entry'}->count(qw(SEARCH));
            $self->{scheduler} =
                new Bio::MView::Build::Scheduler([1..$last], [qw(+ -)]);
            last;
        }

        die "initialise_child: unknown scheduler '$scheduler'";
    }
    return $self;
}

#called on each iteration
sub reset_child {
    my $self = shift;
    my $scheduler = $self->scheduler;
    #warn "reset_child ($scheduler)\n";
    while (1) {
        last if $scheduler eq 'none';

        #(warn "strands: [@{$self->{'strand'}}]\n"),
        $self->{scheduler}->filter($self->{'strand'}),
        last if $scheduler eq 'strand';

        #(warn "cycles: [@{$self->{'cycle'}}]\n"),
        $self->{scheduler}->filter($self->{'cycle'}),
        last if $scheduler eq 'cycle';

        #(warn "cycles+strands: [@{$self->{'cycle'}}][@{$self->{'strand'}}]\n"),
        $self->{scheduler}->filter($self->{'cycle'}, $self->{'strand'}),
        last if $scheduler eq 'cycle+strand';

        die "reset_child: unknown scheduler '$scheduler'";
    }
    return $self;
}

#current cycle being processed
sub cycle {
    my $scheduler = $_[0]->scheduler;
    return $_[0]->{scheduler}->item       if $scheduler eq 'cycle';
    return ($_[0]->{scheduler}->item)[0]  if $scheduler eq 'cycle+strand';
    return 1;
}

#current strand being processed
sub strand {
    my $scheduler = $_[0]->scheduler;
    return $_[0]->{scheduler}->item       if $scheduler eq 'strand';
    return ($_[0]->{scheduler}->item)[1]  if $scheduler eq 'cycle+strand';
    return '+';
}

sub subheader {
    my ($self, $quiet) = (@_, 0);
    my $s = '';
    return $s  if $quiet;
    if ($self->{'hsp'} eq 'all') {
	$s .= "HSP processing: all\n";
    } elsif ($self->{'hsp'} eq 'discrete') {
	$s .= "HSP processing: discrete\n";
    } else {
	$s .= "HSP processing: ranked\n";
    }
    $s;
}

#override base class method to process query row differently
sub build_rows {
    my $self = shift;
    my ($lo, $hi, $i);

    #first, compute alignment length from query sequence in row[0]
    ($lo, $hi) = $self->set_range($self->{'index2row'}->[0]);

    #warn "range ($lo, $hi)\n";

    #query row contains missing query sequence, rather than gaps
    $self->{'index2row'}->[0]->assemble($lo, $hi, $MISSING_QUERY_CHAR);

    #assemble sparse sequence strings for all rows
    for ($i=1; $i < @{$self->{'index2row'}}; $i++) {
	$self->{'index2row'}->[$i]->assemble($lo, $hi, $self->{'gap'});
    }
    $self;
}

#return true if two strings encode the same strand orientation; assumes
#the first character contains the sign
sub samesign { substr($_[1], 0, 1) eq substr($_[2], 0, 1) }

#override as necessary
sub score_attr { 'unknown' }
sub sig_attr   { 'unknown' }

#utility/testing function
sub report_ranking_data {
    my ($self, $match, $coll, $rkey, $qorient) = @_;
    return  unless $qorient eq '+';  #called multiply; only want one pass
    my $n     = $coll->item($rkey)->get_val('n'),
    my $score = $coll->item($rkey)->get_val($self->score_attr),
    my $sig   = $coll->item($rkey)->get_val($self->sig_attr);
    my $state = -1;
    my ($asco, $asig);
    #look for a match (ranking==hit by score and sig) in either orientation
    foreach my $aln ($match->parse(qw(ALN))) {
        last  if $state > 1;
        $state = 0; #entered loop body at least once
        $asco = $aln->{$self->score_attr};
        $asig = $aln->{$self->sig_attr};
        #match conditions
        $state = 2, next  if $score == $asco and $sig == $asig;
        my $ascor = sprintf('%0.f', $asco);
        $state = 3, next  if $score == $ascor and $sig == $asig;
    }
    return  if $state < 0;
    warn "(@{[$self->cycle]})$rkey match: identity\n"  if $state == 2;
    warn "(@{[$self->cycle]})$rkey match: round(score=$score/$asco)\n"
        if $state == 3;
    return  if $state > 0;
    #no match, start reporting
    warn "(@{[$self->cycle]})$rkey <<<<<<<<<<<<<<<<\n";
    foreach my $aln ($match->parse(qw(ALN))) {
        my $asco = $aln->{$self->score_attr};
        my $asig = $aln->{$self->sig_attr};
        my $aqorient = $aln->{'query_orient'};
        warn "$aqorient score: $score $asco " . "sig: $sig $asig  " .
            "@{[$score == $asco ? '1' : '0']} @{[$sig == $asig ? '1' : '0']} | @{[$score == sprintf('%0.f', $asco) ? '1' : '0']}\n";
    }
}

#return a hash of HSP sets; each set is a list of ALN with a given query/sbjct
#ordering, number of fragments, and significance; these sets have multiple
#alternative keys: "qorient/sorient/n/sig", "qorient/sorient/n/score",
#"qorient/sorient/score" to handle fuzziness and errors in the input data.
sub get_hsp_groups {
    my ($self, $match) = @_;
    my $hash = {};
    foreach my $aln ($match->parse(qw(ALN))) {
        my $n       = $aln->{'n'};
        my $score   = $aln->{$self->score_attr};
        my $sig     = $aln->{$self->sig_attr};
        my $qorient = $aln->{'query_orient'};
        my $sorient = $aln->{'sbjct_orient'};
        my (%tmp, $key);

        #key by significance: can exceed $n if more HSP have the same sig
        %tmp = ( $sig => 1 );               #raw significance value
        #BLAST1 and WU-BLAST
        if ($self->sig_attr eq 'p' and $sig !~ /e/i) {
            $tmp{sprintf("%.2f", $sig)}++;  #rounded sig (2dp)
        }
        #generic
        foreach my $sig (keys %tmp) {
            #full information
            $key = join("/", $qorient, $sorient, $n, $sig);
            push @{ $hash->{$key} }, $aln;

            #without N as this can be missing in the ranking or wrong
            $key = join("/", $qorient, $sorient, $sig);
            push @{ $hash->{$key} }, $aln;
        }

        #key by N and score, but we also need to consider rounding:
        #
        #round to nearest integer, or, if X.5, round both ways; this is
        #because the scores reported in the ranking and in the hit summary are
        #themselves rounded from an unknown underlying score, so simply
        #rounding the HSP score is not enough, viz.
        # underlying: 9.49 -> ranking (0dp) 9
        # underlying: 9.49 -> hit     (1dp) 9.5
        # round(9.5, 0) = 10 != 9
        %tmp = ( $score => 1 );             #raw score
        $tmp{sprintf("%.0f", $score)}++;    #rounded score (0dp)
        if ($score - int($score) == 0.5) {  #edge cases +/- 0.5
            $tmp{$score - 0.5}++;
            $tmp{$score + 0.5}++;
        }
        foreach my $score (keys %tmp) {
            #full information
            $key = join("/", $qorient, $sorient, $n, $score);
            push @{ $hash->{$key} }, $aln;

            #without N as this can be missing in the ranking or wrong
            $key = join("/", $qorient, $sorient, $score);
            push @{ $hash->{$key} }, $aln;
        }
    }
    #warn "SAVE: @{[sort keys %$hash]}\n";
    return $hash;
}

#lookup an HSP set in an HSP dictionary, trying various keys based on number
#of HSPs N, significance or score.
sub get_ranked_hsps_by_query {
    my ($self, $hash, $coll, $rkey, $qorient) = @_;

    my $n        = $coll->item($rkey)->get_val('n');
    my $score    = $coll->item($rkey)->get_val($self->score_attr);
    my $qorient2 = ($qorient eq '+' ? '-' : '+');

    $n = 1  unless $n;  #no N in ranking

    my $D = 0;

    my $lookup_o_n_sig = sub {
        my ($qorient, $n, $sig) = @_;
        foreach my $sorient (qw(+ -)) {
            my $key = join("/", $qorient, $sorient, $n, $sig);
            return $hash->{$key}  if exists $hash->{$key};
        }
        return undef;
    };

    my $follow_sig = sub {
        my ($qorient, $key) = @_;

        #take the sig of the first matching HSP: expand that set
        my $n     = $hash->{$key}->[0]->{'n'};
        my $score = $hash->{$key}->[0]->{$self->score_attr};
        my $sig   = $hash->{$key}->[0]->{$self->sig_attr};
        warn "MAP: $qorient $n $score -> $sig\n"  if $D;

        my $match;

        #match in query orientation?
        $match = &$lookup_o_n_sig($qorient, $n, $sig);
        return $match  if defined $match;

        #match in opposite orientation? skip
        $match = &$lookup_o_n_sig($qorient2, $n, $sig);
        return []  if defined $match;

        return undef;
    };

    my $lookup_o_n_score = sub {
        my ($qorient, $n, $score) = @_;
        foreach my $sorient (qw(+ -)) {
            my $key = join("/", $qorient, $sorient, $n, $score);
            return &$follow_sig($qorient, $key)  if exists $hash->{$key};
        }
        return undef;
    };

    my $lookup_score = sub {
        my ($qorient, $score) = @_;
        foreach my $sorient (qw(+ -)) {
            my $key = join("/", $qorient, $sorient, $score);
            return &$follow_sig($qorient, $key)  if exists $hash->{$key};
        }
        return undef;
    };

    my $match;

    warn "KEYS($rkey): @{[sort keys %$hash]}\n"  if $D;

    #match (n, score) in query orientation?
    warn "TRY: $qorient $n $score\n"  if $D;
    $match = &$lookup_o_n_score($qorient, $n, $score);
    warn "MATCH (@{[scalar @$match]})\n"  if defined $match and $D;
    return $match  if defined $match;

    #match (n, score) in opposite orientation? skip
    warn "TRY: $qorient2 $n $score (to skip)\n"  if $D;
    $match = &$lookup_o_n_score($qorient2, $n, $score);
    warn "SKIP (@{[scalar @$match]})\n"  if defined $match and $D;
    return []  if defined $match;

    #match (score) in query orientation?
    warn "TRY: $qorient $score\n"  if $D;
    $match = &$lookup_score($qorient, $score);
    warn "MATCH (@{[scalar @$match]})\n"  if defined $match and $D;
    return $match  if defined $match;

    #match (score) in opposite orientation? skip
    warn "TRY: $qorient2, $score (to skip)\n"  if $D;
    $match = &$lookup_score($qorient2, $score);
    warn "SKIP (@{[scalar @$match]})\n"  if defined $match and $D;
    return []  if defined $match;

    warn "<<<< FAILED >>>>\n"  if $D;
    #no match
    return [];
}

#return a set of HSPs suitable for tiling, that are consistent with the query
#and sbjct sequence numberings.
sub get_ranked_hsps {
    my ($self, $match, $coll, $key, $qorient) = @_;

    my $tmp = $self->get_hsp_groups($match);

    return []  unless keys %$tmp;

    my $alist = $self->get_ranked_hsps_by_query($tmp, $coll, $key, $qorient);

    return $self->combine_hsps_by_centroid($alist, $qorient);
}

# #selects the first HSP: minimal, first is assumed to be the best one
# sub get_first_ranked_hsp {
#     my ($self, $match, $coll, $key, $qorient) = @_;
#     my $tmp = $self->get_hsp_groups($match);
#     my $alist = $self->get_ranked_hsps_by_query($tmp, $coll, $key, $qorient);
#     return [ $alist->[0] ]  if @$alist;
#     return $alist;
# }

# #selects all HSPs: will include out of sequence order HSPs
# sub get_all_ranked_hsps {
#     my ($self, $match, $coll, $key, $qorient) = @_;
#     my $tmp = $self->get_hsp_groups($match);
#     my $alist = $self->get_ranked_hsps_by_query($tmp, $coll, $key, $qorient);
#     return $alist;
# }

#selects the first HSP as a seed then adds HSPs that satisfy query and sbjct
#sequence ordering constraints
sub combine_hsps_by_centroid {
    my ($self, $alist, $qorient) = @_;

    return $alist  if @$alist < 2;  #0 or 1

    my $strictly_ordered = sub {
        my ($o, $a, $b) = @_;
        return $a < $b  if $o eq '+';
        return $a > $b  if $o eq '-';
        return undef;
    };

    my $coincident = sub { $_[0] == $_[1] and $_[2] == $_[3] };

    my $lo = sub {
        my ($o, $a, $b) = @_;
        return ($a < $b ? $a : $b)  if $o eq '+';
        return ($a > $b ? $a : $b)  if $o eq '-';
        return undef;
    };

    my $hi = sub {
        my ($o, $a, $b) = @_;
        return ($a > $b ? $a : $b)  if $o eq '+';
        return ($a < $b ? $a : $b)  if $o eq '-';
        return undef;
    };

    my $query_centre = sub {
        ($_[0]->{'query_start'} + $_[0]->{'query_stop'}) / 2.0;
    };

    my $sbjct_centre = sub {
        ($_[0]->{'sbjct_start'} + $_[0]->{'sbjct_stop'}) / 2.0;
    };

    my $sort_downstream = sub {
        my ($o, $alist) = @_;

        #sort on centre position (increasing) and length (decreasing)
        my $sort = sub {
            my $av = &$query_centre($a);
            my $bv = &$query_centre($b);
            return $av <=> $bv  if $av != $bv;  #centre
            $av = abs($a->{'query_start'} - $a->{'query_stop'});
            $bv = abs($b->{'query_start'} - $b->{'query_stop'});
            return $bv <=> $av;  #length: choose larger, so flip order
        };

        my @tmp = sort $sort @$alist;
        return @tmp          if $o eq '+';  #increasing
        return reverse @tmp  if $o eq '-';  #decreasing
        return @$alist;
    };

    my $sort_upstream = sub { reverse &$sort_downstream(@_) };

    my $aln = shift @$alist;  #first element with the best score
    my ($qm, $sm) = (&$query_centre($aln), &$sbjct_centre($aln));
    my $sorient = $aln->{'sbjct_orient'};
    my @tmp = ($aln);

    #my $D = 0;
    #warn "\n"  if $D;

    #accept the first HSP then process the remainder rejecting any whose query
    #or sbjct midpoint does not extend the alignment monotonically;
    #effectively, we grow the alignment diagonally out from boxes at each end
    #of the growing chain in the 2D alignment matrix.

    #grow upstream
    foreach my $aln (&$sort_upstream($qorient, $alist)) {

        my ($aqm, $asm) = (&$query_centre($aln), &$sbjct_centre($aln));

        #warn "UP($qorient$sorient): centres $aqm .. $qm : $asm .. $sm  @{[&$strictly_ordered($qorient, $aqm, $qm)?'1':'0']} @{[&$strictly_ordered($sorient, $asm, $sm)?'1':'0']}\n"  if $D;

        next  unless
            (&$strictly_ordered($qorient, $aqm, $qm) and
             &$strictly_ordered($sorient, $asm, $sm))
            or
            &$coincident($aqm, $qm, $asm, $sm);

        ($qm, $sm) = (&$lo($qorient, $aqm, $qm), &$lo($sorient, $asm, $sm));
        #warn "up($qorient$sorient): [$aln->{'sbjct'}]\n"  if $D;
        push @tmp, $aln;
    }

    #grow downstream
    foreach my $aln (&$sort_downstream($qorient, $alist)) {

        next  if grep {$_ eq $aln} @tmp;  #seen it already

        my ($aqm, $asm) = (&$query_centre($aln), &$sbjct_centre($aln));

        #warn "DN($qorient$sorient): centres $qm .. $aqm : $sm .. $asm  @{[&$strictly_ordered($qorient, $qm, $aqm)?'1':'0']} @{[&$strictly_ordered($sorient, $sm, $asm)?'1':'0']}\n"  if $D;

        next  unless
            (&$strictly_ordered($qorient, $qm, $aqm) and
             &$strictly_ordered($sorient, $sm, $asm))
            or
            &$coincident($aqm, $qm, $asm, $sm);

        ($qm, $sm) = (&$hi($qorient, $aqm, $qm), &$hi($sorient, $asm, $sm));
        #warn "dn($qorient$sorient): [$aln->{'sbjct'}]\n"  if $D;
        push @tmp, $aln;
    }
    return \@tmp;
}

sub get_scores {
    my ($self, $alist) = @_;

    return unless @$alist;

    my ($score, $sorient) = (0,'?');

    foreach my $aln (@$alist) {
        $score = $aln->{$self->score_attr}  if
            $aln->{$self->score_attr} > $score;

        $sorient = $aln->{'sbjct_orient'}, next  if $sorient eq '?';

        if ($aln->{'sbjct_orient'} ne $sorient) {
            warn "gs: mixed up sbjct orientations\n";
        }
    }

    my $n = scalar @$alist;
    my $sig = $alist->[0]->{$self->sig_attr};

    #try to preserve original precision/format as far as possible
    if ($self->sig_attr eq 'p') {  #BLAST1 and WU-BLAST
        if ($sig !~ /e/i) {
            $sig = sprintf("%.5f", $sig);
            $sig =~ s/\.(\d{2}\d*?)0+$/.$1/;   #trailing zeros after 2dp
            $sig = "0.0"  if $sig == 0;
            $sig = "1.0"  if $sig == 1;
        }
    } else {  #BLAST2
        my $rscore = sprintf("%.0f", $score);  #bit score as integer
        if ($rscore != $score) {               #num. different? put 1dp back
            $score = sprintf("%.1f", $score);  #bit score to 1 dp
        }
    }

    ($n, $score, $sig, $sorient);
}


###########################################################################
###########################################################################
package Bio::MView::Build::Row::BLAST;

use Bio::MView::Build::Row;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row);

sub posn1 {
    my $qfm = $_[0]->{'seq'}->fromlabel1;
    my $qto = $_[0]->{'seq'}->tolabel1;
    return "$qfm:$qto";
}

sub posn2 {
    my $hfm = $_[0]->{'seq'}->fromlabel2;
    my $hto = $_[0]->{'seq'}->tolabel2;
    return "$hfm:$hto"  if defined $_[0]->num and $_[0]->num;
    return '';
}

#fragment sort, called by Row::assemble
sub sort { $_[0]->sort_best_to_worst }

# #don't sort fragments; blast lists HSPs by decreasing score, so this would be
# #good, but the mview fragment collecting algorithm called by get_ranked_hsps()
# #changes the order.
# sub sort_none {$_[0]}

# #sort fragments by (1) increasing score, (2) increasing length; used up to MView
# #version 1.58.1, but inconsistent with NO OVERWRITE policy in Sequence.pm
# sub sort_worst_to_best {
#     $_[0]->{'frag'} = [
#         sort {
#             warn "$b->[7] <=> $a->[7]\n";
#             my $c = $a->[7] <=> $b->[7];                 #compare score
#             return $c  if $c != 0;
#             return length($a->[0]) <=> length($b->[0]);  #compare length
#         } @{$_[0]->{'frag'}}
#        ];
#     $_[0];
# }

#sort fragments by (1) decreasing score, (2) decreasing length
sub sort_best_to_worst {
    $_[0]->{'frag'} = [
        sort {
            #warn "$b->[7] <=> $a->[7]\n";
            my $c = $b->[7] <=> $a->[7];                 #compare score
            return $c  if $c != 0;
            return length($b->[0]) <=> length($a->[0]);  #compare length
        } @{$_[0]->{'frag'}}
	];
    $_[0];
}

#wrapper for logical symmetry with Bio::MView::Build::Row::BLASTX
sub assemble {
    my $self = shift;
    $self->SUPER::assemble(@_);
}

###########################################################################
package Bio::MView::Build::Row::BLASTX;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLAST);

#recompute range for translated sequence
sub range {
    my $self = shift;
    my ($lo, $hi) = $self->SUPER::range;
    $self->translate_range($lo, $hi);
}

#assemble translated
sub assemble {
    my $self = shift;
    foreach my $frag (@{$self->{'frag'}}) {
        ($frag->[1], $frag->[2]) =
            $self->translate_range($frag->[1], $frag->[2]);
    }
    $self->SUPER::assemble(@_);
}


###########################################################################
1;
