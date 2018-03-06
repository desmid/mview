# Copyright (C) 1997-2018 Nigel P. Brown

######################################################################
package Bio::MView::Build;

use Universal;
use NPB::Parse::Regexps;
use NPB::Parse::Stream;
use Bio::MView::Option::Parameters;  #for $PAR
use Bio::MView::Align;
use Bio::MView::Display;
use Bio::MView::Build::Scheduler;
use strict;

my %Template =
    (
     'entry'       => undef,   #parse tree ref
     'align'       => undef,   #current alignment
     'index2row'   => undef,   #list of aligned rows, from zero
     'uid2row'     => undef,   #hash of aligned rows, by Build::Row->uid
     'ref_row'     => undef,   #reference row ref
     'show'        => undef,   #actual number of rows to show
     'aligned'     => undef,   #treat input as aligned
     'keep_uid'    => undef,   #hashed version of 'keeplist' by Row->uid
     'nops_uid'    => undef,   #hashed version of 'nopslist'  by Row->uid
     'hide_uid'    => undef,   #hashed merge of 'disc/keep/nops/' by Row->uid
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

    $self->initialise;

    $self;
}

#sub DESTROY { warn "DESTROY $_[0]\n" }

#override if children have a query sequence (children of Build::Search)
sub is_search {0}

#override if children need to do something special during creation
sub initialise {
    $_[0]->{scheduler} = new Bio::MView::Build::Scheduler;
    $_[0];
}

#override if children need to do something special before each iteration
sub reset_child {
    $_[0]->{scheduler}->filter;
    $_[0];
}

#return 1 if topn rows already generated, 0 otherwise; ignore if if filtering
#on identity; it is assumed the query is implicitly accepted anyway by the
#parser
sub topn_done {
    my ($self, $num) = @_;
    return 0  if $PAR->get('maxident') != 100;
    return 1  if $PAR->get('topn') > 0 and $num > $PAR->get('topn');
    return 0;
}

#return 1 is row should be ignored by row rank or identifier
sub skip_row { my $self = shift; ! $self->use_row(@_) }

#override in children
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

#Allow instance to rebless an Bio::MView::Align object and change
#parameter settings; used by Manager
sub adjust_parameters {}

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
    return ''  if $quiet;

    my $showpcid = $PAR->get('label5');
    my $minident = $PAR->get('minident');
    my $maxident = $PAR->get('maxident');
    my $pcidmode = $PAR->get('pcid');
    my $topn     = $PAR->get('topn');

    my $s = '';

    if (defined $self->{'ref_row'}) {
	$s .= "Reference sequence ";
	if ($self->{'ref_row'}->num !~ /^\s*$/) {
	    $s .= "(" . $self->{'ref_row'}->num . ")";
	} else {
	    $s .= "(query)";
	}
	$s .= ": " . $self->{'ref_row'}->cid . "\n";
    }
    if (0 < $minident and $maxident < 100) {
	$s .= "Identity limits: $minident-$maxident%";
	$s .= " normalised by $pcidmode length.\n";
    } elsif (0 < $minident) {
	$s .= "Minimum identity: $minident%";
	$s .= " normalised by $pcidmode length.\n";
    } elsif ($maxident < 100) {
	$s .= "Maximum identity: $maxident%";
	$s .= " normalised by $pcidmode length.\n";
    } elsif ($showpcid) {
	$s .= "Identities normalised by $pcidmode length.\n";
    }
    if ($topn) {
	$s .= "Maximum sequences to show: $topn\n";
    }
    Bio::MView::Display::displaytext($s);
}

sub reset {
    my $self = shift;

    $self->{'aligned'} = 0;

    #how many expected rows of alignment to show (1 more if search)
    $self->{'show'} = $PAR->get('topn');
    $self->{'show'} += $self->is_search  if $self->{'show'} > 0;

    $self->reset_child;
}

sub subheader {''}

#return the block of sequences, 0 if empty block, or undef if no more work
sub next {
    my $self = shift;

    #drop old data structures: GC *before* next assignment!
    $self->{'align'} = $self->{'index2row'} = undef;

    #extract an array of row objects
    $self->{'index2row'} = $self->parse;
    #Universal::vmstat("Build->next(parse) done");

    #finished? note: "$self->{'align'}->free" is not needed
    return undef  unless defined $self->{'index2row'};

    #my $i; for ($i=0; $i < @{$self->{'index2row'}}; $i++) {
    #    warn "[$i]  ", $self->index2row($i)->num, " ",
    #	      $self->index2row($i)->cid, "\n";
    #}

    #this block empty?
    return 0  unless @{$self->{'index2row'}};

    $self->{'align'} = $self->build_block;
    #Universal::vmstat("Build->next(build_block) done");

    #maybe more data but this alignment empty? (identity filtered)
    return 0  unless defined $self->{'align'};
    return 0  unless $self->{'align'}->visible_ids > 0;

    return $self->{'align'};
}

sub build_block {
    my $self = shift;

    my ($lo, $hi) = $self->get_range($self->{'index2row'}->[0]);

    #if not a search, do all rows have same range?
    my $aligned = 1;
    if ($self->isa('Bio::MView::Build::Align')) {
        for (my $i=1; $i < @{$self->{'index2row'}}; $i++) {
            my ($lo2, $hi2) = $self->get_range($self->{'index2row'}->[$i]);
            #warn "$self->{'index2row'}->[$i] ($lo2, $hi2)\n";
            $aligned = 0, last  if $lo != $lo2 or $hi != $hi2;
        }
    } else { #it's a search, so do we want sequence insertions?
        $aligned = 0  if $PAR->get('keepinserts');
    }
    $self->{'aligned'} = $aligned;

    #warn "KEEPINSERTS: " . $PAR->get('keepinserts') . "\n";
    #warn "ALIGNED:     $self->{'aligned'}\n";

    my $outfmt = $PAR->get('outfmt');

    if (!$self->{'aligned'} and !grep {$_ eq $outfmt} qw(fasta pearson pir)) {
        warn "Sequence lengths must be the same for output format '$outfmt' - aborting\n";
        return undef;
    }

    $self->build_indices;
    $self->build_rows($lo, $hi);

    my $aln = $self->build_base_alignment;

    return undef  unless $aln->all_ids > 0;

    if ($outfmt eq 'new') {
        $aln = $self->build_new_alignment($aln);
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
    if (@id = $self->map_id($PAR->get('ref_id'))) {
	$self->{'ref_row'} = $id[0];
    }

    #make all skiplist rows invisible; this has to be done because some
    #may not really have been discarded at all, eg., reference row.
    foreach $i (@{$PAR->get('skiplist')}) {
	@id = $self->map_id($i);
	foreach $r (@id) {
	    $self->{'hide_uid'}->{$r->uid} = 1;           #invisible
	}
    }

    #hash the keeplist and make all keeplist rows visible again
    foreach $i (@{$PAR->get('keeplist')}) {
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

    foreach $i (@{$PAR->get('nopslist')}) {
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
    my ($self, $lo, $hi) = @_;

    if ($self->{'aligned'}) {  #treat as alignment: common range
        for (my $i=0; $i < @{$self->{'index2row'}}; $i++) {
            #warn "Build::build_rows range[$i] ($lo, $hi)\n";
            $self->{'index2row'}->[$i]->assemble($lo, $hi, $PAR->get('gap'));
        }

    } else {  #treat as format conversion: each row has own range
        for (my $i=0; $i < @{$self->{'index2row'}}; $i++) {
            my ($lo, $hi) = $self->get_range($self->{'index2row'}->[$i]);
            #warn "Build::build_rows range[$i] ($lo, $hi)\n";
            $self->{'index2row'}->[$i]->assemble($lo, $hi, $PAR->get('gap'));
        }
    }
    $self;
}

sub get_range {
    my ($self, $row) = @_;
    my @range = @{$PAR->get('range')};
    if (@range and @range % 2 < 1) {
        return ($range[0], $range[1])  if $range[0] < $range[1];
        return ($range[1], $range[0]);
    }
    return $row->range;  #default
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

    $aln = new Bio::MView::Align(\@list, $self->{'aligned'});

    #filter alignment based on %identity to reference
    if ((0 < $PAR->get('minident') or $PAR->get('maxident') < 100)
        and defined $self->{'ref_row'}) {
        my $tmp = $aln->prune_identities($self->{'ref_row'}->uid,
                                         $PAR->get('pcid'),
                                         $PAR->get('minident'),
                                         $PAR->get('maxident'),
                                         $self->{'show'},
                                         keys %{$self->{'keep_uid'}});
        $aln = $tmp;
    }

    $aln->set_parameters('nopshash' => $self->{'nops_uid'},
                         'hidehash' => $self->{'hide_uid'});

    #compute columnwise data for aligned output
    unless ($PAR->get('keepinserts')) {
        if (defined $self->{'ref_row'}) {
            $aln->set_coverage($self->{'ref_row'}->uid);
            $aln->set_identity($self->{'ref_row'}->uid, $PAR->get('pcid'));
        }
    }

    #copy computed data into build row objects
    for (my $i=0; $i < @{$self->{'index2row'}}; $i++) {

	my $brow = $self->{'index2row'}->[$i];
	my $arow = $aln->item($brow->uid);

	next  unless defined $arow;

        $brow->set_coverage($arow->get_coverage);
        $brow->set_identity($arow->get_identity);
    }

    # foreach my $r ($aln->all_ids) {
    #     $aln->id2row($r)->seqobj->dump;
    # }
    # warn "LEN: ", $aln->length;
    $aln;
}

sub build_new_alignment {
    my ($self, $aln) = @_;

    for (my $i=0; $i < @{$self->{'index2row'}}; $i++) {

	my $brow = $self->{'index2row'}->[$i];

	next  if exists $self->{'hide_uid'}->{$brow->uid};

	my $arow = $aln->item($brow->uid);

	next  unless defined $arow;

	if (exists $self->{'nops_uid'}->{$brow->uid} or
	    (defined $brow->{'type'} and $brow->{'type'} eq 'special')) {

	    $arow->set_display('label0' => '',
			       'label1' => $brow->cid,
			       'label2' => $brow->text,
			       'label3' => '',
			       'label4' => '',
			       'label5' => '',
			       'label6' => $brow->posn1,
			       'label7' => $brow->posn2,
			       'url'    => $brow->url,
		);
	} else {
            my $values = [ $brow->display_column_values ];

            #warn "\n[@$values]\n";

            $arow->set_display(
                'label0' => $values->[0],
                'label1' => $values->[1],
                'label2' => $values->[2],
                'label3' => $values->[3],
                'label4' => $values->[4],
                'label5' => $values->[5],
                'label6' => $values->[6],
                'label7' => $values->[7],
                'url'    => $brow->url,
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
	
	#downcase succeeding symbol in hit
	if (defined substr($$query, $i, 1)) {
	    substr($$sbjct, $i, 1) = lc substr($$sbjct, $i, 1);
	}
	
	#warn "sqg(out q)=[$$query]\n";
	#warn "sqg(out h)=[$$sbjct]\n";
    }
    $self;
}


###########################################################################
1;
