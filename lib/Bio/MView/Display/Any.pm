# Copyright (C) 1997-2017 Nigel P. Brown

use strict;

###########################################################################
package Bio::MView::Display::Any;

use Bio::MView::Display::Display;

sub new {
    my $type = shift;
    my ($parent, $hash) = @_;
    my $self = {};
    bless $self, $type;

    $self->{'parent'} = $parent;          #parent sequence object
    $self->{'length'} = $parent->length;  #length of parent sequence
    $self->{'type'}   = $hash->{'type'};  #type of this row

    $self->{'start'}  = 0;      #start position of parent sequence
    $self->{'stop'}   = 0;      #stop position of parent sequence

    $self->{'string'} = undef;  #alternative sequence to parent
    $self->{'labels'} = undef;  #annotation column labels
    $self->{'number'} = 0;      #marginal numbers flag
    $self->{'url'}    = '';     #URL; to associate with label1
    $self->{'paint'}  = 0;      #overlap behaviour for this row
    $self->{'prefix'} = '';     #prefix; whole row with string
    $self->{'suffix'} = '';     #suffix; whole row with string

    $self->{'string'} = $hash->{'sequence'} if exists $hash->{'sequence'};
    $self->{'labels'} = $hash->{'labels'}   if exists $hash->{'labels'};
    $self->{'number'} = $hash->{'number'}   if exists $hash->{'number'};
    $self->{'url'}    = $hash->{'url'}      if exists $hash->{'url'};
    $self->{'paint'}  = $hash->{'paint'}    if exists $hash->{'paint'};
    $self->{'prefix'} = $hash->{'prefix'}   if exists $hash->{'prefix'};
    $self->{'suffix'} = $hash->{'suffix'}   if exists $hash->{'suffix'};

    #warn "Any::labels: [@{[join(',', @{$self->{'labels'}})]}]\n";

    $self->{'cursor'} = 0;  #current position in display stream, 1-based

    $self->{'r_map'}    = [];
    $self->{'r_color'}  = [];
    $self->{'r_class'}  = [];
    $self->{'r_prefix'} = [];
    $self->{'r_suffix'} = [];
    $self->{'r_sym'}    = [];
    $self->{'r_url'}    = [];
    $self->{'r_case'}   = [];

    if (defined $self->{'string'}) {
        my $seqlen = $self->{'string'}->length;

        #are 'parent' and 'string' the same length?
        if ($seqlen != $self->{'length'}) {
            #warn "parent:   [@{[$self->{'parent'}->{'string'}->string]}]\n";
            #warn "sequence: [@{[$self->{'string'}->string]}]\n";
            die "${type}::new: parent/sequence length mismatch ($self->{'length'}, $seqlen)\n";
        }

        # no idea what this is/was for... 1/10/98
        #starting numbering wrt 'string' or 'parent'?
        if (exists $hash->{'start'}) {
            $self->{'start'} = $hash->{'start'};
            $self->{'stop'}  = $hash->{'stop'};
        } else {
            $self->{'start'} = $parent->{'start'};
            $self->{'stop'}  = $parent->{'stop'};
        }

    } else {
        #starting numbering wrt 'parent'
        $self->{'start'} = $parent->{'start'};
        $self->{'stop'}  = $parent->{'stop'};
    }

    #ensure 'range' attribute has a value
    $hash->{'range'} = []  unless exists $hash->{'range'};

    #populate the range map
    foreach my $range (@{$self->parse_range($hash->{'range'})}) {
        for (my $i = $range->{'pos'}->[0];
             $i <= $range->{'pos'}->[$#{$range->{'pos'}}];
             $i++) {
            foreach my $j (keys %$range) {
                next if $j eq 'pos';
                $self->{"r_$j"}->[$i] = $range->{$j};
            }
            $self->{'r_map'}->[$i]++;    #count hits per position
        }
    }

    #Universal::vmstat("Display::Any::new done");
    $self;
}

######################################################################
# public methods
######################################################################
#force break of back reference to allow garbage collection
sub free {
    #warn "Display::Any:free($_[0])\n";
    $_[0]->{'parent'} = undef;
}

sub has_margins { return $_[0]->{'number'} != 0 }

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
sub next {
    my $self = shift;
    #warn "${self}::next(@_)\n";
    my ($mode, $html, $bold, $col, $gap, $pad, $lap, $ruler) = @_;
    my (@string, $length, $i, $start, $pos, $c) = ();

    return 0  if $self->{'cursor'} > $self->{'length'};

    $length = $self->{'length'} - $self->{'cursor'} +1; #length remaining
    $col = $length    if $col > $length;                #consume smaller amount
    $start = $self->{'start'} + $self->{'cursor'} -1;   #current real position

    $col++;

    #warn "($self->{'cursor'}, $col, $length, ($self->{'start'},$self->{'stop'}))\n";

    for ($i = 1; $i < $col; $i++, $self->{'cursor'}++) {

        $pos = $start + $i;     #real data position

        #warn "$self->{'cursor'}, $pos ", mapcount=$self->{'r_map'}, "\n";

        #any range specifications?
        if (defined $self->{'r_map'}->[$self->{'cursor'}]) {

            #overlapped position if 'paint' mode is off
            if (! $self->{'paint'} and
                $self->{'r_map'}->[$self->{'cursor'}] > 1) {

                if ($html and length $lap > 1) {
                    push @string, "<SPAN style=\"color:$lap\">";
                    push @string, $self->col($self->{'cursor'});
                    push @string, "</SPAN>";
                } else {
                    push @string, $lap;
                }
                next;
            }

            #non-overlapped position, or 'paint' mode is on
            if (defined $self->{'r_sym'}->[$self->{'cursor'}]) {
                #caller specified symbol
                $c = $self->{'r_sym'}->[$self->{'cursor'}];
            } elsif (defined $self->{'r_case'}->[$self->{'cursor'}]) {
                #caller specified case
                $c = $self->{'r_case'}->[$self->{'cursor'}];
                $c = uc $self->col($self->{'cursor'})  if $c eq 'uc';
                $c = lc $self->col($self->{'cursor'})  if $c eq 'lc';
            } else {
                #default to sequence symbol
                $c = $self->col($self->{'cursor'});
            }
            push @string, $self->html_wrap($self->{'cursor'}, $c)  if $html;

        } elsif ($mode eq 'gap') {
            #class Subrange: use gap character
            push @string, $gap;
        } else { #mode eq 'nogap'
            #class Sequence: use sequence character
            push @string, $self->col($self->{'cursor'});
        }
    }

    if ($html) {
        @string = @{ $self->strip_html_repeats(\@string) };

        unshift @string, '<STRONG>'         if $bold;
        unshift @string, $self->{'prefix'}  if $self->{'prefix'};
        push    @string, $self->{'suffix'}  if $self->{'suffix'};
        push    @string, '</STRONG>'        if $bold;
    }

    return [ $start, join('', @string), $pos ];
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
        if (grep /^$data->[$i]$/, qw(color class prefix suffix sym url case)) {
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
    return [
            sort {
                my $c = $a->{'pos'}->[0] <=> $b->{'pos'}->[0];
                return  $c if $c != 0;
                return  $b->{'pos'}->[1] <=> $a->{'pos'}->[1];
            } @list
           ];
}

sub col {
    defined $_[0]->{'string'} ?
        $_[0]->{'string'}->col($_[1]) :
            $_[0]->{'parent'}->{'string'}->col($_[1]);
}

sub html_wrap {
    my ($self, $i, $c) = @_;

    my @string = ();

    #open new url?
    push @string, "<A HREF=\"$self->{'r_url'}->[$i]\">"
        if defined $self->{'r_url'}->[$i];

    #change color?
    push @string, "<SPAN style=\"color:$self->{'r_color'}->[$i]\">"
        if defined $self->{'r_color'}->[$i] and
            ! defined $self->{'r_class'}->[$i];

    #css1 class?
    push @string, "<SPAN CLASS=$self->{'r_class'}->[$i]>"
        if defined $self->{'r_class'}->[$i];

    #prefix
    push @string, $self->{'r_prefix'}->[$i]
        if defined $self->{'r_prefix'}->[$i];

    #embedded character
    push @string, $c;

    #suffix
    push @string, $self->{'r_suffix'}->[$i]
        if defined $self->{'r_suffix'}->[$i];

    #unchange css1 class?
    push @string, "</SPAN>"  if defined $self->{'r_class'}->[$i];

    #unchange color?
    push @string, "</SPAN>"
        if defined $self->{'r_color'}->[$i] and
            ! defined $self->{'r_class'}->[$i];

    #close URL?
    push @string, "</A>"     if defined $self->{'r_url'}->[$i];

    return @string;
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
                $i = _close_tag($list, $limit, ++$i, \@mem);
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
            $i = _close_tag($list, $limit, ++$i, \@mem);
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

sub _close_tag {
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
#sub DESTROY { warn "DESTROY $_[0]\n" }

sub dump {
    my $self = shift;
    foreach my $k (sort keys %$self) {
        warn sprintf "%15s => %s\n", $k, $self->{$k};
    }
}

###########################################################################
package Bio::MView::Display::Sequence;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Display::Any);

sub next { my $self = shift; $self->SUPER::next('nogap', @_) }

###########################################################################
package Bio::MView::Display::Subrange;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Display::Any);

sub next { my $self = shift; $self->SUPER::next('gap', @_) }

###########################################################################
1;
