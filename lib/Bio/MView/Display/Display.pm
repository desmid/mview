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

    $par{'width'} = $Default_Width  unless exists $par{'width'};
    $par{'gap'}   = $Default_Gap    unless exists $par{'gap'};
    $par{'pad'}   = $Default_Pad    unless exists $par{'pad'};
    $par{'bold'}  = $Default_Bold   unless exists $par{'bold'};

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

    print $stm "<PRE>\n"   if $par{'html'};

    $self->display_panes(\%par, $stm, $prefix, $suffix);

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
# private methods
######################################################################
#iterate over display panes of par{'width'}
sub display_panes {
    my ($self, $par, $stm, $prefix, $suffix) = @_;

    return  unless @{$self->{'object'}};

    map { $_->reset } @{$self->{'object'}};

    #need space for sequence position numbers?
    my $has_positions = 0;
    foreach my $o (@{$self->{'object'}}) {
        $has_positions = 1, last  if $o->has_positions;
    }

    while (1) {
        #Universal::vmstat("display pane");

        #do one pane
        foreach my $o (@{$self->{'object'}}) {

            #do one line
            my $d = $o->next($par->{'html'}, $par->{'bold'}, $par->{'width'},
                             $par->{'gap'}, $par->{'pad'}, $par->{'lap'});

            return  unless $d;  #exit point

            #warn "[@$d]\n";

            #clear new row
            my @row = ();

            #label0: rownum
            push @row, label_rownum($par, $o)
                if $par->{'labelflags'}->[0];

            #label1: identifier
            push @row, label_identifier($par, $o)
                if $par->{'labelflags'}->[1];

            #label2: description
            push @row, label_description($par, $o)
                if $par->{'labelflags'}->[2];

            #labels3-7: info
            for (my $i=3; $i < @{$par->{'labelwidths'}}; $i++) {
                push @row, label_annotation($par, $o, $i)
                    if $par->{'labelflags'}->[$i];
            }

            #left position
            push @row, left_position($par, $o, $d->[0], $prefix, $suffix)
                if $has_positions;
            push @row, $Spacer;

            #sequence string
            push @row, $d->[1], $Spacer;

            #right position
            push @row, right_position($par, $o, $d->[2], $prefix, $suffix)
                if $has_positions;

            #end of line
            push @row, "\n";

            #output
            print $stm @row;

        } #foreach

        #end of pane
        print $stm "\n"  unless $self->{'object'}->[0]->done;

        #Universal::vmstat("display pane done");
    } #while
}

######################################################################
# private class methods
######################################################################
#left or right justify as string or numeric identifier
sub label_rownum {
    my ($par, $o) = @_;
    my ($just, $w, $s) = ('-', $par->{'labelwidths'}->[0], $o->label(0));
    return ()  unless $w;
    $just = ''  if $s =~ /^\d+$/;
    return (format_label($just, $w, $s), $Spacer);
}

#left justify
sub label_identifier {
    my ($par, $o) = @_;
    my ($w, $s, $url) = ($par->{'labelwidths'}->[1], $o->label(1), $o->{'url'});
    return ()  unless $w;
    if ($par->{'html'} and $url) {
        my @tmp = ();
        push @tmp, "<A HREF=\"$url\">", $s, "</A>";
        push @tmp, " " x ($w - CORE::length($s));
        return (@tmp, $Spacer);
    }
    return (format_label('-', $w, $s), $Spacer)
}

#left justify
sub label_description {
    my ($par, $o) = @_;
    my ($w, $s) = ($par->{'labelwidths'}->[2], $o->label(2));
    return ()  unless $w;
    return (format_label('-', $w, $s), $Spacer);
}

#right justify
sub label_annotation {
    my ($par, $o, $n) = @_;
    my ($w, $s) = ($par->{'labelwidths'}->[$n], $o->label($n));
    return ()  unless $w;
    return (format_label('', $w, $s), $Spacer);
}

#right justify: does not add $Spacer
sub left_position {
    my ($par, $o, $n, $pfx, $sfx) = @_;
    my ($w, $n) = ($par->{'posnwidth'}, ($o->has_positions ? $n : ''));
    return format_label('', $w, $n, $pfx, $sfx);
}

#left justify: does not add $Spacer
sub right_position {
    my ($par, $o, $n, $pfx, $sfx) = @_;
    my ($w, $n) = ($par->{'posnwidth'}, ($o->has_positions ? $n : ''));
    return format_label('-', $w, $n, $pfx, $sfx);
}

#left or right justify in padded fieldwidth with optional prefix/suffix
sub format_label {
    my ($just, $w, $s, $pfx, $sfx) = (@_, '', '');
    return sprintf("%s%${just}${w}s%s", $pfx, $s, $sfx);
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
