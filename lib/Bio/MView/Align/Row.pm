# Copyright (C) 1997-2018 Nigel P. Brown

###########################################################################
package Bio::MView::Align::Row;

use strict;

#sub DESTROY { warn "DESTROY $_[0]\n" }

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

sub get_display { $_[0]->{'display'} }

sub is_sequence  { 0 }
sub is_consensus { 0 }
sub is_special   { 0 }

sub adjust_display {}

sub dump { Universal::dump_object($_[0]) }

sub color_none { die "function not implemented\n" }
sub color_special { die "function not implemented\n" }
sub color_by_type { die "function not implemented\n" }
sub color_by_identity { die "function not implemented\n" }
sub color_by_mismatch { die "function not implemented\n" }
sub color_by_consensus_sequence { die "function not implemented\n" }
sub color_by_consensus_group { die "function not implemented\n" }
sub color_by_find_block { die "function not implemented\n" }


###########################################################################
1;
