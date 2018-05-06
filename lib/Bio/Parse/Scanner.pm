# Copyright (C) 1996-2018 Nigel P. Brown

use strict;

###########################################################################
package Bio::Parse::Scanner;

use Bio::Parse::Substring;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Message);

sub new {
    my $type = shift;
    my ($entry, $depth,  $text, $offset, $bytes) = (@_, 0);

    my $self = {};
    bless $self, $type;

    $self->{'entry'} = $entry;
    $self->{'depth'} = $depth;

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

    $self->reset;

    $self;
}

sub get_offset { $_[0]->{'cursor'} - $_[0]->{'length'} }
sub get_bytes  { $_[0]->{'length'} }

#return the remaining unprocessed stream without altering the cursor
sub inspect_stream {
    my $self = shift;
    return ''  if $self->{'cursor'} >= $self->{'limit'};
    return $self->{'text'}->substr(
        $self->{'cursor'}, $self->{'limit'} - $self->{'cursor'} + 1
    );
}

#return next line of text or undef if the text stream is done; chomp line if
#optional argument is non-zero.
sub next_line {
    my ($self, $chomp) = (@_, 0);

    #warn "next_line(chomp=$chomp)\n";

    return undef  unless $self->_next_line;

    my $line = \$self->{'line'};
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
	while ($self->_next_line) {
	    $record .= $$line;
	}
    } else {  #scan $count lines
        $count--;  #already seen one line
        while ($count-- > 0 and $self->_next_line) {
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

    while ($self->_next_line) {
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

    while ($self->_next_line) {
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

    while ($self->_next_line) {
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

    while ($self->_next_line) {
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

    while ($self->_next_line) {
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
# private methods
###########################################################################
sub DESTROY {
    #warn "DESTROY $_[0]\n";
    map { $_[0]->{$_} = undef } keys %{$_[0]};
}

sub reset {
    my $self = shift;
    $self->{'cursor'} = $self->{'offset'};
    $self->{'limit'}  = $self->{'offset'} + $self->{'bytes'};
    $self->{'line'}   = '';
    $self->{'length'} = 0;
    #warn "INITIAL=(c=$self->{'cursor'} l=$self->{'limit'})\n";
}

sub backup {
    my $self = shift;
    $self->{'cursor'} -= $self->{'length'};
    $self->{'line'}    = '';
    $self->{'length'}  = 0;
}

#read next line of text into self.line and return 1 on success; otherwise set
#self.line to undef and return 0
sub _next_line {
    my $self = shift;

    #warn "_next_line: $self->{'cursor'} / $self->{'limit'}\n";

    my $line = \$self->{'line'};

    $$line = undef, return 0  if $self->{'cursor'} >= $self->{'limit'};

    #ignore 'depth' leading characters
    my $offset = $self->{'cursor'} + $self->{'depth'};

    #read the line
    my $bytes = $self->{'text'}->getline($line, $offset);

    return 0  unless $bytes;

    #truncate to within this delimited record
    if ($self->{'cursor'} + $bytes > $self->{'limit'}) {
	$bytes = $self->{'limit'} - $offset;
	$$line = substr($$line, 0, $bytes);
    }

    $self->{'length'}  = $self->{'depth'} + $bytes;
    $self->{'cursor'} += $self->{'length'};

    return 1;
}

###########################################################################
1;
