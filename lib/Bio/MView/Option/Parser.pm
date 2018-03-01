# -*- perl -*-
# Copyright (C) 2018 Nigel P. Brown

###########################################################################
package Bio::MView::Option::Parser;

use Getopt::Long;
use strict;

my @OptionTypeLibs = ( 'Bio::MView::Option::Types' );
my @OptionLibs     = ( 'Bio::MView::Option::Options' );

my $DEBUG=0;

sub new {
    my ($type, $prog) = @_;
    my $self = {};
    bless $self, $type;

    $self->{'prog'}    = $prog;
    $self->{'argv'}    = [];
    $self->{'param'}   = {};

    $self->{'types'}   = {};
    $self->{'groups'}  = {};
    $self->{'options'} = {};

    $self->{'group_order'} = [];
    $self->{'option_order'} = [];

    foreach my $lib (@OptionTypeLibs) {
        load_library($lib);
        $self->load_types($lib);
    }

    foreach my $lib (@OptionLibs) {
        load_library($lib);
        $self->load_groups($lib);
        $self->load_options($lib);
    }

    #warn "types:   ", scalar keys %{$self->{'types'}}, "\n";
    #warn "groups:  ", scalar keys %{$self->{'groups'}}, "\n";
    #warn "options: ", scalar keys %{$self->{'options'}}, "\n";

    #want to search arglist for known options
    Getopt::Long::config(qw(permute));

    #keep quiet about unknown options
    Getopt::Long::config(qw(pass_through));

    return $self;
}

sub load_types {
    my ($self, $lib, $var) = (@_, 'Types');
    my $var = load_scalar($lib, ucfirst $var);
    foreach my $type (@$var) {
        my $tn = $type->{'type'};
        if (exists $self->{'types'}->{$tn}) {
            die "GetOptions: type '$tn' already exists\n";
        }
        $self->{'types'}->{$tn} = $type;
    }
    return $self;
}

sub load_groups {
    my ($self, $lib, $var) = (@_, 'Groups');
    my $var = load_scalar($lib, $var);
    foreach my $grp (@$var) {
        my $gn = $grp->{'group'};
        if (exists $self->{'groups'}->{$gn}) {
            die "GetOptions: group '$gn' already exists\n";
        }
        push @{$self->{'group_order'}}, $grp;
        $self->{'groups'}->{$gn} = $grp;
    }
    return $self;
}

sub load_options {
    my ($self, $lib, $var) = (@_, 'Options');
    my $var = load_scalar($lib, $var);
    foreach my $opt (@$var) {
        my $on = $opt->{'group'} . '::' . $opt->{'option'};
        push @{$self->{'option_order'}}, $opt;
        $self->{'options'}->{$on} = $opt;
        $self->initialise_option($opt);
    }
    return $self;
}

sub load_library {
    my $library = $_[0];
    $library =~ s/::/\//g;
    require "$library.pm";
}

sub load_scalar {
    my ($lib, $var) = @_;
    return eval '$' . $lib . '::' . $var;
}

sub initialise_option {
    my ($self, $opt) = @_;

    my $gn = $opt->{'group'};
    my $on = $opt->{'option'};

    if (! exists $opt->{'type'}) {
        die "GetOptions: option '$gn.$on' has no type\n";
    }

    if (! $opt->{'type'}) {
        die "GetOptions: option '$gn.$on' has empty type\n";
    }

    my $type = $self->get_type_record($opt);

    if (! defined $type) {
        die "GetOptions: option '$gn.$on' has unbound type\n";
    }

    #set a default value, unless set already
    if (! exists $opt->{'default'}) {

        if (! exists $type->{'default'}) {
            warn "GetOptions: no default for option '$gn.$on'\n";
            die  "GetOptions: no default for type '$type->{'type'}'\n";
        }

        $opt->{'default'} = $type->{'default'};
    }

    #set the option value from the default: will be overwritten from CL
    $opt->{'option_value'} = $opt->{'default'};

    #set the associated parameter name, unless set already
    $opt->{'param'} = $opt->{'option'}  unless exists $opt->{'param'};

    #set the default parameter value
    my @errors = $self->test_and_set_option($opt);

    if (@errors) {
        warn "GetOptions: option '$gn.$on' initialisation errors:\n";
        foreach my $e (@errors) {
            warn "GetOptions: $e\n";
        }
    }

    #dump_option($opt);

    return $self;
}

sub update_option {
    my ($self, $on, $ov) = @_;
    #warn "update_option ($on)\n";
    return  unless exists $self->{'options'}->{$on};
    my $opt = $self->{'options'}->{$on};
    $opt->{'option_value'} = $ov;
    $self->test_and_set_option($opt);
    #warn "update_option ($on) done\n";
}

sub usage {
    my $self = shift;
    my $s = $Bio::MView::Option::Options::Header;  #already loaded
    $s =~ s/<PROG>/$self->{'prog'}/;

    foreach my $grp (@{$self->{'group_order'}}) {
        next  unless exists $grp->{'header'};  #hidden group

        $s .= $grp->{'header'} . "\n";

        foreach my $opt (@{$self->{'option_order'}}) {
            next  unless $opt->{'group'} eq $grp->{'group'};
            $s .= $self->get_option_usage($opt);
        }

        $s .= "\n";
    }

    return $s;
}

sub get_type_record {
    my ($self, $key) = @_;
    while (ref $key) {  #search for a base type
        $key = $key->{'type'};
    }
    return $self->{'types'}->{$key}  if exists $self->{'types'}->{$key};
    return undef;
}

sub str {
    return '<UNDEF>'  unless defined $_[0];
    return "[@{$_[0]}]"  if ref $_[0] eq 'ARRAY';
    return $_[0];
}

sub get_attr_string {
    my ($self, $opt, $attr) = @_;
    return str($opt->{$attr})   if exists $opt->{$attr};
    my $type = $self->get_type_record($opt);
    return str($type->{$attr})  if exists $type->{$attr};
    return '<NOEXIST>';
}

sub get_label_string {
    my ($self, $opt) = @_;
    return $self->get_attr_string($opt, 'label');
}

sub get_default_string {
    my ($self, $opt) = @_;
    return $self->get_attr_string($opt, 'default');
}

sub get_usage_string {
    my ($self, $opt) = @_;
    return $self->get_attr_string($opt, 'usage');
}

sub get_option_usage {
    my ($self, $opt) = @_;
    my $name = $opt->{'option'};
    my $type = $self->get_label_string($opt);
    my $usage = $self->get_usage_string($opt);
    my $default = $self->get_default_string($opt);
    my $s = sprintf("  -%-20s %s", "$name $type", $usage);
    $s .= " [$default]"  if $default ne '';
    $s .= ".\n";
    return $s;
}

sub dump_item {
    my ($item, $stm) = (shift, shift);
    foreach my $key (@_) {
        next  unless exists $item->{$key};
        my $val = $item->{$key};
        $val = '<UNDEF>'  unless defined $val;
        $val = 'CODE'     if ref $val eq 'CODE';
        print $stm sprintf "%20s => %s\n", $key, $val;
    }
    print $stm "\n";
}

sub dump_type {
    my ($type, $stm) = (@_, \*STDERR);
    my @fields = qw(type label usage default test);
    dump_item($type, $stm, @fields);
}

sub dump_option {
    my ($opt, $stm) = (@_, \*STDERR);
    my @fields = qw(group option option_value usage default type test
                    label param);
    dump_item($opt, $stm, @fields);
}

sub get_available_group_options {
    my ($self, $grp) = @_;
    my @tmp = ();

    foreach my $opt (@{$self->{'option_order'}}) {
        next  unless $opt->{'group'} eq $grp->{'group'};

        my $o = $opt->{'option'};

        #dump_option($opt);

        #flag: no argument
	if ($opt->{'type'} =~/^flag/) {
	    push @tmp, $o;
            next;
        }

        #option: takes argument
        push @tmp, "$o=s";
    }

    return @tmp;
}

sub test_type {
    my ($self, $opt, $on, $pv, $e) = @_;

    return  unless defined $pv;

    my $type = $self->get_type_record($opt);
    my $test = $type->{'test'};

    if (ref $test eq 'CODE') {
        $pv = &{$test}($self, $on, $pv, $e);
    }

    return $pv;
}

sub test_and_set_option {
    my ($self, $opt) = @_;
    my @errors = ();

    #update the parameter hash with this option
    my $on  = $opt->{'option'};
    my $ov  = $opt->{'option_value'};

    #type tests and simple parameter conversion
    my $pv = $self->test_type($opt, $on, $ov, \@errors);

    #update the parameter hash
    $self->{'param'}->{$opt->{'param'}} = $pv;

    if ($DEBUG) {
        printf STDERR "opt:%15s => %-10s    par:%15s => %-10s\n",
            $opt->{'option'}, str($opt->{'option_value'}),
            $opt->{'param'},  str($self->{'param'}->{$opt->{'param'}});
    }
    return @errors;
}

sub parse_group {
    my ($self, $argv, $grp) = @_;

    my @avail = $self->get_available_group_options($grp);
    return ()  unless @avail;

    my @errors = ();
    my $scan = {};

    GetOptions($scan, @avail);

    #map { print STDERR "$_ => $scanned->{$_}\n" } %$scan;

    #process this group's CL options
    foreach my $opt (@{$self->{'option_order'}}) {
        next  unless $opt->{'group'} eq $grp->{'group'};

        my $on = $opt->{'option'};
        next  unless exists $scan->{$on};

        #save scanned value
        $opt->{'option_value'} = $scan->{$on};

        push @errors, $self->test_and_set_option($opt);
    }

    return @errors;
}

sub parse_argv {
    my ($self, $argv) = @_;
    my @errors = ();

    #save input ARGV for posterity
    push @{$self->{'argv'}}, @$argv;

    #process options in specified group order
    foreach my $grp (@{$self->{'group_order'}}) {
        push @errors, $self->parse_group($argv, $grp);
        return @errors  if @errors;
    }

    #fail unprocessed options; leave non-option arguments
    my @tmp = ();
    foreach my $arg (@$argv) {
	if ($arg =~ /^--?\S/) {
            push @errors, "unknown option '$arg'";
	}
        push @tmp, $arg;
    }
    @$argv = @tmp;

    return @errors;
}

sub get_parameters { return $_[0]->{'param'} }

sub dump_argv { return join(" ", @{$_[0]->{'argv'}}) }


###########################################################################
1;
