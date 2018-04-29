# Copyright (C) 1996-2018 Nigel P. Brown

use strict;

###########################################################################
package Bio::Parse::Record_Stream;

use Bio::Parse::Substring;
use Bio::Parse::Message;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Message);

sub new {
    my $type = shift;
    my $self = {};
    my ($entry, $depth,  $text, $offset, $bytes) = (@_, 0);
    $self->{'entry'}  = $entry;
    $self->{'depth'}  = $depth;
    if (defined $text and ref $text) {
	#use supplied text and positions (or defaults thereof)
	$self->{'text'}   = new Bio::Parse::Substring($text);
	$self->{'offset'} = defined $offset ? $offset : 0;
	$self->{'bytes'}  = defined $bytes ? $bytes : length($$text);
    } else {
	#use entry object's text and positions
	$self->{'text'}   = $entry->{'text'};
	$self->{'offset'} = $entry->{'offset'};
	$self->{'bytes'}  = $entry->{'bytes'};
    }
    bless $self, $type;
    $self->reset;
}

sub DESTROY {
    #warn "DESTROY $_[0]\n";
    ####Bio no effect
    map { $_[0]->{$_} = undef } keys %{$_[0]};
}

sub get_offset { $_[0]->{'cursor'} - $_[0]->{'length'} }
sub get_bytes  { $_[0]->{'length'} }

sub reset {
    $_[0]->{'cursor'} = $_[0]->{'offset'};
    $_[0]->{'limit'}  = $_[0]->{'offset'} + $_[0]->{'bytes'};
    $_[0]->{'line'}   = '';
    $_[0]->{'length'} = 0;
    #warn "INITIAL=(c=$_[0]->{'cursor'} l=$_[0]->{'limit'})\n";
    $_[0];
}

sub backup {
    my $self = shift;
    $self->{'cursor'} -= $self->{'length'};
    $self->{'line'}    = '';
    $self->{'length'}  = 0;
}

#return the remaining unprocessed stream without altering the cursor
sub inspect_stream {
    return ''  if $_[0]->{'cursor'} >= $_[0]->{'limit'};
    $_[0]->{'text'}->substr($_[0]->{'cursor'},
			    $_[0]->{'limit'} - $_[0]->{'cursor'} + 1);
}

#return next line of text or undef if the text stream is done
sub _next_line {
    my $self = shift;

    #warn "_next_line: $self->{'cursor'} / $self->{'limit'}\n";

    my $line = \$self->{'line'};

    return $$line = undef  if $self->{'cursor'} >= $self->{'limit'};

    #ignore 'depth' leading characters
    my $ptr = $self->{'cursor'} + $self->{'depth'};

    #read the line
    $$line = $self->{'text'}->getline($ptr);

    return undef  unless defined $$line;

    #how many bytes were actually read?
    my $bytes = $self->{'text'}->bytesread;

    if ($self->{'cursor'} + $bytes > $self->{'limit'}) {
	$bytes = $self->{'limit'} - $ptr;
	$$line = substr($$line, 0, $bytes);
    }

    $self->{'length'}  = $self->{'depth'} + $bytes;
    $self->{'cursor'} += $self->{'length'};

    return $$line;
}

#return next line of text or undef if the text stream is done. chomp returned
#string if optional non-zero argument (defaults to zero).
sub next_line {
    my ($self, $chomp) = (@_, 0);

    #warn "next_line(chomp=$chomp)\n";

    my $line = \$self->{'line'};

    $self->_next_line;

    return undef  unless defined $$line;

    chomp $$line  if $chomp;

    return $$line;
}

#Read $count lines or all lines until (EOF or end-of-string) if $count==0.
#Store final $record in 'entry' using $key if set (defaults to unset).
#Assumes _next_line() called just previously.
sub scan_lines {
    my ($self, $count, $key) = (@_, 0);

    #warn "scan_lines() looking at ($count) lines\n";

    my $line   = \$self->{'line'};
    my $record = $$line;
    my $offset = $self->{'cursor'} - $self->{'length'};

    if ($count < 1) {  #scan everything
	while (defined $self->_next_line) {
	    $record .= $$line;
	}
    } else {  #scan $count lines
        $count--;  #already seen one line
        while ($count-- > 0 and defined $self->_next_line) {
	    $record .= $$line;
	}
    }
    #no $self->backup as we've read exactly the right amount
    my $bytes = $self->{'cursor'} - $offset;

    $self->{'entry'}->push_record($key, $offset, $bytes)  if $key;

    return $record;
}

#Read >= 1 record lines terminating on failure to match $pattern. Store
#final $record in 'entry' using $key if set (defaults to unset). Assumes
#_next_line() called just previously.
sub scan_while {
    my ($self, $pattern, $key) = (@_, 0);

    #warn "scan_while() looking at /$pattern/\n";

    my $line   = \$self->{'line'};
    my $record = $$line;
    my $offset = $self->{'cursor'} - $self->{'length'};

    while (defined $self->_next_line) {
	if ($$line !~ /$pattern/) {
            $self->backup;
            last;
        }
        $record .= $$line;
    }
    my $bytes = $self->{'cursor'} - $offset;

    $self->{'entry'}->push_record($key, $offset, $bytes)  if $key;

    return $record;
}

#Read >= 1 record lines terminating on matching $pattern. Store final
#$record in 'entry' using $key if set (defaults to unset). Assumes
#_next_line() called just previously. Consumed record EXCLUDES matched line.
sub scan_until {
    my ($self, $pattern, $key) = (@_, 0);

    #warn "scan_until() looking until /$pattern/\n";

    my $line   = \$self->{'line'};
    my $record = $$line;
    my $offset = $self->{'cursor'} - $self->{'length'};

    while (defined $self->_next_line) {
	if ($$line =~ /$pattern/) {
	    $self->backup;
	    last;
	}
	$record .= $$line;
    }
    my $bytes = $self->{'cursor'} - $offset;

    $self->{'entry'}->push_record($key, $offset, $bytes)  if $key;

    return $record;
}

#Read >= 1 record lines terminating on matching $pattern. Store final
#$record in 'entry' using $key if set (defaults to unset). Assumes
#_next_line() called just previously. Consumed record INCLUDES matched line.
sub scan_until_inclusive {
    my ($self, $pattern, $key) = (@_, 0);

    #warn "scan_until_inclusive() looking until /$pattern/\n";

    my $line   = \$self->{'line'};
    my $record = $$line;
    my $offset = $self->{'cursor'} - $self->{'length'};

    while (defined $self->_next_line) {
	$record .= $$line;
	last  if $$line =~ /$pattern/;
    }
    my $bytes = $self->{'cursor'} - $offset;

    $self->{'entry'}->push_record($key, $offset, $bytes)  if $key;

    return $record;
}

#Read >= 1 record lines terminating on matching $pattern. Store final
#$record in 'entry' using $key if set (defaults to unset). Assumes
#_next_line() called just previously. Consumed record EXCLUDES matched line.
#Skips initial $skipcount instances of $pattern.
sub scan_skipping_until {
    my ($self, $pattern, $skip, $key) = (@_, 0);

    #warn "scan_skipping_until() looking until /$pattern/\n";

    my $line   = \$self->{'line'};
    my $record = $$line;
    my $offset = $self->{'cursor'} - $self->{'length'};

    while (defined $self->_next_line) {
	if ($$line =~ /$pattern/) {
	    if ($skip-- < 1) {
	        $self->backup;
	        last;
            }
	}
	$record .= $$line;
    }
    my $bytes = $self->{'cursor'} - $offset;

    $self->{'entry'}->push_record($key, $offset, $bytes)  if $key;

    return $record;
}

#Read >= 1 record lines terminating on failure to match empty lines or
#initial blank space up to $nest characters. Store final $record in 'entry'
#using $key if set (defaults to unset). Assumes _next_line() called just
#previously.
sub scan_nest {
    my ($self, $nest, $key) = (@_, 0);

    #warn "scan_nest() looking at nest depth $nest\n";

    my $line   = \$self->{'line'};
    my $record = $$line;
    my $offset = $self->{'cursor'} - $self->{'length'};

    while (defined $self->_next_line) {
	if ($$line !~ /^(\s{$nest}|$)/) {
            $self->backup;
            last;
        }
        $record .= $$line;
    }
    my $bytes = $self->{'cursor'} - $offset;

    $self->{'entry'}->push_record($key, $offset, $bytes)  if $key;

    return $record;
}

###########################################################################
1;
