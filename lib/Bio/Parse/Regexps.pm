# -*- perl -*-
# Copyright (C) 1996-2006 Nigel P. Brown

###########################################################################
# regexps for string matching numerical types
###########################################################################
package Bio::Parse::Regexps;

use Exporter;

@ISA = qw(Exporter);

@EXPORT = 
    qw(
       $RX_Uint
       $RX_Sint
       $RX_Ureal 
       $RX_Sreal
      );


#unsigned integer
$RX_Uint   = '\+?\d+';

#signed integer
$RX_Sint   = '[+-]?\d+';

#unsigned real
$RX_Ureal = '\+?(?:\d+\.\d+|\d+\.|\d+|\.\d+)?(?:[eE][+-]?\d+)?';

#signed real
$RX_Sreal = '[+-]?(?:\d+\.\d+|\d+\.|\d+|\.\d+)?(?:[eE][+-]?\d+)?';


###########################################################################
1;
