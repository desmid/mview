# Copyright (C) 1996-2013 Nigel P. Brown

# This file is part of MView.
# MView is released under license GPLv2, or any later version.

###########################################################################
package Bio::Parse::Format::GCG_FASTA2::fasta;

use Bio::Parse::Format::GCG_FASTA2;
use strict;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Format::GCG_FASTA2);

sub new { my $self=shift; $self->SUPER::new(@_) }


###########################################################################
package Bio::Parse::Format::GCG_FASTA2::fasta::HEADER;

use vars qw(@ISA);

@ISA   = qw(Bio::Parse::Format::GCG_FASTA2::HEADER);


###########################################################################
package Bio::Parse::Format::GCG_FASTA2::fasta::RANK;

use vars qw(@ISA);

@ISA   = qw(Bio::Parse::Format::GCG_FASTA2::RANK);


###########################################################################
package Bio::Parse::Format::GCG_FASTA2::fasta::TRAILER;

use vars qw(@ISA);

@ISA   = qw(Bio::Parse::Format::GCG_FASTA2::TRAILER);


###########################################################################
package Bio::Parse::Format::GCG_FASTA2::fasta::MATCH;

use vars qw(@ISA);

@ISA   = qw(Bio::Parse::Format::GCG_FASTA2::MATCH);


###########################################################################
package Bio::Parse::Format::GCG_FASTA2::fasta::MATCH::SUM;

use vars qw(@ISA);

@ISA   = qw(Bio::Parse::Format::GCG_FASTA2::MATCH::SUM);


###########################################################################
package Bio::Parse::Format::GCG_FASTA2::fasta::MATCH::ALN;

use vars qw(@ISA);

@ISA   = qw(Bio::Parse::Format::GCG_FASTA2::MATCH::ALN);


###########################################################################
1;
