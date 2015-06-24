# -*- perl -*-
# Copyright (C) 1996-2015 Nigel P. Brown
# $Id: Stream.pm,v 1.9 2005/12/12 20:42:48 brown Exp $

###########################################################################
package NPB::Parse::Stream;

use vars qw(@ISA);
# use FileHandle;
use NPB::Parse::Message;
use NPB::Parse::Record;
use NPB::Parse::Substring;
use strict;

@ISA = qw(NPB::Parse::Message);

#assumes a stream doesn't mix formats
sub new {
    my $type = shift;
    my ($file, $format) = @_;
    my $self = {};
    bless $self, $type;

    $self->{'file'}   = $file;
    $self->{'format'} = $format;
    $self->{'text'}   = new NPB::Parse::Substring($file);
    $self->{'offset'} = 0;  #where to start parsing

    ($file = "NPB::Parse::Format::$format") =~ s/::/\//g;
    require "$file.pm";

    $self;
}

sub get_file   { $_[0]->{'file'} }
sub get_format { $_[0]->{'format'} }
sub get_length { $_[0]->{'text'}->get_length }

sub get_entry {
    my $self = shift;
    #warn "\nStream::get_entry\n";

    $self->{'text'}->reset($self->{'offset'});  #start parsing here

    no strict 'refs';
    my $e = &{"NPB::Parse::Format::$self->{'format'}::get_entry"}($self);
    return undef  unless $e;

    $self->{'offset'} += $e->{'bytes'};  #parsed this many bytes

    $e;
}

sub print {
    my $self = shift;
    $self->examine(qw(file format));
} 

sub close { $_[0]->{'text'}->close }

sub DESTROY { $_[0]->close }


###########################################################################
1;
