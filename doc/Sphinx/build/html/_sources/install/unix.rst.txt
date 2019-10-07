Install: Linux, Apple, UNIX
===========================

There are different approaches depending on whether you are installing for
your own use or as a site administrator for multiple users.

Personal use
^^^^^^^^^^^^

1. Save the archive to somewhere under your home folder then uncompress
   and extract it::

        tar xvzf mview-1.66.1.tar.gz

   This creates a sub-folder called ``mview-1.66.1`` containing all the files.
   
2. Change to this folder.

3. Run the command::

        perl install.pl
        
   and follow the instructions. The installer creates a driver script pointing
   to wherever you just unpacked MView. It offers you various places to
   install this driver so that it is on your ``PATH``.
   
4. If the installer couldn't find a sensible place to install the driver, it
   chooses ``~/bin`` and you will have to add that to your ``PATH``, then
   rehash or login again.

Site administrator for multiple users
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

You can use the ``install.pl`` script as above, or install manually:

1. Save the archive to your software area, for example, ``/usr/local``, then
   uncompress and extract it::

        tar xvzf mview-1.66.1.tar.gz

   This creates a sub-folder called ``mview-1.66.1`` containing all the files.

2. Change to this folder.

3. Edit the file ``bin/mview``.

  * Set a valid path for the Perl interpreter on your machine after the ``#!``
    at the top of the file, for example::

        #!/usr/bin/perl

  * Find the line::

        $MVIEW_HOME = "/path/to/mview/unpacked/folder";

    and change the path, in our example, to::

        $MVIEW_HOME = "/usr/local/mview-1.66.1";

  * Save the file.

4. Finally, make sure that the ``bin`` folder containing the ``mview`` script
   (that you just edited) is on the user ``PATH``, then rehash or login again.

   In our example, you would add ``/usr/local/mview-1.66.1/bin`` to the
   existing value of ``PATH``, or replace any older MView path.


As a Perl package
^^^^^^^^^^^^^^^^^

MView can be installed as a Perl package.

1. Save the archive to somewhere under your home folder then uncompress
   and extract it::

        tar xvzf mview-1.66.1.tar.gz

   This creates a sub-folder called ``mview-1.66.1`` containing all the files.
   
2. Change to this folder.

You can now use one of the following sets of instructions to do the install:

3. Run::

        perl Makefile.PL
        make install
        
   which attempts to install into the Perl distribution.

3. Or run::

        perl Makefile.PL INSTALL_BASE=/usr/local
        make install

   which attempts to install under the given folder. In this example you need
   write access to ``/usr/local`` and users will need ``/usr/local/bin`` on
   their ``PATH``.
   
3. Or, if you have a `local::lib <https://metacpan.org/pod/local::lib>`_
   setup, you can install MView there::

        perl Makefile.PL $PERL_MM_OPT
        make install

4. Finally, the unpacked archive can be deleted since the crucial components
   have been installed elsewhere.
