# Copyright (C) 1996-2018 Nigel P. Brown

# This file is part of MView. 
# MView is released under license GPLv2, or any later version.

use strict;

###########################################################################
package Bio::Util::System;

use Exporter;

use vars qw(@ISA @EXPORT_OK);

@ISA = qw(Exporter);

@EXPORT_OK = qw(stacktrace vmstat);

sub stacktrace {
    warn "Stack Trace:\n"; my $i = 0;
    my @calls = caller($i++);
    my ($file, $line, $func) = ($calls[1], $calls[2], $calls[3]);
    while ( @calls = caller($i++) ){
        #func is one ahead
        warn $file . ":" . $line . " in function " . $calls[3] . "\n";
        ($file, $line, $func) = ($calls[1], $calls[2], $calls[3]);
    }
}

#Linux only
sub vmstat {
    my ($s) = (@_, '');
    local ($_, *TMP);
    if (open(TMP, "cat /proc/$$/stat|")) {
        $_ = <TMP>; my @ps = split /\s+/; close TMP;
        print sprintf "VM: %8luk  $s\n", $ps[22] >> 10;
    } else {
        print sprintf "VM: -  $s\n";
    }
}

###########################################################################
1;
