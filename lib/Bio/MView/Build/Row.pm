# Copyright (C) 1997-2015 Nigel P. Brown
# $Id: Row.pm,v 1.16 2015/06/14 17:09:04 npb Exp $

###########################################################################
package Bio::MView::Build::Row;

use Bio::MView::Sequence;

use strict;

my $DEF_IDWIDTH   = 20;  #default width to truncate 'id' field
my $DEF_TEXTWIDTH = 30;  #default width to truncate 'text' field
my $DEF_PAD = '-';       #default terminal gap character
my $DEF_GAP = '-';       #default internal gap character

sub new {
    my $type = shift;
    my ($num, $id, $desc, $seq) = (@_, undef);
    my $self = {};

    bless $self, $type;

    #strip non-identifier leading rubbish:  >  or /:
    $id =~ s/^(>|\/:)//;

    $self->{'rid'}  = $id;                      #supplied identifier
    $self->{'uid'}  = $self->uniqid($num, $id); #unique compound identifier
    
    #ensure identifier is non-null (for Build::map_id())
    $id = ' '  unless $id =~ /./;

    #set row 'subtype' information
    if ($id =~ /^\#/) {
	$self->{'type'} = 'special';  #leading hash: user supplied row
	$id =~ s/^\#//;               #and strip it
    } else {
	$self->{'type'} = undef;                    
    }

    $self->{'num'}  = $num;                     #row number/string
    $self->{'cid'}  = $id;                      #cleaned identifier
    $self->{'desc'} = $desc;                    #description string
    $self->{'frag'} = [];                       #list of fragments

    $self->{'seq'}  = new Bio::MView::Sequence; #finished sequence

    $self->add_frag($seq)    if defined $seq;

    $self->{'url'}  = Bio::SRS::srsLink($self->{'cid'});  #url

    $self;
}

#sub DESTROY { warn "DESTROY $_[0]\n" }

#methods returning standard strings for use in generic output modes
sub rid  { $_[0]->{'rid'} }
sub uid  { $_[0]->{'uid'} }
sub cid  { $_[0]->{'cid'} }
sub num  { $_[0]->{'num'} }
sub url  { $_[0]->{'url'} }
sub sob  { $_[0]->{'seq'} }

sub seq  {
    my ($self, $pad, $gap) = (@_, $DEF_PAD, $DEF_GAP);
    return ''  unless defined $self->{'seq'};
    $self->set_pad($pad);
    $self->set_gap($gap);
    return $self->{'seq'}->string
}

sub desc { $_[0]->{'desc'} }

sub head { '' }         #headers for labels
sub pcid { '' }         #identity %label
sub pcid_std { 'id%' }  #standard text for identity% label
sub data { '' }         #label values, per sequence row

sub text {
    my $w = defined $_[1] ? $_[1] : $DEF_TEXTWIDTH;
    $w = length $_[0]->{'desc'}    if $w > length $_[0]->{'desc'};
    sprintf("%-${w}s", $_[0]->truncate($_[0]->{'desc'}, $w));
}

sub posn1 { '' }
sub posn2 { '' }

#convert nucleotide positions to a relative amino acid scale
sub translate_range {
    my ($self, $fm, $to) = @_;
    return (int(($fm+2)/3), int($to/3))   if $fm < $to;  #orientation +
    return (int($fm/3),  int(($to+2)/3))  if $fm > $to;  #orientation -
    die "translate_range: from == to  $fm, $to";
}

sub uniqid { "$_[1]\034/$_[2]" }

sub print {
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

sub truncate {
    my ($self, $s, $n, $t) = (@_, $DEF_TEXTWIDTH);
    $t = substr($s, 0, $n);
    substr($t, -3, 3) = '...'    if length $s > $n;
    $t;
}

#routine to sort 'frag' list: default is null
sub sort {$_[0]}

#modify the extra 'type' information
sub set_subtype { $_[0]->{'type'} = $_[1] }

#add a sequence fragment to the 'frag' list with value and positions given
#by first three args. use default positions if called with one arg. other
#optional arguments are special to any subclass of Row.
sub add_frag {
    my $self = shift;
    my ($frag, $qry_from, $qry_to) = (shift, shift, shift);

    $qry_from = 1               unless defined $qry_from;
    $qry_to   = length $frag    unless defined $qry_to;

    push @{$self->{'frag'}}, [ \$frag, $qry_from, $qry_to, @_ ];

    #warn "@{$self->{'frag'}->[ $#{$self->{'frag'}} ]}\n";

    $self;
}

sub count_frag { scalar @{$_[0]->{'frag'}} }

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
    $self->{'seq'}->reverse  if $reverse;        #before calling append()
    $self->{'seq'}->append(@{$self->{'frag'}});  #assemble fragments
    $self->{'seq'}->set_range($lo, $hi);         #set sequence range
    $self->{'seq'}->set_pad($gap);
    $self->{'seq'}->set_gap($gap);
    $self;
}

sub set_pad { $_[0]->{'seq'}->set_pad($_[1]) }
sub set_gap { $_[0]->{'seq'}->set_gap($_[1]) }
sub set_spc { $_[0]->{'seq'}->set_spc($_[1]) }

sub plain {
    my ($self, $w, $pad, $gap) = (@_, $DEF_IDWIDTH, $DEF_PAD, $DEF_GAP);
    my $title = sprintf("%-${w}s", substr($self->cid, 0, $w));
    my $sequence = $self->seq($pad, $gap);
    $title . " " . $sequence . "\n";
}

sub pearson {
    my ($self, $pad, $gap) = (@_, $DEF_PAD, $DEF_GAP);
    my $MAXSEQ = 70;

    my $head = sub {
	my $self = shift;
	my $s = ">";
	#my $d = $self->num;
	#$s .= ((defined $d and $d ne '') ? "$d;" : "query;");
	$s .= $self->cid;
    };

    my $desc = sub {
	my $self = shift;
	my ($s, $d) = ('');
	$d = $self->desc;  $s .= " $d"  if $d ne '';
	$d = $self->data;  $s .= " $d"  if $d ne '';
	$d = $self->posn1; $s .= " $d"  if $d ne '';
	$d = $self->posn2; $s .= " $d"  if $d ne '';
	$s . "\n";
    };

    my $sequence = sub {
	my ($self, $pad, $gap) = @_;
	my $seq = $self->seq($pad, $gap);
	my $len = length($seq);
	my $s = '';
	for (my $i=0; $i<$len; $i+=$MAXSEQ) {
	    $s .= substr($seq, $i, $MAXSEQ) . "\n";
	}
	$s;
    };

    &$head($self) . &$desc($self) . &$sequence($self, $pad, $gap);
}

sub pir {
    my ($self, $moltype, $pad, $gap) = (@_, 'aa', $DEF_PAD, $DEF_GAP);
    my $MAXSEQ = 60;

    my $head = sub {
	my ($self, $moltype) = @_;
	my $s = $moltype eq 'aa' ? ">P1;" : ">XX;";
	#my $d = $self->num;
	#$s .= ((defined $d and $d ne '') ? "$d;" : "query;");
	$s .= $self->cid . "\n";
    };

    my $desc = sub {
	my $self = shift;
	my ($s, $d) = ('');
	$d = $self->desc;  $s .= ($s eq '' ? $d : " $d")  if $d ne '';
	$d = $self->data;  $s .= ($s eq '' ? $d : " $d")  if $d ne '';
	$d = $self->posn1; $s .= ($s eq '' ? $d : " $d")  if $d ne '';
	$d = $self->posn2; $s .= ($s eq '' ? $d : " $d")  if $d ne '';
	$s = '.'  if $s eq '';
	$s;
    };	

    my $sequence = sub {
	my ($self, $pad, $gap) = @_;
	my $seq = $self->seq($pad, $gap);
	my $len = length($seq);
	my $s = '';
	for (my $i=0; $i<$len; $i+=$MAXSEQ) {
	    $s .= "\n" . substr($seq, $i, $MAXSEQ);
	}
	$s .= "\n"    if length($s) % ($MAXSEQ+1) < 1 and $s ne '';
	$s .= "*\n\n";
    };

    &$head($self, $moltype) . &$desc($self) . &$sequence($self, $pad, $gap);
}

sub rdb {
    my ($self, $mode, $pad, $gap) = (@_, $DEF_PAD, $DEF_GAP);
    my @cols = ('row', 'id', 'desc', 'seq')  if $mode eq 'attr';
    @cols = ('4N', '30S', '500S', '500S') if $mode eq 'form';
    @cols = ($self->num, $self->cid, $self->desc, $self->seq($pad, $gap))
	if $mode eq 'data';
    my @new = $self->rdb_info($mode);     #subtype has any data?
    splice(@cols, -1, 0, @new)  if @new;  #insert penultimately
    #warn "[@cols]";
    return join("\t", @cols);
}

sub rdb_info {}  #override for format-specific columns


###########################################################################
1;
