# -*- perl -*-
# Copyright (C) 1996-2015 Nigel P. Brown
# $Id: FASTA3.pm,v 1.17 2015/06/14 17:09:04 npb Exp $

###########################################################################
#
# FASTA 3
#
#   fasta, fastx, fasty, tfasta, tfastx, tfasty, tfastxy (tested)
#
###########################################################################
use Bio::MView::Build::Format::FASTA;

use strict;


###########################################################################
###########################################################################
package Bio::MView::Build::Row::FASTA3;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA);

#Handles the fasta 3.3 format change using 'bits' rather than the older
#'z-score', 'initn' and 'init1'. The last two are stored, but flagged here
#with use=0 to ignore them on output.
sub schema {[
    # use? rdb?  key              label         format   default
    [ 0,   1,    'initn',         'initn',      '5N',      ''  ],
    [ 0,   2,    'init1',         'init1',      '5N',      ''  ],
    [ 3,   3,    'opt',           'opt',        '5N',      ''  ],
    [ 4,   4,    'bits',          'bits',       '7N',      ''  ],
    [ 5,   5,    'expect',        'E-value',    '9N',      ''  ],
    [ 6,   6,    'query_orient',  'qy',         '2S',      '?' ],
    [ 7,   7,    'sbjct_orient',  'ht',         '2S',      '?' ],
    ]
}


###########################################################################
package Bio::MView::Build::Row::FASTA3::fasta;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA3);


###########################################################################
package Bio::MView::Build::Row::FASTA3::fastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTX);

sub schema { Bio::MView::Build::Row::FASTA3::schema }


###########################################################################
package Bio::MView::Build::Row::FASTA3::fasty;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTX);

sub schema { Bio::MView::Build::Row::FASTA3::schema }


###########################################################################
package Bio::MView::Build::Row::FASTA3::tfasta;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA3::fasta);


###########################################################################
package Bio::MView::Build::Row::FASTA3::tfastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA3::fasta);


###########################################################################
package Bio::MView::Build::Row::FASTA3::tfasty;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA3::fasta);


###########################################################################
package Bio::MView::Build::Row::FASTA3::tfastxy;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA3::fasta);


###########################################################################
###########################################################################
package Bio::MView::Build::Format::FASTA3;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA);


###########################################################################
package Bio::MView::Build::Format::FASTA3::fasta;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA);

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

    #identify the query itself
    $match = $self->{'entry'}->parse(qw(HEADER));

    my $rtype = $1  if ref($self) =~ /::([^:]+)$/;

    #if this is a pre-3.3 fasta call the old FASTA2 parser
    if ($match->{'version'} =~ /^3\.(\d+)/ and $1 < 3) {
	require Bio::MView::Build::Format::FASTA2;
	my $class = "Bio::MView::Build::Format::FASTA2::$rtype";
	bless $self, $class;
	return $self->parse(@_);
    }

    #all strands done?
    return  unless defined $self->{scheduler}->next;

    if ($match->{'query'} ne '') {
	$query = $match->{'query'};
    } elsif ($match->{'queryfile'} =~ m,.*/([^\.]+)\.,) {
	$query = $1;
    } else {
	$query = 'Query';
    }

    #fasta run with no hits
    my $rankparse = $self->{'entry'}->parse(qw(RANK));
    return []  unless defined $rankparse;

    #the actual Row subclass to build
    my $class = "Bio::MView::Build::Row::FASTA3::$rtype";

    push @hit, new $class(
	'',
	$query,
	'',
	'',
	'',
	'',
	'',
	'',
	$self->strand,
	'',
	);
    
    #extract cumulative scores and identifiers from the ranking
    foreach $match (@{ $rankparse->{'hit'} }) {

	$rank++;

	#check row wanted, by num OR identifier OR row count limit OR opt
	$use = $self->use_row($rank, $rank, $match->{'id'}, $match->{'opt'});

	last  if $use < 0;
	next  if $use < 1;

	#warn "KEEP: ($rank,$match->{'id'})\n";

	if ($match->{'opt'} eq '') {
	    #seen in: tfast[axy]_3.4t23 omit opt by mistake
	    $key = $match->{'id'} . $match->{'init1'} . $match->{'expect'};
	} else {
	    $key = $match->{'id'} . $match->{'opt'} . $match->{'expect'};
	}

	#warn "ADD: [$key]\n";

	push @hit, new $class(
	    $rank,
	    $match->{'id'},
	    $match->{'desc'},
	    $match->{'initn'},
	    $match->{'init1'},
	    $match->{'opt'},
	    $match->{'bits'},
	    $match->{'expect'},
	    $self->strand,
	    '',
	    );
	$hit{$key} = $#hit;
    }

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#only read hits already seen in ranking
	while (1) {
	    $key = $sum->{'id'} . $sum->{'opt'} . $sum->{'expect'};
	    last  if exists $hit{$key};
	    $key = $sum->{'id'} . $sum->{'init1'} . $sum->{'expect'};
	    last  if exists $hit{$key};
	    #tfastx_3.4t23 confuses init1 with s-w score between RANK and SUM
	    $key = $sum->{'id'} . $sum->{'score'} . $sum->{'expect'};
	    last  if exists $hit{$key};
	    $key = '';
	    last;
	}
	next  unless exists $hit{$key};
	#warn "SEE: [$key]\n";

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

	    #override initn, init1, sbjct orientation
	    $hit[$hit{$key}]->set_val('initn', $sum->{'initn'});
	    $hit[$hit{$key}]->set_val('init1', $sum->{'init1'});
	    $hit[$hit{$key}]->set_val('sbjct_orient', $aln->{'sbjct_orient'});
	}
    }

    $self->discard_empty_ranges(\@hit);

    #free objects
    $self->{'entry'}->free(qw(HEADER RANK MATCH));

    #map { $_->print; print "\n" } @hit;

    return \@hit;
}


###########################################################################
package Bio::MView::Build::Format::FASTA3::fastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA3::fasta);


###########################################################################
package Bio::MView::Build::Format::FASTA3::fasty;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA3::fasta);


###########################################################################
package Bio::MView::Build::Format::FASTA3::tfasta;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA3::fasta);


###########################################################################
package Bio::MView::Build::Format::FASTA3::tfastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA3::fasta);


###########################################################################
package Bio::MView::Build::Format::FASTA3::tfasty;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA3::fasta);


###########################################################################
package Bio::MView::Build::Format::FASTA3::tfastxy;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA3::fasta);


###########################################################################
1;
