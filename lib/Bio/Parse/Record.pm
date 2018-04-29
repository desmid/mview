# Copyright (C) 1996-2018 Nigel P. Brown

use strict;

###########################################################################
package Bio::Parse::Record;

use Bio::Parse::Scanner;
use Bio::Parse::Message;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Message);

my $PACK_DELIM = "\0";
my $KEY_DELIM  = "::";

my $IGNORE_ATTR = "text|offset|bytes|index|parent|record_by_posn|record_by_type|indices|relative_key|absolute_key";

#Warning! the 'record_by_*' and 'parent' fields require explicit
#dereferencing otherwise perl won't garbage collect them until after the
#program exits. Therefore, the top-level Record of a Record tree should call
#the free() method when the caller has finished with it a record, to allow
#normal garbage collection at run-time.

sub new { #discard system supplied type
    my ($ignore, $type, $parent, $text, $offset, $bytes) = (@_, -1, -1);

    my $self = {};
    bless $self, $type;

    #warn $text->substr(), "\n";

    $self->{'text'}           = $text;
    $self->{'offset'}         = $offset;    #my string offset
    $self->{'bytes'}          = $bytes;     #my string length
    $self->{'parent'}         = $parent;    #parent record (to be free'd)
    $self->{'record_by_posn'} = [];         #list of records(to be free'd)
    $self->{'record_by_type'} = {};         #hash of record types (to be free'd)
    $self->{'indices'}        = [];         #additional keys for indexing

    #subrecord counter
    $self->{'index'}         = $self->get_record_number($parent);

    #relative key for reporting
    $self->{'relative_key'}  = $self->get_type . $KEY_DELIM . $self->{'index'};

    #absolute hierarchical key for indexing/reporting
    $self->{'absolute_key'}  = '';
    $self->{'absolute_key'}  = $parent->{'absolute_key'}. $KEY_DELIM  if
        defined $parent;
    $self->{'absolute_key'} .= $self->{'relative_key'};

    $self;
}

#Given a triple (key, offset, bytecount), store these as an anonymous array
#under the appropriate keys in the record_by_ attributes. Do NOT instantiate
#the record object.
sub push_record {
    my $self = shift;
    my $rec = [ @_ ];
    push @{$self->{'record_by_posn'}},              $rec;
    push @{$self->{'record_by_type'}->{$rec->[0]}}, $rec;
}

#Remove the latest stored record and free any instantiated parse object;
#returns the deleted record tuple.
sub pop_record {
    my $self = shift;
    my $rec = pop @{$self->{'record_by_posn'}};
    pop @{$self->{'record_by_type'}->{$rec->[0]}};
    return $self->free_record($rec);
}

sub get_parent {
    my ($self, $depth) = (@_, 1);
    $depth = -$depth  if $depth < 0;  #positive
    return $self  if $depth == 0;
    my $ptr = $self;
    while ($depth-- > 0) {
        return undef  unless defined $ptr->{'parent'};
        return $ptr->{'parent'}  if $depth < 1;
        $ptr = $ptr->{'parent'};
    }
    return undef;
}

sub get_record {
    my ($self, $type, $index) = (@_, 0);
    my $rec = $self->{'record_by_type'}->{$type}->[$index];
    return $self->get_object($rec);
}

sub push_indices {
    my ($self, @indices) = @_;
    push @{$self->{'indices'}}, @indices;
}

sub get_indices { @{$_[0]->{'indices'}} }

#Return list of attributes of Record, excepting housekeeping ones.
sub list_attrs {
    my $self = shift;
    my ($key, @attr);
    foreach $key (grep !/^($IGNORE_ATTR)$/o , keys %$self) {
	push @attr, $key;
    }
    return @attr;
}

sub test_args {
    my $self = shift;
    my $lineref = shift;
    my $i; foreach $i (@_) {
	next  if $i ne '';
        chomp $$lineref;
	$self->warn("incomplete match of line: $$lineref");
    }
}

sub test_records {
    my $self = shift;
    local $_;
    foreach (@_) {
        $self->warn("corrupt or missing '$_' record\n")
            unless exists $self->{'record_by_type'}->{$_};
    }
}

sub pack_hash {
    my $self = shift;
    my ($val, $rec, @indicies);

    @indicies = $self->get_indices;

    $val = join($PACK_DELIM,
		(
		 $self->relative_key,
		 $self->{'offset'},
		 $self->{'bytes'},
		 scalar(@indicies),
		 @indicies,
		));
    foreach $rec (@{$self->{'record_by_posn'}}) {
	#append (key, offset, bytes)
	$val .= join($PACK_DELIM,
		     (
		      '',
		      $rec->[0],
		      $rec->[1],
		      $rec->[2],
		     ));
    }
    return $val;
}

sub unpack_hash {
    my ($self, $val) = @_;
    my (@tmp, $num, $rec);

    @tmp = split($PACK_DELIM, $val);

    $self->{'relative_key'} = shift @tmp;
    $self->{'offset'}       = shift @tmp;
    $self->{'bytes'}        = shift @tmp;
    $num                    = shift @tmp;
    push @{$self->{'indices'}}, splice(@tmp, 0, $num);
    while (@tmp) {
	$self->push_record(splice(@tmp, 0, 3));
    }
}

sub fmt {
    my ($self, $val, $undef) = (@_, '<undef>');
    my $ref = ref $val;
    if ($ref eq 'HASH') {
        my @tmp = map {
            my $v = defined $val->{$_} ? $val->{$_} : $undef; "$_:$v"
        } sort keys %$val;
        return "{" . join(',', @tmp) . "}";
    }
    if ($ref eq 'ARRAY') {
        my @tmp = map { defined $_ ? $_ : $undef } @$val;
        return "[" . join(',', @tmp) . "]";
    }
    return defined $val ? $val : $undef;
}

sub print {
    my ($self, $indent) = (@_, 0);
    my ($tmp, $r, $i, $rec) = ('');
    my $x = ' ' x $indent;
    printf "%sClass:  %s\n", $x, $self;
    printf "%sParent: %s\n", $x, defined $self->{'parent'} ?
        $self->{'parent'} : 'undef';
    printf "%sKey:    %s   Indices: [%s]\n", $x,
        $self->relative_key, join(',', $self->get_indices);

    #print records in order of appearance in parent Record
    printf "%s  Subrecords by posn:\n", $x;
    $self->print_records_by_posn($indent);

    #print records in order of type
    #printf "%s  Subrecords by type:\n", $x;
    #$self->print_records_by_type($indent);

    printf "%s  Miscellaneous:\n", $x;
    printf "$x%20s -> %d\n",   'index', $self->{'index'};
    printf "$x%20s -> [%s]\n", 'pos', join(', ', $self->get_pos);
    if (defined $self->{'text'}) {
	## $tmp   = substr(${$self->{'text'}}, $self->{'offset'}, 30);
	$tmp   = $self->{'text'}->substr($self->{'offset'}, 30);
        ($tmp) = split("\n", $tmp);
    }
    printf "$x%20s -> \"%s\" ...\n",  'text', $tmp;
    printf "%s  Data:\n", $x;
    $self->print_data($indent);
}

sub print_data {}  #override to add fields in children

#extract a substring with offset and bytecount from the 'text' attribute,
#defaulting to the entire string
sub substr {
    my $self = shift;
    my ($offset, $bytes) = (@_, $self->{'offset'}, $self->{'bytes'});

    #warn "Record::substr(@_)\n";

    if (! defined $self->{'text'}) {
	$self->die("substr() $self text field undefined");
    }

    ## substr(${$self->{'text'}}, $offset, $bytes);
    return $self->{'text'}->substr($offset, $bytes);
}

#Given a record key for this entry, parse corresponding records and return
#an array of the parsed objects or the first object if called in a scalar
#context. If called with no argument or just '*' parse everything at this
#level.
sub parse {
    my ($self, $key) = (@_, '*');
    my (@list, @keys, $rec) = ();

    #warn "parse($key)\n";

    if ($key eq '*') {
	@keys = keys %{$self->{'record_by_type'}};
    } else {
	push @keys, $key;
    }

    foreach $key (@keys) {
        #warn "parse: $key\n";
	foreach $rec ($self->key_range($key)) {
            push @list, $self->get_object($rec);
	}
    }

    return @list    if wantarray;
    return $list[0] if @list;
    return undef;  #no data
}

#Given a record key for this entry, count how many corresponding records
#exist and return an array of counts or the first count if called in a
#scalar context. If called with no argument or just '*' count everything.
sub count {
    my ($self, $key) = (@_, '*');
    my (@list, @keys) = ();

    if ($key eq '*') {
	@keys = sort keys %{$self->{'record_by_type'}};
    } else {
	push @keys, $key;
    }

    foreach $key (@keys) {

	#is there a record instance for this type?
	if (exists $self->{'record_by_type'}->{$key}) {
	    push @list, scalar @{$self->{'record_by_type'}->{$key}};
	} else {
	    push @list, 0;
	}
    }

    return @list    if wantarray;
    return $list[0] if @list;
    return 0;  #no data
}

#tidy up identifiers: strip leading "/:" or ">" substrings
sub strip_leading_identifier_chars {
    my $string = shift;
    $string =~ s/^(\/:|>)//;
    return $string;
}

#Returns $text less newlines while attempting to assemble hyphenated words
#and excess white space split over multiple lines correctly.
sub strip_english_newlines {
    my $text = shift;

    #multiple hyphens look like 'SO4--' or long dashes - word break with space
    $text =~ s/(--)\s*\n+\s*/$1 /sg;

    #single hyphens look like hyphenated words - join at the hyphen
    $text =~ s/(-)\s*\n+\s*/$1/sg;

    #remaining newlines - word break with space
    $text =~ s/\s*\n+\s*/ /sg;

    #skip trailing white space added after last newline was removed
    $text =~ s/\s+$//s;

    return $text;
}

sub strip_leading_space {
    my $text = shift;
    $text =~ s/^[ \t]+//;
    return $text;
}

sub strip_trailing_space {
    my $text = shift;
    $text =~ s/[ \t]+$//;
    return $text;
}

sub strip_trailing_junk {
    my $text = shift;
    $text =~ s/[;:|,.-]+$//;  #default trailing PDB chain is often '_'
    return $text;
}

sub clean_identifier {
    my $text = shift;
    $text = strip_leading_identifier_chars($text);
    $text = strip_trailing_junk($text);
    return $text;
}

###########################################################################
# private methods
###########################################################################
#sub DESTROY { warn "DESTROY $_[0]\n" }

sub get_pos   { ($_[0]->{'offset'}, $_[0]->{'bytes'}) }
sub get_class { ref $_[0] }

sub relative_key { $_[0]->{'relative_key'} }
sub absolute_key { $_[0]->{'absolute_key'} }

sub get_object {
    my ($self, $rec) = @_;
    #warn "get_object($rec = [@$rec])\n";
    $self->add_object($rec)  unless defined $rec->[3];
    return $rec->[3];
}

sub get_type {
    my @id = split('::', ref($_[0]));
    return pop @id;
}

sub get_record_number {
    my ($self, $parent) = (@_, undef);
    my ($i, $type);
    if (defined $parent) {
	$type   = $self->get_type;
	for ($i=0; $i < @{$parent->{'record_by_type'}->{$type}}; $i++) {
	    if ($parent->{'record_by_type'}->{$type}->[$i]->[1] ==
		$self->{'offset'}) {
		return $i+1;
	    }
	}
    }
    #there is no record number
    return 0;
}

sub print_records_by_posn {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x ($indent+2);
    my ($rec, %count);
    foreach $rec (@{$self->{'record_by_posn'}}) {
	if (@{$self->{'record_by_type'}->{$rec->[0]}} > 1) {
	    printf "$x%20s -> [%s]\n",
	    $rec->[0] . '/' . ++$count{$rec->[0]}, join(", ", @$rec);
	} else {
	    printf "$x%20s -> [%s]\n",
	    $rec->[0],                             join(", ", @$rec);
	}
    }
}

sub print_records_by_type {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x ($indent+2);
    my ($key, $rec, $i);
    foreach $key (sort keys %{$self->{'record_by_type'}}) {
	if (@{$self->{'record_by_type'}->{$key}} > 1) {
	    for ($i=0; $i < @{$self->{'record_by_type'}->{$key}}; $i++) {
		$rec = $self->{'record_by_type'}->{$key}->[$i];
		printf "$x%20s -> [%s]\n",
		$rec->[0] . '/' . ($i+1),          join(", ", @$rec);
	    }
 	} else {
	    $rec = $self->{'record_by_type'}->{$key}->[0];
	    printf "$x%20s -> [%s]\n",
	    $rec->[0],                             join(", ", @$rec);
	}
    }
}

#Given a triple (key, offset, bytecount) in $rec, extract the record
#string, generate an object subclassed from $class, store this in $rec
#after the existing triple, and return the object.
sub add_object {
    my ($self, $rec) = @_;
    my ($class, $ob);
    $class = ref($self) . '::' . $rec->[0];
    #warn "ADD_OBJECT($class)\n";
    $ob = $class->new($self, $self->{'text'}, $rec->[1], $rec->[2]);
    push @$rec, $ob;
    return $ob;
}

#Explicitly call this when finished with a Record to ensure indirect
#circular references through 'parent' and 'record_by_*' fields are
#broken by resetting the 'parent' field. Likewise, set the shared 'text'
#field to undefined. Without this, the Record hierarchy is never garbaged until
#after the program exits! The caller can supply a list of subrecord types, in
#which case only those will be marked for destruction, not this Record.
sub free {
    my $self = shift;
    my ($type, $rec);

    #warn "FREE $self (@_)\n";

    if (@_) {
	#only free these subrecord types
	foreach $type (@_) {
	    if (exists $self->{'record_by_type'}->{$type}) {
		foreach $rec (@{$self->{'record_by_type'}->{$type}}) {
                    $self->free_record($rec);
		}
	    }
	}
	return $self;
    }

    #free every subrecord
    foreach $rec (@{$self->{'record_by_posn'}}) {
        $self->free_record($rec);
    }

    #free our records
    $self->{'parent'} = undef;
    $self->{'record_by_type'} = undef;
    $self->{'record_by_posn'} = undef;
    $self->{'text'} = undef;

    return $self;
}

#Given a record tuple reference, remove and recursively free any instantiated
#parse object; returns the tuple reference.
sub free_record {
    my ($self, $rec) = @_;
    return $rec  unless @$rec > 3;
    #warn "free_record: [", join(", ", @$rec), "]\n";
    $rec->[3]->free;           #recurse
    my $ob = splice @$rec, 3;  #excise parse object
    undef $ob;                 #remove parse object
    return $rec;
}

#Given a record key for this entry, return an array of corresponding record
#strings or the first string if called in a scalar context. If called with
#just '*' return an array of all record strings at this level. If called
#with no argument return the whole database entry string as a scalar.
sub string {
    my ($self, $key) = (@_, undef);
    my (@list, @keys, $rec) = ();

    #warn "string($key)\n";

    if (! defined $key) {
	return $self->substr($self->{'offset'}, $self->{'bytes'});
    }

    if ($key eq '*') {
	@keys = keys %{$self->{'record_by_type'}};
    }

    foreach $key (@keys) {
	foreach $rec ($self->key_range($key)) {
	    if (defined $rec->[3]) {
		#print "STRING() calling child\n";
		push @list, $rec->[3]->string;
	    } else {
		#print "STRING() calling substr [$rec->[1], $rec->[2]]\n";
		push @list, $self->substr($rec->[1], $rec->[2]);
	    }
	}
    }

    return @list    if wantarray;
    return $list[0] if @list;
    return '';  #no data
}

#Split a key string of forms 'key' or 'key[N]' or 'key[M..N]' and return
#an array of records so indexed. Supplied range indices are assumed to be
#positive 1-based and are converted to 0-based for internal use.
sub key_range {
    my ($self, $key) = @_;
    my ($lo, $hi, @rec) = (undef, undef);

    if ($key =~ /(\S+)\s*\[\s*(\d+)\s*\]/) {
	($key, $lo, $hi) = ($1, $2, $2);
    }
    if ($key =~ /(\S+)\s*\[\s*(\d+)\s*\.\.\s*(\d+)\s*\]/) {
	if ($2 < $3) {
	    ($key, $lo, $hi) = ($1, $2, $3);
	} else {
	    ($key, $lo, $hi) = ($1, $3, $2);
	}
    }

    #does the key map to a record type?
    return unless exists $self->{'record_by_type'}->{$key};

    #was a range requested?
    if (defined $lo) {

	$lo--; $hi--;    #convert to internal 0-based indices

	#want range?
	if ($lo != $hi) {
	    #adjust range to fit available records?
	    $lo = 0
		unless defined $self->{'record_by_type'}->{$key}[$lo];
	    $hi = $#{$self->{'record_by_type'}->{$key}}
	        unless defined $self->{'record_by_type'}->{$key}[$hi];
        } else {
	    #ignore non-existent single index
	    return unless $lo > -1 and defined $self->{'record_by_type'}->{$key}[$lo];
	}
	#get the slice
	@rec = @{$self->{'record_by_type'}->{$key}}[$lo..$hi];
    } else {
	#just get'em all
	@rec = @{$self->{'record_by_type'}->{$key}};
    }

    return @rec;
}

#warn with error string: override Message::warn() to a) be quiet
#about the classname and b) interpolate Bio::Parse::Record->get_absolute_key.
sub warn {
    my $self = shift;
    my $s = $_[$#_]; chomp $s;
    my $t = $self; $t =~ s/=.*//;
    warn "Warning $t ($self->{'absolute_key'}) $s\n";
}

###########################################################################
1;
