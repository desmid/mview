# Copyright (C) 1997-2018 Nigel P. Brown

use strict;

###########################################################################
package Bio::MView::Align::Sequence;

use Bio::MView::Align::Row;
use Bio::MView::Color::ColorMap;
use Bio::MView::Align::ColorMixin;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Align::Row Bio::MView::Align::ColorMixin);

sub new {
    my $type = shift;
    #warn "${type}::new(@_)\n";
    die "${type}::new: missing arguments\n"  if @_ < 2;
    my ($id, $sob) = @_;

    my $self = new Bio::MView::Align::Row('sequence', $id);
    bless $self, $type;

    $self->{'from'}   = $sob->lo;  #start number of sequence
    $self->{'string'} = $sob;      #sequence object

    $self->reset_display;          #hash of display parameters

    $Bio::MView::Align::ColorMixin::FIND_WARNINGS = 1;  #reset

    $self;
}

######################################################################
# public methods
######################################################################
#override
sub is_sequence { 1 }

sub from     { $_[0]->{'from'} }
sub seqobj   { $_[0]->{'string'} }
sub string   { $_[0]->{'string'}->string }
sub sequence { $_[0]->{'string'}->sequence }
sub seqlen   { $_[0]->{'string'}->seqlen }

sub set_coverage {
    #warn "Bio::MView::Align::Sequence::set_coverage(@_)\n";
    my ($self, $ref) = @_;
    my $val = $self->compute_coverage_wrt($ref);
    $self->set_display('label4' => sprintf("%.1f%%", $val));
}

sub get_coverage {
    if (exists $_[0]->{'display'}->{'label4'} and
        defined $_[0]->{'display'}->{'label4'}) {
        return $_[0]->{'display'}->{'label4'};
    }
    return '';
}

sub set_identity {
    #warn "Bio::MView::Align::Sequence::set_identity(@_)\n";
    my ($self, $ref, $mode) = @_;
    my $val = $self->compute_identity_to($ref, $mode);
    $self->set_display('label5' => sprintf("%.1f%%", $val));
}

sub get_identity {
    if (exists $_[0]->{'display'}->{'label5'} and
        defined $_[0]->{'display'}->{'label5'}) {
        return $_[0]->{'display'}->{'label5'};
    }
    return '';
}

# Compute the percent coverage of a row with respect to a reference row.
#
# \frac{\mathrm{number~of~residues~in~row~aligned~with~reference~row}}
#      {\mathrm{length~of~ungapped~reference~row}}
# \times 100
#
sub compute_coverage_wrt {
    #warn "Bio::MView::Align::Sequence::compute_coverage_wrt(@_)\n";
    my ($self, $othr) = @_;

    return 0      unless defined $othr;
    return 100.0  if $self == $othr;  #always 100% coverage of self

    die "${self}::compute_coverage_wrt: length mismatch\n"
	unless $self->length == $othr->length;

    my ($sc, $oc) = (0, 0);
    my $end = $self->length +1;

    for (my $i=1; $i<$end; $i++) {

	my $c2 = $othr->{'string'}->raw($i);

	#reference must be a sequence character
	next  unless $self->{'string'}->is_char($c2);

	my $c1 = $self->{'string'}->raw($i);

	#count sequence characters
	$sc++  if $self->{'string'}->is_char($c1);
	$oc++  if $self->{'string'}->is_char($c2);
    }

    #compute percent coverage
    return 100.0 * $sc/$oc;
}

#Compute percent identity to a reference row.
#Normalisation depends on the mode argument:
#  'reference' divides by the reference sequence length,
#  'aligned' divides by the aligned region length (like blast),
#  'hit' divides by the hit sequence.
#The last is the same as 'aligned' for blast, but different for
#multiple alignments like clustal.
#
# Default (mode: 'aligned'):
#
# \frac{\mathrm{number~of~identical~residues}}
#      {\mathrm{length~of~ungapped~reference~row~over~aligned~region}}
# \times 100
#
sub compute_identity_to {
    #warn "Bio::MView::Align::Sequence::compute_identity_to(@_)\n";
    my ($self, $othr, $mode) = (@_, 'aligned');

    return 0      unless defined $othr;
    return 100.0  if $self == $othr;  #always 100% identical to self

    die "${self}::compute_identity_to: length mismatch\n"
	unless $self->length == $othr->length;

    my ($sum, $len) = (0, 0);
    my $end = $self->length +1;

    for (my $i=1; $i<$end; $i++) {
	my $cnt = 0;

	my $c1 = $self->{'string'}->raw($i);
	my $c2 = $othr->{'string'}->raw($i);

	#at least one must be a sequence character
	$cnt++  if $self->{'string'}->is_char($c1);
	$cnt++  if $self->{'string'}->is_char($c2);
	next  if $cnt < 1;

        #standardize case
        $c1 = uc $c1; $c2 = uc $c2;

	#ignore terminal gaps in the *first* sequence
	$len++  unless $self->{'string'}->is_terminal_gap($c1);

        #ignore unknown character: contributes to length only
        next  if $c1 eq 'X' or $c2 eq 'X';

	$sum++  if $c1 eq $c2;
	#warn "[$i] $c1 $c2 : $cnt => $sum / $len\n";
    }

    #normalise identities
    my $norm = 0;
    if ($mode eq 'aligned') {
	$norm = $len;
    } elsif ($mode eq 'reference') {
	$norm = $othr->seqlen;
    } elsif ($mode eq 'hit') {
	$norm = $self->seqlen;
    }
    #warn "normalization mode: $mode, value= $norm\n";
    #warn "identity $self->{'id'} = $sum/$norm\n";

    return ($sum = 100 * ($sum + 0.0) / $norm)    if $norm > 0;
    return 0;
}

######################################################################
# private methods
######################################################################
#override
sub reset_display {
    $_[0]->SUPER::reset_display(
        'type'     => $_[0]->display_type,
        'label1'   => $_[0]->id,
        'sequence' => $_[0]->seqobj,
        'range'    => [],
    );
}

#override
sub length { $_[0]->{'string'}->length }

######################################################################
# debug
######################################################################
#sub DESTROY { warn "DESTROY $_[0]\n" }


###########################################################################
1;
