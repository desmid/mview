# Copyright (C) 1997-2018 Nigel P. Brown

use strict;

###########################################################################
package Bio::MView::Display::Display;

use Universal qw(max vmstat);
use Bio::MView::Display::Track;
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
    my ($labelwidths, $headers, $sequence) = (shift, shift, shift);

    my $self = {};
    bless $self, $type;

    $self->{'labelwidths'} = $labelwidths;
    $self->{'headers'}     = $headers;
    $self->{'string'}      = $sequence;

    $self->{'length'}      = $sequence->length;
    $self->{'forwards'}    = $sequence->is_forwards;

    #start/stop, counting extent forwards
    $self->{'start'}       = $sequence->lo;
#   $self->{'stop'}        = $sequence->hi;
    $self->{'stop'}        = $self->{'start'} + $self->{'length'} - 1;

    #initial width of left/right sequence position as text
    $self->{'posnwidth'}   = max(length("$self->{'start'}"),
                                 length("$self->{'stop'}"));

    $self->{'track'}       = [];  #display objects

    $self->append(@_)  if @_;

    $self;
}

######################################################################
# public methods
######################################################################
sub length   { $_[0]->{'length'} }

sub forwards { $_[0]->{'forwards'} }

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

        my $o = construct_display_row($type, $self, $row);

        push @{$self->{'track'}}, $o;

        #update column widths seen so far
        for (my $i=0; $i < @{$self->{'labelwidths'}}; $i++) {
            $self->{'labelwidths'}->[$i] =
                max($self->{'labelwidths'}->[$i], $o->labelwidth($i));
        }
    }
    #vmstat("Display::append done");
}

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

    $self->display_pane(\%par, $stm, $prefix, $suffix);

    print $stm "</PRE>\n"  if $par{'html'};

    $self->free_rows;  #garbage collect rows
}

######################################################################
# private methods
######################################################################
sub free_rows {
    #print "free: $_[0]\n";
    foreach my $o (@{$_[0]->{'track'}}) {
        $o = undef;
    }
}

#output a pane of par{'width'} chunks
sub display_pane {
    my ($self, $par, $stm, $prefix, $suffix) = @_;

    return  unless @{$self->{'track'}};

    map { $_->reset } @{$self->{'track'}};

    #need space for sequence position numbers?
    my $has_positions = 0;
    foreach my $o (@{$self->{'track'}}) {
        $has_positions = 1, last  if $o->has_positions;
    }

    #vmstat("display pane");
    while (1) {
        last  unless $self->display_chunk($par, $stm, $prefix, $suffix,
                                          $has_positions);

        #space between chunks except final
        print $stm "\n"  unless $self->{'track'}->[0]->done;
    }
    #vmstat("display pane done");
}

#output a single par{'width'} chunk
sub display_chunk {
    my ($self, $par, $stm, $prefix, $suffix, $has_positions) = @_;

    #display each track's segment for this chunk
    foreach my $o (@{$self->{'track'}}) {

        my $seg = $o->next_segment($par);

        return 0  unless defined $seg;  #all chunks done

        #display rowment
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
        push @row, left_position($par, $o, $seg->[0], $prefix, $suffix)
            if $has_positions;
        push @row, $Spacer;

        #sequence string
        push @row, $seg->[1], $Spacer;

        #right position
        push @row, right_position($par, $o, $seg->[2], $prefix, $suffix)
            if $has_positions;

        #end of line
        push @row, "\n";

        #output
        print $stm @row;
    }

    return 1;  #end of chunk
}

######################################################################
# private class methods
######################################################################
sub construct_display_row {
    my ($type, $owner, $data) = @_;
    no strict 'refs';
    my $row = "Bio::MView::Display::$type"->new($owner, $data);
    use strict 'refs';
    return $row;
}

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

######################################################################
# debug
######################################################################
#sub DESTROY { print "destroy: $_[0]\n" }

sub dump {
    my $self = shift;
    foreach my $k (sort keys %$self) {
        warn sprintf "%15s => %s\n", $k, $self->{$k};
    }
    map { $_->dump } @{$self->{'track'}};
}

###########################################################################
1;
