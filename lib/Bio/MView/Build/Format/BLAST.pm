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

#return a hash of HSP sets for the given query and query orientation; each set
#is a list of ALN with a given significance and number of fragments; these
#sets have multiple alternative keys: "sign/sig/sbjct_orient", "score",
#"rounded_score".
sub group_hsps_by_query_orient {
    my ($self, $match) = @_;
    my $hash = {};
    foreach my $aln ($match->parse(qw(ALN))) {
        my $n       = $aln->{'n'};
        my $score   = $aln->{$self->score_attr};
        my $sig     = $aln->{$self->sig_attr};
        my $qorient = $aln->{'query_orient'};
        my $sorient = $aln->{'sbjct_orient'};
        my $key;

        #key by sgnificance: can exceed $n if more HSP have the same sig
        $key = join("/", $qorient, $sorient, $n, $sig);
        push @{ $hash->{$key} }, $aln;

        #also key by N and score, but we also need to consider rounding:
        #
        #round to nearest integer, or, if X.5, round both ways; this is
        #because the scores reported in the ranking and in the hit summary are
        #themselves rounded from an unknown underlying score, so simply
        #rounding the HSP score is not enough, viz.
        #
        # underlying: 9.49 -> ranking (0dp) 9
        # underlying: 9.49 -> hit     (1dp) 9.5
        # round(9.5, 0) = 10 != 9

        my %scores = ( $score => 1 );        #raw score
        $scores{sprintf("%.0f", $score)}++;  #rounded score (0dp)
        if ($score - int($score) == 0.5) {   #edge cases +/- 0.5
            $scores{$score - 0.5}++;
            $scores{$score + 0.5}++;
        }
        foreach my $score (keys %scores) {
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

#lookup an HSP set (common N and significance value) in an HSP dictionary,
#trying various keys
sub find_hsps_by_key {
    my ($self, $hash, $coll, $rkey, $qorient) = @_;

    my $n     = $coll->item($rkey)->get_val('n'),
    my $score = $coll->item($rkey)->get_val($self->score_attr),
    my $sig   = $coll->item($rkey)->get_val($self->sig_attr);
    my $key;

    $n = 1  unless $n;  #no N in ranking

    my $D = 0;

    #match in this query orientation?
    foreach my $sorient (qw(+ -)) {
        $key = join("/", $qorient, $sorient, $n, $sig);
        return $hash->{$key}  if exists $hash->{$key};
    }

    my $qorient2 = ($qorient eq '+' ? '-' : '+');

    #match in inverted query orientation? ignore it - we're done
    foreach my $sorient (qw(+ -)) {
        $key = join("/", $qorient2, $sorient, $n, $sig);
        return []  if exists $hash->{$key};
    }

    warn "KEYS2($rkey): @{[sort keys %$hash]}\n"  if $D;
    warn "NOMATCH: $key TRY: $n $score\n"  if $D;

    #can't find it because the N is missing from the ranking:
    #  tblastn_2.0.10/2.2.6
    #or the ranking score/E-value pair don't match any HSPs together:
    #  tblastx_2.2.6

    #try N and score:

    #match in this query orientation?
    foreach my $sorient (qw(+ -)) {
        $key = join("/", $qorient, $sorient, $n, $score);
        return $hash->{$key}  if exists $hash->{$key};
    }

    #match in inverted query orientation? ignore it - we're done
    foreach my $sorient (qw(+ -)) {
        $key = join("/", $qorient2, $sorient, $n, $score);
        return []  if exists $hash->{$key};
    }

    warn "NOMATCH: $n $score TRY: $score\n"  if $D;

    #try score without the N:

    #match in this query orientation?
    foreach my $sorient (qw(+ -)) {
        $key = join("/", $qorient, $sorient, $score);

        if (exists $hash->{$key}) {

            #take the sig of the first HSP and try again
            my $list = $hash->{$key};
            $n       = $list->[0]->{'n'};
            $score   = $list->[0]->{$self->score_attr};
            my $nsig = $list->[0]->{$self->sig_attr};

            warn "TRANSFORM: $qorient $n $score $sig -> $nsig\n"  if $D;

            #match in this query orientation?
            foreach my $sorient (qw(+ -)) {
                $key = join("/", $qorient, $sorient, $n, $nsig);
                return $hash->{$key}  if exists $hash->{$key};
            }

            #match in inverted query orientation? ignore it - we're done
            foreach my $sorient (qw(+ -)) {
                $key = join("/", $qorient2, $sorient, $n, $nsig);
                return []  if exists $hash->{$key};
            }
        }
    }

    #match in inverted query orientation? ignore it - we're done
    foreach my $sorient (qw(+ -)) {
        $key = join("/", $qorient2, $sorient, $score);
        return []  if exists $hash->{$key};
    }

    warn "NOMATCH: $n $score TRY: $score\n"  if $D;
    warn ">>>> FAILED <<<\n"  if $D;
    #no match
    return [];
}

#return a set of HSPs suitable for tiling, that are consistent with the query
#and sbjct sequence numberings.
sub find_ranked_hsps { my $s=shift; $s->find_ranked_hsps_by_middles(@_) }

# #selects the first HSP: minimal, first is assumed to be the best one
# sub find_ranked_first_matching_hsp {
#     my ($self, $match, $coll, $key, $qorient) = @_;
#
#     my $tmp = $self->group_hsps_by_query_orient($match, $qorient);
#     my $alist = $self->find_hsps_by_key($tmp, $coll, $key);

#     return [ $alist->[0] ]  if @$alist;
#     return $alist;
# }

# #selects all HSPs: will include out of sequence order HSPs
# sub find_ranked_all_hsps {
#     my ($self, $match, $coll, $key, $qorient) = @_;
#
#     my $tmp = $self->group_hsps_by_query_orient($match, $qorient);
#     my $alist = $self->find_hsps_by_key($tmp, $coll, $key);
#
#     return $alist;
# }

#selects the first HSP as a seed then adds HSPs that satisfy query and sbjct
#sequence ordering constraints
sub find_ranked_hsps_by_middles {
    my ($self, $match, $coll, $key, $qorient) = @_;

    my $tmp = $self->group_hsps_by_query_orient($match);

    return []  unless keys %$tmp;

    my $alist = $self->find_hsps_by_key($tmp, $coll, $key, $qorient);

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

    my $query_middle = sub {
        ($_[0]->{'query_start'} + $_[0]->{'query_stop'}) / 2.0;
    };

    my $sbjct_middle = sub {
        ($_[0]->{'sbjct_start'} + $_[0]->{'sbjct_stop'}) / 2.0;
    };

    my $sort_downstream = sub {
        my ($o, $alist) = @_;

        #sort on middle position (increasing) and length (decreasing)
        my $sort = sub {
            my $av = &$query_middle($a);
            my $bv = &$query_middle($b);
            return $av <=> $bv  if $av != $bv;  #middle
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
    my ($qm, $sm) = (&$query_middle($aln), &$sbjct_middle($aln));
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

        my ($aqm, $asm) = (&$query_middle($aln), &$sbjct_middle($aln));

        #warn "UP($qorient$sorient): middles $aqm .. $qm : $asm .. $sm  @{[&$strictly_ordered($qorient, $aqm, $qm)?'1':'0']} @{[&$strictly_ordered($sorient, $asm, $sm)?'1':'0']}\n"  if $D;

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

        my ($aqm, $asm) = (&$query_middle($aln), &$sbjct_middle($aln));

        #warn "DN($qorient$sorient): middles $qm .. $aqm : $sm .. $asm  @{[&$strictly_ordered($qorient, $qm, $aqm)?'1':'0']} @{[&$strictly_ordered($sorient, $sm, $asm)?'1':'0']}\n"  if $D;
       
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

    my ($n, $score, $sig, $sorient) = (0,0,0,'?');

    foreach my $aln (@$alist) {
        $score = $aln->{$self->score_attr}  if
            $aln->{$self->score_attr} > $score;

        $sorient = $aln->{'sbjct_orient'}, next  if $sorient eq '?';

        if ($aln->{'sbjct_orient'} ne $sorient) {
            warn "gs: mixed up sbjct orientations\n";
        }
    }
    $n = scalar @$alist;
    $score = sprintf("%.0f", $score);  #round to nearest integer
    $sig = $alist->[0]->{'expect'};
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

#sort fragments, called by Row::assemble
sub sort { $_[0]->sort_none }

#don't sort fragments: assemble them in discovery order: this the same as
#sort_best_to_worst() because BLAST generates them already sorted
sub sort_none {$_[0]}

# #sort fragments: (1) increasing score, (2) increasing length; used up to MView
# #version 1.58.1, but inconsistent with NO OVERWRITE policy in Sequence.pm
# sub sort_worst_to_best {
#     $_[0]->{'frag'} = [
#         sort {
#             my $c = $a->[7] <=> $b->[7];                 #compare score
#             return $c  if $c != 0;
#             return length($a->[0]) <=> length($b->[0]);  #compare length
#         } @{$_[0]->{'frag'}}
#        ];
#     $_[0];
# }

# #sort fragments: (1) decreasing score, (2) decreasing length
# sub sort_best_to_worst {
#     $_[0]->{'frag'} = [
#         sort {
#             my $c = $b->[7] <=> $a->[7];                 #compare score
#             return $c  if $c != 0;
#             return length($b->[0]) <=> length($a->[0]);  #compare length
#         } @{$_[0]->{'frag'}}
# 	];
#     $_[0];
# }

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
