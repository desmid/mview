# Copyright (C) 1997-2018 Nigel P. Brown

###########################################################################
#
# NCBI BLAST 2.0, PSI-BLAST 2.0, BLAST+
#
#   blastp, blastn, blastx, tblastn, tblastx
#
###########################################################################
package Bio::MView::Build::Format::BLAST2;

use Bio::MView::Option::Parameters;  #for $PAR
use Bio::MView::Build::Format::BLAST0;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::BLAST0);

sub begin_parse {
    my $self = shift;
    my $s = $self->{'entry'}->parse("SEARCH[@{[ $self->cycle ]}]");
    return ()  unless defined $s;
    my $r = $s->parse(qw(RANK));
    return ()  unless defined $r;
    my $h  = $self->{'entry'}->parse(qw(HEADER));
    ($s, $h, $r);
}

sub end_parse { $_[0]->{'entry'}->free(qw(SEARCH)) }

sub parse_record {
    my ($self, $k, $hdr, $sum, $aln) = @_;

    #sub str { join ", ", map { defined $_ ? $_ : 'undef' } @_ }
    #warn "[@{[str($k, $hdr, $sum, $aln)]}]\n";

    my ($id, $desc, $bits, $expect, $n) = ('','','','','');

    $k = ''  unless defined $k;  #row number = rank

    if (defined $hdr) {
        ($id, $desc) = ($hdr->{'query'}, $hdr->{'summary'});
    } elsif (defined $sum) {
        ($id, $desc) = ($sum->{'id'},    $sum->{'desc'});
    } elsif (defined $aln) {
        ($id, $desc) = ($aln->{'id'},    $aln->{'summary'});
    }
    if (defined $aln) {
        ($bits, $expect, $n) = ($aln->{'bits'}, $aln->{'expect'}, $aln->{'n'});
    }

    my $info = {
        'cycle'  => $self->cycle,
        'bits'   => $bits,
        'expect' => $expect,
        'n'      => $n,
    };

    #extract any optional fields from BLAST_OF7
    my $item;
    if (defined $hdr and exists $hdr->{'extra'}) {
        $item = $hdr;
    } elsif (defined $aln and exists $aln->{'extra'}) {
        $item = $aln;
    }
    if (defined $item) {
        map { my ($k,$v) = split("\001"); $info->{$k} = $v }
            split("\000", $item->{'extra'});
    }
    #use Bio::Util::Object qw(dump_hash); warn dump_hash($info);

    return ($k, $id, $desc, $info);
}

sub get_scores {
    my ($self, $list) = @_;
    my @tmp = $self->SUPER::get_scores($list);
    return ()  unless @tmp;

    my $bits = \$tmp[1];

    #try to preserve original precision/format as far as possible
    my $val = sprintf("%.0f", $$bits);     #bits as integer
    if ($val != $$bits) {                  #num. different? put 1dp back
        $$bits = sprintf("%.1f", $$bits);  #bit score to 1 dp
    }

    @tmp;
}

#score/significance filter
sub skip_hsp {
    my ($self, $hsp) = @_;
    return 1  if
        defined $PAR->get('minbits') and $hsp->{'bits'} < $PAR->get('minbits');
    return 1  if
        defined $PAR->get('maxeval') and $hsp->{'expect'} > $PAR->get('maxeval');
    return 0;
}

#standard attribute names
sub attr_score { 'bits' }
sub attr_sig   { 'expect' }


###########################################################################
package Bio::MView::Build::Row::BLAST2;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLAST);

#suppress cycle in all output; it's only for blastp/psi-blastp
sub main_schema {[
    # use? rdb?  key              label          format   default
    [ 0,   0,    'cycle',         'cycle',       '2N',    ''   ],
    [ 2,   2,    'bits',          'bits',        '5N',    ''   ],
    [ 3,   3,    'expect',        'E-value',     '9N',    ''   ],
    [ 4,   4,    'n',             'N',           '2N',    ''   ],
    [ 5,   5,    'query_orient',  'qy',          '2S',    '?'  ],
    [ 6,   6,    'sbjct_orient',  'ht',          '2S',    '?'  ],
    ]
}

sub optional_schema {[
    # use? rdb?  key              label          format   default
    [ 0,    10,  'staxid',        'staxid',      '6S',    ''   ],
    [ 0,    11,  'ssciname',      'ssciname',    '6S',    ''   ],
    [ 0,    12,  'scomname',      'scomname',    '6S',    ''   ],
    [ 0,    13,  'sblastname',    'sblastname',  '6S',    ''   ],
    [ 0,    14,  'sskingdom',     'sskingdom',   '6S',    ''   ],
    [ 0,    15,  'staxids',       'staxids',     '6S',    ''   ],
    [ 0,    16,  'sscinames',     'sscinames',   '6S',    ''   ],
    [ 0,    17,  'scomnames',     'scomnames',   '6S',    ''   ],
    [ 0,    18,  'sblastnames',   'sblastnames', '6S',    ''   ],
    [ 0,    19,  'sskingdoms',    'sskingdoms',  '6S',    ''   ],
    ]
}

sub schema {
    my $self = shift;
    my @schema = @{$self->main_schema};
    foreach my $row (@{$self->optional_schema}) {
        my ($n1, $n2, $name, $label, $format, $default) = @$row;
        if (exists $self->{'info'}->{$name}) {
            push @schema, $row;
        }
    }
    return \@schema;
}


###########################################################################
package Bio::MView::Build::Row::BLAST2::blastp;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLAST2);

#enable cycle in rdb tabulated output
#suppress query and sbjct orientations for blastp data
sub main_schema {[
    # use? rdb?  key              label          format   default
    [ 0,   1,    'cycle',         'cycle',       '2N',    ''   ],
    [ 2,   2,    'bits',          'bits',        '5N',    ''   ],
    [ 3,   3,    'expect',        'E-value',     '9N',    ''   ],
    [ 4,   4,    'n',             'N',           '2N',    ''   ],
    [ 0,   0,    'query_orient',  'qy',          '2S',    '?'  ],
    [ 0,   0,    'sbjct_orient',  'ht',          '2S',    '?'  ],
    ]
}


###########################################################################
package Bio::MView::Build::Row::BLAST2::blastn;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLAST2);


###########################################################################
package Bio::MView::Build::Row::BLAST2::blastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLASTX);

sub main_schema { Bio::MView::Build::Row::BLAST2::main_schema }
sub optional_schema { Bio::MView::Build::Row::BLAST2::optional_schema }
sub schema { Bio::MView::Build::Row::BLAST2::schema($_[0]) }


###########################################################################
package Bio::MView::Build::Row::BLAST2::tblastn;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLAST2);


###########################################################################
package Bio::MView::Build::Row::BLAST2::tblastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Row::BLASTX);

sub main_schema { Bio::MView::Build::Row::BLAST2::main_schema }
sub optional_schema { Bio::MView::Build::Row::BLAST2::optional_schema }
sub schema { Bio::MView::Build::Row::BLAST2::schema($_[0]) }


###########################################################################
###########################################################################
package Bio::MView::Build::Format::BLAST2::blastp;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::BLAST2
          Bio::MView::Build::Format::BLAST0::blastp
);

sub scheduler { 'cycle' }

sub record_type { 'Bio::MView::Build::Row::BLAST2::blastp' }

sub subheader {
    my ($self, $quiet) = (@_, 0);
    my $s = '';
    return $s  if $quiet;
    $s  = $self->SUPER::subheader($quiet);
    $s .= "Search cycle: " . $self->cycle . "\n";
    $s;
}


###########################################################################
package Bio::MView::Build::Format::BLAST2::blastn;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::BLAST2
          Bio::MView::Build::Format::BLAST0::blastn
);

sub scheduler { 'strand' }

sub record_type { 'Bio::MView::Build::Row::BLAST2::blastn' }

sub subheader {
    my ($self, $quiet) = (@_, 0);
    my $s = '';
    return $s  if $quiet;
    $s  = $self->SUPER::subheader($quiet);
    $s .= "Query orientation: " . $self->strand . "\n";
    $s;
}


###########################################################################
package Bio::MView::Build::Format::BLAST2::blastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::BLAST2
          Bio::MView::Build::Format::BLAST0::blastx
);

sub scheduler { 'strand' }

sub record_type { 'Bio::MView::Build::Row::BLAST2::blastx' }

sub subheader {
    my ($self, $quiet) = (@_, 0);
    my $s = '';
    return $s    if $quiet;
    $s  = $self->SUPER::subheader($quiet);
    $s .= "Query orientation: " . $self->strand . "\n";
    $s;
}


###########################################################################
package Bio::MView::Build::Format::BLAST2::tblastn;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::BLAST2
          Bio::MView::Build::Format::BLAST0::tblastn
);

sub scheduler { 'none' }

sub record_type { 'Bio::MView::Build::Row::BLAST2::tblastn' }


###########################################################################
package Bio::MView::Build::Format::BLAST2::tblastx;

use vars qw(@ISA);

@ISA = qw(Bio::MView::Build::Format::BLAST2
          Bio::MView::Build::Format::BLAST0::tblastx
);

sub scheduler { 'strand' }

sub record_type { 'Bio::MView::Build::Row::BLAST2::tblastx' }

sub subheader {
    my ($self, $quiet) = (@_, 0);
    my $s = '';
    return $s  if $quiet;
    $s  = $self->SUPER::subheader($quiet);
    $s .= "Query orientation: " . $self->strand . "\n";
    $s;
}


###########################################################################
1;
