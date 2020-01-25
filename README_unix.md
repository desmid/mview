### Installation - Linux, macOS, UNIX

There are two ways to install MView.

Either method can be used by an ordinary user installing into their own
account, or by a system administrator installing onto a computer with multiple
users. It is assumed that Perl is already installed and on your `PATH`.

* [Installer script](#installer-script)
* [Manual install](#manual-install)


#### Installer script

The installer program should work on all systems, but is new and relatively
experimental.

You unpack the archive into a destination folder and run the installer from
there, following the instructions. You may have to edit `PATH` afterwards.

Explanation: the installer puts a small mview driver program into a folder on
`PATH` so that it can be run easily by the user. The driver knows the location
of the unpacked MView folder and starts the real MView program.

1. Save the archive to somewhere under your home folder then uncompress
   and extract it:

        tar xvzf mview-VERSION.tar.gz

   This creates a sub-folder `mview-VERSION` containing all the files.
   
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


#### Manual install

This works on all systems and is the most basic, but requires that you do a
little editing.

You unpack the archive into a destination folder, edit the MView program by
hand, then add the folder containing that program to `PATH`.

1. Save the archive to your software area, for example, `/usr/local`, then
   uncompress and extract it:

        tar xvzf mview-VERSION.tar.gz

   This creates a sub-folder `mview-VERSION` containing all the files.

2. Change to this folder.

3. Edit the file `bin/mview`.

   Set a valid path for the Perl interpreter on your machine after the `#!`
   at the top of the file, for example:

        #!/usr/bin/perl

   Find the line:
 
        $MVIEW_HOME = "/path/to/mview/unpacked/folder";
       
   and change the path, in our example, to:

        $MVIEW_HOME = "/usr/local/mview-VERSION";

   Save the file.

4. Finally, make sure that the `bin` folder containing the `mview` script
   (that you just edited) is on the user `PATH`, and rehash or login again.

   In our example, you would add `/usr/local/mview-VERSION/bin` to the
   existing value of `PATH`, or replace any older MView path.

---

Return to main [README](README.md).
