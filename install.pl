#!/usr/bin/env perl

# Copyright (C) 2019 Nigel P. Brown

# This file is part of MView.
# MView is released under license GPLv2, or any later version.

###########################################################################
# the application to be installed
my $TARGET_NAME = "MView";
my $TARGET_ENV  = "MVIEW_HOME";
my $TARGET_EXE  = "bin/mview";
my $DRIVER      = "mview";
###########################################################################

require 5.004;

use Cwd qw(getcwd);
use File::Copy qw(copy);
use File::Path qw(mkpath);
use FileHandle;
use POSIX qw(strftime);

use strict;
use warnings;

my $INSTALLDIR = getcwd();
my @SAVEPATH = ();
my $BINDIR = "";
my $SYSTEM = "";
my $PATHENVSEP = ':';
my $PATHSEP = '/';
my $ADMIN = 0;
my $VERSION = "1.0";

umask 0022;

sub abort {
    unlink "$DRIVER";
    die "\nAborted.\n";
}

# trap 1 2 3 15
$SIG{'HUP'}  = \&abort;
$SIG{'INT'}  = \&abort;
$SIG{'QUIT'} = \&abort;
$SIG{'TERM'} = \&abort;

my $test_if_admin;
my $expand_path;
my $guess_bindir;
my $make_driver;

sub show_admin_warning {
    print STDERR <<EOT;
###########################################################################

                     $TARGET_NAME installer

  *********************************************************
  **                                                     **
  **  WARNING: You have administrator/root permissions!  **
  **                                                     **
  *********************************************************

EOT
}

sub show_preamble {
    print STDERR <<EOT;
###########################################################################

                         $TARGET_NAME installer

The installation requires a folder to contain the driver script.

That folder must be (1) writable by the installer and (2) on your PATH if
installing a personal copy, or on the shared PATH for site installations.

You can accept the suggested default, choose a folder from the following
PATH list, or specify another folder that you will add to PATH later:

EOT
}

sub show_summary {
    my $driver_path = join($PATHSEP, ($BINDIR, $DRIVER));
    my $short_name = $DRIVER; $short_name =~ s/\.bat$//i  if is_dos();
    my $long_name = join($PATHSEP, ($BINDIR, $short_name));

    print STDERR <<EOT;

###########################################################################

Installation details:

Installed under:  $INSTALLDIR
PATH entry:       $BINDIR           (add to PATH if missing)
Program:          $driver_path

Installation complete.

Try running the program with:

  $short_name -help

If PATH is not set properly this should work:

  $long_name -help

###########################################################################
EOT
}

sub info    { print STDERR "@_\n"; }
sub warning { print STDERR " + @_\n"; }
sub error   { print STDERR "ERROR: @_\n"; exit 1; }
sub prompt  { print STDERR "\n>> @_ "; }

sub pause {
    prompt "Press the 'return' or 'enter' key to continue (Ctrl-C to abort).";
    <STDIN>;
    info;
}

sub pause_before_exit {
    if (is_dos()) {
        prompt "Press the 'return' or 'enter' key to finish.";
        <STDIN>;
    }
}

sub set_base_system {
    if (grep {/$^O/i} qw(aix android bsdos beos bitrig dgux
        dynixptx cygwin darwin dragonfly freebsd gnukfreebsd haiku hpux interix
        irix linux machten midnightbsd minix mirbsd netbsd next nto openbsd qnx
        sco solaris)) {
        $SYSTEM        = "UNIX";
        $PATHENVSEP    = ':';
        $PATHSEP       = '/';
        $test_if_admin = \&test_if_unix_admin;
        $expand_path   = \&expand_unix_path;
        $guess_bindir  = \&guess_unix_bindir;
        $make_driver   = \&make_unix_driver;
        return $SYSTEM;
    }
    if (grep {/$^O/i} qw(dos MSWin32)) {
        $SYSTEM        = "DOS";
        $PATHENVSEP    = ';';
        $PATHSEP       = '\\';
        $test_if_admin = \&test_if_dos_admin;
        $expand_path   = \&expand_dos_path;
        $guess_bindir  = \&guess_dos_bindir;
        $make_driver   = \&make_dos_driver;
        #change from defaults
        $INSTALLDIR    = join($PATHSEP, split('/', $INSTALLDIR));
        $TARGET_EXE    = join($PATHSEP, split('/', $TARGET_EXE));
        $DRIVER .= ".bat";
        return $SYSTEM;
    }
    error "I do not recognise the operating system '$^O' - stopping";
}

sub is_unix { return $SYSTEM eq "UNIX"; }
sub is_dos  { return $SYSTEM eq "DOS"; }

# make_dir dirpath
sub make_dir {
    my ($dir) = @_;
    warning "Making directory '$dir'";
    return mkpath($dir);
}

# make_symlink target linknamea
sub make_symlink () {
    my ($target, $link) = @_;
    warning "Making symlink from '$link' to '$target'";
    return symlink($target, $link);
}

# make_copy source destination
sub make_copy {
    my ($source, $destination) = @_;
    warning "Making copy from '$source' to '$destination'";
    return copy($source, $destination);
}

# remove_file filepath
sub remove_file {
    my ($file) = @_;
    warning "Deleting '$file'";
    if (!( -f $file or -l $file )) {
        warning "Name '$file' is not a file or symlink";
        return 1;
    }
    return unlink($file);
}

sub list_dirs {
    foreach my $p (@_) {
        info "  $p";
    }
}

sub choose_bindir {
    my $dir;

    while (1) {
        prompt "Choose a directory for the program [$BINDIR]";
        my $raw = <STDIN>;
        chomp $raw;
        $dir = &$expand_path($raw);
        info;

        if ( $dir eq "" and $BINDIR ne "") {
            # accept default BINDIR
            $dir = $BINDIR;
            last;
        }
        if ( $dir eq "" ) {
            warning "Directory must have a name";
            next;
        }
        if ( $dir eq $DRIVER ) {
            warning "That name is reserved - please use another one";
            next;
        }
        if ( -e $dir and  ! -d $dir ) {
            warning "Name '$raw' is not a directory";
            next;
        }
        if ( -e $dir and ! -w $dir ) {
            warning "Directory '$raw' exists but is not writable";
            next;
        }
        if ( ! -e $dir ) {
            # accept input choice - dir will be created by user
            last;
        }
        # input choice accepted - dir already exists
        last;
    }

    $BINDIR = $dir;

    if (! -e $BINDIR) {
        info "  ********************************************************";
        info "  ** Note: That folder does not exist yet.              **";
        info "  ** Don't forget to add it manually to PATH.           **";
        info "  **                                                    **";
        info "  ** For another choice press Ctrl-C, then start again. **";
        info "  *********************************************************";
    }
}

sub make_bindir {
    my $dir = shift;
    if ( ! -e $dir ) {
        if (make_dir($dir) < 1) {
            warning "Can't make directory '$dir'";
            return;
        }
        warning "Created directory '$dir'";
    }
}

sub get_timestamp {
    # Mon Sep 30 17:31:18 CEST 2019
    strftime "%a %b %d %H:%M:%S %Z %Y", localtime;
}

# make_copy filename destdir mode
sub install_driver {
    my ($file, $destination, $mode) = @_;

    return  if $destination eq ".";

    my $source = "$file";
    my $target = join($PATHSEP, ($destination, $file));

    if ( -e $target ) {
        warning "Replacing existing '$target'";
        if (remove_file($target) < 1) {
            error "Attempt to delete old '$target' failed";
        }
    }
    if (make_copy($source, $target) < 1) {
        error "Attempt to copy '$source' into '$target' failed";
    }
    if (is_unix()) {
        if (chmod($mode, $target) < 1) {
            error "Attempt to set execute permissions on '$target' failed";
        }
    }
}

###########################################################################
# UNIX-like system

sub test_if_unix_admin {
    my $user;
    if ($ENV{'USER'} eq "root") {
        $user = 0;
    }
    elsif ( -e "/usr/bin/id" ) {
        $user = `/usr/bin/id -u`;
    }
    elsif ( -e "/bin/id" ) {
        $user = `/bin/id -u`;
    }
    else {
        $user = `id -u`;
    }
    return $user == 0;
}

sub expand_unix_path {
    my $path = shift;
    $path =~ s{
                ^~([^/]*)
              }
              {
                $1 ? (getpwnam($1))[7] : (
                  $ENV{HOME} || $ENV{LOGDIR} || (getpwuid($<))[7]
                )
              }ex;
    return $path;
}

sub guess_unix_bindir {
    return  if $BINDIR ne "";  # already set/guessed

    @SAVEPATH = get_writable_unix_paths();

    if ($ADMIN) {
        guess_unix_admin_bindir(@SAVEPATH);
    } else {
        guess_unix_user_bindir(@SAVEPATH);
    }
}

sub get_writable_unix_paths {
    my $paths = $ENV{'PATH'};
    my (%seen, @list) = ();
    foreach my $p (split($PATHENVSEP, $paths)) {
        $p = expand_unix_path($p);
        next  unless -w $p;  # writable
        push @list, $p  unless exists $seen{$p};
        $seen{$p} = 1;
    }
    return @list;
}

sub guess_unix_admin_bindir {
    # prefer these paths in this order
    if (my @tmp = grep {/\/usr\/local\/bin$/} @_) {
        $BINDIR = $tmp[0];
        return;
    }
    if (my @tmp = grep {/\/opt\/bin$/} @_) {
        $BINDIR = $tmp[0];
        return;
    }
    $BINDIR = "/usr/local/bin";  # force default
}

sub guess_unix_user_bindir {
    # prefer these paths in this order
    if (my @tmp = grep {/$ENV{'HOME'}\/bin$/} @_) {
        $BINDIR = $tmp[0];
        return;
    }
    $BINDIR = "$ENV{'HOME'}/bin";  # force default
}

sub make_unix_driver {
    my $file = shift;
    my $date = get_timestamp();
    my $fh = new FileHandle();
    open($fh, ">", $file);
    print $fh <<EOT;
#!/bin/sh
# $TARGET_NAME driver
# Version: $VERSION
# Generated: $date

$TARGET_ENV=$INSTALLDIR; export $TARGET_ENV
PROGRAM=\$$TARGET_ENV/$TARGET_EXE
PROG=\`basename \$0\`

# echo $TARGET_ENV=\$$TARGET_ENV  1>&2
# echo PROGRAM=\$PROGRAM  1>&2

if [ ! -f \$PROGRAM ]; then
    echo "\$PROG: Can't find program '\$PROGRAM'"
    exit 1
fi
if [ ! -x \$PROGRAM ]; then
    echo "\$PROG: Program '\$PROGRAM' is not executable"
    exit 1
fi

exec \$PROGRAM "\$@"
EOT
    $fh->close;
}

###########################################################################
# DOS system

sub test_if_dos_admin {
    return 1  if system("NET SESSION >NUL 2>&1");
    return 0;
}

sub expand_dos_path {
    return $_[0];
}

sub guess_dos_bindir {
    return  if $BINDIR ne "";  # already set/guessed

    @SAVEPATH = get_writable_dos_paths();

    if ($ADMIN) {
        guess_dos_admin_bindir(@SAVEPATH);
    } else {
        guess_dos_user_bindir(@SAVEPATH);
    }
}

sub get_writable_dos_paths {
    my $paths = $ENV{'PATH'};
    my (%seen, @list) = ();
    foreach my $p (split($PATHENVSEP, $paths)) {
        next  unless -w $p;  # writable
        push @list, $p  unless exists $seen{uc $p}; # case insensitive
        $seen{uc $p} = 1;
    }
    return @list;
}

sub guess_dos_admin_bindir {
    # prefer these paths in this order
    if (my @tmp = grep {/\\perl\\site\\bin$/i} @_) {
        $BINDIR = $tmp[0];
        return;
    }
    if (my @tmp = grep {/\\perl\\bin$/i} @_) {
        $BINDIR = $tmp[0];
        return;
    }
    if (my @tmp = grep {/C:\\bin$/i} @_) {
        $BINDIR = $tmp[0];
        return;
    }
    $BINDIR = "C:\\bin";  # force default
}

sub guess_dos_user_bindir {
    # prefer these paths in this order
    if (my @tmp = grep {/$ENV{'UserProfile'}\\bin$/i} @_) {
        $BINDIR = $tmp[0];
        return;
    }
    $BINDIR = "$ENV{'UserProfile'}\\bin"  # force default
}

sub make_dos_driver {
    my $file = shift;
    my $date = get_timestamp();
    my $fh = new FileHandle();
    open($fh, ">", $file);
    print $fh <<EOT;
\@echo off
rem $TARGET_NAME driver
rem Version: $VERSION
rem Generated: $date

set $TARGET_ENV=$INSTALLDIR
set PROGRAM=%$TARGET_ENV%\\$TARGET_EXE
set PROG=%~nx0

rem echo "$TARGET_ENV=%$TARGET_ENV%"  1>&2
rem echo "PROGRAM=%PROGRAM%"  1>&2

if not exist "%PROGRAM%" (
    echo "%PROG%: Can't find program '%PROGRAM%'"
    exit /b 1
)

perl "%PROGRAM%" %*
EOT
    $fh->close;
}

###########################################################################
set_base_system();

if ( ! -f $TARGET_EXE ) {
    error "You must change into the unpacked directory first!";
}

unlink $DRIVER;  # any previous attempt

if ($ADMIN = &$test_if_admin()) {
    show_admin_warning();
    pause();
}

if (@ARGV) {
    # destination directory on command line
    $BINDIR = shift;
    info;
    info "Installing driver script into '$BINDIR'";
    info;
}
else {
    # interactive choice
    show_preamble();
    &$guess_bindir();
    list_dirs(@SAVEPATH);
    info;
    info "The suggested default is [$BINDIR]";
    info;
    info "At any time, you may type ^C (ctrl-C) to abort.";
    choose_bindir();
    info;
    info "About to install driver script into '$BINDIR'";
    pause()  if @ARGV < 1;
}

make_bindir($BINDIR);
&$make_driver($DRIVER);
install_driver($DRIVER, $BINDIR, 0755);
unlink $DRIVER;

show_summary();
pause_before_exit();

exit 0;
