# Copyright (C) 1997-2015 Nigel P. Brown
# $Id: Sequence.pm,v 1.14 2015/01/24 21:22:42 npb Exp $

###########################################################################
package Bio::MView::Sequence;

use strict;
use vars qw($Find_Pad $Find_Gap $Find_Spc $Find_Fs1 $Find_Fs2
	    $Text_Pad $Text_Gap $Text_Spc $Text_Fs1 $Text_Fs2
	    $Mark_Pad $Mark_Gap $Mark_Spc $Mark_Fs1 $Mark_Fs2);

$Find_Pad = '[-._~]';  #input terminal gap characters
$Find_Gap = '[-._~]';  #input internal gap characters
$Find_Spc = '\s';      #input whitespace character
$Find_Fs1 = '\/';      #input frameshift mark '/' from fast[xy], tfast[axy]
$Find_Fs2 = '\\\\';    #input frameshift mark '\' from fast[xy], tfast[axy]

$Mark_Pad = "\001";    #encoded terminal gap
$Mark_Gap = "\002";    #encoded internal gap
$Mark_Spc = "\003";    #encoded whitespace
$Mark_Fs1 = "\004";    #encoded frameshift
$Mark_Fs2 = "\005";    #encoded frameshift
   
$Text_Pad = '.';       #default output terminal gap
$Text_Gap = '-';       #default output internal gap
$Text_Spc = ' ';       #default output whitespace
$Text_Fs1 = '/';       #default output frameshift
$Text_Fs2 = '\\';      #default output frameshift

my $REPORT_CLASH = 0;  #set to 1 to enable reporting of clashing symbols
my $OVERWRITE = 0;     #set to 1 to enable clash overwrite by newest symbol

#All range numbers count from 1, set to 0 when undefined.
#
#Externally, rows are numbered (increasing) left to right from 1.
#
#Internally, each row is numbered in relation to the reference sequence
#against which all other rows are being assembled.
#
#'lo' and 'hi' for any row give the lowest and highest (by magnitude) sequence
#positions in the reference sequence for that row including terminal gaps.
#
#'seqbeg' and 'seqend' for any row give the starting and stopping positions in
#the reference sequence in the orientation of the reference seqence for that
#row excluding terminal gaps.
#
#'prefix' and 'suffix' give the lengths of the terminal gaps for that row:
#
# Forwards query:

# column  12345
# +query  23456 (lo,hi,	seqbeg,seqend, prefix,suffix) = (2,6, 2,6, 0,0)
# +hit    -23-- (lo,hi,	seqbeg,seqend, prefix,suffix) = (2,6, 3,4, 1,2)
#
# column  12345
# +query  23456 (lo,hi,	seqbeg,seqend, prefix,suffix) = (2,6, 2,6, 0,0)
# -hit    -32-- (lo,hi,	seqbeg,seqend, prefix,suffix) = (2,6, 3,4, 1,2)
#
# Reverse query:
#
# column  12345
# -query  65432 (lo,hi,	seqbeg,seqend, prefix,suffix) = (2,6, 6,2, 0,0)
# +hit    -23-- (lo,hi,	seqbeg,seqend, prefix,suffix) = (2,6, 5,4, 1,2)
#
# column  12345
# -query  65432 (lo,hi,	seqbeg,seqend, prefix,suffix) = (2,6, 6,2, 0,0)
# -hit    -32-- (lo,hi,	seqbeg,seqend, prefix,suffix) = (2,6, 5,4, 1,2)
#
sub new {
    my $type = shift;
    my $self = {};

    $self->{'seq'}    	= {};   	#sparse array
    
    $self->{'lo'}     	= 0;    	#absolute start of string
    $self->{'hi'}     	= 0;    	#absolute end of string
    
    $self->{'prefix'} 	= 0;    	#length of non-sequence prefix
    $self->{'suffix'} 	= 0;    	#length of non-sequence suffix
    
    $self->{'seqbeg'} 	= 0;    	#first position of sequence data
    $self->{'seqend'} 	= 0;    	#last  position of sequence data

    $self->{'f1'}  	= undef;    	#from label of sequence
    $self->{'t1'}   	= undef;    	#to   label of sequence

    $self->{'f2'}  	= undef;    	#2nd from label of sequence (optional)
    $self->{'t2'}   	= undef;    	#2nd to   label of sequence (optional)
    
    $self->{'find_pad'} = $Find_Pad;
    $self->{'find_gap'} = $Find_Gap;
    $self->{'find_spc'} = $Find_Spc;
    $self->{'find_fs1'} = $Find_Fs1;
    $self->{'find_fs2'} = $Find_Fs2;
    
    $self->{'text_pad'} = $Text_Pad;
    $self->{'text_gap'} = $Text_Gap;
    $self->{'text_spc'} = $Text_Spc;
    $self->{'text_fs1'} = $Text_Fs1;
    $self->{'text_fs2'} = $Text_Fs2;
    
    $self->{'ungapped_length'} = undef; #computed once on call to ungapped_length()

    bless $self, $type;

    $self;
}

#sub DESTROY { warn "DESTROY $_[0]\n" }

sub print {
    sub _format {
	my ($self, $k, $v) = @_;
	$v = 'undef' unless defined $v;
	$v = "$v [@{[$self->string]}]" if $k eq 'seq';
	$v = "'$v'" if $v =~ /^\s*$/;
	return sprintf("  %-15s => %s\n", $k, $v)
    }
    my $self = shift;
    warn "$self\n";
    map { warn $self->_format($_, $self->{$_}) } sort keys %$self;
    $self;
}

sub encode {
    my ($self, $s) = @_;

    #leading non-sequence characters
    while ($$s =~ s/^($Mark_Pad*)$self->{'find_gap'}/$1$Mark_Pad/g) {}
    
    #trailing non-sequence characters
    while ($$s =~ s/$self->{'find_gap'}($Mark_Pad*)$/$Mark_Pad$1/g) {}
    
    #internal gap characters
    $$s =~ s/$self->{'find_gap'}/$Mark_Gap/g;

    #internal spaces
    $$s =~ s/$self->{'find_spc'}/$Mark_Spc/g;

    #frameshift '/'
    $$s =~ s/$self->{'find_fs1'}/$Mark_Fs1/g;

    #frameshift '\'
    $$s =~ s/$self->{'find_fs2'}/$Mark_Fs2/g;

    $self;
}

#return effective sequence length given by lower/upper bounds
sub length {
    return $_[0]->{'hi'} - $_[0]->{'lo'} + 1    if $_[0]->{'lo'} > 0;
    return 0;
}

#return effective sequence length given by lower/upper bounds
sub ungapped_length {
    $_[0]->{'ungapped_length'} = length( $_[0]->ungapped_string )
	unless defined $_[0]->{'ungapped_length'};
    return $_[0]->{'ungapped_length'};
}

#return positive oriented begin/end positions
sub lo { $_[0]->{'lo'} }
sub hi { $_[0]->{'hi'} }

#return real oriented begin/end positions
sub from { $_[0]->{'lo'} }
sub to   { $_[0]->{'hi'} }

#return original from/to labels (default, or eg., search query)
sub fromlabel1 { $_[0]->{'f1'} }
sub tolabel1   { $_[0]->{'t1'} }

#return original from/to labels, second set (eg., search hit)
sub fromlabel2 { $_[0]->{'f2'} }
sub tolabel2   { $_[0]->{'t2'} }

#return lengths of leading/trailing terminal gap regions
sub leader  { my $n = $_[0]->{'seqbeg'} - $_[0]->{'lo'}; $n > -1 ? $n : 0 }
sub trailer { my $n = $_[0]->{'hi'} - $_[0]->{'seqend'}; $n > -1 ? $n : 0 }

sub set_find_pad { $_[0]->{'find_pad'} = $_[1] }
sub set_find_gap { $_[0]->{'find_gap'} = $_[1] }
sub set_find_spc { $_[0]->{'find_spc'} = $_[1] }
sub set_find_fs1 { $_[0]->{'find_fs1'} = $_[1] }
sub set_find_fs2 { $_[0]->{'find_fs2'} = $_[1] }

sub set_pad { $_[0]->{'text_pad'} = $_[1] }
sub set_gap { $_[0]->{'text_gap'} = $_[1] }
sub set_spc { $_[0]->{'text_spc'} = $_[1] }
sub set_fs1 { $_[0]->{'text_fs1'} = $_[1] }
sub set_fs2 { $_[0]->{'text_fs2'} = $_[1] }

sub get_pad { $_[0]->{'text_pad'} }
sub get_gap { $_[0]->{'text_gap'} }
sub get_spc { $_[0]->{'text_spc'} }
sub get_fs1 { $_[0]->{'text_fs1'} }
sub get_fs2 { $_[0]->{'text_fs2'} }

sub set_range {
    my ($self, $lo, $hi) = @_;
    die "$self: range values in wrong order ($lo, $hi)\n"    if $lo > $hi;
    ($self->{'lo'}, $self->{'hi'}) = ($lo, $hi);
    $self;
}

sub is_reversed {0}

sub reverse {
    no strict qw(subs);
    bless $_[0], Bio::MView::Reversed_Sequence;
}

#Horribly inefficient search for all matches of a regexp in the possibly
#gapped sequence, ie., regexp matches can span gapchars. Returns a reference
#to a list of matched non-gap sequence positions (indexing from 1).
sub findall {
    my ($self, $blocks, $mapsize) = @_;
    my $list = [];
    my $ungapped = $self->ungapped_string;
    my @gapped = split(//, $self->string);
    my $gapchar = $self->{text_gap};

    #warn "@{[$self->string]}\n";
    #warn "BLOCK=$pattern\n";

    my $end = scalar @$blocks;

    for (my $blocknum=0; $blocknum<$end; $blocknum++) {
	#warn $blocknum, $blocks->[$blocknum];
	my $blockid = chr(ord('A') + $blocknum % $mapsize);
	my $pattern = $blocks->[$blocknum];
	study $pattern;

	for (my ($i,$j) = (0,0); $j<length($ungapped); $i++, $j++) {
	    while ($gapped[$i] eq $gapchar) {
		$i++;  #sync gapped/ungapped string indices
	    }
	    my $s = substr($ungapped, $j);
	    if ($s =~ /^($pattern)/i) {  #case insensitive
		my @match = split(//, $1);
		#warn "\n$i,$j [@match] $s\n";
		for (my ($k,$l) = ($i,0); $l<@match; $k++, $l++) {
		    while ($gapped[$k] eq $gapchar) {
			$k++;  #absorb gaps
		    }
		    push @$list, [$blockid, $k+1];
		}
	    }
	}
    }
    return $list;
}

#input each argument frag as [string, from, to], where from <= to
sub append {
    my $self = shift;
    my ($string, $frag, $len, $i, $p, $c, $state);

    $state = 0;

    foreach $frag (@_) {
	die "${self}::append() wrong direction ($frag->[1], $frag->[2])\n"
	    if $frag->[1] > $frag->[2];

	$string = ${ $frag->[0] };
        #warn "+frg=@$frag\n";
        #warn "+frg=$frag->[1], $frag->[2] [$string]\n";

	$self->encode(\$string);
	#warn "frg=$frag->[1], $frag->[2] [$string]\n";

	$len = CORE::length $string;
	
        #update sequence ranges
        my $f = $frag->[1];
        my $t = $frag->[2];

        $self->{'lo'} = $f  if $f < $self->{'lo'} or $self->{'lo'} == 0;
        $self->{'hi'} = $t  if $t > $self->{'hi'} or $self->{'hi'} == 0;
    
        #update sequence labels: optional first pair
        if (defined $frag->[3] and $frag->[3] != 0) {
	    $self->{'f1'} = $frag->[3]   unless defined $self->{'f1'};
	    $self->{'t1'} = $frag->[4]   unless defined $self->{'t1'};
	    $f = $frag->[3];
	    $t = $frag->[4];
	    if ($f < $t or $self->{'f1'} < $self->{'t1'}) {
		#label pair orientated positive
		$self->{'f1'} = $f  if $f < $self->{'f1'};
		$self->{'t1'} = $t  if $t > $self->{'t1'};
	    } else {
		#label pair orientated negative
		$self->{'f1'} = $f  if $f > $self->{'f1'};
		$self->{'t1'} = $t  if $t < $self->{'t1'};
	    }
	}
    
        #update sequence labels: optional second pair
        if (defined $frag->[5] and $frag->[5] != 0) {
	    $self->{'f2'} = $frag->[5]   unless defined $self->{'f2'};
	    $self->{'t2'} = $frag->[6]   unless defined $self->{'t2'};
	    $f = $frag->[5];
	    $t = $frag->[6];
	    if ($f < $t or $self->{'f2'} < $self->{'t2'}) {
		#label pair orientated positive
		$self->{'f2'} = $f  if $f < $self->{'f2'};
		$self->{'t2'} = $t  if $t > $self->{'t2'};
	    } else {
		#label pair orientated negative
		$self->{'f2'} = $f  if $f > $self->{'f2'};
		$self->{'t2'} = $t  if $t < $self->{'t2'};
	    }
	}
    
	#populate sparse array
	for ($i=0; $i < $len; $i++) {

	    $c = substr($string, $i, 1);

	    #begin/end
	    if ($c eq $Mark_Pad) {
		if ($state == 0) {
		    $self->{'prefix'}++;
		} elsif ($state > 0) {
		    $self->{'suffix'}++;
		    $state = 2;
		}
		next;
	    }

	    #middle
	    $state = 1    if $state < 1;

	    #skip gaps
	    next    if $c eq $Mark_Gap;

	    $p = $frag->[1] + $i;
	    
	    #warn "append(+): $p/($self->{'lo'},$self->{'hi'}) = $i/$len\t[$c]\n";

	    #store other text, including Mark_Spc or Mark_Fs[12] symbols
	    if (exists $self->{'seq'}->{$p}) {
		next if $self->{'seq'}->{$p} eq $c;
		warn "assembly clash $self->{'seq'}->{$p} -> $c at $p\n"
		    if $REPORT_CLASH;
		next unless $OVERWRITE;
	    }
	    $self->{'seq'}->{$p} = $c;
	}

	#warn "append(+): $self->{'lo'} $self->{'hi'}\n";
    }

    #adjust prefix/suffix positions given new lengths
    $self->{'seqbeg'} = $self->{'lo'} + $self->{'prefix'};
    $self->{'seqend'} = $self->{'hi'} - $self->{'suffix'};

    #self->print;

    $self;
}

sub string  { $_[0]->_substr($_[0]->{'lo'}, $_[0]->{'hi'}) }

sub ungapped_string {
    my $s = $_[0]->_substr($_[0]->{'lo'}, $_[0]->{'hi'});
    $s =~ s/$_[0]->{text_gap}//og;
    $s =~ s/$_[0]->{text_pad}//og;
    $s =~ s/$_[0]->{text_gap}//og;
    $s =~ s/$_[0]->{text_spc}//og;
    $s =~ s/$_[0]->{text_fs1}//og;
    if ($_[0]->{text_fs2} eq $Text_Fs2) {  #backslash
	$s =~ s/$_[0]->{text_fs2}$_[0]->{text_fs2}//og;
    } else {
	$s =~ s/$_[0]->{text_fs2}//og;
    }
    $s;
}

sub _substr {
    my ($self, $start, $stop) = (@_, 1);
    my ($s, $i) = ('');

    return $s  if $start < 1 or $stop < 1;   #negative range args
    return $s  unless $self->{'lo'} > 0;     #empty
    return $s  if $stop  < $self->{'lo'};    #missed (too low)
    return $s  if $start > $self->{'hi'};    #missed (too high)

    $stop = $self->{'hi'}  if $stop > $self->{'hi'};
    #warn "$start, $stop";
    #warn "$self->{'seqbeg'}, $self->{'seqend'}";
    $stop++;
    
    for ($i = $start; $i < $stop; $i++) {
	if ($i < $self->{'seqbeg'} or $i > $self->{'seqend'}) {
	    $s .= $self->{'text_pad'};
	    next;
	}
	#warn "$i [$self->{'seq'}->{$i}]";
	$s .= exists $self->{'seq'}->{$i} ?
	    $self->{'seq'}->{$i} : $self->{'text_gap'};
    }
    $s =~ s/$Mark_Spc/$self->{'text_spc'}/g;
    $s =~ s/$Mark_Fs1/$self->{'text_fs1'}/g;
    $s =~ s/$Mark_Fs2/$self->{'text_fs2'}/g;
    return $s;
}

sub raw {
    my ($self, $col, $p) = @_;

    $p = $col + $self->{'lo'} - 1;

    return ''  if $p < $self->{'lo'} or $p > $self->{'hi'};

    return $Mark_Pad
	if $p < $self->{'seqbeg'} or $p > $self->{'seqend'};
    return $self->{'seq'}->{$p}
        if exists $self->{'seq'}->{$p};
    return $Mark_Gap;
}

sub col {
    my ($self, $col, $p) = @_;

    $p = $col + $self->{'lo'} - 1;

#    warn("$col [", 
#	 exists $self->{'seq'}->{$col} ? $self->{'seq'}->{$col} : '',
#	 "]=> $p [", 
#	 exists $self->{'seq'}->{$p} ? $self->{'seq'}->{$p} : '',
#	 "]\n");
    
    return ''  if $p < $self->{'lo'} or $p > $self->{'hi'};

    return $self->{'text_pad'}
        if $p < $self->{'seqbeg'} or $p > $self->{'seqend'};
    if (exists $self->{'seq'}->{$p}) {
	return $self->{'text_spc'} if $self->{'seq'}->{$p} eq $Mark_Spc;
	return $self->{'text_fs1'} if $self->{'seq'}->{$p} eq $Mark_Fs1;
	return $self->{'text_fs2'} if $self->{'seq'}->{$p} eq $Mark_Fs2;
	return $self->{'seq'}->{$p};
    }
    return $self->{'text_gap'};
}

sub is_char {
    $_[1] ne $Mark_Pad and $_[1] ne $Mark_Gap and $_[1] ne $Mark_Spc
	and $_[1] ne $Mark_Fs1 and $_[1] ne $Mark_Fs2;
}
sub is_non_char     { ! $_[0]->is_char($_[1]) }
sub is_space        { $_[1] eq $Mark_Spc }
sub is_frameshift   { $_[1] eq $Mark_Fs1 or $_[1] eq $Mark_Fs2 }
sub is_terminal_gap { $_[1] eq $Mark_Pad }
sub is_internal_gap { $_[1] eq $Mark_Gap }
sub is_gap          { $_[1] eq $Mark_Pad or $_[1] eq $Mark_Gap }

###########################################################################
package Bio::MView::Reversed_Sequence;

use Bio::MView::Sequence;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::MView::Sequence);

#return real oriented begin/end positions
sub from { $_[0]->{'hi'} }
sub to   { $_[0]->{'lo'} }

sub is_reversed {1}

sub reverse {
    no strict qw(subs);
    bless $_[0], Bio::MView::Sequence;
}

#input each argument frag as [string, from, to], where from >= to
sub append {
    my $self = shift;
    my ($string, $frag, $len, $i, $p, $c, $state);

    $state = 0;

    foreach $frag (@_) {
	die "${self}::append() wrong direction ($frag->[1], $frag->[2])\n"
	    if $frag->[2] > $frag->[1];

	$string = ${ $frag->[0] };
        #warn "-frg=@$frag\n";
        #warn "-frg=$frag->[1], $frag->[2] [$string]\n";

	$self->encode(\$string);
	#warn "frg=$frag->[1], $frag->[2] [$string]\n";

	$len = length $string;
	
        #update sequence ranges REVERSE
        my $f = $frag->[2];
        my $t = $frag->[1];

        $self->{'lo'} = $f  if $f < $self->{'lo'} or $self->{'lo'} == 0;
        $self->{'hi'} = $t  if $t > $self->{'hi'} or $self->{'hi'} == 0;
    
        #update sequence labels: optional first pair
        if (defined $frag->[3] and $frag->[3] != 0) {
	    $self->{'f1'} = $frag->[3]   unless defined $self->{'f1'};
	    $self->{'t1'} = $frag->[4]   unless defined $self->{'t1'};
	    $f = $frag->[3];
	    $t = $frag->[4];
	    if ($f < $t or $self->{'f1'} < $self->{'t1'}) {
		#label pair orientated positive
		$self->{'f1'} = $f  if $f < $self->{'f1'};
		$self->{'t1'} = $t  if $t > $self->{'t1'};
	    } else {
		#label pair orientated negative
		$self->{'f1'} = $f  if $f > $self->{'f1'};
		$self->{'t1'} = $t  if $t < $self->{'t1'};
	    }
	}
    
        #update sequence labels: optional second pair
        if (defined $frag->[5] and $frag->[5] != 0) {
	    $self->{'f2'} = $frag->[5]   unless defined $self->{'f2'};
	    $self->{'t2'} = $frag->[6]   unless defined $self->{'t2'};
	    $f = $frag->[5];
	    $t = $frag->[6];
	    if ($f < $t or $self->{'f2'} < $self->{'t2'}) {
		#label pair orientated positive
		$self->{'f2'} = $f  if $f < $self->{'f2'};
		$self->{'t2'} = $t  if $t > $self->{'t2'};
	    } else {
		#label pair orientated negative
		$self->{'f2'} = $f  if $f > $self->{'f2'};
		$self->{'t2'} = $t  if $t < $self->{'t2'};
	    }
	}

	#populate sparse array
	for ($i=0; $i < $len; $i++) {

	    $c = substr($string, $i, 1);

	    #begin/end
	    if ($c eq $Bio::MView::Sequence::Mark_Pad) {
		if ($state == 0) {
		    $self->{'prefix'}++;
		} elsif ($state > 0) {
		    $self->{'suffix'}++;
		    $state = 2;
		}
		next;
	    }

	    #middle
	    $state = 1    if $state < 1;

	    #skip gaps
	    next    if $c eq $Bio::MView::Sequence::Mark_Gap;

	    $p = $frag->[1] - $i;    #REVERSE
	    
	    #warn "append(-): $p/($self->{'lo'},$self->{'hi'}) = $i/$len\t[$c]\n";

	    #store other text, including Mark_Spc or Mark_Fs[12] symbols
	    if (exists $self->{'seq'}->{$p}) {
		next if $self->{'seq'}->{$p} eq $c;
		warn "reverse assembly clash $self->{'seq'}->{$p} -> $c at $p\n"
		    if $REPORT_CLASH;
		next unless $OVERWRITE;
	    }
	    $self->{'seq'}->{$p} = $c;
	}
	
	#warn "append(-): $self->{'lo'} $self->{'hi'}\n";
    }

    #adjust prefix/suffix positions given new lengths
    $self->{'seqbeg'} = $self->{'hi'} - $self->{'prefix'};
    $self->{'seqend'} = $self->{'lo'} + $self->{'suffix'};

    #$self->print;

    $self;
}

sub _substr {
    my ($self, $stop, $start) = (@_, 1); #REVERSE
    my ($s, $i) = ('');

    return $s  if $start < 1 or $stop < 1;   #negative range args
    return $s  unless $self->{'lo'} > 0;     #empty
    return $s  if $stop  > $self->{'hi'};    #missed (too high)
    return $s  if $start < $self->{'lo'};    #missed (too low)

    $stop = $self->{'lo'}  if $stop < $self->{'lo'};
    #warn "$start, $stop";
    #warn "$self->{'seqbeg'}, $self->{'seqend'}";
    $stop--;
    
    for ($i = $start; $i > $stop; $i--) {
	if ($i > $self->{'seqbeg'} or $i < $self->{'seqend'}) {
	    $s .= $self->{'text_pad'};
	    next;
	}
	#warn "$i [$self->{'seq'}->{$i}]";
	$s .= exists $self->{'seq'}->{$i} ?
	    $self->{'seq'}->{$i} : $self->{'text_gap'};
    }
    $s =~ s/$Bio::MView::Sequence::Mark_Spc/$self->{'text_spc'}/g;
    $s =~ s/$Bio::MView::Sequence::Mark_Fs1/$self->{'text_fs1'}/g;
    $s =~ s/$Bio::MView::Sequence::Mark_Fs2/$self->{'text_fs2'}/g;
    return $s;
}

sub raw {
    my ($self, $col, $p) = @_;

    $p = $self->{'hi'} - $col + 1;    #REVERSE $col

    return ''  if $p < $self->{'lo'} or $p > $self->{'hi'};

    return $Bio::MView::Sequence::Mark_Pad
	if $p > $self->{'seqbeg'} or $p < $self->{'seqend'};
    return $self->{'seq'}->{$p}
        if exists $self->{'seq'}->{$p};
    return $Bio::MView::Sequence::Mark_Gap;
}

sub col {
    my ($self, $col, $p) = @_;

    $p = $self->{'hi'} - $col + 1;    #REVERSE $col

#    warn("$col [", 
#	 exists $self->{'seq'}->{$col} ? $self->{'seq'}->{$col} : '',
#	 "]=> $p [", 
#	 exists $self->{'seq'}->{$p} ? $self->{'seq'}->{$p} : '',
#	 "]\n");

    return ''  if $p < $self->{'lo'} or $p > $self->{'hi'};

    return $self->{'text_pad'}
	if $p > $self->{'seqbeg'} or $p < $self->{'seqend'};
    if (exists $self->{'seq'}->{$p}) {
	return $self->{'text_spc'}
	    if $self->{'seq'}->{$p} eq $Bio::MView::Sequence::Mark_Spc;
	return $self->{'text_fs1'}
	    if $self->{'seq'}->{$p} eq $Bio::MView::Sequence::Mark_Fs1;
	return $self->{'text_fs2'}
	    if $self->{'seq'}->{$p} eq $Bio::MView::Sequence::Mark_Fs2;
	return $self->{'seq'}->{$p};
    }
    return $self->{'text_gap'};
}


###########################################################################
1;
