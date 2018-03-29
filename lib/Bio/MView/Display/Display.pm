# Copyright (C) 1997-2018 Nigel P. Brown

use strict;

###########################################################################
package Bio::MView::Display::Display;

use Bio::MView::Display::Any;
use Bio::MView::Display::Ruler;

my $Default_Width         = 80;        #sequence display width
my $Default_Gap           = '-';       #sequence gap character
my $Default_Pad           = '';        #sequence trailing space character
my $Default_Bold          = 0;         #embolden some text

my $Default_Overlap       = '%';       #sequence overlap character
my $Default_Overlap_Color = '#474747'; #sequence overlap color if HTML

my $Spacer                = ' ';       #space between output columns

my %Known_Types = (
    'ruler'    => 1,
    'sequence' => 1,
    );

sub new {
    my $type = shift;
    die "${type}::new: missing arguments\n"  if @_ < 2;
    my ($labelwidths, $sequence) = (shift, shift);

    my $self = {};
    bless $self, $type;

    $self->{'labelwidths'} = $labelwidths;
    $self->{'string'}      = $sequence;

    $self->{'length'}      = $sequence->length;

    #start/stop, counting extent forwards
    $self->{'start'}       = $sequence->lo;
#   $self->{'stop'}        = $sequence->hi;
    $self->{'stop'}        = $self->{'start'} + $self->{'length'} - 1;

    #initial width of left/right sequence position as text
    $self->{'posnwidth'}   = max(length("$self->{'start'}"),
                                 length("$self->{'stop'}"));

    $self->{'object'}      = [];  #display objects

    $self->append(@_)  if @_;

    $self;
}

######################################################################
# public methods
######################################################################
#force break of back references to allow garbage collection
sub free {
    #warn "${_[0]}::Display::free\n";
    while (my $o = shift @{$_[0]->{'object'}}) { $o->free }
}

sub length { $_[0]->{'length'} }

sub display {
    my ($self, $stm) = (shift, shift);
    my %par = @_;

    $par{'width'}  = $Default_Width      unless exists $par{'width'};
    $par{'gap'}    = $Default_Gap        unless exists $par{'gap'};
    $par{'pad'}    = $Default_Pad        unless exists $par{'pad'};
    $par{'bold'}   = $Default_Bold       unless exists $par{'bold'};

    # warn "pw[$par{'posnwidth'}]\n";
    # warn "lf[@{[join(',', @{$par{'labelflags'}})]}]\n";
    # warn "lw[@{[join(',', @{$par{'labelwidths'}})]}]\n";

    my ($prefix, $suffix) = ('','');

    if ($par{'html'}) {
        $par{'lap'}  = $Default_Overlap_Color  unless exists $par{'lap'};
        ($prefix, $suffix) = ('<STRONG>','</STRONG>')  if $par{'bold'};
    } else {
        $par{'lap'}  = $Default_Overlap        unless exists $par{'lap'};
        $par{'bold'} = 0;  #ensure off
    }

    if ($par{'width'} < 1) {  #full length display
        $par{'width'} = $self->{'length'};
    }

    #map { warn "$_ => '$par{$_}'\n" } sort keys %par;

    print $stm "<PRE>\n"  if $par{'html'};

    map { $_->reset } @{$self->{'object'}};

    #need margin space for sequence numbers?
    my $pane_has_margins = 0;
    foreach my $o (@{$self->{'object'}}) {
        $pane_has_margins = 1, last  if $o->has_margins;
    }

    #iterate over display panes of par{'width'}, if any objects
  OUTER:
    while (@{$self->{'object'}}) {

        #Universal::vmstat("display pane");

        #do one pane
        foreach my $o (@{$self->{'object'}}) {

            #do one line
            my $s = $o->next($par{'html'}, $par{'bold'}, $par{'width'},
                             $par{'gap'}, $par{'pad'}, $par{'lap'});

            last OUTER  unless $s; #this terminates

            #warn "[ @$s ]\n";

            #clear new row
            my @row = ();

            #label0: rownum
            if ($par{'labelflags'}->[0] and $par{'labelwidths'}->[0]) {
                push @row, label_rownum(\%par, $o);
            }

            #label1: identifier
            if ($par{'labelflags'}->[1] and $par{'labelwidths'}->[1]) {
                push @row, label_identifier(\%par, $o);
            }

            #label2-7: info columns
            for (my $i=2; $i < @{$par{'labelwidths'}}; $i++) {
                if ($par{'labelflags'}->[$i] and $par{'labelwidths'}->[$i]) {
                    push @row, label_annotation(\%par, $o, $i);
                }
            }

            #left position
            if ($pane_has_margins) {
                my $n = $o->has_margins ? $s->[0] : '';
                push @row, sprintf("$prefix%$par{'posnwidth'}s$suffix", $n);
            }
            push @row, $Spacer;

            #sequence string
            push @row, $s->[1];
            push @row, $Spacer;

            #right position
            if ($pane_has_margins) {
                my $n = $o->has_margins ? $s->[2] : '';
                push @row, sprintf("$prefix%-$par{'posnwidth'}s$suffix", $n);
            }
            push @row, "\n";

            #output
            print $stm @row;

        } #foreach

        #record separator
        print $stm "\n"  unless $self->{'object'}->[0]->done;

        #Universal::vmstat("display loop done");
    } #while

    print $stm "</PRE>\n"  if $par{'html'};
}

sub append {
    my $self = shift;
    #warn "${self}::append(@_)\n";

    #handle data rows
    foreach my $row (@_) {

        unless (exists $row->{'type'}) {
            warn "${self}::append: missing type in '$row'\n";
            next;
        }

        my $type = $row->{'type'};

        unless (exists $Known_Types{$type}) {
            warn "${self}::append: unknown alignment type '$type'\n";
            next;
        }

        $type = ucfirst $type;

        #construct display row object
        no strict 'refs';
        my $o = "Bio::MView::Display::$type"->new($self, $row);
        use strict 'refs';

        push @{$self->{'object'}}, $o;

        #update column widths seen so far
        for (my $i=0; $i < @{$self->{'labelwidths'}}; $i++) {
            $self->{'labelwidths'}->[$i] =
                max($self->{'labelwidths'}->[$i], $o->labelwidth($i));
        }
    }
    #Universal::vmstat("Display::append done");
}

######################################################################
# private class methods
######################################################################
sub label_rownum {
    my ($par, $o) = @_;
    my ($w, $s) = ($par->{'labelwidths'}->[0], $o->label(0));
    my @tmp = ();
    if ($s =~ /^\d+$/) {
        push @tmp, sprintf("%${w}s", $s);   #numeric - right justify
    } else {
        push @tmp, sprintf("%-${w}s", $s);  #string  - left justify
    }
    push @tmp, $Spacer;
    return @tmp;
}

sub label_identifier {
    my ($par, $o) = @_;
    my ($w, $s, $url) = ($par->{'labelwidths'}->[1], $o->label(1), $o->{'url'});
    my @tmp = ();
    #left justify
    if ($par->{'html'} and $url) {
        push @tmp, "<A HREF=\"$url\">", $s, "</A>";
        push @tmp, " " x ($w - CORE::length($s));
    } else {
        push @tmp, sprintf("%-${w}s", $s);
    }
    push @tmp, $Spacer;
    return @tmp;
}

sub label_annotation {
    my ($par, $o, $n) = @_;
    my ($w, $s) = ($par->{'labelwidths'}->[$n], $o->label($n));
    #right justify
    return (sprintf("%${w}s", $s), $Spacer);
}

sub max { $_[0] > $_[1] ? $_[0] : $_[1] }

######################################################################
# debug
######################################################################
#sub DESTROY { warn "DESTROY $_[0]\n" }

sub dump {
    my $self = shift;
    foreach my $k (sort keys %$self) {
        printf "%15s => %s\n", $k, $self->{$k};
    }
    map { $_->dump } @{$self->{'object'}};
}

###########################################################################
1;
