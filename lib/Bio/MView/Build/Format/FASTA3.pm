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
###########################################################################
package Bio::MView::Build::Format::FASTA3;

use Bio::MView::Build::Format::FASTA;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA);


###########################################################################
###########################################################################
package Bio::MView::Build::Row::FASTA3;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA);

#Handles the fasta 3.3 format change using 'bits' rather than older z-scores
#with reduction in importance of 'initn' and 'init1'.

sub new {
    my $type = shift;
    my ($num, $id, $desc, $initn, $init1, $opt, $bits, $e) = @_;
    my $self = new Bio::MView::Build::Row::FASTA(@_);
    $self->{'bits'} = $bits;
    $self->{'e'}    = $e;
    bless $self, $type;
}

sub data  {
    return sprintf("%5s %7s %9s", 'opt', 'bits', 'E-value') unless $_[0]->num;
    return sprintf("%5s %7s %9s", $_[0]->{'opt'}, $_[0]->{'bits'},
		   $_[0]->{'e'});
}

sub rdb_info {
    my ($self, $mode) = @_;
    return ($self->{'opt'}, $self->{'bits'}, $self->{'e'})  if $mode eq 'data';
    return ('opt', 'bits', 'E-value')  if $mode eq 'attr';
    return ('5S', '7S', '9S')  if $mode eq 'form';
}


###########################################################################
package Bio::MView::Build::Row::FASTA3::fasta;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA3);

sub new {
    my $type = shift;
    my $self = new Bio::MView::Build::Row::FASTA3(@_);
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

sub assemble { my $self = shift; $self->assemble_fasta(@_) }


###########################################################################
package Bio::MView::Build::Row::FASTA3::fastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA3::fasta);

sub range {
    my $self = shift;
    my ($lo, $hi) = $self->SUPER::range;
    $self->translate_range($lo, $hi);
}

sub assemble { my $self = shift; $self->assemble_fastx(@_) }


###########################################################################
package Bio::MView::Build::Row::FASTA3::fasty;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA3::fastx);


###########################################################################
package Bio::MView::Build::Row::FASTA3::tfasta;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA3::fasta);

sub assemble { my $self = shift; $self->assemble_tfasta(@_) }


###########################################################################
package Bio::MView::Build::Row::FASTA3::tfastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA3::tfasta);


###########################################################################
package Bio::MView::Build::Row::FASTA3::tfasty;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA3::tfasta);


###########################################################################
package Bio::MView::Build::Row::FASTA3::tfastxy;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA3::tfasta);


###########################################################################
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
    return $self->parse_body('fasta', @_);
}

sub parse_body {
    my ($self, $hint) = (shift, shift);
    my ($match, $sum, $aln, $query, $key);
    my ($rank, $use, %hit, @hit) = (0);

    #the actual Row subclass to build
    my $class = "Bio::MView::Build::Row::FASTA3::$hint";

    #identify the query itself
    $match = $self->{'entry'}->parse(qw(HEADER));

    #if this is a pre-3.3 fasta call the old FASTA2 parser
    if ($match->{'version'} =~ /^3\.(\d+)/ and $1 < 3) {
	require Bio::MView::Build::Format::FASTA2;
	$class = "Bio::MView::Build::Format::FASTA2::$hint";	
	bless $self, $class;
	return $self->parse(@_);
    }

    #all strands done?
    return  unless defined $self->schedule_by_strand;

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
	last  if ($use = $self->use_row($rank, $rank, $match->{'id'},
					$match->{'opt'})
		 ) < 0;
	next  unless $use;

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

    #map { $_->print; print "\n" } @hit;

    return \@hit;
}


###########################################################################
package Bio::MView::Build::Format::FASTA3::fastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA3::fasta);

sub parse {
    my $self = shift;
    return $self->parse_body('fastx', @_);
}


###########################################################################
package Bio::MView::Build::Format::FASTA3::fasty;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA3::fastx); #note


###########################################################################
package Bio::MView::Build::Format::FASTA3::tfasta;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA3::fasta);

sub parse {
    my $self = shift;
    return $self->parse_body('tfasta', @_);
}


###########################################################################
package Bio::MView::Build::Format::FASTA3::tfastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA3::tfasta); #note


###########################################################################
package Bio::MView::Build::Format::FASTA3::tfasty;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA3::tfasta); #note


###########################################################################
package Bio::MView::Build::Format::FASTA3::tfastxy;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA3::tfasta); #note


###########################################################################
1;
