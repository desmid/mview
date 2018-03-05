# Copyright (C) 2018 Nigel P. Brown

###########################################################################
package Kwargs;

# A mixin used to provide keyword arguments having default values in class
# methods:
#
# sub my_func {
#     my ($self, $first) = (shift, shift);
#
#     my $kw = Kwargs::set(@_);  #scan remaining args
#
#     warn $kw->{'keyword1'};  #do something
#     warn $kw->{'keyword2'};  #do something
#     warn $kw->{'keyword3'};  #do something
# }
#
# $obj->my_func(123, 'keyword2' => 3.14);  #call and override keyword2
#
# The keywords and their default values are set in a package level $KWARGS
# hashref.
#
# In a class hierarchy, subclasses can set their own global $KWARGS that
# successively augment the parental ones right back to the base class. The
# base class itself must set the dummy keyword '' to 1 (as below), which
# terminates the search.
#
# In the base class:
#
# $KWARGS = {
#     '' => 1,  #sentinel: terminate kwargs search
#     'keyword1' => default_value1,
#     'keyword2' => default_value2,
# };
#
# In a subclass:
#
# $KWARGS = {
#     'keyword3' => default_value3,
# };
#
# Unrecognised keywords, i.e., any that are not in any KWARGS chain, are
# quietly ignored unless $Kwargs::Warn_Unknown_Keyword is set.

$Warn_Unknown_Keyword = 0;  #set this to 1 to report unknown keywords

use strict;

#public function
sub set {
    #warn "set_kwargs: (@_)\n";
    my $kw = {};
    my $class = caller();
    _kwargs_search($kw, $class, @_);
    return $kw;
}

#implementation
sub _kwargs_search {
    my ($kw, $class) = (shift, shift);

    #warn "entering: $class\n";
    my $kwargs = eval '$' . $class . '::KWARGS';

    if (defined $kwargs and $kwargs->{''} or $class eq '') {
        #warn "  base case\n";
        _kwargs_base_case($kw, $kwargs, @_);
        return;
    }

    #warn "  inner case\n";
    @_ = _kwargs_inner_case($kw, $kwargs, @_);

    #search parent
    my @isa = eval '@' . $class . '::ISA';

    $class = pop @isa;

    #warn "  trying: $class\n";
    _kwargs_search($kw, $class, @_);
}

sub _kwargs_base_case {
    my ($kw, $kwargs) = (shift, shift);

    #warn "  do base: $kwargs (@_)\n";

    if (defined $kwargs) {

        #set own defaults
        map { $kw->{$_} = $kwargs->{$_} } keys %$kwargs;

        delete $kw->{''};  #remove the base KWARGS sentinel

        while (@_) {
            my ($k, $v) = (shift, shift);

            warn "Kwargs::set: unknown keyword '$k'\n"
                if $Kwargs::Warn_Unknown_Keyword and !exists $kw->{$k};

            #warn "  saving $k: $v\n";
            $kw->{$k} = $v;  #override default
        }
    }
}

sub _kwargs_inner_case {
    my ($kw, $kwargs) = (shift, shift);

    #warn "  do inner: $kwargs (@_)\n";

    my @rest = ();

    if (defined $kwargs) {

        #set own defaults
        map { $kw->{$_} = $kwargs->{$_} } keys %$kwargs;

        while (@_) {
            my ($k, $v) = (shift, shift);

            if (!exists $kw->{$k}) {
                push @rest, $k, $v;  #replace for parent
                next;
            }

            #warn "  saving $k: $v\n";
            $kw->{$k} = $v;  #override default
        }

        return @rest;
    }

    return @_;
}

######################################################################
1;
