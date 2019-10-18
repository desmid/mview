### Introduction

**MView** is a command line utility that extracts and reformats the results of
a sequence database search or a multiple alignment, optionally adding HTML
markup for web page layout. It can also be used as a filter to extract and
convert searches or alignments to common formats.

Inputs:

- Sequence database search: BLAST, FASTA suites.
- Multiple sequence alignment: CLUSTAL, HSSP, MSF, FASTA, PIR, MAF.

Outputs:

- HTML, FASTA, CLUSTAL, MSF, PIR, RDB (tab-separated).

The tool is used in molecular biology and biomedical research for data
analyses and as a component in various bioinformatics web services. Research
papers citing MView are indexed on [Google
Scholar](https://scholar.google.com/citations?user=4ughzM0AAAAJ&hl=en "MView
citations").


### Manual

Full documentation can be found in the
[manual](https://desmid.github.io/mview/ "MView manual"), a copy of which is
bundled with the code.


### Requirements

MView is implemented in Perl, version 5 as a self-contained command line
program that should run cross-platform.

[Perl](https://www.perl.org/) is generally installed on Linux and UNIX
systems. MView is known to work on Windows with
[Strawberry Perl](http://strawberryperl.com/).


### Download

- The [current release](
  https://sourceforge.net/projects/bio-mview/files/bio-mview/mview-1.66/
  "MView current release on SourceForge") can be downloaded from SourceForge
  as a gzip or bzip2 compressed tar archive.
- Older [releases](
  https://sourceforge.net/projects/bio-mview/files/bio-mview/ "MView older
  releases on SourceForge") and historical [download statistics](
  https://sourceforge.net/projects/bio-mview/files/stats/timeline?dates=2005-01-01+to+2025-01-01
  "MView download statistics") can also be found on SourceForge.
- The [latest code](https://github.com/desmid/mview "MView source") can be
  downloaded direct from GitHub by clicking the green "Clone or download"
  button and following the instructions to either clone the git repository or
  download a ZIP archive.


### Installation

There are several ways to install MView, with further details given below.

Each method can be used by an ordinary user installing into their own account,
or by a system administrator installing onto a computer with multiple
users. It is assumed that Perl is already installed and on your `PATH`.

* Installer script

  The installer program should work on all systems, but is new and relatively
  experimental.

  You unpack the archive into a destination folder and run the installer from
  there, following the instructions. You may have to edit `PATH` afterwards.
  
  Explanation: the installer puts a small mview driver program into a folder
  on `PATH` so that it can be run easily by the user. The driver knows the
  location of the unpacked MView folder and starts the real MView program.

* Manual install

  This works on all systems and is the most basic, but requires that you do a
  little editing.

  You unpack the archive into a destination folder, edit the MView program by
  hand, then add the folder containing that program to `PATH`.

* Perl module

  This method assumes that, as well as Perl, you have some version of `make`
  installed, so may not work on all systems.
  
  You unpack the archive into a temporary folder and run the standard Perl
  module installation incantation. Unlike the other installation methods you
  can then delete the installation folder because all the code has been copied
  into Perl somewhere.
  
  Installing a perl Module has the advantage that there is (usually) no need
  to change `PATH`, but the disadvantage that it installs directly into your
  Perl installation (or personal perl folder known to Perl), which you may not
  want to do.

#### Linux, macOS, UNIX

##### Installer script

1. Save the archive to somewhere under your home folder then uncompress
   and extract it:

        tar xvzf mview-1.66.2.tar.gz

   This creates a sub-folder `mview-1.66.2` containing all the files.
   
2. Change to this folder.

3. Run the command:

        perl install.pl
        
   and follow the instructions. You will be offered various places to install
   the driver script.
   
   If you know in advance the name of the folder you want to use for the
   driver script, you can supply it on the command line:

        perl install.pl /folder/on/my/path

4. If the installer couldn't find a sensible place to install the script, it
   chooses `~/bin` and you will have to add that to your `PATH`, then rehash
   or login again.

##### Manual install

1. Save the archive to your software area, for example, `/usr/local`, then
   uncompress and extract it:

        tar xvzf mview-1.66.2.tar.gz

   This creates a sub-folder `mview-1.66.2` containing all the files.

2. Change to this folder.

3. Edit the file `bin/mview`.

   Set a valid path for the Perl interpreter on your machine after the `#!`
   at the top of the file, for example:

        #!/usr/bin/perl

   Find the line:
 
        $MVIEW_HOME = "/path/to/mview/unpacked/folder";
       
   and change the path, in our example, to:

        $MVIEW_HOME = "/usr/local/mview-1.66.2";

   Save the file.

4. Finally, make sure that the `bin` folder containing the `mview` script
   (that you just edited) is on the user `PATH`, and rehash or login again.

   In our example, you would add `/usr/local/mview-1.66.2/bin` to the
   existing value of `PATH`, or replace any older MView path.


#### Windows

##### Installer script

1. Save the archive to somewhere under your home folder then uncompress and
   extract it (using an archiver like 7-Zip, as here):

        7z x mview-1.66.2.zip

   This creates a sub-folder `mview-1.66.2` containing all the files.
   
2. Change to this folder.

3. Run the command:

        perl install.pl
        
   and follow the instructions. You will be offered various places to install
   the driver script.
   
   If you know in advance the name of the folder you want to use for the
   driver script, you can supply it on the command line:

        perl install.pl \folder\on\my\path

3. If the installer couldn't find a sensible place to install the driver, it
   chooses `C:\bin` and you will have to add that to your `PATH`, then start
   a new command prompt.


##### Manual install

1. Save the archive to your software area, for example, `C:\Program Files`,
   then uncompress and extract it (using an archiver like 7-Zip, as here):

        7z x mview-1.66.2.zip

   This creates a sub-folder `mview-1.66.2` containing all the files.

2. Change to this folder.

3. Edit the file `bin\mview`.

   Find the line:
   
        $MVIEW_HOME = "/path/to/mview/unpacked/folder";
        
   and change the path, in our example, to:

        $MVIEW_HOME = "C:\Program Files\mview-1.66.2";

   Save the file.

4. Finally, make sure that the `bin` folder containing the mview script (that
   you just edited) is on the user `PATH`, then start a new command prompt.
   
   In our example, you would append `C:\Program Files\mview-1.66.2\bin` to the
   existing value of `PATH`, or replace any older MView path.


#### Perl module

1. Save the archive then uncompress and extract it (Linux, macOS, UNIX):

        tar xvzf mview-1.66.2.tar.gz

   or (Windows, using an archiver like 7-Zip, as here):
   
        7z x mview-1.66.2.zip
        
   This creates a sub-folder called `mview-1.66.2` containing all the files.
   
2. Change to this folder.

You can now use one of the following sets of instructions to do the install:

3. Run:

        perl Makefile.PL
        make install
        
   which attempts to install into the Perl distribution.

3. Or run:

        perl Makefile.PL INSTALL_BASE=/usr/local
        make install

    which attempts to install under the given folder. In this UNIX example you
    need write access to `/usr/local` and users will need `/usr/local/bin` on
    their `PATH`.
   
3. Or, if you have a [local::lib](https://metacpan.org/pod/local::lib) setup,
   you can install mview there:

        perl Makefile.PL $PERL_MM_OPT
        make install

4. Finally, the unpacked archive can be deleted since the important components
   have been copied elsewhere.


### Testing

Each release of MView is regression tested against hundreds of sample data
inputs for all the sequence database search and alignment formats and versions
thereof that are supported, together with known edge cases. This is well over
0.5GB of material, so it's not currently available externally.


### Found a bug?

Please open an issue on the MView [issue tracker](https://github.com/desmid/mview/issues "issue tracker") or send an email to `biomview@gmail.com`.

If MView isn't able to parse your input file or produces a warning message, it
would be very helpful if you can include/attach the data file in your message
so that I can (1) quickly reproduce the error, and (2) add the example to the
test suite.


### Citation

If you use MView in your work, please cite:

> Brown, N.P., Leroy C., Sander C. (1998). MView: A Web compatible database
> search or multiple alignment viewer. *Bioinformatics*. **14** (4):380-381.
> [[PubMed](http://www.ncbi.nlm.nih.gov/pubmed/9632837 "PubMed link")]


### Copyright and licence

MView is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.


### Acknowledgements

People who contributed early code or suggestions include C. Leroy and other
members of the former Sander group at EBI. Useful suggestions relating to the
EBI sequence database search services have come from R. Lopez, W. Li and
H. McWilliam at EBI. Thanks to the many other people who have suggested new
features and reported bugs. Finally, thank you to everyone who has cited MView
in their publications.
