# Copyright (C) 1997-2015 Nigel P. Brown
# $Id: BLAST1.pm,v 1.22 2015/06/14 17:09:04 npb Exp $

###########################################################################
#
# NCBI BLAST 1.4, WashU BLAST 2.0
#
#   blastp, blastn, blastx, tblastn, tblastx
#
###########################################################################
package Bio::MView::Build::Format::BLAST1;

use Bio::MView::Build::Format::BLAST;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::BLAST);

#row filter
sub use_row {
    my ($self, $rank, $nid, $sid, $score, $pval) = @_;
    my $use = $self->SUPER::use_row($rank, $nid, $sid);
    $use = $self->use_hsp($score, $pval)  if $use == 1;
    #warn "BLAST1::use_row($rank, $nid, $sid, $score, $pval) = $use\n";
    return $use;
}

#score/p-value filter
sub use_hsp {
    my ($self, $score, $pval) = @_;
    return 0  if defined $self->{'maxpval'}  and $pval  > $self->{'maxpval'};
    return 0  if defined $self->{'minscore'} and $score < $self->{'minscore'};
    return 1;
}

#BLAST alignments ($h) round non-scientific notation p-values to 2 decimal
#places, but the ranking ($r) reports more places than this: use this function
#to compare the two p-values, returning -1, 0, +1 as $h <=> $r. If $h and $r
#aren't in scientific notation, $h (not $r) may be rounded: treat $h == $r
#when $h > $r and the rounded difference (delta) to $dp decimal place accuracy
#is less than 0.5.
sub compare_p {
    shift; my ($h, $r, $dp) = (@_, 2);
    return $h <=> $r  if $h =~ /e/i and $r =~ /e/i;
    while ($dp--) { $h *= 10; $r *= 10 }
    my $delta = $h - $r;
    return -1  if $delta < -0.5;
    return  1  if $delta >  0.5;
    return  0;  #equal within error
}


###########################################################################
package Bio::MView::Build::Row::BLAST1;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLAST);

sub schema {[
    # use? rdb?  key              label         format   default
    [ 1,   1,    'score',         'score',      '5N',      ''  ],
    [ 2,   2,    'p',             'P(N)',       '9S',      ''  ],
    [ 3,   3,    'n',             'N',          '2N',      ''  ],
    [ 4,   4,    'query_orient',  'qy',         '2S',      '?' ],
    [ 5,   5,    'sbjct_orient',  'ht',         '2S',      '?' ],
    ]
}


###########################################################################
package Bio::MView::Build::Row::BLAST1::blastp;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLAST1);

#suppress query and sbjct orientations for blastp
sub schema {[
    # use? rdb?  key              label         format   default
    [ 1,   1,    'score',         'score',      '5N',      ''  ],
    [ 2,   2,    'p',             'P(N)',       '9S',      ''  ],
    [ 3,   3,    'n',             'N',          '2N',      ''  ],
    [ 0,   0,    'query_orient',  'qy',         '2S',      '?' ],
    [ 0,   0,    'sbjct_orient',  'ht',         '2S',      '?' ],
    ]
}


###########################################################################
package Bio::MView::Build::Row::BLAST1::blastn;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLAST1);


###########################################################################
package Bio::MView::Build::Row::BLAST1::blastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLASTX);

sub schema { Bio::MView::Build::Row::BLAST1::schema }


###########################################################################
package Bio::MView::Build::Row::BLAST1::tblastn;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLAST1);


###########################################################################
package Bio::MView::Build::Row::BLAST1::tblastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLASTX);

sub schema { Bio::MView::Build::Row::BLAST1::schema }


###########################################################################
###########################################################################
package Bio::MView::Build::Format::BLAST1::blastp;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::BLAST1);

sub scheduler { 'none' }

sub parse {
    my $self = shift;
    
    #one query orientation
    return  unless defined $self->{scheduler}->next;

    #identify the query
    my $header = $self->{'entry'}->parse(qw(HEADER));

    #extract the ranking
    my $ranking = $self->{'entry'}->parse(qw(RANK));

    #empty ranking?
    return  unless defined $ranking;

    my $coll = new Bio::MView::Build::Search::Collector($self);

    #create a query row
    $coll->insert(new Bio::MView::Build::Row::BLAST1::blastp(
                      '',                    #alignment row number
                      $header->{'query'},    #sequence identifier
                      $header->{'summary'},  #description
                      '',                    #score
                      '',                    #p-value
                      '',                    #number of HSP used
                      '+',                   #query orientation
                      '+',                   #sbjct orientation
                  ));
    
    #extract hits and identifiers from the ranking
    my $rank = 0; foreach my $hit (@{$ranking->{'hit'}}) {

	$rank++;

	#check row wanted, by rank OR identifier OR row count limit
	#OR score OR p-value
	my $use = $self->use_row($rank, $rank, $hit->{'id'},
                                 $hit->{'score'}, $hit->{'p'});
	last  if $use < 0;
	next  if $use < 1;

	#warn "KEEP: ($rank,$hit->{'id'})\n";

        my $key1 = $coll->key($hit->{'id'});
        my $key2 = $coll->key($hit->{'n'}, $hit->{'id'});

        $coll->insert(new Bio::MView::Build::Row::BLAST1::blastp(
                          $rank,
                          $hit->{'id'},
                          $hit->{'summary'},
                          $hit->{'score'},
                          $hit->{'p'},
                          $hit->{'n'},
                          '+',  #query orientation
                          '+',  #sbjct orientation
                      ),
                      $key1, $key2
            );
    }

    $self->parse_blastp_hits_all($coll)       if $self->{'hsp'} eq 'all';
    $self->parse_blastp_hits_ranked($coll)    if $self->{'hsp'} eq 'ranked';
    $self->parse_blastp_hits_discrete($coll)  if $self->{'hsp'} eq 'discrete';
    
    #free objects
    $self->{'entry'}->free(qw(HEADER RANK MATCH));

    return $coll->list;
}

sub parse_blastp_hits_all {
    my ($self, $coll) = @_;

    #pull out each hit
    foreach my $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	my $sum = $match->parse(qw(SUM));
	
        my $key1 = $coll->key($sum->{'id'});

	#ignore hit?
	next  unless $coll->has($key1);

	my ($n, $score, $p) = (0, 0, 1);

	foreach my $aln ($match->parse(qw(ALN))) {
	    
	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'score'}, $aln->{'p'});
	    
	    #accumulate row data
	    $score = $aln->{'score'}  if $aln->{'score'} > $score;
	    $p     = $aln->{'p'}      if $aln->{'p'}     < $p;
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
                    $aln->{'score'},
                ]);
	}
	#override row data
        $coll->item($key1)->{'desc'} = $sum->{'desc'};
	$coll->item($key1)->set_val('score', $score);
	$coll->item($key1)->set_val('p', $p);
	$coll->item($key1)->set_val('n', $n);
    }
    $self;
}

sub parse_blastp_hits_ranked {
    my ($self, $coll) = @_;

    #pull out each hit
    foreach my $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	my $sum = $match->parse(qw(SUM));
	
        my $key1 = $coll->key($sum->{'id'});

	#ignore hit?
	next  unless $coll->has($key1);

	foreach my $aln ($match->parse(qw(ALN))) {
	    
	    my $key2 = $coll->key($aln->{'n'}, $sum->{'id'});

	    #ignore unranked fragments
	    next  unless $coll->has($key2);

	    #ignore higher p-value than ranked
	    next  unless $self->compare_p($aln->{'p'},
			 $coll->item($key2)->get_val('p'), 2) < 1;

	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'score'}, $aln->{'p'});
	    
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
                    $aln->{'score'},
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
    foreach my $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	my $sum = $match->parse(qw(SUM));
	
        my $key1 = $coll->key($sum->{'id'});

	#ignore hit?
	next  unless $coll->has($key1);

	foreach my $aln ($match->parse(qw(ALN))) {

	    my $key2 = $coll->key($match->{'index'}, $aln->{'index'});

	    #apply row filter with new row numbers
	    next  unless $self->use_row($match->{'index'}, $key2, $sum->{'id'},
					$aln->{'score'}, $aln->{'p'});

	    if (! $coll->has($key2)) {

                $coll->insert(new Bio::MView::Build::Row::BLAST1::blastp(
                                  $key2,
                                  $sum->{'id'},
                                  $sum->{'desc'},
                                  $aln->{'score'},
                                  $aln->{'p'},
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
                    $aln->{'score'},
                ]);
	}
	#override row data
        $coll->item($key1)->{'desc'} = $sum->{'desc'};
    }
    $self;
}


###########################################################################
package Bio::MView::Build::Format::BLAST1::blastn;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::BLAST1);

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
    
    #two query orientations
    return  unless defined $self->{scheduler}->next;

    #identify the query
    my $header = $self->{'entry'}->parse(qw(HEADER));

    #extract the ranking
    my $ranking = $self->{'entry'}->parse(qw(RANK));

    #empty ranking?
    return  unless defined $ranking;

    my $coll = new Bio::MView::Build::Search::Collector($self);

    #create a query row
    $coll->insert(new Bio::MView::Build::Row::BLAST1::blastn(
                      '',                    #alignment row number
                      $header->{'query'},    #sequence identifier
                      $header->{'summary'},  #description
                      '',                    #score
                      '',                    #p-value
                      '',                    #number of HSP used
                      $self->strand,         #query orientation
                      '?',                   #sbjct orientation (none)
                  ));
    
    #extract hits and identifiers from the ranking
    my $rank = 0; foreach my $hit (@{$ranking->{'hit'}}) {

	$rank++;

	#check row wanted, by rank OR identifier OR row count limit
	#OR score OR p-value
	my $use = $self->use_row($rank, $rank, $hit->{'id'},
                                 $hit->{'score'}, $hit->{'p'});
	last  if $use < 0;
	next  if $use < 1;

	#warn "KEEP: ($rank,$hit->{'id'})\n";

        my $key1 = $coll->key($hit->{'id'});
        my $key2 = $coll->key($hit->{'n'}, $hit->{'id'});

	$coll->insert(new Bio::MView::Build::Row::BLAST1::blastn(
                          $rank,
                          $hit->{'id'},
                          $hit->{'summary'},
                          $hit->{'score'},
                          $hit->{'p'},
                          $hit->{'n'},
                          $self->strand,  #query orientation
                          '?',            #sbjct orientation (still unknown)
                      ),
                      $key1, $key2
            );
    }

    $self->parse_blastn_hits_all($coll)       if $self->{'hsp'} eq 'all';
    $self->parse_blastn_hits_ranked($coll)    if $self->{'hsp'} eq 'ranked';
    $self->parse_blastn_hits_discrete($coll)  if $self->{'hsp'} eq 'discrete';

    #free objects
    $self->{'entry'}->free(qw(HEADER RANK MATCH));

    return $coll->list;
}

sub parse_blastn_hits_all {
    my ($self, $coll) = @_;

    #pull out each hit
    foreach my $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
        my $sum = $match->parse(qw(SUM));

        my $key1 = $coll->key($sum->{'id'});

	#ignore hit?
	next  unless $coll->has($key1);

	my ($n1,$n2, $score1,$score2, $p1,$p2) = (0,0,  0,0, 1,1);

	foreach my $aln ($match->parse(qw(ALN))) {

	    #ignore other query strand orientation
	    next  unless $aln->{'query_orient'} eq $self->strand;

	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'score'}, $aln->{'p'});
	    
	    #accumulate row data
            my $orient = substr($aln->{'sbjct_orient'}, 0, 1);
	    my $rank   = $coll->key($match->{'index'}, $aln->{'index'});

	    my $key2 = $coll->key($sum->{'id'}, $orient);

	    if (! $coll->has($key2)) {

		$coll->insert(new Bio::MView::Build::Row::BLAST1::blastn(
                                  $rank,
                                  $sum->{'id'},
                                  $sum->{'desc'},
                                  $aln->{'score'},
                                  $aln->{'p'},
                                  $aln->{'n'},
                                  $self->strand,  #query orientation
                                  $orient,        #sbjct orientation
                              ),
                              $key2
                    );
            }

	    #accumulate row data
	    if ($orient eq '+') {
		$score1 = $aln->{'score'}  if $aln->{'score'} > $score1;
		$p1     = $aln->{'p'}      if $aln->{'p'}     < $p1;
		$n1++;
	    } else {
		$score2 = $aln->{'score'}  if $aln->{'score'} > $score2;
		$p2     = $aln->{'p'}      if $aln->{'p'}     < $p2;
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
                    $aln->{'score'},
                ]);
	}
	#override row data
        $coll->item($key1)->{'desc'} = $sum->{'desc'};

	#override row data (hit + orientation)
	my $keyp = $coll->key($key1, '+');
	if ($coll->has($keyp)) {
	    $coll->item($keyp)->set_val('score', $score1);
	    $coll->item($keyp)->set_val('p', $p1);
	    $coll->item($keyp)->set_val('n', $n1);
	}
	#override row data (hit - orientation)
	my $keym = $coll->key($key1, '-');
	if ($coll->has($keym)) {
	    $coll->item($keym)->set_val('score', $score2);
	    $coll->item($keym)->set_val('p', $p2);
	    $coll->item($keym)->set_val('n', $n2);
	}
    }
    $self;
}

sub parse_blastn_hits_ranked {
    my ($self, $coll) = @_;

    #pull out each hit
    foreach my $match ($self->{'entry'}->parse(qw(MATCH))) {

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

	    my $key2 = $coll->key($aln->{'n'}, $sum->{'id'});

	    #ignore unranked fragments
	    next  unless $coll->has($key2);

	    push @tmp, $aln;
	}
	next  unless @tmp;

	#define sbjct strand orientation by looking for an HSP with the
	#same frag count N (already satisfied) and the same p-value.
	my $orient = '?'; foreach my $aln (@tmp) {
	    if ($self->compare_p($aln->{'p'},
		$coll->item($key1)->get_val('p'), 2) >= 0) {
		$orient = $aln->{'sbjct_orient'};
		last;
	    }
	}

	foreach my $aln (@tmp) {

	    #ignore other subjct orientation
	    next  unless $aln->{'sbjct_orient'} eq $orient;

	    #ignore higher p-value than ranked
	    next  unless $self->compare_p($aln->{'p'},
			 $coll->item($key1)->get_val('p'), 2) < 1;

	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'score'}, $aln->{'p'});

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
                    $aln->{'score'},
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
    foreach my $match ($self->{'entry'}->parse(qw(MATCH))) {

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
					$aln->{'score'}, $aln->{'p'});
	    
	    if (! $coll->has($key2)) {
		
		$coll->insert(new Bio::MView::Build::Row::BLAST1::blastn(
                                  $key2,
                                  $sum->{'id'},
                                  $sum->{'desc'},
                                  $aln->{'score'},
                                  $aln->{'p'},
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
                    $aln->{'score'},
                ]);
	}
        #override row data
        $coll->item($key1)->{'desc'} = $sum->{'desc'};
    }
    $self;
}


###########################################################################
package Bio::MView::Build::Format::BLAST1::blastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::BLAST1);

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
    
    #two query orientations
    return  unless defined $self->{scheduler}->next;

    #identify the query
    my $header = $self->{'entry'}->parse(qw(HEADER));

    #extract the ranking
    my $ranking = $self->{'entry'}->parse(qw(RANK));

    #empty ranking?
    return  unless defined $ranking;

    my $coll = new Bio::MView::Build::Search::Collector($self);

    #create a query row
    $coll->insert(new Bio::MView::Build::Row::BLAST1::blastx(
                      '',                    #alignment row number
                      $header->{'query'},    #sequence identifier
                      $header->{'summary'},  #description
                      '',                    #score
                      '',                    #p-value
                      '',                    #number of HSP used
                      $self->strand,         #query orientation
                      '+',                   #sbjct orientation
                  ));

    #extract hits and identifiers from the ranking
    my $rank = 0; foreach my $hit (@{$ranking->{'hit'}}) {

	$rank++;

	#check row wanted, by rank OR identifier OR row count limit
	#OR score OR p-value
	my $use = $self->use_row($rank, $rank, $hit->{'id'},
                                 $hit->{'score'}, $hit->{'p'});
	last  if $use < 0;
	next  if $use < 1;

	#warn "KEEP: ($rank,$hit->{'id'})\n";

        my $key1 = $coll->key($hit->{'id'});
        my $key2 = $coll->key($hit->{'n'}, $hit->{'id'});

	$coll->insert(new Bio::MView::Build::Row::BLAST1::blastx(
                          $rank,
                          $hit->{'id'},
                          $hit->{'summary'},
                          $hit->{'score'},
                          $hit->{'p'},
                          $hit->{'n'},
                          (
                           ($hit->{'query_frame'} =~ /^[+-]/) ?
                           $hit->{'query_frame'} : $self->strand
                          ),    #query orientation
                          '+',  #sbjct orientation
                      ),
                      $key1, $key2
            );
    }

    $self->parse_blastx_hits_all($coll)       if $self->{'hsp'} eq 'all';
    $self->parse_blastx_hits_ranked($coll)    if $self->{'hsp'} eq 'ranked';
    $self->parse_blastx_hits_discrete($coll)  if $self->{'hsp'} eq 'discrete';

    #free objects
    $self->{'entry'}->free(qw(HEADER RANK MATCH));

    return $coll->list;
}

sub parse_blastx_hits_all {
    my ($self, $coll) = @_;

    #pull out each hit
    foreach my $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	my $sum = $match->parse(qw(SUM));

        my $key1 = $coll->key($sum->{'id'});

	#ignore hit?
	next  unless $coll->has($key1);
	
	my ($n, $score, $p) = (0, 0, 1);

	foreach my $aln ($match->parse(qw(ALN))) {
	    
	    #ignore other query strand orientation
	    next  unless index($aln->{'query_frame'}, $self->strand) > -1;

	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'score'}, $aln->{'p'});
	    
	    #accumulate row data
	    $score = $aln->{'score'}  if $aln->{'score'} > $score;
	    $p     = $aln->{'p'}      if $aln->{'p'}     < $p;
	    $n++;

	    #for gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $coll->add_frags(
                $key1, $aln->{'query_start'}, $aln->{'query_stop'}, [
                    $aln->{'query'},
                    $aln->{'query_start'},
                    $aln->{'query_stop'},
                    1,
                    $aln->{'query_frame'},  #unused
                ], [
                    $aln->{'sbjct'},
                    $aln->{'sbjct_start'},
                    $aln->{'sbjct_stop'},
                    $aln->{'score'},
                    $aln->{'query_frame'},  #unused
                ]);
	}
	#override row data
        $coll->item($key1)->{'desc'} = $sum->{'desc'};
	$coll->item($key1)->set_val('score', $score);
	$coll->item($key1)->set_val('p', $p);
	$coll->item($key1)->set_val('n', $n);
	$coll->item($key1)->set_val('query_orient', $self->strand);
    }
    $self;
}

sub parse_blastx_hits_ranked {
    my ($self, $coll) = @_;

    #pull out each hit
    foreach my $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	my $sum = $match->parse(qw(SUM));

        my $key1 = $coll->key($sum->{'id'});

	#ignore hit?
	next  unless $coll->has($key1);

	foreach my $aln ($match->parse(qw(ALN))) {
	    
	    #process by query orientation
	    next  unless index($aln->{'query_frame'}, $self->strand) > -1;

	    my $key2 = $coll->key($aln->{'n'}, $sum->{'id'});

	    #ignore unranked fragments
            next  unless $coll->has($key2);

	    #ignore higher p-value than ranked
	    next  unless $self->compare_p($aln->{'p'},
			 $coll->item($key1)->get_val('p'), 2) < 1;

	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'score'}, $aln->{'p'});

	    #for gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $coll->add_frags(
                $key1, $aln->{'query_start'}, $aln->{'query_stop'}, [
                    $aln->{'query'},
                    $aln->{'query_start'},
                    $aln->{'query_stop'},
                    1,
                    $aln->{'query_frame'},  #unused
                ], [
                    $aln->{'sbjct'},
                    $aln->{'sbjct_start'},
                    $aln->{'sbjct_stop'},
                    $aln->{'score'},
                    $aln->{'query_frame'},  #unused
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
    foreach my $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	my $sum = $match->parse(qw(SUM));

        my $key1 = $coll->key($sum->{'id'});

	#ignore hit?
	next  unless $coll->has($key1);

	foreach my $aln ($match->parse(qw(ALN))) {
	    
	    #process by query orientation
	    next  unless index($aln->{'query_frame'}, $self->strand) > -1;

	    my $key2 = $coll->key($match->{'index'}, $aln->{'index'});

	    #apply row filter with new row numbers
	    next  unless $self->use_row($match->{'index'}, $key2, $sum->{'id'},
					$aln->{'score'}, $aln->{'p'});

	    if (! $coll->has($key2)) {

		$coll->insert(new Bio::MView::Build::Row::BLAST1::blastx(
                                  $key2,
                                  $sum->{'id'},
                                  $sum->{'desc'},
                                  $aln->{'score'},
                                  $aln->{'p'},
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
                    $aln->{'query_frame'},  #unused
                    ], [
                    $aln->{'sbjct'},
                    $aln->{'sbjct_start'},
                    $aln->{'sbjct_stop'},
                    $aln->{'score'},
                    $aln->{'query_frame'},  #unused
                ]);
	}
        #override row data
        $coll->item($key1)->{'desc'} = $sum->{'desc'};
    }
    $self;
}


###########################################################################
package Bio::MView::Build::Format::BLAST1::tblastn;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::BLAST1);

sub scheduler { 'none' }

sub parse {
    my $self = shift;
    
    #one query orientation
    return  unless defined $self->{scheduler}->next;

    #identify the query
    my $header = $self->{'entry'}->parse(qw(HEADER));

    #extract the ranking
    my $ranking = $self->{'entry'}->parse(qw(RANK));

    #empty ranking?
    return  unless defined $ranking;

    my $coll = new Bio::MView::Build::Search::Collector($self);

    #create a query row
    $coll->insert(new Bio::MView::Build::Row::BLAST1::tblastn(
                      '',                    #alignment row number
                      $header->{'query'},    #sequence identifier
                      $header->{'summary'},  #description
                      '',                    #score
                      '',                    #p-value
                      '',                    #number of HSP used
                      '+',                   #query orientation
                      '?',                   #sbjct orientation (none)
                  ));
    
    #extract hits and identifiers from the ranking
    my $rank = 0; foreach my $hit (@{$ranking->{'hit'}}) {

	$rank++;

	#check row wanted, by rank OR identifier OR row count limit
	#OR score OR p-value
	my $use = $self->use_row($rank, $rank, $hit->{'id'},
                                 $hit->{'score'}, $hit->{'p'});
	last  if $use < 0;
	next  if $use < 1;

	#warn "KEEP: ($rank,$hit->{'id'})\n";

        my $key1 = $coll->key($hit->{'id'});
        my $key2 = $coll->key($hit->{'n'}, $hit->{'id'});

	$coll->insert(new Bio::MView::Build::Row::BLAST1::tblastn(
                          $rank,
                          $hit->{'id'},
                          $hit->{'summary'},
                          $hit->{'score'},
                          $hit->{'p'},
                          $hit->{'n'},
                          '+',                    #query orientation
                          $hit->{'sbjct_frame'},  #sbjct orientation
                      ),
                      $key1, $key2
            );
    }

    $self->parse_tblastn_hits_all($coll)       if $self->{'hsp'} eq 'all';
    $self->parse_tblastn_hits_ranked($coll)    if $self->{'hsp'} eq 'ranked';
    $self->parse_tblastn_hits_discrete($coll)  if $self->{'hsp'} eq 'discrete';
    
    #free objects
    $self->{'entry'}->free(qw(HEADER RANK MATCH));

    return $coll->list;
}

sub parse_tblastn_hits_all {
    my ($self, $coll) = @_;

    #pull out each hit
    foreach my $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	my $sum = $match->parse(qw(SUM));

        my $key1 = $coll->key($sum->{'id'});

	#ignore hit?
	next  unless $coll->has($key1);

	my ($n1,$n2, $score1,$score2, $p1,$p2) = (0,0,  0,0, 1,1);

	foreach my $aln ($match->parse(qw(ALN))) {
	    
	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'score'}, $aln->{'p'});

	    #accumulate row data
	    my $orient = substr($aln->{'sbjct_frame'}, 0, 1);
	    my $rank   = $coll->key($match->{'index'}, $aln->{'index'});

            my $key2 = $coll->key($sum->{'id'}, $orient);

	    if (! $coll->has($key2)) {

		$coll->insert(new Bio::MView::Build::Row::BLAST1::tblastn(
                                  $rank,
                                  $sum->{'id'},
                                  $sum->{'desc'},
                                  $aln->{'score'},
                                  $aln->{'p'},
                                  $aln->{'n'},
                                  '+',      #query orientation
                                  $orient,  #sbjct orientation
                              ),
                              $key2
		    );
	    }

	    #accumulate row data
	    if ($orient eq '+') {
		$score1 = $aln->{'score'}  if $aln->{'score'} > $score1;
		$p1     = $aln->{'p'}      if $aln->{'p'}     < $p1;
		$n1++;
	    } else {
		$score2 = $aln->{'score'}  if $aln->{'score'} > $score2;
		$p2     = $aln->{'p'}      if $aln->{'p'}     < $p2;
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
                    '+',                    #unused
                ], [
                    $aln->{'sbjct'},
                    $aln->{'sbjct_start'},
                    $aln->{'sbjct_stop'},
                    $aln->{'score'},
                    $aln->{'sbjct_frame'},  #unused
                ]);
	}
	#override row data
        $coll->item($key1)->{'desc'} = $sum->{'desc'};

	#override row data (hit + orientation)
	my $keyp = $coll->key($key1, '+');
	if ($coll->has($keyp)) {
	    $coll->item($keyp)->set_val('score', $score1);
	    $coll->item($keyp)->set_val('p', $p1);
	    $coll->item($keyp)->set_val('n', $n1);
	}
	#override row data (hit - orientation)
	my $keym = $coll->key($key1, '-');
	if ($coll->has($keym)) {
	    $coll->item($keym)->set_val('score', $score2);
	    $coll->item($keym)->set_val('p', $p2);
	    $coll->item($keym)->set_val('n', $n2);
	}
    }
    $self;
}

sub parse_tblastn_hits_ranked {
    my ($self, $coll) = @_;

    #pull out each hit
    foreach my $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	my $sum = $match->parse(qw(SUM));

        my $key1 = $coll->key($sum->{'id'});

	#ignore hit?
	next  unless $coll->has($key1);

	foreach my $aln ($match->parse(qw(ALN))) {
	    
	    #ignore different hit frame to ranking
	    next  unless $aln->{'sbjct_frame'} eq
		$coll->item($key1)->get_val('sbjct_orient');

	    my $key2 = $coll->key($aln->{'n'}, $sum->{'id'});

	    #ignore unranked fragments
	    next  unless $coll->has($key2);
	    
	    #ignore higher p-value than ranked
	    next  unless $self->compare_p($aln->{'p'},
			 $coll->item($key1)->get_val('p'), 2) < 1;

	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'score'}, $aln->{'p'});

	    #for gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $coll->add_frags(
                $key1, $aln->{'query_start'}, $aln->{'query_stop'}, [
                    $aln->{'query'},
                    $aln->{'query_start'},
                    $aln->{'query_stop'},
                    1,
                    '+',                    #unused
                ], [
                    $aln->{'sbjct'},
                    $aln->{'sbjct_start'},
                    $aln->{'sbjct_stop'},
                    $aln->{'score'},
                    $aln->{'sbjct_frame'},  #unused
                ]);
	}
	#override row data
        $coll->item($key1)->{'desc'} = $sum->{'desc'};
    }
    $self;
}

sub parse_tblastn_hits_discrete {
    my ($self, $coll) = @_;

    #pull out each hit
    foreach my $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	my $sum = $match->parse(qw(SUM));

        my $key1 = $coll->key($sum->{'id'});

	#ignore hit?
	next  unless $coll->has($key1);

	foreach my $aln ($match->parse(qw(ALN))) {
	    
	    my $key2 = $coll->key($match->{'index'}, $aln->{'index'});

	    #apply row filter with new row numbers
	    next  unless $self->use_row($match->{'index'}, $key2, $sum->{'id'},
					$aln->{'score'}, $aln->{'p'});
	    
	    if (! $coll->has($key2)) {
		
		$coll->insert(new Bio::MView::Build::Row::BLAST1::tblastn(
                                  $key2,
                                  $sum->{'id'},
                                  $sum->{'desc'},
                                  $aln->{'score'},
                                  $aln->{'p'},
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
                    '+',                    #unused
                ], [
                    $aln->{'sbjct'},
                    $aln->{'sbjct_start'},
                    $aln->{'sbjct_stop'},
                    $aln->{'score'},
                    $aln->{'sbjct_frame'},  #unused
                ]);
	}
        #override row data
        $coll->item($key1)->{'desc'} = $sum->{'desc'};
    }
    $self;
}


###########################################################################
package Bio::MView::Build::Format::BLAST1::tblastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::BLAST1);

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
    
    #two query orientations
    return  unless defined $self->{scheduler}->next;

    #identify the query
    my $header = $self->{'entry'}->parse(qw(HEADER));

    #extract the ranking
    my $ranking = $self->{'entry'}->parse(qw(RANK));

    #empty ranking?
    return  unless defined $ranking;

    my $coll = new Bio::MView::Build::Search::Collector($self);

    #create a query row
    $coll->insert(new Bio::MView::Build::Row::BLAST1::tblastx(
                      '',                    #alignment row number
                      $header->{'query'},    #sequence identifier
                      $header->{'summary'},  #description
                      '',                    #score
                      '',                    #p-value
                      '',                    #number of HSP used
                      $self->strand,         #query orientation
                      '?',                   #sbjct orientation (none)
                  ));
    
    #extract hits and identifiers from the ranking
    my $rank = 0; foreach my $hit (@{$ranking->{'hit'}}) {

	$rank++;

	#check row wanted, by rank OR identifier OR row count limit
	#OR score OR p-value
	my $use = $self->use_row($rank, $rank, $hit->{'id'},
                                 $hit->{'score'}, $hit->{'p'});
	last  if $use < 0;
	next  if $use < 1;

	#warn "KEEP: ($rank,$hit->{'id'})\n";

        my $key1 = $coll->key($hit->{'id'});
        my $key2 = $coll->key($hit->{'n'}, $hit->{'id'});

	$coll->insert(new Bio::MView::Build::Row::BLAST1::tblastx(
                          $rank,
                          $hit->{'id'},
                          $hit->{'summary'},
                          $hit->{'score'},
                          $hit->{'p'},
                          $hit->{'n'},
                          $self->strand,          #query orientation
                          $hit->{'sbjct_frame'},  #sbjct orientation
                      ),
                      $key1, $key2
            );
    }

    $self->parse_tblastx_hits_all($coll)       if $self->{'hsp'} eq 'all';
    $self->parse_tblastx_hits_ranked($coll)    if $self->{'hsp'} eq 'ranked';
    $self->parse_tblastx_hits_discrete($coll)  if $self->{'hsp'} eq 'discrete';

    #free objects
    $self->{'entry'}->free(qw(HEADER RANK MATCH));

    return $coll->list;
}

sub parse_tblastx_hits_all {
    my ($self, $coll) = @_;

    #pull out each hit
    foreach my $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	my $sum = $match->parse(qw(SUM));

        my $key1 = $coll->key($sum->{'id'});

	#ignore hit?
	next  unless $coll->has($key1);

	my ($n1,$n2, $score1,$score2, $p1,$p2) = (0,0,  0,0, 1,1);

	foreach my $aln ($match->parse(qw(ALN))) {
	    
	    #process by query orientation
	    next  unless index($aln->{'query_frame'}, $self->strand) > -1;

	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'score'}, $aln->{'p'});
	    
	    #accumulate row data
            my $orient = substr($aln->{'sbjct_frame'}, 0, 1);
	    my $rank   = $coll->key($match->{'index'}, $aln->{'index'});

	    my $key2 = $coll->key($sum->{'id'}, $orient);

	    if (! $coll->has($key2)) {

		$coll->insert(new Bio::MView::Build::Row::BLAST1::tblastx(
                                  $rank,
                                  $sum->{'id'},
                                  $sum->{'desc'},
                                  $aln->{'score'},
                                  $aln->{'p'},
                                  $aln->{'n'},
                                  $self->strand,  #query orientation
                                  $orient,        #sbjct orientation
                              ),
                              $key2
                    );
	    }

	    #accumulate row data
	    if ($orient eq '+') {
		$score1 = $aln->{'score'}  if $aln->{'score'} > $score1;
		$p1     = $aln->{'p'}      if $aln->{'p'}     < $p1;
		$n1++;
	    } else {
		$score2 = $aln->{'score'}  if $aln->{'score'} > $score2;
		$p2     = $aln->{'p'}      if $aln->{'p'}     < $p2;
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
                    $aln->{'query_frame'},  #unused
                ], [
                    $aln->{'sbjct'},
                    $aln->{'sbjct_start'},
                    $aln->{'sbjct_stop'},
                    $aln->{'score'},
                    $aln->{'sbjct_frame'},  #unused
                ]);
	}
	#override row data
        $coll->item($key1)->{'desc'} = $sum->{'desc'};

	#override row data (hit + orientation)
	my $keyp = $coll->key($key1, '+');
	if ($coll->has($keyp)) {
	    $coll->item($keyp)->set_val('score', $score1);
	    $coll->item($keyp)->set_val('p', $p1);
	    $coll->item($keyp)->set_val('n', $n1);
	}
	#override row data (hit - orientation)
	my $keym = $coll->key($key1, '-');
	if ($coll->has($keym)) {
	    $coll->item($keym)->set_val('score', $score2);
	    $coll->item($keym)->set_val('p', $p2);
	    $coll->item($keym)->set_val('n', $n2);
	}
    }
    $self;
}

sub parse_tblastx_hits_ranked {
    my ($self, $coll) = @_;

    #pull out each hit
    foreach my $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	my $sum = $match->parse(qw(SUM));

        my $key1 = $coll->key($sum->{'id'});

	#ignore hit?
	next  unless $coll->has($key1);

	foreach my $aln ($match->parse(qw(ALN))) {
	    
	    #process by query orientation
	    next  unless index($aln->{'query_frame'}, $self->strand) > -1;

	    #ignore different hit frame to ranking
	    next  unless $aln->{'sbjct_frame'} eq 
		$coll->item($key1)->get_val('sbjct_orient');

	    my $key2 = $coll->key($aln->{'n'}, $sum->{'id'});

	    #ignore unranked fragments
	    next  unless $coll->has($key2);
	    
	    #ignore higher p-value than ranked
	    next  unless $self->compare_p($aln->{'p'},
			 $coll->item($key1)->get_val('p'), 2) < 1;

	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'score'}, $aln->{'p'});

	    #for gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $coll->add_frags(
                $key1, $aln->{'query_start'}, $aln->{'query_stop'}, [
                    $aln->{'query'},
                    $aln->{'query_start'},
                    $aln->{'query_stop'},
                    1,
                    $aln->{'query_frame'},  #unused
                ], [
                    $aln->{'sbjct'},
                    $aln->{'sbjct_start'},
                    $aln->{'sbjct_stop'},
                    $aln->{'score'},
                    $aln->{'sbjct_frame'},  #unused
                ]);
	}
	#override row data
        $coll->item($key1)->{'desc'} = $sum->{'desc'};
    }
    $self;
}

sub parse_tblastx_hits_discrete {
    my ($self, $coll) = @_;

    #pull out each hit
    foreach my $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	my $sum = $match->parse(qw(SUM));

        my $key1 = $coll->key($sum->{'id'});

	#ignore hit?
	next  unless $coll->has($key1);

	foreach my $aln ($match->parse(qw(ALN))) {
	    
	    #process by query orientation
	    next  unless index($aln->{'query_frame'}, $self->strand) > -1;

            my $key2 = $coll->key($match->{'index'}, $aln->{'index'});

	    #apply row filter with new row numbers
	    next  unless $self->use_row($match->{'index'}, $key2, $sum->{'id'},
					$aln->{'score'}, $aln->{'p'});
	    
	    if (! $coll->has($key2)) {
		
		$coll->insert(new Bio::MView::Build::Row::BLAST1::tblastx(
                                  $key2,
                                  $sum->{'id'},
                                  $sum->{'desc'},
                                  $aln->{'score'},
                                  $aln->{'p'},
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
                    $aln->{'query_frame'},  #unused
                ], [
                    $aln->{'sbjct'},
                    $aln->{'sbjct_start'},
                    $aln->{'sbjct_stop'},
                    $aln->{'score'},
                    $aln->{'sbjct_frame'},  #unused
                ]);
	}
        #override row data
        $coll->item($key1)->{'desc'} = $sum->{'desc'};
    }
    $self;
}


###########################################################################
1;
