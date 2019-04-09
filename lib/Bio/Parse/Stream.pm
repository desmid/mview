# Copyright (C) 1996-2018 Nigel P. Brown

# This file is part of MView.
# MView is released under license GPLv2, or any later version.

use strict;

###########################################################################
package Bio::Parse::Stream;

use Bio::Parse::Record;
use Bio::Parse::Substring;
use Bio::Parse::Message;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Message);

#assumes a stream doesn't mix formats
sub new {
    my $type = shift;
    my ($file, $format) = @_;

    my $self = {};
    bless $self, $type;

    $self->{'file'}   = $file;
    $self->{'format'} = $format;
    $self->{'text'}   = new Bio::Parse::Substring($file);
    $self->{'offset'} = 0;  #where to start parsing

    ($file = "Bio::Parse::Format::$format") =~ s/::/\//g;
    require "$file.pm";

    $self;
}

sub get_entry {
    my $self = shift;
    #warn "Stream::get_entry: offset= $self->{'offset'}\n";

    $self->{'text'}->reset($self->{'offset'});  #start parsing here

    no strict 'refs';

    my $parser = "Bio::Parse::Format::$self->{'format'}::get_entry";

    $parser = &$parser($self);

    use strict 'refs';

    return undef  unless $parser;

    $self->{'offset'} += $parser->get_size;  #parsed this many bytes

    return $parser;
}

sub close { $_[0]->{'text'}->close }

###########################################################################
# private methods
###########################################################################
sub DESTROY { $_[0]->close }

###########################################################################
# debug methods
###########################################################################
sub print { $_[0]->examine(qw(file format)) }

###########################################################################
1;
