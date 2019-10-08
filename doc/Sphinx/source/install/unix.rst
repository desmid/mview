Install: Linux, Apple, UNIX
===========================

There are different approaches depending on whether you are installing for
your own use or as a site administrator for multiple users.

Personal use
^^^^^^^^^^^^

Using this method, you unpack the archive into a destination directory, then
run an installer that puts a small driver program into a folder on your
``PATH`` so you can run it easily. The driver knows the location of the
unpacked MView folder and starts the real MView program.

1. Save the archive to somewhere under your home folder then uncompress
   and extract it::

        tar xvzf mview-1.66.1.tar.gz

   This creates a sub-folder called ``mview-1.66.1`` containing all the files.
   
2. Change to this folder.

3. Run the command::

        perl install.pl
        
   and follow the instructions. You will be offered various places to install
   the driver script.
   
   If you know in advance the name of the folder you want to use for the
   driver script, you can supply it on the command line::

        perl install.pl /folder/on/my/path

4. If the installer couldn't find a sensible place to install the driver, it
   chooses ``~/bin`` and you will have to add that to your ``PATH``, then
   rehash or login again.

Site administrator for multiple users
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

You can use the installer method above, or install manually:

If installing manually, you unpack the archive and edit the MView program by
hand, then add its folder to ``PATH``.

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
