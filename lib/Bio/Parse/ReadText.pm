# Copyright (C) 1996-2019 Nigel P. Brown

# This file is part of MView.
# MView is released under license GPLv2, or any later version.

use strict;

###########################################################################
# Random access a string in memory assuming any DOS CRLF already converted

package Bio::Parse::ReadText;

use Bio::Util::Object;

use vars qw(@ISA $DEBUG);

@ISA = qw(Bio::Util::Object);

$DEBUG = 0;

sub new {
    my $type = shift;
    #warn "${type}::new:\n"  if $DEBUG;
    Bio::Util::Object::die($type, "new() invalid arguments:", @_)  if @_ < 1;
    my ($text, $base) = (@_, 0);
    my $self = {};
    bless $self, $type;

    $self->{'text'}       = $text;
    $self->{'base'}       = $base;
    $self->{'lastoffset'} = undef;
    $self->{'thisoffset'} = undef;
    $self->{'extent'}     = length ${$self->{'text'}};

    $self->open();

    $self;
}

sub open {
    my $self = shift;
    #warn "String::open:\n"  if $DEBUG;
    $self->reset($self->{'base'});
}

sub close {
    my $self = shift;
    #warn "String::close:\n"  if $DEBUG;
    $self->{'lastoffset'} = undef;
    $self->{'thisoffset'} = undef;
}

sub reset {
    my ($self, $offset) = @_;
    #warn "String::reset($offset)\n"  if $DEBUG;
    $self->{'lastoffset'} = $offset;
    $self->{'thisoffset'} = $offset;
}

sub substr {
    my $self = shift;
    #warn "String::substr(@_)\n"  if $DEBUG;
    my ($offset, $bytes) = @_;

    $bytes  = $self->{'extent'} - $self->{'base'}  unless defined $bytes;
    $offset = $self->{'base'}                      unless defined $offset;

    my $buff = CORE::substr(${$self->{'text'}}, $offset, $bytes);

    $self->{'lastoffset'} = $offset;
    $self->{'thisoffset'} = $offset + length $buff;

    #warn "String::substr: [$buff]\n"  if $DEBUG;

    return $buff;
}

sub getline {
    my $self = shift;
    #warn "String::getline(@_)\n"  if $DEBUG;
    my ($line, $offset) = (@_, $self->{'thisoffset'});

    return 0  unless -1 < $offset and $offset < $self->{'extent'};

    my $i = index(${$self->{'text'}}, "\n", $offset);

    if ($i < 0) {
        #read remaining text, if any, until end of string
        $$line = CORE::substr(${$self->{'text'}}, $offset);
        return 0  unless defined $$line;
    } else {
        #read line upto and including eol; cannot be undef
        $$line = CORE::substr(${$self->{'text'}}, $offset, $i - $offset + 1);
    }

    my $bytes = length $$line;

    $self->{'lastoffset'} = $offset;
    $self->{'thisoffset'} = $offset + $bytes;

    #warn "String::getline: [$$line]\n"  if $DEBUG;

    return $bytes;
}

sub startofline { $_[0]->{'lastoffset'} }
sub tell        { $_[0]->{'thisoffset'} }

###########################################################################
1;
