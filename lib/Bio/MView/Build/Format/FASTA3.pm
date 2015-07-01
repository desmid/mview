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

    #identify the query
    my $header = $self->{'entry'}->parse(qw(HEADER));

    #if this is a pre-3.3 fasta call the old FASTA2 parser
    if ($header->{'version'} =~ /^3\.(\d+)/ and $1 < 3) {
	require Bio::MView::Build::Format::FASTA2;
        my $rtype = $1  if ref($self) =~ /::([^:]+)$/;
	my $class = "Bio::MView::Build::Format::FASTA2::$rtype";
	bless $self, $class;
	return $self->parse(@_);
    }

    #all strands done?
    return  unless defined $self->{scheduler}->next;

    #fasta run with no hits
    my $rankparse = $self->{'entry'}->parse(qw(RANK));

    return []  unless defined $rankparse;

    my $query = 'Query';
    if ($header->{'query'} ne '') {
	$query = $header->{'query'};
    } elsif ($header->{'queryfile'} =~ m,.*/([^\.]+)\.,) {
	$query = $1;
    }

    my $coll = new Bio::MView::Build::Search::Collector($self);

    my $rtype = $1  if ref($self) =~ /::([^:]+)$/;
    my $class = "Bio::MView::Build::Row::FASTA3::$rtype";

    $coll->insert((new $class(
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
                   )));
    
    #extract hits and identifiers from the ranking
    my $rank = 0; foreach my $hit (@{$rankparse->{'hit'}}) {

	$rank++;

        last  if $self->topn_done($rank);
        next  if $self->skip_row($rank, $rank, $hit->{'id'});
        next  if $self->skip_frag($hit->{'opt'});

	#warn "KEEP: ($rank,$hit->{'id'})\n";

        my $key;

	if ($hit->{'opt'} eq '') {
	    #seen in: tfast[axy]_3.4t23 omit opt by mistake
            $key = $coll->key($hit->{'id'}, $hit->{'init1'}, $hit->{'expect'});
	} else {
            $key = $coll->key($hit->{'id'}, $hit->{'opt'}, $hit->{'expect'});
	}

	#warn "ADD: [$key]\n";

	$coll->insert((new $class(
                           $rank,
                           $hit->{'id'},
                           $hit->{'desc'},
                           $hit->{'initn'},
                           $hit->{'init1'},
                           $hit->{'opt'},
                           $hit->{'bits'},
                           $hit->{'expect'},
                           $self->strand,
                           '',
                       )),
                      $key
            );
    }

    #pull out each hit
    foreach my $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	my $sum = $match->parse(qw(SUM));

        my $key;

	#only read hits already seen in ranking
	while (1) {
	    $key = $coll->key($sum->{'id'}, $sum->{'opt'}, $sum->{'expect'});
	    last  if $coll->has($key);
	    $key = $coll->key($sum->{'id'}, $sum->{'init1'}, $sum->{'expect'});
	    last  if $coll->has($key);
	    #tfastx_3.4t23 confuses init1 with s-w score between RANK and SUM
	    $key = $coll->key($sum->{'id'}, $sum->{'score'}, $sum->{'expect'});
	    last  if $coll->has($key);
            $key = 'unknown';
            last;
	}
	next  unless $coll->has($key);

	#warn "SEE: [$key]\n";

	#then the individual matched fragments
	foreach my $aln ($match->parse(qw(ALN))) {

	    #ignore other query strand orientation
            next  unless $self->use_strand($aln->{'query_orient'});

	    #$aln->print;
	    
	    #for FASTA gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'},
				    $aln->{'query_leader'},
                                    $aln->{'query_trailer'});
	    
            $coll->add_frags(
                $key, $aln->{'query_start'}, $aln->{'query_stop'}, [
                    $aln->{'query'},
                    $aln->{'query_start'},
                    $aln->{'query_stop'},
                ], [
                    $aln->{'sbjct'},
                    $aln->{'sbjct_start'},
                    $aln->{'sbjct_stop'},
                ]);

	    #override initn, init1, sbjct orientation
	    $coll->item($key)->set_val('initn', $sum->{'initn'});
	    $coll->item($key)->set_val('init1', $sum->{'init1'});
	    $coll->item($key)->set_val('sbjct_orient', $aln->{'sbjct_orient'});
	}
	#override description
        $coll->item($key)->{'desc'} = $sum->{'desc'}  if $sum->{'desc'};
    }

    #free objects
    $self->{'entry'}->free(qw(HEADER RANK MATCH));

    return $coll->list;
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
