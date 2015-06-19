# -*- perl -*-
# Copyright (C) 1996-2015 Nigel P. Brown
# $Id: FASTA1.pm,v 1.14 2015/06/14 17:09:04 npb Exp $

###########################################################################
#
# FASTA 1
#
#   fasta, tfastx
#
###########################################################################
use Bio::MView::Build::Format::FASTA;

use strict;


###########################################################################
###########################################################################
package Bio::MView::Build::Row::FASTA1;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA);

sub schema {[
    # use?   key              string        format   default 
    [ 1,     'initn',         'initn',      '5N',      ''  ],
    [ 2,     'init1',         'init1',      '5N',      ''  ],
    [ 3,     'opt',           'opt',        '5N',      ''  ],
    [ 4,     'query_orient',  'qy',         '2S',      '?' ],
    [ 5,     'sbjct_orient',  'ht',         '2S',      '?' ],
    ]
}


###########################################################################
package Bio::MView::Build::Row::FASTA1::fasta;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA1);


###########################################################################
package Bio::MView::Build::Row::FASTA1::tfastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA1);


###########################################################################
###########################################################################
package Bio::MView::Build::Format::FASTA1;
# sub new {

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA);


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

    return  unless defined $self->{scheduler}->next;

    #identify the query itself
    $match = $self->{'entry'}->parse(qw(HEADER));

    if ($match->{'query'} ne '') {
	$query = $match->{'query'};
    } elsif ($match->{'queryfile'} =~ m,.*/([^\.]+)\.,) {
	$query = $1;
    } else {
	$query = 'Query';
    }

    #the actual Row subclass to build
    my $rtype = $1  if ref($self) =~ /::([^:]+)$/;
    my $class = "Bio::MView::Build::Row::FASTA1::$rtype";

    push @hit, new $class(
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
	$use = $self->use_row($rank, $rank, $match->{'id'}, $match->{'opt'});

	last  if $use < 0;
	next  if $use < 1;

	#warn "KEEP: ($rank,$match->{'id'})\n";

	$key = $match->{'id'} . $match->{'initn'} . $match->{'init1'};

	push @hit, new $class(
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

	#override description
        $hit[$hit{$key}]->{'desc'} = $sum->{'desc'}  if $sum->{'desc'};

	#then the individual matched fragments
	foreach $aln ($match->parse(qw(ALN))) {

	    #ignore other query strand orientation
            next  unless $self->use_strand($aln->{'query_orient'});

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

	    #override sbjct orientation
	    $hit[$hit{$key}]->set_val('sbjct_orient', $aln->{'sbjct_orient'});
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

    return  unless defined $self->{scheduler}->next;

    #identify the query itself
    $match = $self->{'entry'}->parse(qw(HEADER));

    if ($match->{'query'} ne '') {
	$query = $match->{'query'};
    } elsif ($match->{'queryfile'} =~ m,.*/([^\.]+)\.,) {
	$query = $1;
    } else {
	$query = 'Query';
    }

    my $rtype = $1  if ref($self) =~ /::([^:]+)$/;
    my $class = "Bio::MView::Build::Row::FASTA1::$rtype";

    push @hit, new $class(
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

	$use = $self->use_row($rank, $rank, $match->{'id'}, $match->{'opt'});

	last  if $use < 0;
	next  if $use < 1;

	#warn "KEEP: ($rank,$match->{'id'})\n";

	$key = $match->{'id'} . $match->{'initn'} . $match->{'expect'} . 
	    lc $match->{'orient'};
	
	push @hit, new $class(
            $rank,
            $match->{'id'},
            $match->{'desc'},
            $match->{'initn'},
            $match->{'init1'},
            $match->{'opt'},
            $self->strand,
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

	#override description
        $hit[$hit{$key}]->{'desc'} = $sum->{'desc'}  if $sum->{'desc'};

	#then the individual matched fragments
	foreach $aln ($match->parse(qw(ALN))) {

            next  unless $self->use_strand($aln->{'query_orient'});
	    
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
