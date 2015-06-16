# Copyright (C) 1997-2015 Nigel P. Brown
# $Id: Search.pm,v 1.11 2015/06/16 16:29:31 npb Exp $

###########################################################################
package Bio::MView::Build::Search;

use vars qw(@ISA);
use Bio::MView::Build;
use strict;

@ISA = qw(Bio::MView::Build);

#allow (query+$topn) items, unless $topn is zero
sub set_parameters {
    my $self = shift;
    $self->SUPER::set_parameters(@_);
    $self->{'show'} = $self->{'topn'};
    $self->{'show'}++  if $self->{'show'} > 0;
}

sub use_row {
    my ($self, $num, $nid, $sid) = @_;
    my $pat;

    #warn "use_row($num, $nid, $sid)  $self->{'topn'}  $self->{'maxident'}\n";
    
    #only read $self->{'topn'} hits, if set and if not filtering on identity;
    #it is assumed the query is implicitly accepted anyway by the parser
    return -1
	if $self->{'topn'} > 0 and
	    $num > $self->{'topn'} and
		$self->{'maxident'} == 100;

    #first, check explicit keeplist and reference row
    foreach $pat (@{$self->{'keeplist'}}, $self->{'ref_id'}) {

	#Search subclass only
	return 1  if $pat eq '0'     and $num == 0;
	return 1  if $pat eq 'query' and $num == 0;

	#look at row number
	return 1  if $nid eq $pat;      #major OR major.minor
	if ($nid =~ /^\d+$/ and $pat =~ /^(\d+)\./) {
	    #major matched by major.*
	    return 1  if $nid eq $1;
	} elsif ($pat =~ /^\d+$/ and $nid =~ /^(\d+)\./) {
	    #major.* matched by major
	    return 1  if $1 eq $pat;
	}
	
	#look at identifier
	return 1  if $sid eq $pat;      #exact match
	if ($pat =~ /^\/(.*)\/$/) {     #regex match (case insensitive)
	    return 1  if $sid =~ /$1/i;
	}
    }

    #second, check skiplist and reference row
    foreach $pat (@{$self->{'skiplist'}}, $self->{'ref_id'}) {

	#Search subclass only
	return 0  if $pat eq '0'     and $num == 0;
	return 0  if $pat eq 'query' and $num == 0;

	#look at row number
	return 0  if $nid eq $pat;      #major OR major.minor
	if ($nid =~ /^\d+$/ and $pat =~ /^(\d+)\./) {
	    #major matched by major.*
	    return 0  if $nid eq $1;
	} elsif ($pat =~ /^\d+$/ and $nid =~ /^(\d+)\./) {
	    #major.* matched by major
	    return 0  if $1 eq $pat;
	}
	
	#look at identifier
	return 0  if $sid eq $pat;      #exact match
	if ($pat =~ /^\/(.*)\/$/) {     #regex match (case insensitive)
	    return 0  if $sid =~ /$1/i;
	}
    }

    #assume implicit membership of keeplist
    return 1;    #default
}

sub map_id {
    my ($self, $ref) = @_;
    $ref = 0  if $ref =~ /query/i;
    $self->SUPER::map_id($ref);
}

#given a ref to a list of parse() hits, remove any lacking positional data;
#finally remove the query itself if that's all that's left
sub discard_empty_ranges {
    my ($self, $hit) = @_;
    for (my $i=1; $i<@$hit; $i++) {
        #warn "hit[$i]= $hit->[$i]->{'cid'} [", scalar @{$hit->[$i]->{'frag'}},"]\n";
	if (@{$hit->[$i]->{'frag'}} < 1) {
	    splice(@$hit, $i--, 1);
	}
    }
    pop @$hit  unless @$hit > 1;
    $self;
}


###########################################################################
1;
