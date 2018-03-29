# Copyright (C) 1997-2018 Nigel P. Brown

use strict;

###########################################################################
package Bio::MView::Display::Display;

use Bio::MView::Display::Any;
use Bio::MView::Display::Ruler;

my $Default_Width         = 80;        #sequence display width
my $Default_Separator     = "\n";      #output record separator
my $Default_Gap           = '-';       #sequence gap character
my $Default_Pad           = '';        #sequence trailing space character
my $Default_Overlap       = '%';       #sequence overlap character
my $Default_Overlap_Color = '#474747'; #sequence overlap color if HTML
my $Default_Ruler         = 'abs';     #ruler is absolute from start of sequence
my $Default_HTML          = 0;         #produce HTML?
my $Default_Bold          = 0;         #embolden some text
my $Default_Label0        = 1;         #show label0
my $Default_Label1        = 1;         #show label1
my $Default_Label2        = 1;         #show label2
my $Default_Label3        = 1;         #show label3
my $Default_Label4        = 1;         #show label4
my $Default_Label5        = 1;         #show label5
my $Default_Label6        = 1;         #show label6
my $Default_Label7        = 1;         #show label7

my $Spacer                = ' ';       #space between output columns

my %Template = (
    'string'    => undef, #parent sequence string
    'length'    => 0,     #parent sequence length
    'start'     => undef, #forward start position of parent sequence
    'stop'      => undef, #forward stop position of parent sequence
    'object'    => undef, #ordered list of display objects
    'posnwidth' => 0,     #string width of left/right sequence position
    'labwidth0' => 0,     #string width of zeroth title block
    'labwidth1' => 0,     #string width of first title block
    'labwidth2' => 0,     #string width of second title block
    'labwidth3' => 0,     #string width of third title block
    'labwidth4' => 0,     #string width of fourth title block
    'labwidth5' => 0,     #string width of fifth title block
    'labwidth6' => 0,     #string width of sixth title block
    'labwidth7' => 0,     #string width of seventh title block
    );

my %Known_Types = (
    'Ruler'    => 1,
    'Sequence' => 1,
    'Subrange' => 1,
    );

sub new {
    my $type = shift;
    die "$type::new() missing arguments\n"  unless @_;
    my $sequence = shift;

    my $self = { %Template };
    bless $self, $type;

    $self->{'string'}    = $sequence;
    $self->{'length'}    = $sequence->length;
    $self->{'start'}     = $sequence->lo;
    #$self->{'stop'}      = $sequence->hi;
    $self->{'stop'}      = $self->{'start'} + $self->{'length'} - 1;

    #my $tmp = abs($self->{'stop'}-$self->{'start'})+1;
    #warn "$self->{'start'} $self->{'stop'} :  $self->{length}  $tmp";

    $self->{'posnwidth'} = length(max($self->{'start'}, $self->{'stop'}));
    $self->{'object'}    = [];

    $self->append(@_)  if @_;

    $self;
}

######################################################################
# public methods
######################################################################
#force break of back references to allow garbage collection
sub free {
    #warn "${_[0]}::Display::free\n";
    while (my $o = shift @{$_[0]->{'object'}}) { $o->free }
}

sub length { $_[0]->{'length'} }

sub display {
    my ($self, $stm) = (shift, shift);
    my %par = @_;

    $par{'width'}  = $Default_Width            unless exists $par{'width'};
    $par{'gap'}    = $Default_Gap              unless exists $par{'gap'};
    $par{'pad'}    = $Default_Pad              unless exists $par{'pad'};
    $par{'rec'}    = $Default_Separator        unless exists $par{'rec'};
    $par{'ruler'}  = $Default_Ruler            unless exists $par{'ruler'};
    $par{'bold'}   = $Default_Bold             unless exists $par{'bold'};
    $par{'label0'} = $Default_Label0           unless exists $par{'label0'};
    $par{'label1'} = $Default_Label1           unless exists $par{'label1'};
    $par{'label2'} = $Default_Label2           unless exists $par{'label2'};
    $par{'label3'} = $Default_Label3           unless exists $par{'label3'};
    $par{'label4'} = $Default_Label4           unless exists $par{'label4'};
    $par{'label5'} = $Default_Label5           unless exists $par{'label5'};
    $par{'label6'} = $Default_Label6           unless exists $par{'label6'};
    $par{'label7'} = $Default_Label7           unless exists $par{'label7'};

    $par{'posnwidth'} = $self->{'posnwidth'}   unless exists $par{'posnwidth'};

    $par{'labwidth0'} = $self->{'labwidth0'}   unless exists $par{'labwidth0'};
    $par{'labwidth1'} = $self->{'labwidth1'}   unless exists $par{'labwidth1'};
    $par{'labwidth2'} = $self->{'labwidth2'}   unless exists $par{'labwidth2'};
    $par{'labwidth3'} = $self->{'labwidth3'}   unless exists $par{'labwidth3'};
    $par{'labwidth4'} = $self->{'labwidth4'}   unless exists $par{'labwidth4'};
    $par{'labwidth5'} = $self->{'labwidth5'}   unless exists $par{'labwidth5'};
    $par{'labwidth6'} = $self->{'labwidth6'}   unless exists $par{'labwidth6'};
    $par{'labwidth7'} = $self->{'labwidth7'}   unless exists $par{'labwidth7'};

    $par{'html'} = 1    if $par{'bold'};
    if ($par{'html'}) {
        $par{'lap'}   = $Default_Overlap_Color unless exists $par{'lap'};
    } else {
        $par{'lap'}   = $Default_Overlap       unless exists $par{'lap'};
    }

    if ($par{'width'} < 1) {
        #full length display if meaningless column count
        $par{'width'} = $self->{'length'};
    }
    if (CORE::length $par{'gap'} != 1) {
        warn "${self}::display: gap must be single character '$par{'gap'}'\n";
        $par{'gap'} = $Default_Gap;
    }
    if (CORE::length $par{'pad'} > 1) {
        warn "${self}::display: pad must be null or single character '$par{'pad'}'\n";
        $par{'pad'} = $Default_Pad;
    }

    #map { warn "$_ => '$par{$_}'\n" } sort keys %par;

    my ($prefix, $suffix) = $par{'bold'} ? ('<STRONG>','</STRONG>') : ('','');

    print $stm "<PRE>\n"  if $par{'html'};

    map { $_->reset } @{$self->{'object'}};

    #need space for sequence numbers?
    my $posnwidth = 0;
    foreach my $o (@{$self->{'object'}}) {
        if ($o->{'number'}) {
            $posnwidth = 1;
            last;
        }
    }

    #iterate over display panes, if any objects
  OUTER:
    while (@{$self->{'object'}}) {

        #Universal::vmstat("display pane");

        #do one pane
        foreach my $o (@{$self->{'object'}}) {

            #do one line
            my $s = $o->next($par{'html'}, $par{'bold'}, $par{'width'},
                             $par{'gap'}, $par{'pad'}, $par{'lap'},
                             $par{'ruler'});

            last OUTER  unless $s; #this terminates
            #warn "[ @$s ]\n";

            #clear new row
            my (@row) = ();

            #### rownum ############
            if ($par{'label0'} and $par{'labwidth0'}) {
                push @row, label_rownum(\%par, $o);
                push @row, $Spacer;
            }

            #### identifier ############
            if ($par{'label1'} and $par{'labwidth1'}) {
                push @row, label_identifier(\%par, $o);
                push @row, $Spacer;
            }

            #### info columns ############

            #label2
            if ($par{'label2'} and $par{'labwidth2'}) {
                push @row, sprintf("%-$par{'labwidth2'}s", $o->label2);
                push @row, $Spacer;
            }

            #label3
            if ($par{'label3'} and $par{'labwidth3'}) {
                push @row, sprintf("%$par{'labwidth3'}s", $o->label3);
                push @row, $Spacer;
            }

            #label4
            if ($par{'label4'} and $par{'labwidth4'}) {
                push @row, sprintf("%$par{'labwidth4'}s", $o->label4);
                push @row, $Spacer;
            }

            #label5
            if ($par{'label5'} and $par{'labwidth5'}) {
                push @row, sprintf("%$par{'labwidth5'}s", $o->label5);
                push @row, $Spacer;
            }

            #label6
            if ($par{'label6'} and $par{'labwidth6'}) {
                push @row, sprintf("%$par{'labwidth6'}s", $o->label6);
                push @row, $Spacer;
            }

            #label7
            if ($par{'label7'} and $par{'labwidth7'}) {
                push @row, sprintf("%$par{'labwidth7'}s", $o->label7);
                push @row, $Spacer;
            }

            #### left position ############
            if ($posnwidth) {
                if ($o->{'number'}) {
                    push @row, sprintf("$prefix%$par{'posnwidth'}d$suffix",
                                       $s->[0]);
                } else {
                    push @row, sprintf("$prefix%$par{'posnwidth'}s$suffix",
                                       ' ');
                }
            }
            push @row, $Spacer;

            #### sequence string ############
            push @row, $s->[1];
            push @row, $Spacer;

            #### right position ############
            if ($posnwidth) {
                if ($o->{'number'}) {
                    push @row, sprintf("$prefix%-$par{'posnwidth'}d$suffix",
                                       $s->[2]);
                } else {
                    push @row,
                        sprintf("$prefix%-$par{'posnwidth'}s$suffix", '');
                }
            }
            push @row, "\n";

            #### output row ############
            print $stm @row;

        } #foreach

        #record separator
        print $stm $par{'rec'}    unless $self->{'object'}->[0]->done;

        #Universal::vmstat("display loop done");
    } #while

    print $stm "</PRE>\n"  if $par{'html'};
}

sub append {
    my $self = shift;
    #warn "${self}::append(@_)\n";

    #handle data rows
    foreach my $row (@_) {
        my $type;

        #check row 'type' exists and is valid
        if (exists $row->{'type'}) {
            $type = ucfirst $row->{'type'};
        } else {
            warn "${self}::append: missing type in '$row'\n";
            next;
        }
        unless (exists $Known_Types{$type}) {
            warn "${self}::append: unknown alignment type '$type'\n";
            next;
        }

        next  if $type eq 'Ruler';

        #construct row object
        no strict 'refs';
        $type = "Bio::MView::Display::$type"->new($self, $row);
        use strict 'refs';

        push @{$self->{'object'}}, $type;

        # warn "[", $type->label0, ",", $type->label1, ",", $type->label2,
        # $type->label3, ",", $type->label4, ",", $type->label5,
        # $type->label6, ",", $type->label7, "]\n";

        $self->{'labwidth0'} = max($self->{'labwidth0'}, length($type->label0));
        $self->{'labwidth1'} = max($self->{'labwidth1'}, length($type->label1));
        $self->{'labwidth2'} = max($self->{'labwidth2'}, length($type->label2));
        $self->{'labwidth3'} = max($self->{'labwidth3'}, length($type->label3));
        $self->{'labwidth4'} = max($self->{'labwidth4'}, length($type->label4));
        $self->{'labwidth5'} = max($self->{'labwidth5'}, length($type->label5));
        $self->{'labwidth6'} = max($self->{'labwidth6'}, length($type->label6));
        $self->{'labwidth7'} = max($self->{'labwidth7'}, length($type->label7));
    }

    #handle header/ruler
    foreach my $row (@_) {
        my $type;

        #check row 'type' exists and is valid
        if (exists $row->{'type'}) {
            $type = ucfirst $row->{'type'};
        } else {
            next;
        }
        next  unless exists $Known_Types{$type};

        next  if $type ne 'Ruler';

        #construct row object
        no strict 'refs';
        $type = "Bio::MView::Display::$type"->new($self, $row);
        use strict 'refs';

        push @{$self->{'object'}}, $type;

        # warn "[", $type->label0, ",", $type->label1, ",", $type->label2,
        # $type->label3, ",", $type->label4, ",", $type->label5,
        # $type->label6, ",", $type->label7, ",", "]\n";

        $self->{'labwidth0'} = max($self->{'labwidth0'}, length($type->label0))
            if $self->{'labwidth0'};
        $self->{'labwidth1'} = max($self->{'labwidth1'}, length($type->label1))
            if $self->{'labwidth1'};
        $self->{'labwidth2'} = max($self->{'labwidth2'}, length($type->label2))
            if $self->{'labwidth2'};
        $self->{'labwidth3'} = max($self->{'labwidth3'}, length($type->label3))
            if $self->{'labwidth3'};
        $self->{'labwidth4'} = max($self->{'labwidth4'}, length($type->label4))
            if $self->{'labwidth4'};
        $self->{'labwidth5'} = max($self->{'labwidth5'}, length($type->label5))
            if $self->{'labwidth5'};
        $self->{'labwidth6'} = max($self->{'labwidth6'}, length($type->label6))
            if $self->{'labwidth6'};
        $self->{'labwidth7'} = max($self->{'labwidth7'}, length($type->label7))
            if $self->{'labwidth7'};
    }
    #Universal::vmstat("Display::append done");
}

######################################################################
# private class methods
######################################################################
sub label_rownum {
    my ($par, $o) = @_;
    my ($w, $s) = ($par->{'labwidth0'}, $o->label0);
    return sprintf("%${w}s", $s)  if $s =~ /^\d+$/;  #numeric - right justify
    return sprintf("%-${w}s", $s);                   #string  - left justify
}

sub label_identifier {
    my ($par, $o) = @_;
    my @tmp = ();
    my ($w, $s, $url) = ($par->{'labwidth1'}, $o->label1, $o->{'url'});
    #left justify
    if ($par->{'html'} and $url) {
        push @tmp, "<A HREF=\"$url\">", $s, "</A>";
        push @tmp, " " x ($w - CORE::length($s));
        return @tmp;
    }
    return sprintf("%-${w}s", $s);
}

sub max { $_[0] > $_[1] ? $_[0] : $_[1] }

######################################################################
# debug
######################################################################
#sub DESTROY { warn "DESTROY $_[0]\n" }

sub dump {
    my $self = shift;
    foreach my $k (sort keys %$self) {
        printf "%15s => %s\n", $k, $self->{$k};
    }
    map { $_->dump } @{$self->{'object'}};
}

###########################################################################
1;
