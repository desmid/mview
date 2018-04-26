# Copyright (C) 1996-2018 Nigel P. Brown

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
    #warn "${type}::new()\n"  if $DEBUG;
    Bio::Parse::Message::die($type, "new() invalid argument list (@_)")
	if @_ < 1;
    return new Bio::Parse::Substring::String(@_) if ref $_[0];  #string ref
    return new Bio::Parse::Substring::File(@_);                 #filename
}

#sub DESTROY { warn "DESTROY $_[0]\n" }

sub get_file    { '' }
sub get_length  { $_[0]->{'extent'} }
sub get_base    { $_[0]->{'base'} }
sub startofline { $_[0]->{'lastoffset'} }
sub bytesread   { $_[0]->{'thisoffset'} - $_[0]->{'lastoffset'} }
sub tell        { $_[0]->{'thisoffset'} }

###########################################################################
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
    #warn "${type}::new()\n"  if $Bio::Parse::Substring::DEBUG;
    my ($file, $base) = (@_, 0);
    my $self = {};
    bless $self, $type;

    $self->{'file'}       = $file;
    $self->{'base'}       = $base;
    $self->{'state'}      = $CLOSE;
    $self->{'lastoffset'} = undef;
    $self->{'thisoffset'} = undef;
    $self->{'fh'} = -1;

    $self->_open;

    #find file extent
    #$self->{'fh'}->seek(0, SEEK_END);
    $self->{'extent'} = (stat $self->{'fh'})[7];

    $self;
}

sub get_file {$_[0]->{'file'}}

sub close {
    #warn "close()\n"  if $Bio::Parse::Substring::DEBUG;
    $_[0]->_close;
}

sub open {
    #warn "open()\n"  if $Bio::Parse::Substring::DEBUG;
    $_[0]->reopen(@_);
}

sub reopen {
    my $self = shift;
    #warn "reopen()\n"  if $Bio::Parse::Substring::DEBUG;
    if ($self->{'state'} & $ERROR or $self->{'state'} & $OPEN) {
	$self->_close;
    }
    $self->_open;
    $self->_reset;
    $self;	
}

sub reset {
    my $self = shift;
    #warn "reset(@_)\n"  if $Bio::Parse::Substring::DEBUG;
    if ($self->{'state'} & $ERROR) {
	$self->_close;
	$self->_open;
    } elsif ($self->{'state'} & $CLOSE) {
	$self->_open;
    }
    $self->_reset(@_);
    $self;	
}

sub _seek {
    my ($self, $new) = @_;
    my $delta = $new - $self->{'thisoffset'};
    #warn "seek: entry: $delta\n"  if $Bio::Parse::Substring::DEBUG;
    return 1  unless $delta;
    return seek($self->{'fh'}, $delta, SEEK_CUR);
}

sub _reset {
    my $self = shift;
    my ($offset) = (@_, $self->{'base'});
    #warn "_reset(@_)\n"  if $Bio::Parse::Substring::DEBUG;
    $self->{'fh'}->seek($offset, SEEK_SET);
    $self->{'lastoffset'} = $offset;
    $self->{'thisoffset'} = $offset;
    $self;
}

sub _close {
    my $self = shift;
    warn "_close()\n"  if $Bio::Parse::Substring::DEBUG;
    return $self  if $self->{'state'} & $CLOSE;
    $self->{'fh'}->close;
    $self->{'fh'} = -1;
    $self->{'state'} = $CLOSE;
    $self;
}

sub _open {
    my $self = shift;
    #warn "_open()\n"  if $Bio::Parse::Substring::DEBUG;
    $self->{'fh'} = new FileHandle  if $self->{'fh'} < 1;
    $self->{'fh'}->open($self->{'file'}) or $self->die("_open() can't open ($self->{'file'})");
    $self->{'state'} = $OPEN;
    $self->{'lastoffset'} = $self->{'base'};
    $self->{'thisoffset'} = $self->{'base'};
    $self;
}

sub substr {
    my $self = shift;
    #warn "substr(@_)\n"  if $Bio::Parse::Substring::DEBUG;
    if ($self->{'state'} & $CLOSE) {
	$self->die("substr() can't read on closed file '$self->{'file'}'");
    }
    my ($offset, $bytes) = (@_, $self->{'base'}, $self->{'extent'}-$self->{'base'});
    my $buff = '';

    $self->{'lastoffset'} = $offset;
    if ($self->_seek($offset)) {
        my $c = read($self->{'fh'}, $buff, $bytes);
        $self->{'thisoffset'} = $offset + $c;
    }

    $buff;
}

sub getline {
    my $self = shift;
    #warn "getline(@_)\n"  if $Bio::Parse::Substring::DEBUG;
    my ($offset) = (@_, $self->{'thisoffset'});

    $self->{'lastoffset'} = $offset;

    return undef  unless $self->_seek($offset);

    my $line = readline($self->{'fh'});

    return undef  unless defined $line;

    $self->{'thisoffset'} = $offset + length($line);
    #warn "getline:  $self->{'lastoffset'}, $self->{'thisoffset'}\n";

    #consume CR in CRLF if file came from DOS/Windows
    $line =~ s/\015\012/\012/go;
    $line;
}

###########################################################################
# A wrapper for a string held in memory to mimic a Substring::File

package Bio::Parse::Substring::String;

use Bio::Parse::Message;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Substring);

sub new {
    my $type = shift;
    #warn "${type}::new()\n"  if $Bio::Parse::Substring::DEBUG;
    my $self = {};
    ($self->{'text'}, $self->{'base'}) = (@_, 0);
    $self->{'extent'} = length ${$self->{'text'}};
    $self->{'lastoffset'} = undef;
    $self->{'thisoffset'} = undef;
    bless $self, $type;
}

sub close  {$_[0]}
sub open   {$_[0]}
sub reopen {$_[0]}

sub reset {
    my $self = shift;
    my ($offset) = (@_, $self->{'base'});
    #warn "reset(@_)\n"  if $Bio::Parse::Substring::DEBUG;
    $self->{'lastoffset'} = $offset;
    $self->{'thisoffset'} = $offset;
    $self;
}

sub substr {
    my $self = shift;
    my ($offset, $bytes) = (@_, $self->{'base'}, 
			    $self->{'extent'}-$self->{'base'});
    CORE::substr(${$self->{'text'}}, $offset, $bytes);
}

sub getline {
    my $self = shift;
    my ($offset) = (@_, $self->{'base'});

    $self->{'lastoffset'} = $offset;

    my $i = index(${$self->{'text'}}, "\n", $offset);
    my $line;
    if ($i > -1) {
        $line = CORE::substr(${$self->{'text'}}, $offset, $i-$offset+1);
    } else {
        $line = CORE::substr(${$self->{'text'}}, $offset);
    }

    $self->{'thisoffset'} = $offset + length($line);

    return undef  unless defined $line;

    #consume CR in CRLF if file came from DOS/Windows
    $line =~ s/\015\012/\012/go;
    $line;
}

###########################################################################
1;
