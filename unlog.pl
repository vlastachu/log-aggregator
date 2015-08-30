#!/usr/bin/perl
use strict;
use warnings;
use Time::Piece;
use Time::Seconds;
use Getopt::Long;

my $output = '';
my $error = ''; # can't find alias
my $help;
GetOptions (
    'error=s'  => \$error,
    'output=s' => \$output,
    'help'     => \$help);

if ($help){
    print q(
unlog.pl - aggregate log files for initialization/finalization info.

usage: unlog.pl [-o outfile] [-e errfile] inputfiles...
STDIN if no input files provided.

  -h, --help        this help text
  -o, --output      specify output file
                    default: STDOUT
  -e, --error       specify file for parse error log
                    default: STDERR
) and exit(0);
}

my $out = \*STDOUT;
my $err = \*STDERR;
unless($output eq '') {
    open($out, '>', $output)
      or die "Could not open file '$output' $!";
}
unless($error eq '') {
    open($err, '>', $error)
      or die "Could not open file '$error' $!";
}

my %order = (
    "NOT LAUNCHED"   => 0,
    "START STARTED"  => 1,
    "START COMPLETE" => 2,
    "STOP STARTED"   => 3,
    "STOP COMPLETE"  => 4,
);
# experiments shows that `keys %order` have indetirmenated order
my @val_order = ("NOT LAUNCHED", "START STARTED" ,"START COMPLETE", "STOP STARTED" ,"STOP COMPLETE");
# constants for state number
my $STARTING_END = 2;
my $ENDING_END = 4;

my $date_pattern   = '(\d\d\.\d\d\.\d\d\d\d \d\d:\d\d:\d\d)';
my $action_pattern = $date_pattern . ' (\w+): (START|STOP) (STARTED|COMPLETE)';
my $start_pattern  = $date_pattern . ' SYSTEM START'; 

# contain (name => [state order, date])
my %operation_state = ();

# operations info, which will be sorted and written to output
# could be "X started" => [date1, date2...] or "X stopped" => [...]
my %operations = ();

# main loop

my $starts_counter = 0;
while (my $line = <>) {
    if ($line =~ /$start_pattern/) {
        printSessionStats() if ++$starts_counter > 1;
        log_out("Start $starts_counter:\n");
    }
    elsif($line =~ /$action_pattern/) {
        my $date = Time::Piece->strptime($1, '%d.%m.%Y %H:%M:%S');
        my $state_num = $order{$3 . ' ' . $4};
        put_operation($2, $state_num, $date, $.) if check_order($2, $state_num, $.);
    }
    else {
        log_err("unparsed line: $line");
    }
}
printSessionStats();

# helper subroutines


sub printSessionStats {
    my @stack = sort (keys %operations);
    foreach my $operation (@stack) {
        my $str = $operation . " " . $operations{$operation}[0];
        for (my $i = 1; $i < scalar(@{$operations{$operation}}); $i++) {
            $str .= ", and than $operations{$operation}[$i]";
        }
        log_out($str . "\n");
    }
    %operations = ();
    foreach my $name (keys %operation_state) {
        if($operation_state{$name}[0] != $ENDING_END && 
            $operation_state{$name}[0] != $STARTING_END) {
            print "$name " . get_operation_name($operation_state{$name}[0]) . " didn't end\n";
        }
    }
    %operation_state = ();
}


sub put_operation {
    my ($operation_name, $state_num, $date, $line_number) = @_;
    if($state_num > 1){
        my $launch_time = $operation_state{$operation_name}[1];
        my $time_diff = $date - $launch_time;
        if($time_diff < 0) {
            log_err("incorrect time at line $line_number:\n".
                "\t$launch_time more than $date\n");
            return 0;
        }
        if($state_num == $STARTING_END 
            or $state_num == $ENDING_END){
            my $operation = $state_num == $STARTING_END?
                "$operation_name started" : "$operation_name stopped";
            $operations{$operation} = [] unless exists $operations{$operation};
            # unfortunnely pretty isn't ideal :(
            push $operations{$operation}, $time_diff->pretty();
        }
    }
    $operation_state{$operation_name} = [$state_num, $date];
}

sub get_operation_name {
    my ($operation_num) = @_;
    my $operation = lc $val_order[$operation_num];
    return substr($operation, 0, index($operation, ' '));
}

sub check_order {
    my ($operation_name, $state_num, $line_number) = @_;
    my $prev_state_num = $operation_state{$operation_name}[0] || 0;
    $prev_state_num = 0 if $prev_state_num == $ENDING_END;
    if($state_num == $prev_state_num + 1){
        return 1;
    }
    # TODO line number, more verbose
    log_err("incorrect order at line $line_number: \n".
        "\tjump from $val_order[$prev_state_num] to $val_order[$state_num]\n");
    return 0;
}

sub log_out {
    print $out $_ for (@_)
}

sub log_err {
    print $err $_ for (@_)
}