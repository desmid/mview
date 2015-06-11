# -*- perl -*-
# Copyright (C) 1996-2015 Nigel P. Brown
# $Id: tblastx.pm,v 1.9 2005/12/12 20:42:48 brown Exp $

###########################################################################
package NPB::Parse::Format::BLAST2::tblastx;

use NPB::Parse::Format::BLAST2::blastx;
use strict;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST2::blastx);


###########################################################################
package NPB::Parse::Format::BLAST2::tblastx::HEADER;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST2::blastx::HEADER);


###########################################################################
package NPB::Parse::Format::BLAST2::tblastx::SEARCH;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST2::blastx::SEARCH);


###########################################################################
package NPB::Parse::Format::BLAST2::tblastx::SEARCH::RANK;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST2::blastx::SEARCH::RANK);


###########################################################################
package NPB::Parse::Format::BLAST2::tblastx::SEARCH::MATCH;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST2::blastx::SEARCH::MATCH);


###########################################################################
package NPB::Parse::Format::BLAST2::tblastx::SEARCH::MATCH::SUM;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST2::blastx::SEARCH::MATCH::SUM);


###########################################################################
package NPB::Parse::Format::BLAST2::tblastx::SEARCH::MATCH::ALN;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST2::SEARCH::MATCH::ALN);

sub new {
    my $type = shift;
    my ($parent) = @_;
    my $self = new NPB::Parse::Format::BLAST2::SEARCH::MATCH::ALN(@_);
    bless $self, $type;

    #use sequence numbering to get orientations; ignore
    #explicit orientations or frames in BLAST[NX] 2.0.9
    if ($self->{'query_start'} > $self->{'query_stop'}) {
	$self->{'query_orient'} = '-';
    } else {
	$self->{'query_orient'} = '+';
    }
    if ($self->{'sbjct_start'} > $self->{'sbjct_stop'}) {
	$self->{'sbjct_orient'} = '-';
    } else {
	$self->{'sbjct_orient'} = '+';
    }

    #record paired orientations in MATCH list
    push @{$parent->{'orient'}->{
				 $self->{'query_orient'} .
				 $self->{'sbjct_orient'}
				}}, $self;
    
    if (exists $self->{'frame1'}) {
	#warn "FRAME1 = $self->{'frame1'}";
	$self->{'query_frame'} = $self->{'frame1'};
	delete $self->{'frame1'};
    }

    if (exists $self->{'frame2'}) {
	#warn "FRAME2 = $self->{'frame2'}";
	$self->{'sbjct_frame'} = $self->{'frame2'};
	delete $self->{'frame2'};
    }

    $self;
}

sub print_data {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    printf "$x%20s -> %s\n",  'query_orient', $self->{'query_orient'};
    printf "$x%20s -> %s\n",  'sbjct_orient', $self->{'sbjct_orient'};
    printf "$x%20s -> %s\n",  'query_frame',  $self->{'query_frame'} if
	exists $self->{'query_frame'};
    printf "$x%20s -> %s\n",  'sbjct_frame',  $self->{'sbjct_frame'} if
	exists $self->{'sbjct_frame'};
    $self->SUPER::print($indent);
}

###########################################################################
package NPB::Parse::Format::BLAST2::tblastx::WARNING;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST2::blastx::WARNING);


###########################################################################
package NPB::Parse::Format::BLAST2::tblastx::PARAMETERS;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST2::blastx::PARAMETERS);


###########################################################################
1;
