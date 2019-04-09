# Copyright (C) 1996-2019 Nigel P. Brown

# This file is part of MView.
# MView is released under license GPLv2, or any later version.

######################################################################
package Bio::Parse::Message;

use strict;

#dump sorted list of all instance variables, or supplied list
sub examine {
    my $self = shift;
    my @keys = @_ ? @_ : sort keys %$self;
    my $key;
    print "Class $self\n";
    foreach $key (@keys) {
        printf "%16s => %s\n", $key,
            defined $self->{$key} ? $self->{$key} : 'undef';
    }
    $self;
}

#warn with error string
sub warn {
    my $self = shift;
    my $s = $self->make_message_string('Warning', @_);
    warn "$s\n";
}

#exit with error string
sub die {
    my $self = shift;
    my $s = $self->make_message_string('Died', @_);
    die "$s\n";
}

sub make_message_string {
    my ($self, $prefix) = (shift, shift);
    my $s = "$prefix ";
    $s .= ref($self) ? ref($self) : $self;
    $s .= ": " . args_as_string(@_)  if @_;
    return $s;
}

###########################################################################
# private static
###########################################################################
sub args_as_string {
    my @tmp = ();
    foreach my $a (@_) {
        push @tmp, (defined $a ? $a : 'undef');
    }
    my $s = join(" ", @tmp);
    chomp $s;
    return $s;
}

###########################################################################
1;
