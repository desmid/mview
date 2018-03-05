# Copyright (C) 1997-2018 Nigel P. Brown

######################################################################
package Bio::MView::Align;

use Bio::MView::Colormap;
use Bio::MView::Display;
use Bio::MView::Align::Row;

use strict;

my $BLOCKSEPARATOR = ':';  #for block search patterns

my %Template =
    (
     'length'     => 0,     #alignment width
     'id2index'   => undef, #hash of identifiers giving row numbers
     'index2row'  => undef, #list of aligned rows, from zero
     'parent'     => undef, #identifier of parent sequence
     'cursor'     => -1,    #index2row iterator
     'tally'      => undef, #column tallies for consensus

     'ref_id'     => undef, #identifier of reference row
     'colormap'   => undef, #name of alignment colormap
     'group'      => undef, #consensus group name
     'ignore'     => undef, #ignore self/non-self classes
     'con_gaps'   => undef, #ignore gaps when computing consensus
     'threshold'  => undef, #consensus threshold for colouring
     'bold'       => undef, #display alignment in bold
     'css1'       => undef, #use CSS1 style sheets
     'alncolor'   => undef, #colour of alignment background
     'symcolor'   => undef, #default colour of alignment text
     'gapcolor'   => undef, #colour of alignment gap
     'find'       => undef, #pattern to match in sequence

     'coloring'   => undef, #alignment coloring mode
     'coloringc'  => undef, #consensus coloring mode
     'colormapc'  => undef, #name of consensus colormap
     'colormapf'  => undef, #name of find colormap
     'old'        => {},    #previous settings of the above
     'nopshash'   => undef, #hash of id's to ignore for computations/colouring
     'hidehash'   => undef, #hash of id's to ignore for display
    );

my %Known_Parameter =
    (
     'ref_id'     => [ '(\S+(?:\s*)?)+', undef ],
     'coloring'   => [ '\S+',     'none' ],
     'coloringc'  => [ '\S+',     'none' ],
     'colormap'   => [ '\S+',     $Bio::MView::Align::Sequence::Default_Colormap ],
     'colormapc'  => [ '\S+',     $Bio::MView::Align::Consensus::Default_Colormap ],
     'colormapf'  => [ '\S+',     $Bio::MView::Align::Sequence::Default_FIND_Colormap ],
     'bold'       => [ '[01]',    1 ],
     'css1'       => [ '[01]',    0 ],
     'alncolor'   => [ '\S+',     $Bio::MView::Colormap::Colour_White ],
     'labcolor'   => [ '\S+',     $Bio::MView::Colormap::Colour_Black ],
     'symcolor'   => [ '\S+',     $Bio::MView::Colormap::Colour_Black ],
     'gapcolor'   => [ '\S+',     $Bio::MView::Colormap::Colour_DarkGray ],
     'group'      => [ '\S+',     $Bio::MView::Align::Consensus::Default_Group ],
     'ignore'     => [ '\S+',     $Bio::MView::Align::Consensus::Default_Ignore ],
     'con_gaps'   => [ '[01]',     1 ],
     'threshold'  => [ '\S+',     80 ],
     'nopshash'   => [ {},        {} ],
     'hidehash'   => [ {},        {} ],
     'find'       => [ '\S*',     '' ],
    );

sub new {
    my $type = shift;
    #warn "${type}::new() @_\n";
    if (@_ < 1) {
	die "${type}::new() missing arguments\n";
    }
    my ($obj, $aligned, $parent) = (@_, undef);
    my $i;

    my $self = { %Template };

    $self->{'id2index'}  = {};
    $self->{'index2row'} = [];
    $self->{'aligned'}  = $aligned;

    #warn "Align: [$obj][$aligned]\n";

    for ($i=0; $i<@$obj; $i++) {

	if (defined $obj->[$i]) {
	    #warn "[$i] ",  $obj->[$i]->id, " ", $obj->[$i]->string, "\n";

	    $self->{'id2index'}->{$obj->[$i]->id} = $i;
	    $self->{'index2row'}->[$i] = $obj->[$i];

	    $self->{'length'} = $obj->[$i]->length  if $self->{'length'} < 1;

	    if ($aligned and $obj->[$i]->length != $self->{'length'}) {
		#warn "[@{[$obj->[$i]->string]}]\n";
		die "${type}::new() incompatible alignment lengths, row $i, expect $self->{'length'}, got @{[$obj->[$i]->length]}\n";
	    }
	}
    }

    if (defined $parent) {
	$self->{'parent'} = $parent;
    } else {
	$self->{'parent'} = $self->{'index2row'}->[0];
    }

    bless $self, $type;

    $self->initialise_parameters;

    $self;
}

#sub DESTROY { warn "DESTROY $_[0]\n" }

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
    foreach my $r (@{$self->{'index2row'}}) {
	$r->dump  if defined $r;
    }
    warn "\n";
    $self;
}

sub initialise_parameters {
    my $self = shift;
    my ($p) = (@_, \%Known_Parameter);
    foreach my $k (keys %$p) {
	#warn "initialise_parameters() $k\n";
	if (ref $p->{$k}->[0] eq 'ARRAY') {
	    $self->{$k} = [];
	    next;
	}
	if (ref $p->{$k}->[0] eq 'HASH') {
	    $self->{$k} = {};
	    next;
	}
	$self->{$k} = $p->{$k}->[1];
    }
    $self;
}

sub set_parameters {
    my $self = shift;
    my $p = ref $_[0] ? shift : \%Known_Parameter;
    my ($key, $val);
    #warn "set_parameters($self) ". join(" ", keys %$p), "\n";
    while ($key = shift) {
	$val = shift;
	#warn "set_parameters() $key, $val\n";
	if (exists $p->{$key}) {
	    #warn "set_parameters() $key, $val\n";
	    if (ref $p->{$key}->[0] eq 'ARRAY' and ref $val eq 'ARRAY') {
		$self->{'old'}->{$key} = $self->{$key};
		$self->{$key} = $val;
		next;
	    }
	    if (ref $p->{$key}->[0] eq 'HASH' and ref $val eq 'HASH') {
		$self->{'old'}->{$key} = $self->{$key};
		$self->{$key} = $val;
		next;
	    }
	    if (! defined $val) {
		#set default
		$self->{'old'}->{$key} = $self->{$key};
		$self->{$key} = $p->{$key}->[1];
		next;
	    }
	    if ($val =~ /^$p->{$key}->[0]$/) {
		#matches expected format
		$self->{'old'}->{$key} = $self->{$key};
		$self->{$key} = $val;
		next;
	    }
	    warn "${self}::set_parameters() bad value for '$key', got '$val', wanted '$p->{$key}->[0]'\n";
	}
	#ignore unrecognised parameters which may be recognised by subclass
	#set_parameters() methods.
	warn "set_parameters(IGNORE) $key, $val\n";
    }

    $self;
}

sub get_parameters {
    my $self = shift;
    my @tmp = ();
    foreach my $k (keys %Known_Parameter) {
        push @tmp, $k, $self->{$k};
    }
    return @tmp;
}

sub length { $_[0]->{'length'} }

sub id2row {
    return undef  unless defined $_[0]->{id2index}->{$_[1]};
    $_[0]->{index2row}->[$_[0]->{id2index}->{$_[1]}];
}

sub is_hidden { exists $_[0]->{'hidehash'}->{$_[1]} }
sub is_nop    { exists $_[0]->{'nopshash'}->{$_[1]} }

#return list of all rows as internal ids
sub all_ids {
    my @tmp = ();
    foreach my $r (@{$_[0]->{'index2row'}}) {
	next  unless defined $r;
	push @tmp, $r->id;
    }
    @tmp;
}

#return list of visible rows as internal ids
sub visible_ids {
    my @tmp = ();
    foreach my $r (@{$_[0]->{'index2row'}}) {
	next  unless defined $r;
	next  if $_[0]->is_hidden($r->id);
	push @tmp, $r->id;
    }
    @tmp;
}

#return list of visible and not nops rows as internal ids;
#these are rows that will be displayed AND have consensus calculations done
sub visible_and_scoreable_ids {
    my @tmp = ();
    foreach my $r (@{$_[0]->{'index2row'}}) {
	next  unless defined $r;
	next  if $_[0]->is_hidden($r->id);
	next  if $_[0]->is_nop($r->id);
	push @tmp, $r->id;
    }
    @tmp;
}

#return row object indexed by identifier, or undef
sub item {
    my ($self, $id) = @_;
    return undef  unless defined $id;
    return $self->id2row($id)  if exists $self->{'id2index'}->{$id};
    undef;
}

#delete row(s) by identifier
sub delete {
    my $self = shift;
    foreach my $id (@_) {
	next  unless exists $self->{'id2index'}->{$id};
	$self->id2row($id) = undef;
	$self->{'id2index'}->{$id} = undef;
    }
    $self;
}

#initialise stream of row objects
sub reset { $_[0]->{'cursor'} = -1 }

#return next row object in stream, or return 0 and reinitialise
sub next {
    $_[0]->{'cursor'}++;
    if (defined $_[0]->{'index2row'}->[$_[0]->{'cursor'}]) {
	return $_[0]->{'index2row'}->[$_[0]->{'cursor'}];
    }
    $_[0]->{'cursor'} = -1;
    return 0;
}

#propagate display parameters to row objects
sub set_display {
    my $self = shift;
    foreach my $r (@{$self->{'index2row'}}) {
	$r->set_display(@_)  if defined $r;
    }
}

#ignore id's in remaining arglist
sub set_identity {
    my ($self, $ref, $mode) = @_;
    #warn "Bio::MView::Align::set_identity(@_)\n";

    $ref = $self->id2row($ref);
    return  unless defined $ref;

    foreach my $r (@{$self->{'index2row'}}) {
	next  unless defined $r;
	next  if $self->is_nop($r->id);
	$r->set_identity($ref, $mode);
    }
}

#ignore id's in remaining arglist
sub set_coverage {
    my ($self, $ref) = @_;
    #warn "Bio::MView::Align::set_coverage(@_)\n";

    $ref = $self->id2row($ref);
    return  unless defined $ref;

    foreach my $r (@{$self->{'index2row'}}) {
	next  unless defined $r;
	next  if $self->is_nop($r->id);
	$r->set_coverage($ref);
    }
}

sub header {
    my ($self, $quiet) = (@_, 0);
    return ''  if $quiet;

    my $s = '';

    if ($self->{'coloring'} eq 'any') {
	$s .= "Colored by: property";
    }
    elsif ($self->{'coloring'} eq 'identity' and defined $self->{'ref_id'}) {
	$s .= "Colored by: identity";
    }
    elsif ($self->{'coloring'} eq 'mismatch' and defined $self->{'ref_id'}) {
	$s .= "Colored by: mismatch";
    }
    elsif ($self->{'coloring'} eq 'consensus') {
	$s .= "Colored by: consensus/$self->{'threshold'}\%";
    }
    elsif ($self->{'coloring'} eq 'group') {
	$s .= "Colored by: consensus group/$self->{'threshold'}\%";
    }

    #overlay any find pattern colouring
    if ($self->{'find'} ne '') {
        if ($s eq '') {
            $s .= "Colored by: ";
        } else {
            $s .= "; ";
        }
        $s .= "search pattern '$self->{'find'}'\n";
    }
    $s .= "\n"  if $s ne '';

    Bio::MView::Display::displaytext($s);
}

sub set_color_scheme {
    my $self = shift;

    $self->set_parameters(@_);

    #user-defined colouring?
    $self->color_special('colormap'  => $self->{'colormap'},
			 'symcolor'  => $self->{'symcolor'},
			 'gapcolor'  => $self->{'gapcolor'},
			 'css1'      => $self->{'css1'},
			);

    if ($self->{'coloring'} eq 'none') {
        $self->color_none('colormap'  => $self->{'colormap'},
                          'symcolor'  => $self->{'symcolor'},
                          'gapcolor'  => $self->{'gapcolor'},
                          'css1'      => $self->{'css1'},
                         );
    }

    elsif ($self->{'coloring'} eq 'any') {
	$self->color_by_type('colormap'  => $self->{'colormap'},
			     'symcolor'  => $self->{'symcolor'},
			     'gapcolor'  => $self->{'gapcolor'},
			     'css1'      => $self->{'css1'},
			    );
    }

    elsif ($self->{'coloring'} eq 'identity') {
	$self->color_by_identity($self->{'ref_id'},
				 'colormap'  => $self->{'colormap'},
				 'symcolor'  => $self->{'symcolor'},
				 'gapcolor'  => $self->{'gapcolor'},
				 'css1'      => $self->{'css1'},
				);
    }

    elsif ($self->{'coloring'} eq 'mismatch') {
	$self->color_by_mismatch($self->{'ref_id'},
				 'colormap'  => $self->{'colormap'},
				 'symcolor'  => $self->{'symcolor'},
				 'gapcolor'  => $self->{'gapcolor'},
				 'css1'      => $self->{'css1'},
				);
    }

    elsif ($self->{'coloring'} eq 'consensus') {
	$self->color_by_consensus_sequence('colormap'  => $self->{'colormap'},
					   'symcolor'  => $self->{'symcolor'},
					   'gapcolor'  => $self->{'gapcolor'},
					   'css1'      => $self->{'css1'},
					  );
    }

    elsif ($self->{'coloring'} eq 'group') {
	$self->color_by_consensus_group('colormap'  => $self->{'colormap'},
					'symcolor'  => $self->{'symcolor'},
					'gapcolor'  => $self->{'gapcolor'},
					'css1'      => $self->{'css1'},
				       );
    }

    else {
        warn "${self}::set_color_scheme() unknown mode '$self->{'coloring'}'\n";
    }

    #find overlays anything else
    if ($self->{'find'} ne '') {

        my $mapsize = Bio::MView::Colormap::get_colormap_length(
            $self->{'colormapf'}
        );
        my @patterns = split($BLOCKSEPARATOR, $self->{'find'});
        if (@patterns > $mapsize) {
            warn "recycling colormap '$self->{'colormapf'}': @{[scalar @patterns]} patterns but only $mapsize color(s)\n";
        }

	$self->color_by_find_block('colormap'  => $self->{'colormapf'},
				   'symcolor'  => $self->{'symcolor'},
				   'gapcolor'  => $self->{'gapcolor'},
				   'css1'      => $self->{'css1'},
				   'find'      => $self->{'find'},
                                   'mapsize'   => $mapsize,
                                   'patterns'  => [@patterns],
            );
    }

    return $self;
}

sub set_consensus_color_scheme {
    my ($self, $aln, $ref) = (shift, shift, shift);

    $self->set_parameters(@_);

    if ($self->{'coloringc'} eq 'none') {
        ;
    }

    elsif ($self->{'coloringc'} eq 'any') {
	$self->color_by_type('colormap'  => $self->{'colormap'},
                             'colormapc' => $self->{'colormapc'},
			     'symcolor'  => $self->{'symcolor'},
			     'gapcolor'  => $self->{'gapcolor'},
			     'css1'      => $self->{'css1'},
			    );
    }

    elsif ($self->{'coloringc'} eq 'identity') {
	$self->color_consensus_by_identity($aln, $ref,
                                 'colormap'  => $self->{'colormap'},
                                 'colormapc' => $self->{'colormapc'},
			         'symcolor'  => $self->{'symcolor'},
			         'gapcolor'  => $self->{'gapcolor'},
			         'css1'      => $self->{'css1'},
			    );
    }

    else {
        warn "${self}::set_consensus_color_scheme() unknown mode '$self->{'coloringc'}'\n";
    }

    return $self;
}


#propagate colour scheme to row objects
sub color_special {
    my $self = shift;
    for my $r (@{$self->{'index2row'}}) {
	next  unless defined $r;
	next  if $r->{'type'} ne 'special';
	next  if $self->is_nop($r->id);
	next  if $self->is_hidden($r->id);
	$r->color_special(@_);
	$r->set_display('label0'=>'', #not 1
                        'label2'=>'', 'label3'=>'',
			'label4'=>'', 'label5'=>'',
                        'label6'=>'', 'label7'=>'');
    }
    $self;
}

#propagate colour scheme to row objects
sub color_none {
    my $self = shift;

    for my $r (@{$self->{'index2row'}}) {
	next  unless defined $r;
	next  if $self->is_nop($r->id);
	next  if $self->is_hidden($r->id);
	$r->color_none(@_);
    }
    $self;
}

#propagate colour scheme to row objects
sub color_by_type {
    my $self = shift;

    for my $r (@{$self->{'index2row'}}) {
	next  unless defined $r;
	next  if $self->is_nop($r->id);
	next  if $self->is_hidden($r->id);
	$r->color_by_type(@_);
    }
    $self;
}

#propagate colour scheme to row objects
sub color_by_identity {
    my ($self, $id) = (shift, shift);

    my $ref = $self->item($id);
    return $self  unless defined $ref;

    for my $r (@{$self->{'index2row'}}) {
	next  unless defined $r;
	next  if $self->is_nop($r->id);
	next  if $self->is_hidden($r->id);
	$r->color_by_identity($ref, @_);
    }
    $self;
}

#propagate colour scheme to row objects
sub color_by_mismatch {
    my ($self, $id) = (shift, shift);

    my $ref = $self->item($id);
    return $self  unless defined $ref;

    for my $r (@{$self->{'index2row'}}) {
	next  unless defined $r;
	next  if $self->is_nop($r->id);
	next  if $self->is_hidden($r->id);
	$r->color_by_mismatch($ref, @_);
    }
    $self;
}

#propagate colour scheme to row objects
sub color_by_consensus_sequence {
    my $self = shift;

    #is there already a suitable tally?
    if (!defined $self->{'tally'} or
	(defined $self->{'old'}->{'group'} and
	 $self->{'old'}->{'group'} ne $self->{'group'})) {
	$self->compute_tallies($self->{'group'});
    }

    my $from = $self->{'parent'}->from;
    my $to   = $from + $self->length - 1;

    my $con = new Bio::MView::Align::Consensus($from, $to,
					       $self->{'tally'},
					       $self->{'group'},
					       $self->{'threshold'},
					       $self->{'ignore'});
    for my $r (@{$self->{'index2row'}}) {
	next  unless defined $r;
	next  if $self->is_nop($r->id);
	next  if $self->is_hidden($r->id);
	$con->color_by_consensus_sequence($r, @_);
    }
    $self;
}

#propagate colour scheme to row objects
sub color_by_consensus_group {
    my $self = shift;

    #is there already a suitable tally?
    if (!defined $self->{'tally'} or
	(defined $self->{'old'}->{'group'} and
	 $self->{'old'}->{'group'} ne $self->{'group'})) {

	$self->compute_tallies($self->{'group'});
    }

    my $from = $self->{'parent'}->from;
    my $to   = $from + $self->length - 1;

    my $con = new Bio::MView::Align::Consensus($from, $to,
					       $self->{'tally'},
					       $self->{'group'},
					       $self->{'threshold'},
					       $self->{'ignore'});
    for my $r (@{$self->{'index2row'}}) {
	next  unless defined $r;
	next  if $self->is_nop($r->id);
	next  if $self->is_hidden($r->id);
	$con->color_by_consensus_group($r, @_);
    }
    $self;
}

#propagate colour scheme to row objects
sub color_by_find_block {
    my $self = shift;

    for my $r (@{$self->{'index2row'}}) {
	next  unless defined $r;
	next  if $self->is_nop($r->id);
	next  if $self->is_hidden($r->id);
	$r->color_by_find_block(@_);
    }
    $self;
}

#propagate colour scheme to row objects
sub color_consensus_by_identity {
    my ($self, $aln, $id) = (shift, shift, shift);

    my $ref = $aln->item($id);
    return $self  unless defined $ref;

    for my $r (@{$self->{'index2row'}}) {
	next  unless defined $r;
	next  if $self->is_nop($r->id);
	next  if $self->is_hidden($r->id);
	$r->color_by_identity($ref, @_);
    }
    $self;
}

#return array of Bio::MView::Display::display() constructor arguments
sub init_display { ( $_[0]->{'parent'}->{'string'} ) }

#Append Row data to the input Display object: done one at a time to reduce
#memory usage instead of accumulating a potentially long list before passing
#to Display::append(), and to permit incremental garbage collection of each
#Align::Row object once it has been appended.
#Garbage collection is enabled by default, unless the optional argument
#$gc_flag is false. This is essential when further processing of Row objects
#will occur, eg., consensus calculations.
sub append_display {
    my ($self, $dis, $gc_flag) = (@_, 1);
    #warn "append_display($dis, $gc_flag)\n";

    for (my $i=0; $i<@{$self->{'index2row'}}; $i++) {
	my $r = $self->{'index2row'}->[$i];

	next  unless defined $r;
	next  if $self->is_hidden($r->id); #also let nops through

	#append the row data structure to the Display object
	$dis->append($r->get_display);

	#optional garbage collection
	$self->do_gc($i)  if $gc_flag;
    }
    $self;
}

sub do_gc {
    my ($self, $i) = @_;
    if (defined $i) { #just one
	$self->{'index2row'}->[$i] = undef;
	return $self;
    }
    for (my $i=0; $i<@{$self->{'index2row'}}; $i++) { #all
	$self->{'index2row'}->[$i] = undef;
    }
    $self;
}

sub prune_identities {
    my ($self, $refid, $mode, $min, $max, $topn) = (shift, shift, shift, shift,
                                                    shift, shift);
    $min = 0    if $min < 0;
    $max = 100  if $max > 100;

    #special case
    return $self  unless $min > 0 or $max < 100;
    #return $self  if $min > $max;  #silly combination

    #ensure no replicates in show list
    my %show;
    foreach my $i (@_) {
	my $j = $self->id2row($i);
	$show{$j} = $j  if defined $j;
    }

    #the reference row
    my $ref = $self->item($refid);
    return $self  unless defined $ref;

    #prime show list
    my @obj = ();

    foreach my $r (@{$self->{'index2row'}}) {
	next  unless defined $r;

	#enforce limit on number of rows
	last  if $topn > 0 and @obj == $topn;

	if (exists $show{$r}) {
	    push @obj, $r;
	    next;
	}

	#store object if %identity satisfies cutoff
        my $pcid = $r->compute_identity_to($ref, $mode);
        next  if $pcid < $min or $pcid > $max;
        push @obj, $r;
    }
    #warn join(" ", map { $_->id } @obj), "\n";

    new Bio::MView::Align(\@obj, $self->{'aligned'}, $self->{'parent'});
}

#generate a new alignment with a ruler based on this alignment
sub build_ruler {
    my ($self, $refobj) = @_;
    my $obj = new Bio::MView::Align::Ruler($self->length, $refobj);
    new Bio::MView::Align([$obj], $self->{'aligned'}, $self->{'parent'});
}

#generate a new alignment using an existing one but with a line of
#clustal-style conservation string (*:.)
sub build_conservation_row {
    my ($self, $moltype) = @_;

    #extract sequence rows
    my @ids = $self->visible_ids;

    my $from = $self->{'parent'}->from;
    my $to   = $from + $self->{'length'} - 1;
    #warn "fm/to: ($from, $to)\n";

    #alignment column numbering
    my $string = $self->conservation(\@ids, 1, $self->{'length'}, $moltype);

    #sequence object lo/hi numbering
    my $obj = new Bio::MView::Align::Conservation($from, $to, $string);

    new Bio::MView::Align([$obj], $self->{'aligned'}, $self->{'parent'});
}

#generate a new alignment using an existing one but with lines showing
#consensus sequences at specified percent thresholds
sub build_consensus_rows {
    my ($self, $group, $threshold, $ignore, $con_gaps) = @_;

    $self->set_parameters('group' => $group, 'ignore' => $ignore,
			  'con_gaps' => $con_gaps);

    #is there already a suitable tally?
    if (!defined $self->{'tally'} or
	(defined $self->{'old'}->{'group'} and
	 $self->{'old'}->{'group'} ne $self->{'group'})) {

	$self->compute_tallies($self->{'group'});
    }

    my @obj = ();

    my $from = $self->{'parent'}->from;
    my $to   = $from + $self->length - 1;

    foreach my $thresh (@$threshold) {
	my $con = new Bio::MView::Align::Consensus($from, $to,
						   $self->{'tally'},
						   $group, $thresh, $ignore);
	$con->set_display('label0'=>'',
                          #not 1
			  'label2'=>'',
			  'label3'=>'',
			  'label4'=>'',
			  'label5'=>'',
			  'label6'=>'',
			  'label7'=>'',
	    );
	push @obj, $con;
    }

    new Bio::MView::Align(\@obj, $self->{'aligned'}, $self->{'parent'});
}

sub compute_tallies {
    my ($self, $group) = @_;

    $group = $Bio::MView::Align::Consensus::Default_Group
	unless defined $group;

    $self->{'tally'} = [];

    #iterate over columns
    for (my $c=1; $c <= $self->{'length'}; $c++) {

	my $col = [];

	#iterate over rows
	for my $r (@{$self->{'index2row'}}) {
	    next unless defined $r;
	    next if $r->{'type'} ne 'sequence';
	    next if $self->is_nop($r->id);
	    next if $self->is_hidden($r->id);

	    push @$col, $r->{'string'}->raw($c);
	}

	#warn "compute_tallies: @$col\n";

	push @{$self->{'tally'}},
	    Bio::MView::Align::Consensus::tally($group, $col,
						$self->{'con_gaps'});
    }
    $self;
}

sub conservation {
    #conservation mechanism inspired by Clustalx-2.1/AlignmentOutput.cpp
    my $CONS_STRONG = [ qw(STA NEQK NHQK NDEQ QHRK MILV MILF HY FYW) ];
    my $CONS_WEAK   = [ qw(CSA ATV SAG STNK STPA SGND SNDEQK NDEQHK
                           NEQHRK FVLIM HFY) ];

    #(from,to) must be 1-based along alignment
    my ($self, $ids, $from, $to, $moltype) = @_;

    return ''  unless @$ids; #empty alignment

    my @tmp = $self->visible_and_scoreable_ids;
    my $refseq = $self->id2row($tmp[0])->seqobj;
    my $depth = scalar @tmp;
    my $s = '';
    #warn "conservation: from=$from, to=$to, depth=$depth\n";

    my $initcons = sub {
	my $values = shift;
	my $dict = {};
	for my $group (@$values) { $dict->{$group} = 0 }
	$dict;
    };

    my $addcons = sub {
	my ($dict, $char) = @_;
	for my $group (keys %$dict) {
	    $dict->{$group}++  if index($group, $char) > -1;
	}
	$dict;
    };

    my $testcons = sub {
	my ($dict, $max) = @_;
	for my $group (keys %$dict) {
	    return 1  if $dict->{$group} == $max;
	}
	return 0;
    };

    my $printcons = sub {
	my ($j, $dict, $name, $stm) = (@_, \*STDOUT);
	print "$j, $name\n";
	for my $group (sort keys %$dict) {
	    printf $stm "%-6s => %d\n", $group, $dict->{$group};
	}
	print "\n\n";
    };

    #iterate over alignment columns
    for (my $j=$from; $j<=$to; $j++) {

	last  if $j > $refseq->length;

	my $strong  = &$initcons($CONS_STRONG);
	my $weak    = &$initcons($CONS_WEAK);
	my $refchar = $refseq->raw($j);
	my $same    = 0;

	#iterate over sequence list
	for (my $i=0; $i<@$ids; $i++) {
	    my $thischar = uc $self->id2row($ids->[$i])->seqobj->raw($j);
	    #warn "[$j][$i] $refchar, $thischar, $ids->[$i]\n";
	    next  if $self->is_nop($ids->[$i]);
	    $same++   if $thischar eq $refchar;
	    &$addcons($strong, $thischar);
	    &$addcons($weak, $thischar);
	}
	#&$printcons($j, $strong, 'strong');
	#&$printcons($j, $weak, 'weak');

	#warn "$same, $depth, [$self->{ref_id}], $refchar, ", $refseq->is_char($refchar), "\n";
	if ($depth > 0) {
	    if ($same == $depth and $refseq->is_char($refchar)) {
		$s .= '*';
		next;
	    }
	    if ($moltype eq 'aa') {
		$s .= ':', next  if &$testcons($strong, $depth);
		$s .= '.', next  if &$testcons($weak, $depth);
	    }
	}
	$s .= ' ';
    }
    #warn "@{[length($s)]} [$s]\n";
    \$s;
}


######################################################################
1;
