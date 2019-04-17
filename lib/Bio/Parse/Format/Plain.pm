# Copyright (C) 1998-2019 Nigel P. Brown

# This file is part of MView.
# MView is released under license GPLv2, or any later version.

######################################################################
#
# The simplest input alignment is a column of id's and a column of aligned
# sequences of identical length with the entire alignment in one block.
#
###########################################################################
package Bio::Parse::Format::Plain;

use vars qw(@ISA);
use strict;

@ISA = qw(Bio::Parse::Record);

my $BLANK           = '^\s*$';
my $COMMENT         = '^\s*\#';

#subrecords
my $ALIGNMENT_BEGIN = '^\s*\S+\s+\S';
my $ALIGNMENT_GROUP = '^\s*(\S+)\s+(\S+)\s*$';
my $ALIGNMENT_END   = $BLANK;

#full record
my $DATA_BEGIN      = $ALIGNMENT_BEGIN;
my $DATA_END        = $ALIGNMENT_END;

my $DEBUG = 0;

#Consume one entry-worth of input on text stream associated with $file and
#return a new Plain instance.
sub get_entry {
    my ($text) = @_;
    my ($line, $offset, $bytes) = ('', -1, 0);

    #warn "BEGIN ENTRY\n"  if $DEBUG;

    while ($text->getline(\$line)) {

        #initial blank
        if ($line =~ /$BLANK/o and $offset < 0) {
            #warn " LEADING BLANK\n"  if $DEBUG;
            next;
        }

        #initial comment
        if ($line =~ /$COMMENT/o and $offset < 0) {
            #warn " LEADING COMMENT\n"  if $DEBUG;
            next;
        }

        #start of data
        if ($line =~ /$DATA_BEGIN/o and $offset < 0) {
            #warn " START OF DATA\n"  if $DEBUG;
            $offset = $text->startofline;
            next;
        }

        #end of data
        if ($line =~ /$DATA_END/o and ! ($offset < 0)) {
            #warn " END OF DATA\n"  if $DEBUG;
            last;
        }
    }

    #warn "END ENTRY\n"  if $DEBUG;

    return 0   if $offset < 0;

    $bytes = $text->tell - $offset;

    new Bio::Parse::Format::Plain(undef, $text, $offset, $bytes);
}

#Parse one entry
sub new {
    my $type = shift;
    if (@_ < 2) {
        #at least two args, ($offset, $bytes are optional).
        Bio::Util::Object::die($type, "new() invalid arguments:", @_);
    }
    my ($parent, $text, $offset, $bytes) = (@_, -1, -1);
    my ($self, $line, $record);

    $self = new Bio::Parse::Record($type, $parent, $text, $offset, $bytes);
    $text = new Bio::Parse::Scanner($self);

    #warn "BEGIN PARSE\n"  if $DEBUG;

    while (defined ($line = $text->next_line)) {

        #comment: ignore in middle of alignment; test first
        next    if $line =~ /$COMMENT/o;

        #alignment line
        if ($line =~ /$ALIGNMENT_BEGIN/o) {
            $text->scan_until($ALIGNMENT_END, 'ALIGNMENT');
            next;
        }

        #blank: ignore; test last
        next    if $line =~ /$BLANK/o;

        $self->warn("unknown field: $line");
    }

    #warn "END PARSE\n"  if $DEBUG;

    $self;#->examine;
}


###########################################################################
package Bio::Parse::Format::Plain::ALIGNMENT;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Record);

sub new {
    my $type = shift;
    if (@_ < 2) {
        #at least two args, ($offset, $bytes are optional).
        Bio::Util::Object::die($type, "new() invalid arguments:", @_);
    }
    my ($parent, $text, $offset, $bytes) = (@_, -1, -1);
    my ($self, $line, $record);

    $self = new Bio::Parse::Record($type, $parent, $text, $offset, $bytes);
    $text = new Bio::Parse::Scanner($self);

    $self->{'id'}    = [];
    $self->{'seq'}   = {};

    my $off = 0;

    #warn "BEGIN PARSE ALIGNMENT\n"  if $DEBUG;
    #warn "POSITION(self): $offset $bytes\n" if $DEBUG;
    #warn "POSITION(text): ", $text->{'offset'}, " ", $text->{'bytes'}, "\n" if $DEBUG;

    while (defined ($line = $text->next_line(1))) {

        #comment: ignore in middle of alignment; must come first
        next    if $line =~ /$COMMENT/o;

        #id sequence
        if ($line =~ /$ALIGNMENT_GROUP/o) {
            $self->test_args(\$line, $1, $2);
            push @{$self->{'id'}}, $1    unless exists $self->{'seq'}->{$1};
            $self->{'seq'}->{$1} .= $2;
            next;
        }

        #default
        $self->warn("unknown field: $line");
    }

    #warn "END PARSE ALIGNMENT\n"  if $DEBUG;

    #line length check
    if (defined $self->{'id'}->[0]) {
        $off = length $self->{'seq'}->{$self->{'id'}->[0]};
        foreach $line (keys %{$self->{'seq'}}) {
            $line = $self->{'seq'}->{$line};
            if (length $line != $off) {
                $self->die("unequal line lengths (expect $off, got @{[length $line]})\n");
            }
        }
    }

    $self;
}

sub print_data {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    foreach my $i (@{$self->{'id'}}) {
        printf "$x%20s -> %-15s %s\n", 'seq', $i, $self->{'seq'}->{$i};
    }
}


###########################################################################
1;
