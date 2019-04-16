# Copyright (C) 1996-2019 Nigel P. Brown

# This file is part of MView.
# MView is released under license GPLv2, or any later version.

use strict;

###########################################################################
package Bio::Parse::Record;

use Bio::Util::Object;
use Bio::Parse::Scanner;

use vars qw(@ISA);

@ISA = qw(Bio::Util::Object);

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

    #subrecord counter
    $self->{'index'} = $self->get_record_number($parent);

    #relative key for reporting
    $self->{'relative_key'} = $self->get_type() . $KEY_DELIM . $self->{'index'};

    #absolute hierarchical key for indexing/reporting
    $self->{'absolute_key'} = $self->make_absolute_key();

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

#return record starting offset
sub get_offset { $_[0]->{'text'}->get_offset() }

#return record bytes read
sub get_bytes { $_[0]->{'text'}->get_bytes() }

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
    return $self->get_parsed_subrecord($rec);
}

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
    my ($self, $line) = (shift, shift);
    my $bad = 0; map { $bad++  if $_ eq '' } @_;
    return  unless $bad;
    $line = $$line; chomp $line;
    $self->warn("incomplete match of line: '$line'");
}

sub test_records {
    my $self = shift;
    local $_;
    foreach (@_) {
        $self->warn("corrupt or missing '$_' record\n")
            unless exists $self->{'record_by_type'}->{$_};
    }
}

#Given a record key and optional 1-based index, parse corresponding records
#and return an array of the parsed objects or the first object if called in
#a scalar context. If called with no argument or just '*' parse everything at
#this level.
sub parse {
    my $self = shift;
    my ($key, $num) = @_;
    my (@list, @keys) = ();

    #warn "parse(key=@{[defined $key?$key:'']}, num=@{[defined $num?$num:'']})\n";

    if (@_ == 0 or $key eq '*') {
        @keys = keys %{$self->{'record_by_type'}};
    } else {
        push @keys, $key;
    }

    foreach my $key (@keys) {
        #warn "parse: $key\n";
        foreach my $rec ($self->get_records_for_key($key, $num)) {
            push @list, $self->get_parsed_subrecord($rec);
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
    my $self = shift;
    my ($key) = @_;
    my (@list, @keys) = ();

    #warn "count(key=@{[defined $key?$key:'']})\n";

    if (@_ == 0 or $key eq '*') {
        @keys = sort keys %{$self->{'record_by_type'}};  #note: sorted
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

sub strip_leading_identifier_chars {
    my $text = shift;
    $text =~ s/^(\/:|>)//;  #leading "/:" or ">"
    return $text;
}

sub strip_trailing_identifier_chars {
    my $text = shift;
    $text =~ s/[;:|,.-]+$//;  #default trailing PDB chain is often '_'
    return $text;
}

sub clean_identifier {
    my $text = shift;
    $text = strip_leading_identifier_chars($text);
    $text = strip_trailing_identifier_chars($text);
    return $text;
}

###########################################################################
# private methods
###########################################################################
#sub DESTROY { warn "DESTROY $_[0]\n" }

sub make_absolute_key {
    my $self = shift;
    my $key = '';
    $key = $self->{'parent'}->{'absolute_key'}. $KEY_DELIM
        if defined $self->{'parent'};
    $key .= $self->{'relative_key'};
    return $key;
}

sub get_parsed_subrecord {
    my ($self, $rec) = @_;
    #warn "get_parsed_subrecord($rec = [@$rec])\n";
    $self->parse_subrecord($rec)  unless defined $rec->[3];
    return $rec->[3];
}

#Given a triple (key, offset, bytecount) in $rec, extract the record
#string, generate an object subclassed from $class, store this in $rec
#after the existing triple.
sub parse_subrecord {
    my ($self, $rec) = @_;
    my ($class, $ob);
    $class = ref($self) . '::' . $rec->[0];
    #warn "parse_subrecord: new $class($self, $self->{'text'}, $rec->[1], $rec->[2])\n";
    $ob = $class->new($self, $self->{'text'}, $rec->[1], $rec->[2]);
    push @$rec, $ob;
}

sub get_type {
    my @id = split('::', ref($_[0]));
    return pop @id;
}

sub get_record_number {
    my ($self, $parent) = (@_, undef);
    return 0  unless defined $parent;
    my $type = $self->get_type;
    for (my $i=0; $i < @{$parent->{'record_by_type'}->{$type}}; $i++) {
        my $rec = $parent->{'record_by_type'}->{$type}->[$i];
        return $i+1  if $rec->[1] == $self->{'offset'};
    }
    #there is no record number
    return 0;
}

#Explicitly call this when finished with a Record to ensure indirect
#circular references through 'parent' and 'record_by_*' fields are
#broken by resetting the 'parent' field. Likewise, set the shared 'text'
#field to undefined. Without this, the Record hierarchy is never garbaged until
#after the program exits! The caller can supply a list of subrecord types, in
#which case only those will be marked for destruction, not this Record.
sub free {
    my $self = shift;
    #warn "FREE $self (@_)\n";

    if (@_) {
        #only free these subrecord types
        foreach my $type (@_) {
            if (exists $self->{'record_by_type'}->{$type}) {
                foreach my $rec (@{$self->{'record_by_type'}->{$type}}) {
                    $self->free_record($rec);
                }
            }
        }
        return $self;
    }

    #free every subrecord
    foreach my $rec (@{$self->{'record_by_posn'}}) {
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

#Return an array of records indexed by key and optional index (1-based)
sub get_records_for_key {
    my ($self, $key, $num) = (@_, undef);

    return ()  unless exists $self->{'record_by_type'}->{$key};

    #key only
    return @{$self->{'record_by_type'}->{$key}}  unless defined $num;

    #key with num
    $num--;  #convert 1-based to 0-based
    return () unless defined $self->{'record_by_type'}->{$key}->[$num];
    return ($self->{'record_by_type'}->{$key}->[$num]);
}

# overrides Bio::Util::Object::make_message_string
# used by Bio::Util::Object::warn, Bio::Util::Object::die
sub make_message_string {
    my ($self, $prefix) = (shift, shift);
    my $s = $prefix;
    if (ref $self) {
        my $type = "$self"; $type =~ s/=.*//;
        my $path = $self->{'absolute_key'};
        $s .= " $type ($path)";
    } else {
        $s .= " $self";
    }
    $s .= ": " . Bio::Util::Object::_args_as_string(@_)  if @_;
    return $s;
}

###########################################################################
# debug methods
###########################################################################
# called in the parser test suite
sub print {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    printf "%sClass:  %s\n", $x, $self;
    printf "%sParent: %s\n", $x,
        defined $self->{'parent'} ? $self->{'parent'} : 'undef';
    printf "%sKey:    %s   Indices: []\n", $x, $self->{'relative_key'};

    printf "%s  Subrecords by posn:\n", $x;
    $self->print_records_by_posn($indent);

    printf "%s  Miscellaneous:\n", $x;
    printf "$x%20s -> %d\n",   'index', $self->{'index'};
    printf "$x%20s -> [%s]\n", 'pos',
        join(', ', ($self->{'offset'}, $self->{'bytes'}));
    my $tmp = '';
    if (defined $self->{'text'}) {
        $tmp   = $self->{'text'}->substr($self->{'offset'}, 30);
        ($tmp) = split("\n", $tmp);
    }
    printf "$x%20s -> \"%s\" ...\n",  'text', $tmp;

    printf "%s  Data:\n", $x;
    $self->print_data($indent);  #supplied by subclass
}

# helper for print()
sub print_records_by_posn {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x ($indent+2);
    my %count;
    foreach my $rec (@{$self->{'record_by_posn'}}) {
        my $label = $rec->[0];
        if (@{$self->{'record_by_type'}->{$rec->[0]}} > 1) {
            $label .=  '/' . ++$count{$rec->[0]};
        }
        printf "$x%20s -> [%s]\n", $label, join(", ", @$rec);
    }
}

# helper for print(); subclass overrides to add fields
sub print_data {}

# helper for print_data(); used by subclasses
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

#Given a record key and optional 1-based index, return an array of
#corresponding record strings or the first string if called in a scalar
#context. If called with just '*' return an array of all record strings at
#this level. If called with no argument return the whole database entry
#string as a scalar.
sub string {
    my $self = shift;
    my ($key, $num) = @_;
    my (@list, @keys) = ();

    #warn "string(key=@{[defined $key?$key:'']}, num=@{[defined $num?$num:'']})\n";

    if (@_ == 0) {
        return $self->{'text'}->substr($self->{'offset'}, $self->{'bytes'});
    } elsif ($key eq '*') {
        @keys = keys %{$self->{'record_by_type'}};
    } else {
        push @keys, $key;
    }

    foreach my $key (@keys) {
        foreach my $rec ($self->get_records_for_key($key, $num)) {
            if (defined $rec->[3]) {
                #print "STRING() calling child\n";
                push @list, $rec->[3]->string;
            } else {
                #print "STRING() calling substr [$rec->[1], $rec->[2]]\n";
                push @list, $self->{'text'}->substr($rec->[1], $rec->[2]);
            }
        }
    }

    return @list    if wantarray;
    return $list[0] if @list;
    return '';  #no data
}

###########################################################################
1;
