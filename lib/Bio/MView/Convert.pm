# Copyright (C) 1997-2018 Nigel P. Brown

######################################################################
package Bio::MView::Convert;

use strict;

my $ROW_NUMBER_DELIM = ':';
my $ROW_DATA_DELIM   = ' ';

sub new {
    my $type = shift;
    my $self = {};

    $self->{'build'}   = shift;
    $self->{'align'}   = shift;
    $self->{'moltype'} = shift;
    $self->{'numbered'} = $self->{'build'}->is_search;

    bless $self, $type;
    $self;
}

#return an optional row number
sub row_number {
    my ($self, $row) = @_;
    return $row->num0 . $ROW_NUMBER_DELIM  if $self->{'numbered'};
    return '';
};

###########################################################################
my $PLAIN_ID_WIDTH = 20;  #default width for id' field

#return alignment in 'plain' format
sub plain {
    my ($self, $idw) = (@_, $PLAIN_ID_WIDTH);
    my ($bld, $aln, $s) = ($self->{'build'}, $self->{'align'}, '');
    foreach my $rid ($aln->visible_ids) {
        my $w = length($self->{'build'}->uid2row($rid)->cid);
        $idw = $w  if $w > $idw;
    }
    foreach my $rid ($aln->visible_ids) {
        #warn "[$rid]\n";
        $s .= $self->plain_row($rid, $idw);
    }
    \$s;
}

sub plain_row {
    my ($self, $rid, $idw) = @_;
    my $row = $self->{'build'}->uid2row($rid);

    my $head = sub {
        my $s = $self->row_number($row) . $row->cid;
	sprintf("%-${idw}s", substr($s, 0, $idw));
    };

    &$head . " " . $row->seq . "\n";
}


###########################################################################
my $PEARSON_SEQ_WIDTH = 70;

#return alignment in Pearson/FASTA format
sub pearson {
    my $self = shift;
    my ($bld, $aln, $s) = ($self->{'build'}, $self->{'align'}, '');
    foreach my $rid ($aln->visible_ids) {
        #warn "[$rid]\n";
        $s .= $self->pearson_row($rid);
    }
    \$s;
}

sub pearson_row {
    my ($self, $rid) = @_;
    my $row = $self->{'build'}->uid2row($rid);

    my $head = sub {
	">" . $self->row_number($row) . $row->cid;
    };

    my $desc = sub {
        my $s = $row->row_as_string($ROW_DATA_DELIM, ['num', 'cid', 'seq']);
	$s . "\n";
    };

    my $sequence = sub {
	my $seq = $row->seq;
	my $len = length($seq);
	my $s = '';
	for (my $i=0; $i<$len; $i+=$PEARSON_SEQ_WIDTH) {
	    $s .= substr($seq, $i, $PEARSON_SEQ_WIDTH) . "\n";
	}
	$s;
    };

    join($ROW_DATA_DELIM, (&$head, &$desc)) . &$sequence;
}

###########################################################################
my $PIR_SEQ_WIDTH = 60;

#return alignment in PIR format
sub pir {
    my $self = shift;
    my ($bld, $aln, $s) = ($self->{'build'}, $self->{'align'}, '');
    foreach my $rid ($aln->visible_ids) {
        #warn "[$rid]\n";
        $s .= $self->pir_row($rid);
    }
    \$s;
}

sub pir_row {
    my ($self, $rid) = @_;
    my $row = $self->{'build'}->uid2row($rid);

    my $head = sub {
	my $s = $self->{'moltype'} eq 'aa' ? ">P1;" : ">XX;";
        $s .= $self->row_number($row) . $row->cid . "\n";
    };

    my $desc = sub {
        my $s = $row->row_as_string($ROW_DATA_DELIM, ['num', 'cid', 'seq']);
	$s = '.'  if $s eq '';
	$s;
    };

    my $sequence = sub {
	my $seq = $row->seq;
	my $len = length($seq);
	my $s = '';
	for (my $i=0; $i<$len; $i+=$PIR_SEQ_WIDTH) {
	    $s .= "\n" . substr($seq, $i, $PIR_SEQ_WIDTH);
	}
	$s .= "\n"    if length($s) % ($PIR_SEQ_WIDTH+1) < 1 and $s ne '';
	$s .= "*\n\n";
    };

    &$head . &$desc . &$sequence;
}

###########################################################################
#return alignment in RDB table format
sub rdb {
    my $self = shift;
    my ($bld, $aln, $s) = ($self->{'build'}, $self->{'align'}, '');
    $s .= $bld->index2row(0)->row_as_rdb_string('attr') . "\n";
    $s .= $bld->index2row(0)->row_as_rdb_string('form') . "\n";
    foreach my $rid ($aln->visible_ids) {
        my $row = $bld->uid2row($rid);
        $s .= $row->row_as_rdb_string('data') . "\n";
    }
    \$s;
}

###########################################################################
my $MSF_SEQ_WIDTH = 50;

#return alignment in MSF format
sub msf {
    my $self = shift;
    my ($bld, $aln, $s) = ($self->{'build'}, $self->{'align'}, '');

    my $CHECKSUM = '--------------------------------------&---*---.-----------------@ABCDEFGHIJKLMNOPQRSTUVWXYZ------ABCDEFGHIJKLMNOPQRSTUVWXYZ---~---------------------------------------------------------------------------------------------------------------------------------';

    my $checksum = sub {
	my $s = shift;
	my ($sum, $ch) = (0, 0);
	my $len = length($$s);
	while ($len--) {
	    $ch = ord substr($$s, $len, 1);
	    $ch = substr($CHECKSUM, $ch, 1);
	    $sum += (($len % 57) + 1) * ord $ch  if $ch ne '-';
	}
	$sum % 10000;
    };

    my $now = `date '+%B %d, %Y %H:%M'`;
    $now =~ s/\s0(\d{1})/ $1/; chomp $now; #padding %-d may not work

    if ($self->{'moltype'} eq 'aa') {
        $s .= "!!AA_MULTIPLE_ALIGNMENT 1.0\n";
    } else {
        $s .= "!!NA_MULTIPLE_ALIGNMENT 1.0\n";
    }
    $s .= "PileUp (MView)\n\n";
    $s .= sprintf("   MSF: %5d  Type: %s  %s  Check: %4d  ..\n\n",
          $aln->length, ($self->{'moltype'} eq 'aa' ? 'P' : 'N'), $now, 0);

    my (%names, %seq, $w);

    $w = 0;
    foreach my $rid ($aln->visible_ids) {
        my $row = $bld->uid2row($rid);
        my $name = $self->row_number($row) . $row->cid;
        $w = length($name)  if length($name) > $w;
        $names{$rid} = $name;
    }

    foreach my $rid ($aln->visible_ids) {
        my $row = $bld->uid2row($rid);
        $s .= sprintf(" Name: %-${w}s Len: %5d  Check: %4d  Weight:  %4.2f\n",
                      $names{$rid}, $aln->length, &$checksum(\$row->seq), 1.0);
    }
    $s .= "\n//\n\n";

    foreach my $rid ($aln->visible_ids) {
        $seq{$rid} = $bld->uid2row($rid)->seq;
    }

  LOOP:
    for (my $from = 0; ;$from += $MSF_SEQ_WIDTH) {
        my $ruler = 1;
        foreach my $rid ($aln->visible_ids) {
            last LOOP    if $from >= length($seq{$rid});
            my $row = $bld->uid2row($rid);
            my $tmp = substr($seq{$rid}, $from, $MSF_SEQ_WIDTH);
            my $tmplen = length($tmp);
            if ($ruler) {
                my $lo = $from + 1; my $hi = $from + $tmplen;
                $ruler = $tmplen - length("$lo") - length("$hi");
                $ruler = 1  if $ruler < 1;
                my $insert = int($tmplen / 10);
                $insert -= 1  if $tmplen % 10 == 0;
                $insert += $ruler;
                $insert = sprintf("%d%s%d", $lo, ' ' x $insert, $hi);
                $s .= sprintf("%-${w}s $insert\n", '');
                $ruler = 0;
            }
            $s .= sprintf("%-${w}s ", $names{$rid});
            for (my $lo=0; $lo<$tmplen; $lo+=10) {
                $s .= substr($tmp, $lo, 10);
                $s .= ' '    if $lo < 40;
            }
            $s .= "\n";
        }
        $s .= "\n";
    }
    \$s;
}

###########################################################################
my $CLUSTAL_SEQ_WIDTH    = 60;
my $CLUSTAL_NAME_WIDTH   = 16;
my $CLUSTAL_RULER        = 1;
my $CLUSTAL_CONSERVATION = 1;

#return alignment in CLUSTAL/aln format
sub clustal {
    my $self = shift;
    my ($bld, $aln, $s) = ($self->{'build'}, $self->{'align'}, '');

    my $symcount = sub {
	my ($s, $pad, $gap, $c) = (@_, 0);
	my @s = split('', $$s);
	for (my $i=0; $i<@s; $i++) {
	    $c += 1  unless $s[$i] eq $pad or $s[$i] eq $gap;
	}
	$c;
    };

    $s .= "CLUSTAL 2.1 multiple sequence alignment (MView)\n\n\n";

    my $w = $CLUSTAL_NAME_WIDTH;

    my @ids = $aln->visible_ids;
    my (%names, %seq, %len, $pad, $gap);

    foreach my $rid (@ids) {
        my $row = $bld->uid2row($rid);
        #warn $rid, $row, "\n";
        my $name = $self->row_number($row) . $row->cid;
        $w = length($name)+1  if length($name) >= $w;
        $names{$rid} = $name;
        $seq{$rid} = $row->seq;
        $len{$rid} = 0;
        $pad = $row->sob->get_pad;
        $gap = $row->sob->get_gap;
    }

  LOOP:
    for (my $from = 0; ;$from+=$CLUSTAL_SEQ_WIDTH) {
        foreach my $rid ($aln->visible_ids) {
            last LOOP  if $from >= length($seq{$rid});
            my $row = $bld->uid2row($rid);
            my $tmp = substr($seq{$rid}, $from, $CLUSTAL_SEQ_WIDTH);
            $s .= sprintf("%-${w}s", $names{$rid});
            $s .= $tmp;
            if ($CLUSTAL_RULER) {
                my $syms = &$symcount(\$tmp, $pad, $gap);
                my $hi = $len{$rid} + $syms;
                $s .= sprintf(" %-d", $hi)  if $syms > 0;
                $len{$rid} = $hi;
            }
            $s .= "\n";
        }

        if ($CLUSTAL_CONSERVATION) {
            $s .= sprintf("%-${w}s", '');
            $s .= ${$aln->conservation(\@ids, $from + 1,
                                       $from + $CLUSTAL_SEQ_WIDTH,
                                       $self->{'moltype'})};
        }
        $s .= "\n\n";
    }
    \$s;
}


###########################################################################
1;
