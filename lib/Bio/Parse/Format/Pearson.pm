# Copyright (C) 1998-2019 Nigel P. Brown

# This file is part of MView.
# MView is released under license GPLv2, or any later version.

###########################################################################
package Bio::Parse::Format::Pearson;

use vars qw(@ISA);
use strict;

@ISA = qw(Bio::Parse::Record);


#Pearson record types
my $Pearson_Null     = '^\s*$';#'
my $Pearson_SEQ      = '^\s*>';
my $Pearson_SEQend   = "(?:$Pearson_SEQ|$Pearson_Null)";


#Consume one entry-worth of input on text stream associated with $file and
#return a new Pearson instance.
sub get_entry {
    my ($text) = @_;
    my ($line, $offset, $bytes) = ('', -1, 0);

    while ($text->getline(\$line)) {

        #start of entry
        if ($offset < 0) {
            $offset = $text->startofline;
            next;
        }

    }
    return 0  if $offset < 0;

    $bytes = $text->tell - $offset;

    new Bio::Parse::Format::Pearson(undef, $text, $offset, $bytes);
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

    while (defined ($line = $text->next_line)) {

        #SEQ lines
        if ($line =~ /$Pearson_SEQ/o) {
            $text->OLD_scan_until($Pearson_SEQend, 'SEQ');
            next;
        }

        #blank line or empty record: ignore
        if ($line =~ /$Pearson_Null/o) {
            next;
        }

        #default
        $self->warn("unknown field: $line");
    }
    $self;#->examine;
}


###########################################################################
package Bio::Parse::Format::Pearson::SEQ;

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

    $self->{'id'}    = '';
    $self->{'desc'}  = '';
    $self->{'seq'}   = '';

    while (defined ($line = $text->next_line(1))) {

        #read header line
        if ($line =~ /^\s*>\s*(\S+)\s*(.*)?/o) {
            $self->test_args(\$line, $1);
            (
             $self->{'id'},
             $self->{'desc'},
            ) = ($1, "$2");
            #2015-01-19, GeneDoc puts a '.' in after the identifier
            $self->{'desc'} = ''  if $self->{'desc'} =~ /^\s*\.\s*$/;
            next;
        }

        #read sequence lines up to asterisk, if present
        if ($line =~ /([^\*]+)/) {
            $self->{'seq'} .= $1;
            next;
        }

        #ignore lone asterisk
        last    if $line =~ /\*/;

        #default
        $self->warn("unknown field: $line");
    }

    #strip internal whitespace from sequence
    $self->{'seq'} =~ s/\s//g;

    $self;
}

sub dump_data {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    my $s = '';
    $s .= sprintf "$x%20s -> %s\n",   'id',   $self->{'id'};
    $s .= sprintf "$x%20s -> '%s'\n", 'desc', $self->{'desc'};
    $s .= sprintf "$x%20s -> %s\n",   'seq',  $self->{'seq'};
    return $s;
}


###########################################################################
1;
