# Copyright (C) 1996-2019 Nigel P. Brown

# This file is part of MView.
# MView is released under license GPLv2, or any later version.

use strict;

###########################################################################
# Random access a file or in-memory string

package Bio::Parse::Substring;

use vars qw(@ISA);

@ISA = qw(Bio::Util::Object);

use vars qw($DEBUG);

$DEBUG = 0;

sub new {
    my $type = shift;
    #warn "${type}::new:\n"  if $DEBUG;
    Bio::Util::Object::die($type, "new() invalid arguments:", @_)  if @_ < 1;
    return new Bio::Parse::Substring::String(@_)  if ref $_[0];  #string ref
    return new Bio::Parse::Substring::File(@_);                  #filename
}

sub open  {}
sub close {}
sub reset {}
sub substr {}
sub getline {}
sub startofline { $_[0]->{'lastoffset'} }
sub tell        { $_[0]->{'thisoffset'} }

#sub DESTROY { warn "DESTROY $_[0]\n" }

###########################################################################
# Random access a file converting any DOS CRLF line endings on the fly

package Bio::Parse::Substring::File;

use FileHandle;
use POSIX;  # for SEEK_SET

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Substring);

use vars qw($OPEN $CLOSED $ERROR);

$OPEN = 1; $CLOSED = 2; $ERROR = 4;

sub new {
    my $type = shift;
    #warn "${type}::new\n"  if $Bio::Parse::Substring::DEBUG;
    my ($file, $base) = (@_, 0);
    my $self = {};
    bless $self, $type;

    $self->{'file'}       = $file;
    $self->{'base'}       = $base;
    $self->{'lastoffset'} = undef;
    $self->{'thisoffset'} = undef;
    $self->{'extent'}     = undef;

    $self->{'fh'}    = $self->{'fh'} = new FileHandle();
    $self->{'state'} = $CLOSED;
    $self->{'dos'}   = 0;  #true if file is non-native DOS

    $self->open();

    $self->{'extent'} = (stat $self->{'fh'})[7];

    $self;
}

sub open {
    my $self = shift;
    #warn "File::open:\n"  if $Bio::Parse::Substring::DEBUG;
    $self->reset($self->{'base'});
}

sub close {
    my $self = shift;
    #warn "File::close:\n"  if $Bio::Parse::Substring::DEBUG;
    return $self  if $self->{'state'} & $CLOSED;
    $self->{'fh'}->close();
    $self->{'state'} = $CLOSED;
    $self->{'lastoffset'} = undef;
    $self->{'thisoffset'} = undef;
    $self->{'dos'}        = 0;
}

sub reset {
    my ($self, $offset) = @_;
    #warn "File::reset($offset)\n"  if $Bio::Parse::Substring::DEBUG;
    if ($self->{'state'} & $ERROR or $self->{'state'} & $OPEN) {
        $self->close();
    }
    $self->{'fh'}->open($self->{'file'}) or $self->die("open: can't open '$self->{'file'}'");
    $self->{'state'} = $OPEN;
    $self->{'dos'} = $self->_file_has_crlf();
    $self->{'fh'}->seek($offset, SEEK_SET);  #seek absolute
    $self->{'lastoffset'} = $offset;
    $self->{'thisoffset'} = $offset;
}

sub substr {
    my $self = shift;
    #warn "File::substr(@_)\n"  if $Bio::Parse::Substring::DEBUG;

    if ($self->{'state'} & $CLOSED) {
        $self->die("substr: can't read on closed file '$self->{'file'}'");
    }

    my ($offset, $bytes) = @_;

    $bytes  = $self->{'extent'} - $self->{'base'}  unless defined $bytes;
    $offset = $self->{'base'}                      unless defined $offset;

    my $fh = $self->{'fh'};

    if (my $delta = $offset - $self->{'thisoffset'}) {
        return undef  unless seek($fh, $delta, SEEK_CUR);
    }

    my $buff = ''; $bytes = read($fh, $buff, $bytes);

    $self->{'lastoffset'} = $offset;
    $self->{'thisoffset'} = $offset + $bytes;

    #strip multiple CR if file from DOS
    $buff =~ s/\015\012/\012/go  if $self->{'dos'};

    #warn "File::substr: [$buff]\n"  if $Bio::Parse::Substring::DEBUG;

    return $buff;
}

sub getline {
    my $self = shift;
    #warn "File::getline(@_)\n"  if $Bio::Parse::Substring::DEBUG;
    my ($line, $offset) = (@_, $self->{'thisoffset'});

    my $fh = $self->{'fh'};

    if (my $delta = $offset - $self->{'thisoffset'}) {
        #warn "File::getline: seek($delta)\n"  if $Bio::Parse::Substring::DEBUG;
        return 0  unless seek($fh, $delta, SEEK_CUR);
    }

    $$line = readline($fh);

    return 0  unless defined $$line;

    my $bytes = length $$line;

    $self->{'lastoffset'} = $offset;
    $self->{'thisoffset'} = $offset + $bytes;

    #strip terminal CR if file from DOS
    CORE::substr($$line, $bytes-2, 1, '')  if $self->{'dos'};

    #warn "File::getline: [$$line]\n"  if $Bio::Parse::Substring::DEBUG;

    return $bytes;
}

###########################################################################
# private methods
###########################################################################
#detect CRLF in non-native DOS file on UNIX
sub _file_has_crlf {
    my $self = shift;
    my $line = readline($self->{'fh'});
    my $test = index($line, "\r\n") > -1;
    #warn "File::_file_has_crlf: [$line] --> @{[$test > 0 ? '1' : '0']}\n";
    return $test;
}

###########################################################################
# Random access a string in memory assuming any DOS CRLF already converted

package Bio::Parse::Substring::String;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Substring);

sub new {
    my $type = shift;
    #warn "${type}::new:\n"  if $Bio::Parse::Substring::DEBUG;
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
    #warn "String::open:\n"  if $Bio::Parse::Substring::DEBUG;
    $self->reset($self->{'base'});
}

sub close {
    my $self = shift;
    #warn "String::close:\n"  if $Bio::Parse::Substring::DEBUG;
    $self->{'lastoffset'} = undef;
    $self->{'thisoffset'} = undef;
}

sub reset {
    my ($self, $offset) = @_;
    #warn "String::reset($offset)\n"  if $Bio::Parse::Substring::DEBUG;
    $self->{'lastoffset'} = $offset;
    $self->{'thisoffset'} = $offset;
}

sub substr {
    my $self = shift;
    #warn "String::substr(@_)\n"  if $Bio::Parse::Substring::DEBUG;
    my ($offset, $bytes) = @_;

    $bytes  = $self->{'extent'} - $self->{'base'}  unless defined $bytes;
    $offset = $self->{'base'}                      unless defined $offset;

    my $buff = CORE::substr(${$self->{'text'}}, $offset, $bytes);

    $self->{'lastoffset'} = $offset;
    $self->{'thisoffset'} = $offset + length $buff;

    #warn "String::substr: [$buff]\n"  if $Bio::Parse::Substring::DEBUG;

    return $buff;
}

sub getline {
    my $self = shift;
    #warn "String::getline(@_)\n"  if $Bio::Parse::Substring::DEBUG;
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

    #warn "String::getline: [$$line]\n"  if $Bio::Parse::Substring::DEBUG;

    return $bytes;
}

###########################################################################
1;
