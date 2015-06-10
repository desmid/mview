# Copyright (C) 1997-2015 Nigel P. Brown
# $Id: Build.pm,v 1.21 2015/01/24 21:22:42 npb Exp $

######################################################################
package Bio::MView::Build;

use Universal;
use NPB::Parse::Regexps;
use NPB::Parse::Stream;
use Bio::MView::Align;
use Bio::MView::Display;
use strict;

use vars qw();

my %Template = 
    (
     'entry'       => undef,   #parse tree ref
     'status'      => undef,   #parse status (undef=stop; otherwise=go)
     'align'       => undef,   #current alignment
     'index2row'   => undef,   #list of aligned rows, from zero
     'uid2row'     => undef,   #hash of aligned rows, by Build::Row->uid
     'ref_row'     => undef,   #reference row ref
     'topn'        => undef,   #show at most top N items
     'show'        => undef,   #actual number of rows to show
     'minident'    => undef,   #show items with at least minident %identity 
     'maxident'    => undef,   #show items with at most maxident %identity 
     'pcid'        => undef,   #identity calculation method
     'mode'        => undef,   #display format mode
     'ref_id'      => undef,   #reference id for %identity

     'skiplist'    => undef,   #discard rows by {num,id,regex}
     'keeplist'    => undef,   #keep rows by {num,id,regex}
     'nopslist'    => undef,   #no-process rows by {num,id,regex}

     'keep_uid'    => undef,   #hashed version of 'keeplist' by Row->uid
     'nops_uid'    => undef,   #hashed version of 'nopslist'  by Row->uid
     'hide_uid'    => undef,   #hashed merge of 'disc/keep/nops/' by Row->uid

     'range'       => undef,   #display lower/upper bounds (sequence numbering)
     'gap'         => undef,   #output sequence gap character
    );

my %Known_Parameter = 
    (
     #name        => [ format,     default   ]
     'topn'       => [ '\d+',      0         ],
     'minident'   => [ $RX_Ureal,  0         ],
     'maxident'   => [ $RX_Ureal,  100       ],
     'pcid'       => [ '\S+',      'aligned' ],
     'mode'       => [ '\S+',      'new'     ],
     'ref_id'     => [ '\S+',      0         ],
     'skiplist'   => [ [],         []        ],
     'keeplist'   => [ [],         []        ],
     'nopslist'   => [ [],         []        ],
     'range'      => [ [],         []        ],
     'gap'        => [ '\S',       '+'       ],
     'showpcid'   => [ '\d+',      1,        ],
    );

my %Known_Identity_Mode =
    (
     'reference'  => 1,
     'aligned'    => 1,
     'hit'        => 1,
    );

my %Known_Display_Mode =
    (
     #name
     'plain'      => 1,
     'fasta'      => 1,
     'clustal'    => 1,
     'pir'        => 1,
     'msf'        => 1,
     'rdb'        => 1,
    );

my %Known_HSP_Tiling =
    (
     'all'       => 1,
     'ranked'    => 1,
     'discrete'  => 1,
    );

sub new {
    my $type = shift;
    #warn "${type}::new(@_)\n";
    if (@_ < 1) {
	die "${type}::new() missing argument\n";
    }
    my $self = { %Template };

    $self->{'entry'} = shift;

    bless $self, $type;
    $self->initialise_parameters;
    $self;
}

#sub DESTROY { warn "DESTROY $_[0]\n" }

sub print {
    my $self = shift;
    local $_;
    foreach (sort keys %$self) {
	printf "%15s => %s\n", $_, $self->{$_};
    }
    print "\n";
    $self;
}

sub check_identity_mode {
    if (defined $_[0]) {
	if (exists $Known_Identity_Mode{$_[0]}) {
	    return lc $_[0];
	}
    }
    return map { lc $_ } sort keys %Known_Identity_Mode;
}

sub check_display_mode {
    if (defined $_[0]) {
	if (exists $Known_Display_Mode{$_[0]}) {
	    return lc $_[0];
	}
    }
    return map { lc $_ } sort keys %Known_Display_Mode;
}

sub check_hsp_tiling {
    if (defined $_[0]) {
	if (exists $Known_HSP_Tiling{$_[0]}) {
	    return lc $_[0];
	}
    }
    return map { lc $_ } sort keys %Known_HSP_Tiling;
}

sub initialise_parameters {
    my $self = shift;
    my ($p) = (@_, \%Known_Parameter);
    local $_;
    foreach (keys %$p) {
	#warn "initialise_parameters() $_\n";
	if (ref $p->{$_}->[0] eq 'ARRAY') {
	    $self->{$_} = [];
	    next;
	}
	if (ref $p->{$_}->[0] eq 'HASH') {
	    $self->{$_} = {};
	    next;
	}
	$self->{$_} = $p->{$_}->[1];
    }

    #reset how many rows to display
    $self->{'show'}     = $self->{'topn'};

    #generic alignment scheduler
    $self->{'status'}   = 1;

    $self;
}

sub set_parameters {
    my $self = shift;
    my $p = ref $_[0] ? shift : \%Known_Parameter;
    my ($key, $val);
    while ($key = shift) {
	$val = shift;
	if (exists $p->{$key}) {
	    #warn "set_parameters() $key, @{[defined $val ? $val : 'undef']}\n";
	    if (ref $p->{$key}->[0] eq 'ARRAY' and ref $val eq 'ARRAY') {
		$self->{$key} = $val;
		next;
	    }
	    if (ref $p->{$key}->[0] eq 'HASH' and ref $val eq 'HASH') {
		$self->{$key} = $val;
		next;
	    }
	    if (! defined $val) {
		#set default
		$self->{$key} = $p->{$key}->[1];
		next;
	    }
	    if ($val =~ /^$p->{$key}->[0]$/) {
		#matches expected format
		$self->{$key} = $val;
		next;
	    }
	    warn "${self}::set_parameters() bad value for '$key', got '$val', wanted '$p->{$key}->[0]'\n";
	}
	#ignore unrecognised parameters which may be recognised by subclass
	#set_parameters() methods.
    }

    #always reset when new parameters are given
    $self->{'status'} = 1;

    $self;
}

sub use_row { die "$_[0] use_row() virtual method called\n" }

#map an identifier supplied as {0..N|query|M.N} to a list of row objects in
#$self->{'index2row'}
sub map_id {
    my ($self, $ref) = @_;
    my ($i, @rowref) = ();

    #warn "map_id($ref)\n";

    for ($i=0; $i<@{$self->{'index2row'}}; $i++) {
	
	#major row number = query
	if ($ref =~ /^0$/) {
	    if ($self->{'index2row'}->[$i]->num eq '' or
		$self->{'index2row'}->[$i]->num eq $ref) {
		push @rowref, $self->{'index2row'}->[$i];
	    }
	    next;
	}
	
	#major row number
	if ($ref =~ /^\d+$/) {
	    #exact match
	    if ($self->{'index2row'}->[$i]->num eq $ref) {
		push @rowref, $self->{'index2row'}->[$i];
		next;
	    }
	    #match to major.minor prefix
	    if ($self->{'index2row'}->[$i]->num =~ /^$ref\./) {
		push @rowref, $self->{'index2row'}->[$i];
		next;
	    }
	    next;
	}
	
	#major.minor row number
	if ($ref =~ /^\d+\.\d+$/) {
	    if ($self->{'index2row'}->[$i]->num eq $ref) {
		push @rowref, $self->{'index2row'}->[$i];
	    }
	    next;
	}
	
	#string identifier
	if ($ref eq $self->{'index2row'}->[$i]->rid or 
	    $ref eq $self->{'index2row'}->[$i]->cid) {
	    push @rowref, $self->{'index2row'}->[$i];
	    next;
	}
	
	#regex inside // pair, applied case-insensitive
	if ($ref =~ /^\/.*\/$/) {
	    my $r = $ref;
	    $r =~ s/^\///; $r =~ s/\/$//;
	    if ($self->{'index2row'}->[$i]->cid =~ /$r/i) {
		#warn "map_id: [$i] /$r/ @{[$self->{'index2row'}->[$i]->cid]}\n";
		push @rowref, $self->{'index2row'}->[$i];
	    }
	    next;
	}

	#wildcard
	if ($ref =~ /^\*$/ or $ref =~ /^all$/i) {
	    push @rowref, $self->{'index2row'}->[$i];
	    next;
	}
	
    }
    #warn "${self}::map_id (@rowref)\n";
    return @rowref;
}

#override this to return list of parameters (key, val) pairs special to
#a particular instance (eg., specific to some parser)
sub change_parameters {()}

#allow instance to rebless an Bio::MView::Align object
sub change_alignment_type {}

sub get_entry { $_[0]->{'entry'} }

sub get_row_id {
    my ($self, $id) = @_;
    if (defined $id) {
	my @id = $self->map_id($id);
	return undef        unless @id;
	return $id[0]->uid  unless wantarray;
	return map { $_->uid } @id;
    }
    return undef;
}

sub get_row {
    my ($self, $id) = @_;
    if (defined $id) {
	my @id = $self->map_id($id);
	return undef   unless @id;
	return $id[0]  unless wantarray;
	return @id;
    }
    return undef;
}

sub uid2row   { $_[0]->{uid2row}->{$_[1]} }
sub index2row { $_[0]->{index2row}->[$_[1]] }

#construct a header string describing this alignment
sub header {
    my ($self, $quiet) = (@_, 0);
    my $s = '';
    return $s    if $quiet;
    if (defined $self->{'ref_row'}) {
	$s .= "Reference sequence ";
	if ($self->{'ref_row'}->num !~ /^\s*$/) {
	    $s .= "(" . $self->{'ref_row'}->num . ")";
	} else {
	    $s .= "(query)";
	}
	$s .= ": " . $self->{'ref_row'}->cid . "\n";
    }
    if ($self->{'minident'} > 0 and $self->{'maxident'} < 100) {
	$s .= "Pairwise identity limits: $self->{'minident'}-$self->{'maxident'}%";
	$s .= " normalised by $self->{'pcid'} length.\n";
    } elsif ($self->{'minident'} > 0) {
	$s .= "Minimum pairwise identity: $self->{'minident'}%";
	$s .= " normalised by $self->{'pcid'} length.\n";
    } elsif ($self->{'maxident'} < 100) {
	$s .= "Maximum pairwise identity: $self->{'maxident'}%";
	$s .= " normalised by $self->{'pcid'} length.\n";
    } elsif ($self->{'showpcid'}) {
	$s .= "Identities normalised by $self->{'pcid'} length.\n";
    }
    if ($self->{'topn'}) {
	$s .= "Maximum sequences to show: $self->{'topn'}\n";
    }
    Bio::MView::Display::displaytext($s);
}

sub subheader {''}

#generic one-pass scheduler for parsers. subclasses can override with more
#sophisticated parsers allowing reentry of their parse() method to extract
#different alignment subsets.
sub schedule {
    if (defined $_[0]->{'status'}) {
	$_[0]->{'status'} = undef;
	return 1;
    }
    $_[0]->{'status'};
}

#caller gets a sorted unique list of items from $range if present in
#$request. The special value 0 in $request means the 'last' item in $range.
#Used to convert lists of blast/fasta cycles, strands, frames into an
#ordered list of known tasks.
sub reset_schedule {
    my ($self, $range, $request) = @_;
    return  unless @$range;
    #warn "reset_schedule entry: [@$range] [@$request]\n";

    #empty request: schedule all
    return [ @$range ]  unless @$request;

    #make a dict of requested items for uniqueness
    my @items = (); my %tmp = ();
    map { $tmp{$_}++ } @$request;
    $tmp{$range->[-1]}++  if exists $tmp{0}; #0 means the 'last'

    #extact legitimate items in correct order
    foreach my $i (@$range) {
	push @items, $i  if exists $tmp{$i};
    }
    #warn "reset_schedule exit: [@items]\n";

    return \@items;
}

#return the next alignment, undef if no more work, or 0 if empty alignment
sub next {
    my $self = shift;

    #drop old data structures: GC *before* next assignment!
    $self->{'align'} = $self->{'index2row'} = undef;
    
    #extract an array of aligned row objects
    $self->{'index2row'} = $self->parse;
    #Universal::vmstat("Build->next(parse) done");

    #finished? note: "$self->{'align'}->free" is not needed
    return undef  unless defined $self->{'index2row'};

    #my $i; for ($i=0; $i < @{$self->{'index2row'}}; $i++) {
    #    warn "[$i]  ", $self->index2row($i)->num, " ",
    #	      $self->index2row($i)->cid, "\n";
    #}

    #this alignment empty?
    return 0  unless @{$self->{'index2row'}};

    $self->{'align'} = $self->build_alignment;
    #Universal::vmstat("Build->next(build_alignment) done");

    #maybe more data but this alignment empty? (identity filtered)
    return 0  unless defined $self->{'align'};
    return 0  unless $self->{'align'}->visible_ids > 0;

    return $self->{'align'};
}

sub build_alignment {
    my $self = shift;

    $self->build_indices;
    $self->build_rows;

    my $aln = $self->build_base_alignment;

    return undef  unless $aln->all_ids > 0;

SWITCH: {
	if ($self->{'mode'} eq 'new') {
	    $aln = $self->build_new_alignment($aln);
	    last;
	}
	last    if $self->{'mode'} eq 'none';  #for testing
	last    if $self->{'mode'} eq 'plain';
	last    if $self->{'mode'} eq 'pearson';
	last    if $self->{'mode'} eq 'clustal';
	last    if $self->{'mode'} eq 'pir';
	last    if $self->{'mode'} eq 'msf';
	last    if $self->{'mode'} eq 'rdb';
    
	die "${self}::alignment() unknown mode '$self->{'mode'}'\n";
    }

    $aln;
}

sub build_indices {
    my $self = shift;
    my ($i, $r, @id);

    $self->{'uid2row'}  = {};
    $self->{'keep_uid'} = {};
    $self->{'hide_uid'} = {};
    $self->{'nops_uid'} = {};

    #index the row objects by unique 'uid' for fast lookup.
    foreach $i (@{$self->{'index2row'}}) {
	$self->{'uid2row'}->{$i->uid} = $i;
    }
    
    #get the reference row handle, if any
    if (@id = $self->map_id($self->{'ref_id'})) {
	$self->{'ref_row'} = $id[0];
    }

    #make all skiplist rows invisible; this has to be done because some
    #may not really have been discarded at all, eg., reference row.
    foreach $i (@{$self->{'skiplist'}}) {
	@id = $self->map_id($i);
	foreach $r (@id) {
	    $self->{'hide_uid'}->{$r->uid} = 1;           #invisible
	}
    }

    #hash the keeplist and make all keeplist rows visible again
    foreach $i (@{$self->{'keeplist'}}) {
	@id = $self->map_id($i);
	foreach $r (@id) {
	    $self->{'keep_uid'}->{$r->uid} = 1;
	    delete $self->{'hide_uid'}->{$r->uid}  if
		exists $self->{'hide_uid'}->{$r->uid};    #visible
	}
    }

    #hash the reference row on the keeplist. don't override
    #any previous invisibility set by discard list.
    $self->{'keep_uid'}->{$self->{'ref_row'}->uid} = 1
	if defined $self->{'ref_row'};
    
    #hash the nopslist: the 'uid' key is used so that the
    #underlying Align class can recognise rows. don't override any previous
    #visibility set by discard list.
    foreach $i (@{$self->{'nopslist'}}) {
	@id = $self->map_id($i);
	foreach $r (@id) {
	    $self->{'nops_uid'}->{$r->uid}  = 1;
	}
    }
    #warn "ref:  ",$self->{'ref_row'}->uid, "\n" if defined $self->{'ref_row'};
    #warn "keep: [", join(",", sort keys %{$self->{'keep_uid'}}), "]\n";
    #warn "nops: [", join(",", sort keys %{$self->{'nops_uid'}}), "]\n";
    #warn "hide: [", join(",", sort keys %{$self->{'hide_uid'}}), "]\n";

    $self;
}

sub build_rows {
    my $self = shift;
    my ($lo, $hi, $i);

    #first, compute alignment length from query sequence in row[0]
    ($lo, $hi) = $self->set_range($self->{'index2row'}->[0]);

    #warn "range ($lo, $hi)\n";

    #assemble sparse sequence strings for all rows
    for ($i=0; $i < @{$self->{'index2row'}}; $i++) {
	#warn $self->{'index2row'}->[$i];
	$self->{'index2row'}->[$i]->assemble($lo, $hi, $self->{'gap'});
    }
    $self;
}

sub set_range {
    my ($self, $row) = @_;

    my ($lo, $hi) = $row->range;

    if (@{$self->{'range'}} and @{$self->{'range'}} % 2 < 1) {
	if ($self->{'range'}->[0] < $self->{'range'}->[1]) {
	    ($lo, $hi) = ($self->{'range'}->[0], $self->{'range'}->[1]);
	} else {
	    ($lo, $hi) = ($self->{'range'}->[1], $self->{'range'}->[0]);
	}
    }
    ($lo, $hi);
}

sub build_base_alignment {
    my $self = shift;
    my ($i, $row, $aln, @list) = ();
	
    for ($i=0; $i < @{$self->{'index2row'}}; $i++) {
	$row = $self->{'index2row'}->[$i];
	if (defined $row->{'type'}) {
	    $row = new Bio::MView::Align::Sequence($row->uid, $row->sob,
						   $row->{'type'});
	} else {
	    $row = new Bio::MView::Align::Sequence($row->uid, $row->sob);
	}
	push @list, $row;
    }

    $aln = new Bio::MView::Align(\@list);
    $aln->set_parameters('nopshash' => $self->{'nops_uid'},
			 'hidehash' => $self->{'hide_uid'});

    #filter alignment based on pairwise %identity, if requested
    if ($self->{'minident'} > 0 or $self->{'maxident'} < 100) {
	$aln = $aln->prune_all_identities($self->{'pcid'},
					  $self->{'minident'},
					  $self->{'maxident'},
					  $self->{'show'},
					  keys %{$self->{'keep_uid'}});
    }
    
    # foreach my $r ($aln->all_ids) {
    #     $aln->id2row($r)->seqobj->print;
    # }
    # warn "LEN: ", $aln->length;

    $aln;
}

sub build_new_alignment {
    my ($self, $aln) = @_;
    my ($i, $mrow, $arow);

    $aln->set_identity($self->{'ref_row'}->uid, $self->{'pcid'})
	if defined $self->{'ref_row'};

    for ($i=0; $i < @{$self->{'index2row'}}; $i++) {

	$mrow = $self->{'index2row'}->[$i];

	next  if exists $self->{'hide_uid'}->{$mrow->uid};

	$arow = $aln->item($mrow->uid);

	next  unless defined $arow;

	if (exists $self->{'nops_uid'}->{$mrow->uid} or
	    (defined $mrow->{'type'} and $mrow->{'type'} eq 'special')) {
	    $arow->set_display('label0' => '',
			       'label1' => $mrow->cid,
			       'label2' => $mrow->text,
			       'label3' => '',
			       'label4' => '',
			       'label5' => $mrow->posn1,
			       'label6' => $mrow->posn2,
			       'url'    => $mrow->url,
		);
	} else {
	    #don't change label4 (percent identity) here as this was
	    #already computed by $aln->set_identity() above.
	    $arow->set_display('label0' => $mrow->num,
			       'label1' => $mrow->cid,
			       'label2' => $mrow->text,
			       'label3' => $mrow->data,
			       #'label4' => '',###
			       'label5' => $mrow->posn1,
			       'label6' => $mrow->posn2,
			       'url'    => $mrow->url,
		);
	}
    }

    $aln;
}

#remove query and hit columns at gaps in the query sequence and downcase
#the bounding hit symbols in the hit sequence thus affected.
sub strip_query_gaps {
    my ($self, $query, $sbjct) = @_;
    my $i;

    #warn "sqg(in  q)=[$$query]\n";
    #warn "sqg(in  h)=[$$sbjct]\n";

    #no gaps in query
    return    if index($$query, '-') < 0;
    
    #iterate over query frag symbols
    while ( ($i = index($$query, '-')) >= 0 ) {
	
	#downcase preceding symbol in hit
	if (defined substr($$query, $i-1, 1)) {
	    substr($$sbjct, $i-1, 1) = lc substr($$sbjct, $i-1, 1);
	}
	
	#consume gap symbols in query and hit
	while (substr($$query, $i, 1) eq '-') {
	    substr($$query, $i, 1) = "";
	    substr($$sbjct, $i, 1) = "";
	}
	
	#downcase succeding symbol in hit
	if (defined substr($$query, $i, 1)) {
	    substr($$sbjct, $i, 1) = lc substr($$sbjct, $i, 1);
	}
	
	#warn "sqg(out q)=[$$query]\n";
	#warn "sqg(out h)=[$$sbjct]\n";
    }
    $self;
}

#given a ref to a list of parse() hits, remove any that have no positional
#data, finally removing the query itself if that's all that's left.
sub discard_empty_ranges {
    my ($self, $hit, $i) = @_;
    for ($i=1; $i<@$hit; $i++) {
#	warn "hit[$i]= $hit->[$i]->{'cid'} [", scalar @{$hit->[$i]->{'frag'}},"]\n";
	if (@{$hit->[$i]->{'frag'}} < 1) {
	    splice(@$hit, $i--, 1);
	}
    }
    pop @$hit    unless @$hit > 1;
    $self;
}

#return alignment in 'plain' format
sub plain {
    my $self = shift;
    my $s = '';
    foreach my $aln (@_) {
	foreach my $r ($aln->visible_ids) {
	    #warn "$aln [$r]\n";
	    $s .= $self->uid2row($r)->plain;
	}
    }
    $s;
}

#return alignment in Pearson/FASTA format
sub pearson {
    my $self = shift;
    my $s = '';
    foreach my $aln (@_) {
	foreach my $r ($aln->visible_ids) {
	    #warn "$aln [$r]\n";
	    $s .= $self->uid2row($r)->pearson;
	}
    }
    $s;
}

#return alignment in PIR format
sub pir {
    my ($self, $moltype) = (shift, shift);
    my $s = '';
    foreach my $aln (@_) {
	foreach my $r ($aln->visible_ids) {
	    #warn "$aln [$r]\n";
	    $s .= $self->uid2row($r)->pir($moltype);
	}
    }
    $s;
}

#return alignment in RDB table format
sub rdb {
    my $self = shift;
    my $s = $self->index2row(0)->rdb('attr') . "\n";
    $s .= $self->index2row(0)->rdb('form') . "\n";
    foreach my $aln (@_) {
	foreach my $r ($aln->visible_ids) {
	    #warn "$aln [$r]\n";
	    $s .= $self->uid2row($r)->rdb('data') . "\n";
	}
    }
    $s;
}

#return alignment in MSF format
sub msf {
    my $CHECKSUM = '--------------------------------------&---*---.-----------------@ABCDEFGHIJKLMNOPQRSTUVWXYZ------ABCDEFGHIJKLMNOPQRSTUVWXYZ---~---------------------------------------------------------------------------------------------------------------------------------';
    my ($MAXSEQ, $GAP) = (50, '.');
    
    my $checksum = sub {
	my $s = shift;
	my ($sum, $ch) = (0, 0);
	my $len = length($$s);
	while ($len--) {
	    $ch = ord substr($$s, $len, 1);
	    $ch = substr($CHECKSUM, $ch, 1);
	    $sum += (($len % 57) + 1) * ord $ch  if $ch ne '-';
	}
	$sum % 10000;
    };

    my ($self, $moltype) = (shift, shift);
    my $s = '';
    my $now = `date '+%B %d, %Y %H:%M'`;
    $now =~ s/\s0(\d{1})/ $1/; chomp $now;  #padding %-d may not work

    foreach my $aln (@_) {
	if ($moltype eq 'aa') {
	    $s .= "!!AA_MULTIPLE_ALIGNMENT 1.0\n";
	} else {
	    $s .= "!!NA_MULTIPLE_ALIGNMENT 1.0\n";
	}
	$s .= "PileUp (MView)\n\n";
	$s .= sprintf("   MSF: %5d  Type: %s  %s  Check: %4d  ..\n\n", 
		      $aln->length, ($moltype eq 'aa' ? 'P' : 'N'), $now, 0);

	my $w = 0;
	foreach my $r ($aln->visible_ids) {
	    $w = length($self->uid2row($r)->cid)
		if length($self->uid2row($r)->cid) > $w;
	}
	    
	foreach my $r ($aln->visible_ids) {
	    $s .=
		sprintf(" Name: %-${w}s Len: %5d  Check: %4d  Weight:  %4.2f\n",
			$self->uid2row($r)->cid, $aln->length, 
			&$checksum(\$self->uid2row($r)->seq), 1.0);
	}
	$s .= "\n//\n\n";

	my %seq = ();
	foreach my $r ($aln->visible_ids) {
	    $seq{$r} = $self->uid2row($r)->seq($GAP, $GAP);
	}
	
    LOOP:
	for (my $from = 0; ;$from += $MAXSEQ) {
	    my $ruler = 1;
	    foreach my $r ($aln->visible_ids) {
		last LOOP    if $from >= length($seq{$r});
		my $tmp = substr($seq{$r}, $from, $MAXSEQ);
		my $tmplen = length($tmp);
		if ($ruler) {
		    my $lo = $from + 1; my $hi = $from + $tmplen;
		    $ruler = $tmplen - length("$lo") - length("$hi");
		    $ruler = 1  if $ruler < 1;
		    my $insert = int($tmplen / 10);
		    $insert -= 1  if $tmplen % 10 == 0;
		    $insert += $ruler;
		    $insert = sprintf("%d%s%d", $lo, ' ' x $insert, $hi);
		    $s .= sprintf("%-${w}s $insert\n", '');
		    $ruler = 0;
		}
		$s .= sprintf("%-${w}s ", $self->uid2row($r)->cid);
		for (my $lo=0; $lo<$tmplen; $lo+=10) {
		    $s .= substr($tmp, $lo, 10);
		    $s .= ' '    if $lo < 40;
		}
		$s .= "\n";
	    }
	    $s .= "\n";
	}
    }
    $s;
}

#return alignment in CLUSTAL/aln format
sub clustal {
    my ($MAXSEQ, $MINNAME, $GAP) = (60, 16, '-');
    my ($RULER, $CONSERVATION) = (1, 1);

    my $symcount = sub {
	my ($s, $gap, $c) = (@_, 0);
	my @s = split('', $$s);
	for (my $i=0; $i<@s; $i++) {
	    $c += 1  unless $s[$i] eq $gap;
	}
	$c;
    };

    my ($self, $moltype) = (shift, shift);
    my $s = '';

    foreach my $aln (@_) {
	$s .= "CLUSTAL 2.1 multiple sequence alignment (MView)\n\n\n";

	my $w = $MINNAME;
	my @ids = $aln->visible_ids;
	my %seq = ();
	my %len = ();

	foreach my $r (@ids) {
	    #warn $r, $self->uid2row($r), "\n";
	    $w = length($self->uid2row($r)->cid)+1 if
		length($self->uid2row($r)->cid) >= $w;
	    $seq{$r} = $self->uid2row($r)->seq($GAP, $GAP);
	    $len{$r} = 0;
	}

      LOOP:
	for (my $from = 0; ;$from+=$MAXSEQ) {
	    foreach my $r ($aln->visible_ids) {
		last LOOP  if $from >= length($seq{$r});
		my $tmp = substr($seq{$r}, $from, $MAXSEQ);
		$s .= sprintf("%-${w}s", $self->uid2row($r)->cid);
		$s .= $tmp;
		if ($RULER) {
		    my $syms = &$symcount(\$tmp, $GAP);
		    my $hi = $len{$r} + $syms;
		    $s .= sprintf(" %-d", $hi)  if $syms > 0;
		    $len{$r} = $hi;
                }
                $s .= "\n";
            }

	    if ($CONSERVATION) {
		$s .= sprintf("%-${w}s", '');
		$s .= ${$self->{align}->conservation(\@ids,
						     $from+1, $from + $MAXSEQ,
						     $moltype)};
	    }
	    $s .= "\n\n";
	}
    }
    $s;
}


###########################################################################
1;
