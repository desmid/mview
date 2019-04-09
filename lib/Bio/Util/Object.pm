# Copyright (C) 1996-2018 Nigel P. Brown

# This file is part of MView.
# MView is released under license GPLv2, or any later version.

use strict;

######################################################################
package Bio::Util::Object;

use Exporter;

use vars qw(@ISA @EXPORT_OK);

@ISA = qw(Exporter);

@EXPORT_OK = qw(dump_object dump_hash);

#pretty-print object contents by given ordered keys, or all sorted
sub dump_object { return "Class: $_[0]\n" . _dump_body(@_) }

#pretty-print hash contents by given ordered keys, or all sorted
sub dump_hash { return "$_[0]\n" . _dump_body(@_) }

###########################################################################
# private functions
###########################################################################
use Bio::Util::Regexp;
use Bio::Util::Math qw(max);

#pretty-print hash contents by given ordered keys, or all sorted
sub _dump_body {
    my $hash = shift;

    sub maxlen {
        my $w = 0;
        foreach my $key (@_) {
            $w = max($w, length(defined $key ? $key : '<NOEXIST>'));
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
                $s .= layout($w, $key, 'UNDEF');
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
                $s .= layout($w, $key, "<$ref>");  #other ref
                next;
            }
            # numeric
            if ($val =~ /^$RX_Sreal$/) {
                $s .= layout($w, $key, (length($val) > 0 ? $val : "'$val'"));
                next;
            }
            #string
            $s .= layout($w, $key, "'$val'");
        } else {
            $s .= layout($w, $key, 'NOEXIST');
        }
    }
    return $s;
}

######################################################################
1;
