# Copyright (C) 1997-2018 Nigel P. Brown

use strict;

###########################################################################
package Bio::MView::Display::Ruler;

use Bio::MView::Display::Track;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Display::Track);

sub new {
    my $type = shift;
    my $self = new Bio::MView::Display::Track(@_);
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
sub next_segment {
    my ($self, $par) = @_;
    #warn "${self}::next_segment\n";

    return undef  if $self->{'cursor'} > $self->{'length'};

    #current real position: by orientation
    my $start;
    if ($self->{'forwards'}) {
        $start = $self->{'start'} + $self->{'cursor'} - 1;
    } else {
        $start = $self->{'stop'} - $self->{'cursor'} + 1;
    }

    my $rest  = $self->{'length'} - $self->{'cursor'} + 1;  #length remaining
    my $chunk = $par->{'width'} < $rest ? $par->{'width'} : $rest;

    #warn "($self->{'length'}, $self->{'cursor'}, $chunk, $rest, ($self->{'start'}, $self->{'stop'}))\n";

    my $string = [];
    my $pos = $start + ($self->{'forwards'} ? -1 : +1);

    for (my $i = 0; $i < $chunk; $i++) {

        $self->{'forwards'} ? $pos++ : $pos--;  #real data position

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
    $self->{'cursor'} += $chunk;

    $string = $self->finish_html($string, $par->{'bold'})  if $par->{'html'};

    return [ $start, join('', @$string), $pos ];
}

###########################################################################
1;
