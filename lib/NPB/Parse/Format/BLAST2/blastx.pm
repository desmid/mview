# -*- perl -*-
# Copyright (C) 1996-2015 Nigel P. Brown
# $Id: blastx.pm,v 1.10 2015/06/14 17:09:04 npb Exp $

###########################################################################
package NPB::Parse::Format::BLAST2::blastx;

use strict;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST2);


###########################################################################
package NPB::Parse::Format::BLAST2::blastx::HEADER;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST::HEADER);


###########################################################################
package NPB::Parse::Format::BLAST2::blastx::SEARCH;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST2::SEARCH);


###########################################################################
package NPB::Parse::Format::BLAST2::blastx::SEARCH::RANK;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST2::SEARCH::RANK);


###########################################################################
package NPB::Parse::Format::BLAST2::blastx::SEARCH::MATCH;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST::MATCH);


###########################################################################
package NPB::Parse::Format::BLAST2::blastx::SEARCH::MATCH::SUM;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST::MATCH::SUM);


###########################################################################
package NPB::Parse::Format::BLAST2::blastx::SEARCH::MATCH::ALN;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST2::SEARCH::MATCH::ALN);

sub new {
    my $type = shift;
    my ($parent) = @_;
    my $self = new NPB::Parse::Format::BLAST2::SEARCH::MATCH::ALN(@_);
    bless $self, $type;

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

    $self;
}

sub print_data {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    $self->SUPER::print_data($indent);
    printf "$x%20s -> %s\n",  'query_frame',  $self->{'query_frame'} if
	exists $self->{'query_frame'};
}

###########################################################################
package NPB::Parse::Format::BLAST2::blastx::WARNING;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST::WARNING);


###########################################################################
package NPB::Parse::Format::BLAST2::blastx::PARAMETERS;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Format::BLAST::PARAMETERS);


###########################################################################
1;
