# Copyright (C) 1997-2017 Nigel P. Brown

###########################################################################
package Bio::MView::Display;

use Bio::MView::Display::Any;

use strict;
use vars qw(%Template %Known_Types $Default_Stream
	    $Default_Columns $Default_Separator $Default_Gap $Default_Pad
	    $Default_Overlap $Default_Overlap_Color $Default_Ruler
	    $Default_HTML $Default_Bold $Default_Label0
	    $Default_Label1 $Default_Label2 $Default_Label3 $Default_Label4
	    $Default_Label5 $Default_Label6 $Default_Label7
            $Intercolumn_Space);

$Default_Stream        = \*STDOUT;  #output stream
$Default_Columns       = 80;        #sequence display width
$Default_Separator     = "\n";      #output record separator
$Default_Gap           = '-';       #sequence gap character
$Default_Pad           = '';        #sequence trailing space character
$Default_Overlap       = '%';       #sequence overlap character
$Default_Overlap_Color = '#474747'; #sequence overlap color if HTML
$Default_Ruler         = 'abs';     #ruler is absolute from start of sequence
$Default_HTML          = 0;         #produce HTML?
$Default_Bold          = 0;         #embolden some text
$Default_Label0        = 1;         #show label0
$Default_Label1        = 1;         #show label1
$Default_Label2        = 1;         #show label2
$Default_Label3        = 1;         #show label3
$Default_Label4        = 1;         #show label4
$Default_Label5        = 1;         #show label5
$Default_Label6        = 1;         #show label6
$Default_Label7        = 1;         #show label7

$Intercolumn_Space     = ' ';       #space between output column types

%Template =
    (
     'string'    => undef, #parent sequence string
     'length'    => 0,     #parent sequence length
     'start'     => undef, #forward start position of parent sequence
     'stop'      => undef, #forward stop position of parent sequence
     'object'    => undef, #ordered list of display objects
     'posnwidth' => 0,     #string width of left/right sequence position
     'labwidth0' => 0,     #string width of zeroth title block
     'labwidth1' => 0,     #string width of first title block
     'labwidth2' => 0,     #string width of second title block
     'labwidth3' => 0,     #string width of third title block
     'labwidth4' => 0,     #string width of fourth title block
     'labwidth5' => 0,     #string width of fifth title block
     'labwidth6' => 0,     #string width of sixth title block
     'labwidth7' => 0,     #string width of seventh title block
    );

%Known_Types =
    (
     'Ruler'    => 1,
     'Sequence' => 1,
     'Subrange' => 1,
    );

sub new {
    my $type = shift;
    die "$type::new() missing arguments\n"  unless @_;
    my $sequence = shift;
    my $self = { %Template };

    $self->{'string'}    = $sequence;
    $self->{'length'}    = $sequence->length;
    $self->{'start'}     = $sequence->lo;
    #$self->{'stop'}      = $sequence->hi;
    $self->{'stop'}      = $self->{'start'} + $self->{'length'} - 1;

    #my $tmp = abs($self->{'stop'}-$self->{'start'})+1;
    #warn "$self->{'start'} $self->{'stop'} :  $self->{length}  $tmp";

    $self->{'posnwidth'} = length(max($self->{'start'}, $self->{'stop'}));
    $self->{'object'}    = [];

    bless $self, $type;

    $self->append(@_)  if @_;

    $self;
}

#sub DESTROY { warn "DESTROY $_[0]\n" }

#force break of back references to allow garbage collection
sub free {
    local $_;
    #warn "FREE $_[0]\n";
    while ($_ = shift @{$_[0]->{'object'}}) { $_->free }
}

sub set_parameters {
    my $self = shift;
    my ($key, $val);

    while (@_) {
	($key, $val) = (shift, shift);
	if (exists $Template{$key}) {
	    $self->{$key} = $val;
	    next;
	}
	warn "Bio::MView::Manager: unknown parameter '$key'\n";
    }

    $self;
}

sub append {
    my $self = shift;
    #warn "${self}::append(@_)\n";

    #handle data rows
    foreach my $row (@_) {
        my $type;

	#check row 'type' exists and is valid
	if (exists $row->{'type'}) {
	    $type = ucfirst $row->{'type'};
	} else {
	    warn "$self append: missing type in '$row'\n";
	    next;
	}
	unless (exists $Known_Types{$type}) {
	    warn "$self append: unknown alignment type '$type'\n";
	    next;
	}

        next  if $type eq 'Ruler';

	#construct row object
	no strict 'refs';
	$type = "Bio::MView::Display::$type"->new($self, $row);
	use strict 'refs';

	push @{$self->{'object'}}, $type;

	# warn "[", $type->label0, ",", $type->label1, ",", $type->label2,
        # $type->label3, ",", $type->label4, ",", $type->label5,
        # $type->label6, ",", $type->label7, "]\n";

	$self->{'labwidth0'} = max($self->{'labwidth0'}, length($type->label0));
	$self->{'labwidth1'} = max($self->{'labwidth1'}, length($type->label1));
	$self->{'labwidth2'} = max($self->{'labwidth2'}, length($type->label2));
	$self->{'labwidth3'} = max($self->{'labwidth3'}, length($type->label3));
	$self->{'labwidth4'} = max($self->{'labwidth4'}, length($type->label4));
	$self->{'labwidth5'} = max($self->{'labwidth5'}, length($type->label5));
	$self->{'labwidth6'} = max($self->{'labwidth6'}, length($type->label6));
	$self->{'labwidth7'} = max($self->{'labwidth7'}, length($type->label7));
    }

    #handle header/ruler
    foreach my $row (@_) {
        my $type;

	#check row 'type' exists and is valid
	if (exists $row->{'type'}) {
	    $type = ucfirst $row->{'type'};
	} else {
	    next;
	}
	next  unless exists $Known_Types{$type};

        next  if $type ne 'Ruler';

	#construct row object
	no strict 'refs';
	$type = "Bio::MView::Display::$type"->new($self, $row);
	use strict 'refs';

	push @{$self->{'object'}}, $type;

	# warn "[", $type->label0, ",", $type->label1, ",", $type->label2,
        # $type->label3, ",", $type->label4, ",", $type->label5,
        # $type->label6, ",", $type->label7, ",", "]\n";

	$self->{'labwidth0'} = max($self->{'labwidth0'}, length($type->label0))
            if $self->{'labwidth0'};
	$self->{'labwidth1'} = max($self->{'labwidth1'}, length($type->label1))
            if $self->{'labwidth1'};
	$self->{'labwidth2'} = max($self->{'labwidth2'}, length($type->label2))
            if $self->{'labwidth2'};
	$self->{'labwidth3'} = max($self->{'labwidth3'}, length($type->label3))
            if $self->{'labwidth3'};
	$self->{'labwidth4'} = max($self->{'labwidth4'}, length($type->label4))
            if $self->{'labwidth4'};
	$self->{'labwidth5'} = max($self->{'labwidth5'}, length($type->label5))
            if $self->{'labwidth5'};
	$self->{'labwidth6'} = max($self->{'labwidth6'}, length($type->label6))
            if $self->{'labwidth6'};
	$self->{'labwidth7'} = max($self->{'labwidth7'}, length($type->label7))
            if $self->{'labwidth7'};
    }
    #Universal::vmstat("Display::append done");
    $self;
}

sub dump {
    my $self = shift;
    foreach my $k (sort keys %$self) {
	printf "%15s => %s\n", $k, $self->{$k};
    }
    map { $_->dump } @{$self->{'object'}};
    $self;
}

sub length { $_[0]->{'length'} }

sub set_widths {
    my $self = shift;
    my ($key, $val);
    while (@_) {
	($key, $val) = (shift, shift);
	$self->{$key} = $val;
    }
    $self;
}

sub display {
    my $self = shift;
    my %par = @_;

    $par{'stream'} = $Default_Stream           unless exists $par{'stream'};
    $par{'col'}    = $Default_Columns  	       unless exists $par{'col'};
    $par{'gap'}    = $Default_Gap      	       unless exists $par{'gap'};
    $par{'pad'}    = $Default_Pad      	       unless exists $par{'pad'};
    $par{'rec'}    = $Default_Separator        unless exists $par{'rec'};
    $par{'ruler'}  = $Default_Ruler            unless exists $par{'ruler'};
    $par{'bold'}   = $Default_Bold             unless exists $par{'bold'};
    $par{'label0'} = $Default_Label0           unless exists $par{'label0'};
    $par{'label1'} = $Default_Label1           unless exists $par{'label1'};
    $par{'label2'} = $Default_Label2           unless exists $par{'label2'};
    $par{'label3'} = $Default_Label3           unless exists $par{'label3'};
    $par{'label4'} = $Default_Label4           unless exists $par{'label4'};
    $par{'label5'} = $Default_Label5           unless exists $par{'label5'};
    $par{'label6'} = $Default_Label6           unless exists $par{'label6'};
    $par{'label7'} = $Default_Label7           unless exists $par{'label7'};

    $par{'posnwidth'} = $self->{'posnwidth'}   unless exists $par{'posnwidth'};

    $par{'labwidth0'} = $self->{'labwidth0'}   unless exists $par{'labwidth0'};
    $par{'labwidth1'} = $self->{'labwidth1'}   unless exists $par{'labwidth1'};
    $par{'labwidth2'} = $self->{'labwidth2'}   unless exists $par{'labwidth2'};
    $par{'labwidth3'} = $self->{'labwidth3'}   unless exists $par{'labwidth3'};
    $par{'labwidth4'} = $self->{'labwidth4'}   unless exists $par{'labwidth4'};
    $par{'labwidth5'} = $self->{'labwidth5'}   unless exists $par{'labwidth5'};
    $par{'labwidth6'} = $self->{'labwidth6'}   unless exists $par{'labwidth6'};
    $par{'labwidth7'} = $self->{'labwidth7'}   unless exists $par{'labwidth7'};

    $par{'html'} = 1    if $par{'bold'};
    if ($par{'html'}) {
	$par{'lap'}   = $Default_Overlap_Color unless exists $par{'lap'};
    } else {
	$par{'lap'}   = $Default_Overlap       unless exists $par{'lap'};
    }

    if ($par{'col'} < 1) {
	#full length display if meaningless column count
	$par{'col'} = $self->{'length'};
    }
    if (CORE::length $par{'gap'} != 1) {
	warn "${self}::display: gap must be single character '$par{'gap'}'\n";
	$par{'gap'} = $Default_Gap;
    }
    if (CORE::length $par{'pad'} > 1) {
	warn "${self}::display: pad must be null or single character '$par{'pad'}'\n";
	$par{'pad'} = $Default_Pad;
    }

    #map { warn "$_ => '$par{$_}'\n" } sort keys %par;

    my $str = $par{'stream'};

    my ($prefix, $suffix) = $par{'bold'} ? ('<STRONG>','</STRONG>') : ('','');

    print $str "<PRE>\n"    if $par{'html'};

    map { $_->reset } @{$self->{'object'}};

    my ($posnwidth, $o, $s, @left, @middle, @right, @tmp, $tmp) = (0);

    #need space for sequence numbers?
    foreach $o (@{$self->{'object'}}) {
	if ($o->{'number'}) {
	    $posnwidth = 1;
	    last;
	}
    }

    #iterate over display rows
LOOP:
    {
	while (1) {

	    last LOOP   unless scalar @{$self->{'object'}};

	    #Universal::vmstat("display LOOP");

	    #do record
	    foreach $o (@{$self->{'object'}}) {

		@left = @middle = @right = ();

		#do line
		$s = $o->next($par{'html'}, $par{'bold'}, $par{'col'},
			      $par{'gap'}, $par{'pad'}, $par{'lap'},
			      $par{'ruler'});

		last LOOP   unless $s;
		#warn "[ @$s ]\n";

		#### left ############
		@tmp = ();

		#label0
		if ($par{'label0'} and $par{'labwidth0'}) {
		    $tmp = $o->label0;
		    if ($tmp =~ /^\d+$/) {
			#numeric label - right justify
			push @tmp, sprintf("%$par{'labwidth0'}s", $tmp);
		    } else {
			#string label - left justify
			push @tmp, sprintf("%-$par{'labwidth0'}s", $tmp);
		    }
		    push @tmp, $Intercolumn_Space;
		}

		#label1
		if ($par{'label1'} and $par{'labwidth1'}) {
		    if ($par{'html'} and $o->{'url'}) {
			push @tmp,
			"<A HREF=\"$o->{'url'}\">", $o->label1, "</A>";
			push @tmp,
			" " x ($par{'labwidth1'}-CORE::length $o->label1);
		    } else {
			push @tmp,
			sprintf("%-$par{'labwidth1'}s", $o->label1);
		    }
		    push @tmp, $Intercolumn_Space;
		}

		#label2
		if ($par{'label2'} and $par{'labwidth2'}) {
		    push @tmp, sprintf("%-$par{'labwidth2'}s", $o->label2);
		    push @tmp, $Intercolumn_Space;
		}

		#label3
		if ($par{'label3'} and $par{'labwidth3'}) {
		    push @tmp, sprintf("%$par{'labwidth3'}s", $o->label3);
		    push @tmp, $Intercolumn_Space;
		}

		#label4
		if ($par{'label4'} and $par{'labwidth4'}) {
		    push @tmp, sprintf("%$par{'labwidth4'}s", $o->label4);
		    push @tmp, $Intercolumn_Space;
		}

		#label5
		if ($par{'label5'} and $par{'labwidth5'}) {
		    push @tmp, sprintf("%$par{'labwidth5'}s", $o->label5);
		    push @tmp, $Intercolumn_Space;
		}

		#label6
		if ($par{'label6'} and $par{'labwidth6'}) {
		    push @tmp, sprintf("%$par{'labwidth6'}s", $o->label6);
		    push @tmp, $Intercolumn_Space;
		}

		#label7
		if ($par{'label7'} and $par{'labwidth7'}) {
		    push @tmp, sprintf("%$par{'labwidth7'}s", $o->label7);
		    push @tmp, $Intercolumn_Space;
		}

		#left sequence position
		if ($posnwidth) {
		    if ($o->{'number'}) {
			push @tmp, sprintf("$prefix%$par{'posnwidth'}d$suffix", $s->[0]);
		    } else {
			push @tmp, sprintf("$prefix%$par{'posnwidth'}s$suffix", ' ');
		    }
		}

		push @tmp, $Intercolumn_Space;

		push @left, @tmp;

		#### middle ############
		@tmp = ();

		#sequence string
		push @tmp, $s->[2];
		push @tmp, $Intercolumn_Space;

		push @middle, @tmp;

		#### right ############
		@tmp = ();

		#right position
		if ($posnwidth) {
  		    if ($o->{'number'}) {
			push @tmp,
			sprintf("$prefix%-$par{'posnwidth'}d$suffix",
				$s->[1]);
		    } else {
			push @tmp,
			sprintf("$prefix%-$par{'posnwidth'}s$suffix", '');
		    }
		}

		push @tmp, "\n";

		push @right, @tmp;

		#### output row ############
		print $str @left, @middle, @right;

	    }#foreach

	    #record separator
	    print $str $par{'rec'}    unless $self->{'object'}->[0]->done;

	    #Universal::vmstat("display loop done");
 	}
    }
    print $str "</PRE>\n"    if $par{'html'};

    $self;
}

sub max { $_[0] > $_[1] ? $_[0] : $_[1] }

###########################################################################
1;
