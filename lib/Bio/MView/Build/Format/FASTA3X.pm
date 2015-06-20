# -*- perl -*-
# Copyright (C) 1996-2015 Nigel P. Brown
# $Id: FASTA3X.pm,v 1.7 2015/06/18 21:26:11 npb Exp $

###########################################################################
#
# FASTA 3X (34/35/36)
#
#   fasta, fastx, fasty, tfasta, tfastx, tfasty, tfastxy,
#   fastm, fastf, fasts, ggsearch, glsearch, ssearch
#
###########################################################################
###########################################################################
use Bio::MView::Build::Format::FASTA3;


###########################################################################
package Bio::MView::Build::Format::FASTA3X;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA3);


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

sub new {
    my $type = shift;
    my ($num, $id, $desc, $initn, $init1, $bits, $e, $sn, $sl,
	$query_orient, $sbjct_orient) = @_;
    my $self = new Bio::MView::Build::Row($num, $id, $desc);
    $self->{'initn'} 	    = $initn;
    $self->{'init1'} 	    = $init1;
    $self->{'bits'}    	    = $bits;
    $self->{'e'}       	    = $e;
    $self->{'sn'}      	    = $sn;
    $self->{'sl'}      	    = $sl;
    $self->{'query_orient'} = $query_orient;
    $self->{'sbjct_orient'} = $sbjct_orient;
    bless $self, $type;
}

sub data  {
    return sprintf("%5s %5s %7s %9s %3s %3s %2s %2s",
		   'initn', 'init1', 'bits', 'E-value', 'sn', 'sl', 'qy', 'ht')
	unless $_[0]->num;
    return sprintf("%5s %5s %7s %9s %3s %3s %2s %2s",
		   $_[0]->{'initn'}, $_[0]->{'init1'}, $_[0]->{'bits'},
		   $_[0]->{'e'}, $_[0]->{'sn'}, $_[0]->{'sl'},
		   $_[0]->{'query_orient'}, $_[0]->{'sbjct_orient'});
}

sub rdb_info {
    my ($self, $mode) = @_;
    return ($self->{'initn'}, $self->{'init1'}, $self->{'bits'},
	    $self->{'e'}, $self->{'sn'}, $self->{'sl'},
	    $self->{'query_orient'}, $self->{'sbjct_orient'})
	if $mode eq 'data';
    return ('initn', 'init1', 'bits', 'E-value', 'sn', 'sl',
	    'query_orient', 'sbjct_orient')  if $mode eq 'attr';
    return ('5N', '5N', '7N', '9N', '3N', '3N', '2S', '2S')  if $mode eq 'form';
}

sub assemble { my $self = shift; $self->assemble_fasta(@_) }


###########################################################################
package Bio::MView::Build::Row::FASTA3X::ssearch;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA);

sub new {
    my $type = shift;
    my ($num, $id, $desc, $score, $bits, $e, $query_orient, $sbjct_orient)
	= @_;
    my $self = new Bio::MView::Build::Row($num, $id, $desc);
    $self->{'score'} 	    = $score;
    $self->{'bits'}    	    = $bits;
    $self->{'e'}       	    = $e;
    $self->{'query_orient'} = $query_orient;
    $self->{'sbjct_orient'} = $sbjct_orient;
    bless $self, $type;
}

sub data  {
    return sprintf("%5s %7s %9s %2s %2s",
		   'S-W', 'bits', 'E-value', 'qy', 'ht')
	unless $_[0]->num;
    return sprintf("%5s %7s %9s %2s %2s",
		   $_[0]->{'score'}, $_[0]->{'bits'}, $_[0]->{'e'},
		   $_[0]->{'query_orient'}, $_[0]->{'sbjct_orient'});
}

sub rdb_info {
    my ($self, $mode) = @_;
    return ($self->{'score'}, $self->{'bits'}, $self->{'e'},
	    $self->{'query_orient'}, $self->{'sbjct_orient'})
	if $mode eq 'data';
    return ('S-W', 'bits', 'E-value', 'query_orient', 'sbjct_orient')
	if $mode eq 'attr';
    return ('5N', '7N', '9N', '2S', '2S')  if $mode eq 'form';
}

sub assemble { my $self = shift; $self->assemble_fasta(@_) }


###########################################################################
package Bio::MView::Build::Row::FASTA3X::ggsearch;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA3X::ssearch);

sub data  {
    return sprintf("%5s %7s %9s %2s %2s",
		   'N-W', 'bits', 'E-value', 'qy', 'ht')
	unless $_[0]->num;
    return sprintf("%5s %7s %9s %2s %2s",
		   $_[0]->{'score'}, $_[0]->{'bits'}, $_[0]->{'e'},
		   $_[0]->{'query_orient'}, $_[0]->{'sbjct_orient'});
}

sub rdb_info {
    my ($self, $mode) = @_;
    return ($self->{'score'}, $self->{'bits'}, $self->{'e'},
	    $self->{'query_orient'}, $self->{'sbjct_orient'})
	if $mode eq 'data';
    return ('N-W', 'bits', 'E-value', 'query_orient', 'sbjct_orient')
	if $mode eq 'attr';
    return ('5N', '7N', '9N', '2S', '2S')  if $mode eq 'form';
}


###########################################################################
package Bio::MView::Build::Row::FASTA3X::glsearch;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::FASTA3X::ggsearch);


###########################################################################
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

sub subheader {
    my ($self, $quiet) = (@_, 0);
    my $s = '';
    return $s    if $quiet;
    $s  = $self->SUPER::subheader($quiet);
    $s .= "Peptide tuple: $self->{'peptup_idx'}  " . $self->peptup . "\n";
    $s;
}

sub parse {
    my $self = shift;
    return $self->parse_body('fastm', @_);
}

sub initialise_parameters {
    my $self = shift;
    #warn "initialise_parameters";
    $self->SUPER::initialise_parameters;
    $self->reset_peptup;
}

sub set_parameters {
    my $self = shift;
    #warn "set_parameters";
    $self->SUPER::set_parameters(@_);
    $self->reset_peptup;
}

#overrides FASTA: initialise
sub initialise {
    my $self = shift;

    #warn "initialise";
    $self->{'peptup_list'} = undef;  #peptup tuples
    $self->{'do_peptup'}   = undef;  #list of required peptups
    $self->{'peptup_idx'}  = undef;  #current index into 'do_peptup'
    $self->{'peptup'}      = [];

    $self->parse(1);  #first pass: gather peptide tuples

    $self->SUPER::initialise();
    $self;
}

sub peptup   { $_[0]->{'do_peptup'}->[$_[0]->{'peptup_idx'}-1] }

sub reset_peptup {
    my $self = shift;
    #warn "peptup: [@{$self->{'peptup'}}]\n";
    $self->{'do_peptup'} = $self->reset_schedule($self->{'peptup_list'},
                                                 $self->{'peptup'});
}

sub next_peptup {
    my $self = shift;

    #first pass?
    $self->{'peptup_idx'} = 0  unless defined $self->{'peptup_idx'};

    #normal pass: post-increment peptup counter
    if ($self->{'peptup_idx'} < @{$self->{'do_peptup'}}) {
	return $self->{'do_peptup'}->[$self->{'peptup_idx'}++];
    }

    #finished loop
    $self->{'peptup_idx'} = undef;
}

sub schedule_by_peptup {
    my ($self, $next) = shift;
    if (defined ($next = $self->next_peptup)) {
	return $next;
    }
    return undef;           #tell parser
}

sub parse_body {
    my ($self, $hint) = (shift, shift);
    my ($inipeptups) = (@_, 0);
    my ($match, $sum, $aln, $query, $key);
    my ($rank, $use, %hit, @hit) = (0);

    #the actual Row subclass to build
    my $class = "Bio::MView::Build::Row::FASTA3X::$hint";

    #all peptup tuples done?
    return  unless $inipeptups or defined $self->schedule_by_peptup;

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
	last  if ($use = $self->use_row($rank, $rank, $match->{'id'},
					$match->{'initn'})
		 ) < 0;
	next  unless $use;

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

    my ($pep, $peplist) = ({}, []);

    #pull out each hit
    foreach $match ($self->{'entry'}->parse(qw(MATCH))) {

	#first the summary
	$sum = $match->parse(qw(SUM));

	#only read hits already seen in ranking
	while (1) {
	    #FASTM3X reports three s-w scores, any might match:
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

	#override the row description
	if ($sum->{'desc'}) {
	    $hit[$hit{$key}]->{'desc'} = $sum->{'desc'};
	}

        my $maketup = sub {
            $_[0] =~ s/^\s+//o;
            $_[0] =~ s/\s+$//o;
            $_[0] =~ s/[-\s]+/, /og;
            $_[0];
        };

	#then the individual matched fragments
	foreach $aln ($match->parse(qw(ALN))) {

	    $aln = $match->parse(qw(ALN));

	    #$aln->print;

            my $peptup = &$maketup("$aln->{'query'}");

            if ($inipeptups) {
                if (!exists $pep->{$peptup}) { #new peptide tuple
                    #warn "PEP: $peptup\n";
                    push @$peplist, $peptup;
                    $pep->{$peptup}++;
                }
            } else {
                #ignore other peptide tuples
                next  unless $peptup eq $self->peptup;
            }

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

	    #override row data
	    $hit[$hit{$key}]->{'sbjct_orient'} = $aln->{'sbjct_orient'};
	}
    }

    $self->discard_empty_ranges(\@hit);

    #free objects
    $self->{'entry'}->free(qw(HEADER RANK MATCH));

    #map { $_->print; print "\n" } @hit;

    if ($inipeptups) {
        #warn "[@$peplist]\n";
        $self->{'peptup_list'} = $peplist;
    }

    return \@hit;
}

#overrides FASTA
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
package Bio::MView::Build::Format::FASTA3X::fasts;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA3X::fastm); #note


###########################################################################
package Bio::MView::Build::Format::FASTA3X::fastf;

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
    return $self->parse_body('ssearch', @_);
}

sub parse_body {
    my ($self, $hint) = (shift, shift);
    my ($match, $sum, $aln, $query, $key);
    my ($rank, $use, %hit, @hit) = (0);

    #the actual Row subclass to build
    my $class = "Bio::MView::Build::Row::FASTA3X::$hint";

    #all strands done?
    return  unless defined $self->schedule_by_strand;

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
	last  if ($use = $self->use_row($rank, $rank, $match->{'id'},
					$match->{'score'})
		 ) < 0;
	next  unless $use;

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
package Bio::MView::Build::Format::FASTA3X::ggsearch;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA3X::ssearch); #note

sub parse {
    my $self = shift;
    return $self->parse_body('ggsearch', @_);
}


###########################################################################
package Bio::MView::Build::Format::FASTA3X::glsearch;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::FASTA3X::ssearch); #note

sub parse {
    my $self = shift;
    return $self->parse_body('glsearch', @_);
}


###########################################################################
1;
