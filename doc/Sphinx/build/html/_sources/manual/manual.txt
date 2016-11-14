.. raw:: html

  <LINK rel="stylesheet" type="text/css" href="../_static/MView.css">


Manual
======

Basic usage
-----------

Getting started
^^^^^^^^^^^^^^^

Given an existing sequence alignment in a file ``data.dat`` in FASTA format,
the simplest usage might be::

  mview -in fasta data.dat

Similarly, if the input file contained a CLUSTAL alignment::

  mview -in clustal data.dat

In either case, the output would be a stacked alignment with extra columns
added to show row numbers and percent identities (with respect to the first
sequence), looking something like this, regardless of the input format:

.. raw:: html

  <PRE>
  Reference sequence (1): EGFR_HUMAN
  Identities normalised by aligned length.

  1 EGFR_HUMAN  100.0%  FKKIKVLGSGAFGTVYKGLWIPEGEK---------VKIPVAIKELREATSPK-ANKEILDEAYVMASVDNPHVCRLLGIC 
  2 PR2_DROME    35.7%  ISVNKQLGTGEFGIVQQGVWSNGNE-----------RIQVAIKCLCRERMQS-NPMEFLKEAAIMHSIEHENIVRLYGVV 
  3 ITK_HUMAN    32.9%  LTFVQEIGSGQFGLVHLGYWLN--------------KDKVAIKTIREGAMS---EEDFIEEAEVMMKLSHPKLVQLYGVC 
  4 PTK7_HUMAN   21.2%  IREVKQIGVGQFGAVVLAEMTGLS-XLPKGSMNADGVALVAVKKLKPDVSD-EVLQSFDKEIKFMSQLQHDSIVQLLAIC 
  5 KIN31_CAEEL  31.5%  VELTKKLGEGAFGEVWKGKLLKILDA-------NHQPVLVAVKTAKLESMTKEQIKEIMREARLMRNLDHINVVKFFGVA 
  </PRE>

To process the output of a BLAST run use something like::

  mview -in blast blastresults.dat

while to process the output of a FASTA run (the database search program, not
the simple FASTA/Pearson data format) use something like::

  mview -in uvfasta fastaresults.dat

The ``-in`` option isn't always necessary. If the filename extension, or the
filename itself minus any directory path begins with or contains the first few
letters of the valid ``-in`` options (e.g., ``mydata.msf`` or ``mydata.fasta``
or ``tfastx_run.dat``), MView tries to choose a sensible input format,
allowing multiple files in mixed formats to be supplied on the command
line. The ``-in`` option will always override this mechanism but requires that
all input files be of the same format.


.. _ref_rulers:

Attaching a ruler
^^^^^^^^^^^^^^^^^

Add a ruler along the top, with ``-ruler on``, for example::

  mview -in fasta -ruler on data.dat

gives:

.. raw:: html

  <PRE>
  Reference sequence (1): EGFR_HUMAN
  Identities normalised by aligned length.

                      1 [        .         .         .         .         :         .         .         ] 80
  1 EGFR_HUMAN  100.0%    FKKIKVLGSGAFGTVYKGLWIPEGEK---------VKIPVAIKELREATSPK-ANKEILDEAYVMASVDNPHVCRLLGIC   
  2 PR2_DROME    35.7%    ISVNKQLGTGEFGIVQQGVWSNGNE-----------RIQVAIKCLCRERMQS-NPMEFLKEAAIMHSIEHENIVRLYGVV   
  3 ITK_HUMAN    32.9%    LTFVQEIGSGQFGLVHLGYWLN--------------KDKVAIKTIREGAMS---EEDFIEEAEVMMKLSHPKLVQLYGVC   
  4 PTK7_HUMAN   21.2%    IREVKQIGVGQFGAVVLAEMTGLS-XLPKGSMNADGVALVAVKKLKPDVSD-EVLQSFDKEIKFMSQLQHDSIVQLLAIC   
  5 KIN31_CAEEL  31.5%    VELTKKLGEGAFGEVWKGKLLKILDA-------NHQPVLVAVKTAKLESMTKEQIKEIMREARLMRNLDHINVVKFFGVA   
  </PRE>

Only one kind of ruler is currently provided, numbering the columns of the
final alignment from M to N (incrementing) or N to M (decrementing) based on
the input sequence numbering, if any. For multiple alignments like the one
above with no numbering the ruler runs from 1 to the length of the alignment.

For database searches that translate nucleotide sequences to protein, such as
TBLASTX, the rulers differ slightly in that the native query numbering is
given in nucleotide units, but MView reports amino acid units instead (using
modulo 3 arithmetic).


.. _ref_reference_row:

Changing the reference sequence
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

One can colour and compute identities with respect to a sequence other than
the first/query sequence using the ``-reference`` option. This takes either
the sequence identifier or an integer argument corresponding to the ranking or
ordering of a sequence usually shown in the first labelling column of MView
output. For multiple alignment input formats, sequences are numbered from 1,
while for searches the hits are numbered from 1, but the query itself is 0, so
beware.


Command line options
^^^^^^^^^^^^^^^^^^^^

ALl available options can be listed using::

  mview -help

There are a lot of options, but the main ones are described in this manual.


Adding HTML
-----------

Basic HTML
^^^^^^^^^^

To add some HTML markup a few extra options are needed, for example::

        mview -in fasta -html head data.dat > data.html

produces a complete page of HTML and you can load this into your Web browser
with a URL like ``file:///full/path/to/the/folder/data.html``.

To colour all the residues using the default built-in colourmap for proteins::

    mview -in fasta -ruler on -html head -coloring any data.dat > data.html

produces:

.. raw:: html

  <PRE>
  Colored by: property

                      1 [        .         .         .         .         :         .         .         ] 80
  1 EGFR_HUMAN  100.0%    <SPAN style="color:#009900">F</SPAN><SPAN style="color:#cc0000">KK</SPAN><SPAN style="color:#33cc00">I</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#33cc00">VLG</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#33cc00">GA</SPAN><SPAN style="color:#009900">F</SPAN><SPAN style="color:#33cc00">G</SPAN><SPAN style="color:#0099ff">T</SPAN><SPAN style="color:#33cc00">V</SPAN><SPAN style="color:#009900">Y</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#33cc00">GL</SPAN><SPAN style="color:#009900">W</SPAN><SPAN style="color:#33cc00">IP</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">G</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#666666">---------</SPAN><SPAN style="color:#33cc00">V</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#33cc00">IPVAI</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">L</SPAN><SPAN style="color:#cc0000">R</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">A</SPAN><SPAN style="color:#0099ff">TS</SPAN><SPAN style="color:#33cc00">P</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#666666">-</SPAN><SPAN style="color:#33cc00">A</SPAN><SPAN style="color:#6600cc">N</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">IL</SPAN><SPAN style="color:#0033ff">DE</SPAN><SPAN style="color:#33cc00">A</SPAN><SPAN style="color:#009900">Y</SPAN><SPAN style="color:#33cc00">VMA</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#33cc00">V</SPAN><SPAN style="color:#0033ff">D</SPAN><SPAN style="color:#6600cc">N</SPAN><SPAN style="color:#33cc00">P</SPAN><SPAN style="color:#009900">H</SPAN><SPAN style="color:#33cc00">V</SPAN><SPAN style="color:#ffff00">C</SPAN><SPAN style="color:#cc0000">R</SPAN><SPAN style="color:#33cc00">LLGI</SPAN><SPAN style="color:#ffff00">C</SPAN>   
  2 PR2_DROME    35.7%    <SPAN style="color:#33cc00">I</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#33cc00">V</SPAN><SPAN style="color:#6600cc">N</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#6600cc">Q</SPAN><SPAN style="color:#33cc00">LG</SPAN><SPAN style="color:#0099ff">T</SPAN><SPAN style="color:#33cc00">G</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#009900">F</SPAN><SPAN style="color:#33cc00">GIV</SPAN><SPAN style="color:#6600cc">QQ</SPAN><SPAN style="color:#33cc00">GV</SPAN><SPAN style="color:#009900">W</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#6600cc">N</SPAN><SPAN style="color:#33cc00">G</SPAN><SPAN style="color:#6600cc">N</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#666666">-----------</SPAN><SPAN style="color:#cc0000">R</SPAN><SPAN style="color:#33cc00">I</SPAN><SPAN style="color:#6600cc">Q</SPAN><SPAN style="color:#33cc00">VAI</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#ffff00">C</SPAN><SPAN style="color:#33cc00">L</SPAN><SPAN style="color:#ffff00">C</SPAN><SPAN style="color:#cc0000">R</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#cc0000">R</SPAN><SPAN style="color:#33cc00">M</SPAN><SPAN style="color:#6600cc">Q</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#666666">-</SPAN><SPAN style="color:#6600cc">N</SPAN><SPAN style="color:#33cc00">PM</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#009900">F</SPAN><SPAN style="color:#33cc00">L</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">AAIM</SPAN><SPAN style="color:#009900">H</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#33cc00">I</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#009900">H</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#6600cc">N</SPAN><SPAN style="color:#33cc00">IV</SPAN><SPAN style="color:#cc0000">R</SPAN><SPAN style="color:#33cc00">L</SPAN><SPAN style="color:#009900">Y</SPAN><SPAN style="color:#33cc00">GVV</SPAN>   
  3 ITK_HUMAN    32.9%    <SPAN style="color:#33cc00">L</SPAN><SPAN style="color:#0099ff">T</SPAN><SPAN style="color:#009900">F</SPAN><SPAN style="color:#33cc00">V</SPAN><SPAN style="color:#6600cc">Q</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">IG</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#33cc00">G</SPAN><SPAN style="color:#6600cc">Q</SPAN><SPAN style="color:#009900">F</SPAN><SPAN style="color:#33cc00">GLV</SPAN><SPAN style="color:#009900">H</SPAN><SPAN style="color:#33cc00">LG</SPAN><SPAN style="color:#009900">YW</SPAN><SPAN style="color:#33cc00">L</SPAN><SPAN style="color:#6600cc">N</SPAN><SPAN style="color:#666666">--------------</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#0033ff">D</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#33cc00">VAI</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#0099ff">T</SPAN><SPAN style="color:#33cc00">I</SPAN><SPAN style="color:#cc0000">R</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">GAM</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#666666">---</SPAN><SPAN style="color:#0033ff">EED</SPAN><SPAN style="color:#009900">F</SPAN><SPAN style="color:#33cc00">I</SPAN><SPAN style="color:#0033ff">EE</SPAN><SPAN style="color:#33cc00">A</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">VMM</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#33cc00">L</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#009900">H</SPAN><SPAN style="color:#33cc00">P</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#33cc00">LV</SPAN><SPAN style="color:#6600cc">Q</SPAN><SPAN style="color:#33cc00">L</SPAN><SPAN style="color:#009900">Y</SPAN><SPAN style="color:#33cc00">GV</SPAN><SPAN style="color:#ffff00">C</SPAN>   
  4 PTK7_HUMAN   21.2%    <SPAN style="color:#33cc00">I</SPAN><SPAN style="color:#cc0000">R</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">V</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#6600cc">Q</SPAN><SPAN style="color:#33cc00">IGVG</SPAN><SPAN style="color:#6600cc">Q</SPAN><SPAN style="color:#009900">F</SPAN><SPAN style="color:#33cc00">GAVVLA</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">M</SPAN><SPAN style="color:#0099ff">T</SPAN><SPAN style="color:#33cc00">GL</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#666666">-X</SPAN><SPAN style="color:#33cc00">LP</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#33cc00">G</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#33cc00">M</SPAN><SPAN style="color:#6600cc">N</SPAN><SPAN style="color:#33cc00">A</SPAN><SPAN style="color:#0033ff">D</SPAN><SPAN style="color:#33cc00">GVALVAV</SPAN><SPAN style="color:#cc0000">KK</SPAN><SPAN style="color:#33cc00">L</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#33cc00">P</SPAN><SPAN style="color:#0033ff">D</SPAN><SPAN style="color:#33cc00">V</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#0033ff">D</SPAN><SPAN style="color:#666666">-</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">VL</SPAN><SPAN style="color:#6600cc">Q</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#009900">F</SPAN><SPAN style="color:#0033ff">D</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">I</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#009900">F</SPAN><SPAN style="color:#33cc00">M</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#6600cc">Q</SPAN><SPAN style="color:#33cc00">L</SPAN><SPAN style="color:#6600cc">Q</SPAN><SPAN style="color:#009900">H</SPAN><SPAN style="color:#0033ff">D</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#33cc00">IV</SPAN><SPAN style="color:#6600cc">Q</SPAN><SPAN style="color:#33cc00">LLAI</SPAN><SPAN style="color:#ffff00">C</SPAN>   
  5 KIN31_CAEEL  31.5%    <SPAN style="color:#33cc00">V</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">L</SPAN><SPAN style="color:#0099ff">T</SPAN><SPAN style="color:#cc0000">KK</SPAN><SPAN style="color:#33cc00">LG</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">GA</SPAN><SPAN style="color:#009900">F</SPAN><SPAN style="color:#33cc00">G</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">V</SPAN><SPAN style="color:#009900">W</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#33cc00">G</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#33cc00">LL</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#33cc00">IL</SPAN><SPAN style="color:#0033ff">D</SPAN><SPAN style="color:#33cc00">A</SPAN><SPAN style="color:#666666">-------</SPAN><SPAN style="color:#6600cc">N</SPAN><SPAN style="color:#009900">H</SPAN><SPAN style="color:#6600cc">Q</SPAN><SPAN style="color:#33cc00">PVLVAV</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#0099ff">T</SPAN><SPAN style="color:#33cc00">A</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#33cc00">L</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#33cc00">M</SPAN><SPAN style="color:#0099ff">T</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#6600cc">Q</SPAN><SPAN style="color:#33cc00">I</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">IM</SPAN><SPAN style="color:#cc0000">R</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">A</SPAN><SPAN style="color:#cc0000">R</SPAN><SPAN style="color:#33cc00">LM</SPAN><SPAN style="color:#cc0000">R</SPAN><SPAN style="color:#6600cc">N</SPAN><SPAN style="color:#33cc00">L</SPAN><SPAN style="color:#0033ff">D</SPAN><SPAN style="color:#009900">H</SPAN><SPAN style="color:#33cc00">I</SPAN><SPAN style="color:#6600cc">N</SPAN><SPAN style="color:#33cc00">VV</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#009900">FF</SPAN><SPAN style="color:#33cc00">GVA</SPAN>   
  </PRE>

To make the letters stand out use the ``-bold`` option::

  mview -in fasta -ruler on -html head -bold -coloring any data.dat > data.html

giving:

.. raw:: html

  <PRE>
  Colored by: property

                     <STRONG> 1</STRONG> <STRONG>[        .         .         .         .         :         .         .         ]</STRONG> <STRONG>80</STRONG>
  1 EGFR_HUMAN  100.0% <STRONG>  </STRONG> <STRONG><SPAN style="color:#009900">F</SPAN><SPAN style="color:#cc0000">KK</SPAN><SPAN style="color:#33cc00">I</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#33cc00">VLG</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#33cc00">GA</SPAN><SPAN style="color:#009900">F</SPAN><SPAN style="color:#33cc00">G</SPAN><SPAN style="color:#0099ff">T</SPAN><SPAN style="color:#33cc00">V</SPAN><SPAN style="color:#009900">Y</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#33cc00">GL</SPAN><SPAN style="color:#009900">W</SPAN><SPAN style="color:#33cc00">IP</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">G</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#666666">---------</SPAN><SPAN style="color:#33cc00">V</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#33cc00">IPVAI</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">L</SPAN><SPAN style="color:#cc0000">R</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">A</SPAN><SPAN style="color:#0099ff">TS</SPAN><SPAN style="color:#33cc00">P</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#666666">-</SPAN><SPAN style="color:#33cc00">A</SPAN><SPAN style="color:#6600cc">N</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">IL</SPAN><SPAN style="color:#0033ff">DE</SPAN><SPAN style="color:#33cc00">A</SPAN><SPAN style="color:#009900">Y</SPAN><SPAN style="color:#33cc00">VMA</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#33cc00">V</SPAN><SPAN style="color:#0033ff">D</SPAN><SPAN style="color:#6600cc">N</SPAN><SPAN style="color:#33cc00">P</SPAN><SPAN style="color:#009900">H</SPAN><SPAN style="color:#33cc00">V</SPAN><SPAN style="color:#ffff00">C</SPAN><SPAN style="color:#cc0000">R</SPAN><SPAN style="color:#33cc00">LLGI</SPAN><SPAN style="color:#ffff00">C</SPAN></STRONG> <STRONG>  </STRONG>
  2 PR2_DROME    35.7% <STRONG>  </STRONG> <STRONG><SPAN style="color:#33cc00">I</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#33cc00">V</SPAN><SPAN style="color:#6600cc">N</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#6600cc">Q</SPAN><SPAN style="color:#33cc00">LG</SPAN><SPAN style="color:#0099ff">T</SPAN><SPAN style="color:#33cc00">G</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#009900">F</SPAN><SPAN style="color:#33cc00">GIV</SPAN><SPAN style="color:#6600cc">QQ</SPAN><SPAN style="color:#33cc00">GV</SPAN><SPAN style="color:#009900">W</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#6600cc">N</SPAN><SPAN style="color:#33cc00">G</SPAN><SPAN style="color:#6600cc">N</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#666666">-----------</SPAN><SPAN style="color:#cc0000">R</SPAN><SPAN style="color:#33cc00">I</SPAN><SPAN style="color:#6600cc">Q</SPAN><SPAN style="color:#33cc00">VAI</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#ffff00">C</SPAN><SPAN style="color:#33cc00">L</SPAN><SPAN style="color:#ffff00">C</SPAN><SPAN style="color:#cc0000">R</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#cc0000">R</SPAN><SPAN style="color:#33cc00">M</SPAN><SPAN style="color:#6600cc">Q</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#666666">-</SPAN><SPAN style="color:#6600cc">N</SPAN><SPAN style="color:#33cc00">PM</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#009900">F</SPAN><SPAN style="color:#33cc00">L</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">AAIM</SPAN><SPAN style="color:#009900">H</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#33cc00">I</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#009900">H</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#6600cc">N</SPAN><SPAN style="color:#33cc00">IV</SPAN><SPAN style="color:#cc0000">R</SPAN><SPAN style="color:#33cc00">L</SPAN><SPAN style="color:#009900">Y</SPAN><SPAN style="color:#33cc00">GVV</SPAN></STRONG> <STRONG>  </STRONG>
  3 ITK_HUMAN    32.9% <STRONG>  </STRONG> <STRONG><SPAN style="color:#33cc00">L</SPAN><SPAN style="color:#0099ff">T</SPAN><SPAN style="color:#009900">F</SPAN><SPAN style="color:#33cc00">V</SPAN><SPAN style="color:#6600cc">Q</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">IG</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#33cc00">G</SPAN><SPAN style="color:#6600cc">Q</SPAN><SPAN style="color:#009900">F</SPAN><SPAN style="color:#33cc00">GLV</SPAN><SPAN style="color:#009900">H</SPAN><SPAN style="color:#33cc00">LG</SPAN><SPAN style="color:#009900">YW</SPAN><SPAN style="color:#33cc00">L</SPAN><SPAN style="color:#6600cc">N</SPAN><SPAN style="color:#666666">--------------</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#0033ff">D</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#33cc00">VAI</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#0099ff">T</SPAN><SPAN style="color:#33cc00">I</SPAN><SPAN style="color:#cc0000">R</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">GAM</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#666666">---</SPAN><SPAN style="color:#0033ff">EED</SPAN><SPAN style="color:#009900">F</SPAN><SPAN style="color:#33cc00">I</SPAN><SPAN style="color:#0033ff">EE</SPAN><SPAN style="color:#33cc00">A</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">VMM</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#33cc00">L</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#009900">H</SPAN><SPAN style="color:#33cc00">P</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#33cc00">LV</SPAN><SPAN style="color:#6600cc">Q</SPAN><SPAN style="color:#33cc00">L</SPAN><SPAN style="color:#009900">Y</SPAN><SPAN style="color:#33cc00">GV</SPAN><SPAN style="color:#ffff00">C</SPAN></STRONG> <STRONG>  </STRONG>
  4 PTK7_HUMAN   21.2% <STRONG>  </STRONG> <STRONG><SPAN style="color:#33cc00">I</SPAN><SPAN style="color:#cc0000">R</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">V</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#6600cc">Q</SPAN><SPAN style="color:#33cc00">IGVG</SPAN><SPAN style="color:#6600cc">Q</SPAN><SPAN style="color:#009900">F</SPAN><SPAN style="color:#33cc00">GAVVLA</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">M</SPAN><SPAN style="color:#0099ff">T</SPAN><SPAN style="color:#33cc00">GL</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#666666">-X</SPAN><SPAN style="color:#33cc00">LP</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#33cc00">G</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#33cc00">M</SPAN><SPAN style="color:#6600cc">N</SPAN><SPAN style="color:#33cc00">A</SPAN><SPAN style="color:#0033ff">D</SPAN><SPAN style="color:#33cc00">GVALVAV</SPAN><SPAN style="color:#cc0000">KK</SPAN><SPAN style="color:#33cc00">L</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#33cc00">P</SPAN><SPAN style="color:#0033ff">D</SPAN><SPAN style="color:#33cc00">V</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#0033ff">D</SPAN><SPAN style="color:#666666">-</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">VL</SPAN><SPAN style="color:#6600cc">Q</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#009900">F</SPAN><SPAN style="color:#0033ff">D</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">I</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#009900">F</SPAN><SPAN style="color:#33cc00">M</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#6600cc">Q</SPAN><SPAN style="color:#33cc00">L</SPAN><SPAN style="color:#6600cc">Q</SPAN><SPAN style="color:#009900">H</SPAN><SPAN style="color:#0033ff">D</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#33cc00">IV</SPAN><SPAN style="color:#6600cc">Q</SPAN><SPAN style="color:#33cc00">LLAI</SPAN><SPAN style="color:#ffff00">C</SPAN></STRONG> <STRONG>  </STRONG>
  5 KIN31_CAEEL  31.5% <STRONG>  </STRONG> <STRONG><SPAN style="color:#33cc00">V</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">L</SPAN><SPAN style="color:#0099ff">T</SPAN><SPAN style="color:#cc0000">KK</SPAN><SPAN style="color:#33cc00">LG</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">GA</SPAN><SPAN style="color:#009900">F</SPAN><SPAN style="color:#33cc00">G</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">V</SPAN><SPAN style="color:#009900">W</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#33cc00">G</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#33cc00">LL</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#33cc00">IL</SPAN><SPAN style="color:#0033ff">D</SPAN><SPAN style="color:#33cc00">A</SPAN><SPAN style="color:#666666">-------</SPAN><SPAN style="color:#6600cc">N</SPAN><SPAN style="color:#009900">H</SPAN><SPAN style="color:#6600cc">Q</SPAN><SPAN style="color:#33cc00">PVLVAV</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#0099ff">T</SPAN><SPAN style="color:#33cc00">A</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#33cc00">L</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#0099ff">S</SPAN><SPAN style="color:#33cc00">M</SPAN><SPAN style="color:#0099ff">T</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#6600cc">Q</SPAN><SPAN style="color:#33cc00">I</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">IM</SPAN><SPAN style="color:#cc0000">R</SPAN><SPAN style="color:#0033ff">E</SPAN><SPAN style="color:#33cc00">A</SPAN><SPAN style="color:#cc0000">R</SPAN><SPAN style="color:#33cc00">LM</SPAN><SPAN style="color:#cc0000">R</SPAN><SPAN style="color:#6600cc">N</SPAN><SPAN style="color:#33cc00">L</SPAN><SPAN style="color:#0033ff">D</SPAN><SPAN style="color:#009900">H</SPAN><SPAN style="color:#33cc00">I</SPAN><SPAN style="color:#6600cc">N</SPAN><SPAN style="color:#33cc00">VV</SPAN><SPAN style="color:#cc0000">K</SPAN><SPAN style="color:#009900">FF</SPAN><SPAN style="color:#33cc00">GVA</SPAN></STRONG> <STRONG>  </STRONG>
  </PRE>

Or change the colouring to use blocked letters with ``-css on`` instead::

  mview -in fasta -ruler on -html head -css on -coloring any data.dat > data.html

giving:

.. raw:: html

  <PRE>
  Colored by: property

                      1 [        .         .         .         .         :         .         .         ] 80
  1 EGFR_HUMAN  100.0%    <SPAN CLASS=S13>F</SPAN><SPAN CLASS=S17>KK</SPAN><SPAN CLASS=S14>I</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>VLG</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S14>GA</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=S13>Y</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>GL</SPAN><SPAN CLASS=S13>W</SPAN><SPAN CLASS=S14>IP</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#666666">---------</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>IPVAI</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>A</SPAN><SPAN CLASS=S9>TS</SPAN><SPAN CLASS=S14>P</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#666666">-</SPAN><SPAN CLASS=S14>A</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>IL</SPAN><SPAN CLASS=S12>DE</SPAN><SPAN CLASS=S14>A</SPAN><SPAN CLASS=S13>Y</SPAN><SPAN CLASS=S14>VMA</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=S12>D</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S14>P</SPAN><SPAN CLASS=S13>H</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=S7>C</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S14>LLGI</SPAN><SPAN CLASS=S7>C</SPAN>   
  2 PR2_DROME    35.7%    <SPAN CLASS=S14>I</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S14>LG</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>GIV</SPAN><SPAN CLASS=S8>QQ</SPAN><SPAN CLASS=S14>GV</SPAN><SPAN CLASS=S13>W</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S12>E</SPAN><SPAN style="color:#666666">-----------</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S14>I</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S14>VAI</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S7>C</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S7>C</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S14>M</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S9>S</SPAN><SPAN style="color:#666666">-</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S14>PM</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>AAIM</SPAN><SPAN CLASS=S13>H</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S14>I</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S13>H</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S14>IV</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S13>Y</SPAN><SPAN CLASS=S14>GVV</SPAN>   
  3 ITK_HUMAN    32.9%    <SPAN CLASS=S14>L</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>IG</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>GLV</SPAN><SPAN CLASS=S13>H</SPAN><SPAN CLASS=S14>LG</SPAN><SPAN CLASS=S13>YW</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S8>N</SPAN><SPAN style="color:#666666">--------------</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S12>D</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>VAI</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S14>I</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>GAM</SPAN><SPAN CLASS=S9>S</SPAN><SPAN style="color:#666666">---</SPAN><SPAN CLASS=S12>EED</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>I</SPAN><SPAN CLASS=S12>EE</SPAN><SPAN CLASS=S14>A</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>VMM</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S13>H</SPAN><SPAN CLASS=S14>P</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>LV</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S13>Y</SPAN><SPAN CLASS=S14>GV</SPAN><SPAN CLASS=S7>C</SPAN>   
  4 PTK7_HUMAN   21.2%    <SPAN CLASS=S14>I</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S14>IGVG</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>GAVVLA</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>M</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S14>GL</SPAN><SPAN CLASS=S9>S</SPAN><SPAN style="color:#666666">-</SPAN><SPAN CLASS=T19>X</SPAN><SPAN CLASS=S14>LP</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S14>M</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S14>A</SPAN><SPAN CLASS=S12>D</SPAN><SPAN CLASS=S14>GVALVAV</SPAN><SPAN CLASS=S17>KK</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>P</SPAN><SPAN CLASS=S12>D</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S12>D</SPAN><SPAN style="color:#666666">-</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>VL</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S12>D</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>I</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>M</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S13>H</SPAN><SPAN CLASS=S12>D</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S14>IV</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S14>LLAI</SPAN><SPAN CLASS=S7>C</SPAN>   
  5 KIN31_CAEEL  31.5%    <SPAN CLASS=S14>V</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S17>KK</SPAN><SPAN CLASS=S14>LG</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>GA</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=S13>W</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>LL</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>IL</SPAN><SPAN CLASS=S12>D</SPAN><SPAN CLASS=S14>A</SPAN><SPAN style="color:#666666">-------</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S13>H</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S14>PVLVAV</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S14>A</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S14>M</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S14>I</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>IM</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>A</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S14>LM</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S12>D</SPAN><SPAN CLASS=S13>H</SPAN><SPAN CLASS=S14>I</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S14>VV</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S13>FF</SPAN><SPAN CLASS=S14>GVA</SPAN>   
  </PRE>

You can combine ``-css on`` with ``-bold`` to make the blocks and letters even
more prominent.

If your data are DNA or RNA, add the option ``-moltype dna`` (or ``rna`` or
``na`` for "nucleic acid") to change to the default nucleotide
colourmap. Here's an MView run on some BLASTN data demonstrating some other
options as well::

  mview -in blast -ruler on -html head -css on -coloring identity -moltype dna -top 5 -range 250:310 blastn.dat

which (slightly edited to reduce space) produced:

.. raw:: html

  <PRE>
  HSP processing: ranked
  Query orientation: +
                                                                             250 [         .         .         .         .         3         ] 310
    EMBOSS_001                   bits E-value N qy ht 100.0%   1:521             <SPAN CLASS=S9>T</SPAN><SPAN CLASS=S12>GAAG</SPAN><SPAN CLASS=S9>CCT</SPAN><SPAN CLASS=S12>G</SPAN><SPAN CLASS=S9>C</SPAN><SPAN CLASS=S12>A</SPAN><SPAN CLASS=S9>CTT</SPAN><SPAN CLASS=S12>A</SPAN><SPAN CLASS=S9>CTC</SPAN><SPAN CLASS=S12>AGGA</SPAN><SPAN CLASS=S9>CTC</SPAN><SPAN CLASS=S12>A</SPAN><SPAN CLASS=S9>TC</SPAN><SPAN CLASS=S12>A</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S12>GA</SPAN><SPAN CLASS=S9>CT</SPAN><SPAN CLASS=S12>G</SPAN><SPAN CLASS=S9>C</SPAN><SPAN CLASS=S12>G</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S12>A</SPAN><SPAN CLASS=S9>CC</SPAN><SPAN CLASS=S12>AA</SPAN><SPAN CLASS=S9>TTC</SPAN><SPAN CLASS=S12>G</SPAN><SPAN CLASS=S9>TCTT</SPAN><SPAN CLASS=S12>A</SPAN><SPAN CLASS=S9>CTC</SPAN><SPAN CLASS=S12>AGGA</SPAN><SPAN CLASS=S9>CT</SPAN>    
  1 EM_EST:GT222018.2 gh1574...  1033     0.0 1  +  + 100.0%   1:521   4:524     <SPAN CLASS=S9>T</SPAN><SPAN CLASS=S12>GAAG</SPAN><SPAN CLASS=S9>CCT</SPAN><SPAN CLASS=S12>G</SPAN><SPAN CLASS=S9>C</SPAN><SPAN CLASS=S12>A</SPAN><SPAN CLASS=S9>CTT</SPAN><SPAN CLASS=S12>A</SPAN><SPAN CLASS=S9>CTC</SPAN><SPAN CLASS=S12>AGGA</SPAN><SPAN CLASS=S9>CTC</SPAN><SPAN CLASS=S12>A</SPAN><SPAN CLASS=S9>TC</SPAN><SPAN CLASS=S12>A</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S12>GA</SPAN><SPAN CLASS=S9>CT</SPAN><SPAN CLASS=S12>G</SPAN><SPAN CLASS=S9>C</SPAN><SPAN CLASS=S12>G</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S12>A</SPAN><SPAN CLASS=S9>CC</SPAN><SPAN CLASS=S12>AA</SPAN><SPAN CLASS=S9>TTC</SPAN><SPAN CLASS=S12>G</SPAN><SPAN CLASS=S9>TCTT</SPAN><SPAN CLASS=S12>A</SPAN><SPAN CLASS=S9>CTC</SPAN><SPAN CLASS=S12>AGGA</SPAN><SPAN CLASS=S9>CT</SPAN>    
  2 EM_EST:GT222017.1 gh1572...   186   4e-43 1  +  +  98.2% 256:372 205:318     <SPAN style="color:#666666">------</SPAN><SPAN CLASS=S9>CT</SPAN><SPAN CLASS=S12>G</SPAN><SPAN CLASS=S9>C</SPAN><SPAN CLASS=S12>A</SPAN><SPAN CLASS=S9>CTT</SPAN><SPAN CLASS=S12>A</SPAN><SPAN CLASS=S9>CTC</SPAN><SPAN CLASS=S12>AGGA</SPAN><SPAN CLASS=S9>CTC</SPAN><SPAN CLASS=S12>A</SPAN><SPAN CLASS=S9>TC</SPAN><SPAN CLASS=S12>A</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S12>GA</SPAN><SPAN CLASS=S9>CT</SPAN><SPAN CLASS=S12>G</SPAN><SPAN CLASS=S9>C</SPAN><SPAN CLASS=S12>G</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S12>A</SPAN><SPAN CLASS=S9>CC</SPAN><SPAN CLASS=S12>AA</SPAN><SPAN CLASS=S9>TTC</SPAN><SPAN CLASS=S12>G</SPAN><SPAN CLASS=S9>T</SPAN><SPAN style="color:#666666">-</SPAN><SPAN CLASS=S9>TT</SPAN><SPAN CLASS=S12>A</SPAN><SPAN CLASS=S9>CTC</SPAN><SPAN CLASS=S12>AGGA</SPAN><SPAN CLASS=S9>CT</SPAN>    
  3 EM_EST:GT222024.2 gh1633...   182   7e-42 1  +  +  95.9% 262:372  96:209     <SPAN style="color:#666666">------------</SPAN><SPAN CLASS=S9>TT</SPAN><SPAN CLASS=S12>A</SPAN><SPAN CLASS=S9>CTC</SPAN><SPAN CLASS=S12>AGGA</SPAN><SPAN CLASS=S9>CTC</SPAN><SPAN CLASS=S12>A</SPAN><SPAN CLASS=S9>TC</SPAN><SPAN CLASS=S12>A</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S12>GA</SPAN><SPAN CLASS=S9>CT</SPAN><SPAN CLASS=S12>G</SPAN><SPAN CLASS=S9>C</SPAN><SPAN CLASS=S12>G</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S12>A</SPAN><SPAN CLASS=S9>CC</SPAN><SPAN CLASS=S12>AA</SPAN><SPAN CLASS=S9>TTC</SPAN><SPAN CLASS=S12>G</SPAN><SPAN CLASS=S9>TCtt</SPAN><SPAN CLASS=S12>A</SPAN><SPAN CLASS=S9>CTC</SPAN><SPAN CLASS=S12>AGGA</SPAN><SPAN CLASS=S9>CT</SPAN>    
  4 EM_EST:GT222023.2 gh1631...   182   7e-42 1  +  +  95.9% 262:372  96:209     <SPAN style="color:#666666">------------</SPAN><SPAN CLASS=S9>TT</SPAN><SPAN CLASS=S12>A</SPAN><SPAN CLASS=S9>CTC</SPAN><SPAN CLASS=S12>AGGA</SPAN><SPAN CLASS=S9>CTC</SPAN><SPAN CLASS=S12>A</SPAN><SPAN CLASS=S9>TC</SPAN><SPAN CLASS=S12>A</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S12>GA</SPAN><SPAN CLASS=S9>CT</SPAN><SPAN CLASS=S12>G</SPAN><SPAN CLASS=S9>C</SPAN><SPAN CLASS=S12>G</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S12>A</SPAN><SPAN CLASS=S9>CC</SPAN><SPAN CLASS=S12>AA</SPAN><SPAN CLASS=S9>TTC</SPAN><SPAN CLASS=S12>G</SPAN><SPAN CLASS=S9>TCtt</SPAN><SPAN CLASS=S12>A</SPAN><SPAN CLASS=S9>CTC</SPAN><SPAN CLASS=S12>AGGA</SPAN><SPAN CLASS=S9>CT</SPAN>    
  5 EM_EST:GT222054.2 gh721 ...   178   1e-40 1  +  + 100.0% 279:372    4:97     <SPAN style="color:#666666">-----------------------------</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S12>GA</SPAN><SPAN CLASS=S9>CT</SPAN><SPAN CLASS=S12>G</SPAN><SPAN CLASS=S9>C</SPAN><SPAN CLASS=S12>G</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S12>A</SPAN><SPAN CLASS=S9>CC</SPAN><SPAN CLASS=S12>AA</SPAN><SPAN CLASS=S9>TTC</SPAN><SPAN CLASS=S12>G</SPAN><SPAN CLASS=S9>TCTT</SPAN><SPAN CLASS=S12>A</SPAN><SPAN CLASS=S9>CTC</SPAN><SPAN CLASS=S12>AGGA</SPAN><SPAN CLASS=S9>CT</SPAN>    
  </PRE>

showing scoring and sequence range information parsed from the BLASTN run, and
using the default nucleotide colouring scheme (purines, dark blue;
pyrimidines, light blue). Notice the lower-cased pairs of thymines near the
end of sequences 3 and 4, columns 299--300 indicating where a segment of hit
sequence has been excised to close a gap in the query (see
:ref:`ref_funny_sequences`).


Controlling the amount of HTML
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

There are several values that can be passed to the ``-html`` option: ``head``,
``body``, ``data``, ``full``, ``off``.

**Mode** ``head``

Produces a complete web page. Output includes the style sheet if ``-css on``
was given. The most common situation.

**Mode** ``body``

Produces just the ``<BODY></BODY>`` part of the web page.  Note: the style
sheet produced by ``-css on`` will be missing.

**Mode** ``data``

Produces just the alignment part of the web page. Note: any style sheet
produced by ``-css on`` will be missing.

**Mode** ``full``

Produces a complete web page with the ``MIME-type "text/html"``, suitable for
serving directly from a web server. Output includes the style sheet if ``-css
on`` was given.

**Mode** ``off``

Switches off HTML (default).


Using an external CSS style sheet
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The option ``-listcss`` dumps the style sheet to stdout, so you can share that
across MView invocations from a web server. Each would be of the form::

  mview -css URL ...

where the URL specifies the location of the style sheet as seen by the web
server (i.e., ``file:///some/path`` or ``http://server/path``).

If you build a new colourmap you can load it into MView and save the new CSS
file. Suppose you have a new colourmap in ``newcolmap.dat``::

  mview -colorfile newcolmap.dat -listcss

will dump the new style sheet for use as before.


.. _ref_consensus_sequences:

Consensus sequences
-------------------

Clustal conservation line
^^^^^^^^^^^^^^^^^^^^^^^^^

A Clustal-style conservation line of ``*:.`` symbols can be added to any
alignment (not just one from CLUSTAL itself) using ``-conservation on``, like
this:

.. raw:: html

  <PRE>
                           1 [        .         .         .         .         :         .         .         ] 80
  1 DMD401_1-640   100.0%    LQLDTVLGEGEFGQVLKGFATEIAG---------LPGITTVAVKMLKKGSNSV------------EYMALLSEFQLLQEV   
  2 CER09D1_11-435  22.2%    DTFNRKLGKGKFGIINKGLLTLRICKTNE------VVQVNVAVKKMVDPTDEK------------QDKLIYDEIKLMEYN   
  3 EGFR_HUMAN      26.7%    FKKIKVLGSGAFGTVYKGLWIPEGEK----------VKIPVAIKELREATSPK------------ANKEILDEAYVMASV   
  4 DMDPR2_1-384    25.4%    ISVNKQLGTGEFGIVQQGVWSNGNE------------RIQVAIKCLCRERMQS------------NPMEFLKEAAIMHSI   
  5 ITK_HUMAN-620   22.0%    LTFVQEIGSGQFGLVHLGYWLN---------------KDKVAIKTIREGAMS--------------EEDFIEEAEVMMKL   
    clustal                        :* * ** :  *                      **:* :                       :  *  ::      
  </PRE>

The symbols are ``*`` for full column identity, and ``:`` or ``.`` for strong
and weak amino acid grouping, respectively, as defined in CLUSTAL.

For DNA or RNA sequences, if the molecule type was set to nucleic acid with
``-moltype na`` or ``dna`` or ``rna``, then the clustal conservation line will
show only the column identities.

Note: these conservation lines can be generated for any subset of rows
extracted using the various row filtering options (see
:ref:`ref_filtering_rows`).


Consensus lines
^^^^^^^^^^^^^^^

Consensus lines can be added beneath the alignment using ``-consensus on``. By
default, this adds four extra lines of consensus sequences computed at various
thresholds of percentage composition of the columns.

There are default consensus patterns for protein and nucleotide (either DNA or
RNA) sequences. MView starts up with the default protein consensus pattern,
for example::

  mview ... -consensus on ...

gives:

.. raw:: html

  <PRE>
                           1 [        .         .         .         .         :         .         .         ] 80
  1 EGFR_HUMAN     100.0%    FKKIKVLGSGAFGTVYKGLWIPEGEK---------VKIPVAIKELREATSPK-ANKEILDEAYVMASVDNPHVCRLLGIC   
  2 PR2_DROME       35.7%    ISVNKQLGTGEFGIVQQGVWSNGNE-----------RIQVAIKCLCRERMQS-NPMEFLKEAAIMHSIEHENIVRLYGVV   
  3 ITK_HUMAN       32.9%    LTFVQEIGSGQFGLVHLGYWLN--------------KDKVAIKTIREGAMS---EEDFIEEAEVMMKLSHPKLVQLYGVC   
  4 PTK7_HUMAN      21.2%    IREVKQIGVGQFGAVVLAEMTGLS-XLPKGSMNADGVALVAVKKLKPDVSD-EVLQSFDKEIKFMSQLQHDSIVQLLAIC   
  5 KIN31_CAEEL     31.5%    VELTKKLGEGAFGEVWKGKLLKILDA-------NHQPVLVAVKTAKLESMTKEQIKEIMREARLMRNLDHINVVKFFGVA   
    consensus/100%           hp..p.lG.GtFG.V..u.h...................VAlKphp.t........ph.cEh.hM.plpp.plsphhuls   
    consensus/90%            hp..p.lG.GtFG.V..u.h...................VAlKphp.t........ph.cEh.hM.plpp.plsphhuls   
    consensus/80%            lphsKplGsGtFGhVhhGhhhs..............hh.VAlKpl+.ts.s....p-hhcEAtlMtplpH.plVpLhGls   
    consensus/70%            lphsKplGsGtFGhVhhGhhhs..............hh.VAlKpl+.ts.s....p-hhcEAtlMtplpH.plVpLhGls   
  </PRE>


Changing consensus thresholds
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The default consensus mechanism displays consensus lines calculated at four
levels of identity (100%, 90%, 80%, 70%). This can be changed to show as many
or as few consensus lines at any level of percent identity between 50 and 100%
using the ``-con_threshold`` option and a comma-separated list of identities::

  mview ... -consensus on -con_threshold 80 ...

would give a single consensus line calculated at 80% identity, while::

  mview ... -consensus on -con_threshold 80,65 ...

would produce two lines at 80% and 65% identity.


Consensus pattern definitions
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Consensus patterns are based on equivalence classes, that is, sets of residues
that share some predefined property. These classes are not mutually exclusive
and the consensus mechanism will choose the most specific class that
summarizes a given column at the desired percent identity.

The default for protein alignments is called ``P1`` and is defined by
physicochemical property as follows:

.. raw:: html

  <PRE>
  <SPAN style="color:#000000">[P1]</SPAN>
  <SPAN style="color:#aa6666">#Protein consensus: conserved physicochemical classes, derived from
  #the Venn diagrams of: Taylor W. R. (1986). The classification of amino acid
  #conservation. J. Theor. Biol. 119:205-218.
  #description =>  symbol  members</SPAN>
  .            =>  .     
  A            =>  A       { A }
  C            =>  C       { C }
  D            =>  D       { D }
  E            =>  E       { E }
  F            =>  F       { F }
  G            =>  G       { G }
  H            =>  H       { H }
  I            =>  I       { I }
  K            =>  K       { K }
  L            =>  L       { L }
  M            =>  M       { M }
  N            =>  N       { N }
  P            =>  P       { P }
  Q            =>  Q       { Q }
  R            =>  R       { R }
  S            =>  S       { S }
  T            =>  T       { T }
  V            =>  V       { V }
  W            =>  W       { W }
  Y            =>  Y       { Y }
  alcohol      =>  o       { S, T }
  aliphatic    =>  l       { I, L, V }
  aromatic     =>  a       { F, H, W, Y }
  charged      =>  c       { D, E, H, K, R }
  hydrophobic  =>  h       { A, C, F, G, H, I, K, L, M, R, T, V, W, Y }
  negative     =>  -       { D, E }
  polar        =>  p       { C, D, E, H, K, N, Q, R, S, T }
  positive     =>  +       { H, K, R }
  small        =>  s       { A, C, D, G, N, P, S, T, V }
  tiny         =>  u       { A, G, S }
  turnlike     =>  t       { A, C, D, E, G, H, K, N, Q, R, S, T }
  stop         =>  *       { * }
  </PRE>

The default nucleotide consensus pattern is ``D1`` grouping bases by ring type
(purine, pyrimidine). It is selected when any of the nucleotide molecule types
is set ``-moltype na`` (for "nucleic acid"; also ``dna`` or ``rna``), for
example::

  mview ... -consensus on -moltype dna ...

and has the following definition:

.. raw:: html

  <PRE>
  <SPAN style="color:#000000">[D1]</SPAN>
  <SPAN style="color:#aa6666">#DNA consensus: conserved ring types
  #Ambiguous base R is purine: A or G
  #Ambiguous base Y is pyrimidine: C or T or U
  #description =>  symbol  members</SPAN>
  .            =>  .     
  A            =>  A       { A }
  C            =>  C       { C }
  G            =>  G       { G }
  T            =>  T       { T }
  U            =>  U       { U }
  purine       =>  r       { A, G, R }
  pyrimidine   =>  y       { C, T, U, Y }
  </PRE>


.. _ref_changeing_consensus_patterns:

Changing consensus patterns
^^^^^^^^^^^^^^^^^^^^^^^^^^^

The available list of built-in patterns can be seen with ``-listgroups``.

Alternative equivalence classes can be selected using ``-con_groupmap``. For
example, to select the ``CYS`` built-in consensus pattern to show only
conserved cysteines you would use an invocation like::

  mview ... -consensus on -con_groupmap CYS ...

New groups can be defined in the same format and read in from a file using
the ``-groupfile`` option.


.. _ref_conserved_symbols or conserved classes:

Showing conserved symbols or conserved classes
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Two options ``-con_ignore`` and ``-con_gaps`` can be used to tune the
consensus lines. Consider the following alignment:

.. raw:: html

  <PRE>
                          1 [        .         .         .         .         :         .         .         ] 80
  1 EGFR_HUMAN    100.0%    FKKIKVLGSGAFGTVYKGLWIPEGEK---------VKIPVAIKELREATSPK-ANKEILDEAYVMASVDNPHVCRLLGIC   
  2 PR2_DROME      35.7%    ISVNKQLGTGEFGIVQQGVWSNGNE-----------RIQVAIKCLCRERMQS-NPMEFLKEAAIMHSIEHENIVRLYGVV   
  3 ITK_HUMAN      32.9%    LTFVQEIGSGQFGLVHLGYWLN--------------KDKVAIKTIREGAMS---EEDFIEEAEVMMKLSHPKLVQLYGVC   
  4 PTK7_HUMAN     21.2%    IREVKQIGVGQFGAVVLAEMTGLS-XLPKGSMNADGVALVAVKKLKPDVSD-EVLQSFDKEIKFMSQLQHDSIVQLLAIC   
  5 KIN31_CAEEL    31.5%    VELTKKLGEGAFGEVWKGKLLKILDA-------NHQPVLVAVKTAKLESMTKEQIKEIMREARLMRNLDHINVVKFFGVA   
  </PRE>

The default consensus pattern for proteins, with these options::

  mview ... -consensus on -con_threshold 80 ...

would add this consensus line:

.. raw:: html

  <PRE>
    consensus/80%           lphsKplGsGtFGhVhhGhhhs..............hh.VAlKpl+.ts.s....p-hhcEAtlMtplpH.plVpLhGls   
  </PRE>

comprising a mixture of conserved residue classes and residues, whichever is
more specific.

If you just want to see the conserved physicochemical classes, use ``-con_ignore singleton``:

.. raw:: html

  <PRE>
    consensus/80%           lphs+plusutauhlhhuhhhs..............hh.lul+pl+.ts.s....p-hhc-utlhtplp+.pllplhuls   
  </PRE>

Alternatively, to see just the conserved residues, use ``-con_ignore class``:

.. raw:: html

  <PRE>
    consensus/80%           ....K..G.G.FG.V..G.....................VA.K.................EA..M....H...V.L.G..   
  </PRE>

Lastly, the default consensus computation counts gap characters in each
column, so that gapped regions are diluted and may not show up in the
consensus. Building on the last example, setting ``-con_gaps off`` prevents
this:

.. raw:: html

  <PRE>
    consensus/80%           ....K..G.G.FG.V..G........LPKGSMN......VA.K.........E.......EA..M....H...V.L.G..   
  </PRE>

The consensus sequence now runs the full length of the alignment because the
insert in sequence 4 spanning the gap has been added to the consensus. This is
a little contrived in this case, but is sometimes useful when you want to
preserve as much of the alignment as possible.

These options work similarly with nucleotide alignments and with any other
consensus pattern you choose.

Note: it is possible to colour the consensus sequences independently of the
alignment (see :ref:`ref_consensus_colouring`).


Colouring modes
---------------


.. _ref_alignment_colouring:

Alignment colouring
^^^^^^^^^^^^^^^^^^^

There are several basic ways to colour the alignment using the ``-coloring``
option which takes five modes: ``any``, ``identity``, ``mismatch``,
``consensus``, ``group``. These all have default associated colour schemes,
but you can supply a different one or just a single colour by name (see the
description for the ``mismatch`` mode for an example).


**Mode** ``any``

The simplest is to colour every residue according to the currently selected
colourmap::

  mview ... -coloring any ...

gives:

.. raw:: html

  <PRE>
  1 EGFR_HUMAN  100.0%  <SPAN CLASS=S13>F</SPAN><SPAN CLASS=S17>KK</SPAN><SPAN CLASS=S14>I</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>VLG</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S14>GA</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=S13>Y</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>GL</SPAN><SPAN CLASS=S13>W</SPAN><SPAN CLASS=S14>IP</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#666666">---------</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>IPVAI</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>A</SPAN><SPAN CLASS=S9>TS</SPAN><SPAN CLASS=S14>P</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#666666">-</SPAN><SPAN CLASS=S14>A</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>IL</SPAN><SPAN CLASS=S12>DE</SPAN><SPAN CLASS=S14>A</SPAN><SPAN CLASS=S13>Y</SPAN><SPAN CLASS=S14>VMA</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=S12>D</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S14>P</SPAN><SPAN CLASS=S13>H</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=S7>C</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S14>LLGI</SPAN><SPAN CLASS=S7>C</SPAN> 
  2 PR2_DROME    35.7%  <SPAN CLASS=S14>I</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S14>LG</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>GIV</SPAN><SPAN CLASS=S8>QQ</SPAN><SPAN CLASS=S14>GV</SPAN><SPAN CLASS=S13>W</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S12>E</SPAN><SPAN style="color:#666666">-----------</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S14>I</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S14>VAI</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S7>C</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S7>C</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S14>M</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S9>S</SPAN><SPAN style="color:#666666">-</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S14>PM</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>AAIM</SPAN><SPAN CLASS=S13>H</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S14>I</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S13>H</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S14>IV</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S13>Y</SPAN><SPAN CLASS=S14>GVV</SPAN> 
  3 ITK_HUMAN    32.9%  <SPAN CLASS=S14>L</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>IG</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>GLV</SPAN><SPAN CLASS=S13>H</SPAN><SPAN CLASS=S14>LG</SPAN><SPAN CLASS=S13>YW</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S8>N</SPAN><SPAN style="color:#666666">--------------</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S12>D</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>VAI</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S14>I</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>GAM</SPAN><SPAN CLASS=S9>S</SPAN><SPAN style="color:#666666">---</SPAN><SPAN CLASS=S12>EED</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>I</SPAN><SPAN CLASS=S12>EE</SPAN><SPAN CLASS=S14>A</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>VMM</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S13>H</SPAN><SPAN CLASS=S14>P</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>LV</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S13>Y</SPAN><SPAN CLASS=S14>GV</SPAN><SPAN CLASS=S7>C</SPAN> 
  4 PTK7_HUMAN   21.2%  <SPAN CLASS=S14>I</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S14>IGVG</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>GAVVLA</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>M</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S14>GL</SPAN><SPAN CLASS=S9>S</SPAN><SPAN style="color:#666666">-</SPAN><SPAN CLASS=T19>X</SPAN><SPAN CLASS=S14>LP</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S14>M</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S14>A</SPAN><SPAN CLASS=S12>D</SPAN><SPAN CLASS=S14>GVALVAV</SPAN><SPAN CLASS=S17>KK</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>P</SPAN><SPAN CLASS=S12>D</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S12>D</SPAN><SPAN style="color:#666666">-</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>VL</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S12>D</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>I</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>M</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S13>H</SPAN><SPAN CLASS=S12>D</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S14>IV</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S14>LLAI</SPAN><SPAN CLASS=S7>C</SPAN> 
  5 KIN31_CAEEL  31.5%  <SPAN CLASS=S14>V</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S17>KK</SPAN><SPAN CLASS=S14>LG</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>GA</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=S13>W</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>LL</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>IL</SPAN><SPAN CLASS=S12>D</SPAN><SPAN CLASS=S14>A</SPAN><SPAN style="color:#666666">-------</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S13>H</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S14>PVLVAV</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S14>A</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S14>M</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S14>I</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>IM</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>A</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S14>LM</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S12>D</SPAN><SPAN CLASS=S13>H</SPAN><SPAN CLASS=S14>I</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S14>VV</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S13>FF</SPAN><SPAN CLASS=S14>GVA</SPAN> 
  </PRE>


**Mode** ``identity``

You can colour only those residues that are identical to some reference
sequence (usually the query or first row) with::

  mview ... -coloring identity ...

to produce:

.. raw:: html

  <PRE>
  1 EGFR_HUMAN  100.0%  <SPAN CLASS=S13>F</SPAN><SPAN CLASS=S17>KK</SPAN><SPAN CLASS=S14>I</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>VLG</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S14>GA</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=S13>Y</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>GL</SPAN><SPAN CLASS=S13>W</SPAN><SPAN CLASS=S14>IP</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#666666">---------</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>IPVAI</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>A</SPAN><SPAN CLASS=S9>TS</SPAN><SPAN CLASS=S14>P</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#666666">-</SPAN><SPAN CLASS=S14>A</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>IL</SPAN><SPAN CLASS=S12>DE</SPAN><SPAN CLASS=S14>A</SPAN><SPAN CLASS=S13>Y</SPAN><SPAN CLASS=S14>VMA</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=S12>D</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S14>P</SPAN><SPAN CLASS=S13>H</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=S7>C</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S14>LLGI</SPAN><SPAN CLASS=S7>C</SPAN> 
  2 PR2_DROME    35.7%  <SPAN CLASS=T19>ISVN</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=T19>Q</SPAN><SPAN CLASS=S14>LG</SPAN><SPAN CLASS=T19>T</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T19>E</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T19>I</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=T19>QQ</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T19>V</SPAN><SPAN CLASS=S13>W</SPAN><SPAN CLASS=T19>SNGN</SPAN><SPAN CLASS=S12>E</SPAN><SPAN style="color:#666666">-----------</SPAN><SPAN CLASS=T19>R</SPAN><SPAN CLASS=S14>I</SPAN><SPAN CLASS=T19>Q</SPAN><SPAN CLASS=S14>VAI</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=T19>C</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=T19>CRERMQS</SPAN><SPAN style="color:#666666">-</SPAN><SPAN CLASS=T19>NPM</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=T19>F</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=T19>K</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>A</SPAN><SPAN CLASS=T19>AI</SPAN><SPAN CLASS=S14>M</SPAN><SPAN CLASS=T19>H</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=T19>IEHENIV</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=T19>Y</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T19>VV</SPAN> 
  3 ITK_HUMAN    32.9%  <SPAN CLASS=T19>LTFVQEI</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T19>Q</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T19>L</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=T19>HL</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T19>Y</SPAN><SPAN CLASS=S13>W</SPAN><SPAN CLASS=T19>LN</SPAN><SPAN style="color:#666666">--------------</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=T19>DK</SPAN><SPAN CLASS=S14>VAI</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=T19>TI</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=T19>GAMS</SPAN><SPAN style="color:#666666">---</SPAN><SPAN CLASS=T19>EEDFIE</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>A</SPAN><SPAN CLASS=T19>E</SPAN><SPAN CLASS=S14>VM</SPAN><SPAN CLASS=T19>MKLSH</SPAN><SPAN CLASS=S14>P</SPAN><SPAN CLASS=T19>KLVQ</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=T19>Y</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T19>V</SPAN><SPAN CLASS=S7>C</SPAN> 
  4 PTK7_HUMAN   21.2%  <SPAN CLASS=T19>IREV</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=T19>QI</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T19>V</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T19>Q</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T19>A</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=T19>VLAEMTGLS</SPAN><SPAN style="color:#666666">-</SPAN><SPAN CLASS=T19>XLPKGSMNADGVAL</SPAN><SPAN CLASS=S14>VA</SPAN><SPAN CLASS=T19>V</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=T19>K</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=T19>KPDV</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=T19>D</SPAN><SPAN style="color:#666666">-</SPAN><SPAN CLASS=T19>EVLQSFDK</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=T19>IKF</SPAN><SPAN CLASS=S14>M</SPAN><SPAN CLASS=T19>SQLQHDSIVQ</SPAN><SPAN CLASS=S14>LL</SPAN><SPAN CLASS=T19>A</SPAN><SPAN CLASS=S14>I</SPAN><SPAN CLASS=S7>C</SPAN> 
  5 KIN31_CAEEL  31.5%  <SPAN CLASS=T19>VELT</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=T19>K</SPAN><SPAN CLASS=S14>LG</SPAN><SPAN CLASS=T19>E</SPAN><SPAN CLASS=S14>GA</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T19>E</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=T19>W</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T19>KLLKILDA</SPAN><SPAN style="color:#666666">-------</SPAN><SPAN CLASS=T19>NHQPVL</SPAN><SPAN CLASS=S14>VA</SPAN><SPAN CLASS=T19>V</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=T19>TAKLESMT</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=T19>EQI</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>I</SPAN><SPAN CLASS=T19>MR</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>A</SPAN><SPAN CLASS=T19>RL</SPAN><SPAN CLASS=S14>M</SPAN><SPAN CLASS=T19>RNL</SPAN><SPAN CLASS=S12>D</SPAN><SPAN CLASS=T19>HIN</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=T19>VKFF</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T19>VA</SPAN> 
  </PRE>

or with respect to another row (let's use row 4)::

  mview ... -coloring identity -ref 4 ...

giving:

.. raw:: html

  <PRE>
  1 EGFR_HUMAN   21.2%  <SPAN CLASS=T19>FKKI</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=T19>VL</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T19>S</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T19>A</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T19>T</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=T19>YKGLWIPEGEK</SPAN><SPAN style="color:#666666">---------</SPAN><SPAN CLASS=T19>VKIP</SPAN><SPAN CLASS=S14>VA</SPAN><SPAN CLASS=T19>I</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=T19>E</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=T19>REAT</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=T19>PK</SPAN><SPAN style="color:#666666">-</SPAN><SPAN CLASS=T19>ANKEILD</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=T19>AYV</SPAN><SPAN CLASS=S14>M</SPAN><SPAN CLASS=T19>ASVDNPHVCR</SPAN><SPAN CLASS=S14>LL</SPAN><SPAN CLASS=T19>G</SPAN><SPAN CLASS=S14>I</SPAN><SPAN CLASS=S7>C</SPAN> 
  2 PR2_DROME    25.0%  <SPAN CLASS=S14>I</SPAN><SPAN CLASS=T19>SVN</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=T19>L</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T19>T</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T19>E</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T19>I</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=T19>QQGVWSNGNE</SPAN><SPAN style="color:#666666">-----------</SPAN><SPAN CLASS=T19>RIQ</SPAN><SPAN CLASS=S14>VA</SPAN><SPAN CLASS=T19>I</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=T19>C</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=T19>CRERMQS</SPAN><SPAN style="color:#666666">-</SPAN><SPAN CLASS=T19>NPME</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=T19>L</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=T19>AAI</SPAN><SPAN CLASS=S14>M</SPAN><SPAN CLASS=T19>HSIE</SPAN><SPAN CLASS=S13>H</SPAN><SPAN CLASS=T19>EN</SPAN><SPAN CLASS=S14>IV</SPAN><SPAN CLASS=T19>R</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=T19>YGVV</SPAN> 
  3 ITK_HUMAN    26.9%  <SPAN CLASS=T19>LTF</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=T19>QE</SPAN><SPAN CLASS=S14>IG</SPAN><SPAN CLASS=T19>S</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T19>L</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=T19>H</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=T19>GYWLN</SPAN><SPAN style="color:#666666">--------------</SPAN><SPAN CLASS=T19>KDK</SPAN><SPAN CLASS=S14>VA</SPAN><SPAN CLASS=T19>I</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=T19>TIREGAMS</SPAN><SPAN style="color:#666666">---</SPAN><SPAN CLASS=T19>EED</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=T19>IE</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=T19>AEV</SPAN><SPAN CLASS=S14>M</SPAN><SPAN CLASS=T19>MK</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=T19>S</SPAN><SPAN CLASS=S13>H</SPAN><SPAN CLASS=T19>PKL</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=T19>YGV</SPAN><SPAN CLASS=S7>C</SPAN> 
  4 PTK7_HUMAN1  00.0%  <SPAN CLASS=S14>I</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S14>IGVG</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>GAVVLA</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>M</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S14>GL</SPAN><SPAN CLASS=S9>S</SPAN><SPAN style="color:#666666">-</SPAN><SPAN CLASS=T19>X</SPAN><SPAN CLASS=S14>LP</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S14>M</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S14>A</SPAN><SPAN CLASS=S12>D</SPAN><SPAN CLASS=S14>GVALVAV</SPAN><SPAN CLASS=S17>KK</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>P</SPAN><SPAN CLASS=S12>D</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S12>D</SPAN><SPAN style="color:#666666">-</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>VL</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S12>D</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>I</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>M</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S13>H</SPAN><SPAN CLASS=S12>D</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S14>IV</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S14>LLAI</SPAN><SPAN CLASS=S7>C</SPAN> 
  5 KIN31_CAEEL  22.5%  <SPAN CLASS=T19>VELT</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=T19>KL</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T19>E</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T19>A</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T19>E</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=T19>WKGKLLKILDA</SPAN><SPAN style="color:#666666">-------</SPAN><SPAN CLASS=T19>NHQPV</SPAN><SPAN CLASS=S14>LVAV</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=T19>TA</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=T19>LESMTK</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=T19>QIKEIMR</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=T19>ARL</SPAN><SPAN CLASS=S14>M</SPAN><SPAN CLASS=T19>RN</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=T19>D</SPAN><SPAN CLASS=S13>H</SPAN><SPAN CLASS=T19>INV</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=T19>KFFGVA</SPAN> 
  </PRE>

in which also you see that the percent identity calculations have been
recomputed with respect to the new row of interest.


**Mode** ``mismatch``

Behaves like ``identity`` mode, but colours only those residues that differ
from the reference sequence (the query or first row unless specified
otherwise) with::

  mview ... -coloring mismatch ...

to produce:

.. raw:: html

  <PRE>
  1 EGFR_HUMAN  100.0%  <SPAN style="color:#666666">FKKIKVLGSGAFGTVYKGLWIPEGEK---------VKIPVAIKELREATSPK-ANKEILDEAYVMASVDNPHVCRLLGIC</SPAN> 
  2 PR2_DROME    35.7%  <SPAN CLASS=S14>I</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=S8>N</SPAN><SPAN style="color:#666666">K</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN style="color:#666666">LG</SPAN><SPAN CLASS=S9>T</SPAN><SPAN style="color:#666666">G</SPAN><SPAN CLASS=S12>E</SPAN><SPAN style="color:#666666">FG</SPAN><SPAN CLASS=S14>I</SPAN><SPAN style="color:#666666">V</SPAN><SPAN CLASS=S8>QQ</SPAN><SPAN style="color:#666666">G</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">W</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=S8>N</SPAN><SPAN style="color:#666666">E-----------</SPAN><SPAN CLASS=S17>R</SPAN><SPAN style="color:#666666">I</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN style="color:#666666">VAIK</SPAN><SPAN CLASS=S7>C</SPAN><SPAN style="color:#666666">L</SPAN><SPAN CLASS=S7>C</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S14>M</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S9>S</SPAN><SPAN style="color:#666666">-</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S14>PM</SPAN><SPAN style="color:#666666">E</SPAN><SPAN CLASS=S13>F</SPAN><SPAN style="color:#666666">L</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#666666">EA</SPAN><SPAN CLASS=S14>AI</SPAN><SPAN style="color:#666666">M</SPAN><SPAN CLASS=S13>H</SPAN><SPAN style="color:#666666">S</SPAN><SPAN CLASS=S14>I</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S13>H</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S14>IV</SPAN><SPAN style="color:#666666">RL</SPAN><SPAN CLASS=S13>Y</SPAN><SPAN style="color:#666666">G</SPAN><SPAN CLASS=S14>VV</SPAN> 
  3 ITK_HUMAN    32.9%  <SPAN CLASS=S14>L</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>I</SPAN><SPAN style="color:#666666">GSG</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN style="color:#666666">FG</SPAN><SPAN CLASS=S14>L</SPAN><SPAN style="color:#666666">V</SPAN><SPAN CLASS=S13>H</SPAN><SPAN CLASS=S14>L</SPAN><SPAN style="color:#666666">G</SPAN><SPAN CLASS=S13>Y</SPAN><SPAN style="color:#666666">W</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S8>N</SPAN><SPAN style="color:#666666">--------------K</SPAN><SPAN CLASS=S12>D</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#666666">VAIK</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S14>I</SPAN><SPAN style="color:#666666">RE</SPAN><SPAN CLASS=S14>GAM</SPAN><SPAN CLASS=S9>S</SPAN><SPAN style="color:#666666">---</SPAN><SPAN CLASS=S12>EED</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>I</SPAN><SPAN CLASS=S12>E</SPAN><SPAN style="color:#666666">EA</SPAN><SPAN CLASS=S12>E</SPAN><SPAN style="color:#666666">VM</SPAN><SPAN CLASS=S14>M</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S13>H</SPAN><SPAN style="color:#666666">P</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>LV</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN style="color:#666666">L</SPAN><SPAN CLASS=S13>Y</SPAN><SPAN style="color:#666666">G</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">C</SPAN> 
  4 PTK7_HUMAN   21.2%  <SPAN CLASS=S14>I</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">K</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S14>I</SPAN><SPAN style="color:#666666">G</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">G</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN style="color:#666666">FG</SPAN><SPAN CLASS=S14>A</SPAN><SPAN style="color:#666666">V</SPAN><SPAN CLASS=S14>VLA</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>M</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S14>GL</SPAN><SPAN CLASS=S9>S</SPAN><SPAN style="color:#666666">-</SPAN><SPAN CLASS=T19>X</SPAN><SPAN CLASS=S14>LP</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S14>M</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S14>A</SPAN><SPAN CLASS=S12>D</SPAN><SPAN CLASS=S14>GVAL</SPAN><SPAN style="color:#666666">VA</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">K</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#666666">L</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>P</SPAN><SPAN CLASS=S12>D</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">S</SPAN><SPAN CLASS=S12>D</SPAN><SPAN style="color:#666666">-</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>VL</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S12>D</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#666666">E</SPAN><SPAN CLASS=S14>I</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S13>F</SPAN><SPAN style="color:#666666">M</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S13>H</SPAN><SPAN CLASS=S12>D</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S14>IV</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN style="color:#666666">LL</SPAN><SPAN CLASS=S14>A</SPAN><SPAN style="color:#666666">IC</SPAN> 
  5 KIN31_CAEEL  31.5%  <SPAN CLASS=S14>V</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S9>T</SPAN><SPAN style="color:#666666">K</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#666666">LG</SPAN><SPAN CLASS=S12>E</SPAN><SPAN style="color:#666666">GAFG</SPAN><SPAN CLASS=S12>E</SPAN><SPAN style="color:#666666">V</SPAN><SPAN CLASS=S13>W</SPAN><SPAN style="color:#666666">KG</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>LL</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>IL</SPAN><SPAN CLASS=S12>D</SPAN><SPAN CLASS=S14>A</SPAN><SPAN style="color:#666666">-------</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S13>H</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S14>PVL</SPAN><SPAN style="color:#666666">VA</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">K</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S14>A</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S14>M</SPAN><SPAN CLASS=S9>T</SPAN><SPAN style="color:#666666">K</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S14>I</SPAN><SPAN style="color:#666666">KEI</SPAN><SPAN CLASS=S14>M</SPAN><SPAN CLASS=S17>R</SPAN><SPAN style="color:#666666">EA</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S14>L</SPAN><SPAN style="color:#666666">M</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S14>L</SPAN><SPAN style="color:#666666">D</SPAN><SPAN CLASS=S13>H</SPAN><SPAN CLASS=S14>I</SPAN><SPAN CLASS=S8>N</SPAN><SPAN style="color:#666666">V</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S13>FF</SPAN><SPAN style="color:#666666">G</SPAN><SPAN CLASS=S14>VA</SPAN> 
  </PRE>

**Using a single colour**

That's using the default protein colourmap and rather difficult to see, so
let's mark all mismatched residues in red::

  mview ... -coloring mismatch -colormap red

to produce:

.. raw:: html

  <PRE>
  1 EGFR_HUMAN  100.0%  <SPAN style="color:#666666">FKKIKVLGSGAFGTVYKGLWIPEGEK---------VKIPVAIKELREATSPK-ANKEILDEAYVMASVDNPHVCRLLGIC</SPAN> 
  2 PR2_DROME    35.7%  <SPAN CLASS=S2>ISVN</SPAN><SPAN style="color:#666666">K</SPAN><SPAN CLASS=S2>Q</SPAN><SPAN style="color:#666666">LG</SPAN><SPAN CLASS=S2>T</SPAN><SPAN style="color:#666666">G</SPAN><SPAN CLASS=S2>E</SPAN><SPAN style="color:#666666">FG</SPAN><SPAN CLASS=S2>I</SPAN><SPAN style="color:#666666">V</SPAN><SPAN CLASS=S2>QQ</SPAN><SPAN style="color:#666666">G</SPAN><SPAN CLASS=S2>V</SPAN><SPAN style="color:#666666">W</SPAN><SPAN CLASS=S2>SNGN</SPAN><SPAN style="color:#666666">E-----------</SPAN><SPAN CLASS=S2>R</SPAN><SPAN style="color:#666666">I</SPAN><SPAN CLASS=S2>Q</SPAN><SPAN style="color:#666666">VAIK</SPAN><SPAN CLASS=S2>C</SPAN><SPAN style="color:#666666">L</SPAN><SPAN CLASS=S2>CRERMQS</SPAN><SPAN style="color:#666666">-</SPAN><SPAN CLASS=S2>NPM</SPAN><SPAN style="color:#666666">E</SPAN><SPAN CLASS=S2>F</SPAN><SPAN style="color:#666666">L</SPAN><SPAN CLASS=S2>K</SPAN><SPAN style="color:#666666">EA</SPAN><SPAN CLASS=S2>AI</SPAN><SPAN style="color:#666666">M</SPAN><SPAN CLASS=S2>H</SPAN><SPAN style="color:#666666">S</SPAN><SPAN CLASS=S2>IEHENIV</SPAN><SPAN style="color:#666666">RL</SPAN><SPAN CLASS=S2>Y</SPAN><SPAN style="color:#666666">G</SPAN><SPAN CLASS=S2>VV</SPAN> 
  3 ITK_HUMAN    32.9%  <SPAN CLASS=S2>LTFVQEI</SPAN><SPAN style="color:#666666">GSG</SPAN><SPAN CLASS=S2>Q</SPAN><SPAN style="color:#666666">FG</SPAN><SPAN CLASS=S2>L</SPAN><SPAN style="color:#666666">V</SPAN><SPAN CLASS=S2>HL</SPAN><SPAN style="color:#666666">G</SPAN><SPAN CLASS=S2>Y</SPAN><SPAN style="color:#666666">W</SPAN><SPAN CLASS=S2>LN</SPAN><SPAN style="color:#666666">--------------K</SPAN><SPAN CLASS=S2>DK</SPAN><SPAN style="color:#666666">VAIK</SPAN><SPAN CLASS=S2>TI</SPAN><SPAN style="color:#666666">RE</SPAN><SPAN CLASS=S2>GAMS</SPAN><SPAN style="color:#666666">---</SPAN><SPAN CLASS=S2>EEDFIE</SPAN><SPAN style="color:#666666">EA</SPAN><SPAN CLASS=S2>E</SPAN><SPAN style="color:#666666">VM</SPAN><SPAN CLASS=S2>MKLSH</SPAN><SPAN style="color:#666666">P</SPAN><SPAN CLASS=S2>KLVQ</SPAN><SPAN style="color:#666666">L</SPAN><SPAN CLASS=S2>Y</SPAN><SPAN style="color:#666666">G</SPAN><SPAN CLASS=S2>V</SPAN><SPAN style="color:#666666">C</SPAN> 
  4 PTK7_HUMAN   21.2%  <SPAN CLASS=S2>IREV</SPAN><SPAN style="color:#666666">K</SPAN><SPAN CLASS=S2>QI</SPAN><SPAN style="color:#666666">G</SPAN><SPAN CLASS=S2>V</SPAN><SPAN style="color:#666666">G</SPAN><SPAN CLASS=S2>Q</SPAN><SPAN style="color:#666666">FG</SPAN><SPAN CLASS=S2>A</SPAN><SPAN style="color:#666666">V</SPAN><SPAN CLASS=S2>VLAEMTGLS</SPAN><SPAN style="color:#666666">-</SPAN><SPAN CLASS=S2>XLPKGSMNADGVAL</SPAN><SPAN style="color:#666666">VA</SPAN><SPAN CLASS=S2>V</SPAN><SPAN style="color:#666666">K</SPAN><SPAN CLASS=S2>K</SPAN><SPAN style="color:#666666">L</SPAN><SPAN CLASS=S2>KPDV</SPAN><SPAN style="color:#666666">S</SPAN><SPAN CLASS=S2>D</SPAN><SPAN style="color:#666666">-</SPAN><SPAN CLASS=S2>EVLQSFDK</SPAN><SPAN style="color:#666666">E</SPAN><SPAN CLASS=S2>IKF</SPAN><SPAN style="color:#666666">M</SPAN><SPAN CLASS=S2>SQLQHDSIVQ</SPAN><SPAN style="color:#666666">LL</SPAN><SPAN CLASS=S2>A</SPAN><SPAN style="color:#666666">IC</SPAN> 
  5 KIN31_CAEEL  31.5%  <SPAN CLASS=S2>VELT</SPAN><SPAN style="color:#666666">K</SPAN><SPAN CLASS=S2>K</SPAN><SPAN style="color:#666666">LG</SPAN><SPAN CLASS=S2>E</SPAN><SPAN style="color:#666666">GAFG</SPAN><SPAN CLASS=S2>E</SPAN><SPAN style="color:#666666">V</SPAN><SPAN CLASS=S2>W</SPAN><SPAN style="color:#666666">KG</SPAN><SPAN CLASS=S2>KLLKILDA</SPAN><SPAN style="color:#666666">-------</SPAN><SPAN CLASS=S2>NHQPVL</SPAN><SPAN style="color:#666666">VA</SPAN><SPAN CLASS=S2>V</SPAN><SPAN style="color:#666666">K</SPAN><SPAN CLASS=S2>TAKLESMT</SPAN><SPAN style="color:#666666">K</SPAN><SPAN CLASS=S2>EQI</SPAN><SPAN style="color:#666666">KEI</SPAN><SPAN CLASS=S2>MR</SPAN><SPAN style="color:#666666">EA</SPAN><SPAN CLASS=S2>RL</SPAN><SPAN style="color:#666666">M</SPAN><SPAN CLASS=S2>RNL</SPAN><SPAN style="color:#666666">D</SPAN><SPAN CLASS=S2>HIN</SPAN><SPAN style="color:#666666">V</SPAN><SPAN CLASS=S2>VKFF</SPAN><SPAN style="color:#666666">G</SPAN><SPAN CLASS=S2>VA</SPAN> 
  </PRE>

This approach of using a single colour works with any of the coloring modes
listed above. To see colours and colormaps use ``mview -listcolors``.

You can add new colours or build your own multicoloured specialist
colourmap. For example, you might want certain important mismatched residues
showing up in one colour against a ground colour of all the other mismatches
(see :ref:`ref_colourmaps`).


**Mode** ``consensus``

This mode uses the currently selected alignment colourmap to colour only those
residues assigned to a consensus class for each column (see
:ref:`ref_consensus_sequences`). The consensus threshold defaults to 70% and
and may be set to another value with the ``-threshold`` option. In the
following example we add a single consensus line and set the same threshold
for both consensus calculations (they are independent) to 90%::

  mview ... -coloring consensus -threshold 90 ... -consensus on -con_threshold 90 ...

gives:

.. raw:: html

  <PRE>
  1 EGFR_HUMAN    100.0%  <SPAN CLASS=S13>F</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#666666">KI</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#666666">V</SPAN><SPAN CLASS=S14>LG</SPAN><SPAN style="color:#666666">S</SPAN><SPAN CLASS=S14>GA</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">T</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">YK</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">L</SPAN><SPAN CLASS=S13>W</SPAN><SPAN style="color:#666666">IPEGEK---------VKIP</SPAN><SPAN CLASS=S14>VAI</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S17>R</SPAN><SPAN style="color:#666666">E</SPAN><SPAN CLASS=S14>A</SPAN><SPAN style="color:#666666">TSPK-ANK</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>I</SPAN><SPAN style="color:#666666">L</SPAN><SPAN CLASS=S12>DE</SPAN><SPAN CLASS=S14>A</SPAN><SPAN style="color:#666666">Y</SPAN><SPAN CLASS=S14>VM</SPAN><SPAN style="color:#666666">A</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=S12>D</SPAN><SPAN CLASS=S8>N</SPAN><SPAN style="color:#666666">P</SPAN><SPAN CLASS=S13>H</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=S7>C</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S14>LLGI</SPAN><SPAN CLASS=S7>C</SPAN> 
  2 PR2_DROME      35.7%  <SPAN CLASS=S14>I</SPAN><SPAN CLASS=S9>S</SPAN><SPAN style="color:#666666">VN</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#666666">Q</SPAN><SPAN CLASS=S14>LG</SPAN><SPAN style="color:#666666">T</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">I</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">QQ</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">V</SPAN><SPAN CLASS=S13>W</SPAN><SPAN style="color:#666666">SNGNE-----------RIQ</SPAN><SPAN CLASS=S14>VAI</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S7>C</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S7>C</SPAN><SPAN style="color:#666666">R</SPAN><SPAN CLASS=S12>E</SPAN><SPAN style="color:#666666">RMQS-NPM</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S13>F</SPAN><SPAN style="color:#666666">L</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>A</SPAN><SPAN style="color:#666666">A</SPAN><SPAN CLASS=S14>IM</SPAN><SPAN style="color:#666666">H</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S14>I</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S13>H</SPAN><SPAN style="color:#666666">E</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S14>IV</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S13>Y</SPAN><SPAN CLASS=S14>GVV</SPAN> 
  3 ITK_HUMAN      32.9%  <SPAN CLASS=S14>L</SPAN><SPAN CLASS=S9>T</SPAN><SPAN style="color:#666666">FV</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN style="color:#666666">E</SPAN><SPAN CLASS=S14>IG</SPAN><SPAN style="color:#666666">S</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">L</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">HL</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">Y</SPAN><SPAN CLASS=S13>W</SPAN><SPAN style="color:#666666">LN--------------KDK</SPAN><SPAN CLASS=S14>VAI</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S14>I</SPAN><SPAN CLASS=S17>R</SPAN><SPAN style="color:#666666">E</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">AMS---EE</SPAN><SPAN CLASS=S12>D</SPAN><SPAN CLASS=S13>F</SPAN><SPAN style="color:#666666">I</SPAN><SPAN CLASS=S12>EE</SPAN><SPAN CLASS=S14>A</SPAN><SPAN style="color:#666666">E</SPAN><SPAN CLASS=S14>VM</SPAN><SPAN style="color:#666666">M</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S13>H</SPAN><SPAN style="color:#666666">P</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S14>LV</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S13>Y</SPAN><SPAN CLASS=S14>GV</SPAN><SPAN CLASS=S7>C</SPAN> 
  4 PTK7_HUMAN     21.2%  <SPAN CLASS=S14>I</SPAN><SPAN CLASS=S17>R</SPAN><SPAN style="color:#666666">EV</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#666666">Q</SPAN><SPAN CLASS=S14>IG</SPAN><SPAN style="color:#666666">V</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">A</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">VL</SPAN><SPAN CLASS=S14>A</SPAN><SPAN style="color:#666666">E</SPAN><SPAN CLASS=S14>M</SPAN><SPAN style="color:#666666">TGLS-XLPKGSMNADGVAL</SPAN><SPAN CLASS=S14>VAV</SPAN><SPAN CLASS=S17>KK</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#666666">P</SPAN><SPAN CLASS=S12>D</SPAN><SPAN style="color:#666666">VSD-EVLQ</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S13>F</SPAN><SPAN style="color:#666666">D</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>I</SPAN><SPAN style="color:#666666">K</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>M</SPAN><SPAN style="color:#666666">S</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S13>H</SPAN><SPAN style="color:#666666">D</SPAN><SPAN CLASS=S9>S</SPAN><SPAN CLASS=S14>IV</SPAN><SPAN CLASS=S8>Q</SPAN><SPAN CLASS=S14>LLAI</SPAN><SPAN CLASS=S7>C</SPAN> 
  5 KIN31_CAEEL    31.5%  <SPAN CLASS=S14>V</SPAN><SPAN CLASS=S12>E</SPAN><SPAN style="color:#666666">LT</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#666666">K</SPAN><SPAN CLASS=S14>LG</SPAN><SPAN style="color:#666666">E</SPAN><SPAN CLASS=S14>GA</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">E</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">WK</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">K</SPAN><SPAN CLASS=S14>L</SPAN><SPAN style="color:#666666">LKILDA-------NHQPVL</SPAN><SPAN CLASS=S14>VAV</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S9>T</SPAN><SPAN CLASS=S14>A</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#666666">L</SPAN><SPAN CLASS=S12>E</SPAN><SPAN style="color:#666666">SMTKEQIK</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>I</SPAN><SPAN style="color:#666666">M</SPAN><SPAN CLASS=S17>R</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>A</SPAN><SPAN style="color:#666666">R</SPAN><SPAN CLASS=S14>LM</SPAN><SPAN style="color:#666666">R</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=S12>D</SPAN><SPAN CLASS=S13>H</SPAN><SPAN style="color:#666666">I</SPAN><SPAN CLASS=S8>N</SPAN><SPAN CLASS=S14>VV</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=S13>FF</SPAN><SPAN CLASS=S14>GVA</SPAN> 
    consensus/90%         hp..p.lG.GtFG.V..u.h...................VAlKphp.t........ph.cEh.hM.plpp.plsphhuls 
  </PRE>

Notice that the coloured columns correspond to the consensus features (i.e.,
not wildcards or gaps). In each column, the residues that contribute to that
consensus class have been coloured using the prevailing alignment colourmap
(see :ref:`ref_alignment_colouring`), which is the default one used in the
other examples in this section.


**Mode** ``group``

The last mode works like the consensus colouring mode, but gives the residues
in a column a uniform colour defined for that consensus class (see
:ref:`ref_consensus_colouring`)::

  mview ... -coloring group -threshold 90 ... -consensus on -con_threshold 90 ...

yields:

.. raw:: html

  <PRE>
  1 EGFR_HUMAN    100.0%  <SPAN CLASS=T14>F</SPAN><SPAN CLASS=T9>K</SPAN><SPAN style="color:#666666">KI</SPAN><SPAN CLASS=T9>K</SPAN><SPAN style="color:#666666">V</SPAN><SPAN CLASS=T14>L</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">S</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T14>A</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">T</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">YK</SPAN><SPAN CLASS=T14>G</SPAN><SPAN style="color:#666666">L</SPAN><SPAN CLASS=T14>W</SPAN><SPAN style="color:#666666">IPEGEK---------VKIP</SPAN><SPAN CLASS=S14>VA</SPAN><SPAN CLASS=T14>I</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=T9>E</SPAN><SPAN CLASS=T14>L</SPAN><SPAN CLASS=T9>R</SPAN><SPAN style="color:#666666">E</SPAN><SPAN CLASS=T14>A</SPAN><SPAN style="color:#666666">TSPK-ANK</SPAN><SPAN CLASS=T9>E</SPAN><SPAN CLASS=T14>I</SPAN><SPAN style="color:#666666">L</SPAN><SPAN CLASS=T8>D</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=T14>A</SPAN><SPAN style="color:#666666">Y</SPAN><SPAN CLASS=T14>V</SPAN><SPAN CLASS=S14>M</SPAN><SPAN style="color:#666666">A</SPAN><SPAN CLASS=T9>S</SPAN><SPAN CLASS=T14>V</SPAN><SPAN CLASS=T9>DN</SPAN><SPAN style="color:#666666">P</SPAN><SPAN CLASS=T9>H</SPAN><SPAN CLASS=T14>VC</SPAN><SPAN CLASS=T9>R</SPAN><SPAN CLASS=T14>LLGIC</SPAN> 
  2 PR2_DROME      35.7%  <SPAN CLASS=T14>I</SPAN><SPAN CLASS=T9>S</SPAN><SPAN style="color:#666666">VN</SPAN><SPAN CLASS=T9>K</SPAN><SPAN style="color:#666666">Q</SPAN><SPAN CLASS=T14>L</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">T</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T14>E</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">I</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">QQ</SPAN><SPAN CLASS=T14>G</SPAN><SPAN style="color:#666666">V</SPAN><SPAN CLASS=T14>W</SPAN><SPAN style="color:#666666">SNGNE-----------RIQ</SPAN><SPAN CLASS=S14>VA</SPAN><SPAN CLASS=T14>I</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=T9>C</SPAN><SPAN CLASS=T14>L</SPAN><SPAN CLASS=T9>C</SPAN><SPAN style="color:#666666">R</SPAN><SPAN CLASS=T14>E</SPAN><SPAN style="color:#666666">RMQS-NPM</SPAN><SPAN CLASS=T9>E</SPAN><SPAN CLASS=T14>F</SPAN><SPAN style="color:#666666">L</SPAN><SPAN CLASS=T8>K</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=T14>A</SPAN><SPAN style="color:#666666">A</SPAN><SPAN CLASS=T14>I</SPAN><SPAN CLASS=S14>M</SPAN><SPAN style="color:#666666">H</SPAN><SPAN CLASS=T9>S</SPAN><SPAN CLASS=T14>I</SPAN><SPAN CLASS=T9>EH</SPAN><SPAN style="color:#666666">E</SPAN><SPAN CLASS=T9>N</SPAN><SPAN CLASS=T14>IV</SPAN><SPAN CLASS=T9>R</SPAN><SPAN CLASS=T14>LYGVV</SPAN> 
  3 ITK_HUMAN      32.9%  <SPAN CLASS=T14>L</SPAN><SPAN CLASS=T9>T</SPAN><SPAN style="color:#666666">FV</SPAN><SPAN CLASS=T9>Q</SPAN><SPAN style="color:#666666">E</SPAN><SPAN CLASS=T14>I</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">S</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T14>Q</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">L</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">HL</SPAN><SPAN CLASS=T14>G</SPAN><SPAN style="color:#666666">Y</SPAN><SPAN CLASS=T14>W</SPAN><SPAN style="color:#666666">LN--------------KDK</SPAN><SPAN CLASS=S14>VA</SPAN><SPAN CLASS=T14>I</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=T9>T</SPAN><SPAN CLASS=T14>I</SPAN><SPAN CLASS=T9>R</SPAN><SPAN style="color:#666666">E</SPAN><SPAN CLASS=T14>G</SPAN><SPAN style="color:#666666">AMS---EE</SPAN><SPAN CLASS=T9>D</SPAN><SPAN CLASS=T14>F</SPAN><SPAN style="color:#666666">I</SPAN><SPAN CLASS=T8>E</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=T14>A</SPAN><SPAN style="color:#666666">E</SPAN><SPAN CLASS=T14>V</SPAN><SPAN CLASS=S14>M</SPAN><SPAN style="color:#666666">M</SPAN><SPAN CLASS=T9>K</SPAN><SPAN CLASS=T14>L</SPAN><SPAN CLASS=T9>SH</SPAN><SPAN style="color:#666666">P</SPAN><SPAN CLASS=T9>K</SPAN><SPAN CLASS=T14>LV</SPAN><SPAN CLASS=T9>Q</SPAN><SPAN CLASS=T14>LYGVC</SPAN> 
  4 PTK7_HUMAN     21.2%  <SPAN CLASS=T14>I</SPAN><SPAN CLASS=T9>R</SPAN><SPAN style="color:#666666">EV</SPAN><SPAN CLASS=T9>K</SPAN><SPAN style="color:#666666">Q</SPAN><SPAN CLASS=T14>I</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">V</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T14>Q</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">A</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">VL</SPAN><SPAN CLASS=T14>A</SPAN><SPAN style="color:#666666">E</SPAN><SPAN CLASS=T14>M</SPAN><SPAN style="color:#666666">TGLS-XLPKGSMNADGVAL</SPAN><SPAN CLASS=S14>VA</SPAN><SPAN CLASS=T14>V</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=T9>K</SPAN><SPAN CLASS=T14>L</SPAN><SPAN CLASS=T9>K</SPAN><SPAN style="color:#666666">P</SPAN><SPAN CLASS=T14>D</SPAN><SPAN style="color:#666666">VSD-EVLQ</SPAN><SPAN CLASS=T9>S</SPAN><SPAN CLASS=T14>F</SPAN><SPAN style="color:#666666">D</SPAN><SPAN CLASS=T8>K</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=T14>I</SPAN><SPAN style="color:#666666">K</SPAN><SPAN CLASS=T14>F</SPAN><SPAN CLASS=S14>M</SPAN><SPAN style="color:#666666">S</SPAN><SPAN CLASS=T9>Q</SPAN><SPAN CLASS=T14>L</SPAN><SPAN CLASS=T9>QH</SPAN><SPAN style="color:#666666">D</SPAN><SPAN CLASS=T9>S</SPAN><SPAN CLASS=T14>IV</SPAN><SPAN CLASS=T9>Q</SPAN><SPAN CLASS=T14>LLAIC</SPAN> 
  5 KIN31_CAEEL    31.5%  <SPAN CLASS=T14>V</SPAN><SPAN CLASS=T9>E</SPAN><SPAN style="color:#666666">LT</SPAN><SPAN CLASS=T9>K</SPAN><SPAN style="color:#666666">K</SPAN><SPAN CLASS=T14>L</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">E</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T14>A</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">E</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">WK</SPAN><SPAN CLASS=T14>G</SPAN><SPAN style="color:#666666">K</SPAN><SPAN CLASS=T14>L</SPAN><SPAN style="color:#666666">LKILDA-------NHQPVL</SPAN><SPAN CLASS=S14>VA</SPAN><SPAN CLASS=T14>V</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=T9>T</SPAN><SPAN CLASS=T14>A</SPAN><SPAN CLASS=T9>K</SPAN><SPAN style="color:#666666">L</SPAN><SPAN CLASS=T14>E</SPAN><SPAN style="color:#666666">SMTKEQIK</SPAN><SPAN CLASS=T9>E</SPAN><SPAN CLASS=T14>I</SPAN><SPAN style="color:#666666">M</SPAN><SPAN CLASS=T8>R</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=T14>A</SPAN><SPAN style="color:#666666">R</SPAN><SPAN CLASS=T14>L</SPAN><SPAN CLASS=S14>M</SPAN><SPAN style="color:#666666">R</SPAN><SPAN CLASS=T9>N</SPAN><SPAN CLASS=T14>L</SPAN><SPAN CLASS=T9>DH</SPAN><SPAN style="color:#666666">I</SPAN><SPAN CLASS=T9>N</SPAN><SPAN CLASS=T14>VV</SPAN><SPAN CLASS=T9>K</SPAN><SPAN CLASS=T14>FFGVA</SPAN> 
    consensus/90%         hp..p.lG.GtFG.V..u.h...................VAlKphp.t........ph.cEh.hM.plpp.plsphhuls 
  </PRE>

As in the last example, the coloured columns correspond to the consensus
features (i.e., not wildcards or gaps). In each column, the residues that
contribute to that consensus class have been coloured using a single colour
defined for that consensus class (see :ref:`ref_consensus_colouring`), and
conserved residues (at least 90% of a column) are given a solid coloured
background for emphasis.

The choice of consensus classes may be changed using the ``-groupmap name``
option, where ``name`` is the name of a consensus pattern. These can be listed
using the ``-listgroups`` option (see :ref:`ref_changeing_consensus_patterns`).

Note: it is also possible to colour the consensus sequences themselves
independently of the alignment (see :ref:`ref_consensus_colouring`).


Colouring only conserved residues
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The colouring of an alignment under the ``consensus`` or ``group`` colouring
modes (see :ref:`ref_alignment_colouring`) can be tuned to ignore the
consensus classes with ``-ignore class`` for the purposes of colouring::

  mview ... -coloring group -threshold 90 ... -consensus on -con_threshold 90 ... -ignore class

gives:

.. raw:: html

  <PRE>
  1 EGFR_HUMAN    100.0%  <SPAN style="color:#666666">FKKIKVL</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">S</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">A</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">T</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">YKGLWIPEGEK---------VKIP</SPAN><SPAN CLASS=S14>VA</SPAN><SPAN style="color:#666666">I</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#666666">ELREATSPK-ANKEILD</SPAN><SPAN CLASS=S12>E</SPAN><SPAN style="color:#666666">AYV</SPAN><SPAN CLASS=S14>M</SPAN><SPAN style="color:#666666">ASVDNPHVCRLLGIC</SPAN> 
  2 PR2_DROME      35.7%  <SPAN style="color:#666666">ISVNKQL</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">T</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">E</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">I</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">QQGVWSNGNE-----------RIQ</SPAN><SPAN CLASS=S14>VA</SPAN><SPAN style="color:#666666">I</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#666666">CLCRERMQS-NPMEFLK</SPAN><SPAN CLASS=S12>E</SPAN><SPAN style="color:#666666">AAI</SPAN><SPAN CLASS=S14>M</SPAN><SPAN style="color:#666666">HSIEHENIVRLYGVV</SPAN> 
  3 ITK_HUMAN      32.9%  <SPAN style="color:#666666">LTFVQEI</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">S</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">Q</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">L</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">HLGYWLN--------------KDK</SPAN><SPAN CLASS=S14>VA</SPAN><SPAN style="color:#666666">I</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#666666">TIREGAMS---EEDFIE</SPAN><SPAN CLASS=S12>E</SPAN><SPAN style="color:#666666">AEV</SPAN><SPAN CLASS=S14>M</SPAN><SPAN style="color:#666666">MKLSHPKLVQLYGVC</SPAN> 
  4 PTK7_HUMAN     21.2%  <SPAN style="color:#666666">IREVKQI</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">V</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">Q</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">A</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">VLAEMTGLS-XLPKGSMNADGVAL</SPAN><SPAN CLASS=S14>VA</SPAN><SPAN style="color:#666666">V</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#666666">KLKPDVSD-EVLQSFDK</SPAN><SPAN CLASS=S12>E</SPAN><SPAN style="color:#666666">IKF</SPAN><SPAN CLASS=S14>M</SPAN><SPAN style="color:#666666">SQLQHDSIVQLLAIC</SPAN> 
  5 KIN31_CAEEL    31.5%  <SPAN style="color:#666666">VELTKKL</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">E</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">A</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">E</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">WKGKLLKILDA-------NHQPVL</SPAN><SPAN CLASS=S14>VA</SPAN><SPAN style="color:#666666">V</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#666666">TAKLESMTKEQIKEIMR</SPAN><SPAN CLASS=S12>E</SPAN><SPAN style="color:#666666">ARL</SPAN><SPAN CLASS=S14>M</SPAN><SPAN style="color:#666666">RNLDHINVVKFFGVA</SPAN> 
    consensus/90%         hp..p.lG.GtFG.V..u.h...................VAlKphp.t........ph.cEh.hM.plpp.plsphhuls 
  </PRE>

which highlights the conserved residues (at least 90% of a column) in the
alignment by applying the default consensus group colouring scheme to them.


.. _ref_consensus_colouring:

Consensus colouring
^^^^^^^^^^^^^^^^^^^

The consensus lines may be coloured independently of the alignment using the
``-con_coloring`` option which takes two modes: ``any``, ``identity``.

Consider the following alignment:

.. raw:: html

  <PRE>
                          1 [        .         .         .         .         :         .         .         ] 80
  1 EGFR_HUMAN    100.0%    FKKIKVLGSGAFGTVYKGLWIPEGEK---------VKIPVAIKELREATSPK-ANKEILDEAYVMASVDNPHVCRLLGIC   
  2 PR2_DROME      35.7%    ISVNKQLGTGEFGIVQQGVWSNGNE-----------RIQVAIKCLCRERMQS-NPMEFLKEAAIMHSIEHENIVRLYGVV   
  3 ITK_HUMAN      32.9%    LTFVQEIGSGQFGLVHLGYWLN--------------KDKVAIKTIREGAMS---EEDFIEEAEVMMKLSHPKLVQLYGVC   
  4 PTK7_HUMAN     21.2%    IREVKQIGVGQFGAVVLAEMTGLS-XLPKGSMNADGVALVAVKKLKPDVSD-EVLQSFDKEIKFMSQLQHDSIVQLLAIC   
  5 KIN31_CAEEL    31.5%    VELTKKLGEGAFGEVWKGKLLKILDA-------NHQPVLVAVKTAKLESMTKEQIKEIMREARLMRNLDHINVVKFFGVA   
  </PRE>


**Mode** ``any``

The simplest is to colour every consensus symbol according to the currently
selected consensus colourmap::

  mview ... -consensus on -con_coloring any ...

gives:

.. raw:: html

  <PRE>
    consensus/100%         <SPAN CLASS=T14>h</SPAN><SPAN CLASS=T9>p</SPAN><SPAN style="color:#666666">..</SPAN><SPAN CLASS=T9>p</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=T14>l</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T14>t</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">..</SPAN><SPAN CLASS=T14>u</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=T14>h</SPAN><SPAN style="color:#666666">...................</SPAN><SPAN CLASS=S14>VA</SPAN><SPAN CLASS=T14>l</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=T9>p</SPAN><SPAN CLASS=T14>h</SPAN><SPAN CLASS=T9>p</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=T14>t</SPAN><SPAN style="color:#666666">........</SPAN><SPAN CLASS=T9>p</SPAN><SPAN CLASS=T14>h</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=T8>c</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=T14>h</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=T14>h</SPAN><SPAN CLASS=S14>M</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=T9>p</SPAN><SPAN CLASS=T14>l</SPAN><SPAN CLASS=T9>pp</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=T9>p</SPAN><SPAN CLASS=T14>ls</SPAN><SPAN CLASS=T9>p</SPAN><SPAN CLASS=T14>hhuls</SPAN>   
    consensus/90%          <SPAN CLASS=T14>h</SPAN><SPAN CLASS=T9>p</SPAN><SPAN style="color:#666666">..</SPAN><SPAN CLASS=T9>p</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=T14>l</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T14>t</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">..</SPAN><SPAN CLASS=T14>u</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=T14>h</SPAN><SPAN style="color:#666666">...................</SPAN><SPAN CLASS=S14>VA</SPAN><SPAN CLASS=T14>l</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=T9>p</SPAN><SPAN CLASS=T14>h</SPAN><SPAN CLASS=T9>p</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=T14>t</SPAN><SPAN style="color:#666666">........</SPAN><SPAN CLASS=T9>p</SPAN><SPAN CLASS=T14>h</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=T8>c</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=T14>h</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=T14>h</SPAN><SPAN CLASS=S14>M</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=T9>p</SPAN><SPAN CLASS=T14>l</SPAN><SPAN CLASS=T9>pp</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=T9>p</SPAN><SPAN CLASS=T14>ls</SPAN><SPAN CLASS=T9>p</SPAN><SPAN CLASS=T14>hhuls</SPAN>   
    consensus/80%          <SPAN CLASS=T14>l</SPAN><SPAN CLASS=T9>p</SPAN><SPAN CLASS=T14>hs</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=T9>p</SPAN><SPAN CLASS=T14>l</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T14>s</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T14>t</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T14>h</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=T14>hh</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T14>hhhs</SPAN><SPAN style="color:#666666">..............</SPAN><SPAN CLASS=T14>hh</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S14>VA</SPAN><SPAN CLASS=T14>l</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=T9>p</SPAN><SPAN CLASS=T14>l</SPAN><SPAN CLASS=T17>+</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=T14>ts</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=T14>s</SPAN><SPAN style="color:#666666">....</SPAN><SPAN CLASS=T9>p</SPAN><SPAN CLASS=T12>-</SPAN><SPAN CLASS=T14>hh</SPAN><SPAN CLASS=T8>c</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>A</SPAN><SPAN CLASS=T14>tl</SPAN><SPAN CLASS=S14>M</SPAN><SPAN CLASS=T14>t</SPAN><SPAN CLASS=T9>p</SPAN><SPAN CLASS=T14>l</SPAN><SPAN CLASS=T9>p</SPAN><SPAN CLASS=S13>H</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=T9>p</SPAN><SPAN CLASS=T14>l</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=T9>p</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=T14>h</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T14>ls</SPAN>   
    consensus/70%          <SPAN CLASS=T14>l</SPAN><SPAN CLASS=T9>p</SPAN><SPAN CLASS=T14>hs</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=T9>p</SPAN><SPAN CLASS=T14>l</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T14>s</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T14>t</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T14>h</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=T14>hh</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T14>hhhs</SPAN><SPAN style="color:#666666">..............</SPAN><SPAN CLASS=T14>hh</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S14>VA</SPAN><SPAN CLASS=T14>l</SPAN><SPAN CLASS=S17>K</SPAN><SPAN CLASS=T9>p</SPAN><SPAN CLASS=T14>l</SPAN><SPAN CLASS=T17>+</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=T14>ts</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=T14>s</SPAN><SPAN style="color:#666666">....</SPAN><SPAN CLASS=T9>p</SPAN><SPAN CLASS=T12>-</SPAN><SPAN CLASS=T14>hh</SPAN><SPAN CLASS=T8>c</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>A</SPAN><SPAN CLASS=T14>tl</SPAN><SPAN CLASS=S14>M</SPAN><SPAN CLASS=T14>t</SPAN><SPAN CLASS=T9>p</SPAN><SPAN CLASS=T14>l</SPAN><SPAN CLASS=T9>p</SPAN><SPAN CLASS=S13>H</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=T9>p</SPAN><SPAN CLASS=T14>l</SPAN><SPAN CLASS=S14>V</SPAN><SPAN CLASS=T9>p</SPAN><SPAN CLASS=S14>L</SPAN><SPAN CLASS=T14>h</SPAN><SPAN CLASS=S14>G</SPAN><SPAN CLASS=T14>ls</SPAN>   
  </PRE>


**Mode** ``identity``

You can colour only those consensus symbols that are identical to some
reference sequence (usually the query or first row) with::

  mview ... -consensus on -con_coloring identity ...

to produce:

.. raw:: html

  <PRE>
    consensus/100%         <SPAN style="color:#000000">hp</SPAN><SPAN style="color:#666666">..</SPAN><SPAN style="color:#000000">p</SPAN><SPAN style="color:#666666">.</SPAN><SPAN style="color:#000000">l</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#000000">t</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">..</SPAN><SPAN style="color:#000000">u</SPAN><SPAN style="color:#666666">.</SPAN><SPAN style="color:#000000">h</SPAN><SPAN style="color:#666666">...................</SPAN><SPAN CLASS=S14>VA</SPAN><SPAN style="color:#000000">l</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#000000">php</SPAN><SPAN style="color:#666666">.</SPAN><SPAN style="color:#000000">t</SPAN><SPAN style="color:#666666">........</SPAN><SPAN style="color:#000000">ph</SPAN><SPAN style="color:#666666">.</SPAN><SPAN style="color:#000000">c</SPAN><SPAN CLASS=S12>E</SPAN><SPAN style="color:#000000">h</SPAN><SPAN style="color:#666666">.</SPAN><SPAN style="color:#000000">h</SPAN><SPAN CLASS=S14>M</SPAN><SPAN style="color:#666666">.</SPAN><SPAN style="color:#000000">plpp</SPAN><SPAN style="color:#666666">.</SPAN><SPAN style="color:#000000">plsphhuls</SPAN>   
    consensus/90%          <SPAN style="color:#000000">hp</SPAN><SPAN style="color:#666666">..</SPAN><SPAN style="color:#000000">p</SPAN><SPAN style="color:#666666">.</SPAN><SPAN style="color:#000000">l</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#000000">t</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">..</SPAN><SPAN style="color:#000000">u</SPAN><SPAN style="color:#666666">.</SPAN><SPAN style="color:#000000">h</SPAN><SPAN style="color:#666666">...................</SPAN><SPAN CLASS=S14>VA</SPAN><SPAN style="color:#000000">l</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#000000">php</SPAN><SPAN style="color:#666666">.</SPAN><SPAN style="color:#000000">t</SPAN><SPAN style="color:#666666">........</SPAN><SPAN style="color:#000000">ph</SPAN><SPAN style="color:#666666">.</SPAN><SPAN style="color:#000000">c</SPAN><SPAN CLASS=S12>E</SPAN><SPAN style="color:#000000">h</SPAN><SPAN style="color:#666666">.</SPAN><SPAN style="color:#000000">h</SPAN><SPAN CLASS=S14>M</SPAN><SPAN style="color:#666666">.</SPAN><SPAN style="color:#000000">plpp</SPAN><SPAN style="color:#666666">.</SPAN><SPAN style="color:#000000">plsphhuls</SPAN>   
    consensus/80%          <SPAN style="color:#000000">lphs</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#000000">pl</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#000000">s</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#000000">t</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#000000">h</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#000000">hh</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#000000">hhhs</SPAN><SPAN style="color:#666666">..............</SPAN><SPAN style="color:#000000">hh</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S14>VA</SPAN><SPAN style="color:#000000">l</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#000000">pl+</SPAN><SPAN style="color:#666666">.</SPAN><SPAN style="color:#000000">ts</SPAN><SPAN style="color:#666666">.</SPAN><SPAN style="color:#000000">s</SPAN><SPAN style="color:#666666">....</SPAN><SPAN style="color:#000000">p-hhc</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>A</SPAN><SPAN style="color:#000000">tl</SPAN><SPAN CLASS=S14>M</SPAN><SPAN style="color:#000000">tplp</SPAN><SPAN CLASS=S13>H</SPAN><SPAN style="color:#666666">.</SPAN><SPAN style="color:#000000">pl</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#000000">p</SPAN><SPAN CLASS=S14>L</SPAN><SPAN style="color:#000000">h</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#000000">ls</SPAN>   
    consensus/70%          <SPAN style="color:#000000">lphs</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#000000">pl</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#000000">s</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#000000">t</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#000000">h</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#000000">hh</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#000000">hhhs</SPAN><SPAN style="color:#666666">..............</SPAN><SPAN style="color:#000000">hh</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S14>VA</SPAN><SPAN style="color:#000000">l</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#000000">pl+</SPAN><SPAN style="color:#666666">.</SPAN><SPAN style="color:#000000">ts</SPAN><SPAN style="color:#666666">.</SPAN><SPAN style="color:#000000">s</SPAN><SPAN style="color:#666666">....</SPAN><SPAN style="color:#000000">p-hhc</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>A</SPAN><SPAN style="color:#000000">tl</SPAN><SPAN CLASS=S14>M</SPAN><SPAN style="color:#000000">tplp</SPAN><SPAN CLASS=S13>H</SPAN><SPAN style="color:#666666">.</SPAN><SPAN style="color:#000000">pl</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#000000">p</SPAN><SPAN CLASS=S14>L</SPAN><SPAN style="color:#000000">h</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#000000">ls</SPAN>   
  </PRE>


**Tuning**

These modes work with the ``-con_ignore`` and ``-con_gaps`` options to tune
the consensus symbols displayed (see :ref:`ref_conserved_symbols or conserved
classes`). For example, the consensus symbols can be switched off, to leave
only conserved residues::

  mview ... -consensus on -con_coloring identity -con_ignore class ...

to produce:

.. raw:: html

  <PRE>
    consensus/100%         <SPAN style="color:#666666">.......</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">........................</SPAN><SPAN CLASS=S14>VA</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#666666">.................</SPAN><SPAN CLASS=S12>E</SPAN><SPAN style="color:#666666">...</SPAN><SPAN CLASS=S14>M</SPAN><SPAN style="color:#666666">...............</SPAN>   
    consensus/90%          <SPAN style="color:#666666">.......</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">........................</SPAN><SPAN CLASS=S14>VA</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#666666">.................</SPAN><SPAN CLASS=S12>E</SPAN><SPAN style="color:#666666">...</SPAN><SPAN CLASS=S14>M</SPAN><SPAN style="color:#666666">...............</SPAN>   
    consensus/80%          <SPAN style="color:#666666">....</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#666666">..</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">..</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">.....................</SPAN><SPAN CLASS=S14>VA</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#666666">.................</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>A</SPAN><SPAN style="color:#666666">..</SPAN><SPAN CLASS=S14>M</SPAN><SPAN style="color:#666666">....</SPAN><SPAN CLASS=S13>H</SPAN><SPAN style="color:#666666">...</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S14>L</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">..</SPAN>   
    consensus/70%          <SPAN style="color:#666666">....</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#666666">..</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S13>F</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">..</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">.....................</SPAN><SPAN CLASS=S14>VA</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S17>K</SPAN><SPAN style="color:#666666">.................</SPAN><SPAN CLASS=S12>E</SPAN><SPAN CLASS=S14>A</SPAN><SPAN style="color:#666666">..</SPAN><SPAN CLASS=S14>M</SPAN><SPAN style="color:#666666">....</SPAN><SPAN CLASS=S13>H</SPAN><SPAN style="color:#666666">...</SPAN><SPAN CLASS=S14>V</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S14>L</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S14>G</SPAN><SPAN style="color:#666666">..</SPAN>   
  </PRE>


Finding and colouring patterns and motifs
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Occurrences of a string or pattern defined by a regular expression can be
coloured using the ``-find 'pattern'`` option. This will cause all instances
of the pattern to be highlighted using the user selected colourmap. Patterns
are case-insensitive.

\1. Patterns may be exact strings::

  mview ... -html head -css on -find VAIK

.. raw:: html

  <PRE>
  1 EGFR_HUMAN  100.0%  <SPAN style="color:#666666">FKKIKVLGSGAFGTVYKGLWIPEGEK---------VKIP</SPAN><SPAN CLASS=S93>VAIK</SPAN><SPAN style="color:#666666">ELREATSPK-ANKEILDEAYVMASVDNPHVCRLLGIC</SPAN> 
  2 PR2_DROME    35.7%  <SPAN style="color:#666666">ISVNKQLGTGEFGIVQQGVWSNGNE-----------RIQ</SPAN><SPAN CLASS=S93>VAIK</SPAN><SPAN style="color:#666666">CLCRERMQS-NPMEFLKEAAIMHSIEHENIVRLYGVV</SPAN> 
  3 ITK_HUMAN    32.9%  <SPAN style="color:#666666">LTFVQEIGSGQFGLVHLGYWLN--------------KDK</SPAN><SPAN CLASS=S93>VAIK</SPAN><SPAN style="color:#666666">TIREGAMS---EEDFIEEAEVMMKLSHPKLVQLYGVC</SPAN> 
  4 PTK7_HUMAN   21.2%  <SPAN style="color:#666666">IREVKQIGVGQFGAVVLAEMTGLS-XLPKGSMNADGVALVAVKKLKPDVSD-EVLQSFDKEIKFMSQLQHDSIVQLLAIC</SPAN> 
  5 KIN31_CAEEL  31.5%  <SPAN style="color:#666666">VELTKKLGEGAFGEVWKGKLLKILDA-------NHQPVLVAVKTAKLESMTKEQIKEIMREARLMRNLDHINVVKFFGVA</SPAN> 
  </PRE>

\2. Patterns may be regular expressions enclosed in quotes::

   mview ... -find 'VA[IV]K'

.. raw:: html

  <PRE>
  1 EGFR_HUMAN  100.0%  <SPAN style="color:#666666">FKKIKVLGSGAFGTVYKGLWIPEGEK---------VKIP</SPAN><SPAN CLASS=S93>VAIK</SPAN><SPAN style="color:#666666">ELREATSPK-ANKEILDEAYVMASVDNPHVCRLLGIC</SPAN> 
  2 PR2_DROME    35.7%  <SPAN style="color:#666666">ISVNKQLGTGEFGIVQQGVWSNGNE-----------RIQ</SPAN><SPAN CLASS=S93>VAIK</SPAN><SPAN style="color:#666666">CLCRERMQS-NPMEFLKEAAIMHSIEHENIVRLYGVV</SPAN> 
  3 ITK_HUMAN    32.9%  <SPAN style="color:#666666">LTFVQEIGSGQFGLVHLGYWLN--------------KDK</SPAN><SPAN CLASS=S93>VAIK</SPAN><SPAN style="color:#666666">TIREGAMS---EEDFIEEAEVMMKLSHPKLVQLYGVC</SPAN> 
  4 PTK7_HUMAN   21.2%  <SPAN style="color:#666666">IREVKQIGVGQFGAVVLAEMTGLS-XLPKGSMNADGVAL</SPAN><SPAN CLASS=S93>VAVK</SPAN><SPAN style="color:#666666">KLKPDVSD-EVLQSFDKEIKFMSQLQHDSIVQLLAIC</SPAN> 
  5 KIN31_CAEEL  31.5%  <SPAN style="color:#666666">VELTKKLGEGAFGEVWKGKLLKILDA-------NHQPVL</SPAN><SPAN CLASS=S93>VAVK</SPAN><SPAN style="color:#666666">TAKLESMTKEQIKEIMREARLMRNLDHINVVKFFGVA</SPAN> 
  </PRE>

\3. Patterns are unaffected by gaps in the sequence::

  mview ... -find '.{4}VA[IV]K'

.. raw:: html

  <PRE>
  1 EGFR_HUMAN  100.0%  <SPAN style="color:#666666">FKKIKVLGSGAFGTVYKGLWIPEGEK---------</SPAN><SPAN CLASS=S93>VKIPVAIK</SPAN><SPAN style="color:#666666">ELREATSPK-ANKEILDEAYVMASVDNPHVCRLLGIC</SPAN> 
  2 PR2_DROME    35.7%  <SPAN style="color:#666666">ISVNKQLGTGEFGIVQQGVWSNGN</SPAN><SPAN CLASS=S93>E</SPAN><SPAN style="color:#666666">-----------</SPAN><SPAN CLASS=S93>RIQVAIK</SPAN><SPAN style="color:#666666">CLCRERMQS-NPMEFLKEAAIMHSIEHENIVRLYGVV</SPAN> 
  3 ITK_HUMAN    32.9%  <SPAN style="color:#666666">LTFVQEIGSGQFGLVHLGYWL</SPAN><SPAN CLASS=S93>N</SPAN><SPAN style="color:#666666">--------------</SPAN><SPAN CLASS=S93>KDKVAIK</SPAN><SPAN style="color:#666666">TIREGAMS---EEDFIEEAEVMMKLSHPKLVQLYGVC</SPAN> 
  4 PTK7_HUMAN   21.2%  <SPAN style="color:#666666">IREVKQIGVGQFGAVVLAEMTGLS-XLPKGSMNAD</SPAN><SPAN CLASS=S93>GVALVAVK</SPAN><SPAN style="color:#666666">KLKPDVSD-EVLQSFDKEIKFMSQLQHDSIVQLLAIC</SPAN> 
  5 KIN31_CAEEL  31.5%  <SPAN style="color:#666666">VELTKKLGEGAFGEVWKGKLLKILDA-------NH</SPAN><SPAN CLASS=S93>QPVLVAVK</SPAN><SPAN style="color:#666666">TAKLESMTKEQIKEIMREARLMRNLDHINVVKFFGVA</SPAN> 
  </PRE>

where you can see that the pattern (any 4 residues followed by V A [I or V] K)
has been found even though it spans a gap in two rows.

\4. Patterns will find all possible matches including overlapping matches::

   mview ... -find '.V.'

.. raw:: html

  <PRE>
  1 EGFR_HUMAN  100.0%  <SPAN style="color:#666666">FKKI</SPAN><SPAN CLASS=S93>KVL</SPAN><SPAN style="color:#666666">GSGAFG</SPAN><SPAN CLASS=S93>TVY</SPAN><SPAN style="color:#666666">KGLWIPEGE</SPAN><SPAN CLASS=S93>K</SPAN><SPAN style="color:#666666">---------</SPAN><SPAN CLASS=S93>VK</SPAN><SPAN style="color:#666666">I</SPAN><SPAN CLASS=S93>PVA</SPAN><SPAN style="color:#666666">IKELREATSPK-ANKEILDEA</SPAN><SPAN CLASS=S93>YVM</SPAN><SPAN style="color:#666666">A</SPAN><SPAN CLASS=S93>SVD</SPAN><SPAN style="color:#666666">NP</SPAN><SPAN CLASS=S93>HVC</SPAN><SPAN style="color:#666666">RLLGIC</SPAN> 
  2 PR2_DROME    35.7%  <SPAN style="color:#666666">I</SPAN><SPAN CLASS=S93>SVN</SPAN><SPAN style="color:#666666">KQLGTGEFG</SPAN><SPAN CLASS=S93>IVQ</SPAN><SPAN style="color:#666666">Q</SPAN><SPAN CLASS=S93>GVW</SPAN><SPAN style="color:#666666">SNGNE-----------RI</SPAN><SPAN CLASS=S93>QVA</SPAN><SPAN style="color:#666666">IKCLCRERMQS-NPMEFLKEAAIMHSIEHEN</SPAN><SPAN CLASS=S93>IVR</SPAN><SPAN style="color:#666666">LY</SPAN><SPAN CLASS=S93>GVV</SPAN> 
  3 ITK_HUMAN    32.9%  <SPAN style="color:#666666">LT</SPAN><SPAN CLASS=S93>FVQ</SPAN><SPAN style="color:#666666">EIGSGQFG</SPAN><SPAN CLASS=S93>LVH</SPAN><SPAN style="color:#666666">LGYWLN--------------KD</SPAN><SPAN CLASS=S93>KVA</SPAN><SPAN style="color:#666666">IKTIREGAMS---EEDFIEEA</SPAN><SPAN CLASS=S93>EVM</SPAN><SPAN style="color:#666666">MKLSHPK</SPAN><SPAN CLASS=S93>LVQ</SPAN><SPAN style="color:#666666">LY</SPAN><SPAN CLASS=S93>GVC</SPAN> 
  4 PTK7_HUMAN   21.2%  <SPAN style="color:#666666">IR</SPAN><SPAN CLASS=S93>EVK</SPAN><SPAN style="color:#666666">QI</SPAN><SPAN CLASS=S93>GVG</SPAN><SPAN style="color:#666666">QFG</SPAN><SPAN CLASS=S93>AVVL</SPAN><SPAN style="color:#666666">AEMTGLS-XLPKGSMNAD</SPAN><SPAN CLASS=S93>GVALVAVK</SPAN><SPAN style="color:#666666">KLKP</SPAN><SPAN CLASS=S93>DVS</SPAN><SPAN style="color:#666666">D-</SPAN><SPAN CLASS=S93>EVL</SPAN><SPAN style="color:#666666">QSFDKEIKFMSQLQHDS</SPAN><SPAN CLASS=S93>IVQ</SPAN><SPAN style="color:#666666">LLAIC</SPAN> 
  5 KIN31_CAEEL  31.5%  <SPAN style="color:#666666">VELTKKLGEGAFG</SPAN><SPAN CLASS=S93>EVW</SPAN><SPAN style="color:#666666">KGKLLKILDA-------NHQ</SPAN><SPAN CLASS=S93>PVLVAVK</SPAN><SPAN style="color:#666666">TAKLESMTKEQIKEIMREARLMRNLDHI</SPAN><SPAN CLASS=S93>NVVK</SPAN><SPAN style="color:#666666">FF</SPAN><SPAN CLASS=S93>GVA</SPAN> 
  </PRE>

where overlapping instances of the pattern merge together.

\5. Multiple alternative patterns are allowed, separated by ``|`` characters::

   mview ... -find 'VAIK|VAVK|[LI]G.G|[DKER]E[AI]..M|[VIL]V[QR]L'

.. raw:: html

  <PRE>
  1 EGFR_HUMAN  100.0%  <SPAN style="color:#666666">FKKIKV</SPAN><SPAN CLASS=S93>LGSG</SPAN><SPAN style="color:#666666">AFGTVYKGLWIPEGEK---------VKIP</SPAN><SPAN CLASS=S93>VAIK</SPAN><SPAN style="color:#666666">ELREATSPK-ANKEIL</SPAN><SPAN CLASS=S93>DEAYVM</SPAN><SPAN style="color:#666666">ASVDNPHVCRLLGIC</SPAN> 
  2 PR2_DROME    35.7%  <SPAN style="color:#666666">ISVNKQ</SPAN><SPAN CLASS=S93>LGTG</SPAN><SPAN style="color:#666666">EFGIVQQGVWSNGNE-----------RIQ</SPAN><SPAN CLASS=S93>VAIK</SPAN><SPAN style="color:#666666">CLCRERMQS-NPMEFL</SPAN><SPAN CLASS=S93>KEAAIM</SPAN><SPAN style="color:#666666">HSIEHEN</SPAN><SPAN CLASS=S93>IVRL</SPAN><SPAN style="color:#666666">YGVV</SPAN> 
  3 ITK_HUMAN    32.9%  <SPAN style="color:#666666">LTFVQE</SPAN><SPAN CLASS=S93>IGSG</SPAN><SPAN style="color:#666666">QFGLVHLGYWLN--------------KDK</SPAN><SPAN CLASS=S93>VAIK</SPAN><SPAN style="color:#666666">TIREGAMS---EEDFI</SPAN><SPAN CLASS=S93>EEAEVM</SPAN><SPAN style="color:#666666">MKLSHPK</SPAN><SPAN CLASS=S93>LVQL</SPAN><SPAN style="color:#666666">YGVC</SPAN> 
  4 PTK7_HUMAN   21.2%  <SPAN style="color:#666666">IREVKQ</SPAN><SPAN CLASS=S93>IGVG</SPAN><SPAN style="color:#666666">QFGAVVLAEMTGLS-XLPKGSMNADGVAL</SPAN><SPAN CLASS=S93>VAVK</SPAN><SPAN style="color:#666666">KLKPDVSD-EVLQSFD</SPAN><SPAN CLASS=S93>KEIKFM</SPAN><SPAN style="color:#666666">SQLQHDS</SPAN><SPAN CLASS=S93>IVQL</SPAN><SPAN style="color:#666666">LAIC</SPAN> 
  5 KIN31_CAEEL  31.5%  <SPAN style="color:#666666">VELTKK</SPAN><SPAN CLASS=S93>LGEG</SPAN><SPAN style="color:#666666">AFGEVWKGKLLKILDA-------NHQPVL</SPAN><SPAN CLASS=S93>VAVK</SPAN><SPAN style="color:#666666">TAKLESMTKEQIKEIM</SPAN><SPAN CLASS=S93>REARLM</SPAN><SPAN style="color:#666666">RNLDHINVVKFFGVA</SPAN> 
  </PRE>

\6. Alternative patterns can be given different colours by changing the
delimiter from a ``|`` to a ``:`` character::

   mview ... -find 'VAIK:VAVK:[LI]G.G:[DKER]E[AI]..M:[VIL]V[QR]L'

.. raw:: html

  <PRE>
  1 EGFR_HUMAN  100.0%  <SPAN style="color:#666666">FKKIKV</SPAN><SPAN CLASS=S95>LGSG</SPAN><SPAN style="color:#666666">AFGTVYKGLWIPEGEK---------VKIP</SPAN><SPAN CLASS=S93>VAIK</SPAN><SPAN style="color:#666666">ELREATSPK-ANKEIL</SPAN><SPAN CLASS=S96>DEAYVM</SPAN><SPAN style="color:#666666">ASVDNPHVCRLLGIC</SPAN> 
  2 PR2_DROME    35.7%  <SPAN style="color:#666666">ISVNKQ</SPAN><SPAN CLASS=S95>LGTG</SPAN><SPAN style="color:#666666">EFGIVQQGVWSNGNE-----------RIQ</SPAN><SPAN CLASS=S93>VAIK</SPAN><SPAN style="color:#666666">CLCRERMQS-NPMEFL</SPAN><SPAN CLASS=S96>KEAAIM</SPAN><SPAN style="color:#666666">HSIEHEN</SPAN><SPAN CLASS=S97>IVRL</SPAN><SPAN style="color:#666666">YGVV</SPAN> 
  3 ITK_HUMAN    32.9%  <SPAN style="color:#666666">LTFVQE</SPAN><SPAN CLASS=S95>IGSG</SPAN><SPAN style="color:#666666">QFGLVHLGYWLN--------------KDK</SPAN><SPAN CLASS=S93>VAIK</SPAN><SPAN style="color:#666666">TIREGAMS---EEDFI</SPAN><SPAN CLASS=S96>EEAEVM</SPAN><SPAN style="color:#666666">MKLSHPK</SPAN><SPAN CLASS=S97>LVQL</SPAN><SPAN style="color:#666666">YGVC</SPAN> 
  4 PTK7_HUMAN   21.2%  <SPAN style="color:#666666">IREVKQ</SPAN><SPAN CLASS=S95>IGVG</SPAN><SPAN style="color:#666666">QFGAVVLAEMTGLS-XLPKGSMNADGVAL</SPAN><SPAN CLASS=S94>VAVK</SPAN><SPAN style="color:#666666">KLKPDVSD-EVLQSFD</SPAN><SPAN CLASS=S96>KEIKFM</SPAN><SPAN style="color:#666666">SQLQHDS</SPAN><SPAN CLASS=S97>IVQL</SPAN><SPAN style="color:#666666">LAIC</SPAN> 
  5 KIN31_CAEEL  31.5%  <SPAN style="color:#666666">VELTKK</SPAN><SPAN CLASS=S95>LGEG</SPAN><SPAN style="color:#666666">AFGEVWKGKLLKILDA-------NHQPVL</SPAN><SPAN CLASS=S94>VAVK</SPAN><SPAN style="color:#666666">TAKLESMTKEQIKEIM</SPAN><SPAN CLASS=S96>REARLM</SPAN><SPAN style="color:#666666">RNLDHINVVKFFGVA</SPAN> 
  </PRE>

and ``|`` and ``:`` delimiters may be combined so that patterns joined by ``|``
still form a single discrete pattern and will have one colour.

If you specify more patterns than the number of colours available
(currently 20) the colours are simply cycled.

.. _ref_colourmaps:

Colours
-------

Colourmaps
^^^^^^^^^^^^^^^

There are default colourmaps for protein and nucleotide (either DNA or RNA)
alignments and consensus lines. MView starts up with the default protein
colourmap selected, as if you had specified a molecule type with ``-moltype
aa`` (for "amino acid").

**Alignments**

Colourmaps have names, e.g., the default protein alignment colourmap is called
``P1`` and the default nucleotide colourmap is ``D1``. Alternative alignment
colouring colourmaps are explicitly selected using the ``-colormap``
option. For example, another built-in colouring scheme can be specified with
``-colormap CLUSTAL``.

Here is the default colormap for proteins:

.. raw:: html

  <PRE>
  <SPAN style="color:#000000">[P1]</SPAN>
  <SPAN style="color:#aa6666">#Protein: highlight amino acid physicochemical properties
  #symbols =>  color                #comment</SPAN>
  <SPAN style="color:#666666">.      </SPAN>  ->  <SPAN style="color:#666666">dark-gray           </SPAN> <SPAN style="color:#aa6666">#wildcard/mismatch</SPAN>
  <SPAN style="color:#33cc00">Aa     </SPAN>  =>  <SPAN style="color:#33cc00">bright-green        </SPAN> <SPAN style="color:#aa6666">#hydrophobic</SPAN>
  <SPAN style="color:#666666">Bb     </SPAN>  =>  <SPAN style="color:#666666">dark-gray           </SPAN> <SPAN style="color:#aa6666">#D or N</SPAN>
  <SPAN style="color:#ffff00">Cc     </SPAN>  =>  <SPAN style="color:#ffff00">yellow              </SPAN> <SPAN style="color:#aa6666">#cysteine</SPAN>
  <SPAN style="color:#0033ff">Dd     </SPAN>  =>  <SPAN style="color:#0033ff">bright-blue         </SPAN> <SPAN style="color:#aa6666">#negative charge</SPAN>
  <SPAN style="color:#0033ff">Ee     </SPAN>  =>  <SPAN style="color:#0033ff">bright-blue         </SPAN> <SPAN style="color:#aa6666">#negative charge</SPAN>
  <SPAN style="color:#009900">Ff     </SPAN>  =>  <SPAN style="color:#009900">dark-green          </SPAN> <SPAN style="color:#aa6666">#large hydrophobic</SPAN>
  <SPAN style="color:#33cc00">Gg     </SPAN>  =>  <SPAN style="color:#33cc00">bright-green        </SPAN> <SPAN style="color:#aa6666">#hydrophobic</SPAN>
  <SPAN style="color:#009900">Hh     </SPAN>  =>  <SPAN style="color:#009900">dark-green          </SPAN> <SPAN style="color:#aa6666">#large hydrophobic</SPAN>
  <SPAN style="color:#33cc00">Ii     </SPAN>  =>  <SPAN style="color:#33cc00">bright-green        </SPAN> <SPAN style="color:#aa6666">#hydrophobic</SPAN>
  <SPAN style="color:#cc0000">Kk     </SPAN>  =>  <SPAN style="color:#cc0000">bright-red          </SPAN> <SPAN style="color:#aa6666">#positive charge</SPAN>
  <SPAN style="color:#33cc00">Ll     </SPAN>  =>  <SPAN style="color:#33cc00">bright-green        </SPAN> <SPAN style="color:#aa6666">#hydrophobic</SPAN>
  <SPAN style="color:#33cc00">Mm     </SPAN>  =>  <SPAN style="color:#33cc00">bright-green        </SPAN> <SPAN style="color:#aa6666">#hydrophobic</SPAN>
  <SPAN style="color:#6600cc">Nn     </SPAN>  =>  <SPAN style="color:#6600cc">purple              </SPAN> <SPAN style="color:#aa6666">#polar</SPAN>
  <SPAN style="color:#33cc00">Pp     </SPAN>  =>  <SPAN style="color:#33cc00">bright-green        </SPAN> <SPAN style="color:#aa6666">#hydrophobic</SPAN>
  <SPAN style="color:#6600cc">Qq     </SPAN>  =>  <SPAN style="color:#6600cc">purple              </SPAN> <SPAN style="color:#aa6666">#polar</SPAN>
  <SPAN style="color:#cc0000">Rr     </SPAN>  =>  <SPAN style="color:#cc0000">bright-red          </SPAN> <SPAN style="color:#aa6666">#positive charge</SPAN>
  <SPAN style="color:#0099ff">Ss     </SPAN>  =>  <SPAN style="color:#0099ff">dull-blue           </SPAN> <SPAN style="color:#aa6666">#small alcohol</SPAN>
  <SPAN style="color:#0099ff">Tt     </SPAN>  =>  <SPAN style="color:#0099ff">dull-blue           </SPAN> <SPAN style="color:#aa6666">#small alcohol</SPAN>
  <SPAN style="color:#33cc00">Vv     </SPAN>  =>  <SPAN style="color:#33cc00">bright-green        </SPAN> <SPAN style="color:#aa6666">#hydrophobic</SPAN>
  <SPAN style="color:#009900">Ww     </SPAN>  =>  <SPAN style="color:#009900">dark-green          </SPAN> <SPAN style="color:#aa6666">#large hydrophobic</SPAN>
  <SPAN style="color:#009900">Yy     </SPAN>  =>  <SPAN style="color:#009900">dark-green          </SPAN> <SPAN style="color:#aa6666">#large hydrophobic</SPAN>
  <SPAN style="color:#666666">Zz     </SPAN>  =>  <SPAN style="color:#666666">dark-gray           </SPAN> <SPAN style="color:#aa6666">#E or Q</SPAN>
  <SPAN style="color:#666666">Xx     </SPAN>  ->  <SPAN style="color:#666666">dark-gray           </SPAN> <SPAN style="color:#aa6666">#unknown</SPAN>
  <SPAN style="color:#999999">?      </SPAN>  ->  <SPAN style="color:#999999">light-gray          </SPAN> <SPAN style="color:#aa6666">#unknown</SPAN>
  <SPAN style="color:#000000">*      </SPAN>  ->  <SPAN style="color:#000000">black               </SPAN> <SPAN style="color:#aa6666">#stop</SPAN>
  </PRE>

The default alignment colormap for nucleotide sequences can be selected using
the ``-moltype na`` (or ``dna`` or ``rna``) option::

  mview ... -moltype na ...

or by specifying::

  mview ... -colormap D1 ...

and is defined as:

.. raw:: html

  <PRE>
  <SPAN style="color:#000000">[D1]</SPAN>
  <SPAN style="color:#aa6666">#DNA: highlight nucleotide types
  #symbols =>  color                #comment</SPAN>
  <SPAN style="color:#666666">.      </SPAN>  ->  <SPAN style="color:#666666">dark-gray           </SPAN> <SPAN style="color:#aa6666">#wildcard/mismatch</SPAN>
  <SPAN style="color:#0033ff">Aa     </SPAN>  =>  <SPAN style="color:#0033ff">bright-blue         </SPAN> <SPAN style="color:#aa6666">#adenosine</SPAN>
  <SPAN style="color:#0099ff">Cc     </SPAN>  =>  <SPAN style="color:#0099ff">dull-blue           </SPAN> <SPAN style="color:#aa6666">#cytosine</SPAN>
  <SPAN style="color:#0033ff">Gg     </SPAN>  =>  <SPAN style="color:#0033ff">bright-blue         </SPAN> <SPAN style="color:#aa6666">#guanine</SPAN>
  <SPAN style="color:#0099ff">Tt     </SPAN>  =>  <SPAN style="color:#0099ff">dull-blue           </SPAN> <SPAN style="color:#aa6666">#thymine</SPAN>
  <SPAN style="color:#0099ff">Uu     </SPAN>  =>  <SPAN style="color:#0099ff">dull-blue           </SPAN> <SPAN style="color:#aa6666">#uracil</SPAN>
  <SPAN style="color:#666666">Mm     </SPAN>  =>  <SPAN style="color:#666666">dark-gray           </SPAN> <SPAN style="color:#aa6666">#amino:      A or C</SPAN>
  <SPAN style="color:#666666">Rr     </SPAN>  =>  <SPAN style="color:#666666">dark-gray           </SPAN> <SPAN style="color:#aa6666">#purine:     A or G</SPAN>
  <SPAN style="color:#666666">Ww     </SPAN>  =>  <SPAN style="color:#666666">dark-gray           </SPAN> <SPAN style="color:#aa6666">#weak:       A or T</SPAN>
  <SPAN style="color:#666666">Ss     </SPAN>  =>  <SPAN style="color:#666666">dark-gray           </SPAN> <SPAN style="color:#aa6666">#strong:     C or G</SPAN>
  <SPAN style="color:#666666">Yy     </SPAN>  =>  <SPAN style="color:#666666">dark-gray           </SPAN> <SPAN style="color:#aa6666">#pyrimidine: C or T</SPAN>
  <SPAN style="color:#666666">Kk     </SPAN>  =>  <SPAN style="color:#666666">dark-gray           </SPAN> <SPAN style="color:#aa6666">#keto:       G or T</SPAN>
  <SPAN style="color:#666666">Vv     </SPAN>  =>  <SPAN style="color:#666666">dark-gray           </SPAN> <SPAN style="color:#aa6666">#not T: A or C or G</SPAN>
  <SPAN style="color:#666666">Hh     </SPAN>  =>  <SPAN style="color:#666666">dark-gray           </SPAN> <SPAN style="color:#aa6666">#not G: A or C or T</SPAN>
  <SPAN style="color:#666666">Dd     </SPAN>  =>  <SPAN style="color:#666666">dark-gray           </SPAN> <SPAN style="color:#aa6666">#not C: A or G or T</SPAN>
  <SPAN style="color:#666666">Bb     </SPAN>  =>  <SPAN style="color:#666666">dark-gray           </SPAN> <SPAN style="color:#aa6666">#not A: C or G or T</SPAN>
  <SPAN style="color:#666666">Nn     </SPAN>  =>  <SPAN style="color:#666666">dark-gray           </SPAN> <SPAN style="color:#aa6666">#any: A or C or G or T</SPAN>
  <SPAN style="color:#666666">Xx     </SPAN>  ->  <SPAN style="color:#666666">dark-gray           </SPAN> <SPAN style="color:#aa6666">#any</SPAN>
  <SPAN style="color:#999999">?      </SPAN>  ->  <SPAN style="color:#999999">light-gray          </SPAN> <SPAN style="color:#aa6666">#unknown</SPAN>
  </PRE>


**Consensus lines**

In addition, the consensus lines optionally displayed below an alignment can
be coloured, and they have their own consensus colourmaps; the default for
proteins is ``PC1`` and for nucleotides it is ``DC1``. Alternative consensus
colouring colourmaps are explicitly selected using the ``-con_colormap`` option.

Here is the default consensus colormap for proteins:

.. raw:: html

  <PRE>
  <SPAN style="color:#000000">[PC1]</SPAN>
  <SPAN style="color:#aa6666">#Protein consensus: highlight equivalence class
  #symbols =>  color                #comment</SPAN>
  <SPAN style="color:#666666">.      </SPAN>  ->  <SPAN style="color:#666666">dark-gray           </SPAN> <SPAN style="color:#aa6666">#unconserved</SPAN>
  <SPAN style="color:#cc0000">+      </SPAN>  ->  <SPAN style="color:#cc0000">bright-red          </SPAN> <SPAN style="color:#aa6666">#positive charge</SPAN>
  <SPAN style="color:#0033ff">-      </SPAN>  ->  <SPAN style="color:#0033ff">bright-blue         </SPAN> <SPAN style="color:#aa6666">#negative charge</SPAN>
  <SPAN style="color:#009900">a      </SPAN>  ->  <SPAN style="color:#009900">dark-green          </SPAN> <SPAN style="color:#aa6666">#aromatic</SPAN>
  <SPAN style="color:#6600cc">c      </SPAN>  ->  <SPAN style="color:#6600cc">purple              </SPAN> <SPAN style="color:#aa6666">#charged</SPAN>
  <SPAN style="color:#33cc00">h      </SPAN>  ->  <SPAN style="color:#33cc00">bright-green        </SPAN> <SPAN style="color:#aa6666">#hydrophobic</SPAN>
  <SPAN style="color:#33cc00">l      </SPAN>  ->  <SPAN style="color:#33cc00">bright-green        </SPAN> <SPAN style="color:#aa6666">#aliphatic</SPAN>
  <SPAN style="color:#0099ff">o      </SPAN>  ->  <SPAN style="color:#0099ff">dull-blue           </SPAN> <SPAN style="color:#aa6666">#alcohol</SPAN>
  <SPAN style="color:#0099ff">p      </SPAN>  ->  <SPAN style="color:#0099ff">dull-blue           </SPAN> <SPAN style="color:#aa6666">#polar</SPAN>
  <SPAN style="color:#33cc00">s      </SPAN>  ->  <SPAN style="color:#33cc00">bright-green        </SPAN> <SPAN style="color:#aa6666">#small</SPAN>
  <SPAN style="color:#33cc00">t      </SPAN>  ->  <SPAN style="color:#33cc00">bright-green        </SPAN> <SPAN style="color:#aa6666">#turnlike</SPAN>
  <SPAN style="color:#33cc00">u      </SPAN>  ->  <SPAN style="color:#33cc00">bright-green        </SPAN> <SPAN style="color:#aa6666">#tiny</SPAN>
  </PRE>

The default consensus colormap for nucleotide sequences can be selected using
the ``-moltype na`` (or ``dna`` or ``rna``) option::

  mview ... -moltype na ...

or by specifying::

  mview ... -con_colormap DC1 ...

and is defined as:

.. raw:: html

  <PRE>
  <SPAN style="color:#000000">[DC1]</SPAN>
  <SPAN style="color:#aa6666">#DNA consensus: highlight ring type
  #symbols =>  color                #comment</SPAN>
  <SPAN style="color:#666666">.      </SPAN>  ->  <SPAN style="color:#666666">dark-gray           </SPAN> <SPAN style="color:#aa6666">#unconserved</SPAN>
  <SPAN style="color:#6600cc">r      </SPAN>  ->  <SPAN style="color:#6600cc">purple              </SPAN> <SPAN style="color:#aa6666">#purine</SPAN>
  <SPAN style="color:#ff3333">y      </SPAN>  ->  <SPAN style="color:#ff3333">orange              </SPAN> <SPAN style="color:#aa6666">#pyrimidine</SPAN>
  </PRE>


Creating new colourmaps
^^^^^^^^^^^^^^^^^^^^^^^

The built-in colour palette and colourmaps built from it can be listed from
the command line with ``-listcolors``, and new colour schemes can be loaded
from a file using the ``-colorfile`` option.

Predefined colours are defined as in the following short segment of the built
in colour palette obtained with ``-listcolors -html head`` to wrap the output
in HTML and display the actual colours:

.. raw:: html

  <PRE>
  <SPAN style="color:#aa6666">#color                     : #RGB</SPAN> 
  color <SPAN style="color:#000000">black               </SPAN> : #000000
  color <SPAN style="color:#ffffff">white               </SPAN> : #ffffff
  color <SPAN style="color:#ff0000">red                 </SPAN> : #ff0000
  color <SPAN style="color:#00ff00">green               </SPAN> : #00ff00
  color <SPAN style="color:#0000ff">blue                </SPAN> : #0000ff
  color <SPAN style="color:#00ffff">cyan                </SPAN> : #00ffff
  color <SPAN style="color:#ff00ff">magenta             </SPAN> : #ff00ff
  color <SPAN style="color:#ffff00">yellow              </SPAN> : #ffff00    
  ...
  </PRE>

Here's an example of a short protein colouring scheme using the built-in
colourmap, which is used to explain the syntax:

.. raw:: html

  <PRE>
  <SPAN style="color:#000000">[CYS]</SPAN>
  <SPAN style="color:#aa6666">#Protein: highlight cysteines
  #symbols =>  color                #comment</SPAN>
  <SPAN style="color:#666666">.      </SPAN>  ->  <SPAN style="color:#666666">dark-gray           </SPAN> <SPAN style="color:#aa6666">#wildcard/mismatch</SPAN>
  <SPAN style="color:#ffff00">Cc     </SPAN>  =>  <SPAN style="color:#ffff00">yellow              </SPAN> <SPAN style="color:#aa6666">#cysteine</SPAN>
  <SPAN style="color:#666666">Xx     </SPAN>  ->  <SPAN style="color:#666666">dark-gray           </SPAN> <SPAN style="color:#aa6666">#unknown</SPAN>
  <SPAN style="color:#999999">?      </SPAN>  ->  <SPAN style="color:#999999">light-gray          </SPAN> <SPAN style="color:#aa6666">#unknown</SPAN>
  </PRE>

When writing a new protein/nucleotide colouring scheme, scheme names
introduced in square brackets (``[CYS]``, above) are case-insensitive.

Any line or part of a line beginning with a ``#`` character is a comment.

Colourings are defined one per line by symbol(s) at the left, an arrow, then
the colour name or RGB code, followed by an optional comment. The symbols at
the left are case-sensitive, and can be given as single characters ``X`` or as
a character pair like ``Xx``, where we want both upper- and lowercase to have
the same colour. The special wildcard ``.`` symbol sets the base colour to be
used for all symbols in the alignment. Other lines define specific colourings
for sequence symbols of interest. The ordering of lines is not important.

In the example, ``C`` or ``c`` will be painted yellow; an explicit ``X`` or
``x`` residue will be dark grey; an explicit unknown residue ``?`` will be
light gray; any other residue will match the ``.`` wildcard and be painted
dark grey.

A symbol to name mapping can use a predefined colour name (as above) or an
explicit hexadecimal RGB code like those in the colour palette.

The arrow separating the symbol(s) from the colour code can be double ``=>``
or single ``->`` arrows selecting background or foreground colouring:

* If style sheets are not being used, the choice of arrow is unimportant: the
  supplied colour is used for the foreground, i.e., the output symbol.

* If style sheets are in use with ``-css on``, then ``=>`` means that the
  colour should be applied to the background of the symbol, while ``->`` means
  it should be aplied to the foreground, i.e., the symbol itself.

So, in the ``CYS`` example, the symbols ``*``, ``?``, ``X``, ``x`` will be
coloured in the foreground (i.e., the symbols themselves), and ``C`` or ``c``
will be displayed as coloured symbols unless ``-css on`` is set, in which case
they will appear as coloured bocks.


Layout and filtering
--------------------


Pagination
^^^^^^^^^^

The default layout is a single unbroken horizontal band of alignment - fine if
scrolling inside Firefox. However, you may prefer to break the alignment into
vertically stacked panes. For panes, for example, 80 columns wide, set
``-width 80``. Widths refer to the alignment, not to the whole displayed
output.


Column ranges
^^^^^^^^^^^^^

It is possible to narrow (or expand) the displayed range of columns of the
alignment, for example, ``-range 10:78`` would select only that column range
using the numbering scheme reported when ``-ruler on`` is set (see
:ref:`ref_rulers`). Note: the range setting is not related to the sequence
position labelling for blast/fasta database search input; it's just the
position along the ruler.

The order of the numbers is unimportant making it simpler to state interest in
a region of the alignment that might actually be reversed in the output (e.g.,
a BLASTN search hit matching the reverse complement of the query strand).


.. _ref_filtering_rows:

Filtering rows
^^^^^^^^^^^^^^

**Showing only the top N rows**

Usually, specifying a limited number of hits to view from a long search
alignment speeds things up a lot as there's less parsing and less formatting
to be generated, so to get the best 10 hits, use the option ``-top 10``.

**Filtering by percent identity**

You also can squeeze more out of a deep alignment and get a less biased view
if a threshold on the pairwise sequence identity is set using ``-maxident N``,
where N is some value between 0 and 100.

Similarly, ``-minident N`` will report only those hits above some threshold
percent identity; useful for looking for close matches to the query or some
reference sequence.

**Showing and hiding sets of rows**

Rows can be dropped explicitly using the ``-hide`` option. This can be
supplied a comma-separated list of row identifiers, rank numbers, rank number
ranges (1,2,3, 1..3, 1:3 are all equivalent), regular expressions (case
insensitive, enclosed between // characters) to match against row identifiers,
or the ``*`` symbol meaning all rows.

Likewise, the ``-show`` option specifies a list of rows to keep in the
alignment. The ``-show`` option overrides ``-hide`` whenever a row is common
to both.

For example, the options::

  -hide all  -show '2,3,6..10,/^pdb/'

or even::

  -hide '/.*/'  -show '2,3,6:10,/^pdb/'

would hide everything except rows 2, 3, 6 through 10 inclusive, and any hits
beginning with the string 'pdb'.

Note: the currently set reference row is still used for percent identity and
colouring operations, even though the row may have been dropped from display
by the ``-hide`` list (see :ref:`ref_reference_row`).

**Data format specific filters**
 
Other filters specific to BLASTP, FASTA, etc., input formats allow cutoffs on
scores or p-values, etc. In particular, it is possible to apply some control
over the selection of HSPs used in building the MView alignment using the
``-hsp`` filtering option.

Some search programs produce DNA strand-directional output (e.g., BLASTN) and
you can extract or output the results separately. For example, to see just the
plus strand matches::

  mview -in blast -strand p blastn_results.dat 

The choices are ``p``, ``m``, ``both``.

Of interest to anyone using PSI-BLAST, you can display alignments for any/all
iterations of a PSI-BLAST run using, say::

  mview -in blast -cycle 1,last psiblast_results.dat 

to get just those two iterations. The default is to display only the last
iteration. If you want all output, use ``-cycle all``.

**Keeping rows, but ignoring them in calculations**

Another control option can be used to prevent MView from using rows for
colouring or for calculation of percent identities although these rows will
still be displayed. Use ``-nop`` to specify a list (comma-separated as usual)
of identifiers or row numbers to flag for "NO Processing". This is useful for
displaying non-alignment data (e.g., secondary structure predictions)
alongside the alignment.


Labels and annotations
^^^^^^^^^^^^^^^^^^^^^^

The labelling information at the left of the alignment can be too wide, so you
can switch some of them off. Labels are in blocks numbered from zero
(perverse, but the original reasoning was that the input data starts with the
sequence identifiers in column 1 and MView tacks on a rank number in front, so
make that column 0).

 ======   ==================================================
 Column   Description
 ======   ==================================================
 0        rank
 1        identifier
 2        description
 3        score block (may contain many score columns)
 4        percent identities
 5        query sequence positions (blast or fasta searches)
 6        hit sequence positions (blast or fasta searches)
 ======   ==================================================

Any of the of the label types can be switched off with an option like
``-label2`` to remove the descriptions label at column 2, and so on.


Data formats
------------


Input formats
^^^^^^^^^^^^^

MView supports a variety of input formats covering common sequence database
seach and multiple alignment formats. Alternatively, if you can convert some
strange alignment to one of the simpler input formats (FASTA, PIR, MSF, plain)
you can then read it into MView. See `input_formats`_.

.. _input_formats: formats_in.html


Output formats
^^^^^^^^^^^^^^

The default output is plain text showing the alignment together with some
header information. HTML markup will be added if any of the HTML-specific or
colouring options are set.

However, a number of alternative output formats allow format conversions
(e.g., convert a BLAST search to FASTA sequence format) for subsequent
processing. See `output_formats`_.

.. _output_formats: formats_out.html


Linking identifiers to external resources
-----------------------------------------

Using the ``-srs on`` option with HTML output, it is possible to convert
sequence identifiers into links to a sequence database:

.. raw:: html

  <PRE>
  1 <A HREF="http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?val=P00533">sp|P00533.2|EGFR_HUMAN</A>  100.0%    <SPAN CLASS=S37>F</SPAN><SPAN CLASS=S36>K</SPAN><SPAN style="color:#666666">KI</SPAN><SPAN CLASS=S36>K</SPAN><SPAN style="color:#666666">V</SPAN><SPAN CLASS=S37>L</SPAN><SPAN CLASS=S43>G</SPAN><SPAN style="color:#666666">S</SPAN><SPAN CLASS=S43>G</SPAN><SPAN CLASS=S37>AF</SPAN><SPAN CLASS=S43>G</SPAN><SPAN style="color:#666666">T</SPAN><SPAN CLASS=S37>V</SPAN><SPAN style="color:#666666">YK</SPAN><SPAN CLASS=S43>G</SPAN><SPAN style="color:#666666">L</SPAN><SPAN CLASS=S37>W</SPAN><SPAN style="color:#666666">IPEGEK---------VKIP</SPAN><SPAN CLASS=S37>VAI</SPAN><SPAN CLASS=S36>K</SPAN><SPAN CLASS=S41>E</SPAN><SPAN CLASS=S37>L</SPAN><SPAN CLASS=S36>R</SPAN><SPAN style="color:#666666">E</SPAN><SPAN CLASS=S37>A</SPAN><SPAN style="color:#666666">TSPK-ANK</SPAN><SPAN CLASS=S41>E</SPAN><SPAN CLASS=S37>I</SPAN><SPAN style="color:#666666">L</SPAN><SPAN CLASS=S41>DE</SPAN><SPAN CLASS=S37>A</SPAN><SPAN style="color:#666666">Y</SPAN><SPAN CLASS=S37>VM</SPAN><SPAN style="color:#666666">A</SPAN><SPAN CLASS=S38>S</SPAN><SPAN CLASS=S37>V</SPAN><SPAN CLASS=S41>D</SPAN><SPAN CLASS=S38>N</SPAN><SPAN style="color:#666666">P</SPAN><SPAN CLASS=S39>H</SPAN><SPAN CLASS=S37>V</SPAN><SPAN CLASS=S40>C</SPAN><SPAN CLASS=S36>R</SPAN><SPAN CLASS=S37>LL</SPAN><SPAN CLASS=S43>G</SPAN><SPAN CLASS=S37>I</SPAN><SPAN CLASS=S40>C</SPAN>   
  2 <A HREF="http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?val=Q9I7F7">sp|Q9I7F7.3|PR2_DROME</A>    35.7%    <SPAN CLASS=S37>I</SPAN><SPAN CLASS=S38>S</SPAN><SPAN style="color:#666666">VN</SPAN><SPAN CLASS=S36>K</SPAN><SPAN style="color:#666666">Q</SPAN><SPAN CLASS=S37>L</SPAN><SPAN CLASS=S43>G</SPAN><SPAN style="color:#666666">T</SPAN><SPAN CLASS=S43>G</SPAN><SPAN CLASS=S41>E</SPAN><SPAN CLASS=S37>F</SPAN><SPAN CLASS=S43>G</SPAN><SPAN style="color:#666666">I</SPAN><SPAN CLASS=S37>V</SPAN><SPAN style="color:#666666">QQ</SPAN><SPAN CLASS=S43>G</SPAN><SPAN style="color:#666666">V</SPAN><SPAN CLASS=S37>W</SPAN><SPAN style="color:#666666">SNGNE-----------RIQ</SPAN><SPAN CLASS=S37>VAI</SPAN><SPAN CLASS=S36>K</SPAN><SPAN CLASS=S40>C</SPAN><SPAN CLASS=S37>L</SPAN><SPAN CLASS=S40>C</SPAN><SPAN style="color:#666666">R</SPAN><SPAN CLASS=S41>E</SPAN><SPAN style="color:#666666">RMQS-NPM</SPAN><SPAN CLASS=S41>E</SPAN><SPAN CLASS=S37>F</SPAN><SPAN style="color:#666666">L</SPAN><SPAN CLASS=S36>K</SPAN><SPAN CLASS=S41>E</SPAN><SPAN CLASS=S37>A</SPAN><SPAN style="color:#666666">A</SPAN><SPAN CLASS=S37>IM</SPAN><SPAN style="color:#666666">H</SPAN><SPAN CLASS=S38>S</SPAN><SPAN CLASS=S37>I</SPAN><SPAN CLASS=S41>E</SPAN><SPAN CLASS=S39>H</SPAN><SPAN style="color:#666666">E</SPAN><SPAN CLASS=S38>N</SPAN><SPAN CLASS=S37>IV</SPAN><SPAN CLASS=S36>R</SPAN><SPAN CLASS=S37>L</SPAN><SPAN CLASS=S39>Y</SPAN><SPAN CLASS=S43>G</SPAN><SPAN CLASS=S37>VV</SPAN>   
  3 <A HREF="http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?val=Q08881">sp|Q08881.1|ITK_HUMAN</A>    32.9%    <SPAN CLASS=S37>L</SPAN><SPAN CLASS=S38>T</SPAN><SPAN style="color:#666666">FV</SPAN><SPAN CLASS=S38>Q</SPAN><SPAN style="color:#666666">E</SPAN><SPAN CLASS=S37>I</SPAN><SPAN CLASS=S43>G</SPAN><SPAN style="color:#666666">S</SPAN><SPAN CLASS=S43>G</SPAN><SPAN CLASS=S38>Q</SPAN><SPAN CLASS=S37>F</SPAN><SPAN CLASS=S43>G</SPAN><SPAN style="color:#666666">L</SPAN><SPAN CLASS=S37>V</SPAN><SPAN style="color:#666666">HL</SPAN><SPAN CLASS=S43>G</SPAN><SPAN style="color:#666666">Y</SPAN><SPAN CLASS=S37>W</SPAN><SPAN style="color:#666666">LN--------------KDK</SPAN><SPAN CLASS=S37>VAI</SPAN><SPAN CLASS=S36>K</SPAN><SPAN CLASS=S38>T</SPAN><SPAN CLASS=S37>I</SPAN><SPAN CLASS=S36>R</SPAN><SPAN style="color:#666666">E</SPAN><SPAN CLASS=S43>G</SPAN><SPAN style="color:#666666">AMS---EE</SPAN><SPAN CLASS=S41>D</SPAN><SPAN CLASS=S37>F</SPAN><SPAN style="color:#666666">I</SPAN><SPAN CLASS=S41>EE</SPAN><SPAN CLASS=S37>A</SPAN><SPAN style="color:#666666">E</SPAN><SPAN CLASS=S37>VM</SPAN><SPAN style="color:#666666">M</SPAN><SPAN CLASS=S36>K</SPAN><SPAN CLASS=S37>L</SPAN><SPAN CLASS=S38>S</SPAN><SPAN CLASS=S39>H</SPAN><SPAN style="color:#666666">P</SPAN><SPAN CLASS=S36>K</SPAN><SPAN CLASS=S37>LV</SPAN><SPAN CLASS=S38>Q</SPAN><SPAN CLASS=S37>L</SPAN><SPAN CLASS=S39>Y</SPAN><SPAN CLASS=S43>G</SPAN><SPAN CLASS=S37>V</SPAN><SPAN CLASS=S40>C</SPAN>   
  4 <A HREF="http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?val=Q13308">sp|Q13308.2|PTK7_HUMAN</A>   21.2%    <SPAN CLASS=S37>I</SPAN><SPAN CLASS=S36>R</SPAN><SPAN style="color:#666666">EV</SPAN><SPAN CLASS=S36>K</SPAN><SPAN style="color:#666666">Q</SPAN><SPAN CLASS=S37>I</SPAN><SPAN CLASS=S43>G</SPAN><SPAN style="color:#666666">V</SPAN><SPAN CLASS=S43>G</SPAN><SPAN CLASS=S38>Q</SPAN><SPAN CLASS=S37>F</SPAN><SPAN CLASS=S43>G</SPAN><SPAN style="color:#666666">A</SPAN><SPAN CLASS=S37>V</SPAN><SPAN style="color:#666666">VL</SPAN><SPAN CLASS=S37>A</SPAN><SPAN style="color:#666666">E</SPAN><SPAN CLASS=S37>M</SPAN><SPAN style="color:#666666">TGLS-XLPKGSMNADGVAL</SPAN><SPAN CLASS=S37>VAV</SPAN><SPAN CLASS=S36>KK</SPAN><SPAN CLASS=S37>L</SPAN><SPAN CLASS=S36>K</SPAN><SPAN style="color:#666666">P</SPAN><SPAN CLASS=S41>D</SPAN><SPAN style="color:#666666">VSD-EVLQ</SPAN><SPAN CLASS=S38>S</SPAN><SPAN CLASS=S37>F</SPAN><SPAN style="color:#666666">D</SPAN><SPAN CLASS=S36>K</SPAN><SPAN CLASS=S41>E</SPAN><SPAN CLASS=S37>I</SPAN><SPAN style="color:#666666">K</SPAN><SPAN CLASS=S37>FM</SPAN><SPAN style="color:#666666">S</SPAN><SPAN CLASS=S38>Q</SPAN><SPAN CLASS=S37>L</SPAN><SPAN CLASS=S38>Q</SPAN><SPAN CLASS=S39>H</SPAN><SPAN style="color:#666666">D</SPAN><SPAN CLASS=S38>S</SPAN><SPAN CLASS=S37>IV</SPAN><SPAN CLASS=S38>Q</SPAN><SPAN CLASS=S37>LLAI</SPAN><SPAN CLASS=S40>C</SPAN>   
  5 <A HREF="http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?val=P34265">sp|P34265.4|KIN31_CAEEL</A>  31.5%    <SPAN CLASS=S37>V</SPAN><SPAN CLASS=S41>E</SPAN><SPAN style="color:#666666">LT</SPAN><SPAN CLASS=S36>K</SPAN><SPAN style="color:#666666">K</SPAN><SPAN CLASS=S37>L</SPAN><SPAN CLASS=S43>G</SPAN><SPAN style="color:#666666">E</SPAN><SPAN CLASS=S43>G</SPAN><SPAN CLASS=S37>AF</SPAN><SPAN CLASS=S43>G</SPAN><SPAN style="color:#666666">E</SPAN><SPAN CLASS=S37>V</SPAN><SPAN style="color:#666666">WK</SPAN><SPAN CLASS=S43>G</SPAN><SPAN style="color:#666666">K</SPAN><SPAN CLASS=S37>L</SPAN><SPAN style="color:#666666">LKILDA-------NHQPVL</SPAN><SPAN CLASS=S37>VAV</SPAN><SPAN CLASS=S36>K</SPAN><SPAN CLASS=S38>T</SPAN><SPAN CLASS=S37>A</SPAN><SPAN CLASS=S36>K</SPAN><SPAN style="color:#666666">L</SPAN><SPAN CLASS=S41>E</SPAN><SPAN style="color:#666666">SMTKEQIK</SPAN><SPAN CLASS=S41>E</SPAN><SPAN CLASS=S37>I</SPAN><SPAN style="color:#666666">M</SPAN><SPAN CLASS=S36>R</SPAN><SPAN CLASS=S41>E</SPAN><SPAN CLASS=S37>A</SPAN><SPAN style="color:#666666">R</SPAN><SPAN CLASS=S37>LM</SPAN><SPAN style="color:#666666">R</SPAN><SPAN CLASS=S38>N</SPAN><SPAN CLASS=S37>L</SPAN><SPAN CLASS=S41>D</SPAN><SPAN CLASS=S39>H</SPAN><SPAN style="color:#666666">I</SPAN><SPAN CLASS=S38>N</SPAN><SPAN CLASS=S37>VV</SPAN><SPAN CLASS=S36>K</SPAN><SPAN CLASS=S37>FF</SPAN><SPAN CLASS=S43>G</SPAN><SPAN CLASS=S37>VA</SPAN>   
    consensus/90%                     <SPAN style="color:#666666">.......</SPAN><SPAN CLASS=S43>G</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S43>G</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S37>F</SPAN><SPAN CLASS=S43>G</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S37>V</SPAN><SPAN style="color:#666666">........................</SPAN><SPAN CLASS=S37>VA</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S36>K</SPAN><SPAN style="color:#666666">.................</SPAN><SPAN CLASS=S41>E</SPAN><SPAN style="color:#666666">...</SPAN><SPAN CLASS=S37>M</SPAN><SPAN style="color:#666666">...............</SPAN>   
    consensus/80%                     <SPAN style="color:#666666">....</SPAN><SPAN CLASS=S36>K</SPAN><SPAN style="color:#666666">..</SPAN><SPAN CLASS=S43>G</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S43>G</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S37>F</SPAN><SPAN CLASS=S43>G</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S37>V</SPAN><SPAN style="color:#666666">..</SPAN><SPAN CLASS=S43>G</SPAN><SPAN style="color:#666666">.....................</SPAN><SPAN CLASS=S37>VA</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S36>K</SPAN><SPAN style="color:#666666">.................</SPAN><SPAN CLASS=S41>E</SPAN><SPAN CLASS=S37>A</SPAN><SPAN style="color:#666666">..</SPAN><SPAN CLASS=S37>M</SPAN><SPAN style="color:#666666">....</SPAN><SPAN CLASS=S39>H</SPAN><SPAN style="color:#666666">...</SPAN><SPAN CLASS=S37>V</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S37>L</SPAN><SPAN style="color:#666666">.</SPAN><SPAN CLASS=S43>G</SPAN><SPAN style="color:#666666">..</SPAN>   
  </PRE>

The identfiers need to conform to patterns such as::

        database|accession|identifier 
        database:identifier

like those produced by the NCBI, EBI or other blast services.

Links will be constructed if the patterns are listed in the ``SRS.pm``
library, which is part of this software. You can modify and extend this file
to include more patterns if you know some Perl and the format of the URLs
needed to access the sequence databases of interest.

Of course, this linking mechanism works for any recognised input data format,
not just blast results.


Memory usage
------------

Use of memory by MView can be very great, particularly if you try to process
complete sets of PSI-BLAST cycles each containing 1000s of hits all at
once. Use of most filtering options should reduce memory requirements by
cutting down the number of internal data structures created. Likewise,
processing each alignment separately will save memory or you can use the
option ``-register off`` to cause each alignment to be output when ready (by
default all alignments are saved until the end so they can be printed with
fields in register). Finally, the choice of malloc library compiled into your
perl may affect memory use.


.. END
