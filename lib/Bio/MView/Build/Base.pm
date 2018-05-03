# Copyright (C) 1997-2018 Nigel P. Brown

use strict;

######################################################################
package Bio::MView::Build::Base;

use Bio::Util::System qw(vmstat);
use Bio::MView::Option::Parameters;  #for $PAR
use Bio::MView::Build::Scheduler;
use Bio::MView::Align::Alignment;

sub new {
    my $type = shift;
    #warn "${type}::new(@_)\n";
    die "${type}::new() missing argument\n"  if @_ < 1;
    my $entry = shift;

    my $self = {};
    bless $self, $type;

    $self->{'entry'}     = $entry;  #parse tree ref
    $self->{'align'}     = undef;   #current alignment
    $self->{'index2row'} = undef;   #list of aligned rows, from zero
    $self->{'uid2row'}   = undef;   #hash of aligned rows; by Build::Row->uid
    $self->{'ref_row'}   = undef;   #reference row ref
    $self->{'topn'}      = undef;   #actual number of rows to show
    $self->{'aligned'}   = undef;   #treat input as aligned
    $self->{'keep_uid'}  = undef;   #hash 'keeplist' by Row->uid
    $self->{'nops_uid'}  = undef;   #hash 'nopslist' by Row->uid
    $self->{'hide_uid'}  = undef;   #hash merge 'disc/keep/nops/' by Row->uid

    $self->initialise;

    $self;
}

######################################################################
# public methods
######################################################################
#override if children have a query sequence (children of Build::Search)
sub is_search { 0 }

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
sub skip_row { my $self = shift; return ! $self->use_row(@_) }

sub get_entry { return $_[0]->{'entry'} }

sub get_row_from_id {
    my ($self, $id) = @_;
    if (defined $id) {
	my @id = $self->map_id($id);
	return undef   unless @id;
	return $id[0]  unless wantarray;
	return @id;
    }
    return undef;
}

sub get_uid_from_id {
    my ($self, $id) = @_;
    if (defined $id) {
	my @id = $self->map_id($id);
	return undef        unless @id;
	return $id[0]->uid  unless wantarray;
	return map { $_->uid } @id;
    }
    return undef;
}

sub uid2row   { $_[0]->{uid2row}->{$_[1]} }
sub index2row { $_[0]->{index2row}->[$_[1]] }

sub reset {
    my $self = shift;

    $self->{'aligned'} = 0;

    #how many expected rows of alignment to show (1 more if search)
    $self->{'topn'} = $PAR->get('topn');
    $self->{'topn'} += $self->is_search  if $self->{'topn'} > 0;

    $self->reset_child;
}

#return the block of sequences, 0 if empty block, or undef if no more work
sub next_align {
    my $self = shift;

    #drop old data structures: GC *before* next assignment!
    $self->{'align'} = $self->{'index2row'} = undef;

    #extract an array of row objects
    $self->{'index2row'} = $self->parse;
    #vmstat("Build->next(parse) done");

    #finished?
    return undef  unless defined $self->{'index2row'};

    #for (my $i=0; $i < @{$self->{'index2row'}}; $i++) {
    #    warn "[$i]  ", $self->index2row($i)->num, " ",
    #	      $self->index2row($i)->cid, "\n";
    #}

    #this block empty?
    return 0  unless @{$self->{'index2row'}};

    $self->{'align'} = $self->build_block;
    #vmstat("Build->next(build_block) done");

    #maybe more data but this alignment empty? (identity filtered)
    return 0  unless defined $self->{'align'};
    return 0  unless $self->{'align'}->visible_ids > 0;

    return $self->{'align'};
}

#subclass overrides
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

    return $s;
}

#subclass overrides
sub subheader {''}

######################################################################
# protected methods
######################################################################
#subclass overrides: if children need to do something during creation
sub initialise { $_[0]->{scheduler} = new Bio::MView::Build::Scheduler }

#subclass overrides: if children need to do something before each iteration
sub reset_child { $_[0]->{scheduler}->filter }

#subclass overrides: must be overridden
sub use_row { die "$_[0] use_row: virtual method called\n" }

#subclass overrides: must be overridden
sub test_if_aligned { die "$_[0] use_row: virtual method called\n" }

#subclass overrides: map an identifier supplied as {0..N|query|M.N} to
#a list of row objects in $self->{'index2row'}
sub map_id {
    my ($self, $id) = @_;
    my @rowref = ();
    #warn "map_id($id)\n";
    foreach my $row (@{$self->{'index2row'}}) {
        push @rowref, $row  if $row->matches_id($id);
    }
    #warn "${self}::map_id (@rowref)\n";
    return @rowref;
}

#subclass overrides
sub build_rows {
    my ($self, $lo, $hi) = @_;
    foreach my $row (@{$self->{'index2row'}}) {
        unless ($self->{'aligned'}) {
            ($lo, $hi) = $self->get_range($row);
        }
        #warn "Build::build_rows range ($lo, $hi)\n";
        $row->assemble($lo, $hi, $PAR->get('gap'));
    }
}

#subclass overrides
sub get_range {
    my ($self, $row) = @_;
    my @range = @{$PAR->get('range')};
    if (@range and @range % 2 < 1) {
        return ($range[0], $range[1])  if $range[0] < $range[1];
        return ($range[1], $range[0]);
    }
    return $row->range;  #default
}

#subclass overrides
sub rebless_alignment {}

#subclass overrides: remove query and hit columns at gaps in the query
#sequence and downcase the bounding hit symbols in the hit sequence thus
#affected.
sub strip_query_gaps {
    my ($self, $query, $sbjct) = @_;

    #warn "sqg(in  q)=[$$query]\n";
    #warn "sqg(in  h)=[$$sbjct]\n";

    #no gaps in query
    return    if index($$query, '-') < 0;

    #iterate over query frag symbols
    while ( (my $i = index($$query, '-')) >= 0 ) {

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

######################################################################
# private methods
######################################################################
sub is_aligned { return $_[0]->{'aligned'} == 1 }
sub is_hidden  { return exists $_[0]->{'hide_uid'}->{$_[1]} }
sub is_nop     { return exists $_[0]->{'nops_uid'}->{$_[1]} }

sub outfmt_supported {
    my ($self, $fmt) = @_;
    return 1  if $self->is_aligned;
    return 1  if grep {$_ eq $fmt} qw(fasta pearson pir);
    return 0;
}

sub build_block {
    my $self = shift;

    my ($lo, $hi) = $self->get_range($self->{'index2row'}->[0]);

    $self->{'aligned'} = $self->test_if_aligned($lo, $hi);

    #warn "KEEPINSERTS: @{[$PAR->get('keepinserts')]}\n";
    #warn "ALIGNED:     $self->{'aligned'}\n";

    my $outfmt = $PAR->get('outfmt');

    unless ($self->outfmt_supported($outfmt)) {
        warn "Sequence lengths differ for output format '$outfmt' - aborting\n";
        return undef;
    }

    $self->build_indices;
    $self->build_rows($lo, $hi);

    my $aln = new Bio::MView::Align::Alignment($self, undef);

    $self->rebless_alignment($aln);  #allow child to change type

    $aln = $self->build_base_alignment($aln);

    return undef  unless $aln->size > 0;

    $self->build_mview_alignment($aln)  if $outfmt eq 'mview';

    return $aln;
}

sub build_indices {
    my $self = shift;

    $self->{'uid2row'}  = {};
    $self->{'keep_uid'} = {};
    $self->{'hide_uid'} = {};
    $self->{'nops_uid'} = {};

    #index the row objects by unique 'uid' for fast lookup
    foreach my $i (@{$self->{'index2row'}}) {
	$self->{'uid2row'}->{$i->uid} = $i;
    }

    #get the reference row handle, if any
    if (my @id = $self->map_id($PAR->get('ref_id'))) {
	$self->{'ref_row'} = $id[0];
    }

    #make all skiplist rows invisible; this has to be done because some
    #may not really have been discarded at all, eg., reference row
    foreach my $i (@{$PAR->get('skiplist')}) {
	my @id = $self->map_id($i);
	foreach my $r (@id) {
	    $self->{'hide_uid'}->{$r->uid} = 1;         #invisible
	}
    }

    #hash the keeplist and make all keeplist rows visible again
    foreach my $i (@{$PAR->get('keeplist')}) {
	my @id = $self->map_id($i);
	foreach my $r (@id) {
	    $self->{'keep_uid'}->{$r->uid} = 1;
	    delete $self->{'hide_uid'}->{$r->uid}  if
		exists $self->{'hide_uid'}->{$r->uid};  #visible
	}
    }

    #hash the reference row on the keeplist. don't override
    #any previous invisibility set by discard list.
    $self->{'keep_uid'}->{$self->{'ref_row'}->uid} = 1
	if defined $self->{'ref_row'};

    #hash the nopslist: the 'uid' key is used so that the
    #underlying Align class can recognise rows; don't override any previous
    #visibility set by discard list
    foreach my $i (@{$PAR->get('nopslist')}) {
	my @id = $self->map_id($i);
	foreach my $r (@id) {
	    $self->{'nops_uid'}->{$r->uid} = 1;
	}
    }

    #warn "ref:  ",$self->{'ref_row'}->uid, "\n" if defined $self->{'ref_row'};
    #warn "keep: [", join(",", sort keys %{$self->{'keep_uid'}}), "]\n";
    #warn "nops: [", join(",", sort keys %{$self->{'nops_uid'}}), "]\n";
    #warn "hide: [", join(",", sort keys %{$self->{'hide_uid'}}), "]\n";
}

sub build_base_alignment {
    my ($self, $aln) = @_;

    #make and insert each sequence into the alignment
    foreach my $row (@{$self->{'index2row'}}) {
        my $arow = $aln->make_sequence($row);
        $aln->append($arow);
    }

    #filter alignment based on %identity to reference
    $aln = $aln->prune_identities($self->{'ref_row'}->uid,
                                  $PAR->get('pcid'),
                                  $PAR->get('minident'),
                                  $PAR->get('maxident'),
                                  $self->{'topn'},
                                  $self->{'keep_uid'});

    my $sequences = $PAR->get('sequences');
    my $noinserts = !$PAR->get('keepinserts');

    #compute columnwise data for aligned output
    if ($self->{'aligned'} and $sequences and $noinserts) {

        if (defined $self->{'ref_row'}) {
            $aln->set_coverage($self->{'ref_row'}->uid);
            $aln->set_identity($self->{'ref_row'}->uid, $PAR->get('pcid'));
        }

        #copy computed data into build row objects
        foreach my $row (@{$self->{'index2row'}}) {
            next  if exists $self->{'hide_uid'}->{$row->uid};

            my $arow = $aln->uid2row($row->uid);
            next  unless defined $arow;

            $row->set_coverage($arow->get_coverage);
            $row->set_identity($arow->get_identity);
        }
    }

    #foreach my $r ($aln->all_ids) { $aln->uid2row($r)->seqobj->dump }
    #warn "Alignment width: ", $aln->length;

    return $aln;
}

sub build_mview_alignment {
    my ($self, $aln) = @_;

    foreach my $row (@{$self->{'index2row'}}) {
	next  if exists $self->{'hide_uid'}->{$row->uid};

	my $arow = $aln->uid2row($row->uid);
	next  unless defined $arow;

        my @labels = $row->display_column_values;

        $labels[0] = ''  if $self->is_nop($row->uid);

        #warn "labels: [@{[scalar @labels]}] [@{[join(',', @labels)]}]\n";

        $arow->set_display(
            'label0' => $labels[0],
            'label1' => $labels[1],
            'label2' => $labels[2],
            'label3' => $labels[3],
            'label4' => $labels[4],
            'label5' => $labels[5],
            'label6' => $labels[6],
            'label7' => $labels[7],
            'label8' => $labels[8],
            'url'    => $row->url,
            );
    }
}

######################################################################
# debug
######################################################################
#sub DESTROY { print "destroy: $_[0]\n" }

sub dump_index2row {
    my $self = shift;
    for (my $i=0; $i < @{$self->{'index2row'}}; $i++) {
        warn "$i:  ", $self->index2row($i)->num, " ",
            $self->index2row($i)->cid, " [",
            $self->index2row($i)->seq, "]\n";
    }
}

###########################################################################
1;
