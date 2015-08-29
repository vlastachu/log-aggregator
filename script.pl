use strict;
use warnings;
use Time::Piece;
 
my $date_pattern = '\d\d\.\d\d\.\d\d\d\d \d\d:\d\d:\d\d';
my $action = $date_pattern . ' (\w+): (START|STOP) (STARTED|COMPLETE)';
my $start = $date_pattern . ' SYSTEM START';
my $datelen = 19;

my $system_starts = 1;
my %procedure_time = ();
my @stack = ();

# write last iteration statistic and reinitialize values
# could be used on first iteration
sub printSessionStats{
	@stack = sort @stack;
	print for (@stack);
	@stack = ();
	foreach my $name (keys %procedure_time) {
		print "$name ". (lc $procedure_time{$name}[1]). " didn't end\n";
	}
	%procedure_time = ();
}


my $filename = 'tests/sample.txt';
open(my $fh, '<:encoding(UTF-8)', $filename)
  or die "Could not open file '$filename' $!";
 
while (my $row = <$fh>) {
	if ($row =~ /$start/) {
		printSessionStats() if $system_starts > 1;
		print "Start $system_starts:\n";
		++$system_starts;
	} elsif ($row =~ /$action/) {
		my $date_str = substr $row, 0, $datelen;
		my $date = Time::Piece->strptime($date_str, '%d.%m.%Y %H:%M:%S');
		if ($3 eq 'STARTED'){
			# case when stop started when start started
			# when start started when stop started
			# TRY to use hash of tuples
			if(exists $procedure_time{$1}){
				# stderr
			}
			else{
				$procedure_time{$1} = [$date, $2];
			}
		} else {
			# TODO functions for each branch
			my ($launch_time, $name) = @{$procedure_time{$1}};
			my $time_diff = $date - $launch_time;
			if ($2 eq 'START'){
				push @stack, "$1 started $time_diff seconds\n";
			} else {
				push @stack, "$1 stopped $time_diff seconds\n";
			}
			delete $procedure_time{$1};
		}
	}
	chomp $row;
	# print "$row\n";
}


