# Copyright (C) 1996-2018 Nigel P. Brown

######################################################################
package Universal;

use strict;

#pretty-print object contents by given ordered keys, or all sorted
sub dump_object { return "Class: $_[0]\n" . _dump_body(@_) }

#pretty-print hash contents by given ordered keys, or all sorted
sub dump_hash { return "$_[0]\n" . _dump_body(@_) }

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

sub min { return $_[0] < $_[1] ? $_[0] : $_[1] }

sub max { return $_[0] > $_[1] ? $_[0] : $_[1] }

sub swap { return ($_[1], $_[0]) }

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
# private fnuctions
###########################################################################
#pretty-print hash contents by given ordered keys, or all sorted
sub _dump_body {
    my $hash = shift;

    sub maxlen {
        my $w = 0;
        foreach my $key (@_) {
            $w = Universal::max($w, length(defined $key ? $key : '<NOEXIST>'));
        }
        return $w;
    }

    sub layout {
        my $w = shift; return sprintf("%${w}s => %s\n", @_);
    }

    push @_, sort keys %$hash  unless @_;

    my $w = maxlen(@_); return ''  unless $w > 0;
    my $s = '';

    foreach my $key (@_) {
        if (exists $hash->{$key}) {
            my $val = $hash->{$key};
            if (! defined $val) {
                $s .= layout($w, $key, '<UNDEF>');
                next;
            }
            my $ref = ref $val;
            if ($ref) {
                if ($ref eq 'ARRAY') {
                    $s .= layout($w, $key, "@[" . join(',', @$val)  . "]");
                    next;
                }
                if ($ref eq 'HASH') {
                    my @tmp = map { "$_:$val->{$_}" } sort keys %$val;
                    $s .= layout($w, $key, "%{" . join(',', @tmp) . "}");
                    next;
                }
                $s .= layout($w, $key, '<$ref>');  #other ref
                next;
            }
            #SCALAR
            $s .= layout($w, $key, (length($val) > 0 ? $val : "'$val'"));
        } else {
            $s .= layout($w, $key, '<NOEXIST>');
        }

    }
    return $s;
}

######################################################################
1;
