# Copyright (C) 1997-2006 Nigel P. Brown
# $Id: Search.pm,v 1.12 2015/06/18 21:26:11 npb Exp $

###########################################################################
package Bio::MView::Build::Search;

use Bio::MView::Build;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::MView::Build);

#there's a query sequence to account for an extra row
sub has_query {1}

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


###########################################################################
package Bio::MView::Build::Search::Collector;

my $QUERY = 0;
my $DELIM = '.';

sub new {
    my $type = shift;
    my $self = {};
    bless $self, $type;

    $self->{parent} = shift;
    $self->{keys} = {};
    $self->{list} = [];

    $self;
}

sub key {
    my $self = shift;
    join($DELIM, @_);
}

sub insert {
    my ($self, $item) = (shift, shift);
    push @_, $QUERY  unless @_;
    foreach my $key (@_) {
        #allow this
        #warn "insert: key already exists '$key'\n"
        #    if exists $self->{keys}->{$key};
        $self->{keys}->{$key} = scalar @{$self->{list}};
    }
    push @{$self->{list}}, $item;
    $self;
}

sub has {
    my ($self, $key) = @_;
    return 1  if exists $self->{keys}->{$key};
    return 0;
}

sub item {
    my ($self, $key) = @_;
    die "get: unknown key '$key'\n"  unless exists $self->{keys}->{$key};
    $self->{list}->[ $self->{keys}->{$key} ];
}

sub add_frags {
    my ($self, $key, $qf, $qt, $qdata, $hdata) = @_;
    my ($q, $q1, $q2, @qrest) = @$qdata;
    #warn "[$q1, $q2, @qrest]\n";
    $self->item($QUERY)->add_frag($q, $qf,$qt, $q1,$q2, 0,0, @qrest);
    my ($h, $h1, $h2, @hrest) = @$hdata;
    #warn "[$h1, $h2, @hrest]\n";
    $self->item($key)->add_frag($h, $qf,$qt, $q1,$q2, $h1,$h2, @hrest);
    $self;
}

sub list {
    my $self = shift;
    $self->_discard_empty_ranges;
    $self->{list};
}

#remove hits lacking positional data; finally remove the query itself if
#that's all that's left
sub _discard_empty_ranges {
    my $self = shift;
    my $hit = $self->{list};
    for (my $i=1; $i<@$hit; $i++) {
        #warn "hit[$i]= $hit->[$i]->{'cid'} [", scalar @{$hit->[$i]->{'frag'}},"]\n";
	if (@{$hit->[$i]->{'frag'}} < 1) {
	    splice(@$hit, $i--, 1);
	}
    }
    pop @$hit  unless @$hit > 1;
    $self;
}

sub dump {
    my $self = shift;
    warn "Collector:\n";
    warn "keys: @{[scalar keys %{$self->{keys}}]} list: @{[scalar @{$self->{list}}]}\n";
    foreach my $k (sort { $self->{keys}->{$a} <=> $self->{keys}->{$b} } keys %{$self->{keys}}) {
        my $i = $self->{keys}->{$k};
        warn "[$self->{keys}->{$k}] <= $k => $self->{list}->[$i]\n";
    }
}


###########################################################################
1;
