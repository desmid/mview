# -*- perl -*-
# Copyright (C) 1996-2015 Nigel P. Brown
# $Id: FASTA2.pm,v 1.17 2015/06/14 17:09:04 npb Exp $

###########################################################################
#
# FASTA 2
#
#   fasta, tfastx (tested)
#   fastx, fasty, tfasta, tfasty, tfastxy (not tested: may work)
#
###########################################################################
use Bio::MView::Build::Format::FASTA;

use strict;


###########################################################################
###########################################################################
package Bio::MView::Build::Row::FASTA2;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA);

sub schema {[
    # use? rdb?  key              label         format   default
    [ 1,   1,    'initn',         'initn',      '5N',      ''  ],
    [ 2,   2,    'init1',         'init1',      '5N',      ''  ],
    [ 3,   3,    'opt',           'opt',        '5N',      ''  ],
    [ 4,   4,    'zscore',        'z-sc',       '7N',      ''  ],
    [ 5,   5,    'expect',        'E-value',    '9N',      ''  ],
    [ 6,   6,    'query_orient',  'qy',         '2S',      '?' ],
    [ 7,   7,    'sbjct_orient',  'ht',         '2S',      '?' ],
    ]
}


###########################################################################
package Bio::MView::Build::Row::FASTA2::fasta;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA2);


###########################################################################
package Bio::MView::Build::Row::FASTA2::tfasta;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA2::fasta);


###########################################################################
package Bio::MView::Build::Row::FASTA2::tfastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA2::fasta);


###########################################################################
package Bio::MView::Build::Row::FASTA2::tfasty;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA2::fasta);


###########################################################################
package Bio::MView::Build::Row::FASTA2::tfastxy;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA2::fasta);


###########################################################################
###########################################################################
package Bio::MView::Build::Format::FASTA2;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA);


###########################################################################
package Bio::MView::Build::Format::FASTA2::fasta;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA2);

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

    #identify the query
    my $header = $self->{'entry'}->parse(qw(HEADER));

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
    my $class = "Bio::MView::Build::Row::FASTA2::$rtype";

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

	#check row wanted, by num OR identifier OR row count limit OR opt
	my $use = $self->use_row($rank, $rank, $hit->{'id'}, $hit->{'opt'});

	last  if $use < 0;
	next  if $use < 1;

	#warn "KEEP: ($rank,$hit->{'id'})\n";

	my $key = $coll->key($hit->{'id'}, $hit->{'initn'}, $hit->{'expect'});

	$coll->insert((new $class(
                           $rank,
                           $hit->{'id'},
                           $hit->{'desc'},
                           $hit->{'initn'},
                           $hit->{'init1'},
                           $hit->{'opt'},
                           $hit->{'zscore'},
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

        my $key = $coll->key($sum->{'id'}, $sum->{'initn'}, $sum->{'expect'});

	#only read hits already seen in ranking
	next  unless $coll->has($key);

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

	    #override sbjct orientation
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
package Bio::MView::Build::Format::FASTA2::fastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA2::fasta);


###########################################################################
package Bio::MView::Build::Format::FASTA2::fasty;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA2::fasta);


###########################################################################
package Bio::MView::Build::Format::FASTA2::tfasta;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA2);

sub parse {
    my $self = shift;

    #all strands done?
    return  unless defined $self->{scheduler}->next;

    #identify the query
    my $header = $self->{'entry'}->parse(qw(HEADER));

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
    my $class = "Bio::MView::Build::Row::FASTA2::$rtype";

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

	#check row wanted, by num OR identifier OR row count limit OR opt
	my $use = $self->use_row($rank, $rank, $hit->{'id'}, $hit->{'opt'});

	last  if $use < 0;
	next  if $use < 1;

	#warn "KEEP: ($rank,$hit->{'id'})\n";

	my $key = $coll->key($hit->{'id'}, $hit->{'initn'}, $hit->{'expect'},
                             lc $hit->{'orient'});

	$coll->insert((new $class(
                           $rank,
                           $hit->{'id'},
                           $hit->{'desc'},
                           $hit->{'initn'},
                           $hit->{'init1'},
                           $hit->{'opt'},
                           $hit->{'zscore'},
                           $hit->{'expect'},
                           $self->strand,
                           $hit->{'orient'},
                       )),
                      $key
            );
    }

    #pull out each hit
    foreach my $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	my $sum = $match->parse(qw(SUM));

	my $key = $coll->key($sum->{'id'}, $sum->{'initn'}, $sum->{'expect'},
                             lc $sum->{'orient'});

	#only read hits accepted in ranking
	next  unless $coll->has($key);

	#then the individual matched fragments
	foreach my $aln ($match->parse(qw(ALN))) {

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
	}
	#override description
        $coll->item($key)->{'desc'} = $sum->{'desc'}  if $sum->{'desc'};
    }

    #free objects
    $self->{'entry'}->free(qw(HEADER RANK MATCH));

    return $coll->list;
}


###########################################################################
package Bio::MView::Build::Format::FASTA2::tfastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA2::tfasta);


###########################################################################
package Bio::MView::Build::Format::FASTA2::tfasty;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA2::tfasta);


###########################################################################
package Bio::MView::Build::Format::FASTA2::tfastxy;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA2::tfasta);


###########################################################################
###########################################################################
package Bio::MView::Build::Format::FASTA2::ssearch;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA2);

sub parse {
    warn "FASTA2 SSEARCH processing - not implemented\n";
    return undef;
}


###########################################################################
package Bio::MView::Build::Format::FASTA2::align;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA2);

sub parse {
    warn "FASTA2 ALIGN processing - not implemented\n";
    return undef;
}


###########################################################################
package Bio::MView::Build::Format::FASTA2::lalign;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA2);

sub parse {
    warn "FASTA2 LALIGN processing - not implemented\n";
    return undef;
}


###########################################################################
1;
