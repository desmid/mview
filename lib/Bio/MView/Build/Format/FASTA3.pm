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
    my $ranking = $self->{'entry'}->parse(qw(RANK));

    return []  unless defined $ranking;

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
    my $rank = 0; foreach my $hit (@{$ranking->{'hit'}}) {

	$rank++;

        last  if $self->topn_done($rank);
        next  if $self->skip_row($rank, $rank, $hit->{'id'});

	#warn "KEEP: ($rank,$hit->{'id'})\n";

        my $key1 = $coll->key($hit->{'id'}, $hit->{'expect'});

	#warn "ADD: [$key1]\n";

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
                      $key1
            );
    }

    #pull out each hit
    foreach my $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	my $sum = $match->parse(qw(SUM));

        my $key1 = $coll->key($sum->{'id'}, $sum->{'expect'});

	next  unless $coll->has($key1);

	#warn "USE: [$key1]\n";

        my $aset = $self->get_ranked_frags($match, $coll, $key1, $self->strand);

        #nothing matched
        next  unless @$aset;

        foreach my $aln (@$aset) {
	    #apply score/significance filter
            next  if $self->skip_frag($sum->{'opt'});

	    #$aln->print;
	    
	    #for gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'},
				    $aln->{'query_leader'},
                                    $aln->{'query_trailer'});
	    
            $coll->add_frags(
                $key1, $aln->{'query_start'}, $aln->{'query_stop'}, [
                    $aln->{'query'},
                    $aln->{'query_start'},
                    $aln->{'query_stop'},
                ], [
                    $aln->{'sbjct'},
                    $aln->{'sbjct_start'},
                    $aln->{'sbjct_stop'},
                ]);
	}
	#override row data
        $coll->item($key1)->{'desc'} = $sum->{'desc'}  if $sum->{'desc'};

        my ($qorient, $sorient) = $self->get_orient($aset);
        $coll->item($key1)->set_val('initn', $sum->{'initn'});
        $coll->item($key1)->set_val('init1', $sum->{'init1'});
        $coll->item($key1)->set_val('sbjct_orient', $sorient);
    }

    #free objects
    $self->{'entry'}->free(qw(HEADER RANK MATCH));

    return $coll->list;
}

#return a hash of frag sets; each set is a list of ALN with a given
#query/sbjct ordering, score, and significance; these sets have multiple
#alternative keys: "qorient/sorient/opt/sig", "qorient/sorient/init1/sig",
#"qorient/sorient/initn/sig" to handle variations in the input data.
sub get_frag_groups {
    my ($self, $match) = @_;
    my $hash = {};
    my $sum = $match->parse(qw(SUM));
    foreach my $aln ($match->parse(qw(ALN))) {
        my $opt     = $sum->{'opt'};
        my $init1   = $sum->{'init1'};
        my $initn   = $sum->{'initn'};
        my $sig     = $sum->{'expect'};
        my $qorient = $aln->{'query_orient'};
        my $sorient = $aln->{'sbjct_orient'};
        my (%tmp, $key);
        
        $tmp { join("/", $qorient, $sorient, $opt,   $sig) }++;
        $tmp { join("/", $qorient, $sorient, $init1, $sig) }++;
        $tmp { join("/", $qorient, $sorient, $initn, $sig) }++;

        foreach my $key (keys %tmp) {
            push @{ $hash->{$key} }, $aln;
        }
    }
    #warn "SAVE: @{[sort keys %$hash]}\n";
    return $hash;
}        

#lookup a frag set in a frag dictionary, trying various keys based on scores
#and significance.
sub get_ranked_frags_by_query {
    my ($self, $hash, $coll, $rkey, $qorient) = @_;

    my $opt      = $coll->item($rkey)->get_val('opt');
    my $sig      = $coll->item($rkey)->get_val('expect');
    my $init1    = $coll->item($rkey)->get_val('init1');
    my $initn    = $coll->item($rkey)->get_val('initn');
    my $qorient2 = ($qorient eq '+' ? '-' : '+');
    
    my $D = 0;

    my $lookup_o_score_sig = sub {
        my ($qorient, $score, $sig) = @_;
        foreach my $sorient (qw(+ -)) {
            my $key = join("/", $qorient, $sorient, $score, $sig);
            return $hash->{$key}  if exists $hash->{$key};
        }
        return undef;
    };

    my $match;

    warn "KEYS($rkey): @{[sort keys %$hash]}\n"  if $D;

    #match (opt, sig) in query orientation?
    warn "TRY: $qorient $opt $sig\n"  if $D;
    $match = &$lookup_o_score_sig($qorient, $opt, $sig);
    warn "MATCH (@{[scalar @$match]})\n"  if defined $match and $D;
    return $match  if defined $match;

    #match (init1, sig) in query orientation?
    warn "TRY: $qorient $init1 $sig\n"  if $D;
    $match = &$lookup_o_score_sig($qorient, $init1, $sig);
    warn "MATCH (@{[scalar @$match]})\n"  if defined $match and $D;
    return $match  if defined $match;

    #match (initn, sig) in query orientation?
    warn "TRY: $qorient $initn $sig\n"  if $D;
    $match = &$lookup_o_score_sig($qorient, $initn, $sig);
    warn "MATCH (@{[scalar @$match]})\n"  if defined $match and $D;
    return $match  if defined $match;

    warn "<<<< FAILED >>>>\n"  if $D;
    #no match
    return [];
}

#return a set of frags suitable for tiling, that are consistent with the query
#and sbjct sequence numberings.
sub get_ranked_frags {
    my ($self, $match, $coll, $key, $qorient) = @_;
    my $tmp = $self->get_frag_groups($match);
    
    return []  unless keys %$tmp;

    my $alist = $self->get_ranked_frags_by_query($tmp, $coll, $key, $qorient);

    return $self->combine_frags_by_centroid($alist, $qorient);
}

sub get_orient {
    my ($self, $list) = @_;

    return unless @$list;

    my ($qorient, $sorient) = ('?', '?');

    foreach my $aln (@$list) {
        $qorient = $aln->{'query_orient'}, next  if $qorient eq '?';
        if ($aln->{'query_orient'} ne $qorient) {
            warn "get_orient: mixed up query orientations\n";
        }
    }

    foreach my $aln (@$list) {
        $sorient = $aln->{'sbjct_orient'}, next  if $sorient eq '?';
        if ($aln->{'sbjct_orient'} ne $sorient) {
            warn "get_orient: mixed up sbjct orientations\n";
        }
    }

    ($qorient, $sorient);
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
