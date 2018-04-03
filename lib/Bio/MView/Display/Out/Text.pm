# Copyright (C) 2018 Nigel P. Brown

use strict;

###########################################################################
package Bio::MView::Display::Out::Text;

sub new {
    my $type = shift;
    die "${type}::new: missing arguments\n"  if @_ < 1;
    my $self = {};
    bless $self, $type;

    $self->{'stm'} = shift;  #o/p stream

    $self;
}

######################################################################
# public methods
######################################################################
#subclass overrides
sub process_url {
    my ($self, $s, $url) = @_;
    return $s;
}

#subclass overrides
sub process_bold {
    my ($self, $s) = @_;
    return $s;
}

#subclass overrides
sub process_char {
    my ($self, $caller, $c) = @_;
    return $c;
}

#subclass overrides
sub process_segment {
    my ($self, $string, $bold) = @_;
    return $string;
}

###########################################################################
#subclass overrides
sub render_text {
    my $self = shift;
    my $stm = $self->{'stm'};
    foreach my $s (@_) {
        print($stm $s), next  if defined $s;
        print $stm "\n";  #replace undef with newline
    }
}

#subclass overrides
sub render_table_begin {}

#subclass overrides
sub render_table_end {}

#subclass overrides
sub render_tr_pre_begin {}

#subclass overrides
sub render_tr_pre_end {}

###########################################################################
1;
