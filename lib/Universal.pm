# Copyright (C) 1996-2018 Nigel P. Brown

######################################################################
package Universal;

use strict;

#pretty-print object contents by given ordered keys, or all sorted
sub dump_object {
    my $self = shift;
    warn "Class: $self\n";
    @_ = sort keys %$self  unless @_;
    foreach my $k (@_) {
        warn sprintf "%16s => %s\n", $k,
            defined $self->{$k} ? $self->{$k} : '';
    }
}

#pretty-print hash contents by given ordered keys, or all sorted
sub dump_hash {
    my $hash = shift;
    warn "HASH: $hash\n";
    @_ = sort keys %$hash  unless @_;
    foreach my $k (@_) {
        warn sprintf "%16s => %s\n", $k,
            defined $hash->{$k} ? $hash->{$k} : '';
    }
}

#replacement for /bin/basename
sub basename {
    my ($path, $ext) = (@_, "");
    if ($^O ne 'MSWin32') {
        ($path) = "/$path" =~ /.*\/(.+)$/;
        return $1  if $path =~ /(.*)$ext$/;
        return $path;
    }
    ($path) = "\\$path" =~ /.*\\(.+)$/;
    return $1  if $path =~ /(.*)$ext$/;
}

#basename and extension
sub fileparts {
    my ($path, $wantbase) = (@_, 1); #discard leading path if true (default)
    $path = basename($path)  if $wantbase;
    return ($1, $2)  if $path =~ /^(.+?)\.([^.]+)$/; #non-greedy
    return ('', $1)  if $path =~ /^\.([^.]+)$/;
    return ($1, '')  if $path =~ /^(.+)\.$/;
    return ($path, '');
}

#temporary file name
sub tmpfile {
    my ($s) = (@_, $$);
    return "/tmp/$s"  if $^O ne 'MSWin32';
    return $s;
}

sub min {
    my ($a, $b) = @_;
    return $a < $b ? $a : $b;
}

sub max {
    my ($a, $b) = @_;
    return $a > $b ? $a : $b;
}

sub swap {
    my ($a, $b) = @_;
    my $t = $a; $a = $b; $b = $t;
    return ($a, $b);
}

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

######################################################################
1;
