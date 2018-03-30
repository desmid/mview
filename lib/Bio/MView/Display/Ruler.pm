# Copyright (C) 1997-2017 Nigel P. Brown

use strict;

###########################################################################
package Bio::MView::Display::Ruler;

use Bio::MView::Display::Any;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Display::Any);

sub new {
    my $type = shift;
    my $self = new Bio::MView::Display::Any(@_);
    bless $self, $type;

    if ($self->{'forwards'}) {
        $self->{'charlo'}   = '[';
        $self->{'charhi'}   = ']';
    } else {
        $self->{'charlo'}   = ']';
        $self->{'charhi'}   = '[';
    }

    $self;
}

#overrides
sub next {
    my $self = shift;
    #warn "${self}::next(@_)\n";
    my ($html, $bold, $col, $gap, $pad, $lap) = @_;

    return 0  if $self->{'cursor'} > $self->{'length'};

    my $rest = $self->{'length'} - $self->{'cursor'} + 1;  #length remaining

    #orientation
    my $forwards = $self->{'forwards'};

    #current real position
    my $start;
    if ($forwards) {
        $start = $self->{'start'} + $self->{'cursor'} - 1;
    } else {
        $start = $self->{'stop'} - $self->{'cursor'} + 1;
    }

    $col = $rest  if $col > $rest;  #override caller: consume smaller amount

    #warn "($self->{'cursor'}, $col, $rest, ($self->{'start'}, $self->{'stop'}))\n";

    my $string = [];
    my $pos = $start + ($forwards ? -1 : +1);

    for (my $i = 0; $i < $col; $i++) {

        $forwards ? $pos++ : $pos--;  #real data position

        #ruler ends
        if ($pos == $self->{'start'}) {
            push @$string, $self->{'charlo'};
            next;
        }
        if ($pos == $self->{'stop'}) {
            push @$string, $self->{'charhi'};
            next;
        }

        #ruler markings
        if ($pos % 100 == 0) {
            push @$string, substr($pos,-3,1);  #third digit from right
            next;
        }
        if ($pos % 50 == 0) {
            push @$string, ':';
            next;
        }
        if ($pos % 10 == 0) {
            push @$string, '.';
            next;
        }
#       if ($pos % 5 == 0) {
#           push @$string, '.';
#           next;
#       }

        push @$string, ' ';
    }
    $self->{'cursor'} += $col;

    $string = $self->finish_html($string, $bold)  if $html;

    return [ $start, join('', @$string), $pos ];
}

###########################################################################
1;
