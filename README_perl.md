### Installation - Perl module

This method assumes that you have Perl and some version of `make` installed,
so may not work on all systems.

Installing a perl Module has the advantage that there is (usually) no need to
change `PATH`, but the disadvantage that it installs directly into your Perl
installation (or personal perl folder known to Perl), which you may not want
to do.

You unpack the archive into a temporary folder and run the standard Perl
module installation incantation. Unlike the other installation methods you can
then delete the installation folder because all the code has been copied into
Perl somewhere.

1. Save the archive then uncompress and extract it (Linux, Apple, UNIX):

        tar xvzf mview-VERSION.tar.gz

   or (Windows, using an archiver like 7-Zip, as here):

        7z x mview-VERSION.zip

   This creates a sub-folder called `mview-VERSION` containing all the files.

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
   you can install MView there:

        perl Makefile.PL $PERL_MM_OPT
        make install

4. Finally, the unpacked archive can be deleted since the important components
   have been copied elsewhere.

---

Return to main [README](README.md).
