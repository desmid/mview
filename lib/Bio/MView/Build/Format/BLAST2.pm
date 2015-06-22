# Copyright (C) 1997-2015 Nigel P. Brown
# $Id: BLAST2.pm,v 1.17 2015/06/14 17:09:04 npb Exp $

###########################################################################
#
# NCBI BLAST 2.0, PSI-BLAST 2.0
#
#   blastp, blastn, blastx, tblastn, tblastx
#
###########################################################################
package Bio::MView::Build::Format::BLAST2;

use Bio::MView::Build::Format::BLAST;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::BLAST);

#row filter
sub use_row {
    my ($self, $rank, $nid, $sid, $bits, $eval) = @_;
    my $use = $self->SUPER::use_row($rank, $nid, $sid);
    $use = $self->use_hsp($bits, $eval)  if $use == 1;
    #warn "BLAST2::use_row($rank, $nid, $sid, $bits, $eval) = $use\n";
    return $use;
}

#bits/E-value filter
sub use_hsp {
    my ($self, $bits, $eval) = @_;
    return 0  if defined $self->{'maxeval'}  and $eval  > $self->{'maxeval'};
    return 0  if defined $self->{'minbits'} and $bits < $self->{'minbits'};
    return 1;
}

#Can be extended like BLAST1::compare_p() if BLAST2 shows same difference
#of rounding problem for e-values in the ranking and alignment sections as
#BLAST1 shows for p-values.
sub compare_e {
    shift; my ($h, $r, $dp) = @_;
    return $h <=> $r;
}

#'bits' in ranking is subject to rounding to nearest integer: direction of
#rounding when delta == 0.5 is unimportant in this comparison.
sub compare_bits {
    shift; my ($h, $r) = @_;
    if ($h < $r) {
	return -1    if $r - $h > 0.5;
    } elsif ($h > $r) {
	return  1    if $h - $r > 0.5;
    }
    return 0;
}


###########################################################################
package Bio::MView::Build::Row::BLAST2;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLAST);

#suppress cycle in all output; it's only for blastp/psi-blastp
sub schema {[
    # use? rdb?  key              label         format   default
    [ 0,   0,    'cycle',         'cycle',      '2N',      ''  ],
    [ 2,   2,    'bits',          'bits',       '5N',      ''  ],
    [ 3,   3,    'expect',        'E-value',    '9S',      ''  ],
    [ 4,   4,    'n',             'N',          '2N',      ''  ],
    [ 5,   5,    'query_orient',  'qy',         '2S',      '?' ],
    [ 6,   6,    'sbjct_orient',  'ht',         '2S',      '?' ],
    ]
}


###########################################################################
package Bio::MView::Build::Row::BLAST2::blastp;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLAST2);

#enable cycle in rdb tabulated output
#suppress query and sbjct orientations for blastp data
sub schema {[
    # use? rdb?  key              label         format   default
    [ 0,   1,    'cycle',         'cycle',      '2N',      ''  ],
    [ 2,   2,    'bits',          'bits',       '5N',      ''  ],
    [ 3,   3,    'expect',        'E-value',    '9S',      ''  ],
    [ 4,   4,    'n',             'N',          '2N',      ''  ],
    [ 0,   0,    'query_orient',  'qy',         '2S',      '?' ],
    [ 0,   0,    'sbjct_orient',  'ht',         '2S',      '?' ],
    ]
}


###########################################################################
package Bio::MView::Build::Row::BLAST2::blastn;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLAST2);


###########################################################################
package Bio::MView::Build::Row::BLAST2::blastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLASTX);

sub schema { Bio::MView::Build::Row::BLAST2::schema }


###########################################################################
package Bio::MView::Build::Row::BLAST2::tblastn;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLAST2);


###########################################################################
package Bio::MView::Build::Row::BLAST2::tblastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLASTX);

sub schema { Bio::MView::Build::Row::BLAST2::schema }


###########################################################################
###########################################################################
package Bio::MView::Build::Format::BLAST2::blastp;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::BLAST2);

sub scheduler { 'cycle' }

sub subheader {
    my ($self, $quiet) = (@_, 0);
    my $s = '';
    return $s  if $quiet;
    $s  = $self->SUPER::subheader($quiet);
    $s .= "Search cycle: " . $self->cycle . "\n";
    $s;
}

sub parse {
    my $self = shift;

    #all cycles done?
    return  unless defined $self->{scheduler}->next;

    $self->{'cycle_ptr'} = $self->{'entry'}->parse("SEARCH[@{[$self->cycle]}]");

    #search doesn't exist?
    return  unless defined $self->{'cycle_ptr'};

    #identify the query
    my $header = $self->{'entry'}->parse(qw(HEADER));

    #extract the ranking
    my $ranking = $self->{'cycle_ptr'}->parse(qw(RANK));

    #empty ranking?
    return  unless defined $ranking;

    my $coll = new Bio::MView::Build::Search::Collector($self);

    $coll->insert(new Bio::MView::Build::Row::BLAST2::blastp(
                      '',                    #alignment row number
                      $header->{'query'},    #sequence identifier
                      $header->{'summary'},  #description
                      $self->cycle,          #cycle
                      '',                    #bits
                      '',                    #expectation
                      '',                    #number of HSP used
                      '+',                   #query orientation
                      '+',                   #sbjct orientation
                  ));

    #extract hits and identifiers from the ranking
    my $rank = 0; foreach my $hit (@{$ranking->{'hit'}}) {

	$rank++;

	#check row wanted, by num OR identifier OR row count limit
	#OR bits OR expect
	my $use = $self->use_row($rank, $rank, $hit->{'id'},
                                 $hit->{'bits'}, $hit->{'expect'});
	last  if $use < 0;
	next  if $use < 1;

	#warn "KEEP: ($rank,$hit->{'id'})\n";

        my $key1 = $coll->key($hit->{'id'});

	$coll->insert(new Bio::MView::Build::Row::BLAST2::blastp(
                          $rank,
                          $hit->{'id'},
                          $hit->{'summary'},
                          $self->cycle,
                          $hit->{'bits'},
                          $hit->{'expect'},
                          1,
                          '+',  #query orientation
                          '+',  #sbjct orientation
                      ),
                      $key1
            );
    }

    $self->parse_blastp_hits_all($coll)       if $self->{'hsp'} eq 'all';
    $self->parse_blastp_hits_ranked($coll)    if $self->{'hsp'} eq 'ranked';
    $self->parse_blastp_hits_discrete($coll)  if $self->{'hsp'} eq 'discrete';

    #free objects
    $self->{'entry'}->free(qw(SEARCH));

    return $coll->list;
}

sub parse_blastp_hits_all {
    my ($self, $coll) = @_;

    #pull out each hit
    foreach my $match ($self->{'cycle_ptr'}->parse(qw(MATCH))) {

	#first the summary
	my $sum = $match->parse(qw(SUM));

        my $key1 = $coll->key($sum->{'id'});

	#ignore hit?
	next  unless $coll->has($key1);

	my ($n, $score, $e) = (0, 0, -1);

	foreach my $aln ($match->parse(qw(ALN))) {

	    #apply score/E-value filter
	    next  unless $self->use_hsp($aln->{'bits'}, $aln->{'expect'});

	    #accumulate row data
	    $score = $aln->{'bits'}    if $aln->{'bits'}   > $score;
	    $e     = $aln->{'expect'}  if $aln->{'expect'} < $e or $e < 0;
	    $n++;

	    #for gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

            $coll->add_frags(
                $key1, $aln->{'query_start'}, $aln->{'query_stop'}, [
                    $aln->{'query'},
                    $aln->{'query_start'},
                    $aln->{'query_stop'},
                    1,
                ], [
                    $aln->{'sbjct'},
                    $aln->{'sbjct_start'},
                    $aln->{'sbjct_stop'},
                    $aln->{'bits'},
                ]);
	}
	#override row data
        $coll->item($key1)->{'desc'} = $sum->{'desc'};
	$coll->item($key1)->set_val('bits', $score);
	$coll->item($key1)->set_val('expect', $e);
	$coll->item($key1)->set_val('n', $n);
    }
    $self;
}

sub parse_blastp_hits_ranked {
    my ($self, $coll) = @_;

    #pull out each hit
    foreach my $match ($self->{'cycle_ptr'}->parse(qw(MATCH))) {

	#first the summary
	my $sum = $match->parse(qw(SUM));

        my $key1 = $coll->key($sum->{'id'});

	#ignore hit?
	next  unless $coll->has($key1);

	foreach my $aln ($match->parse(qw(ALN))) {

	    #ignore more than one fragment: assumes first was best
	    last  unless $coll->item($key1)->count_frag < 1;

	    #ignore higher e-value than ranked
	    next  unless $self->compare_e($aln->{'expect'},
		  $coll->item($key1)->get_val('expect'), 2) < 1;

	    #ignore lower score than ranked
	    next  unless $self->compare_bits($aln->{'bits'},
                  $coll->item($key1)->get_val('bits'), 2) >= 0;

	    #apply score/E-value filter
	    next  unless $self->use_hsp($aln->{'bits'}, $aln->{'expect'});

	    #for gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

            $coll->add_frags(
                $key1, $aln->{'query_start'}, $aln->{'query_stop'}, [
                    $aln->{'query'},
                    $aln->{'query_start'},
                    $aln->{'query_stop'},
                    1,
                ], [
                    $aln->{'sbjct'},
                    $aln->{'sbjct_start'},
                    $aln->{'sbjct_stop'},
                    $aln->{'bits'},
                ]);
	}
	#override row data
	$coll->item($key1)->{'desc'} = $sum->{'desc'};
    }
    $self;
}

sub parse_blastp_hits_discrete {
    my ($self, $coll) = @_;

    #pull out each hit
    foreach my $match ($self->{'cycle_ptr'}->parse(qw(MATCH))) {

	#first the summary
	my $sum = $match->parse(qw(SUM));

        my $key1 = $coll->key($sum->{'id'});

	#ignore hit?
	next  unless $coll->has($key1);

	foreach my $aln ($match->parse(qw(ALN))) {

            my $key2 = $coll->key($match->{'index'}, $aln->{'index'});

	    #apply row filter with new row numbers
	    next  unless $self->use_row($match->{'index'}, $key2, $sum->{'id'},
					$aln->{'bits'}, $aln->{'expect'});

	    if (! $coll->has($key2)) {

                $coll->insert(new Bio::MView::Build::Row::BLAST2::blastp(
                                  $key2,
                                  $sum->{'id'},
                                  $sum->{'desc'},
                                  $self->cycle,
                                  $aln->{'bits'},
                                  $aln->{'expect'},
                                  $aln->{'n'},
                                  '+',  #query orientation
                                  '+',  #sbjct orientation
                                  ),
                              $key2
                    );
	    }

	    #for gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

            $coll->add_frags(
                $key2, $aln->{'query_start'}, $aln->{'query_stop'}, [
                    $aln->{'query'},
                    $aln->{'query_start'},
                    $aln->{'query_stop'},
                    1,
                ], [
                    $aln->{'sbjct'},
                    $aln->{'sbjct_start'},
                    $aln->{'sbjct_stop'},
                    $aln->{'bits'},
                ]);
	}
	#override row data
        $coll->item($key1)->{'desc'} = $sum->{'desc'};
    }
    $self;
}


###########################################################################
package Bio::MView::Build::Format::BLAST2::blastn;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::BLAST2);

sub scheduler { 'strand' }

sub subheader {
    my ($self, $quiet) = (@_, 0);
    my $s = '';
    return $s  if $quiet;
    $s  = $self->SUPER::subheader($quiet);
    $s .= "Query orientation: " . $self->strand . "\n";
    $s;
}

sub parse {
    my $self = shift;

    #all strands done?
    return  unless defined $self->{scheduler}->next;

    $self->{'cycle_ptr'} = $self->{'entry'}->parse("SEARCH[@{[$self->cycle]}]");

    #search doesn't exist?
    return  unless defined $self->{'cycle_ptr'};

    #identify the query
    my $header = $self->{'entry'}->parse(qw(HEADER));

    #extract the ranking
    my $ranking = $self->{'cycle_ptr'}->parse(qw(RANK));

    #empty ranking?
    return  unless defined $ranking;

    my $coll = new Bio::MView::Build::Search::Collector($self);

    $coll->insert(new Bio::MView::Build::Row::BLAST2::blastn(
                      '',                    #alignment row number
                      $header->{'query'},    #sequence identifier
                      $header->{'summary'},  #description
                      $self->cycle,          #cycle
                      '',                    #bits
                      '',                    #expectation
                      '',                    #number of HSP used
                      $self->strand,         #query orientation
                      '?',                   #sbjct orientation (none)
                  ));

    #extract hits and identifiers from the ranking
    my $rank = 0; foreach my $hit (@{$ranking->{'hit'}}) {

	$rank++;

	#check row wanted, by num OR identifier OR row count limit
	#OR bits OR expect
	my $use = $self->use_row($rank, $rank, $hit->{'id'},
                                 $hit->{'bits'}, $hit->{'expect'});
	last  if $use < 0;
	next  if $use < 1;

	#warn "KEEP: ($rank,$hit->{'id'})\n";

        my $key1 = $coll->key($hit->{'id'});

        $coll->insert(new Bio::MView::Build::Row::BLAST2::blastn(
                          $rank,
                          $hit->{'id'},
                          $hit->{'summary'},
                          $self->cycle,
                          $hit->{'bits'},
                          $hit->{'expect'},
                          1,
                          $self->strand,  #query orientation
                          '?',            #sbjct orientation (still unknown)
                      ),
                      $key1
	    );
    }

    $self->parse_blastn_hits_all($coll)       if $self->{'hsp'} eq 'all';
    $self->parse_blastn_hits_ranked($coll)    if $self->{'hsp'} eq 'ranked';
    $self->parse_blastn_hits_discrete($coll)  if $self->{'hsp'} eq 'discrete';

    #free objects
    $self->{'entry'}->free(qw(SEARCH));

    return $coll->list;
}

sub parse_blastn_hits_all {
    my ($self, $coll) = @_;

    #pull out each hit
    foreach my $match ($self->{'cycle_ptr'}->parse(qw(MATCH))) {

	#first the summary
	my $sum = $match->parse(qw(SUM));

        my $key1 = $coll->key($sum->{'id'});

	#ignore hit?
	next  unless $coll->has($key1);

	my ($n1,$n2, $score1,$score2, $e1,$e2) = (0,0,  0,0, -1,-1);

	foreach my $aln ($match->parse(qw(ALN))) {

	    #ignore other query strand orientation
	    next  unless $aln->{'query_orient'} eq $self->strand;

	    #apply score/E-value filter
	    next  unless $self->use_hsp($aln->{'bits'}, $aln->{'expect'});

	    my $orient = substr($aln->{'sbjct_orient'}, 0, 1);
	    my $rank   = $coll->key($match->{'index'}, $aln->{'index'});

            my $key2 = $coll->key($sum->{'id'}, $orient);

	    if (! $coll->has($key2)) {

                $coll->insert(new Bio::MView::Build::Row::BLAST2::blastn(
                                  $rank,
                                  $sum->{'id'},
                                  $sum->{'desc'},
                                  $self->cycle, #cycle
                                  $aln->{'bits'},
                                  $aln->{'expect'},
                                  $aln->{'n'},
                                  $self->strand,  #query orientation
                                  $orient,        #sbjct orientation
                              ),
                              $key2
                    );
	    }

	    #accumulate row data
	    if ($orient eq '+') {
		$score1 = $aln->{'bits'}   if $aln->{'bits'}   > $score1;
		$e1     = $aln->{'expect'} if $aln->{'expect'} < $e1 or $e1 < 0;
		$n1++;
	    } else {
		$score2 = $aln->{'bits'}   if $aln->{'bits'}   > $score2;
		$e2     = $aln->{'expect'} if $aln->{'expect'} < $e2 or $e2 < 0;
		$n2++;
	    }

	    #for gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

            $coll->add_frags(
                $key2, $aln->{'query_start'}, $aln->{'query_stop'}, [
                    $aln->{'query'},
                    $aln->{'query_start'},
                    $aln->{'query_stop'},
                    1,
                ], [
                    $aln->{'sbjct'},
                    $aln->{'sbjct_start'},
                    $aln->{'sbjct_stop'},
                    $aln->{'bits'},
                ]);
	}
	#override row data
        $coll->item($key1)->{'desc'} = $sum->{'desc'};

	#override row data (hit + orientation)
	my $keyp = $coll->key($key1, '+');
	if ($coll->has($keyp)) {
	    $coll->item($keyp)->set_val('bits', $score1);
	    $coll->item($keyp)->set_val('expect', $e1);
	    $coll->item($keyp)->set_val('n', $n1);
	}
	#override row data (hit - orientation)
	my $keym = $coll->key($key1, '-');
	if ($coll->has($keym)) {
	    $coll->item($keym)->set_val('bits', $score2);
	    $coll->item($keym)->set_val('expect', $e2);
	    $coll->item($keym)->set_val('n', $n2);
	}
    }
    $self;
}

sub parse_blastn_hits_ranked {
    my ($self, $coll) = @_;

    #pull out each hit
    foreach my $match ($self->{'cycle_ptr'}->parse(qw(MATCH))) {

	#first the summary
	my $sum = $match->parse(qw(SUM));

        my $key1 = $coll->key($sum->{'id'});

	#ignore hit?
	next  unless $coll->has($key1);

	#we don't know which hit orientation was chosen for the ranking
	#since BLASTN neglects to tell us. it is conceivable that two sets
	#of hits in each orientation could have the same frag 'n' count.
	#gather both, then decide which the ranking refers to.
	my @tmp = (); foreach my $aln ($match->parse(qw(ALN))) {

	    #ignore other query strand orientation
	    next  unless $aln->{'query_orient'} eq $self->strand;

            # BLAST1 did this
            # my $key2 = $coll->key($aln->{'n'}, $sum->{'id'});

	    # #ignore unranked fragments
	    # next  unless $coll->has($key2);

	    push @tmp, $aln;
	}
	next  unless @tmp;

	#define sbjct strand orientation by looking for an HSP with the
	#same frag count N (already satisfied) and the same e-value.
	my $orient = '?'; foreach my $aln (@tmp) {
	    if ($self->compare_e($aln->{'expect'},
                $coll->item($key1)->get_val('expect'), 2) >= 0) {
		$orient = $aln->{'sbjct_orient'};
		last;
	    }
	}

	foreach my $aln (@tmp) {

	    #ignore more than one fragment: assumes first was best
	    last  unless $coll->item($key1)->count_frag < 1;

	    #ignore other subjct orientation
	    next  unless $aln->{'sbjct_orient'} eq $orient;

	    #ignore higher e-value than ranked
	    next  unless $self->compare_e($aln->{'expect'},
		  $coll->item($key1)->get_val('expect'), 2) < 1;

	    #ignore lower score than ranked
	    next  unless $self->compare_bits($aln->{'bits'},
                  $coll->item($key1)->get_val('bits'), 2) >= 0;

	    #apply score/E-value filter
	    next  unless $self->use_hsp($aln->{'bits'}, $aln->{'expect'});

	    #for gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

            $coll->add_frags(
                $key1, $aln->{'query_start'}, $aln->{'query_stop'}, [
                    $aln->{'query'},
                    $aln->{'query_start'},
                    $aln->{'query_stop'},
                    1,
                ], [
                    $aln->{'sbjct'},
                    $aln->{'sbjct_start'},
                    $aln->{'sbjct_stop'},
                    $aln->{'bits'},
                ]);
	}
	#override row data
	$coll->item($key1)->{'desc'} = $sum->{'desc'};
	$coll->item($key1)->set_val('sbjct_orient', $orient);
    }
    $self;
}

sub parse_blastn_hits_discrete {
    my ($self, $coll) = @_;

    #pull out each hit
    foreach my $match ($self->{'cycle_ptr'}->parse(qw(MATCH))) {

	#first the summary
	my $sum = $match->parse(qw(SUM));

        my $key1 = $coll->key($sum->{'id'});

	#ignore hit?
	next  unless $coll->has($key1);

	foreach my $aln ($match->parse(qw(ALN))) {

	    #ignore other query strand orientation
	    next  unless $aln->{'query_orient'} eq $self->strand;

            my $key2 = $coll->key($match->{'index'}, $aln->{'index'});

	    #apply row filter with new row numbers
	    next  unless $self->use_row($match->{'index'}, $key2, $sum->{'id'},
					$aln->{'bits'}, $aln->{'expect'});

	    if (! $coll->has($key2)) {

                $coll->insert(new Bio::MView::Build::Row::BLAST2::blastn(
                                  $key2,
                                  $sum->{'id'},
                                  $sum->{'desc'},
                                  $self->cycle,
                                  $aln->{'bits'},
                                  $aln->{'expect'},
                                  $aln->{'n'},
                                  $self->strand,           #query orientation
                                  $aln->{'sbjct_orient'},  #sbjct orientation
                              ),
                              $key2
                    );
	    }

	    #for gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

            $coll->add_frags(
                $key2, $aln->{'query_start'}, $aln->{'query_stop'}, [
                    $aln->{'query'},
                    $aln->{'query_start'},
                    $aln->{'query_stop'},
                    1,
                ], [
                    $aln->{'sbjct'},
                    $aln->{'sbjct_start'},
                    $aln->{'sbjct_stop'},
                    $aln->{'bits'},
                ]);
	}
	#override row data
        $coll->item($key1)->{'desc'} = $sum->{'desc'};
    }
    $self;
}


###########################################################################
package Bio::MView::Build::Format::BLAST2::blastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::BLAST2);

sub scheduler { 'strand' }

sub subheader {
    my ($self, $quiet) = (@_, 0);
    my $s = '';
    return $s    if $quiet;
    $s  = $self->SUPER::subheader($quiet);
    $s .= "Query orientation: " . $self->strand . "\n";
    $s;
}

sub parse {
    my $self = shift;

    #all strands done?
    return  unless defined $self->{scheduler}->next;

    $self->{'cycle_ptr'} = $self->{'entry'}->parse("SEARCH[@{[$self->cycle]}]");

    #search doesn't exist?
    return  unless defined $self->{'cycle_ptr'};

    #identify the query
    my $header = $self->{'entry'}->parse(qw(HEADER));

    #extract the ranking
    my $ranking = $self->{'cycle_ptr'}->parse(qw(RANK));

    #empty ranking?
    return  unless defined $ranking;

    my $coll = new Bio::MView::Build::Search::Collector($self);

    $coll->insert(new Bio::MView::Build::Row::BLAST2::blastx(
                      '',                    #alignment row number
                      $header->{'query'},    #sequence identifier
                      $header->{'summary'},  #description
                      $self->cycle,          #cycle
                      '',                    #bits
                      '',                    #expectation
                      '',                    #number of HSP used
                      $self->strand,         #query orientation
                      '+',                   #sbjct orientation
                  ));

    #extract hits and identifiers from the ranking
    my $rank = 0; foreach my $hit (@{$ranking->{'hit'}}) {

	$rank++;

	#check row wanted, by num OR identifier OR row count limit
	#OR bits OR expect
	my $use = $self->use_row($rank, $rank, $hit->{'id'},
                                 $hit->{'bits'}, $hit->{'expect'});
	last  if $use < 0;
	next  if $use < 1;

	#warn "KEEP: ($rank,$hit->{'id'})\n";

        my $key1 = $coll->key($hit->{'id'});

        $coll->insert(new Bio::MView::Build::Row::BLAST2::blastx(
                          $rank,
                          $hit->{'id'},
                          $hit->{'summary'},
                          $self->cycle,
                          $hit->{'bits'},
                          $hit->{'expect'},
                          1,
                          $self->strand,  #query orientation
                          '+',            #sbjct orientation
                      ),
                      $key1
            );
    }

    $self->parse_blastx_hits_all($coll)       if $self->{'hsp'} eq 'all';
    $self->parse_blastx_hits_ranked($coll)    if $self->{'hsp'} eq 'ranked';
    $self->parse_blastx_hits_discrete($coll)  if $self->{'hsp'} eq 'discrete';

    #free objects
    $self->{'entry'}->free(qw(SEARCH));

    return $coll->list;
}

sub parse_blastx_hits_all {
    my ($self, $coll) = @_;

    #pull out each hit
    foreach my $match ($self->{'cycle_ptr'}->parse(qw(MATCH))) {

	#first the summary
	my $sum = $match->parse(qw(SUM));

        my $key1 = $coll->key($sum->{'id'});

	#ignore hit?
	next  unless $coll->has($key1);

	my ($n, $score, $e) = (0, 0, -1);

	foreach my $aln ($match->parse(qw(ALN))) {

	    #ignore other query strand orientation
	    next  unless $aln->{'query_orient'} eq $self->strand;

	    #apply score/E-value filter
	    next  unless $self->use_hsp($aln->{'bits'}, $aln->{'expect'});

	    #accumulate row data
	    $score = $aln->{'bits'}    if $aln->{'bits'}   > $score;
	    $e     = $aln->{'expect'}  if $aln->{'expect'} < $e or $e < 0;
	    $n++;

	    #for gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

            $coll->add_frags(
                $key1, $aln->{'query_start'}, $aln->{'query_stop'}, [
                    $aln->{'query'},
                    $aln->{'query_start'},
                    $aln->{'query_stop'},
                    1,
                    $aln->{'query_orient'},  #unused
                ], [
                    $aln->{'sbjct'},
                    $aln->{'sbjct_start'},
                    $aln->{'sbjct_stop'},
                    $aln->{'bits'},
                    $aln->{'query_orient'},  #unused
                ]);
	}
	#override row data
        $coll->item($key1)->{'desc'} = $sum->{'desc'};
	$coll->item($key1)->set_val('bits', $score);
	$coll->item($key1)->set_val('expect', $e);
	$coll->item($key1)->set_val('n', $n);
	$coll->item($key1)->set_val('query_orient', $self->strand);
    }
    $self;
}

sub parse_blastx_hits_ranked {
    my ($self, $coll) = @_;

    #pull out each hit
    foreach my $match ($self->{'cycle_ptr'}->parse(qw(MATCH))) {

	#first the summary
	my $sum = $match->parse(qw(SUM));

        my $key1 = $coll->key($sum->{'id'});

	#ignore hit?
        next  unless $coll->has($key1);

	foreach my $aln ($match->parse(qw(ALN))) {

	    #ignore more than one fragment: assumes first was best
	    last  unless $coll->item($key1)->count_frag < 1;

	    #process by query orientation
	    next  unless $aln->{'query_orient'} eq $self->strand;

	    #ignore higher e-value than ranked
	    next  unless $self->compare_e($aln->{'expect'},
                  $coll->item($key1)->get_val('expect'), 2) < 1;

	    #ignore lower score than ranked
	    next  unless $self->compare_bits($aln->{'bits'},
                  $coll->item($key1)->get_val('bits'), 2) >= 0;

	    #apply score/E-value filter
	    next  unless $self->use_hsp($aln->{'bits'}, $aln->{'expect'});

	    #for gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

            $coll->add_frags(
                $key1, $aln->{'query_start'}, $aln->{'query_stop'}, [
                    $aln->{'query'},
                    $aln->{'query_start'},
                    $aln->{'query_stop'},
                    1,
                    $aln->{'query_orient'},  #unused

                ], [
                    $aln->{'sbjct'},
                    $aln->{'sbjct_start'},
                    $aln->{'sbjct_stop'},
                    $aln->{'bits'},
                    $aln->{'query_orient'},  #unused
                ]);
	}
	#override row data
	$coll->item($key1)->{'desc'} = $sum->{'desc'};
    }
    $self;
}

sub parse_blastx_hits_discrete {
    my ($self, $coll) = @_;

    #pull out each hit
    foreach my $match ($self->{'cycle_ptr'}->parse(qw(MATCH))) {

	#first the summary
	my $sum = $match->parse(qw(SUM));

        my $key1 = $coll->key($sum->{'id'});

	#ignore hit?
	next  unless $coll->has($key1);

	foreach my $aln ($match->parse(qw(ALN))) {

	    #process by query orientation
	    next  unless $aln->{'query_orient'} eq $self->strand;

            my $key2 = $coll->key($match->{'index'}, $aln->{'index'});

	    #apply row filter with new row numbers
	    next  unless $self->use_row($match->{'index'}, $key2, $sum->{'id'},
					$aln->{'bits'}, $aln->{'expect'});

	    if (! $coll->has($key2)) {

                $coll->insert(new Bio::MView::Build::Row::BLAST2::blastx(
                                  $key2,
                                  $sum->{'id'},
                                  $sum->{'desc'},
                                  $self->cycle,
                                  $aln->{'bits'},
                                  $aln->{'expect'},
                                  $aln->{'n'},
                                  (
                                   exists $aln->{'query_frame'} ?
                                   $aln->{'query_frame'} : $self->strand
                                  ),    #query orientation
                                  '+',  #sbjct orientation
                              ),
                              $key2
                    );
	    }

	    #for gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

            $coll->add_frags(
                $key2, $aln->{'query_start'}, $aln->{'query_stop'}, [
                    $aln->{'query'},
                    $aln->{'query_start'},
                    $aln->{'query_stop'},
                    1,
                    $aln->{'query_orient'},  #unused
                ], [
                    $aln->{'sbjct'},
                    $aln->{'sbjct_start'},
                    $aln->{'sbjct_stop'},
                    $aln->{'bits'},
                    $aln->{'query_orient'},  #unused
                ]);
	}
	#override row data
        $coll->item($key1)->{'desc'} = $sum->{'desc'};
    }
    $self;
}


###########################################################################
package Bio::MView::Build::Format::BLAST2::tblastn;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::BLAST2);

sub scheduler { 'none' }

sub parse {
    my $self = shift;

    #all done?
    return  unless defined $self->{scheduler}->next;

    $self->{'cycle_ptr'} = $self->{'entry'}->parse("SEARCH[@{[$self->cycle]}]");

    #search doesn't exist?
    return  unless defined $self->{'cycle_ptr'};

    #identify the query
    my $header = $self->{'entry'}->parse(qw(HEADER));

    #extract the ranking
    my $ranking = $self->{'cycle_ptr'}->parse(qw(RANK));

    #empty ranking?
    return  unless defined $ranking;

    my $coll = new Bio::MView::Build::Search::Collector($self);

    $coll->insert(new Bio::MView::Build::Row::BLAST2::tblastn(
                      '',                    #alignment row number
                      $header->{'query'},    #sequence identifier
                      $header->{'summary'},  #description
                      $self->cycle,          #cycle
                      '',                    #bits
                      '',                    #expectation
                      '',                    #number of HSP used
                      '+',                   #query orientation
                      '?',                   #sbjct orientation (none)
                  ));

    #extract hits and identifiers from the ranking
    my $rank = 0; foreach my $hit (@{$ranking->{'hit'}}) {

	$rank++;

	#check row wanted, by num OR identifier OR row count limit
	#OR bits OR expect
	my $use = $self->use_row($rank, $rank, $hit->{'id'},
                                 $hit->{'bits'}, $hit->{'expect'});
	last  if $use < 0;
	next  if $use < 1;

	#warn "KEEP: ($rank,$hit->{'id'})\n";

        my $key1 = $coll->key($hit->{'id'});

	$coll->insert(new Bio::MView::Build::Row::BLAST2::tblastn(
                          $rank,
                          $hit->{'id'},
                          $hit->{'summary'},
                          $self->cycle,
                          $hit->{'bits'},
                          $hit->{'expect'},
                          1,
                          '+',  #query orientation
                          '?',  #sbjct orientation (unknown)
                      ),
                      $key1
            );
    }

    $self->parse_tblastn_hits_all($coll)       if $self->{'hsp'} eq 'all';
    $self->parse_tblastn_hits_ranked($coll)    if $self->{'hsp'} eq 'ranked';
    $self->parse_tblastn_hits_discrete($coll)  if $self->{'hsp'} eq 'discrete';

    #free objects
    $self->{'entry'}->free(qw(SEARCH));

    return $coll->list;
}

sub parse_tblastn_hits_all {
    my ($self, $coll) = @_;

    #pull out each hit
    foreach my $match ($self->{'cycle_ptr'}->parse(qw(MATCH))) {

	#first the summary
	my $sum = $match->parse(qw(SUM));

        my $key1 = $coll->key($sum->{'id'});

	#ignore hit?
	next  unless $coll->has($key1);

	my ($n1,$n2, $score1,$score2, $e1,$e2) = (0,0,  0,0, -1,-1);

	foreach my $aln ($match->parse(qw(ALN))) {

	    #apply score/E-value filter
	    next  unless $self->use_hsp($aln->{'bits'}, $aln->{'expect'});

	    my $orient = substr($aln->{'sbjct_orient'}, 0, 1);
	    my $rank   = $coll->key($match->{'index'}, $aln->{'index'});

            my $key2 = $coll->key($sum->{'id'}, $orient);

            if (! $coll->has($key2)) {

		$coll->insert(new Bio::MView::Build::Row::BLAST2::tblastn(
                                  $rank,
                                  $sum->{'id'},
                                  $sum->{'desc'},
                                  $self->cycle,
                                  $aln->{'bits'},
                                  $aln->{'expect'},
                                  $aln->{'n'},
                                  '+',      #query orientation
                                  $orient,  #sbjct orientation
                              ),
                              $key2
                    );
	    }

	    #accumulate row data
	    if ($orient eq '+') {
		$score1 = $aln->{'bits'}   if $aln->{'bits'}   > $score1;
		$e1     = $aln->{'expect'} if $aln->{'expect'} < $e1 or $e1 < 0;
		$n1++;
	    } else {
		$score2 = $aln->{'bits'}   if $aln->{'bits'}   > $score2;
		$e2     = $aln->{'expect'} if $aln->{'expect'} < $e2 or $e2 < 0;
		$n2++;
	    }

	    #for gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

            $coll->add_frags(
                $key2, $aln->{'query_start'}, $aln->{'query_stop'}, [
                    $aln->{'query'},
                    $aln->{'query_start'},
                    $aln->{'query_stop'},
                    1,
                    '+',                     #unused
                ], [
                    $aln->{'sbjct'},
                    $aln->{'sbjct_start'},
                    $aln->{'sbjct_stop'},
                    $aln->{'bits'},
                    $aln->{'sbjct_orient'},  #unused
                ]);
	}
	#override row data
        $coll->item($key1)->{'desc'} = $sum->{'desc'};

	#override row data (hit + orientation)
	my $keyp = $coll->key($key1, '+');
	if ($coll->has($keyp)) {
	    $coll->item($keyp)->set_val('bits', $score1);
	    $coll->item($keyp)->set_val('expect', $e1);
	    $coll->item($keyp)->set_val('n', $n1);
	}
	#override row data (hit - orientation)
	my $keym = $coll->key($key1, '-');
	if ($coll->has($keym)) {
	    $coll->item($keym)->set_val('bits', $score2);
	    $coll->item($keym)->set_val('expect', $e2);
	    $coll->item($keym)->set_val('n', $n2);
	}
    }
    $self;
}

sub parse_tblastn_hits_ranked {
    my ($self, $coll) = @_;

    #pull out each hit
    foreach my $match ($self->{'cycle_ptr'}->parse(qw(MATCH))) {

	#first the summary
	my $sum = $match->parse(qw(SUM));

        my $key1 = $coll->key($sum->{'id'});

	#ignore hit?
        next  unless $coll->has($key1);

	#we don't know which hit orientation was chosen for the ranking since
        #TBLASTN neglects to tell us: gather all fragments before choosing.
	my @tmp = (); foreach my $aln ($match->parse(qw(ALN))) {
	    push @tmp, $aln;
	}
	next  unless @tmp;

	#define sbjct strand orientation by looking for an HSP with the
	#same frag count N (already satisfied) and the same e-value.
	my $orient = '?'; foreach my $aln (@tmp) {
	    if ($self->compare_e($aln->{'expect'},
                $coll->item($key1)->get_val('expect'), 2) >= 0) {
		$orient = $aln->{'sbjct_orient'};
		last;
	    }
	}

	foreach my $aln (@tmp) {

	    #ignore more than one fragment: assumes first was best
	    last  unless $coll->item($key1)->count_frag < 1;

	    #ignore different hit orientation to ranking
	    next  unless $aln->{'sbjct_orient'} eq $orient;

	    #ignore higher e-value than ranked
	    next  unless $self->compare_e($aln->{'expect'},
                  $coll->item($key1)->get_val('expect'), 2) < 1;

	    #ignore lower score than ranked
	    next  unless $self->compare_bits($aln->{'bits'},
                  $coll->item($key1)->get_val('bits'), 2) >= 0;

	    #apply score/E-value filter
	    next  unless $self->use_hsp($aln->{'bits'}, $aln->{'expect'});

	    #for gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

            $coll->add_frags(
                $key1, $aln->{'query_start'}, $aln->{'query_stop'}, [
                    $aln->{'query'},
                    $aln->{'query_start'},
                    $aln->{'query_stop'},
                    1,
                    '+',                     #unused
                ], [
                    $aln->{'sbjct'},
                    $aln->{'sbjct_start'},
                    $aln->{'sbjct_stop'},
                    $aln->{'bits'},
                    $aln->{'sbjct_orient'},  #unused
                ]);
	}
	#override row data (hit + orientation)
	$coll->item($key1)->{'desc'} = $sum->{'desc'};
	$coll->item($key1)->set_val('sbjct_orient', $orient);
    }
    $self;
}

sub parse_tblastn_hits_discrete {
    my ($self, $coll) = @_;

    #pull out each hit
    foreach my $match ($self->{'cycle_ptr'}->parse(qw(MATCH))) {

	#first the summary
	my $sum = $match->parse(qw(SUM));

        my $key1 = $coll->key($sum->{'id'});

	#ignore hit?
	next  unless $coll->has($key1);

	foreach my $aln ($match->parse(qw(ALN))) {

            my $key2 = $coll->key($match->{'index'}, $aln->{'index'});

	    #apply row filter with new row numbers
	    next  unless $self->use_row($match->{'index'}, $key2, $sum->{'id'},
					$aln->{'bits'}, $aln->{'expect'});

	    if (! $coll->has($key2)) {

		$coll->insert(new Bio::MView::Build::Row::BLAST2::tblastn(
                                  $key2,
                                  $sum->{'id'},
                                  $sum->{'desc'},
                                  $self->cycle,
                                  $aln->{'bits'},
                                  $aln->{'expect'},
                                  $aln->{'n'},
                                  '+',  #query orientation
                                  (
                                   exists $aln->{'sbjct_frame'} ?
                                   $aln->{'sbjct_frame'} :
                                   $aln->{'sbjct_orient'}
                                  ),    #sbjct orientation
                              ),
                              $key2
                    );
	    }

	    #for gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

            $coll->add_frags(
                $key2, $aln->{'query_start'}, $aln->{'query_stop'}, [
                    $aln->{'query'},
                    $aln->{'query_start'},
                    $aln->{'query_stop'},
                    1,
                    '+',                     #unused
                ], [
                    $aln->{'sbjct'},
                    $aln->{'sbjct_start'},
                    $aln->{'sbjct_stop'},
                    $aln->{'bits'},
                    $aln->{'sbjct_orient'},  #unused
                ]);
	}
	#override row data
        $coll->item($key1)->{'desc'} = $sum->{'desc'};
    }
    $self;
}


###########################################################################
package Bio::MView::Build::Format::BLAST2::tblastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::BLAST2);

sub scheduler { 'strand' }

sub subheader {
    my ($self, $quiet) = (@_, 0);
    my $s = '';
    return $s  if $quiet;
    $s  = $self->SUPER::subheader($quiet);
    $s .= "Query orientation: " . $self->strand . "\n";
    $s;
}

sub parse {
    my $self = shift;

    #all strands done?
    return  unless defined $self->{scheduler}->next;

    $self->{'cycle_ptr'} = $self->{'entry'}->parse("SEARCH[@{[$self->cycle]}]");

    #search doesn't exist?
    return  unless defined $self->{'cycle_ptr'};

    #identify the query
    my $header = $self->{'entry'}->parse(qw(HEADER));

    #extract the ranking
    my $ranking = $self->{'cycle_ptr'}->parse(qw(RANK));

    #empty ranking?
    return  unless defined $ranking;

    my $coll = new Bio::MView::Build::Search::Collector($self);

    $coll->insert(new Bio::MView::Build::Row::BLAST2::tblastx(
                      '',                    #alignment row number
                      $header->{'query'},    #sequence identifier
                      $header->{'summary'},  #description
                      $self->cycle,          #cycle
                      '',                    #bits
                      '',                    #expectation
                      '',                    #number of HSP used
                      $self->strand,         #query orientation
                      '?',                   #sbjct orientation
                  ));

    #extract hits and identifiers from the ranking
    my $rank = 0; foreach my $hit (@{$ranking->{'hit'}}) {

	$rank++;

	#check row wanted, by num OR identifier OR row count limit
	#OR bits OR expect
	my $use = $self->use_row($rank, $rank, $hit->{'id'},
                                 $hit->{'bits'}, $hit->{'expect'});
	last  if $use < 0;
	next  if $use < 1;

	#warn "KEEP: ($rank,$hit->{'id'})\n";

        my $key1 = $coll->key($hit->{'id'});

	$coll->insert(new Bio::MView::Build::Row::BLAST2::tblastx(
                          $rank,
                          $hit->{'id'},
                          $hit->{'summary'},
                          $self->cycle,
                          $hit->{'bits'},
                          $hit->{'expect'},
                          1,
                          $self->strand,  #query orientation
                          '?',            #sbjct orientation
                      ),
                      $key1
            );
    }

    $self->parse_tblastx_hits_all($coll)       if $self->{'hsp'} eq 'all';
    $self->parse_tblastx_hits_ranked($coll)    if $self->{'hsp'} eq 'ranked';
    $self->parse_tblastx_hits_discrete($coll)  if $self->{'hsp'} eq 'discrete';

    #free objects
    $self->{'entry'}->free(qw(SEARCH));

    return $coll->list;
}

sub parse_tblastx_hits_all {
    my ($self, $coll) = @_;

    #pull out each hit
    foreach my $match ($self->{'cycle_ptr'}->parse(qw(MATCH))) {

	#first the summary
	my $sum = $match->parse(qw(SUM));

        my $key1 = $coll->key($sum->{'id'});

	#ignore hit?
        next  unless $coll->has($key1);

	my ($n1,$n2, $score1,$score2, $e1,$e2) = (0,0,  0,0, -1,-1);

	foreach my $aln ($match->parse(qw(ALN))) {

	    #process by query orientation
	    next  unless $aln->{'query_orient'} eq $self->strand;

	    #apply score/E-value filter
	    next  unless $self->use_hsp($aln->{'bits'}, $aln->{'expect'});

	    my $orient = substr($aln->{'sbjct_orient'}, 0, 1);
	    my $rank   = $coll->key($match->{'index'}, $aln->{'index'});

	    my $key2 = $coll->key($sum->{'id'}, $orient);

	    if (! $coll->has($key2)) {

		$coll->insert(new Bio::MView::Build::Row::BLAST2::tblastx(
                                  $rank,
                                  $sum->{'id'},
                                  $sum->{'desc'},
                                  $self->cycle,
                                  $aln->{'bits'},
                                  $aln->{'expect'},
                                  $aln->{'n'},
                                  $self->strand,  #query orientation
                                  $orient,        #sbjct orientation
                              ),
                              $key2
                    );
	    }

	    #accumulate row data
	    if ($orient eq '+') {
		$score1 = $aln->{'bits'}   if $aln->{'bits'}   > $score1;
		$e1     = $aln->{'expect'} if $aln->{'expect'} < $e1 or $e1 < 0;
		$n1++;
	    } else {
		$score2 = $aln->{'bits'}   if $aln->{'bits'}   > $score2;
		$e2     = $aln->{'expect'} if $aln->{'expect'} < $e2 or $e2 < 0;
		$n2++;
	    }

	    #for gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

            $coll->add_frags(
                $key2, $aln->{'query_start'}, $aln->{'query_stop'}, [
                    $aln->{'query'},
                    $aln->{'query_start'},
                    $aln->{'query_stop'},
                    1,
                    $aln->{'query_orient'},  #unused
                ], [
                    $aln->{'sbjct'},
                    $aln->{'sbjct_start'},
                    $aln->{'sbjct_stop'},
                    $aln->{'bits'},
                    $aln->{'sbjct_orient'},  #unused
                ]);
	}
	#override row data
        $coll->item($key1)->{'desc'} = $sum->{'desc'};

	#override row data (hit + orientation)
	my $keyp = $coll->key($key1, '+');
	if ($coll->has($keyp)) {
	    $coll->item($keyp)->set_val('bits', $score1);
	    $coll->item($keyp)->set_val('expect', $e1);
	    $coll->item($keyp)->set_val('n', $n1);
	}
	#override row data (hit - orientation)
	my $keym = $coll->key($key1, '-');
	if ($coll->has($keym)) {
	    $coll->item($keym)->set_val('bits', $score2);
	    $coll->item($keym)->set_val('expect', $e2);
	    $coll->item($keym)->set_val('n', $n2);
	}
    }
    $self;
}

sub parse_tblastx_hits_ranked {
    my ($self, $coll) = @_;

    #pull out each hit
    foreach my $match ($self->{'cycle_ptr'}->parse(qw(MATCH))) {

	#first the summary
	my $sum = $match->parse(qw(SUM));

        my $key1 = $coll->key($sum->{'id'});

	#ignore hit?
        next  unless $coll->has($key1);

	#we don't know which hit orientation was chosen for the ranking since
        #TBLASTX neglects to tell us: gather all fragments before choosing.
	my @tmp = (); foreach my $aln ($match->parse(qw(ALN))) {
	    #ignore other query strand orientation
	    next  unless $aln->{'query_orient'} eq $self->strand;
	    push @tmp, $aln;
	}
	next  unless @tmp;

	#define sbjct strand orientation by looking for an HSP with the
	#same frag count N (already satisfied) and the same e-value.
	my $orient = '?'; foreach my $aln (@tmp) {
	    if ($self->compare_e($aln->{'expect'},
                $coll->item($key1)->get_val('expect'), 2) >= 0) {
		$orient = $aln->{'sbjct_orient'};
		last;
	    }
	}

	foreach my $aln (@tmp) {

	    #ignore more than one fragment: assumes first was best
	    last  unless $coll->item($key1)->count_frag < 1;

	    #ignore different hit orientation to ranking
	    next  unless $aln->{'sbjct_orient'} eq $orient;

	    #ignore higher e-value than ranked
	    next  unless $self->compare_e($aln->{'expect'},
                  $coll->item($key1)->get_val('expect'), 2) < 1;

	    #ignore lower score than ranked
	    next  unless $self->compare_bits($aln->{'bits'},
		  $coll->item($key1)->get_val('bits'), 2) >= 0;

	    #apply score/E-value filter
	    next  unless $self->use_hsp($aln->{'bits'}, $aln->{'expect'});

	    #for gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

            $coll->add_frags(
                $key1, $aln->{'query_start'}, $aln->{'query_stop'}, [
                    $aln->{'query'},
                    $aln->{'query_start'},
                    $aln->{'query_stop'},
                    1,
                    $aln->{'query_orient'},  #unused
                ], [
                    $aln->{'sbjct'},
                    $aln->{'sbjct_start'},
                    $aln->{'sbjct_stop'},
                    $aln->{'bits'},
                    $aln->{'sbjct_orient'},  #unused
                ]);
	}
	#override row data (hit + orientation)
	$coll->item($key1)->{'desc'} = $sum->{'desc'};
	$coll->item($key1)->set_val('sbjct_orient', $orient);
    }
    $self;
}

sub parse_tblastx_hits_discrete {
    my ($self, $coll) = @_;

    #pull out each hit
    foreach my $match ($self->{'cycle_ptr'}->parse(qw(MATCH))) {

	#first the summary
	my $sum = $match->parse(qw(SUM));

        my $key1 = $coll->key($sum->{'id'});

	#ignore hit?
	next  unless $coll->has($key1);

	foreach my $aln ($match->parse(qw(ALN))) {

	    #process by query orientation
	    next  unless $aln->{'query_orient'} eq $self->strand;

            my $key2 = $coll->key($match->{'index'}, $aln->{'index'});

	    #apply row filter with new row numbers
	    next  unless $self->use_row($match->{'index'}, $key2, $sum->{'id'},
					$aln->{'bits'}, $aln->{'expect'});

	    if (! $coll->has($key2)) {

		$coll->insert(new Bio::MView::Build::Row::BLAST2::tblastx(
                                  $key2,
                                  $sum->{'id'},
                                  $sum->{'desc'},
                                  $self->cycle,
                                  $aln->{'bits'},
                                  $aln->{'expect'},
                                  $aln->{'n'},
                                  (
                                   exists $aln->{'query_frame'} ?
                                   $aln->{'query_frame'} : $self->strand
                                  ),  #query orientation
                                  (
                                   exists $aln->{'sbjct_frame'} ?
                                   $aln->{'sbjct_frame'} :
                                   $aln->{'sbjct_orient'}
                                  ),  #sbjct orientation
                              ),
                              $key2
                    );
	    }

	    #for gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

            $coll->add_frags(
                $key2, $aln->{'query_start'}, $aln->{'query_stop'}, [
                    $aln->{'query'},
                    $aln->{'query_start'},
                    $aln->{'query_stop'},
                    1,
                    $aln->{'query_orient'},  #unused
                ], [
                    $aln->{'sbjct'},
                    $aln->{'sbjct_start'},
                    $aln->{'sbjct_stop'},
                    $aln->{'bits'},
                    $aln->{'sbjct_orient'},  #unused
                ]);
	}
        #override row data
        $coll->item($key1)->{'desc'} = $sum->{'desc'};
    }
    $self;
}


###########################################################################
1;
