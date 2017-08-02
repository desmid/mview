# Copyright (C) 1997-2017 Nigel P. Brown

###########################################################################
package Bio::MView::Build::Row;

use Bio::MView::Sequence;

use strict;

my $DEF_TEXTWIDTH = 30;  #default width to truncate 'text' field

sub new {
    my $type = shift;
    my ($num, $id, $desc) = splice @_, 0, 3;
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

    $self->{'url'}  = Bio::SRS::srsLink($self->{'cid'});  #url

    $self->{'data'} = {};                       #other parsed info

    $self->save_info(@_);

    $self;
}

#sub DESTROY { warn "DESTROY $_[0]\n" }

sub uniqid { "$_[1]\034/$_[2]" }

#methods returning standard strings for use in generic output modes
sub rid   { $_[0]->{'rid'} }
sub uid   { $_[0]->{'uid'} }
sub cid   { $_[0]->{'cid'} }
sub num   { $_[0]->{'num'} }
sub url   { $_[0]->{'url'} }
sub sob   { $_[0]->{'seq'} }

sub desc  { $_[0]->{'desc'} } #row description

sub covr  { $_[0]->{'covr'} } #percent coverage
sub pcid  { $_[0]->{'pcid'} } #percent identity

sub posn1 { '' }              #first sequence range
sub posn2 { '' }              #second sequence range

sub seq {                     #the sequence
    my $self = shift;
    return ''  unless defined $self->{'seq'};
    return $self->{'seq'}->string
}

sub text {                    #possibly truncated description
    my $w = defined $_[1] ? $_[1] : $DEF_TEXTWIDTH;
    $w = length $_[0]->{'desc'}  if $w > length $_[0]->{'desc'};
    sprintf("%-${w}s", $_[0]->truncate($_[0]->{'desc'}, $w));
}

sub set_coverage {
    my ($self, $val) = @_;
    $self->{'covr'} = $val;
}

sub set_identity {
    my ($self, $val) = @_;
    $self->{'pcid'} = $val;
}

#convert nucleotide positions to a relative amino acid scale
sub translate_range {
    my ($self, $fm, $to) = @_;
    return (int(($fm+2)/3), int($to/3))   if $fm < $to;  #orientation +
    return (int($fm/3),  int(($to+2)/3))  if $fm > $to;  #orientation -
    die "translate_range: from == to  $fm, $to";
}

#truncate a string
sub truncate {
    my ($self, $s, $n, $t) = (@_, $DEF_TEXTWIDTH);
    $t = substr($s, 0, $n);
    substr($t, -3, 3) = '...'    if length $s > $n;
    $t;
}

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

    #warn "@{$self->{'frag'}->[-1]}\n";

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
    $self->{'seq'}->reverse  if $reverse;        #before calling insert()
    $self->{'seq'}->insert(@{$self->{'frag'}});  #assemble fragments
    $self->{'seq'}->set_range($lo, $hi);         #set sequence range
    $self->{'seq'}->set_pad($gap);
    $self->{'seq'}->set_gap($gap);
    $self;
}

###########################################################################

sub schema { [] }  #default schema is empty

#convenience functions for column headers: eliminate eventually
sub lbl_data { $_[0]->data('attr'); }
sub lbl_covr { 'cov' }
sub lbl_pcid { 'pid' }

#save row information following a schema
sub save_info {
    my $self = shift;
    #warn "save_info: [@_]\n";

    my $schema = $self->schema;
    return $self  unless @$schema;

    for (my $i=0; $i<@$schema; $i++) {
        my ($n0, $n1, $name, $label, $format, $default) = @{$schema->[$i]};
        #warn "save: $name\n";
        $self->{'data'}->{$name} = defined $_[$i] ? $_[$i] : $default;
    }
    $self;
}

#set a row information attribute if in the schema
sub set_val {
    my ($self, $key, $val) = @_;
    #warn "set_val: [$key => $val]\n";

    my $schema = $self->schema;
    return $self  unless @$schema;

    foreach my $row (@$schema) {
        my ($n0, $n1, $name, $label, $format, $default) = @$row;
        $self->{'data'}->{$name} = $val, return $self  if $key eq $name;
        $self->{'data'}->{$name} = $val, return $self  if $key eq $label;
    }
    warn "@{[ref $self]}::set_val: unknown attribute '$key'\n";
    $self;
}

#test if item has attribute
sub has {
    my ($self, $key) = @_;
    #warn "has: [$key]\n";

    my $schema = $self->schema;

    return exists $self->{$key}  unless @$schema;

    foreach my $row (@$schema) {
        my ($n0, $n1, $name, $label, $format, $default) = @$row;
        return 1  if $key eq $name;
        return 1  if $key eq $label;
    }
    0; #no key
}

#get a row information attribute if in the schema
sub get_val {
    my ($self, $key) = @_;
    #warn "get_val: [$key]\n";

    my $schema = $self->schema;

    if (@$schema < 1) {
        return $self->{$key}  if exists $self->{$key};
        return '';
    }

    foreach my $row (@$schema) {
        my ($n0, $n1, $name, $label, $format, $default) = @$row;
        return $self->{'data'}->{$name}  if $key eq $name;
        return $self->{'data'}->{$name}  if $key eq $label;
    }
    warn "@{[ref $self]}::get_val: unknown attribute '$key'\n";
    '';
}

#return a concatenated string of formatted schema data
sub data {
    my ($self, $mode, $delim) = (@_, ' ');

    my $fmtstr = sub {
        my $fmt = shift;
        $fmt =~ /(\d+)(\S)/o;
        return "%-$1s"  if $2 eq 'S';
        return "%$1s";
    };

    my $schema = $self->schema;

    my @tmp = ();
    foreach my $row (sort { $a->[0] <=> $b->[0] } @$schema) {
        my ($n0, $n1, $name, $label, $format, $default) = @$row;

        next  unless $n0;  #ignore row

        my $fmt = &$fmtstr($format);
        if ($mode eq 'data') {
            my $data = $self->{'data'}->{$name};
            #warn "data: $name => [$data]\n";
            push(@tmp, sprintf($fmt, $data));
            next;
        }
        push(@tmp, sprintf($fmt, $label)),  next  if $mode eq 'attr';
        push(@tmp, sprintf($fmt, $format)), next  if $mode eq 'form';
    }
    join($delim, @tmp);
}

#return a list of schema data
sub rdb_data {
    my ($self, $mode) = (@_);

    my $schema = $self->schema;

    my @tmp = ();
    foreach my $row (sort { $a->[1] <=> $b->[1] } @$schema) {
        my ($n0, $n1, $name, $label, $format, $default) = @$row;

        next  unless $n1;  #ignore row

        if ($mode eq 'data') {
            my $data = $self->{'data'}->{$name};
            #warn "rdb_data: $name => $data\n";
            push(@tmp, $data);
            next;
        }
        push(@tmp, $label),  next  if $mode eq 'attr';
        push(@tmp, $format), next  if $mode eq 'form';
    }
    @tmp;
}

#tabulated rdb output
sub rdb_row {
    my ($self, $mode, $pad, $gap) = @_;
    my @cols = ();
    if ($mode eq 'data') {
        @cols = ($self->num, $self->cid, $self->desc, $self->rdb_data($mode),
                 $self->covr, $self->pcid, $self->seq($pad, $gap));
    }
    elsif ($mode eq 'attr') {
        @cols = ('row', 'id', 'desc', $self->rdb_data($mode),
                 'cov', 'pid', 'seq');
    }
    elsif ($mode eq 'form') {
        @cols = ('4N', '30S', '500S', $self->rdb_data($mode),
                 '6N', '6N', '500S');
    }
    #warn "[@cols]";
    join("\t", @cols);
}

#tabulated rdb output
sub rdb_row_no_description {
    my ($self, $mode, $pad, $gap) = @_;
    my @cols = ();
    if ($mode eq 'data') {
        @cols = ($self->num, $self->cid, $self->rdb_data($mode),
                 $self->covr, $self->pcid, $self->seq($pad, $gap));
    }
    elsif ($mode eq 'attr') {
        @cols = ('row', 'id', $self->rdb_data($mode), 'cov', 'pid', 'seq');
    }
    elsif ($mode eq 'form') {
        @cols = ('4N', '30S', $self->rdb_data($mode), '6N', '6N', '500S');
    }
    #warn "[@cols]";
    join("\t", @cols);
}

#tabulated rdb output
sub rdb_row_search {
    my ($self, $mode, $pad, $gap) = @_;
    my @cols = ();
    if ($mode eq 'data') {
        @cols = ($self->num, $self->cid, $self->desc, $self->rdb_data($mode),
                 $self->covr, $self->pcid, $self->posn1, $self->posn2,
                 $self->seq($pad, $gap),);
    }
    elsif ($mode eq 'attr') {
        @cols = ('row', 'id', 'desc', $self->rdb_data($mode), 'cov', 'pid',
                 'query', 'sbjct', 'seq');
    }
    elsif ($mode eq 'form') {
        @cols = ('4N', '30S', '500S', $self->rdb_data($mode), '6N', '6N',
                 '15S', '15S', '500S');
    }
    #warn "[@cols]";
    join("\t", @cols);
}


###########################################################################
package Bio::MView::Build::Simple_Row;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row);

sub new {
    my $type = shift;
    my ($num, $id, $desc, $seq) = @_;
    my $self = new Bio::MView::Build::Row($num, $id, $desc);
    bless $self, $type;
    $self->add_frag($seq)  if defined $seq;
    $self;
}


###########################################################################
1;
