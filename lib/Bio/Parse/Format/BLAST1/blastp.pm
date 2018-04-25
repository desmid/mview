# -*- perl -*-
# Copyright (C) 1996-2015 Nigel P. Brown

###########################################################################
package Bio::Parse::Format::BLAST1::blastp;

use strict;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Format::BLAST1);

my $NULL      = '^\s*$';
my $RANK_NONE = '^\s*\*\*\* NONE';
my $RANK_CUT  = 60;


###########################################################################
package Bio::Parse::Format::BLAST1::blastp::HEADER;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Format::BLAST1::HEADER);


###########################################################################
package Bio::Parse::Format::BLAST1::blastp::RANK;

use vars qw(@ISA);
use Bio::Parse::Regexps;

@ISA = qw(Bio::Parse::Format::BLAST1::RANK);

sub new {
    my $type = shift;
    if (@_ < 2) {
	#at least two args, ($offset, $bytes are optional).
	Bio::Message::die($type, "new() invalid argument list (@_)");
    }
    my ($parent, $text, $offset, $bytes) = (@_, -1, -1);
    my ($self, $line, $record);

    $self = new Bio::Parse::Record($type, $parent, $text, $offset, $bytes);
    $text = new Bio::Parse::Record_Stream($self);

    #column headers
    $self->{'header'} = $text->scan_lines(5);

    #ranked search hits
    $self->{'hit'}    = [];

    while (defined ($line = $text->next_line(1))) {
	
	#blank line or empty record: ignore
        next    if $line =~ /$NULL/o;

	#GCG annotation: ignore
        next    if $line =~ /$Bio::Parse::Format::BLAST::GCG_JUNK/o;

	#empty ranking: done
        last    if $line =~ /$RANK_NONE/o;

	#excise variable length description and append it
	my $tmp = substr($line, 0, $RANK_CUT);
	if ($tmp =~ /^\s*([^\s]+)(.*)/o) {
	    $line = $1 . substr($line, $RANK_CUT) . $2;
	}

	if ($line =~ /\s*
	    ([^\s]+)                          #id
	    \s+
	    ($RX_Uint)                        #score
	    \s+
	    ($RX_Ureal)                       #p-value
	    \s+
	    ($RX_Uint)                        #n fragments
	    \s*
	    \!?                               #GCG junk
	    \s*
	    (.*)                              #summary
	    /xo) {

	    $self->test_args(\$line, $1, $2, $3, $4); #ignore $5
	    
	    push @{$self->{'hit'}}, 
	    {
	     'id'      => Bio::Parse::Record::clean_identifier($1),
	     'score'   => $2,
	     'p'       => $3,
	     'n'       => $4,
	     'summary' => Bio::Parse::Record::strip_trailing_space($5),
	    };

	    next;
	}
	
	#default
	$self->warn("unknown field: $line");
    }
    $self;
}


###########################################################################
package Bio::Parse::Format::BLAST1::blastp::MATCH;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Format::BLAST1::MATCH);


###########################################################################
package Bio::Parse::Format::BLAST1::blastp::MATCH::SUM;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Format::BLAST1::MATCH::SUM);


###########################################################################
package Bio::Parse::Format::BLAST1::blastp::MATCH::ALN;

use vars qw(@ISA);
use Bio::Parse::Regexps;

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
    $text = new Bio::Parse::Record_Stream($self);

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
	/xo) {
	
	$self->test_args(\$line, $1, $2, $3, $4);

	(
	 $self->{'id_fraction'},
	 $self->{'id_percent'},
	 $self->{'pos_fraction'},
	 $self->{'pos_percent'},
	) = ($1, $2, $3, $4);

	#record query orientation in MATCH list (always +)
	push @{$parent->{'orient'}->{'+'}}, $self;
	
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
}


###########################################################################
package Bio::Parse::Format::BLAST1::blastp::WARNING;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Format::BLAST::WARNING);


###########################################################################
package Bio::Parse::Format::BLAST1::blastp::HISTOGRAM;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Format::BLAST::HISTOGRAM);


###########################################################################
package Bio::Parse::Format::BLAST1::blastp::PARAMETERS;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Format::BLAST::PARAMETERS);


###########################################################################
1;
