Install: Windows
================

MView requires a Perl installation and is known to work with `Strawberry Perl
for Windows <http://strawberryperl.com/>`_.

There are different approaches depending on whether you are installing for
your own use or as a site administrator for multiple users.

Personal use
^^^^^^^^^^^^

Using this method, you unpack the archive into a destination directory, then
run an installer that puts a small driver program into a folder on your
``PATH`` so you can run it easily. The driver knows the location of the
unpacked MView folder and starts the real MView program.

1. Save the archive to somewhere under your home folder then uncompress and
   extract it (using an archiver like WinZip or 7-Zip, as here)::

        7z x mview-1.66.1.tar.bz2
        7z x mview-1.66.1.tar

   This creates a sub-folder called ``mview-1.66.1`` containing all the files.
   
2. Change to this folder.

3. Run the command::

        perl install.pl
        
   and follow the instructions. You will be offered various places to install
   the driver script.
   
   If you know in advance the name of the folder you want to use for the
   driver script, you can supply it on the command line::

        perl install.pl \folder\on\my\path

4. If the installer couldn't find a sensible place to install the driver, it
   chooses ``C:\bin`` and you will have to add that to your ``PATH``, then
   start a new command prompt.


Site administrator for multiple users
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

You can use the installer method above, or install manually.

If installing manually, you unpack the archive and edit the MView program by
hand, then add its folder to ``PATH``.

1. Save the archive to your software area, for example, ``C:\Program Files``,
   then uncompress and extract it (using an archiver like WinZip or 7-Zip, as
   here)::

        7z x mview-1.66.1.tar.bz2
        7z x mview-1.66.1.tar

   This creates a sub-folder called ``mview-1.66.1`` containing all the files.

2. Change to this folder.

3. Edit the file ``bin\mview``.

  * Find the line::

        $MVIEW_HOME = "/path/to/mview/unpacked/folder";

    and change the path, in our example, to::

        $MVIEW_HOME = "C:\Program Files\mview-1.66.1";

  * Save the file.

4. Finally, make sure that the ``bin`` folder containing the ``mview`` script
   (that you just edited) is on the user ``PATH``, then start a new command
   prompt.

   In our example, you would add ``C:\Program Files\mview-1.66.1\bin`` to the
   existing value of ``PATH``, or replace any older MView path.
