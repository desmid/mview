# Copyright (C) 1997-2015 Nigel P. Brown
# $Id: BLAST2.pm,v 1.16 2005/12/12 20:42:48 brown Exp $

###########################################################################
#
# NCBI BLAST 2.0, PSI-BLAST 2.0
#
#   blastp, blastn, blastx, tblastn, tblastx
#
###########################################################################
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

#bits/p-value filter
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

sub new {
    my $type = shift;
    my ($num, $id, $desc, $bits, $e, $n, $qo, $ho, $cycle) = @_;
    my $self = new Bio::MView::Build::Row($num, $id, $desc);
    $self->{'bits'}   	    = $bits;
    $self->{'expect'} 	    = $e;
    $self->{'n'}      	    = $n; 
    $self->{'query_orient'} = $qo;
    $self->{'sbjct_orient'} = $ho;
    $self->{'cycle'}        = $cycle;
    bless $self, $type;
}

sub data {
    return sprintf("%5s %9s %2s %2s %2s",
		   $_[0]->{'bits'}, $_[0]->{'expect'}, $_[0]->{'n'},
		   $_[0]->{'query_orient'}, $_[0]->{'sbjct_orient'})
	if $_[0]->num;
    return sprintf("%5s %9s %2s %2s %2s", 'bits', 'E-value', 'N', 'qy', 'ht');
}

sub rdb_info {
    my ($self, $mode) = @_;
    return ($self->{'bits'}, $self->{'expect'}, $self->{'n'},
	    $self->{'query_orient'}, $self->{'sbjct_orient'}, $self->{'cycle'})
	if $mode eq 'data';
    return ('bits', 'expect', 'N', 'query_orient', 'sbjct_orient', 'cycle')
	if $mode eq 'attr';
    return ('5N', '9S', '2N', '2S', '2S', '2N')  if $mode eq 'form';
}

sub eval { $_[0]->{'expect'} }
sub bits { $_[0]->{'bits'} }


###########################################################################
package Bio::MView::Build::Row::BLAST2::blastp;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLAST2);

sub assemble { my $self = shift; $self->assemble_blastp(@_) }

#suppress query and sbjct orientations for blastp data() method
sub data {
    return sprintf("%5s %9s %2s",
		   $_[0]->{'bits'}, $_[0]->{'expect'}, $_[0]->{'n'})
	if $_[0]->num;
    return sprintf("%5s %9s %2s", 'bits', 'E-value', 'N');
}


###########################################################################
package Bio::MView::Build::Row::BLAST2::blastn;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLAST2);

sub range {
    my $self = shift;
    $self->SUPER::range($self->{'query_orient'});
}

sub assemble { my $self = shift; $self->assemble_blastn(@_) }


###########################################################################
package Bio::MView::Build::Row::BLAST2::blastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLAST2);

#start' = int((start+2)/3); stop' = int(stop/3)
sub range {
    my $self = shift;
    my ($lo, $hi) = $self->SUPER::range($self->{'query_orient'});
    (int(($lo+2)/3), int($hi/3));
}

sub assemble { my $self = shift; $self->assemble_blastx(@_) }


###########################################################################
package Bio::MView::Build::Row::BLAST2::tblastn;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLAST2);

sub assemble { my $self = shift; $self->assemble_tblastn(@_) }


###########################################################################
package Bio::MView::Build::Row::BLAST2::tblastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLAST2);

#start' = int((start+2)/3); stop' = int(stop/3)
sub range {
    my $self = shift;
    my ($lo, $hi) = $self->SUPER::range($self->{'query_orient'});
    (int(($lo+2)/3), int($hi/3));
}

sub assemble { my $self = shift; $self->assemble_tblastx(@_) }


###########################################################################
###########################################################################
package Bio::MView::Build::Format::BLAST2::blastp;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::BLAST2);

sub subheader {
    my ($self, $quiet) = (@_, 0);
    my $s = '';
    return $s    if $quiet;
    $s  = $self->SUPER::subheader($quiet);
    $s .= "Search cycle: " . $self->cycle . "\n";
    $s;    
}

sub parse {
    my $self = shift;
    my ($match, $ranking, $sum, $aln, $key);
    my ($rank, $use, %idx, @hit) = (0);

    #all searches done?
    return unless defined $self->schedule_by_cycle;

    $self->{'cycle_ptr'} = $self->{'entry'}->parse("SEARCH[@{[$self->cycle]}]");

    #search doesn't exist?
    return unless defined $self->{'cycle_ptr'};
    
    #identify the query itself
    $match = $self->{'entry'}->parse(qw(HEADER));

    #extract the ranking
    $ranking = $self->{'cycle_ptr'}->parse(qw(RANK));

    #empty ranking?
    return unless defined $ranking; 

    push @hit, new Bio::MView::Build::Row::BLAST2::blastp
	(
	 '',                    #alignment row number
	 $match->{'query'},     #sequence identifier
	 $match->{'summary'},   #description
	 '',                    #bits
	 '',                    #expectation
	 '',                    #number of HSP used
	 '+',                   #query orientation
	 '+',                   #sbjct orientation
	 $self->cycle,          #cycle (psi-blast compatibility)
	);

    #extract hits and identifiers from the ranking
    foreach $match (@{$ranking->{'hit'}}) {

	$rank++;

	#check row wanted, by num OR identifier OR row count limit
	#OR bits OR expect
	last  if ($use = $self->use_row($rank, $rank, $match->{'id'},
					$match->{'bits'}, $match->{'expect'})
		 ) < 0;
	next  unless $use;

	#warn "KEEP: ($rank,$match->{'id'})\n";

	push @hit, new Bio::MView::Build::Row::BLAST2::blastp
	    (
	     $rank,
	     $match->{'id'},
	     $match->{'summary'},
	     $match->{'bits'},
	     $match->{'expect'},
	     1,
	     '+',                   #query orientation
	     '+',                   #sbjct orientation
	     $self->cycle,          #cycle (psi-blast compatibility)
	    );
	
	$idx{$match->{'id'}} = $#hit;
    }

    if ($self->{'hsp'} eq 'all') {
	$self->parse_hits_all(\@hit, \%idx);
    } elsif ($self->{'hsp'} eq 'discrete') {
	$self->parse_hits_discrete(\@hit, \%idx);
    } else {
	$self->parse_hits_ranked(\@hit, \%idx);
    }

    $self->discard_empty_ranges(\@hit);

    #free SEARCH object: vital for big psi-blast runs
    $self->{'entry'}->free(qw(SEARCH));

    #map { $_->print } @hit;

    return \@hit;
}

sub parse_hits_all {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln);

    #pull out each hit
    foreach $match ($self->{'cycle_ptr'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));
	
	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	my ($n, $score, $e) = (0, 0, -1);

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'bits'}, $aln->{'expect'});

	    #accumulate row data
	    $score = $aln->{'bits'}   if $aln->{'bits'}   > $score;
	    $e     = $aln->{'expect'} if $aln->{'expect'} < $e or $e < 0;
	    $n++;

	    #for gapped alignments
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
		 $aln->{'bits'},
		);
	}

	#override row data
	$hit->[$idx->{$sum->{'id'}}]->{'bits'}   = $score;
	$hit->[$idx->{$sum->{'id'}}]->{'expect'} = $e;
	$hit->[$idx->{$sum->{'id'}}]->{'n'}      = $n;
    }
    $self;
}

sub parse_hits_ranked {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key);

    #pull out each hit
    foreach $match ($self->{'cycle_ptr'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));
	
	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    #ignore more than one fragment: assumes first was best
	    last  unless $hit->[$idx->{$sum->{'id'}}]->count_frag < 1;

	    #ignore higher e-value than ranked
	    next  unless $self->compare_e($aln->{'expect'},
				      $hit->[$idx->{$sum->{'id'}}]->{'expect'},
				      2) < 1;
	    
	    #ignore lower score than ranked
	    next  unless $self->compare_bits($aln->{'bits'},
				      $hit->[$idx->{$sum->{'id'}}]->{'bits'},
				      2) >= 0;
	    
	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'bits'}, $aln->{'expect'});

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
		 $aln->{'bits'},
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
    foreach $match ($self->{'cycle_ptr'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));
	
	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    $key = $match->{'index'} . '.' . $aln->{'index'};

	    #apply row filter with new row numbers
	    next  unless $self->use_row($match->{'index'}, $key, $sum->{'id'},
					$aln->{'bits'}, $aln->{'expect'});

	    if (! exists $idx->{$key}) {
		
		push @$hit, new Bio::MView::Build::Row::BLAST2::blastp
		    (
		     $key,
		     $sum->{'id'},
		     $sum->{'desc'},
		     $aln->{'bits'},
		     $aln->{'expect'},
		     $aln->{'n'},
		     '+',                   #query orientation
		     '+',                   #sbjct orientation
		     $self->cycle,          #cycle (psi-blast compatibility)
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
		 $aln->{'bits'},
		);
	}
    }
    $self;
}


###########################################################################
package Bio::MView::Build::Format::BLAST2::blastn;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::BLAST2);

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
    my ($match, $ranking, $sum, $aln, $key);
    my ($rank, $use, %idx, @hit) = (0);

    #all searches/orientations done?
    return unless defined $self->schedule_by_cycle_and_strand;

    $self->{'cycle_ptr'} = $self->{'entry'}->parse("SEARCH[@{[$self->cycle]}]");

    #search doesn't exist?
    return unless defined $self->{'cycle_ptr'};
    
    #identify the query itself
    $match = $self->{'entry'}->parse(qw(HEADER));

    #extract the ranking
    $ranking = $self->{'cycle_ptr'}->parse(qw(RANK));

    #empty ranking?
    return unless defined $ranking; 

    push @hit, new Bio::MView::Build::Row::BLAST2::blastn
	(
	 '',                    #alignment row number
	 $match->{'query'},     #sequence identifier
	 $match->{'summary'},   #description
	 '',                    #bits
	 '',                    #expectation
	 '',                    #number of HSP used
	 $self->strand,         #query orientation
	 '?',                   #sbjct orientation (none)
	 $self->cycle,          #cycle (psi-blast compatibility)
	);
    
    #extract hits and identifiers from the ranking
    foreach $match (@{$ranking->{'hit'}}) {

	$rank++;

	#check row wanted, by num OR identifier OR row count limit
	#OR bits OR expect
	last  if ($use = $self->use_row($rank, $rank, $match->{'id'},
					$match->{'bits'}, $match->{'expect'})
		 ) < 0;
	next  unless $use;

	#warn "KEEP: ($rank,$match->{'id'})\n";

	push @hit, new Bio::MView::Build::Row::BLAST2::blastn
	    (
	     $rank,
	     $match->{'id'},
	     $match->{'summary'},
	     $match->{'bits'},
	     $match->{'expect'},
	     1,
	     $self->strand,         #query orientation
	     '?',                   #sbjct orientation (still unknown)
	     $self->cycle,          #cycle (psi-blast compatibility)
	    );

	$idx{$match->{'id'}} = $#hit;
    }

    if ($self->{'hsp'} eq 'all') {
	$self->parse_hits_all(\@hit, \%idx);
    } elsif ($self->{'hsp'} eq 'discrete') {
	$self->parse_hits_discrete(\@hit, \%idx);
    } else {
	$self->parse_hits_ranked(\@hit, \%idx);
    }

    $self->discard_empty_ranges(\@hit);

    #free SEARCH object: vital for big psi-blast runs
    $self->{'entry'}->free(qw(SEARCH));

    #map { $_->print } @hit;

    return \@hit;
}

sub parse_hits_all {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key, $rank, $orient);

    #pull out each hit
    foreach $match ($self->{'cycle_ptr'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	my ($n1,$n2, $score1,$score2, $e1,$e2) = (0,0,  0,0, -1,-1);

	foreach $aln ($match->parse(qw(ALN))) {

	    #ignore other query strand orientation
	    next  unless $aln->{'query_orient'} eq $self->strand;

	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'bits'}, $aln->{'expect'});

	    $orient = substr($aln->{'sbjct_orient'}, 0, 1);
	    $rank   = $match->{'index'} . '.' . $aln->{'index'};
	    $key    = $idx->{$sum->{'id'}} . '.' . $orient;

	    if (! exists $idx->{$key}) {
		
		push @$hit, new Bio::MView::Build::Row::BLAST2::blastn
		    (
		     $rank,
		     $sum->{'id'},
		     $sum->{'desc'},
		     $aln->{'bits'},
		     $aln->{'expect'},
		     $aln->{'n'},
		     $self->strand,         #query orientation
		     $orient,               #sbjct orientation
		     $self->cycle,          #cycle
		    );

		$idx->{$key} = $#$hit;
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
		 $aln->{'bits'},
		);
	}

	#override row data (hit + orientation)
	$key = $idx->{$sum->{'id'}} . '.+';
	if (exists $idx->{$key}) {
	    $hit->[$idx->{$key}]->{'bits'}   = $score1;
	    $hit->[$idx->{$key}]->{'expect'} = $e1;
	    $hit->[$idx->{$key}]->{'n'}      = $n1;
	}
	#override row data (hit - orientation)
	$key = $idx->{$sum->{'id'}} . '.-';
	if (exists $idx->{$key}) {
	    $hit->[$idx->{$key}]->{'bits'}   = $score2;
	    $hit->[$idx->{$key}]->{'expect'} = $e2;
	    $hit->[$idx->{$key}]->{'n'}      = $n2;
	}
    }
    $self;
}

sub parse_hits_ranked {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key, $orient, @tmp);

    #pull out each hit
    foreach $match ($self->{'cycle_ptr'}->parse(qw(MATCH))) {

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

	    push @tmp, $aln;
	}
	next  unless @tmp;

	#define sbjct strand orientation by looking for an HSP with the
	#same frag count N (already satisfied) and the same e-value.
	$orient = '?'; foreach $aln (@tmp) {
	    if ($self->compare_e($aln->{'expect'},
				 $hit->[$idx->{$sum->{'id'}}]->{'expect'},
				 2) >= 0) {
		$orient = $aln->{'sbjct_orient'};
		last;
	    }
	}

	foreach $aln (@tmp) {

	    #ignore more than one fragment: assumes first was best
	    last  unless $hit->[$idx->{$sum->{'id'}}]->count_frag < 1;

	    #ignore other subjct orientation
	    next  unless $aln->{'sbjct_orient'} eq $orient;

	    #ignore higher e-value than ranked
	    next  unless $self->compare_e($aln->{'expect'},
				      $hit->[$idx->{$sum->{'id'}}]->{'expect'},
				      2) < 1;

	    #ignore lower score than ranked
	    next  unless $self->compare_bits($aln->{'bits'},
				      $hit->[$idx->{$sum->{'id'}}]->{'bits'},
				      2) >= 0;
	    
	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'bits'}, $aln->{'expect'});

	    #for gapped alignments
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
		 $aln->{'bits'},
		);
	}
	#override row data
	$hit->[$idx->{$sum->{'id'}}]->{'sbjct_orient'} = $orient;
	$hit->[$idx->{$sum->{'id'}}]->{'desc'} = $sum->{'desc'};
    }
    $self;
}

sub parse_hits_discrete {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key);

    #pull out each hit
    foreach $match ($self->{'cycle_ptr'}->parse(qw(MATCH))) {

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
					$aln->{'bits'}, $aln->{'expect'});
	    
	    if (! exists $idx->{$key}) {
		
		push @$hit, new Bio::MView::Build::Row::BLAST2::blastn
		    (
		     $key,
		     $sum->{'id'},
		     $sum->{'desc'},
		     $aln->{'bits'},
		     $aln->{'expect'},
		     $aln->{'n'},
		     $self->strand,         #query orientation
		     $aln->{'sbjct_orient'},#sbjct orientation
		     $self->cycle,          #cycle (psi-blast compatibility)
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
		 $aln->{'bits'},
		);
	}
    }
    $self;
}


###########################################################################
package Bio::MView::Build::Format::BLAST2::blastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::BLAST2);

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
    my ($match, $ranking, $sum, $aln, $key);
    my ($rank, $use, %idx, @hit) = (0);
    
    #all strands done?
    return     unless defined $self->schedule_by_cycle_and_strand;

    $self->{'cycle_ptr'} = $self->{'entry'}->parse("SEARCH[@{[$self->cycle]}]");

    #search doesn't exist?
    return unless defined $self->{'cycle_ptr'};
    
    #identify the query itself
    $match = $self->{'entry'}->parse(qw(HEADER));

    #extract the ranking
    $ranking = $self->{'cycle_ptr'}->parse(qw(RANK));

    #empty ranking?
    return unless defined $ranking; 

    push @hit, new Bio::MView::Build::Row::BLAST2::blastx
	(
	 '',                    #alignment row number
	 $match->{'query'},     #sequence identifier
	 $match->{'summary'},   #description
	 '',                    #bits
	 '',                    #expectation
	 '',                    #number of HSP used
	 $self->strand,         #query orientation
	 '+',                   #sbjct orientation
	 $self->cycle,          #cycle (psi-blast compatibility)
	);

    #extract cumulative scores and identifiers from the ranking
    foreach $match (@{$ranking->{'hit'}}) {

	$rank++;

	#check row wanted, by num OR identifier OR row count limit
	#OR bits OR expect
	last  if ($use = $self->use_row($rank, $rank, $match->{'id'},
					$match->{'bits'}, $match->{'expect'})
		 ) < 0;
	next  unless $use;

	#warn "KEEP: ($rank,$match->{'id'})\n";

	push @hit, new Bio::MView::Build::Row::BLAST2::blastx
	    (
	     $rank,
	     $match->{'id'},
	     $match->{'summary'},
	     $match->{'bits'},
	     $match->{'expect'},
	     1,
	     $self->strand,         #query orientation
	     '+',                   #sbjct orientation
	     $self->cycle,          #cycle (psi-blast compatibility)
	    );

	$idx{$match->{'id'}} = $#hit;
    }

    if ($self->{'hsp'} eq 'all') {
	$self->parse_hits_all(\@hit, \%idx);
    } elsif ($self->{'hsp'} eq 'discrete') {
	$self->parse_hits_discrete(\@hit, \%idx);
    } else {
	$self->parse_hits_ranked(\@hit, \%idx);
    }

    $self->discard_empty_ranges(\@hit);

    #free SEARCH object: vital for big psi-blast runs
    $self->{'entry'}->free(qw(SEARCH));

    #map { $_->print } @hit;

    return \@hit;
}

sub parse_hits_all {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln);

    #pull out each hit
    foreach $match ($self->{'cycle_ptr'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};
	
	my ($n, $score, $e) = (0, 0, -1);

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    #ignore other query strand orientation
	    next  unless $aln->{'query_orient'} eq $self->strand;

	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'bits'}, $aln->{'expect'});

	    #accumulate row data
	    $score = $aln->{'bits'}   if $aln->{'bits'}   > $score;
	    $e     = $aln->{'expect'} if $aln->{'expect'} < $e or $e < 0;
	    $n++;

	    #for gapped alignments
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
		 $aln->{'query_orient'},    #unused
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
		 $aln->{'bits'},
		 $aln->{'query_orient'},    #unused
		);
	}

	#override row data
	$hit->[$idx->{$sum->{'id'}}]->{'bits'}         = $score;
	$hit->[$idx->{$sum->{'id'}}]->{'expect'}       = $e;
	$hit->[$idx->{$sum->{'id'}}]->{'n'}            = $n;
	$hit->[$idx->{$sum->{'id'}}]->{'query_orient'} = $self->strand;
    }
    $self;
}

sub parse_hits_ranked {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key);

    #pull out each hit
    foreach $match ($self->{'cycle_ptr'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    #ignore more than one fragment: assumes first was best
	    last  unless $hit->[$idx->{$sum->{'id'}}]->count_frag < 1;

	    #process by query orientation
	    next  unless $aln->{'query_orient'} eq $self->strand;

	    #ignore higher e-value than ranked
	    next  unless $self->compare_e($aln->{'expect'},
				      $hit->[$idx->{$sum->{'id'}}]->{'expect'},
				      2) < 1;
	    
	    #ignore lower score than ranked
	    next  unless $self->compare_bits($aln->{'bits'},
				      $hit->[$idx->{$sum->{'id'}}]->{'bits'},
				      2) >= 0;
	    
	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'bits'}, $aln->{'expect'});

	    #for gapped alignments
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
		 $aln->{'query_orient'},    #unused
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
		 $aln->{'bits'},
		 $aln->{'query_orient'},    #unused
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
    foreach $match ($self->{'cycle_ptr'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    #process by query orientation
	    next  unless $aln->{'query_orient'} eq $self->strand;

	    $key = $match->{'index'} . '.' . $aln->{'index'};

	    #apply row filter with new row numbers
	    next  unless $self->use_row($match->{'index'}, $key, $sum->{'id'},
					$aln->{'bits'}, $aln->{'expect'});

	    if (! exists $idx->{$key}) {

		push @$hit, new Bio::MView::Build::Row::BLAST2::blastx
		    (
		     $key,
		     $sum->{'id'},
		     $sum->{'desc'},
		     $aln->{'bits'},
		     $aln->{'expect'},
		     $aln->{'n'},
		     (
		      exists $aln->{'query_frame'} ?
		      $aln->{'query_frame'} : $self->strand
		     ),                     #query orientation
		     '+',                   #sbjct orientation
		     $self->cycle,          #cycle (psi-blast compatibility)
		    );

		$idx->{$key} = $#$hit;
	    }

	    #for gapped alignments
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
		 $aln->{'query_orient'},    #unused
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
		 $aln->{'bits'},
		 $aln->{'query_orient'},    #unused
		);
	}
    }
    $self;
}


###########################################################################
package Bio::MView::Build::Format::BLAST2::tblastn;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::BLAST2);

sub parse {
    my $self = shift;
    my ($match, $ranking, $sum, $aln, $key);
    my ($rank, $use, %idx, @hit) = (0);
    
    #all strands done?
    return     unless defined $self->schedule_by_cycle;

    $self->{'cycle_ptr'} = $self->{'entry'}->parse("SEARCH[@{[$self->cycle]}]");

    #search doesn't exist?
    return unless defined $self->{'cycle_ptr'};
    
    #identify the query itself
    $match = $self->{'entry'}->parse(qw(HEADER));

    #extract the ranking
    $ranking = $self->{'cycle_ptr'}->parse(qw(RANK));

    #empty ranking?
    return unless defined $ranking; 

    push @hit, new Bio::MView::Build::Row::BLAST2::tblastn
	(
	 '',                    #alignment row number
	 $match->{'query'},     #sequence identifier
	 $match->{'summary'},   #description
	 '',                    #bits
	 '',                    #expectation
	 '',                    #number of HSP used
	 '+',                   #query orientation
	 '?',                   #sbjct orientation (none)
	 $self->cycle,          #cycle (psi-blast compatibility)
	);

    #extract cumulative scores and identifiers from the ranking
    foreach $match (@{$ranking->{'hit'}}) {

	$rank++;

	#check row wanted, by num OR identifier OR row count limit
	#OR bits OR expect
	last  if ($use = $self->use_row($rank, $rank, $match->{'id'},
					$match->{'bits'}, $match->{'expect'})
		 ) < 0;
	next  unless $use;

	#warn "KEEP: ($rank,$match->{'id'})\n";

	push @hit, new Bio::MView::Build::Row::BLAST2::tblastn
	    (
	     $rank,
	     $match->{'id'},
	     $match->{'summary'},
	     $match->{'bits'},
	     $match->{'expect'},
	     1,
	     '+',                   #query orientation
	     '?',                   #sbjct orientation (unknown)
	     $self->cycle,          #cycle (psi-blast compatibility)
	    );

	$idx{$match->{'id'}} = $#hit;
    }

    if ($self->{'hsp'} eq 'all') {
	$self->parse_hits_all(\@hit, \%idx);
    } elsif ($self->{'hsp'} eq 'discrete') {
	$self->parse_hits_discrete(\@hit, \%idx);
    } else {
	$self->parse_hits_ranked(\@hit, \%idx);
    }

    $self->discard_empty_ranges(\@hit);

    #free SEARCH object: vital for big psi-blast runs
    $self->{'entry'}->free(qw(SEARCH));

    #map { $_->print } @hit;

    return \@hit;
}

sub parse_hits_all {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key, $rank, $orient);

    #pull out each hit
    foreach $match ($self->{'cycle_ptr'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	my ($n1,$n2, $score1,$score2, $e1,$e2) = (0,0,  0,0, -1,-1);

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'bits'}, $aln->{'expect'});

	    $orient = substr($aln->{'sbjct_orient'}, 0, 1);
	    $rank   = $match->{'index'} . '.' . $aln->{'index'};
	    $key    = $idx->{$sum->{'id'}} . '.' . $orient;

	    if (! exists $idx->{$key}) {
		
		push @$hit, new Bio::MView::Build::Row::BLAST2::tblastn
		    (
		     $rank,
		     $sum->{'id'},
		     $sum->{'desc'},
		     $aln->{'bits'},
		     $aln->{'expect'},
		     $aln->{'n'},
		     '+',                   #query orientation
		     $orient,               #sbjct orientation
		     $self->cycle,          #cycle (psi-blast compatibility)
		    );

		$idx->{$key} = $#$hit;
	    }

	    #accumulate row data
	    if ($orient eq '+') {
		$score1 = $aln->{'bits'}   if $aln->{'bits'}   > $score1;
		$e1     = $aln->{'expect'} if $aln->{'expect'} < $e1 or $e1 < 0;
		$n1++;
	    } else {
		$score2 = $aln->{'bits'}  if $aln->{'bits'}    > $score2;
		$e2     = $aln->{'expect'} if $aln->{'expect'} < $e2 or $e2 < 0;
		$n2++;
	    }

	    #for gapped alignments
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
		 '+',                       #unused
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
		 $aln->{'bits'},
		 $aln->{'sbjct_orient'},    #unused
		);
	}

	#override row data (hit + orientation)
	$key = $idx->{$sum->{'id'}} . '.+';
	if (exists $idx->{$key}) {
	    $hit->[$idx->{$key}]->{'bits'}   = $score1;
	    $hit->[$idx->{$key}]->{'expect'} = $e1;
	    $hit->[$idx->{$key}]->{'n'}      = $n1;
	}
	#override row data (hit 1 orientation)
	$key = $idx->{$sum->{'id'}} . '.-';
	if (exists $idx->{$key}) {
	    $hit->[$idx->{$key}]->{'bits'}   = $score2;
	    $hit->[$idx->{$key}]->{'expect'} = $e2;
	    $hit->[$idx->{$key}]->{'n'}      = $n2;
	}
    }
    $self;
}

sub parse_hits_ranked {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key, $orient, @tmp);

    #pull out each hit
    foreach $match ($self->{'cycle_ptr'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	#we don't know which hit orientation was chosen for the ranking since
        #TBLASTN neglects to tell us: gather all fragments before choosing.
	@tmp = (); foreach $aln ($match->parse(qw(ALN))) {
	    push @tmp, $aln;
	}
	next  unless @tmp;

	#define sbjct strand orientation by looking for an HSP with the
	#same frag count N (already satisfied) and the same e-value.
	$orient = '?'; foreach $aln (@tmp) {
	    if ($self->compare_e($aln->{'expect'},
				 $hit->[$idx->{$sum->{'id'}}]->{'expect'},
				 2) >= 0) {
		$orient = $aln->{'sbjct_orient'};
		last;
	    }
	}

	foreach $aln (@tmp) {
	    
	    #ignore more than one fragment: assumes first was best
	    last  unless $hit->[$idx->{$sum->{'id'}}]->count_frag < 1;

	    #ignore different hit orientation to ranking
	    next  unless $aln->{'sbjct_orient'} eq $orient;

	    #ignore higher e-value than ranked
	    next  unless $self->compare_e($aln->{'expect'},
				      $hit->[$idx->{$sum->{'id'}}]->{'expect'},
				      2) < 1;

	    #ignore lower score than ranked
	    next  unless $self->compare_bits($aln->{'bits'},
				      $hit->[$idx->{$sum->{'id'}}]->{'bits'},
				      2) >= 0;
	    
	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'bits'}, $aln->{'expect'});

	    #for gapped alignments
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
		 '+',                       #unused
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
		 $aln->{'bits'},
		 $aln->{'sbjct_orient'},    #unused
		);
	}
	#override row data (hit + orientation)
	$hit->[$idx->{$sum->{'id'}}]->{'sbjct_orient'} = $orient;
	$hit->[$idx->{$sum->{'id'}}]->{'desc'} = $sum->{'desc'};
    }
    $self;
}

sub parse_hits_discrete {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key);

    #pull out each hit
    foreach $match ($self->{'cycle_ptr'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    $key = $match->{'index'} . '.' . $aln->{'index'};

	    #apply row filter with new row numbers
	    next  unless $self->use_row($match->{'index'}, $key, $sum->{'id'},
					$aln->{'bits'}, $aln->{'expect'});
	    
	    if (! exists $idx->{$key}) {
		
		push @$hit, new Bio::MView::Build::Row::BLAST2::tblastn
		    (
		     $key,
		     $sum->{'id'},
		     $sum->{'desc'},
		     $aln->{'bits'},
		     $aln->{'expect'},
		     $aln->{'n'},
		     '+',                   #query orientation
		     (
		      exists $aln->{'sbjct_frame'} ?
		      $aln->{'sbjct_frame'} : $aln->{'sbjct_orient'}
		     ),                     #sbjct orientation
		     $self->cycle,          #cycle (psi-blast compatibility)
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
		 '+',                       #unused
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
		 $aln->{'bits'},
		 $aln->{'sbjct_orient'},    #unused
		);
	}
    }
    $self;
}


###########################################################################
package Bio::MView::Build::Format::BLAST2::tblastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::BLAST2);

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
    my ($match, $ranking, $sum, $aln, $key);
    my ($rank, $use, %idx, @hit) = (0);

    #all searches/orientations done?
    return unless defined $self->schedule_by_cycle_and_strand;

    $self->{'cycle_ptr'} = $self->{'entry'}->parse("SEARCH[@{[$self->cycle]}]");

    #search doesn't exist?
    return unless defined $self->{'cycle_ptr'};
    
    #identify the query itself
    $match = $self->{'entry'}->parse(qw(HEADER));

    #extract the ranking
    $ranking = $self->{'cycle_ptr'}->parse(qw(RANK));

    #empty ranking?
    return unless defined $ranking;

    push @hit, new Bio::MView::Build::Row::BLAST2::tblastx
	(
	 '',                    #alignment row number
	 $match->{'query'},     #sequence identifier
	 $match->{'summary'},   #description
	 '',                    #bits
	 '',                    #expectation
	 '',                    #number of HSP used
	 $self->strand,         #query orientation
	 '?',                   #sbjct orientation
	 $self->cycle,          #cycle (psi-blast compatibility)
	);
    
    #extract hits and identifiers from the ranking
    foreach $match (@{$ranking->{'hit'}}) {

	$rank++;

	#check row wanted, by num OR identifier OR row count limit
	#OR bits OR expect
	last  if ($use = $self->use_row($rank, $rank, $match->{'id'},
					$match->{'bits'}, $match->{'expect'})
		 ) < 0;
	next  unless $use;

	#warn "KEEP: ($rank,$match->{'id'})\n";

	push @hit, new Bio::MView::Build::Row::BLAST2::tblastx
	    (
	     $rank,
	     $match->{'id'},
	     $match->{'summary'},
	     $match->{'bits'},
	     $match->{'expect'},
             1,
	     $self->strand,         #query orientation
	     '?',                   #sbjct orientation
	     $self->cycle,          #cycle (psi-blast compatibility)
	    );

	$idx{$match->{'id'}} = $#hit;
    }

    if ($self->{'hsp'} eq 'all') {
	$self->parse_hits_all(\@hit, \%idx);
    } elsif ($self->{'hsp'} eq 'discrete') {
	$self->parse_hits_discrete(\@hit, \%idx);
    } else {
	$self->parse_hits_ranked(\@hit, \%idx);
    }

    $self->discard_empty_ranges(\@hit);

    #free SEARCH object: vital for big psi-blast runs
    $self->{'entry'}->free(qw(SEARCH));

    #map { $_->print } @hit;

    return \@hit;
}

sub parse_hits_all {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key, $rank, $orient);

    #pull out each hit
    foreach $match ($self->{'cycle_ptr'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	my ($n1,$n2, $score1,$score2, $e1,$e2) = (0,0,  0,0, -1,-1);

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    #process by query orientation
	    next  unless $aln->{'query_orient'} eq $self->strand;

	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'bits'}, $aln->{'expect'});

	    $orient = substr($aln->{'sbjct_orient'}, 0, 1);
	    $rank   = $match->{'index'} . '.' . $aln->{'index'};
	    $key    = $idx->{$sum->{'id'}} . '.' . $orient;

	    if (! exists $idx->{$key}) {
		
		push @$hit, new Bio::MView::Build::Row::BLAST2::tblastx
		    (
		     $rank,
		     $sum->{'id'},
		     $sum->{'desc'},
		     $aln->{'bits'},
		     $aln->{'expect'},
		     $aln->{'n'},
		     $self->strand,          #query orientation
		     $orient,                #sbjct orientation
		     $self->cycle,           #cycle (psi-blast compatibility)
		    );

		$idx->{$key} = $#$hit;
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
		 $aln->{'query_orient'},    #unused
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
		 $aln->{'bits'},
		 $aln->{'sbjct_orient'},    #unused
		);
	    
	}

	#override row data (hit + orientation)
	$key = $idx->{$sum->{'id'}} . '.+';
	if (exists $idx->{$key}) {
	    $hit->[$idx->{$key}]->{'bits'}   = $score1;
	    $hit->[$idx->{$key}]->{'expect'} = $e1;
	    $hit->[$idx->{$key}]->{'n'}      = $n1;
	}
	#override row data (hit - orientation)
	$key = $idx->{$sum->{'id'}} . '.-';
	if (exists $idx->{$key}) {
	    $hit->[$idx->{$key}]->{'bits'}   = $score2;
	    $hit->[$idx->{$key}]->{'expect'} = $e2;
	    $hit->[$idx->{$key}]->{'n'}      = $n2;
	}
    }
    $self;
}

sub parse_hits_ranked {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key, $orient, @tmp);

    #pull out each hit
    foreach $match ($self->{'cycle_ptr'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	#we don't know which hit orientation was chosen for the ranking
	#since TBLASTX neglects to tell us: gather all fragments before choosing.
	@tmp = (); foreach $aln ($match->parse(qw(ALN))) {

	    #ignore other query strand orientation
	    next  unless $aln->{'query_orient'} eq $self->strand;

	    push @tmp, $aln;
	}
	next  unless @tmp;

	#define sbjct strand orientation by looking for an HSP with the
	#same frag count N (already satisfied) and the same e-value.
	$orient = '?'; foreach $aln (@tmp) {
	    if ($self->compare_e($aln->{'expect'},
				 $hit->[$idx->{$sum->{'id'}}]->{'expect'},
				 2) >= 0) {
		$orient = $aln->{'sbjct_orient'};
		last;
	    }
	}

	foreach $aln (@tmp) {
	    
	    #ignore more than one fragment: assumes first was best
	    last  unless $hit->[$idx->{$sum->{'id'}}]->count_frag < 1;

	    #ignore different hit orientation to ranking
	    next  unless $aln->{'sbjct_orient'} eq $orient;

	    #ignore higher e-value than ranked
	    next  unless $self->compare_e($aln->{'expect'},
				      $hit->[$idx->{$sum->{'id'}}]->{'expect'},
				      2) < 1;

	    #ignore lower score than ranked
	    next  unless $self->compare_bits($aln->{'bits'},
				      $hit->[$idx->{$sum->{'id'}}]->{'bits'},
				      2) >= 0;

	    #apply score/p-value filter
	    next  unless $self->use_hsp($aln->{'bits'}, $aln->{'expect'});
	    
	    #for gapped alignments
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
		 $aln->{'query_orient'},    #unused
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
		 $aln->{'bits'},
		 $aln->{'sbjct_orient'},    #unused
		);
	}
	#override row data (hit + orientation)
	$hit->[$idx->{$sum->{'id'}}]->{'sbjct_orient'} = $orient;
	$hit->[$idx->{$sum->{'id'}}]->{'desc'} = $sum->{'desc'};
    }
    $self;
}

sub parse_hits_discrete {
    my ($self, $hit, $idx) = @_;
    my ($match, $sum, $aln, $key);

    #pull out each hit
    foreach $match ($self->{'cycle_ptr'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#ignore hit?
	next  unless exists $idx->{$sum->{'id'}};

	foreach $aln ($match->parse(qw(ALN))) {
	    
	    #process by query orientation
	    next  unless $aln->{'query_orient'} eq $self->strand;

	    $key = $match->{'index'} . '.' . $aln->{'index'};

	    #apply row filter with new row numbers
	    next  unless $self->use_row($match->{'index'}, $key, $sum->{'id'},
					$aln->{'bits'}, $aln->{'expect'});
	    
	    if (! exists $idx->{$key}) {
		
		push @$hit, new Bio::MView::Build::Row::BLAST2::tblastx
		    (
		     $key,
		     $sum->{'id'},
		     $sum->{'desc'},
		     $aln->{'bits'},
		     $aln->{'expect'},
		     $aln->{'n'},
		     (
		      exists $aln->{'query_frame'} ?
		      $aln->{'query_frame'} : $self->strand
		     ),                     #query orientation
		     (
		      exists $aln->{'sbjct_frame'} ?
		      $aln->{'sbjct_frame'} : $aln->{'sbjct_orient'}
		     ),                     #sbjct orientation
		     $self->cycle,          #cycle (psi-blast compatibility)
		    );

		$idx->{$key} = $#$hit;
	    }

	    #for gapped alignments
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
		 $aln->{'query_orient'},    #unused
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
		 $aln->{'bits'},
		 $aln->{'sbjct_orient'},    #unused
		);
	}
    }
    $self;
}


###########################################################################
1;
