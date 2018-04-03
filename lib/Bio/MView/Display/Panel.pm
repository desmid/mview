# Copyright (C) 1997-2018 Nigel P. Brown

use strict;

###########################################################################
package Bio::MView::Display::Panel;

use Universal qw(max vmstat);
use Bio::MView::Display::Sequence;
use Bio::MView::Display::Ruler;

my $Spacer = ' ';  #space between output columns

my %Known_Track_Types = (
    'ruler'    => 1,
    'sequence' => 1,
    );

sub new {
    my $type = shift;
    die "${type}::new: missing arguments\n"  if @_ < 3;
    my ($par, $headers, $startseq) = @_;

    my $self = {};
    bless $self, $type;

    $self->{'par'}        = $par;
    $self->{'header'}     = $headers;

    $self->{'length'}     = $startseq->length;
    $self->{'forwards'}   = $startseq->is_forwards;

    #start/stop, counting extent forwards
    $self->{'start'}      = $startseq->lo;
#   $self->{'stop'}       = $startseq->hi;
    $self->{'stop'}       = $self->{'start'} + $self->{'length'} - 1;

    $self->{'track'}      = [];  #display objects

    #initial width of left/right sequence position as text
    $self->{'posnwidths'}  = max(length("$self->{'start'}"),
                                 length("$self->{'stop'}"));

    #initial label widths
    $self->{'labelwidths'} = [];
    for (my $i=0; $i < @{$par->{'labelflags'}}; $i++) {
        $self->{'labelwidths'}->[$i] = 0;
    }

    $self;
}

######################################################################
# public methods
######################################################################
sub length      { return $_[0]->{'length'} }
sub forwards    { return $_[0]->{'forwards'} }
sub posnwidths  { return $_[0]->{'posnwidths'} }
sub labelwidths { return $_[0]->{'labelwidths'}->[$_[1]] }

sub append {
    my $self = shift;

    #handle data rows
    foreach my $row (@_) {

        unless (exists $row->{'type'}) {
            warn "${self}::append: missing type in '$row'\n";
            next;
        }

        my $type = $row->{'type'};

        unless (exists $Known_Track_Types{$type}) {
            warn "${self}::append: unknown alignment type '$type'\n";
            next;
        }

        $type = ucfirst $type;

        my $o = construct_row($type, $self, $row);

        push @{$self->{'track'}}, $o;

        #update column widths seen so far in this panel
        for (my $i=0; $i < @{$self->{'labelwidths'}}; $i++) {
            $self->{'labelwidths'}->[$i] =
                max($self->{'labelwidths'}->[$i], $o->labelwidth($i));
        }
    }
    #vmstat("Panel::append done");
}

sub render_panel {
    my ($self, $par, $posnwidths, $labelwidths) = @_;

    return  unless @{$self->{'track'}};

    #no fieldwidths from caller? use own set
    if (! defined $posnwidths) {
        $posnwidths  = $self->{'posnwidths'};
        $labelwidths = $self->{'labelwidths'};
    }

    $par->{'chunk'} = $par->{'width'};
    $par->{'chunk'} = $self->{'length'}  if $par->{'chunk'} < 1;  #full width

    if (@{$self->{'header'}}) {
        $par->{'dev'}->render_tr_pre_begin;
        foreach my $s (@{$self->{'header'}}) {
            $par->{'dev'}->render_text($s);
        }
        $par->{'dev'}->render_tr_pre_end;
    }

    $par->{'dev'}->render_tr_pre_begin;
    $self->render_pane($par, $posnwidths, $labelwidths);
    $par->{'dev'}->render_tr_pre_end;

    $self->free_rows;  #garbage collect rows
}

######################################################################
# private methods
######################################################################
sub free_rows {
    #print "free: $_[0]\n";
    while (@{$_[0]->{'track'}}) {  #consume tracks
        my $o = shift @{$_[0]->{'track'}};
        $o = undef;
    }
}

#output a pane of par{'width'} chunks
sub render_pane {
    my ($self, $par, $posnwidths, $labelwidths) = @_;

    #need space for sequence position numbers?
    my $has_ruler = 0;
    foreach my $o (@{$self->{'track'}}) {
        $has_ruler = 1  if $o->is_ruler;
        $o->reset;
    }

    #vmstat("render pane");
    while (1) {
        last  unless $self->render_chunk($par, $has_ruler,
                                         $posnwidths, $labelwidths);
    }
    #vmstat("render pane done");
}

#output a single chunk
sub render_chunk {
    my ($self, $par, $has_ruler, $posnwidths, $labelwidths) = @_;

    #render each track's segment for this chunk
    foreach my $o (@{$self->{'track'}}) {

        my $seg = $o->next_segment($par);

        return 0  unless defined $seg;  #all chunks done

        my @row = ();

        #label0: rownum
        push @row, label_rownum($par, $labelwidths, $o)
            if $par->{'labelflags'}->[0];

        #label1: identifier
        push @row, label_identifier($par, $labelwidths, $o)
            if $par->{'labelflags'}->[1];

        #label2: description
        push @row, label_description($par, $labelwidths, $o)
            if $par->{'labelflags'}->[2];

        #labels3-7: info
        for (my $i=3; $i < @$labelwidths; $i++) {
            push @row, label_annotation($par, $labelwidths, $o, $i)
                if $par->{'labelflags'}->[$i];
        }

        #left position
        push @row, left_position($par, $posnwidths, $o, $seg->[0])
            if $has_ruler;
        push @row, $Spacer;

        #sequence string
        push @row, $seg->[1], $Spacer;

        #right position
        push @row, right_position($par, $posnwidths, $o, $seg->[2])
            if $has_ruler;

        #output segment
        $par->{'dev'}->render_text(@row, "\n");
    }

    #blank between chunks
    $par->{'dev'}->render_text("\n");

    return 1;  #end of chunk
}

######################################################################
# private class methods
######################################################################
sub construct_row {
    my ($type, $owner, $data) = @_;
    no strict 'refs';
    my $row = "Bio::MView::Display::$type"->new($owner, $data);
    use strict 'refs';
    return $row;
}

#left or right justify as string or numeric identifier
sub label_rownum {
    my ($par, $labelwidths, $o) = @_;
    my ($just, $w, $s) = ('-', $labelwidths->[0], $o->label(0));
    return ()  unless $w;
    $just = ''  if $s =~ /^\d+$/;
    return (format_label($just, $w, $s), $Spacer);
}

#left justify
sub label_identifier {
    my ($par, $labelwidths, $o) = @_;
    my ($w, $s) = ($labelwidths->[1], $o->label(1));
    return ()  unless $w;
    my @tmp = ();
    push @tmp, $par->{'dev'}->process_url($s, $o->{'url'});
    push @tmp, " " x ($w - CORE::length($s));
    return (@tmp, $Spacer);
}

#left justify
sub label_description {
    my ($par, $labelwidths, $o) = @_;
    my ($w, $s) = ($labelwidths->[2], $o->label(2));
    return ()  unless $w;
    return (format_label('-', $w, $s), $Spacer);
}

#right justify
sub label_annotation {
    my ($par, $labelwidths, $o, $n) = @_;
    my ($w, $s) = ($labelwidths->[$n], $o->label($n));
    return ()  unless $w;
    return (format_label('', $w, $s), $Spacer);
}

#right justify: does not add $Spacer
sub left_position {
    my ($par, $posnwidths, $o, $n) = @_;
    my ($w, $n) = ($posnwidths, ($o->is_ruler ? $n : ''));
    my $s = format_label('', $w, $n);
    return $par->{'dev'}->process_bold($s)  if $par->{'bold'};
    return $s;
}

#left justify: does not add $Spacer
sub right_position {
    my ($par, $posnwidths, $o, $n) = @_;
    my ($w, $n) = ($posnwidths, ($o->is_ruler ? $n : ''));
    my $s = format_label('-', $w, $n);
    return $par->{'dev'}->process_bold($s)  if $par->{'bold'};
    return $s;
}

#left or right justify in padded fieldwidth
sub format_label {
    my ($just, $w, $s) = @_;
    return sprintf("%${just}${w}s", $s);
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
