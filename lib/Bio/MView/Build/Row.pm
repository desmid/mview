# Copyright (C) 1997-2018 Nigel P. Brown

use strict;

###########################################################################
package Bio::MView::Build::Simple_Row;

use Bio::MView::Build::Row;
use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row);

#implements a row with an optional supplied sequence and no info labels
sub new {
    my $type = shift;
    my ($num, $id, $desc, $seq) = @_;

    my $self = new Bio::MView::Build::Row($num, $id, $desc);

    bless $self, $type;

    $self->add_frag($seq)  if defined $seq;

    $self;
}


###########################################################################
package Bio::MView::Build::Row;

use Bio::MView::Build::RowInfoMixin;
use Bio::MView::Sequence;
use Bio::MView::SRS;
use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::RowInfoMixin);

my $DEF_TEXTWIDTH = 30;  #default width to truncate 'text' field

sub new {
    my $type = shift;
    #warn "${type}::new(@_)\n";
    die "${type}::new: missing arguments\n"  if @_ < 3;
    my ($num, $id, $desc) = (shift, shift, shift);
    my $self = {};

    bless $self, $type;

    #strip non-identifier leading rubbish: > or /:
    $id =~ s/^(>|\/:)//;

    $self->{'rid'}  = $id;                      #raw identifier
    $self->{'uid'}  = $self->uniqid($num, $id); #unique identifier

    $id =~ s/^\#//;                             #comment: special row?
    $id = ' '  unless length($id) > 0;          #non-null for Build::map_id

    $self->{'cid'}  = $id;                      #cleaned identifier

    $self->{'num'}  = $num;                     #row number/string
    $self->{'desc'} = $desc;                    #description string
    $self->{'frag'} = [];                       #list of fragments
    $self->{'seq'}  = new Bio::MView::Sequence; #finished sequence
    $self->{'url'}  = Bio::MView::SRS::srsLink($self->{'cid'});  #url

    $self->save_info(@_);                       #other info

    $self;
}

######################################################################
# subclass overrides
######################################################################
sub posn1 { '' }  #first sequence range
sub posn2 { '' }  #second sequence range

#routine to sort 'frag' list: default is null
sub sort {$_[0]}

#compute the maximal positional range of a row
sub range {
    my $self = shift;
    my ($lo, $hi) = ($self->{'frag'}->[0][1], $self->{'frag'}->[0][2]);
    foreach my $frag (@{$self->{'frag'}}) {
        #warn "range: $frag->[1], $frag->[2]\n";
        $lo = $frag->[1]  if $frag->[1] < $lo;
        $lo = $frag->[2]  if $frag->[2] < $lo;
	$hi = $frag->[1]  if $frag->[1] > $hi;
	$hi = $frag->[2]  if $frag->[2] > $hi;
    }
    #warn "range: ($lo, $hi)\n";
    ($lo, $hi);
}

#assemble a row from sequence fragments
sub assemble {
    my ($self, $lo, $hi, $gap) = @_;
    my $reverse = 0;
    #get direction from first fragment range longer than 1
    foreach my $frag (@{$self->{'frag'}}) {
        $reverse = 0, last  if $frag->[1] < $frag->[2];
        $reverse = 1, last  if $frag->[1] > $frag->[2];
    }
    #warn "Row::assemble: [@_] $reverse\n";
    $self->sort;                                 #fragment order
    $self->{'seq'}->reverse  if $reverse;        #before calling insert()
    $self->{'seq'}->insert(@{$self->{'frag'}});  #assemble fragments
    $self->{'seq'}->set_range($lo, $hi);         #set sequence range
    $self->{'seq'}->set_pad($gap);
    $self->{'seq'}->set_gap($gap);
    $self;
}

######################################################################
# public methods
######################################################################
sub num   { $_[0]->{'num'} }
sub num0  { $_[0]->{'num'} ne '' ? $_[0]->{'num'} : '0' }

sub rid   { $_[0]->{'rid'} }
sub uid   { $_[0]->{'uid'} }
sub cid   { $_[0]->{'cid'} }

sub url   { $_[0]->{'url'} }
sub sob   { $_[0]->{'seq'} }

sub desc  { $_[0]->{'desc'} }  #row description
sub covr  { $_[0]->{'covr'} }  #percent coverage
sub pcid  { $_[0]->{'pcid'} }  #percent identity

#return the sequence string
sub seq {
    return ''  unless defined $_[0]->{'seq'};
    return $_[0]->{'seq'}->string
}

#return possibly truncated description
sub text {
    my $w = defined $_[1] ? $_[1] : $DEF_TEXTWIDTH;
    $w = length $_[0]->{'desc'}  if $w > length $_[0]->{'desc'};
    sprintf("%-${w}s", $_[0]->truncate($_[0]->{'desc'}, $w));
}

sub set_coverage { $_[0]->{'covr'} = $_[1] }
sub set_identity { $_[0]->{'pcid'} = $_[1] }

#convert nucleotide positions to a relative amino acid scale
sub translate_range {
    my ($self, $fm, $to) = @_;
    return (int(($fm+2)/3), int($to/3))   if $fm < $to;  #orientation +
    return (int($fm/3),  int(($to+2)/3))  if $fm > $to;  #orientation -
    die "translate_range: from == to  $fm, $to";
}

#add a sequence fragment to the 'frag' list with value and positions given
#by first three args. use default positions if called with one arg. other
#optional arguments are special to any subclass of Row.
sub add_frag {
    my $self = shift;
    my ($frag, $qry_from, $qry_to) = (shift, shift, shift);

    $qry_from = 1               unless defined $qry_from;
    $qry_to   = length $frag    unless defined $qry_to;

    push @{$self->{'frag'}}, [ \$frag, $qry_from, $qry_to, @_ ];

    #warn "@{$self->{'frag'}->[-1]}\n";

    $self;
}

######################################################################
# private methods
######################################################################
sub uniqid { "$_[1]\034/$_[2]" }

#truncate a string
sub truncate {
    my ($self, $s, $n, $t) = (@_, $DEF_TEXTWIDTH);
    $t = substr($s, 0, $n);
    substr($t, -3, 3) = '...'    if length $s > $n;
    $t;
}

######################################################################
# debug
######################################################################
sub dump {
    sub _format {
	my ($self, $k, $v) = @_;
	$v = 'undef' unless defined $v;
	$v = "'$v'" if $v =~ /^\s*$/;
	return sprintf("  %-15s => %s\n", $k, $v)
    }
    my $self = shift;
    warn "$self\n";
    map { warn $self->_format($_, $self->{$_}) } sort keys %{$self};
    $self;
}

sub frag_count { scalar @{$_[0]->{'frag'}} }

#sub DESTROY { warn "DESTROY $_[0]\n" }

###########################################################################
1;
