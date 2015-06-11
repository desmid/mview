# -*- perl -*-
# Copyright (C) 1996-2015 Nigel P. Brown
# $Id: blastn.pm,v 1.10 2005/12/12 20:42:48 brown Exp $

###########################################################################
package NPB::Parse::Format::BLAST2::blastn;

use strict;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST2);


###########################################################################
package NPB::Parse::Format::BLAST2::blastn::HEADER;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST::HEADER);


###########################################################################
package NPB::Parse::Format::BLAST2::blastn::SEARCH;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST2::SEARCH);


###########################################################################
package NPB::Parse::Format::BLAST2::blastn::SEARCH::RANK;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST2::SEARCH::RANK);


###########################################################################
package NPB::Parse::Format::BLAST2::blastn::SEARCH::MATCH;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST::MATCH);


###########################################################################
package NPB::Parse::Format::BLAST2::blastn::SEARCH::MATCH::SUM;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST::MATCH::SUM);


###########################################################################
package NPB::Parse::Format::BLAST2::blastn::SEARCH::MATCH::ALN;

use vars qw(@ISA);
use NPB::Parse::Regexps;

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
    
    $self;
}

sub print_data {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    printf "$x%20s -> %s\n",  'query_orient', $self->{'query_orient'};
    printf "$x%20s -> %s\n",  'sbjct_orient', $self->{'sbjct_orient'};
    $self->SUPER::print($indent);
}


###########################################################################
package NPB::Parse::Format::BLAST2::blastn::WARNING;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST::WARNING);


###########################################################################
package NPB::Parse::Format::BLAST2::blastn::PARAMETERS;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST::PARAMETERS);


###########################################################################
1;
