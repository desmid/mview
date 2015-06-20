# -*- perl -*-
# Copyright (C) 1996-2015 Nigel P. Brown
# $Id: FASTA3X.pm,v 1.6 2015/06/16 17:11:10 npb Exp $

###########################################################################
#
# FASTA 3X (34/35/36)
#
#   fasta, fastx, fasty, tfasta, tfastx, tfasty, tfastxy,
#   fastm, fastf, fasts, ggsearch, glsearch, ssearch
#
###########################################################################
use Bio::MView::Build::Format::FASTA3;

use strict;

###########################################################################
###########################################################################
package Bio::MView::Build::Row::FASTA3X;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA3);


###########################################################################
package Bio::MView::Build::Row::FASTA3X::fasta;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA3::fasta);


###########################################################################
package Bio::MView::Build::Row::FASTA3X::fastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA3::fastx);


###########################################################################
package Bio::MView::Build::Row::FASTA3X::fasty;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA3::fasty);


###########################################################################
package Bio::MView::Build::Row::FASTA3X::tfasta;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA3::tfasta);


###########################################################################
package Bio::MView::Build::Row::FASTA3X::tfastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA3::tfastx);


###########################################################################
package Bio::MView::Build::Row::FASTA3X::tfasty;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA3::tfasty);


###########################################################################
package Bio::MView::Build::Row::FASTA3X::tfastxy;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA3::tfastxy);


###########################################################################
package Bio::MView::Build::Row::FASTA3X::fastm;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA);

sub schema {[
    # use? rdb?  key              label         format   default
    [ 1,   1,    'initn',         'initn',      '5N',      ''  ],
    [ 2,   2,    'init1',         'init1',      '5N',      ''  ],
    [ 3,   3,    'bits',          'bits',       '7N',      ''  ],
    [ 4,   4,    'e',             'E-value',    '9N',      ''  ],
    [ 5,   5,    'sn',            'sn',         '3N',      ''  ],
    [ 6,   6,    'sl',            'sl',         '3N',      ''  ],
    [ 7,   7,    'query_orient',  'qy',         '2S',      '?' ],
    [ 8,   8,    'sbjct_orient',  'ht',         '2S',      '?' ],
    ]
}


###########################################################################
package Bio::MView::Build::Row::FASTA3X::fastf;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA3X::fastm);


###########################################################################
package Bio::MView::Build::Row::FASTA3X::fasts;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA3X::fastm);


###########################################################################
package Bio::MView::Build::Row::FASTA3X::ssearch;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA);

sub schema {[
    # use? rdb?  key              label         format   default
    [ 1,   1,    'score',         'S-W',        '5N',      ''  ],
    [ 2,   2,    'bits',          'bits',       '7N',      ''  ],
    [ 3,   3,    'expect',        'E-value',    '9N',      ''  ],
    [ 4,   4,    'query_orient',  'qy',         '2S',      '?' ],
    [ 5,   5,    'sbjct_orient',  'ht',         '2S',      '?' ],
    ]
}


###########################################################################
package Bio::MView::Build::Row::FASTA3X::ggsearch;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA3X::ssearch);

sub schema {[
    # use? rdb?  key              label         format   default
    [ 1,   1,    'score',         'N-W',        '5N',      ''  ],
    [ 2,   2,    'bits',          'bits',       '7N',      ''  ],
    [ 3,   3,    'expect',        'E-value',    '9N',      ''  ],
    [ 4,   4,    'query_orient',  'qy',         '2S',      '?' ],
    [ 5,   5,    'sbjct_orient',  'ht',         '2S',      '?' ],
    ]
}


###########################################################################
package Bio::MView::Build::Row::FASTA3X::glsearch;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA3X::ggsearch);


###########################################################################
###########################################################################
package Bio::MView::Build::Format::FASTA3X;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA3);


###########################################################################
package Bio::MView::Build::Format::FASTA3X::fasta;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA3::fasta);


###########################################################################
package Bio::MView::Build::Format::FASTA3X::fastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA3::fastx);


###########################################################################
package Bio::MView::Build::Format::FASTA3X::fasty;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA3::fasty);


###########################################################################
package Bio::MView::Build::Format::FASTA3X::tfasta;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA3::tfasta);


###########################################################################
package Bio::MView::Build::Format::FASTA3X::tfastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA3::tfastx);


###########################################################################
package Bio::MView::Build::Format::FASTA3X::tfasty;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA3::tfasty);


###########################################################################
package Bio::MView::Build::Format::FASTA3X::tfastxy;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA3::tfastxy);


###########################################################################
package Bio::MView::Build::Format::FASTA3X::fastm;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA); #note

my $FASTMFS_SPACER = '\001' x 5;

#called by the constructor
sub initialise_child {
    my $self = shift;

    #schedule by query peptide tuple
    my $peplist = $self->parse_query_tuples;

    $self->{scheduler} = new Bio::MView::Build::Scheduler($peplist);
    $self;
}

#called on each iteration
sub reset_child {
    my $self = shift;
    #warn "reset_child [all]\n";
    $self->{scheduler}->filter;
    $self;
}

#current peptide tuple being processed
sub pepnum { $_[0]->{scheduler}->itemnum }
sub peptup { $_[0]->{scheduler}->item }

sub subheader {
    my ($self, $quiet) = (@_, 0);
    my $s = '';
    return $s    if $quiet;
    $s  = $self->SUPER::subheader($quiet);
    $s .= "Peptide tuple: @{[$self->pepnum]}  @{[$self->peptup]}\n";
    $s;
}

sub makepeptup {
    $_[0] =~ s/^\s+//o;
    $_[0] =~ s/\s+$//o;
    $_[0] =~ s/[-\s]+/, /og;
    $_[0];
}

sub parse_query_tuples {
    my $self = shift;
    my ($peplist, $pephash) = ([], {});
    foreach my $match ($self->{'entry'}->parse(qw(MATCH))) {
	foreach my $aln ($match->parse(qw(ALN))) {

            my $peptup = makepeptup("$aln->{'query'}");

            next  if exists $pephash->{$peptup};

            push @$peplist, $peptup;
            $pephash->{$peptup}++;
            #warn "PEP: $peptup\n";
        }
    }
    #free objects
    $self->{'entry'}->free(qw(MATCH));
    $peplist;
}

sub parse {
    my $self = shift;
    my ($match, $sum, $aln, $query, $key);
    my ($rank, $use, %hit, @hit) = (0);

    #all peptide tuples done?
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

    #fasta run with no hits
    my $rankparse = $self->{'entry'}->parse(qw(RANK));
    return []  unless defined $rankparse;

    #the actual Row subclass to build
    my $rtype = $1  if ref($self) =~ /::([^:]+)$/;
    my $class = "Bio::MView::Build::Row::FASTA3X::$rtype";

    push @hit, new $class(
	'',
	$query,
	'',
        '',
	'',
	'',
	'',
	'',
	'',
	'+',
	'',
	);

    #extract cumulative scores and identifiers from the ranking
    foreach $match (@{ $rankparse->{'hit'} }) {

	$rank++;

	#check row wanted, by num OR identifier OR row count limit OR initn OR
	#initn in fastm rankings.
	$use = $self->use_row($rank, $rank, $match->{'id'}, $match->{'initn'});

	last  if $use < 0;
	next  if $use < 1;

	#warn "KEEP: ($rank,$match->{'id'})\n";

	$key = $match->{'id'} . $match->{'initn'} . $match->{'expect'};

	#warn "ADD: [$key]\n";

	push @hit, new $class(
	    $rank,
	    $match->{'id'},
	    $match->{'desc'},
	    $match->{'initn'},
	    $match->{'init1'},
	    $match->{'bits'},
	    $match->{'expect'},
	    $match->{'sn'},
	    $match->{'sl'},
            '+',
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
	    #FASTA3X reports three s-w scores, any might match:
	    $key = $sum->{'id'} . $sum->{'opt'} . $sum->{'expect'};
	    last  if exists $hit{$key};
	    $key = $sum->{'id'} . $sum->{'initn'} . $sum->{'expect'};
	    last  if exists $hit{$key};
	    $key = $sum->{'id'} . $sum->{'init1'} . $sum->{'expect'};
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

	    #$aln->print;

            my $peptup = makepeptup("$aln->{'query'}");

            #ignore other peptide tuples
            next  unless $self->{scheduler}->use_item($peptup);

	    #for FASTA gapped alignments
	    $self->strip_query_gaps(\$aln->{'query'}, \$aln->{'sbjct'},
				    $aln->{'query_leader'},
                                    $aln->{'query_trailer'});

            my $qlen = length $aln->{'query'};

	    $hit[0]->add_frag
		(
		 $aln->{'query'},
		 $aln->{'query_start'},
                 $aln->{'query_start'} + $qlen,
		 $aln->{'query_start'},
		 $aln->{'query_stop'},
		 0,
		 0,
		);

	    $hit[$hit{$key}]->add_frag
		(
		 $aln->{'sbjct'},
		 $aln->{'query_start'},
                 $aln->{'query_start'} + $qlen,
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

    #map { $_->print; print "\n" } @hit;

    return \@hit;
}

#overrides FASTA::strip_query_gaps
sub strip_query_gaps {
    my ($self, $query, $sbjct, $leader, $trailer) = @_;

    my $gapper = sub {
        my ($query, $sbjct, $char) = @_;

        while ( (my $i = index($$query, $char)) >= 0 ) {

            my $pos = $i;

            #downcase preceding symbol
            if (defined substr($$query, $i-1, 1)) {
                substr($$sbjct, $i-1, 1) = lc substr($$sbjct, $i-1, 1);
            }

            #consume more of same in query and hit
            while (substr($$query, $i, 1) eq $char) {
                substr($$query, $i, 1) = '';
                substr($$sbjct, $i, 1) = '';
            }

            #downcase succeeding symbol
            if (defined substr($$query, $i, 1)) {
                substr($$sbjct, $i, 1) = lc substr($$sbjct, $i, 1);
            }

            #insert fixed spacer
            substr($$query, $pos, 0) = $FASTMFS_SPACER;
            substr($$sbjct, $pos, 0) = $FASTMFS_SPACER;
        }
    };
    
    &$gapper($query, $sbjct, '-');  #mark gaps in sbjct only

    #strip query terminal white space
    $trailer = length($$query) - $leader - $trailer;
    $$query  = substr($$query, $leader, $trailer);
    $$sbjct  = substr($$sbjct, $leader, $trailer);
	
    #replace sbjct leading/trailing white space with gaps
    $$sbjct =~ s/\s/-/g;

    #replace spacer with '-'
    $$query =~ s/\\001/-/g;
    $$sbjct =~ s/\\001/-/g;

    #warn "sqg(out q)=[$$query]\n";
    #warn "sqg(out h)=[$$sbjct]\n";

    $self;
}


###########################################################################
package Bio::MView::Build::Format::FASTA3X::fastf;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA3X::fastm); #note


###########################################################################
package Bio::MView::Build::Format::FASTA3X::fasts;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA3X::fastm); #note


###########################################################################
package Bio::MView::Build::Format::FASTA3X::ssearch;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA); #note

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

    #all strands done?
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

    #fasta run with no hits
    my $rankparse = $self->{'entry'}->parse(qw(RANK));
    return []  unless defined $rankparse;

    #the actual Row subclass to build
    my $rtype = $1  if ref($self) =~ /::([^:]+)$/;
    my $class = "Bio::MView::Build::Row::FASTA3X::$rtype";

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
    foreach $match (@{ $rankparse->{'hit'} }) {

	$rank++;

	#check row wanted, by num OR identifier OR row count limit OR score:
	#in ssearch rankings, 'score' seems the same as 'opt in the summaries
	#so use the same fasta use_row filter
	$use = $self->use_row($rank, $rank, $match->{'id'}, $match->{'score'});

	last  if $use < 0;
	next  if $use < 1;

	#warn "KEEP: ($rank,$match->{'id'})\n";

	$key = $match->{'id'} . $match->{'score'} . $match->{'expect'};

	#warn "ADD: [$key]\n";

	push @hit, new $class(
	    $rank,
	    $match->{'id'},
	    $match->{'desc'},
	    $match->{'score'},
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
	    #SSEARCH3X reports two s-w scores, either might match:
	    $key = $sum->{'id'} . $sum->{'opt'} . $sum->{'expect'};
	    last  if exists $hit{$key};
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

	    #override sbjct orientation
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
package Bio::MView::Build::Format::FASTA3X::ggsearch;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA3X::ssearch); #note


###########################################################################
package Bio::MView::Build::Format::FASTA3X::glsearch;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA3X::ssearch); #note


###########################################################################
1;
