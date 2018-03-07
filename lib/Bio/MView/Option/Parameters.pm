# Copyright (C) 2018 Nigel P. Brown

###########################################################################
package Bio::MView::Option::Parameters;

use Exporter;
use strict;
use vars qw(@ISA @EXPORT $PAR);

@ISA = qw(Exporter);

@EXPORT = qw($PAR);

$PAR = undef;  #unique global instance

sub new {
    my ($type, $par) = @_;
    if (defined $PAR) {
        die "Bio::MView::Option::Parameters instance already exists\n";
    }
    my $self = {};
    bless $self, $type;

    $self->{'p'} = $par;

    return $PAR = $self;
}

#Return internal hash cloned and modified with any extra (key,val) pairs
#supplied by the caller.
sub as_dict {
    my $self = shift;
    my %clone = %{$self->{'p'}};
    while (@_) {
        my ($k, $v) = (shift, shift);
        $clone{$k} = $v;
    }
    return \%clone;
}

#Return value at $key or undef if it doesn't exist.
sub get {
    my ($self, $key) = @_;
    return $self->{'p'}->{$key}  if exists $self->{'p'}->{$key};
    return undef;  #no match
}

#Set value at $key to $val and return previous value or undef.
sub set {
    my ($self, $key, $val) = @_;
    my $old = undef;
    $old = $self->{'p'}->{$key}  if exists $self->{'p'}->{$key};
    $self->{'p'}->{$key} = $val;  #set new
    return $old;  #return old
}

#Copy value at key $src to key $dst. Do nothing if key $src doesn't exist.
#Return original value of key $dst or undef.
sub get_set {
    my ($self, $src, $dst) = @_;
    my $old = undef;
    $old = $self->{'p'}->{$dst}  if exists $self->{'p'}->{$dst};
    if (exists $self->{'p'}->{$src}) {
        $self->{'p'}->{$dst} = $self->{'p'}->{$src};
    } else {
        ;  #src doesn't exist: do nothing
    }
    return $old;
}

#Return pretty-printed parameter listing; operate on supplied keys or
#all keys if none given.
sub dump {
    my $self = shift;

    sub maxlen {
        my $w = 0;
        foreach my $key (@_) {
            $w = Universal::max($w, length(defined $key ? $key : '<NOEXIST>'));
        }
        return $w;
    }

    sub layout {
        my $w = shift; return sprintf("%${w}s => %s\n", @_);
    }

    my $p = $self->{'p'};
    push @_, sort keys %$p  unless @_;

    my $w = maxlen(@_); return ''  unless $w > 0;
    my $s = '';

    foreach my $key (@_) {
        if (exists $p->{$key}) {
            my $val = $p->{$key};
            if (! defined $val) {
                $s .= layout($w, $key, '<UNDEF>');
                next;
            }
            my $ref = ref $val;
            if ($ref) {
                if ($ref eq 'ARRAY') {
                    $s .= layout($w, $key, "@[" . join(',', @$val)  . "]");
                    next;
                }
                if ($ref eq 'HASH') {
                    my @tmp = map { "$_:$val->{$_}" } sort keys %$val;
                    $s .= layout($w, $key, "%{" . join(',', @tmp) . "}");
                    next;
                }
                $s .= layout($w, $key, '<$ref>');  #other ref
                next;
            }
            #SCALAR
            $s .= layout($w, $key, (length($val) > 0 ? $val : "'$val'"));
        } else {
            $s .= layout($w, $key, '<NOEXIST>');
        }

    }
    return $s;
}


###########################################################################
1;
