# -*- perl -*-
# Copyright (C) 1999-2018 Nigel P. Brown

###########################################################################
# 
# Getopt fields:
#
# [name]     names a group of options; the group [.] is special.
#
# option:    the command line option.
# generic:   refer to an already defined option in group [.].
#
# header:    descriptive string, may span multiple lines.
# usage:     usage string; if undefined, be silent about the option.
# type:      parameter type.
# param:     internal parameter name: if null or empty uses option name.
# convert:   function, return value sets the parameter value.
# action:    function, for side effects only.
# 
###########################################################################
package Bio::Getopt::Class;

use Getopt::Long;
use NPB::Parse::Regexps;
use strict;

my $DEBUG = 0;

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
	foreach my $val (keys %Template) {
	    $self->{'option'}->{$o}->{$val} = $Template{$val}
	        if ! exists $self->{'option'}->{$o}->{$val};
	}
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
    $self->{'option'}->{$option} = { 'name' => $option };
    push @{$self->{'order'}}, $option;
    $self;
}

sub set_generic {
    my ($self, $option) = @_;
    $self->{'option'}->{$option} = { 'generic' => 1 };
    push @{$self->{'order'}}, $option;
    $self;
}

sub set_option_keyval {
    my ($self, $option, $key, $val) = @_;
    #warn "($option, $key, $val)\n";
    $self->{'option'}->{$option}->{$key} = $val;
    $self;
}

sub warn {
    my $self = shift;
    push @{$self->{'errors'}}, "$self->{'prog'}: @_\n";
    $self;
}

sub die {
    my $self = shift;
    CORE::warn $self->errors    if @{$self->{'errors'}};
    CORE::die "$self->{'prog'}: @_\n";
}

sub usage {
    my ($self, $generic) = (shift, shift);
    my @list = ();

    return ''  if $self->{'name'} eq '.';  #silent

    #lookup the option in this class, or in the generic class
    foreach my $o (@{$self->{'order'}}) {
        my $item = $self->{'option'}->{$o};
        $item = $generic->{'option'}->{$o} if exists $item->{'generic'};
        if (defined $item->{'usage'}) {
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
        my ($name, $default, $text, $type);

        $name = $item->{'name'};
	$default = $item->{'default'};

	if (defined $default) {
	    if ($item->{'type'} eq '') {
		$default = ($default ? 'set' : 'unset');
	    } elsif ($default eq '') {
		$default = "''";
	    }
	    $default = "[$default]";
	} else {
	    $default = "[no default]";
	}
	$text = $item->{'usage'};
	$type = '';  #default
	$type = "on|off"    if $item->{'type'} eq 'b';
	$type = "integer"   if $item->{'type'} eq 'i';
	$type = "float"     if $item->{'type'} eq 'f';
	$type = "string"    if $item->{'type'} eq 's';
	$type = "int[,int]" if $item->{'type'} eq '@i';
	$type = "flo[,flo]" if $item->{'type'} eq '@f';
	$type = "str[,str]" if $item->{'type'} eq '@s';
	$type = "int[,int]" if $item->{'type'} eq '@I';
	$type = "flo[,flo]" if $item->{'type'} eq '@F';
	$type = "str[,str]" if $item->{'type'} eq '@S';
	$s .= sprintf("  -%-20s %s %s.\n", "$name $type", $text, $default);
    }
    return "$s\n";
}

sub option_value {
    my $self = shift;
    my ($o, $v) = @_; #warn "($o, $v)\n";
    return "'undef'"  unless defined $v;
    return "''"       if $v eq '';
    return $v;
}

sub param_value {
    my $self = shift;
    my ($o, $v) = @_; #warn "($o, $v)\n";
    return "'undef'"  unless defined $v;
    if (ref $v or $self->{'option'}->{$o}->{'type'} =~ /@/) {
	$v = "[" . join(",", @$v) . "]"  #assume it's a list
    }
    return $v;
}

sub get_options {
    my $self = shift;
    my ($caller, $opt, $par) = @_;
    my (@tmp, $o, $ov, $p, $pv);

    return  if (@tmp = build_options($self->{'option'})) < 1;

    GetOptions($opt, @tmp);

    #map { print STDERR "$_ => $opt->{$_}\n" } %$opt;

OPTION:
    foreach $o (@{$self->{'order'}}) {

        my $item = $self->{'option'}->{$o};

        next  if $item->{'generic'};  #let the [.] group deal with it

        $ov = $item->{'default'};                 #default
        $ov = $opt->{$o}  if defined $opt->{$o};  #command line

	$p = $item->{'param'};                    #explicit name
	$p = $o  unless defined $p;               #use option name
	
	#type tests and simple parameter conversion
	$pv = $self->test_type($item->{'type'}, $o, $ov);

	next OPTION  if @{$self->{'errors'}};

	#convert: special parameter conversion
        if (defined $item->{'convert'} and ref $item->{'convert'} eq 'CODE') {
            $pv = &{$item->{'convert'}}($caller, $self, $o, $ov, $p, $pv);
	}

	next OPTION  if @{$self->{'errors'}};

	#action: perform special action
	if (defined $item->{'action'} and ref $item->{'action'} eq 'CODE') {
	    &{$item->{'action'}}($caller, $self, $o, $ov, $p, $pv);
	}
	
	next OPTION  if @{$self->{'errors'}};

	#overwrite option and parameter values
	$opt->{$o} = $ov; $par->{$p} = $pv;

	if ($DEBUG) {
	    $ov = $self->option_value($o, $ov);
	    $pv = $self->param_value($o, $pv);
            printf STDERR "opt:%15s => %-10s    par:%15s => %-10s\n",
                $o, $ov, $p, $pv;
	}
    }

    @{$self->{'errors'}};
}

sub errors { return @{$_[0]->{'errors'}} }

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
    CORE::die "Bio::Getopt::Class::test_type() unknown type '$type'\n";
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

sub build_options {
    my $opt = shift;
    my @opt = ();
    local $_;
    foreach (keys %$opt) {
	if (!defined $opt->{$_}->{'type'} or $opt->{$_}->{'type'} eq '') {
	    push @opt, $_;
	} else {
	    push @opt, "$_=s";
	}
    }
    #warn "OPT: @opt\n";
    @opt;
}


###########################################################################
package Bio::Getopt::OptionLoader;

use strict;

sub load_options {
    my ($scope, $prog, $stm) = @_;
    my $text = '';
    my @order = ();
    my %class;

    my ($tmp, $class, $name, $option);
    local $_;

    while (<$stm>) {
	chomp;

	next  if /^\s*$/;   #blank
	next  if /^\s*\#/;  #hash comment

	#HEADER
	if (!defined $class and /^\s*header\s*:\s*(.*)/i) {
	    #warn "#header($1)\n";
	    ($text, $_) = _scan_quoted_text($prog, $stm, $1);
	    redo;
	}
	
	#CLASS
	if (/^\s*\[\s*([._a-z0-9]+)\s*\]/i) {
	    $name = uc $1;
            #allow classname to recur
	    if (! exists $class{$name}) {
		$class = new Bio::Getopt::Class($prog, $name, 1);
		$class{$name} = $class;
                #warn "consct: $name, $class\n";
		push @order, $name;
                next;
	    }
            $class = $class{$name};
            #warn "extend: $name, $class\n";
	    next;
	}

	#class.HEADER
	if (/^\s*header\s*:\s*(.*)/i) {
	    #warn "#class.header($1)\n";
	    ($tmp, $_) = _scan_quoted_text($prog, $stm, $1);
	    $class->set_text($tmp);
	    redo;
	}
	
	#class.OPTION
	if (/^\s*option\s*:\s*(\S+)/i) {
	    #warn "#class.option($1)\n";
	    $option = _strip_quotes($1);
            $class->set_option($option);
	    next;
	}
	
	#class.GENERIC
	if (/^\s*generic\s*:\s*(\S+)/i) {
	    #warn "#class.generic($1)\n";
	    $option = _strip_quotes($1);
            $class->set_generic($option);
	    next;
	}
	
	#class.option.TYPE
	if (/^\s*(type)\s*:\s*(\S+)/i) {
	    #warn "#class.option.$1($2)\n";
            $class->set_option_keyval($option, $1, _strip_quotes($2));
	    next;
	}
	
	#class.option.DEFAULT
	if (/^\s*(default)\s*:\s*(.*)/i) {
	    #warn "#class.option.$1($2)\n";
	    $class->set_option_keyval($option, $1, _strip_quotes($2));
	    next;
	}
	
	#class.option.USAGE
	if (/^\s*(usage)\s*:\s*(.*)/i) {
	    #warn "#class.option.$1($2)\n";
	    ($tmp, $_) = _scan_quoted_text($prog, $stm, $2);
	    $class->set_option_keyval($option, $1, $tmp);
	    redo;
	}
	
	#class.option.PARAM
	if (/^\s*(param)\s*:\s*(\S*)/i) {
	    #warn "#class.option.$1($2)\n";
	    $class->set_option_keyval($option, $1, _strip_quotes($2));
	    next;
	}
	
	#class.option.CONVERT
	if (/^\s*(convert)\s*:\s*(.*)/i) {
	    #warn "#class.option.$1($2)\n";
	    ($tmp, $_) = _scan_subroutine($scope, $prog, $stm, "$name.$option", $2);
	    $class->set_option_keyval($option, $1, $tmp);
	    redo;
	}
	
	#class.option.ACTION
	if (/^\s*(action)\s*:\s*(.*)/i) {
	    #warn "#class.option.$1($2)\n";
	    ($tmp, $_) = _scan_subroutine($scope, $prog, $stm, "$name.$option", $2);
	    $class->set_option_keyval($option, $1, $tmp);
	    redo;
	}
	
	CORE::die "Bio::Getopt::Class::load_options() unrecognised line: [$_]";
    }

    ($text, \@order, \%class);
}

sub _scan_quoted_text {
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
	    last    if $line =~ /^\s*\[\s*[._a-z0-9]+\s*\]i/; #next class
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
    $text = _process_macros($prog, $text, 1);
    #warn "TXT: ($text)\n"; 
    ($text, $line);
}

sub _scan_subroutine {
    my ($scope, $prog, $stm, $option, $line) = @_;
    my $tmp = '';
    $line = ''    unless defined $line;
    #warn "($stm, $line, $tmp)";
    if ($line =~ /^\s*(sub.*)/) {
        $tmp = "$1\n";                                  #first line
    }
    while ($line = <$stm>) {    
        last if $line =~ /^\s*(?:header|option|generic|usage|type|default|param|convert|action)\s*:/i;                                  #next option
        last if $line =~ /^\s*\[\s*[._a-z0-9]+\s*\]/i;  #next class
        $tmp .= $line;                                  #middle lines
    }

    #warn "SUB: ($tmp)\n";
    $tmp = _process_macros($prog, $tmp, 0);
    #warn "SUB: ($tmp)\n";

    $tmp = eval $tmp;
    CORE::die "Bio::Getopt::Class::load_options() bad subroutine definition '$option':\n$@"    if $@;

    ($tmp, $line);
}

sub _strip_quotes {
    my $txt = shift;
    $txt =~ s/^[\"\']//;
    $txt =~ s/[\"\']$//;
    $txt;
}

sub _process_macros {
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
	$text =~ s/<ARGS>/my (\$getopt,\$class,\$on,\$ov,\$pn,\$pv)=\@_;/g;

	#GETOPT macro
	$text =~ s/<GETOPT>/\$getopt/g;

	#CLASS macro
	$text =~ s/<CLASS>/\$class/g;

	#OPTION macro
	$text =~ s/<OPTION>/\$getopt->{'option'}->/g;
	
	#PARAM macro
	$text =~ s/<PARAM>/\$getopt->{'param'}->/g;
	
	#DELETE_PARAM macro
	$text =~ s/<DELETE_PARAM>/\$getopt->delete_parameter/g;
	
	#TEST macro
	$text =~ s/<TEST>/\$class->test_type/g;

	#WARN macro
	$text =~ s/<WARN>/\$class->warn/g;

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
     $self->{'class'},
    ) = Bio::Getopt::OptionLoader::load_options((caller)[0], $prog, $stm);

    foreach my $cls (keys %{$self->{'class'}}) {
	$self->{'class'}->{$cls}->init;
    }

    bless $self, $type;
}

sub usage {
    my $self = shift;
    my $s = '';
    $s .= "$self->{'text'}\n"  if defined $self->{'text'};
    foreach my $cls (@{$self->{'order'}}) {
	$s .= $self->{'class'}->{$cls}->usage($self->{'class'}->{'.'});
    }
    $s;
}

sub parse_options {
    my ($self, $argv, $stm) = (@_, \*STDERR);
    my @tmp = ();
    my $error = 0;

    #save input ARGV for posterity
    push @{$self->{'argv'}}, @$argv;

    #process options in specified class order
    foreach my $cls (@{$self->{'order'}}) {
	if ($self->{'class'}->{$cls}->get_options($self, $self->{'option'}, 
                                                  $self->{'param'})) {
	    print $stm $self->{'class'}->{$cls}->errors;
	    $error++;
	}
    }

    #error if any remaining options
    foreach my $arg (@ARGV) {
	if ($arg =~ /^--?\S/) {
	    print $stm "$self->{'prog'}: unknown option '$arg'\n";
	    $error++;
	} else {
	    push @tmp, $arg;
	}
    }
    CORE::die "$self->{'prog'}: aborting.\n"  if $error;

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
