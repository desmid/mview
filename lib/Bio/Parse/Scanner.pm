# Copyright (C) 1996-2019 Nigel P. Brown

# This file is part of MView.
# MView is released under license GPLv2, or any later version.

use strict;

###########################################################################
package Bio::Parse::Scanner;

use Bio::Util::Object;
use Bio::Parse::ReadText;

use vars qw(@ISA);

@ISA = qw(Bio::Util::Object);

sub new {
    my ($type, $entry, $indent,  $text) = (@_, 0, undef);

    my $self = {};
    bless $self, $type;

    $self->{'entry'}  = $entry;
    $self->{'indent'} = $indent;

    if (defined $text and ref $text) {
        #use supplied text and positions (or defaults thereof)
        $self->{'text'}   = new Bio::Parse::ReadText($text);
        $self->{'offset'} = 0;
        $self->{'bytes'}  = length($$text);
    } else {
        #use entry object's text and positions
        $self->{'text'}   = $entry->get_text();
        $self->{'offset'} = $entry->get_offset();
        $self->{'bytes'}  = $entry->get_bytes();
    }

    $self->{'extent'}     = $self->{'offset'} + $self->{'bytes'};

    $self->{'linestart'}  = $self->{'offset'};
    $self->{'blockstart'} = $self->{'offset'};
    $self->{'cursor'}     = $self->{'offset'};

    $self->{'line'}       = '';
    $self->{'block'}      = '';

    $self;
}

sub get_offset { $_[0]->{'linestart'} }
sub get_bytes  { $_[0]->{'cursor'} - $_[0]->{'linestart'} }

sub get_line_start  { $_[0]->{'linestart'}; }
sub get_line_stop   { $_[0]->{'cursor'}; }
sub get_line_bytes  { $_[0]->{'cursor'} - $_[0]->{'linestart'}; }
sub get_line        { $_[0]->{'line'}; }

sub get_block_start { $_[0]->{'blockstart'}; }
sub get_block_stop  { $_[0]->{'cursor'}; }
sub get_block_bytes { $_[0]->{'cursor'} - $_[0]->{'blockstart'}; }
sub get_block       { $_[0]->{'block'}; }

# read next line; chomp line if optional argument is non-zero;
# return line read or undef if no bytes.
sub next_line {
    my ($self, $chomp) = (@_, 0);
    #warn "next_line(chomp=$chomp)\n";

    return undef  unless $self->_next_line_core;

    chomp $self->{'line'}  if $chomp;

    return $self->{'line'};
}

# Read $count lines; return block read.
sub scan_lines {
    my ($self, $count) = (@_, 0);
    #warn "scan_lines: $count lines\n";

    my $line   = \$self->{'line'};
    my $block  = \$self->{'block'};

    $$block = $$line; $self->{'blockstart'} = $self->{'linestart'};

    while ($count > 0 and $self->_next_line_core) {
        $$block .= $$line;
        $count--;
    }

    return $$block;
}

# read all remaining lines until EOF; return block read.
sub scan_remainder {
    my ($self, $count, $key) = (@_, 0);
    #warn "scan_lines:\n";

    my $line   = \$self->{'line'};
    my $block  = \$self->{'block'};

    $$block = $$line; $self->{'blockstart'} = $self->{'linestart'};

    while ($self->_next_line_core) {
        $$block .= $$line;
    }

    return $$block;
}

# read >= 1 record lines terminating on matching 'pattern';
# return block read.
sub scan_until {
    my ($self, $pattern) = @_;
    #warn "scan_until: until /$pattern/\n";

    my $line   = \$self->{'line'};
    my $block  = \$self->{'block'};

    $$block = $$line; $self->{'blockstart'} = $self->{'linestart'};

    while ($self->_next_line_core) {
        if ($$line =~ /$pattern/) {  #backup
            $self->{'cursor'} = $self->{'linestart'};
            $$line = '';
            last;
        }
        $$block .= $$line;
    }

    return $$block;
}

# read >= 1 record lines terminating on matching 'pattern';
# return block read.
sub scan_while {
    my ($self, $pattern) = @_;
    #warn "scan_while() looking at /$pattern/\n";

    my $line   = \$self->{'line'};
    my $block  = \$self->{'block'};

    $$block = $$line; $self->{'blockstart'} = $self->{'linestart'};

    while ($self->_next_line_core) {
        if ($$line !~ /$pattern/) {  #backup
            $self->{'cursor'} = $self->{'linestart'};
            $$line = '';
            last;
        }
        $$block .= $$line;
    }

    return $$block;
}

# read >= 1 record lines terminating on matching 'pattern';
# return block read.
sub scan_until_inclusive {
    my ($self, $pattern) = @_;
    #warn "scan_until_inclusive: until /$pattern/\n";

    my $line   = \$self->{'line'};
    my $block  = \$self->{'block'};

    $$block = $$line; $self->{'blockstart'} = $self->{'linestart'};

    while ($self->_next_line_core) {
        $$block .= $$line;
        last  if $$line =~ /$pattern/;
    }

    return $$block;
}

# read >= 1 record lines terminating on matching 'pattern';
# skip optional $skip instances (default 0) before terminating;
# return block read.
sub scan_skipping_until {
    my ($self, $pattern, $skip, $key) = (@_, 0);
    #warn "scan_skipping_until: /$pattern/\n";

    my $line   = \$self->{'line'};
    my $block  = \$self->{'block'};

    $$block = $$line; $self->{'blockstart'} = $self->{'linestart'};

    while ($self->_next_line_core) {
        if ($$line =~ /$pattern/) {
            if ($skip < 1) {  #backup
                $self->{'cursor'} = $self->{'linestart'};
                $$line = '';
                last;
            }
            $skip--;
        }
        $$block .= $$line;
    }

    return $$block;
}

# #Read >= 1 record lines terminating on failure to match empty lines or
# #initial blank space up to $nest characters. Store final record in 'entry'
# #using $key if set (defaults to unset). Assumes _next_line_core() called just
# #previously.
# sub scan_nest {
#     my ($self, $nest, $key) = (@_, 0);
#     #warn "scan_nest() looking at nest depth $nest\n";
#
#     my $line   = \$self->{'line'};
#     my $offset = $self->{'linestart'};
#     my $block  = $$line;
#
#     while ($self->_next_line_core) {
#         if ($$line !~ /^(\s{$nest}|$)/) {  #backup
#             $self->{'cursor'} = $self->{'linestart'};
#             $$line = '';
#             last;
#         }
#         $block .= $$line;
#     }
#     my $bytes = $self->{'cursor'} - $offset;
#
#     $self->{'entry'}->push_record($key, $offset, $bytes)  if $key;
#
#     return $block;
# }

###########################################################################
# private methods
###########################################################################
sub DESTROY {
    #warn "DESTROY $_[0]\n";
    map { $_[0]->{$_} = undef } keys %{$_[0]};
}

#read next line of text into self.line and return 1 on success; otherwise set
#self.line to undef and return 0
sub _next_line_core {
    my $self = shift;
    #warn sprintf("_next_line_core: > linestart=%d cursor=%d extent=%d\n",
    #    $self->{'linestart'}, $self->{'cursor'}, $self->{'extent'});

    my $line = \$self->{'line'};

    $$line = undef, return 0  if $self->{'cursor'} >= $self->{'extent'};

    #read the line
    my $bytes = $self->{'text'}->getline($line, $self->{'cursor'});

    #warn "_next_line_core:   read $bytes\n";

    return 0  unless $bytes;

    #ignore leading indent chars
    if ($self->{'indent'} > 0) {
        $$line = substr($$line, $self->{'indent'}, $bytes - $self->{'indent'});
    }

    #advance cursor
    $self->{'linestart'} = $self->{'cursor'};
    $self->{'cursor'}   += $bytes;

    #warn sprintf("_next_line_core: < linestart=%d cursor=%d\n",
    #             $self->{'linestart'}, $self->{'cursor'});

    return 1;
}

###########################################################################
# debug
###########################################################################
#return the remaining unprocessed stream without altering the cursor
sub inspect_stream {
    my $self = shift;
    return ''  if $self->{'cursor'} >= $self->{'extent'};
    return $self->{'text'}->substr(
        $self->{'cursor'}, $self->{'extent'} - $self->{'cursor'} + 1
    );
}

###########################################################################
1;
