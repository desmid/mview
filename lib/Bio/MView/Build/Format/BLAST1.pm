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
    return  0;   #equal within error
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

@ISA = qw(Bio::MView::Build::Row::BLAST1);

sub range {
    my $self = shift;
    my ($lo, $hi) = $self->SUPER::range;
    $self->translate_range($lo, $hi);
}

sub assemble { my $self = shift; $self->assemble_translated(@_) }


###########################################################################
package Bio::MView::Build::Row::BLAST1::tblastn;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLAST1);


###########################################################################
package Bio::MView::Build::Row::BLAST1::tblastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLAST1);

sub range {
    my $self = shift;
    my ($lo, $hi) = $self->SUPER::range;
    $self->translate_range($lo, $hi);
}

sub assemble { my $self = shift; $self->assemble_translated(@_) }


###########################################################################
###########################################################################
package Bio::MView::Build::Format::BLAST1::blastp;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::BLAST1);

sub scheduler { 'none' }

sub parse {
    my $self = shift;
    my ($match, $ranking);
    my ($rank, $use, %idx, @hit) = (0);
    
    #one query strand orientation
    return  unless defined $self->{scheduler}->next;

    #identify the query itself
    $match = $self->{'entry'}->parse(qw(HEADER));

    #extract the ranking
    $ranking = $self->{'entry'}->parse(qw(RANK));

    #empty ranking?
    return  unless defined $ranking;

    #create a query row
    push @hit, new Bio::MView::Build::Row::BLAST1::blastp
	(
	 '',                    #alignment row number
	 $match->{'query'},     #sequence identifier
	 $match->{'summary'},   #description
	 '',                    #score
	 '',                    #p-value
	 '',                    #number of HSP used
	 '+',                   #query orientation
	 '+',                   #sbjct orientation
	);
    
    #extract cumulative scores and identifiers from the ranking
    foreach $match (@{$ranking->{'hit'}}) {

	$rank++;

	#check row wanted, by rank OR identifier OR row count limit
	#OR score OR p-value
	$use = $self->use_row($rank, $rank, $match->{'id'},
                              $match->{'score'}, $match->{'p'});

	last  if $use < 0;
	next  if $use < 1;

	#warn "KEEP: ($rank,$match->{'id'})\n";

	push @hit, new Bio::MView::Build::Row::BLAST1::blastp
	    (
	     $rank,
	     $match->{'id'},
	     $match->{'summary'},
	     $match->{'score'},
	     $match->{'p'},
	     $match->{'n'},
	     '+',                   #query orientation
	     '+',                   #sbjct orientation
	    );

	$idx{$match->{'id'}}                 = $#hit;
	$idx{$match->{'n'} . $match->{'id'}} = $#hit;
    }

    if ($self->{'hsp'} eq 'all') {
	$self->parse_hits_all(\@hit, \%idx);
    } elsif ($self->{'hsp'} eq 'discrete') {
	$self->parse_hits_discrete(\@hit, \%idx);
    } else {
	$self->parse_hits_ranked(\@hit, \%idx);
    }
    
    #now remove the unoccupied Rows with unused subject reading frames
    $self->discard_empty_ranges(\@hit);

    #free objects
    $self->{'entry'}->free(qw(HEADER RANK MATCH));

    #map { $_->print } @hit;

    return \@hit;
}

sub parse_hits_all {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln);

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));
	
	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	my ($n, $score, $p) = (0, 0, 1);

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'score'}, $aln->{'p'});
	    
	    #accumulate row data
	    $score = $aln->{'score'} if $aln->{'score'} > $score;
	    $p     = $aln->{'p'}     if $aln->{'p'}     < $p;
	    $n++;

	    #for WashU blast2 gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $hit->[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 0,
		 0,
		 1,
		);

	    $hit->[$idx->{$sum->{'id'}}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		 $aln->{'score'},
		);
	}

	#override row data
	$hit->[$idx->{$sum->{'id'}}]->set_val('score', $score);
	$hit->[$idx->{$sum->{'id'}}]->set_val('p', $p);
	$hit->[$idx->{$sum->{'id'}}]->set_val('n', $n);
    }
    $self;
}

sub parse_hits_ranked {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key);

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));
	
	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    $key = $aln->{'n'} . $sum->{'id'};

	    #ignore unranked fragments
	    next  unless exists $idx->{$key};

	    #ignore higher p-value than ranked
	    next  unless $self->compare_p($aln->{'p'},
			 $hit->[$idx->{$sum->{'id'}}]->get_val('p'), 2) < 1;

	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'score'}, $aln->{'p'});
	    
	    #for WashU blast2 gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $hit->[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 0,
		 0,
		 1,
		);

	    $hit->[$idx->{$sum->{'id'}}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		 $aln->{'score'},
		);
	}
	#override row data
        $hit->[$idx->{$sum->{'id'}}]->{'desc'} = $sum->{'desc'};
    }
    $self;
}

sub parse_hits_discrete {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key);

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));
	
	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	foreach $aln ($match->parse(qw(ALN))) {

	    $key = $match->{'index'} . '.' . $aln->{'index'};

	    #apply row filter with new row numbers
	    next  unless $self->use_row($match->{'index'}, $key, $sum->{'id'},
					$aln->{'score'}, $aln->{'p'});

	    if (! exists $idx->{$key}) {

		push @$hit, new Bio::MView::Build::Row::BLAST1::blastp
		    (
		     $key,
		     $sum->{'id'},
		     $sum->{'desc'},
		     $aln->{'score'},
		     $aln->{'p'},
		     $aln->{'n'},
		     '+',                   #query orientation
		     '+',                   #sbjct orientation
		    );

		$idx->{$key} = $#$hit;
	    }

	    #for WashU blast2 gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});
	    
	    $hit->[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 0,
		 0,
		 1,
		);

	    $hit->[$idx->{$key}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		 $aln->{'score'},
		);
	}
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
    my ($match, $ranking);
    my ($rank, $use, %idx, @hit) = (0);
    
    #two query strand orientations
    return  unless defined $self->{scheduler}->next;

    #identify the query itself
    $match = $self->{'entry'}->parse(qw(HEADER));

    #extract the ranking
    $ranking = $self->{'entry'}->parse(qw(RANK));

    #empty ranking?
    return  unless defined $ranking;

    push @hit, new Bio::MView::Build::Row::BLAST1::blastn
	(
	 '',                    #alignment row number
	 $match->{'query'},     #sequence identifier
	 $match->{'summary'},   #description
	 '',                    #score
	 '',                    #p-value
	 '',                    #number of HSP used
	 $self->strand,         #query orientation
	 '?',                   #sbjct orientation (none)
	);
    
    #extract cumulative scores and identifiers from the ranking
    foreach $match (@{$ranking->{'hit'}}) {

	$rank++;

	#check row wanted, by rank OR identifier OR row count limit
	#OR score OR p-value
	$use = $self->use_row($rank, $rank, $match->{'id'},
                              $match->{'score'}, $match->{'p'});

	last  if $use < 0;
	next  if $use < 1;

	#warn "KEEP: ($rank,$match->{'id'})\n";

	push @hit, new Bio::MView::Build::Row::BLAST1::blastn
	    (
	     $rank,
	     $match->{'id'},
	     $match->{'summary'},
	     $match->{'score'},
	     $match->{'p'},
	     $match->{'n'},
	     $self->strand,     #query orientation
	     '?',               #sbjct orientation (still unknown)
	    );

	$idx{$match->{'id'}}                 = $#hit;
	$idx{$match->{'n'} . $match->{'id'}} = $#hit;
    }

    if ($self->{'hsp'} eq 'all') {
	$self->parse_hits_all(\@hit, \%idx);
    } elsif ($self->{'hsp'} eq 'discrete') {
	$self->parse_hits_discrete(\@hit, \%idx);
    } else {
	$self->parse_hits_ranked(\@hit, \%idx);
    }

    #remove Rows with unused subject reading frames
    $self->discard_empty_ranges(\@hit);

    #free objects
    $self->{'entry'}->free(qw(HEADER RANK MATCH));

    #map { $_->print } @hit;

    return \@hit;
}

sub parse_hits_all {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key, $rank, $orient);

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	my ($n1,$n2, $score1,$score2, $p1,$p2) = (0,0,  0,0, 1,1);

	foreach $aln ($match->parse(qw(ALN))) {

	    #ignore other query strand orientation
	    next  unless $aln->{'query_orient'} eq $self->strand;

	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'score'}, $aln->{'p'});
	    
	    $orient = substr($aln->{'sbjct_orient'}, 0, 1);
	    $rank   = $match->{'index'} . '.' . $aln->{'index'};
	    $key    = $idx->{$sum->{'id'}} . '.' . $orient;

	    if (! exists $idx->{$key}) {
		
		push @$hit, new Bio::MView::Build::Row::BLAST1::blastn
		    (
		     $rank,
		     $sum->{'id'},
		     $sum->{'desc'},
		     $aln->{'score'},
		     $aln->{'p'},
		     $aln->{'n'},
		     $self->strand,         #query orientation
		     $orient,               #sbjct orientation
		    );

		$idx->{$key} = $#$hit;
	    }

	    #accumulate row data
	    if ($orient eq '+') {
		$score1 = $aln->{'score'} if $aln->{'score'} > $score1;
		$p1     = $aln->{'p'}     if $aln->{'p'}     < $p1;
		$n1++;
	    } else {
		$score2 = $aln->{'score'} if $aln->{'score'} > $score2;
		$p2     = $aln->{'p'}     if $aln->{'p'}     < $p2;
		$n2++;
	    }

	    #for WashU blast2 gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $hit->[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 0,
		 0,
		 1,
		);

	    $hit->[$idx->{$key}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		 $aln->{'score'},
		);
	}

	#override row data (hit + orientation)
	$key = $idx->{$sum->{'id'}} . '.+';
	if (exists $idx->{$key}) {
	    $hit->[$idx->{$key}]->set_val('score', $score1);
	    $hit->[$idx->{$key}]->set_val('p', $p1);
	    $hit->[$idx->{$key}]->set_val('n', $n1);
	}
	#override row data (hit - orientation)
	$key = $idx->{$sum->{'id'}} . '.-';
	if (exists $idx->{$key}) {
	    $hit->[$idx->{$key}]->set_val('score', $score2);
	    $hit->[$idx->{$key}]->set_val('p', $p2);
	    $hit->[$idx->{$key}]->set_val('n', $n2);
	}
    }
    $self;
}

sub parse_hits_ranked {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key, $orient, @tmp);

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	#we don't know which hit orientation was chosen for the ranking
	#since BLASTN neglects to tell us. it is conceivable that two sets 
	#of hits in each orientation could have the same frag 'n' count.
	#gather both, then decide which the ranking refers to.
	@tmp = (); foreach $aln ($match->parse(qw(ALN))) {
	    
	    #ignore other query strand orientation
	    next  unless $aln->{'query_orient'} eq $self->strand;

	    #ignore unranked fragments
	    $key = $aln->{'n'} . $sum->{'id'};
	    next  unless exists $idx->{$key};

	    push @tmp, $aln;
	}
	next  unless @tmp;

	#define sbjct strand orientation by looking for an HSP with the
	#same frag count N (already satisfied) and the same p-value.
	$orient = '?'; foreach $aln (@tmp) {
	    if ($self->compare_p($aln->{'p'},
		$hit->[$idx->{$sum->{'id'}}]->get_val('p'), 2) >= 0) {
		$orient = $aln->{'sbjct_orient'};
		last;
	    }
	}

	foreach $aln (@tmp) {

	    #ignore other subjct orientation
	    next  unless $aln->{'sbjct_orient'} eq $orient;

	    #ignore higher p-value than ranked
	    next  unless $self->compare_p($aln->{'p'},
			 $hit->[$idx->{$sum->{'id'}}]->get_val('p'), 2) < 1;

	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'score'}, $aln->{'p'});

	    #for WashU blast2 gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $hit->[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 0,
		 0,
		 1,
		);

	    $hit->[$idx->{$sum->{'id'}}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		 $aln->{'score'},
		);
	}
	#override row data
        $hit->[$idx->{$sum->{'id'}}]->{'desc'} = $sum->{'desc'};
	$hit->[$idx->{$sum->{'id'}}]->set_val('sbjct_orient', $orient);
    }
    $self;
}

sub parse_hits_discrete {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key);

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};
	
	foreach $aln ($match->parse(qw(ALN))) {

	    #ignore other query strand orientation
	    next  unless $aln->{'query_orient'} eq $self->strand;

	    $key = $match->{'index'} . '.' . $aln->{'index'};

	    #apply row filter with new row numbers
	    next  unless $self->use_row($match->{'index'}, $key, $sum->{'id'},
					$aln->{'score'}, $aln->{'p'});
	    
	    if (! exists $idx->{$key}) {
		
		push @$hit, new Bio::MView::Build::Row::BLAST1::blastn
		    (
		     $key,
		     $sum->{'id'},
		     $sum->{'desc'},
		     $aln->{'score'},
		     $aln->{'p'},
		     $aln->{'n'},
		     $self->strand,             #query orientation
		     $aln->{'sbjct_orient'},    #sbjct orientation
		    );

		$idx->{$key} = $#$hit;
	    }

	    #for WashU blast2 gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $hit->[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 0,
		 0,
		 1,
		);

	    $hit->[$idx->{$key}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		 $aln->{'score'},
		);
	}
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
    my ($match, $ranking);
    my ($rank, $use, %idx, @hit) = (0);
    
    #two query strand orientations
    return  unless defined $self->{scheduler}->next;

    #identify the query itself
    $match = $self->{'entry'}->parse(qw(HEADER));

    #extract the ranking
    $ranking = $self->{'entry'}->parse(qw(RANK));

    #empty ranking?
    return  unless defined $ranking;

    push @hit, new Bio::MView::Build::Row::BLAST1::blastx
	(
	 '',                    #alignment row number
	 $match->{'query'},     #sequence identifier
	 $match->{'summary'},   #description
	 '',                    #score
	 '',                    #p-value
	 '',                    #number of HSP used
	 $self->strand,         #query orientation
	 '+',                   #sbjct orientation
	);

    #extract cumulative scores and identifiers from the ranking
    foreach $match (@{$ranking->{'hit'}}) {

	$rank++;

	#check row wanted, by rank OR identifier OR row count limit
	#OR score OR p-value
	$use = $self->use_row($rank, $rank, $match->{'id'},
                              $match->{'score'}, $match->{'p'});

	last  if $use < 0;
	next  if $use < 1;

	#warn "KEEP: ($rank,$match->{'id'})\n";

	push @hit, new Bio::MView::Build::Row::BLAST1::blastx
	    (
	     $rank,
	     $match->{'id'},
	     $match->{'summary'},
	     $match->{'score'},
	     $match->{'p'},
	     $match->{'n'},
	     (
	      ($match->{'query_frame'} =~ /^[+-]/) ?
	      $match->{'query_frame'} : $self->strand
	     ),                       #query orientation
	     '+',                     #sbjct orientation
	    );

	$idx{$match->{'id'}}                 = $#hit;
	$idx{$match->{'n'} . $match->{'id'}} = $#hit;
    }

    if ($self->{'hsp'} eq 'all') {
	$self->parse_hits_all(\@hit, \%idx);
    } elsif ($self->{'hsp'} eq 'discrete') {
	$self->parse_hits_discrete(\@hit, \%idx);
    } else {
	$self->parse_hits_ranked(\@hit, \%idx);
    }
    
    #now remove the unoccupied Rows with unused subject reading frames
    $self->discard_empty_ranges(\@hit);

    #free objects
    $self->{'entry'}->free(qw(HEADER RANK MATCH));

    #map { $_->print } @hit;

    return \@hit;
}

sub parse_hits_all {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln);

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};
	
	my ($n, $score, $p) = (0, 0, 1);

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    #ignore other query strand orientation
	    next  unless index($aln->{'query_frame'}, $self->strand) > -1;

	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'score'}, $aln->{'p'});
	    
	    #accumulate row data
	    $score = $aln->{'score'} if $aln->{'score'} > $score;
	    $p     = $aln->{'p'}     if $aln->{'p'}     < $p;
	    $n++;

	    #for WashU blast2 gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $hit->[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 0,
		 0,
		 1,
		 $aln->{'query_frame'},    #unused
		);

	    $hit->[$idx->{$sum->{'id'}}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		 $aln->{'score'},
		 $aln->{'query_frame'},    #unused
		);
	}

	#override row data
	$hit->[$idx->{$sum->{'id'}}]->set_val('score', $score);
	$hit->[$idx->{$sum->{'id'}}]->set_val('p', $p);
	$hit->[$idx->{$sum->{'id'}}]->set_val('n', $n);
	$hit->[$idx->{$sum->{'id'}}]->set_val('query_orient', $self->strand);
    }
    $self;
}

sub parse_hits_ranked {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key);

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    #process by query orientation
	    next  unless index($aln->{'query_frame'}, $self->strand) > -1;

	    $key = $aln->{'n'} . $sum->{'id'};

	    #ignore unranked fragments
	    next  unless exists $idx->{$key};

	    #ignore higher p-value than ranked
	    next  unless $self->compare_p($aln->{'p'},
			 $hit->[$idx->{$sum->{'id'}}]->get_val('p'), 2) < 1;

	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'score'}, $aln->{'p'});

	    #for WashU blast2 gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $hit->[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 0,
		 0,
		 1,
		 $aln->{'query_frame'},    #unused
		);

	    $hit->[$idx->{$sum->{'id'}}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		 $aln->{'score'},
		 $aln->{'query_frame'},    #unused
		);
	}
	#override row data
        $hit->[$idx->{$sum->{'id'}}]->{'desc'} = $sum->{'desc'};
    }
    $self;
}
    
sub parse_hits_discrete {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key);

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    #process by query orientation
	    next  unless index($aln->{'query_frame'}, $self->strand) > -1;

	    $key = $match->{'index'} . '.' . $aln->{'index'};

	    #apply row filter with new row numbers
	    next  unless $self->use_row($match->{'index'}, $key, $sum->{'id'},
					$aln->{'score'}, $aln->{'p'});

	    if (! exists $idx->{$key}) {

		push @$hit, new Bio::MView::Build::Row::BLAST1::blastx
		    (
		     $key,
		     $sum->{'id'},
		     $sum->{'desc'},
		     $aln->{'score'},
		     $aln->{'p'},
		     $aln->{'n'},
		     (
		      exists $aln->{'query_frame'} ?
		      $aln->{'query_frame'} : $self->strand
		     ),                     #query orientation
		     '+',                   #sbjct orientation
		    );

		$idx->{$key} = $#$hit;
	    }

	    #for WashU blast2 gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $hit->[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 0,
		 0,
		 1,
		 $aln->{'query_frame'},    #unused
		);

	    $hit->[$idx->{$key}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		 $aln->{'score'},
		 $aln->{'query_frame'},    #unused
		);
	}
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
    my ($match, $ranking);
    my ($rank, $use, %idx, @hit) = (0);
    
    #one query strand orientation
    return  unless defined $self->{scheduler}->next;

    #identify the query itself
    $match = $self->{'entry'}->parse(qw(HEADER));

    #extract the ranking
    $ranking = $self->{'entry'}->parse(qw(RANK));

    #empty ranking?
    return  unless defined $ranking;

    push @hit, new Bio::MView::Build::Row::BLAST1::tblastn
	(
	 '',                    #alignment row number
	 $match->{'query'},     #sequence identifier
	 $match->{'summary'},   #description
	 '',                    #score
	 '',                    #p-value
	 '',                    #number of HSP used
	 '+',                   #query orientation
	 '?',                   #sbjct orientation (none)
	);
    
    #extract cumulative scores and identifiers from the ranking
    foreach $match (@{$ranking->{'hit'}}) {

	$rank++;

	#check row wanted, by rank OR identifier OR row count limit
	#OR score OR p-value
	$use = $self->use_row($rank, $rank, $match->{'id'},
                              $match->{'score'}, $match->{'p'});

	last  if $use < 0;
	next  if $use < 1;

	#warn "KEEP: ($rank,$match->{'id'})\n";

	push @hit, new Bio::MView::Build::Row::BLAST1::tblastn
	    (
	     $rank,
	     $match->{'id'},
	     $match->{'summary'},
	     $match->{'score'},
	     $match->{'p'},
	     $match->{'n'},
	     '+',                     #query orientation
	     $match->{'sbjct_frame'}, #sbjct orientation
	    );
	
	$idx{$match->{'id'}}                 = $#hit;
	$idx{$match->{'n'} . $match->{'id'}} = $#hit;
    }

    if ($self->{'hsp'} eq 'all') {
	$self->parse_hits_all(\@hit, \%idx);
    } elsif ($self->{'hsp'} eq 'discrete') {
	$self->parse_hits_discrete(\@hit, \%idx);
    } else {
	$self->parse_hits_ranked(\@hit, \%idx);
    }
    
    #now remove the unoccupied Rows with unused subject reading frames
    $self->discard_empty_ranges(\@hit);

    #free objects
    $self->{'entry'}->free(qw(HEADER RANK MATCH));

    #map { $_->print } @hit;

    return \@hit;
}

sub parse_hits_all {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key, $rank, $orient);

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	my ($n1,$n2, $score1,$score2, $p1,$p2) = (0,0,  0,0, 1,1);

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'score'}, $aln->{'p'});
	    
	    $orient = substr($aln->{'sbjct_frame'}, 0, 1);
	    $rank   = $match->{'index'} . '.' . $aln->{'index'};
	    $key    = $idx->{$sum->{'id'}} . '.' . $orient;

	    if (! exists $idx->{$key}) {
		
		push @$hit, new Bio::MView::Build::Row::BLAST1::tblastn
		    (
		     $rank,
		     $sum->{'id'},
		     $sum->{'desc'},
		     $aln->{'score'},
		     $aln->{'p'},
		     $aln->{'n'},
		     '+',                   #query orientation
		     $orient,               #sbjct orientation
		    );

		$idx->{$key} = $#$hit;
	    }

	    #accumulate row data
	    if ($orient eq '+') {
		$score1 = $aln->{'score'} if $aln->{'score'} > $score1;
		$p1     = $aln->{'p'}     if $aln->{'p'}     < $p1;
		$n1++;
	    } else {
		$score2 = $aln->{'score'} if $aln->{'score'} > $score2;
		$p2     = $aln->{'p'}     if $aln->{'p'}     < $p2;
		$n2++;
	    }

	    #for WashU blast2 gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $hit->[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 0,
		 0,
		 1,
		 '+',                      #unused
		);

	    $hit->[$idx->{$key}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		 $aln->{'score'},
		 $aln->{'sbjct_frame'},    #unused
		);
	}

	#override row data (hit + orientation)
	$key = $idx->{$sum->{'id'}} . '.+';
	if (exists $idx->{$key}) {
	    $hit->[$idx->{$key}]->set_val('score', $score1);
	    $hit->[$idx->{$key}]->set_val('p', $p1);
	    $hit->[$idx->{$key}]->set_val('n', $n1);
	}
	#override row data (hit 1 orientation)
	$key = $idx->{$sum->{'id'}} . '.-';
	if (exists $idx->{$key}) {
	    $hit->[$idx->{$key}]->set_val('score', $score2);
	    $hit->[$idx->{$key}]->set_val('p', $p2);
	    $hit->[$idx->{$key}]->set_val('n', $n2);
	}
    }
    $self;
}

sub parse_hits_ranked {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key);

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    #ignore different hit frame to ranking
	    next  unless $aln->{'sbjct_frame'} eq 
		$hit->[$idx->{$sum->{'id'}}]->get_val('sbjct_orient');

	    $key = $aln->{'n'} . $sum->{'id'};
	    
	    #ignore unranked fragments
	    next  unless exists $idx->{$key};
	    
	    #ignore higher p-value than ranked
	    next  unless $self->compare_p($aln->{'p'},
			 $hit->[$idx->{$sum->{'id'}}]->get_val('p'), 2) < 1;

	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'score'}, $aln->{'p'});

	    #for WashU blast2 gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $hit->[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 0,
		 0,
		 1,
		 '+',                      #unused
		);

	    $hit->[$idx->{$sum->{'id'}}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		 $aln->{'score'},
		 $aln->{'sbjct_frame'},    #unused
		);
	}
	#override row data
        $hit->[$idx->{$sum->{'id'}}]->{'desc'} = $sum->{'desc'};
    }
    $self;
}

sub parse_hits_discrete {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key);

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    $key = $match->{'index'} . '.' . $aln->{'index'};

	    #apply row filter with new row numbers
	    next  unless $self->use_row($match->{'index'}, $key, $sum->{'id'},
					$aln->{'score'}, $aln->{'p'});
	    
	    if (! exists $idx->{$key}) {
		
		push @$hit, new Bio::MView::Build::Row::BLAST1::tblastn
		    (
		     $key,
		     $sum->{'id'},
		     $sum->{'desc'},
		     $aln->{'score'},
		     $aln->{'p'},
		     $aln->{'n'},
		     '+',                   #query orientation
		     (
		      exists $aln->{'sbjct_frame'} ?
		      $aln->{'sbjct_frame'} : $aln->{'sbjct_orient'}
		     ),                     #sbjct orientation
		    );

		$idx->{$key} = $#$hit;
	    }

	    #for WashU blast2 gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $hit->[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 0,
		 0,
		 1,
		 '+',                      #unused
		);

	    $hit->[$idx->{$key}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		 $aln->{'score'},
		 $aln->{'sbjct_frame'},    #unused
		);
	}
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
    my ($match, $ranking);
    my ($rank, $use, %idx, @hit) = (0);
    
    #two query strand orientations
    return  unless defined $self->{scheduler}->next;

    #identify the query itself
    $match = $self->{'entry'}->parse(qw(HEADER));

    #extract the ranking
    $ranking = $self->{'entry'}->parse(qw(RANK));

    #empty ranking?
    return  unless defined $ranking;

    push @hit, new Bio::MView::Build::Row::BLAST1::tblastx
	(
	 '',                    #alignment row number
	 $match->{'query'},     #sequence identifier
	 $match->{'summary'},   #description
	 '',                    #score
	 '',                    #p-value
	 '',                    #number of HSP used
	 $self->strand,         #query orientation
	 '?',                   #sbjct orientation (none)
	);
    
    #extract cumulative scores and identifiers from the ranking
    foreach $match (@{$ranking->{'hit'}}) {

	$rank++;

	#check row wanted, by rank OR identifier OR row count limit
	#OR score OR p-value
	$use = $self->use_row($rank, $rank, $match->{'id'},
                              $match->{'score'}, $match->{'p'});

	last  if $use < 0;
	next  if $use < 1;

	#warn "KEEP: ($rank,$match->{'id'})\n";

	push @hit, new Bio::MView::Build::Row::BLAST1::tblastx
	    (
	     $rank,
	     $match->{'id'},
	     $match->{'summary'},
	     $match->{'score'},
	     $match->{'p'},
	     $match->{'n'},
	     $self->strand,           #query orientation
	     $match->{'sbjct_frame'}, #sbjct orientation
	    );
	
	$idx{$match->{'id'}}                 = $#hit;
	$idx{$match->{'n'} . $match->{'id'}} = $#hit;
    }

    if ($self->{'hsp'} eq 'all') {
	$self->parse_hits_all(\@hit, \%idx);
    } elsif ($self->{'hsp'} eq 'discrete') {
	$self->parse_hits_discrete(\@hit, \%idx);
    } else {
	$self->parse_hits_ranked(\@hit, \%idx);
    }
    
    #now remove the unoccupied Rows with unused subject reading frames
    $self->discard_empty_ranges(\@hit);

    #free objects
    $self->{'entry'}->free(qw(HEADER RANK MATCH));

    #map { $_->print } @hit;

    return \@hit;
}

sub parse_hits_all {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key, $rank, $orient);

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	my ($n1,$n2, $score1,$score2, $p1,$p2) = (0,0,  0,0, 1,1);

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    #process by query orientation
	    next  unless index($aln->{'query_frame'}, $self->strand) > -1;

	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'score'}, $aln->{'p'});
	    
	    $orient = substr($aln->{'sbjct_frame'}, 0, 1);
	    $rank   = $match->{'index'} . '.' . $aln->{'index'};
	    $key    = $idx->{$sum->{'id'}} . '.' . $orient;

	    if (! exists $idx->{$key}) {
		
		push @$hit, new Bio::MView::Build::Row::BLAST1::tblastx
		    (
		     $rank,
		     $sum->{'id'},
		     $sum->{'desc'},
		     $aln->{'score'},
		     $aln->{'p'},
		     $aln->{'n'},
		     $self->strand,         #query orientation
		     $orient,               #sbjct orientation
		    );

		$idx->{$key} = $#$hit;
	    }

	    #accumulate row data
	    if ($orient eq '+') {
		$score1 = $aln->{'score'} if $aln->{'score'} > $score1;
		$p1     = $aln->{'p'}     if $aln->{'p'}     < $p1;
		$n1++;
	    } else {
		$score2 = $aln->{'score'} if $aln->{'score'} > $score2;
		$p2     = $aln->{'p'}     if $aln->{'p'}     < $p2;
		$n2++;
	    }

	    #for WashU blast2 gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $hit->[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 0,
		 0,
		 1,
		 $aln->{'query_frame'},    #unused
		);

	    $hit->[$idx->{$key}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		 $aln->{'score'},
		 $aln->{'sbjct_frame'},    #unused
		);
	    
	}

	#override row data (hit + orientation)
	$key = $idx->{$sum->{'id'}} . '.+';
	if (exists $idx->{$key}) {
	    $hit->[$idx->{$key}]->set_val('score', $score1);
	    $hit->[$idx->{$key}]->set_val('p', $p1);
	    $hit->[$idx->{$key}]->set_val('n', $n1);
	}
	#override row data (hit - orientation)
	$key = $idx->{$sum->{'id'}} . '.-';
	if (exists $idx->{$key}) {
	    $hit->[$idx->{$key}]->set_val('score', $score2);
	    $hit->[$idx->{$key}]->set_val('p', $p2);
	    $hit->[$idx->{$key}]->set_val('n', $n2);
	}
    }
    $self;
}

sub parse_hits_ranked {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key);

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    #process by query orientation
	    next  unless index($aln->{'query_frame'}, $self->strand) > -1;

	    #ignore different hit frame to ranking
	    next  unless $aln->{'sbjct_frame'} eq 
		$hit->[$idx->{$sum->{'id'}}]->get_val('sbjct_orient');

	    $key = $aln->{'n'} . $sum->{'id'};

	    #ignore unranked fragments
	    next  unless exists $idx->{$key};
	    
	    #ignore higher p-value than ranked
	    next  unless $self->compare_p($aln->{'p'},
			 $hit->[$idx->{$sum->{'id'}}]->get_val('p'), 2) < 1;

	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'score'}, $aln->{'p'});

	    #for WashU blast2 gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $hit->[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 0,
		 0,
		 1,
		 $aln->{'query_frame'},    #unused
		);

	    $hit->[$idx->{$sum->{'id'}}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		 $aln->{'score'},
		 $aln->{'sbjct_frame'},    #unused
		);
	}
	#override row data
        $hit->[$idx->{$sum->{'id'}}]->{'desc'} = $sum->{'desc'};
    }
    $self;
}

sub parse_hits_discrete {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key);

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    #process by query orientation
	    next  unless index($aln->{'query_frame'}, $self->strand) > -1;

	    $key = $match->{'index'} . '.' . $aln->{'index'};

	    #apply row filter with new row numbers
	    next  unless $self->use_row($match->{'index'}, $key, $sum->{'id'},
					$aln->{'score'}, $aln->{'p'});
	    
	    if (! exists $idx->{$key}) {
		
		push @$hit, new Bio::MView::Build::Row::BLAST1::tblastx
		    (
		     $key,
		     $sum->{'id'},
		     $sum->{'desc'},
		     $aln->{'score'},
		     $aln->{'p'},
		     $aln->{'n'},
		     (
		      exists $aln->{'query_frame'} ?
		      $aln->{'query_frame'} : $self->strand
		     ),                     #query orientation
		     (
		      exists $aln->{'sbjct_frame'} ?
		      $aln->{'sbjct_frame'} : $aln->{'sbjct_orient'}
		     ),                     #sbjct orientation
		    );

		$idx->{$key} = $#$hit;
	    }

	    #for WashU blast2 gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'});

	    $hit->[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 0,
		 0,
		 1,
		 $aln->{'query_frame'},    #unused
		);

	    $hit->[$idx->{$key}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		 $aln->{'score'},
		 $aln->{'sbjct_frame'},    #unused
		);
	}
    }
    $self;
}


###########################################################################
1;
