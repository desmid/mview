Install: Windows
================

MView requires a Perl installation and is known to work with `Strawberry Perl
for Windows <http://strawberryperl.com/>`_.

There are different approaches depending on whether you are installing for
your own use or as a site administrator for multiple users.

Personal use
^^^^^^^^^^^^

1. Save the archive to somewhere under your home folder then uncompress and
   extract it (using an archiver like WinZip or 7-Zip, as here)::

        7z x mview-1.66.1.tar.gz
        7z x mview-1.66.1.tar

   This creates a sub-folder called ``mview-1.66.1`` containing all the files.
   
2. Change to this folder.

3. Run the command::

        perl install.pl
        
   and follow the instructions. The installer creates a driver script pointing
   to wherever you just unpacked MView. It offers you various places to
   install this driver so that it is on your ``PATH``.
   
4. If the installer couldn't find a sensible place to install the driver, it
   chooses ``C:\bin`` and you will have to add that to your ``PATH``, then
   start a new command prompt.


Site administrator for multiple users
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

You can use the ``install.pl`` script as above, or install manually:

1. Save the archive to your software area, for example, ``C:\Programs``, then
   uncompress and extract it (using an archiver like WinZip or 7-Zip, as
   here)::

        7z x mview-1.66.1.tar.gz
        7z x mview-1.66.1.tar

   This creates a sub-folder called ``mview-1.66.1`` containing all the files.

2. Change to this folder.

3. Edit the file ``bin\mview``.

  * Find the line::

        $MVIEW_HOME = "/path/to/mview/unpacked/folder";

    and change the path, in our example, to::

        $MVIEW_HOME = "C:\Programs\mview-1.66.1";

  * Save the file.

4. Finally, make sure that the ``bin`` folder containing the ``mview`` script
   (that you just edited) is on the user ``PATH``, then start a new command
   prompt.

   In our example, you would add ``C:\Programs\mview-1.66.1\bin`` to the
   existing value of ``PATH``, or replace any older MView path.
