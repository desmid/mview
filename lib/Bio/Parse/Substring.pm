# Copyright (C) 1996-2018 Nigel P. Brown

# This file is part of MView. 
# MView is released under license GPLv2, or any later version.

use strict;

###########################################################################
package Bio::Parse::Substring;

use FileHandle;
use Bio::Parse::Message;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Message);

use vars qw($DEBUG);

$DEBUG = 0;

sub new {
    my $type = shift;
    #warn "${type}::new:\n"  if $DEBUG;
    Bio::Parse::Message::die($type, "new(@_): invalid argument list")
	if @_ < 1;
    return new Bio::Parse::Substring::String(@_) if ref $_[0];  #string ref
    return new Bio::Parse::Substring::File(@_);                 #filename
}

sub open  {}
sub close {}
sub reset {}

sub startofline { $_[0]->{'lastoffset'} }
sub tell        { $_[0]->{'thisoffset'} }

#sub DESTROY { warn "DESTROY $_[0]\n" }

###########################################################################
# Random access a file converting any DOS CRLF line endings on the fly

package Bio::Parse::Substring::File;

use POSIX;
use FileHandle;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Substring);

use vars qw($OPEN $CLOSE $ERROR);

$OPEN  = 1;
$CLOSE = 2;
$ERROR = 4;

sub new {
    my $type = shift;
    #warn "${type}::new\n"  if $Bio::Parse::Substring::DEBUG;
    my ($file, $base) = (@_, 0);
    my $self = {};
    bless $self, $type;

    $self->{'file'}       = $file;
    $self->{'base'}       = $base;
    $self->{'state'}      = $CLOSE;
    $self->{'lastoffset'} = undef;
    $self->{'thisoffset'} = undef;
    $self->{'crlf'}       = undef;
    $self->{'fh'}         = -1;

    $self->open;

    $self->{'extent'} = (stat $self->{'fh'})[7];

    $self;
}

sub open {
    my $self = shift;
    #warn "File::open:\n"  if $Bio::Parse::Substring::DEBUG;
    $self->reset($self->{'base'});
}

sub reset {
    my ($self, $offset) = @_;
    #warn "File::reset($offset)\n"  if $Bio::Parse::Substring::DEBUG;
    if ($self->{'state'} & $ERROR or $self->{'state'} & $OPEN) {
	$self->close;
    }
    $self->{'fh'} = new FileHandle  if $self->{'fh'} < 1;
    $self->{'fh'}->open($self->{'file'}) or $self->die("open: can't open '$self->{'file'}'");
    $self->{'state'} = $OPEN;
    $self->_init($offset);
}

sub close {
    my $self = shift;
    #warn "File::close:\n"  if $Bio::Parse::Substring::DEBUG;
    return $self  if $self->{'state'} & $CLOSE;
    $self->{'fh'}->close;
    $self->{'fh'} = -1;
    $self->{'state'} = $CLOSE;
    $self->{'lastoffset'} = undef;
    $self->{'thisoffset'} = undef;
    $self->{'crlf'}       = undef;
}

sub substr {
    my $self = shift;
    #warn "File::substr(@_)\n"  if $Bio::Parse::Substring::DEBUG;

    if ($self->{'state'} & $CLOSE) {
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
    $buff =~ s/\015\012/\012/go  if $self->{'crlf'};

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
    CORE::substr($$line, $bytes-2, 1, '')  if $self->{'crlf'};

    #warn "File::getline: [$$line]\n"  if $Bio::Parse::Substring::DEBUG;

    return $bytes;
}

###########################################################################
# private methods
###########################################################################
sub _init {
    my ($self, $offset) = @_;
    #warn "File::_init($offset):\n"  if $Bio::Parse::Substring::DEBUG;
    my $line = readline($self->{'fh'});
    $self->{'crlf'} = $self->_test_crlf(\$line);
    #seek absolute to desired offset
    $self->{'fh'}->seek($offset, SEEK_SET);
    $self->{'lastoffset'} = $offset;
    $self->{'thisoffset'} = $offset;
}

#detect CRLF in non-native DOS file on UNIX
sub _test_crlf {
    my ($self, $buff) = @_;
    my $test = index($$buff, "\r\n") > -1;
    #warn "File::_test_crlf: [$$buff] --> @{[$test > 0 ? '1' : '0']}\n";
    return $test;
}

###########################################################################
# Random access a string in memory assuming any DOS CRLF already converted

package Bio::Parse::Substring::String;

use Bio::Parse::Message;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Substring);

sub new {
    my $type = shift;
    #warn "${type}::new:\n"  if $Bio::Parse::Substring::DEBUG;
    my $self = {};
    bless $self, $type;

    ($self->{'text'}, $self->{'base'}) = (@_, 0);

    $self->{'lastoffset'} = undef;
    $self->{'thisoffset'} = undef;
    $self->{'extent'}     = length ${$self->{'text'}};

    $self->open;

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
    #set desired start
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
