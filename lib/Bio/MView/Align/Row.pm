# Copyright (C) 1997-2018 Nigel P. Brown

use strict;

###########################################################################
package Bio::MView::Align::Row;

sub new {
    my $type = shift;
    #warn "${type}::new(@_)\n";
    die "${type}::new: missing arguments\n"  if @_ < 2;
    my ($display_type, $uid) = @_;

    my $self = {};
    bless $self, $type;

    $self->{'display_type'} = $display_type;
    $self->{'uid'}          = $uid ne '' ? $uid : $self;

    $self->reset_display;

    $self;
}

######################################################################
# public methods
######################################################################
sub is_sequence  { 0 }  #subclass overrides
sub is_consensus { 0 }  #subclass overrides
sub is_special   { 0 }  #subclass overrides

sub set_display {
    my $self = shift;
    while (@_) {
	my ($key, $val) = (shift, shift);
        my $ref = ref $val;

	#shallow copy referenced data
	if ($ref eq 'HASH') {
	    $val = { %$val }
	}
        elsif ($ref eq 'ARRAY') {
	    $val = [ @$val ];
	}

	$self->{'display'}->{$key} = $val;
    }
}

sub uid          { $_[0]->{'uid'} }
sub get_display  { $_[0]->{'display'} }
sub display_type { $_[0]->{'display_type'} }

######################################################################
# private methods
######################################################################
#subclass overrides
sub reset_display {
    my $self = shift;
    $self->{'display'} = {};
    $self->set_display(@_);
}

#subclass overrides
sub length { 0 }

######################################################################
# debug
######################################################################
#sub DESTROY { warn "DESTROY $_[0]\n" }

sub dump { Universal::dump_object($_[0]) }

###########################################################################
1;
