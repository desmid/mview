# -*- perl -*-
# Copyright (C) 1996-2006 Nigel P. Brown

###########################################################################
package NPB::Parse::Math;

use Exporter;

@ISA = Exporter;

@EXPORT = qw(
	     min
	     max
	     );

use strict;

###########################################################################
#arithmetic min() function
sub min {
    my ($a, $b) = @_;
    $a < $b ? $a : $b;
}

#arithmetic max() function
sub max {
    my ($a, $b) = @_;
    $a > $b ? $a : $b;
}

###########################################################################
1;
