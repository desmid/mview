# Copyright (C) 1997-2018 Nigel P. Brown

use strict;

###########################################################################
package Bio::MView::Display::Track;

use Universal qw(vmstat);
use Bio::MView::Display::Display;

sub new {
    my $type = shift;
    my ($parent, $hash) = @_;
    my $self = {};
    bless $self, $type;

    $self->{'parent'}   = $parent;  #parent sequence object

    $self->{'length'}   = $parent->length;
    $self->{'start'}    = $parent->{'start'};
    $self->{'stop'}     = $parent->{'stop'};
    $self->{'forwards'} = $parent->forwards;

    $self->{'string'}   = undef;  #alternative sequence to parent
    $self->{'labels'}   = undef;  #annotation column labels
    $self->{'url'}      = '';     #URL; to associate with label1

    $self->{'string'}   = $hash->{'sequence'} if exists $hash->{'sequence'};
    $self->{'labels'}   = $hash->{'labels'}   if exists $hash->{'labels'};
    $self->{'url'}      = $hash->{'url'}      if exists $hash->{'url'};

    #warn "Track::labels: [@{[join(',', @{$self->{'labels'}})]}]\n";

    $self->{'cursor'} = 0;  #current position in display stream, 1-based

    #are 'parent' and 'string' the same length?
    if (defined $self->{'string'}) {
        my $len = $self->{'string'}->length;
        if ($len != $self->{'length'}) {
            die "${type}::new: parent/sequence length mismatch ($self->{'length'}, $len)\n";
        }
    }

    #character range maps: hold attributes by column
    $self->{'r_color'}  = [];  #colors
    $self->{'r_class'}  = [];  #solid/thin

    $hash->{'range'}    = []  unless exists $hash->{'range'};

    #warn "range: [@{[join(',', @{$hash->{'range'}})]}]\n";

    #populate the range maps
    foreach my $range (@{$self->parse_range($hash->{'range'})}) {
        my $start = $range->{'pos'}->[0];
        my $stop  = $range->{'pos'}->[$#{$range->{'pos'}}] + 1;
        for (my $i = $start; $i < $stop; $i++) {
            foreach my $key (keys %$range) {
                next  if $key eq 'pos';
                $self->{"r_$key"}->[$i] = $range->{$key};
            }
        }
    }

    #vmstat("Track::new: done");
    $self;
}

######################################################################
# public methods
######################################################################
sub has_positions { 0 }

#return kth label string
sub label {
    return ''  unless defined $_[0]->{'labels'}->[$_[1]];
    return $_[0]->{'labels'}->[$_[1]];
}

#return kth labelwidth
sub labelwidth {
    return 0  unless defined $_[0]->{'labels'}->[$_[1]];
    return length($_[0]->{'labels'}->[$_[1]]);
}

#forward/reverse oriented rulers/sequences
sub reset { $_[0]->{'cursor'} = 1 }

#stop iterating
sub done {
    return 1  if $_[0]->{'cursor'} > $_[0]->{'length'};
    return 0;
}

#iterator: subclass overrides
sub next_segment {
    my ($self, $par) = @_;
    #warn "${self}::next_segment\n";

    return undef  if $self->{'cursor'} > $self->{'length'};

    #current real position
    my $start = $self->{'start'} + $self->{'cursor'} - 1;

    my $rest  = $self->{'length'} - $self->{'cursor'} + 1;  #length remaining
    my $chunk = ($par->{'width'} < $rest ? $par->{'width'} : $rest);

    #warn "($self->{'length'}, $self->{'cursor'}, $chunk, $rest, ($self->{'start'}, $self->{'stop'}))\n";

    my $string = [];
    my $pos = $start - 1;

    for (my $i = 0; $i < $chunk; $i++) {

        $pos++;  #real data position

        my $c = $self->char_at($self->{'cursor'});

        if ($par->{'html'}) {
            push @$string, $self->html_wrap($self->{'cursor'}, $c);
        } else {
            push @$string, $c;
        }

        $self->{'cursor'}++;  #stuff output so far
    }

    $string = $self->finish_html($string, $par->{'bold'})  if $par->{'html'};

    return [ $start, join('', @$string), $pos ];
}

sub finish_html {
    my ($self, $string, $bold) = @_;

    $string = $self->strip_html_repeats($string);

    unshift @$string, '<STRONG>'         if $bold;
    push    @$string, '</STRONG>'        if $bold;

    return $string;
}

######################################################################
# private methods
######################################################################
sub parse_range {
    my ($self, $data) = @_;
    my ($state, @list, $attr, $i) = (2);

    for ($i=0; $i < @$data; $i++) {

        #position data
        if ($data->[$i] =~ /^\d+$/) {
            if ($state == 2) {
                #warn "SAVE   [$i] $data->[$i]\n";
                #begin new range: save old attribute hash, if useful
                if (defined $attr and keys %$attr > 1) {
                    if ($attr->{'pos'}->[0] > $attr->{'pos'}->[1]) {
                        warn "bad attribute range '@{$attr->{'pos'}}'\n";
                    } else {
                        push @list, $attr;
                    }
                }
                $attr  = {};   #reset attribute hash
                $state = 0;    #ready for first pos
            }
            if ($state == 0) {
                #warn "0->1   [$i] $data->[$i]\n";
                #first position
                $attr->{'pos'}->[0] = $data->[$i];
                $state = 1;    #ready for second pos, if any
                next;
            }
            if ($state == 1) {
                #warn "1->2   [$i] $data->[$i]\n";
                #second position
                $attr->{'pos'}->[1] = $data->[$i];
                $state = 2;
                next;
            }
            die "${self}::parse_range: never get here!\n";
        }

        #first position wasn't given: bad attribute list
        if ($state == 0) {
            warn "$self: bad attribute list '@$data'\n";
            last;
        }

        #second position wasn't given: make one and continue
        if ($state == 1) {
            $attr->{'pos'}->[1] = $attr->{'pos'}->[0];
            $state = 2;
        }

        #position range attributes: key=>value pair
        if (grep /^$data->[$i]$/, qw(color class)) {
            #warn "ATTR   [$i] $data->[$i] $data->[$i+1]\n";
            $attr->{$data->[$i]} = $data->[$i+1]  if defined $data->[$i+1];
            $i++;    #jump value
            next;
        }

        warn "$self: unknown range attribute '$data->[$i]'\n";
        $i++;    #skip likely value
    }

    #save last iteration
    if ($state == 2 and defined $attr) {
        #warn "SAVE   LAST\n";
        #save old attribute hash, if useful
        if (defined $attr and keys %$attr > 1) {
            if ($attr->{'pos'}->[0] > $attr->{'pos'}->[1]) {
                warn "bad attribute range '@{$attr->{'pos'}}'\n";
            } else {
                push @list, $attr;
            }
        }
    }

    #resort ranges by (1) lowest 'start', and (2) highest 'stop'
    return [ sort { my $c = $a->{'pos'}->[0] <=> $b->{'pos'}->[0];
                    return  $c  if $c != 0;
                    return  $b->{'pos'}->[1] <=> $a->{'pos'}->[1];
             } @list
    ];
}

sub char_at {
    defined $_[0]->{'string'} ? $_[0]->{'string'}->col($_[1]) :
        $_[0]->{'parent'}->{'string'}->col($_[1]);
}

sub html_wrap {
    my ($self, $i, $c) = @_;

    my $class = $self->{'r_class'}->[$i];
    if (defined $class) {
        return ("<SPAN CLASS=$class>", $c, "</SPAN>");
    }

    my $color = $self->{'r_color'}->[$i];
    if (defined $color) {
        return "<SPAN style=\"color:$color\">", $c, "</SPAN>";
    }

    return ($c);
}

sub strip_html_repeats {
    my ($self, $list) = @_;
    my ($new, $i, $limit) = [];

    return $list  if @$list < 4;

    #warn " IN=[", @$list, "]\n";

    #use 1 element lookahead
    $limit = @$list;

    for ($i=0; $i<$limit; $i++) {

        if ($list->[$i] =~ /^</) {
            #looking at: <tag> or </tag>

            #empty stack
            if (@$new < 1) {
                #warn "NEW(@{[scalar @$new]}) lex[$i] <-- $list->[$i]\n";
                push @$new, $list->[$i];
                #warn "[", @$new, "]\n";
                next;
            }

            #non-empty stack: different tag
            if ($list->[$i] ne $new->[$#$new]) {
                #warn "NEW(@{[scalar @$new]}) lex[$i] <-- $list->[$i]\n";
                push @$new, $list->[$i];
                #warn "[", @$new, "]\n";
                next;
            }

            #non-empty stack: same tag
            #warn "NOP(@{[scalar @$new]}) lex[$i]     $new->[$#$new]\n";
            #warn "[", @$new, "]\n";

        } else {
            #non-tag
            #warn "ARG(@{[scalar @$new]})    [$i] <-- $list->[$i]\n";
            push @$new, $list->[$i];
            #warn "[", @$new, "]\n";
        }
    }

    #warn "SR1=[", @$new, "]\n";

    $new = $self->strip_html_tandem_repeats($new);

    #warn "SR2=[", @$new, "]\n\n";

    return $new;
}

sub strip_html_tandem_repeats {
    my ($self, $list) = @_;
    my ($new, @mem, $i, $limit) = ([]);

    return $list  if @$list < 6;

    #warn " IN=[", @$list, "]\n";

    #use 1 element lookahead
    $limit = @$list;

    for ($i=0; $i<$limit; $i++) {

        #looking at: tag
        if ($list->[$i] =~ /^<[^\/]/) {

            #empty stack
            if (@mem < 1) {
                #warn "NEW(@{[scalar @mem]}) lex[$i] <-- $list->[$i]\n";
                push @mem, $list->[$i];
                #scan until next closing tag
                $i = close_tag($list, $limit, ++$i, \@mem);
                next;
            }

            #non-empty stack: different tag
            if ($list->[$i] ne $mem[0]) {
                #warn "NEW(@{[scalar @mem]}) lex[$i] <-- $list->[$i]\n";
                push @$new, @mem;
                @mem = ();
                redo;
            }

            #non-empty stack: same tag
            #warn "POP(@{[scalar @mem]}) lex[$i] --> $mem[$#mem]\n";
            pop @mem;
            #scan until next closing tag
            $i = close_tag($list, $limit, ++$i, \@mem);
            next;

        } else {
            #non-tag
            #warn "ARG(@{[scalar @mem]}) lex[$i] <-- $list->[$i]\n";
            push @$new, @mem, $list->[$i];
            @mem = ();
        }
    }

    push @$new, @mem    if @mem;

    #warn "SR2=[", @$new, "]\n\n";

    return $new;
}

sub close_tag {
    my ($list, $limit, $i, $mem) = @_;
    my $tag = 0;
    while ($i < $limit) {

        if ($list->[$i] =~ /^<[^\/]/) {
            #inner tag
            $tag++;
            #warn "I  tag[$i] <-- $list->[$i]\n";
            push @$mem, $list->[$i++];
            next;
        }

        if ($list->[$i] =~ /^<\//) {
            if ($tag) {
                #inner /tag
                $tag--;
                #warn "I /tag[$i] <-- $list->[$i]\n";
                push @$mem, $list->[$i++];
                next;
            }
            #outer /tag
            #warn "O /tag[$i] <-- $list->[$i]\n";
            push @$mem, $list->[$i];
            last;
        }

        #datum
        #warn "  data[$i] <-- $list->[$i]\n";
        push @$mem, $list->[$i++];
    }
    return $i;
}

######################################################################
# debug
######################################################################
#sub DESTROY { print "destroy: $_[0]\n" }

sub dump { warn Universal::dump_object(@_) }

###########################################################################
package Bio::MView::Display::Sequence;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Display::Track);

###########################################################################
1;
