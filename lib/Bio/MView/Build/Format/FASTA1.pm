# -*- perl -*-
# Copyright (C) 1996-2015 Nigel P. Brown
# $Id: FASTA1.pm,v 1.13 2013/09/09 21:31:04 npb Exp $

###########################################################################
#
# FASTA 1
#
#   fasta, tfastx
#
###########################################################################
###########################################################################
package Bio::MView::Build::Format::FASTA1;

use Bio::MView::Build::Format::FASTA;
use strict;
use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA);


###########################################################################
###########################################################################
package Bio::MView::Build::Row::FASTA1;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA);


###########################################################################
package Bio::MView::Build::Row::FASTA1::fasta;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA1);

sub new {
    my $type = shift;
    my $self = new Bio::MView::Build::Row::FASTA1(@_);
    $self->{'query_orient'} = $_[@_-2];
    $self->{'sbjct_orient'} = $_[@_-1];
    bless $self, $type;
}

sub data {
    my $s = $_[0]->SUPER::data;
    return $s .= sprintf(" %2s %2s", 'qy', 'ht') unless $_[0]->num;
    $s .= sprintf(" %2s %2s", $_[0]->{'query_orient'}, $_[0]->{'sbjct_orient'});
}

sub rdb_info {
    my ($self, $mode) = @_;
    return ($self->{'query_orient'}, $self->{'sbjct_orient'})
	if $mode eq 'data';
    return ('query_orient', 'sbjct_orient')  if $mode eq 'attr';
    return ('2S', '2S')  if $mode eq 'form';
}

sub range {
    my $self = shift;
    $self->SUPER::range($self->{'query_orient'});
}

sub assemble { my $self = shift; $self->assemble_fasta(@_) }


###########################################################################
package Bio::MView::Build::Row::FASTA1::tfastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA1);

sub new {
    my $type = shift;
    my $self = new Bio::MView::Build::Row::FASTA1(@_);
    $self->{'orient'} = $_[@_-1];
    bless $self, $type;
}

sub data {
    my $s = $_[0]->SUPER::data;
    return $s .= sprintf(" %2s %2s", 'qy', 'ht') unless $_[0]->num;
    $s .= sprintf(" %2s %2s", '+', $_[0]->{'orient'});
}

sub rdb_info {
    my ($self, $mode) = @_;
    return ('+', $self->{'orient'})  if $mode eq 'data';
    return ('query_orient', 'sbjct_orient')  if $mode eq 'attr';
    return ('2S', '2S')  if $mode eq 'form';
}


###########################################################################
###########################################################################
package Bio::MView::Build::Format::FASTA1::fasta;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA1);

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
    my ($match, $sum, $aln, $query, $key);
    my ($rank, $use, %hit, @hit) = (0);

    return     unless defined $self->schedule_by_strand;

    #identify the query itself
    $match = $self->{'entry'}->parse(qw(HEADER));

    if ($match->{'query'} ne '') {
	$query = $match->{'query'};
    } elsif ($match->{'queryfile'} =~ m,.*/([^\.]+)\.,) {
	$query = $1;
    } else {
	$query = 'Query';
    }

    push @hit, new Bio::MView::Build::Row::FASTA1::fasta
	(
	 '',
	 $query,
	 '',
	 '',
	 '',
	 '',
	 $self->strand,
	 '',
	);
    
    #extract cumulative scores and identifiers from the ranking
    foreach $match (@{$self->{'entry'}->parse(qw(RANK))->{'hit'}}) {

	$rank++;

	#check row wanted, by num OR identifier OR row count limit OR opt
	last  if ($use = $self->use_row($rank, $rank, $match->{'id'},
					$match->{'opt'})
		 ) < 0;
	next  unless $use;

	#warn "KEEP: ($rank,$match->{'id'})\n";

	$key = $match->{'id'} . $match->{'initn'} . $match->{'init1'};

	push @hit, new Bio::MView::Build::Row::FASTA1::fasta
	    (
	     $rank,
	     $match->{'id'},
	     $match->{'desc'},
	     $match->{'initn'},
	     $match->{'init1'},
	     $match->{'opt'},
	     $self->strand,
	     '',
	    );
	$hit{$key} = $#hit;
    }

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	$key = $sum->{'id'} . $sum->{'initn'} . $sum->{'init1'};

	#only read hits already seen in ranking
	next  unless exists $hit{$key};

	#override the row description
	if ($sum->{'desc'}) {
	    $hit[$hit{$key}]->{'desc'} = $sum->{'desc'};
	}

	#then the individual matched fragments
	foreach $aln ($match->parse(qw(ALN))) {

	    #ignore other query strand orientation
            next  unless $aln->{'query_orient'} eq $self->strand;

	    $aln = $match->parse(qw(ALN));
	    
	    #$aln->print;
	    
	    #for FASTA gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'},
				    $aln->{'query_leader'},
                                    $aln->{'query_trailer'});

	    $hit[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 0,
		 0,
		);
	    
	    $hit[$hit{$key}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		);

	    #override row data
	    $hit[$hit{$key}]->{'sbjct_orient'} = $aln->{'sbjct_orient'};
	}
    }

    $self->discard_empty_ranges(\@hit);

    #free objects
    $self->{'entry'}->free(qw(HEADER RANK MATCH));

    #map { $_->print } @hit;

    return \@hit;
}


###########################################################################
package Bio::MView::Build::Format::FASTA1::tfastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA1);

sub parse {
    my $self = shift;
    my ($match, $sum, $aln, $query, $key);
    my ($rank, $use, %hit, @hit) = (0);

    return     unless defined $self->schedule;

    #identify the query itself
    $match = $self->{'entry'}->parse(qw(HEADER));

    if ($match->{'query'} ne '') {
	$query = $match->{'query'};
    } elsif ($match->{'queryfile'} =~ m,.*/([^\.]+)\.,) {
	$query = $1;
    } else {
	$query = 'Query';
    }

    push @hit, new Bio::MView::Build::Row::FASTA1::tfastx
	(
	 '',
	 $query,
	 '',
	 '',
	 '',
	 '',
	 '',
	);

    #extract cumulative scores and identifiers from the ranking
    foreach $match (@{$self->{'entry'}->parse(qw(RANK))->{'hit'}}) {
	
	$rank++;

	#check row wanted, by num OR identifier OR row count limit OR opt
	last  if ($use = $self->use_row($rank, $rank, $match->{'id'},
					$match->{'opt'})
		 ) < 0;
	next  unless $use;

	#warn "KEEP: ($rank,$match->{'id'})\n";

	$key = $match->{'id'} . $match->{'initn'} . $match->{'expect'} . 
	    lc $match->{'orient'};
	
	push @hit, new Bio::MView::Build::Row::FASTA1::tfastx
	    (
	     $rank,
	     $match->{'id'},
	     $match->{'desc'},
	     $match->{'initn'},
	     $match->{'init1'},
	     $match->{'opt'},
	     $match->{'orient'},
	    );
	$hit{$key} = $#hit;
    }

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	$key = $sum->{'id'} . $sum->{'initn'} . $sum->{'init1'};

	#only read hits accepted in ranking
	next  unless exists $hit{$key};

	#override the row description
	if ($sum->{'desc'}) {
	    $hit[$hit{$key}]->{'desc'} = $sum->{'desc'};
	}

	#then the individual matched fragments
	foreach $aln ($match->parse(qw(ALN))) {
	    $aln = $match->parse(qw(ALN));
	    
	    #$aln->print;
	    
	    #for FASTA gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'},
				    $aln->{'query_leader'},
                                    $aln->{'query_trailer'});
	    
	    $hit[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 0,
		 0,
		);
	    
	    $hit[$hit{$key}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 $aln->{'sbjct_start'},
		 $aln->{'sbjct_stop'},
		);
	}
    }

    $self->discard_empty_ranges(\@hit);

    #free objects
    $self->{'entry'}->free(qw(HEADER RANK MATCH));

    #map { $_->print } @hit;

    return \@hit;
}


###########################################################################
1;
