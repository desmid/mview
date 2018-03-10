# Copyright (C) 1997-2018 Nigel P. Brown

###########################################################################
package Bio::MView::Groupmap;

use strict;
use vars qw($Default_PRO_Group $Default_DNA_Group
	    $Group_Any $Default_Group_Any $Group);

$Group                = {};       #static hash of consensus schemes
$Group_Any            = '.';      #key for non-consensus group
$Default_Group_Any    = '.';      #default symbol for non-consensus group
$Default_PRO_Group    = 'P1';     #default consensus scheme name, protein
$Default_DNA_Group    = 'D1';     #default consensus scheme name, dna

load_groupmaps(\*DATA);

sub list_groupmap_names { return join(",", sort keys %$Group) }

sub check_groupmap {
    if (exists $Group->{uc $_[0]}) {
        return uc $_[0];
    }
    return undef;
}

sub get_default_groupmap {
    if (! defined $_[0] or $_[0] eq 'aa') {  #default to protein
	return $Default_PRO_Group;
    }
    return $Default_DNA_Group;
}

sub load_groupmaps {
    my ($stream, $override) = (@_, 1);
    my ($state, $map, $class, $sym, $members, $c, $de, $mapignore) = (0, {}, undef);
    local $_;
    while (<$stream>) {

	#comments, blank lines
	if (/^\s*\#/ or /^\s*$/) {
	    next  if $state != 1;
	    $de .= $_;
	    next;
	}

	#group [name]
	if (/^\s*\[\s*(\S+)\s*\]/) {
	    $map = uc $1;
	    if (exists $Group->{$map} and !$override) {
		$mapignore = 1;  #just for duration of this map
	    } else {
		$mapignore = 0;
	    }
	    $state = 1;
	    $de = '';
	    next;
	}

	die "Bio::MView::Groupmap::load_groupmaps() groupname undefined\n"
	    unless defined $map;

	next  if $mapignore;    #forget it if we're not allowing overrides

	#save map description?
	$Group->{$map}->[3] = $de  if $state == 1;

	#Group_Any symbol (literal in regexp)
	if (/^\s*\.\s*=>\s*(\S+|\'[^\']+\')/) {
	    $state = 2;
	    $sym     = $1;
	    $sym     =~ s/^\'//;
	    $sym     =~ s/\'$//;
	    chomp; die "Bio::MView::Groupmap::load_groupmaps() bad format in line '$_'\n"    if length $sym > 1;
	    make_group($map, $Group_Any, $sym, []);
            next;
	}

	#general class membership
	if (/^\s*(\S+)\s*=>\s*(\S+|\'[^\']+\')\s*\{\s*(.*)\s*\}/) {
	    $state = 2;
	    ($class, $sym, $members) = ($1, $2, $3);
	    $sym     =~ s/^\'//;
	    $sym     =~ s/\'$//;
	    chomp; die "Bio::MView::Groupmap::load_groupmaps() bad format in line '$_'\n"    if length $sym > 1;
	    $members =~ s/[\s,]//g;
	    $members =~ s/''/ /g;
	    $members = uc $members;
	    $members = [ split(//, $members) ];
	    make_group($map, $class, $sym, $members);
	    next;
	}

	#trivial class self-membership: different symbol
	if (/^\s*(\S+)\s*=>\s*(\S+|\'[^\']+\')/) {
	    $state = 2;
	    ($class, $sym, $members) = ($1, $2, $1);
	    chomp; die "Bio::MView::Groupmap::load_groupmaps() bad format in line '$_'\n"    if length $sym > 1;
	    $members = uc $members;
	    $members = [ split(//, $members) ];
	    make_group($map, $class, $sym, $members);
	    next;
	}

	#trivial class self-membership: same symbol
	if (/^\s*(\S+)/) {
	    $state = 2;
	    ($class, $sym, $members) = ($1, $1, $1);
	    $members = uc $members;
	    $members = [ split(//, $members) ];
	    make_group($map, $class, $sym, $members);
	    next;
	}

	#default
	chomp; die "Bio::MView::Groupmap::load_groupmaps() bad format in line '$_'\n";
    }
    close $stream;

    foreach $map (keys %$Group) {
	make_group($map, $Group_Any, $Default_Group_Any, [])
	    unless exists $Group->{$map}->[0]->{$Group_Any};
	make_group($map, '', $Bio::MView::Sequence::Mark_Spc,
		   [
		    $Bio::MView::Sequence::Mark_Pad,
		    $Bio::MView::Sequence::Mark_Gap,
		   ]);
    }
}

sub make_group {
    my ($group, $class, $sym, $members) = @_;
    local $_;

    #class => symbol
    $Group->{$group}->[0]->{$class}->[0] = $sym;

    foreach (@$members) {
        next  unless defined $_;
	#class  => member existence
	$Group->{$group}->[0]->{$class}->[1]->{$_} = 1;
	#member => symbol existence
	$Group->{$group}->[1]->{$_}->{$sym} = 1;
	#symbol => members
	$Group->{$group}->[2]->{$sym}->{$_} = 1;
    }
}

sub dump_group {
    my ($group, $class, $mem, $p);
    push @_, keys %$Group    unless @_;
    warn "Groups by class\n";
    foreach $group (@_) {
	warn "[$group]\n";
	$p = $Group->{$group}->[0];
	foreach $class (keys %{$p}) {
	    warn "$class  =>  $p->{$class}->[0]  { ",
		join(" ", keys %{$p->{$class}->[1]}), " }\n";
	}
    }
    warn "Groups by membership\n";
    foreach $group (@_) {
	warn "[$group]\n";
	$p = $Group->{$group}->[1];
	foreach $mem (keys %{$p}) {
	    warn "$mem  =>  { ", join(" ", keys %{$p->{$mem}}), " }\n";
	}
    }
}

#return a descriptive listing of supplied groups or all groups
sub dump_groupmaps {
    my $html = shift;
    my ($group, $class, $p, $sym);
    my ($s, $c0, $c1, $c2) = ('', '', '', '');

    ($c0, $c1, $c2) = (
	"<SPAN style=\"color:$Bio::MView::Colormap::Colour_Black\">",
	"<SPAN style=\"color:$Bio::MView::Colormap::Colour_Comment\">",
	"</SPAN>")  if $html;

    $s .= "$c1#Consensus group listing - suitable for reloading.\n";
    $s .= "#Character matching is case-insensitive.\n";
    $s .= "#Non-consensus positions default to '$Default_Group_Any' symbol.\n";
    $s .= "#Sequence gaps are shown as ' ' (space) symbols.$c2\n\n";

    @_ = keys %$Group  unless @_;

    foreach $group (sort @_) {
	$s .= "$c0\[$group]$c2\n";
	$s .= "$c1$Group->{$group}->[3]";
        $s .= "#description =>  symbol  members$c2\n";

	$p = $Group->{$group}->[0];
	foreach $class (sort keys %{$p}) {

	    next    if $class eq '';    #gap character

	    #wildcard
	    if ($class eq $Group_Any) {
		$sym = $p->{$class}->[0];
		$sym = "'$sym'"    if $sym =~ /\s/;
		$s .= sprintf "%-12s =>  %-6s\n", $class, $sym;
		next;
	    }

	    #consensus symbol
	    $sym = $p->{$class}->[0];
	    $sym = "'$sym'"    if $sym =~ /\s/;
	    $s .= sprintf "%-12s =>  %-6s  { ", $class, $sym;
	    $s .= join(", ", sort keys %{$p->{$class}->[1]}) . " }\n";
	}
	$s .= "\n";
    }
    $s;
}

######################################################################
1;

__DATA__
#label       =>  symbol  { member list }

[P1]
#Protein consensus: conserved physicochemical classes, derived from
#the Venn diagrams of: Taylor W. R. (1986). The classification of amino acid
#conservation. J. Theor. Biol. 119:205-218.
.            =>  .
G            =>  G       { G }
A            =>  A       { A }
I            =>  I       { I }
V            =>  V       { V }
L            =>  L       { L }
M            =>  M       { M }
F            =>  F       { F }
Y            =>  Y       { Y }
W            =>  W       { W }
H            =>  H       { H }
C            =>  C       { C }
P            =>  P       { P }
K            =>  K       { K }
R            =>  R       { R }
D            =>  D       { D }
E            =>  E       { E }
Q            =>  Q       { Q }
N            =>  N       { N }
S            =>  S       { S }
T            =>  T       { T }
aromatic     =>  a       { F, Y, W, H }
aliphatic    =>  l       { I, V, L }
hydrophobic  =>  h       { I, V, L,   F, Y, W, H,   A, G, M, C, K, R, T }
positive     =>  +       { H, K, R }
negative     =>  -       { D, E }
charged      =>  c       { H, K, R,   D, E }
polar        =>  p       { H, K, R,   D, E,   Q, N, S, T, C }
alcohol      =>  o       { S, T }
tiny         =>  u       { G, A, S }
small        =>  s       { G, A, S,   V, T, D, N, P, C }
turnlike     =>  t       { G, A, S,   H, K, R, D, E, Q, N, T, C }
stop         =>  *       { * }

[D1]
#DNA consensus: conserved ring types
#Ambiguous base R is purine: A or G
#Ambiguous base Y is pyrimidine: C or T or U
.            =>  .
A            =>  A       { A }
C            =>  C       { C }
G            =>  G       { G }
T            =>  T       { T }
U            =>  U       { U }
purine       =>  r       { A, G,  R }
pyrimidine   =>  y       { C, T, U,  Y }

[CYS]
#Protein consensus: conserved cysteines
.            =>  .
C            =>  C       { C }

###########################################################################
