# -*- perl -*-
# Copyright (C) 1999-2018 Nigel P. Brown

###########################################################################
# 
# Getopt fields:
#
# [.]        names the generic group of options which may be shared.
# [name]     names a group of options.
#
# header:    descriptive string, may span multiple lines.
#
# option:    the command line option, or instead,
# generic:   refer to an already defined option in group [.].
#
# usage:     usage string; if undefined, be silent about the option.
# type:      parameter type (see below for variants).
# default:   default parameter value.
# param:     internal parameter name: if null or empty uses option name.
# convert:   function, return value sets the parameter value.
# action:    function, for side effects only.
# 
###########################################################################
$Bio::Getopt::GENERIC_GROUP = '.';

###########################################################################
package Bio::Getopt::Option;

use strict;

my %Template =
    (
     'usage'   => undef,
     'type'    => '',
     'default' => undef,
     'param'   => undef,
     'convert' => undef,
     'action'  => undef,
    );

sub new {
    my $type = shift;
    my $self = {};
    my ($name, $generic) = (@_, 0);  #1 is generic

    $self->{'name'}    = $name;
    $self->{'generic'} = $generic;
    $self->{'o_val'}   = undef;
    $self->{'p_val'}   = undef;

    bless $self, $type;
}

sub init {
    my $self = shift;
    foreach my $val (keys %Template) {
        $self->{$val} = $Template{$val} if !exists $self->{$val};
    }
    $self;
}

sub set_attribute {
    my ($self, $key, $val) = @_;
    $self->{$key} = $val;
    $self;
}

sub is_generic { return $_[0]->{'generic'} == 1 }

sub name    { return $_[0]->{'name'} }
sub o_val   { return $_[0]->{'o_val'} }
sub p_val   { return $_[0]->{'p_val'} }

sub usage   { return $_[0]->{'usage'} }
sub type    { return $_[0]->{'type'} }
sub default { return $_[0]->{'default'} }
sub param   { return $_[0]->{'param'} }
sub convert { return $_[0]->{'convert'} }
sub action  { return $_[0]->{'action'} }

sub _as_string {
    my ($self, $v) = @_;
    return "undef"  unless defined $v;
    if ($v eq '') {
        return "''";
    }
    if (ref $v eq 'ARRAY') {
        return "[" . join(@$v, ",") . "]";
    }
    return "$v";
}

sub name_string    { return $_[0]->_as_string($_[0]->{'name'}) }
sub generic_string { return $_[0]->_as_string($_[0]->{'generic'}) }
sub o_val_string   { return $_[0]->_as_string($_[0]->{'o_val'}) }
sub p_val_string   { return $_[0]->_as_string($_[0]->{'p_val'}) }
sub usage_string   { return $_[0]->_as_string($_[0]->{'usage'}) }
sub param_string   { return $_[0]->_as_string($_[0]->{'param'}) }
sub type_string    { return $_[0]->_as_string($_[0]->{'type'}) }
                   
sub type_string_long {
    return "on|off"     if $_[0]->{'type'} eq 'b';
    return "integer"    if $_[0]->{'type'} eq 'i';
    return "float"      if $_[0]->{'type'} eq 'f';
    return "string"     if $_[0]->{'type'} eq 's';
    return "int[,int]"  if $_[0]->{'type'} eq '@i';
    return "flo[,flo]"  if $_[0]->{'type'} eq '@f';
    return "str[,str]"  if $_[0]->{'type'} eq '@s';
    return "int[,int]"  if $_[0]->{'type'} eq '@I';
    return "flo[,flo]"  if $_[0]->{'type'} eq '@F';
    return "str[,str]"  if $_[0]->{'type'} eq '@S';
    return '';
}

sub default_string {
    return "no default"  unless defined $_[0]->{'default'};
    if ($_[0]->{'type'} eq '') {
        return ($_[0]->{'default'} ? 'set' : 'unset');
    }
    if ($_[0]->{'default'} eq '') {
        return "''";
    }
    if (ref $_[0]->{'default'} eq 'ARRAY') {
        return "[" . join(@{$_[0]->{'default'}}, ",") . "]";
    }
    return $_[0]->{'default'};
}

sub dump {
    my ($self, $stm) = (@_, \*STDERR);
    print $stm sprintf "%20s => %s\n", 'option',      $self->name_string;
    print $stm sprintf "%20s => %s\n", 'generic',     $self->generic_string;
    print $stm sprintf "%20s => %s\n", 'o_val',       $self->o_val_string;
    print $stm sprintf "%20s => %s\n", 'p_val',       $self->p_val_string;
    print $stm sprintf "%20s => %s\n", 'usage',       $self->usage_string;
    print $stm sprintf "%20s => %s\n", 'type',        $self->type_string;
    print $stm sprintf "%20s => %s\n", 'type_string', $self->type_string_long;
    print $stm sprintf "%20s => %s\n", 'default',     $self->default_string;
    print $stm sprintf "%20s => %s\n", 'param',       $self->param_string;
    print $stm "\n";
    $_[0];
}


###########################################################################
package Bio::Getopt::Group;

use Getopt::Long;
use NPB::Parse::Regexps;
use strict;

my $DEBUG = 0;

sub new {
    my $type = shift;
    my ($prog, $name, $passthru) = (@_, 1);
    my $self = {};

    $self->{'prog'}   = $prog;
    $self->{'name'}   = $name;
    $self->{'text'}   = undef;
    $self->{'option'} = {};
    $self->{'order'}  = [];
    $self->{'errors'} = [];

    #want to search arglist for known options
    Getopt::Long::config(qw(permute));

    if ($passthru) {
	#keep quiet about unknown options: may be
	#recognised by another instance
	Getopt::Long::config(qw(pass_through));
    } else {
	#complain about unknown options
	Getopt::Long::config(qw(no_pass_through));
    }

    bless $self, $type;
}

sub init {
    my $self = shift;
    foreach my $o (keys %{$self->{'option'}}) {
        my $item = $self->{'option'}->{$o};
        $item->init;
    }
    $self;
}

sub set_text {
    my ($self, $text) = @_;
    $self->{'text'} = $text;
    $self;
}

sub set_option {
    my ($self, $option) = @_;
    my $item = new Bio::Getopt::Option($option);
    $self->{'option'}->{$option} = $item;
    push @{$self->{'order'}}, $option;
    $self;
}

sub set_generic {
    my ($self, $option) = @_;
    my $item = new Bio::Getopt::Option($option, 1);
    $self->{'option'}->{$option} = $item;
    push @{$self->{'order'}}, $option;
    $self;
}

sub set_option_keyval {
    my ($self, $option, $key, $val) = @_;
    $self->{'option'}->{$option}->set_attribute($key, $val);
    $self;
}

sub warn {
    my $self = shift;
    push @{$self->{'errors'}}, "$self->{'prog'}: @_\n";
    $self;
}

sub die {
    my $self = shift;
    CORE::warn $self->get_errors  if @{$self->{'errors'}};
    CORE::die "$self->{'prog'}: @_\n";
}

sub usage {
    my ($self, $generic) = (shift, shift);
    my @list = ();

    return ''  if $self->{'name'} eq $Bio::Getopt::GENERIC_GROUP;  #silent

    #lookup the option in this group, or in the generic group
    foreach my $o (@{$self->{'order'}}) {
        my $item = $self->{'option'}->{$o};
        $item = $generic->{'option'}->{$o}  if $item->is_generic;
        if (defined $item->usage) {
            push @list, $item;
            next;
        }
    }

    return ''  unless @list;

    my $s = '';

    if (defined $self->{'text'} and $self->{'text'}) {
        $s = $self->{'text'} . "\n";
    }
    
    foreach my $item (@list) {
        my $name    = $item->name;
        my $type    = $item->type_string_long;
	my $usage   = $item->usage_string;
	my $default = $item->default_string;
	$s .= sprintf("  -%-20s %s [%s].\n", "$name $type", $usage, $default);
    }
    return "$s\n";
}

sub get_options {
    my $self = shift;
    my ($caller, $opt, $par) = @_;
    my (@tmp, $o, $ov, $p, $pv);

    return  if (@tmp = $self->build_options) < 1;

    GetOptions($opt, @tmp);

    #map { print STDERR "$_ => $opt->{$_}\n" } %$opt;

OPTION:
    foreach $o (@{$self->{'order'}}) {

        my $item = $self->{'option'}->{$o};

        next  if $item->is_generic;  #let the [.] group deal with it

        $ov = $item->default;                     #default
        $ov = $opt->{$o}  if defined $opt->{$o};  #command line

	$p = $item->param;                        #explicit name
	$p = $o  unless defined $p;               #use option name
	
	#type tests and simple parameter conversion
	$pv = $self->test_type($item->type, $o, $ov);

	next OPTION  if @{$self->{'errors'}};

	#convert: special parameter conversion
        if (defined $item->convert and ref $item->convert eq 'CODE') {
            $pv = &{$item->convert}($caller, $self, $o, $ov, $p, $pv);
	}

	next OPTION  if @{$self->{'errors'}};

	#action: perform special action
	if (defined $item->action and ref $item->action eq 'CODE') {
	    &{$item->action}($caller, $self, $o, $ov, $p, $pv);
	}
	
	next OPTION  if @{$self->{'errors'}};

	#overwrite caller's parameter values
        $par->{$p} = $pv;

        $item->set_attribute('o_val', $ov);
        $item->set_attribute('p_val', $pv);

	if ($DEBUG) {
	    $ov = $item->o_val_string;
	    $pv = $item->p_val_string;
            printf STDERR "opt:%15s => %-10s    par:%15s => %-10s\n",
                $o, $ov, $p, $pv;
	}
    }

    @{$self->{'errors'}};
}

sub get_errors { @{$_[0]->{'errors'}} }

sub build_options {
    my $self = shift;
    my @tmp = ();
    foreach my $o (keys %{$self->{'option'}}) {
        my $item = $self->{'option'}->{$o};
	if (!defined $item->type or $item->type eq '') {
	    push @tmp, $o;
	} else {
	    push @tmp, "$o=s";
	}
    }
    #warn "OPT: @tmp\n";
    @tmp;
}

sub test_type {
    my ($self, $type, $o, $v) = @_;
    return $v  unless defined $type;
    return $v  if $type eq 's' or $type eq '';
    if ($type eq 'i') {
	unless ($v =~ /^$RX_Sint$/) {
	    $self->warn("bad argument '$o=$v', want integer");
	} 
	return $v;
    }
    if ($type eq 'f') {
	unless ($v =~ /^$RX_Sreal$/) {
	    $self->warn("bad argument '$o=$v', want float");
	} 
	return $v;
    }
    if ($type eq '@i') {
	return $self->expand_integer_list($o, $v, 0);
    }
    if ($type eq '@I') {
	return $self->expand_integer_list($o, $v, 1);    #expect sorted
    }
    if ($type eq '@f') {
	return $self->expand_float_list($o, $v, 0);
    }
    if ($type eq '@F') {
	return $self->expand_float_list($o, $v, 1);      #expect sorted
    }
    if ($type eq '@s') {
	return $self->expand_list($o, $v, 0);
    }
    if ($type eq '@S') {
	return $self->expand_list($o, $v, 1);            #expect sorted
    }
    if ($type eq 'b') {
	return $self->expand_toggle($o, $v);
    }
    CORE::die "Bio::Getopt::Group::test_type() unknown type '$type'\n";
}

sub expand_integer_list {
    my ($self, $o, $v, $sortP) = (@_, 0);
    return []    unless defined $v;
    my @tmp = ();
    local $_;
    #warn "expand_integer_list($o, [$v])\n";
    foreach (split /[,\s]+/, $v) {
	next  unless length($_);
	#warn ">>>[$_]";
        #range M\.\.N or M:N
        if (/^($RX_Sint)(?:\.\.|:)($RX_Sint)$/) {
            if ($2 < $1) {
		if ($sortP) {
		    $self->warn("bad integer list range value '$o=$_'");
		    next;
		} else {
		    push @tmp, $2..$1;
		}
            } else {
		push @tmp, $1..$2;
	    }
            next;
        }
        #non-range
        if (/^($RX_Sint)$/ and ! /\.\./ and ! /:/) {
            push @tmp, $1;
            next;
        }
        $self->warn("bad integer list value '$o=$_'");
        return [];
    }
    #warn "expand_integer_list(@tmp)\n";
    return [ sort @tmp ]    if $sortP;
    return [ @tmp ];
}

sub expand_float_list {
    my ($self, $o, $v, $sortP) = (@_, 0);
    return []    unless defined $v;
    my @tmp = ();
    local $_;
    #warn "expand_float_list($o, [$v])\n";
    foreach (split /[,\s]+/, $v) {
	next  unless length($_);
	#warn ">>>[$_]";
        #non-range
        if (/^($RX_Sreal)$/ and ! /\.\./ and ! /:/) {
            push @tmp, $1;
            next;
        }
        $self->warn("bad float list value '$o=$_'");
        return [];
    }
    #warn "expand_float_list(@tmp)\n";
    return [ sort @tmp ]    if $sortP;
    return [ @tmp ];
}

sub expand_list {
    my ($self, $o, $v, $sortP) = (@_, 0);
    return []    unless defined $v;
    my @tmp = ();
    local $_;
    #warn "expand_list($o, [$v])\n";
    foreach (split /[,\s]+/, $v) {
	next  unless length($_);
	#warn ">>>[$_]";
        #integer range M\.\.N or M:N
        if (/^($RX_Sint)(?:\.\.|:)($RX_Sint)$/) {
            if ($2 < $1) {
		if ($sortP) {
		    $self->warn("bad integer list range value '$o=$_'");
		    next;
		} else {
		    push @tmp, $2..$1;
		}
            } else {
		push @tmp, $1..$2;
	    }
            next;
        }
	#non-range: take whole string
	push @tmp, $_;
    }
    #warn "expand_list(@tmp)\n";
    return [ sort @tmp ]    if $sortP;
    return \@tmp;
}

sub expand_toggle {
    my ($self, $o, $v) = @_;
    return 'off'    unless defined $v;
    if ($v ne 'on' and $v ne 'off' and $v ne '0' and $v ne '1') {
	$self->warn("bad value for '$o=$v' want {on,off} or {0,1}");
    }
    return 1    if $v eq 'on' or $v eq '1';
    return 0;
}

sub dump {
    my ($self, $stm) = (@_, \*STDERR);
    print $stm "group: ", $self->{'name'}, "\n";
    foreach my $o (@{$self->{'order'}}) {
        my $item = $self->{'option'}->{$o};        
        $item->dump($stm);
    }
    $self;
}


###########################################################################
package Bio::Getopt::OptionLoader;

use strict;

sub load_options {
    my ($scope, $prog, $stm) = @_;
    my $text = '';
    my @order = ();
    my %group;

    my ($tmp, $group, $name, $option);
    local $_;

    while (<$stm>) {
	chomp;

	next  if /^\s*$/;   #blank
	next  if /^\s*\#/;  #hash comment

	#HEADER
	if (!defined $group and /^\s*header\s*:\s*(.*)/i) {
	    #warn "#header($1)\n";
	    ($text, $_) = scan_quoted_text($prog, $stm, $1);
	    redo;
	}
	
	#GROUP
	if (/^\s*\[\s*([._a-z0-9]+)\s*\]/i) {
	    $name = uc $1;
            #allow groupname to recur
	    if (! exists $group{$name}) {
		$group = new Bio::Getopt::Group($prog, $name, 1);
		$group{$name} = $group;
                #warn "consct: $name, $group\n";
		push @order, $name;
                next;
	    }
            $group = $group{$name};
            #warn "extend: $name, $group\n";
	    next;
	}

	#group.HEADER
	if (/^\s*header\s*:\s*(.*)/i) {
	    #warn "#group.header($1)\n";
	    ($tmp, $_) = scan_quoted_text($prog, $stm, $1);
	    $group->set_text($tmp);
	    redo;
	}
	
	#group.OPTION
	if (/^\s*option\s*:\s*(\S+)/i) {
	    #warn "#group.option($1)\n";
	    $option = strip_quotes($1);
            $group->set_option($option);
	    next;
	}
	
	#group.GENERIC
	if (/^\s*generic\s*:\s*(\S+)/i) {
	    #warn "#group.generic($1)\n";
	    $option = strip_quotes($1);
            $group->set_generic($option);
	    next;
	}
	
	#group.option.TYPE
	if (/^\s*(type)\s*:\s*(\S+)/i) {
	    #warn "#group.option.$1($2)\n";
            $group->set_option_keyval($option, $1, strip_quotes($2));
	    next;
	}
	
	#group.option.DEFAULT
	if (/^\s*(default)\s*:\s*(.*)/i) {
	    #warn "#group.option.$1($2)\n";
	    $group->set_option_keyval($option, $1, strip_quotes($2));
	    next;
	}
	
	#group.option.USAGE
	if (/^\s*(usage)\s*:\s*(.*)/i) {
	    #warn "#group.option.$1($2)\n";
	    ($tmp, $_) = scan_quoted_text($prog, $stm, $2);
	    $group->set_option_keyval($option, $1, $tmp);
	    redo;
	}
	
	#group.option.PARAM
	if (/^\s*(param)\s*:\s*(\S*)/i) {
	    #warn "#group.option.$1($2)\n";
	    $group->set_option_keyval($option, $1, strip_quotes($2));
	    next;
	}
	
	#group.option.CONVERT
	if (/^\s*(convert)\s*:\s*(.*)/i) {
	    #warn "#group.option.$1($2)\n";
	    ($tmp, $_) = scan_subroutine($scope, $prog, $stm, "$name.$option", $2);
	    $group->set_option_keyval($option, $1, $tmp);
	    redo;
	}
	
	#group.option.ACTION
	if (/^\s*(action)\s*:\s*(.*)/i) {
	    #warn "#group.option.$1($2)\n";
	    ($tmp, $_) = scan_subroutine($scope, $prog, $stm, "$name.$option", $2);
	    $group->set_option_keyval($option, $1, $tmp);
	    redo;
	}
	
	CORE::die "Bio::Getopt::Group::load_options() unrecognised line: [$_]";
    }

    ($text, \@order, \%group);
}

sub scan_quoted_text {
    my ($prog, $stm, $line, $text) = (shift, shift, shift, '');
    $line = ''    unless defined $line;
    #warn "($stm, $line, $text)";
    if ($line =~ /([\"\'].*[\"\'])\s*$/) {
	$text = $1;                                     #single line
	$line = <$stm>;
    }
    elsif ($line =~ /([\"\'].*)/) {
	$text = $1;                                     #first line
	while ($line = <$stm>) {
	    last    if $line =~ /^\s*\S+\s*:/;          #next option
	    last    if $line =~ /^\s*\[\s*[._a-z0-9]+\s*\]i/; #next group
	    chomp $line;
	    if ($line =~ /(.*[\"\'])\s*$/) {            #last line
		$text .= $1;
		$line = <$stm>;
		last;
	    }
	    $text .= $line;                             #middle lines
	}
    }
    #warn "TXT: ($text)\n";
    $text =~ s/^[\"\']//;       #strip leading quote
    $text =~ s/[\"\']$//;       #strip trailing quote
    $text =~ s/\\n/\n/g;        #translate newlines
    $text = process_macros($prog, $text, 1);
    #warn "TXT: ($text)\n"; 
    ($text, $line);
}

sub scan_subroutine {
    my ($scope, $prog, $stm, $option, $line) = @_;
    my $tmp = '';
    $line = ''    unless defined $line;
    #warn "($stm, $line, $tmp)";
    if ($line =~ /^\s*(sub.*)/) {
        $tmp = "$1\n";                                  #first line
    }
    while ($line = <$stm>) {    
        last if $line =~ /^\s*(?:header|option|generic|usage|type|default|param|convert|action)\s*:/i;                                  #next option
        last if $line =~ /^\s*\[\s*[._a-z0-9]+\s*\]/i;  #next group
        $tmp .= $line;                                  #middle lines
    }

    #warn "SUB: ($tmp)\n";
    $tmp = process_macros($prog, $tmp, 0);
    #warn "SUB: ($tmp)\n";

    $tmp = eval $tmp;
    CORE::die "Bio::Getopt::Group::load_options() bad subroutine definition '$option':\n$@"    if $@;

    ($tmp, $line);
}

sub strip_quotes {
    my $txt = shift;
    $txt =~ s/^[\"\']//;
    $txt =~ s/[\"\']$//;
    $txt;
}

sub process_macros {
    my ($prog, $text, $string) = @_;

    #PROG macro
    $text =~ s/<PROG>/$prog/g;

    if ($string) {
	#CHOOSE() macro
	if ($text =~ /<CHOOSE>\((.*)\)/) {
	    my ($repl, $sig, @tmp);
	    $sig = $SIG{'__WARN__'};
	    $SIG{'__WARN__'} = sub {};
	    @tmp = eval $1;
	    if ($@) {
		$repl = $1;
	    } else {
		$repl = join(",", @tmp);
	    }
	    $SIG{'__WARN__'} = $sig;
	    $text =~ s/<CHOOSE>\((.*)\)/\{$repl\}/g;
	}
    } else {
	#ARGS macro
	$text =~ s/<ARGS>/my (\$getopt,\$group,\$on,\$ov,\$pn,\$pv)=\@_;/g;

	#GETOPT macro
	$text =~ s/<GETOPT>/\$getopt/g;

	#GROUP macro
	$text =~ s/<GROUP>/\$group/g;

	#OPTION macro
	$text =~ s/<OPTION>/\$getopt->{'option'}->/g;
	
	#PARAM macro
	$text =~ s/<PARAM>/\$getopt->{'param'}->/g;
	
	#DELETE_PARAM macro
	$text =~ s/<DELETE_PARAM>/\$getopt->delete_parameter/g;
	
	#TEST macro
	$text =~ s/<TEST>/\$group->test_type/g;

	#WARN macro
	$text =~ s/<WARN>/\$group->warn/g;

	#USAGE macro
	$text =~ s/<USAGE>/\$getopt->usage/g;
	
	#ONAME macro (option name)
	$text =~ s/<ONAME>/\$on/g;

	#OVAL macro (option value)
	$text =~ s/<OVAL>/\$ov/g;

	#PNAME macro (parameter name)
	$text =~ s/<PNAME>/\$pn/g;

	#PVAL macro (parameter value)
	$text =~ s/<PVAL>/\$pv/g;
    }
    $text;
}


###########################################################################
package Bio::Getopt;

use strict;

sub new {
    my ($type, $prog, $stm) = @_;
    my $self = {};

    $self->{'prog'}   = $prog;
    $self->{'argv'}   = [];
    $self->{'option'} = {};
    $self->{'param'}  = {};
    (
     $self->{'text'},
     $self->{'order'},
     $self->{'group'},
    ) = Bio::Getopt::OptionLoader::load_options((caller)[0], $prog, $stm);

    foreach my $grp (keys %{$self->{'group'}}) {
	$self->{'group'}->{$grp}->init;
    }

    bless $self, $type;
}

sub usage {
    my $self = shift;
    my $s = '';
    $s .= "$self->{'text'}\n"  if defined $self->{'text'};
    my $generic = $self->{'group'}->{$Bio::Getopt::GENERIC_GROUP};
    foreach my $grp (@{$self->{'order'}}) {
        #$self->{'group'}->{$grp}->dump;
	$s .= $self->{'group'}->{$grp}->usage($generic);
    }
    $s;
}

sub parse_options {
    my ($self, $argv, $stm) = (@_, \*STDERR);
    my @tmp = ();
    my $errors = 0;

    #save input ARGV for posterity
    push @{$self->{'argv'}}, @$argv;

    #process options in specified group order
    foreach my $grp (@{$self->{'order'}}) {
        my $item = $self->{'group'}->{$grp}; 
        $errors += $item->get_options($self,
                                      $self->{'option'}, $self->{'param'});
        print $stm $item->get_errors  if $errors;
    }

    #error if any remaining options
    foreach my $arg (@ARGV) {
	if ($arg =~ /^--?\S/) {
	    print $stm "$self->{'prog'}: unknown option '$arg'\n";
	    $errors++;
	} else {
	    push @tmp, $arg;
	}
    }
    CORE::die "$self->{'prog'}: aborting.\n"  if $errors;

    @ARGV = @tmp;
    $self;
}

sub _delete_item {
    my ($self, $label) = (shift, shift);
    foreach my $key (@_) {
	delete $self->{$label}->{$key}  if exists $self->{$label}->{$key};
    }
    $self;
}

sub get_parameters { $_[0]->{'param'} }

sub delete_parameter { my $self = shift; $self->_delete_item('param',  @_); }

sub dump_argv { join(" ", @{$_[0]->{'argv'}}) }


###########################################################################
1;
