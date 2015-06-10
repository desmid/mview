# Copyright (C) 1997-2015 Nigel P. Brown
# $Id: HSSP.pm,v 1.30 2011/01/20 15:58:53 npb Exp $

###########################################################################
package Bio::MView::Build::Row::HSSP;

use vars qw(@ISA);
use Bio::MView::Build;
use strict;

@ISA = qw(Bio::MView::Build::Row);

sub new {
    my $type = shift;
    my ($num, $id, $desc, $chain, $seq) = @_;
    my $self = new Bio::MView::Build::Row($num, $id, $desc, $seq);
    $self->{'chain'} = $chain;
    bless $self, $type;
}

sub rdb_info {
    my ($self, $mode) = @_;
    return ($self->{'chain'})  if $mode eq 'data';
    return ('chain')  if $mode eq 'attr';
    return ('1S')  if $mode eq 'form';
}


###########################################################################
package Bio::MView::Build::Format::HSSP;

use vars qw(@ISA);
use Bio::MView::Build::Search;
use Bio::MView::Build::Row;
use strict;

@ISA = qw(Bio::MView::Build::Search);

#the name of the underlying NPB::Parse::Format parser
sub parser { 'HSSP' }

my %Known_Parameter = 
    (
     #name        => [ format,               default ]
     'chain'      => [ [],                   undef   ],
    );

sub initialise_parameters {
    my $self = shift;
    $self->SUPER::initialise_parameters;
    $self->SUPER::initialise_parameters(\%Known_Parameter);

    $self->reset_chain;
}

sub set_parameters {
    my $self = shift;
    $self->SUPER::set_parameters(@_);
    $self->SUPER::set_parameters(\%Known_Parameter, @_);

    $self->reset_chain;
}

sub new {
    my $type = shift;
    my $self = new Bio::MView::Build::Search(@_);

    #MaxHom/HSSP chain names
    $self->{'do_chain'}   = undef;    #required list of chain *names*
    $self->{'chain_idx'}  = undef;    #current index into 'do_chain'

    bless $self, $type;
}

sub chain   { $_[0]->{'do_chain'}->[$_[0]->{'chain_idx'}-1] }

sub reset_chain {
    my $self = shift;
    my (%names, @names, $i, @tmp) = ();

    #initialise scheduler loops and loop counters
    if (! defined $self->{'do_chain'}) {

	#get the chain names
	@names = $self->{'entry'}->parse(qw(ALIGNMENT))->get_chains;
	
	#hash them
	map { $names{$_}=1 } @names;

	if (@{$self->{'chain'}} < 1) {
	    #empty list - do all chains
	    $self->{'do_chain'} = [ @names ];
	} elsif ($self->{'chain'}->[0] eq '*') {
	    #wildcard '*' - do all chains
	    $self->{'do_chain'} = [ @names ];
	} else {
	    #explicit chain range
	    foreach $i (@{$self->{'chain'}}) {
		
		#it's a recognised chain name
		if (exists $names{$i}) {
		    push @tmp, $i;
		    next;
		}
		
		#it's a serial number 1..N
		if ($i =~ /^\d+$/ and 0 < $i and $i <= @names) {
		    push @tmp, $names[$i-1];
		    next;
		}
	    }
	    $self->{'do_chain'} = [ sort @tmp ];
	}
    }
}

sub next_chain {
    my $self = shift;

    #first pass?
    $self->{'chain_idx'} = 0    unless defined $self->{'chain_idx'};
    
    #normal pass: post-increment chain counter
    if ($self->{'chain_idx'} < @{$self->{'do_chain'}}) {
	return $self->{'do_chain'}->[$self->{'chain_idx'}++];
    }

    #finished loop
    $self->{'chain_idx'} = undef;
}

sub schedule_by_chain {
    my ($self, $next) = shift;

    if (defined ($next = $self->next_chain)) {
	return $next;
    }
    return undef;           #tell parser    
}

sub subheader {
    my ($self, $quiet) = (@_, 0);
    my $s = '';
    return $s    if $quiet;
    $s .= "Chain: " . $self->chain . "\n";
    $s;    
}

sub parse {
    my $self = shift;
    my ($rank, $use, $head, $prot, $align, $match, $id, $seq, @hit) = (0);

    return  unless defined $self->schedule_by_chain;

    $head  = $self->{'entry'}->parse(qw(HEADER));
    $prot  = $self->{'entry'}->parse(qw(PROTEIN));
    $align = $self->{'entry'}->parse(qw(ALIGNMENT));

    push @hit, new Bio::MView::Build::Row::HSSP
	(
	 '',
	 $head->{'pdbid'},
	 $head->{'header'},
	 $self->chain,
	 $align->get_query($self->chain),
	);

    #extract cumulative scores and identifiers from the ranking and
    #corresponding sequences from the already parsed alignment.
    foreach $match (@{$prot->{'ranking'}}) {
	
	$rank++;
	
	#thanks to tof, 18-9-97
	if ($match->{'id'} =~ /\|/) {
	    #looks like a genequiz generated HSSP file
	    $id = $match->{'id'};
	} elsif ($match->{'accnum'}) {
	    #looks like a uniprot derived HSSP file
	    $id = "uniprot|$match->{'accnum'}|$match->{'id'}";
	} else {
	    #give up
	    $id = $match->{'id'};
	}

	#check row wanted, by rank OR identifier OR row count limit
	last  if ($use = $self->use_row($rank, $rank, $id)) < 0;
	next  unless $use;

	#warn "KEEP: ($rank,$id)\n";

	$seq = $align->get_sequence($rank, $self->chain);

	#skip empty alignments (aligned to different chain)
	next  if $seq =~ /^\s+$/;

	$seq =~ tr/ /-/;    #replace spaces with hyphens

	push @hit, new Bio::MView::Build::Row::HSSP(
						    $rank,
						    $id,
						    $match->{'protein'},
						    $self->chain,
						    $seq,
						   );
    }
    
    #map { $_->print } @hit;
    
    return \@hit;
}


###########################################################################
1;
