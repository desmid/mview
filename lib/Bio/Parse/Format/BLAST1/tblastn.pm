# Copyright (C) 1996-2015 Nigel P. Brown

# This file is part of MView. 
# MView is released under license GPLv2, or any later version.

###########################################################################
package Bio::Parse::Format::BLAST1::tblastn;

use Bio::Parse::Format::BLAST1::blastx;
use Bio::Parse::Format::BLAST1::tblastx;
use strict;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Format::BLAST1::blastx);


###########################################################################
package Bio::Parse::Format::BLAST1::tblastn::HEADER;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Format::BLAST1::blastx::HEADER);


###########################################################################
package Bio::Parse::Format::BLAST1::tblastn::RANK;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Format::BLAST1::tblastx::RANK);


###########################################################################
package Bio::Parse::Format::BLAST1::tblastn::MATCH;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Format::BLAST1::blastx::MATCH);


###########################################################################
package Bio::Parse::Format::BLAST1::tblastn::MATCH::SUM;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Format::BLAST1::blastx::MATCH::SUM);


###########################################################################
package Bio::Parse::Format::BLAST1::tblastn::MATCH::ALN;

use vars qw(@ISA);
use Bio::Util::Regexp;

@ISA = qw(Bio::Parse::Format::BLAST1::MATCH::ALN);

sub new {
    my $type = shift;
    if (@_ < 2) {
        #at least two args, ($offset, $bytes are optional).
        Bio::Message::die($type, "new() invalid argument list (@_)");
    }
    my ($parent, $text, $offset, $bytes) = (@_, -1, -1);
    my ($self, $line, $record);

    $self = new Bio::Parse::Record($type, $parent, $text, $offset, $bytes);
    $text = new Bio::Parse::Scanner($self);

    #Score line
    $line = $text->next_line;

    if ($line =~ /^\s*
        Score\s*=\s*
        ($RX_Uint)                           #score
        \s+
        \(($RX_Ureal)\s+bits\),              #bits
        \s+
        Expect\s*=\s*
        ($RX_Ureal),                         #expectation
        \s+
        (?:Sum\sP\((\d+)\)|P)\s*=\s*         #number of frags
        ($RX_Ureal)                          #p-value
        /xo) {

        $self->test_args(\$line, $1, $2, $3, $5);

        (
         $self->{'score'},
         $self->{'bits'},
         $self->{'expect'},
         $self->{'n'},                       #substitute 1 unless $4
         $self->{'p'},
        ) = ($1, $2, $3, defined $4?$4:1, $5);
    }
    else {
        $self->warn("expecting 'Score' line: $line");
    }

    #Identities line
    $line = $text->next_line;

    if ($line =~ /^\s*
        Identities\s*=\s*
        (\d+\/\d+)                           #identities fraction
        \s+
        \((\d+)%\),                          #identities percentage
        \s+
        Positives\s*=\s*
        (\d+\/\d+)                           #positives fraction
        \s+
        \((\d+)%\)                           #positives percentage
        ,\s+Frame\s*=\s*
        ([+-])                               #frame sign
        (\d+)                                #frame number
        /xo) {

        $self->test_args(\$line, $1, $2, $3, $4, $5, $6);

        (
         $self->{'id_fraction'},
         $self->{'id_percent'},
         $self->{'pos_fraction'},
         $self->{'pos_percent'},
         $self->{'sbjct_frame'},
        ) = ($1, $2, $3, $4, $5 . $6);

        #record sbjct orientation in MATCH list
        push @{$parent->{'orient'}->{$self->{'sbjct_frame'}}}, $self;

    } else {
        $self->warn("expecting 'Identities' line: $line");
    }

    $self->parse_alignment($text);

    $self;
}

sub print_data {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    $self->SUPER::print_data($indent);
    printf "$x%20s -> %s\n",  'score',        $self->{'score'};
    printf "$x%20s -> %s\n",  'bits',         $self->{'bits'};
    printf "$x%20s -> %s\n",  'expect',       $self->{'expect'};
    printf "$x%20s -> %s\n",  'p',            $self->{'p'};
    printf "$x%20s -> %s\n",  'n',            $self->{'n'};
    printf "$x%20s -> %s\n",  'id_fraction',  $self->{'id_fraction'};
    printf "$x%20s -> %s\n",  'id_percent',   $self->{'id_percent'};
    printf "$x%20s -> %s\n",  'pos_fraction', $self->{'pos_fraction'};
    printf "$x%20s -> %s\n",  'pos_percent',  $self->{'pos_percent'};
    printf "$x%20s -> %s\n",  'sbjct_frame',  $self->{'sbjct_frame'};
}


###########################################################################
package Bio::Parse::Format::BLAST1::tblastn::WARNING;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Format::BLAST::WARNING);


###########################################################################
package Bio::Parse::Format::BLAST1::tblastn::HISTOGRAM;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Format::BLAST::HISTOGRAM);


###########################################################################
package Bio::Parse::Format::BLAST1::tblastn::PARAMETERS;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Format::BLAST::PARAMETERS);


###########################################################################
1;
