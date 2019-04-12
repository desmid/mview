# Copyright (C) 1996-2019 Nigel P. Brown

# This file is part of MView.
# MView is released under license GPLv2, or any later version.

use strict;

###########################################################################
# Random access a file converting any DOS CRLF line endings on the fly

package Bio::Parse::ReadFile;

use FileHandle;
use POSIX;  # for SEEK_SET

use Bio::Util::Object;

use vars qw(@ISA $DEBUG);

@ISA = qw(Bio::Util::Object);

$DEBUG = 0;

use vars qw($OPEN $CLOSED $ERROR);

$OPEN = 1; $CLOSED = 2; $ERROR = 4;

sub new {
    my $type = shift;
    #warn "${type}::new\n"  if $DEBUG;
    Bio::Util::Object::die($type, "new() invalid arguments:", @_)  if @_ < 1;
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

    $self;
}

sub open {
    my $self = shift;
    #warn "File::open:\n"  if $DEBUG;
    if ($self->{'state'} != $CLOSED) {
        $self->close();
    }
    $self->{'fh'}->open($self->{'file'}) or $self->die("open: can't open '$self->{'file'}'");
    $self->{'extent'} = (stat $self->{'fh'})[7];
    $self->{'state'} = $OPEN;
    $self->{'dos'} = $self->_file_has_crlf();
    $self->reset($self->{'base'});
}

sub close {
    my $self = shift;
    #warn "File::close:\n"  if $DEBUG;
    if ($self->{'state'} == $CLOSED) {
        return;
    }
    $self->{'fh'}->close();
    $self->{'state'} = $CLOSED;
    $self->{'lastoffset'} = undef;
    $self->{'thisoffset'} = undef;
}

sub reset {
    my ($self, $offset) = @_;
    #warn "File::reset($offset)\n"  if $DEBUG;
    if ($self->{'state'} != $OPEN) {
        $self->die("reset: can't reset '$self->{'file'}'");
    }
    $self->{'fh'}->seek($offset, SEEK_SET);  #seek absolute
    $self->{'lastoffset'} = $offset;
    $self->{'thisoffset'} = $offset;
}

sub substr {
    my $self = shift;
    #warn "File::substr(@_)\n"  if $DEBUG;

    if ($self->{'state'} != $OPEN) {
        $self->die("substr: can't read '$self->{'file'}'");
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

    #warn "File::substr: [$buff]\n"  if $DEBUG;

    return $buff;
}

sub getline {
    my $self = shift;
    #warn "File::getline(@_)\n"  if $DEBUG;
    my ($line, $offset) = (@_, $self->{'thisoffset'});

    my $fh = $self->{'fh'};

    if (my $delta = $offset - $self->{'thisoffset'}) {
        #warn "File::getline: seek($delta)\n"  if $DEBUG;
        return 0  unless seek($fh, $delta, SEEK_CUR);
    }

    $$line = readline($fh);

    return 0  unless defined $$line;

    my $bytes = length $$line;

    $self->{'lastoffset'} = $offset;
    $self->{'thisoffset'} = $offset + $bytes;

    #convert CRLF to LF if file from DOS
    CORE::substr($$line, $bytes-2, 1, '')  if $self->{'dos'};

    #warn "File::getline: [$$line]\n"  if $DEBUG;

    return $bytes;
}

sub startofline { $_[0]->{'lastoffset'} }
sub tell        { $_[0]->{'thisoffset'} }

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
1;
