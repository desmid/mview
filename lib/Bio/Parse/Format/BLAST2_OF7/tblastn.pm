# -*- perl -*-
# Copyright (C) 2015-2017 Nigel P. Brown

###########################################################################
package Bio::Parse::Format::BLAST2_OF7::tblastn;

use strict;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Format::BLAST2_OF7);


###########################################################################
package Bio::Parse::Format::BLAST2_OF7::tblastn::HEADER;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Format::BLAST2_OF7::HEADER);


###########################################################################
package Bio::Parse::Format::BLAST2_OF7::tblastn::SEARCH;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Format::BLAST2_OF7::SEARCH);


###########################################################################
package Bio::Parse::Format::BLAST2_OF7::tblastn::SEARCH::RANK;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Format::BLAST2_OF7::SEARCH::RANK);


###########################################################################
package Bio::Parse::Format::BLAST2_OF7::tblastn::SEARCH::MATCH;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Format::BLAST2_OF7::SEARCH::MATCH);


###########################################################################
package Bio::Parse::Format::BLAST2_OF7::tblastn::SEARCH::MATCH::SUM;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Format::BLAST2_OF7::SEARCH::MATCH::SUM);


###########################################################################
package Bio::Parse::Format::BLAST2_OF7::tblastn::SEARCH::MATCH::ALN;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Format::BLAST2_OF7::SEARCH::MATCH::ALN);

my $MAP_ALN = { 'sframe' => 'sbjct_frame' };

sub new {
    my $type = shift;
    my $self = new Bio::Parse::Format::BLAST2_OF7::SEARCH::MATCH::ALN(@_);
    my $text = new Bio::Parse::Record_Stream($self);

    #BLAST2 -outfmt 7
    $self->{'sbjct_frame'} = '';

    my $fields = $self->get_parent(3)->get_record('HEADER')->{'fields'};
    Bio::Parse::Format::BLAST2_OF7::get_fields($text->next_line(1),
                                               $fields, $MAP_ALN, $self);

    if ($self->{'sbjct_frame'} eq '') {
        $self->die("blast column specifier 'sframe' is needed");
    }

    #prepend sign to forward frame
    $self->{'sbjct_frame'} = "+$self->{'sbjct_frame'}"
        if $self->{'sbjct_frame'} =~ /^\d+/;

    #record paired orientations in MATCH list
    push @{$self->get_parent(1)->{'orient'}->{
				 $self->{'query_orient'} .
				 $self->{'sbjct_orient'}
				}}, $self;
    bless $self, $type;
}

sub print_data {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    $self->SUPER::print_data($indent);
    printf "$x%20s -> %s\n",  'sbjct_frame',  $self->{'sbjct_frame'};
}


###########################################################################
1;
