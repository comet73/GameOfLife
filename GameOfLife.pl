use strict;
use warnings;
use Curses;
use Term::Size;

my ($cols, $rows) = Term::Size::chars;
if (! ($cols && $rows)) {
	print "Cannot get terminal size.\n";
	print "If this process is running in Docker, consider using the --terminal parameter\n";
	$cols = $rows = 10;
}

initscr();

my $width;
my $height;
getmaxyx($height, $width);
my $seeds = int($width * $height * rand(1));

my @grid = ([(1) x $width], [(1) x $height]);

for (my $y = 0; $y < $height; $y++) {
	for (my $x = 0; $x < $width; $x++) {
		$grid[$x][$y] = "";
	}
}

noecho();
clear();
refresh();

$SIG{INT} = sub { endwin(); exit; };

my $i = 0;
while ($i < $seeds) {
	my $x = int(rand($width));
	my $y = int(rand($height));
	$i++ unless $grid[$x][$y];
	if ($i % 2 == 0) {
		$grid[$x][$y] = "X";
	} else {
		$grid[$x][$y] = "O"
	}
}

my @scenelist = ();

my $firstrun = 1;

my %scenes = ();
my $generation = 0;
my $termination = "";
while (1) {
    $generation ++;
	my @nextGrid = ([(1) x $width], [(1) x $height]);
    my $livingCells = 0;
    my $changes = 0;
    my $scene = "";
    clear();
	for (my $y = 0; $y < $height; $y++) {
		for (my $x = 0; $x < $width; $x++) {
			my $alive = $grid[$x][$y];
			move($y, $x);
			if ($alive) {
				delch(); 
					insch($alive); 
				$scene .= "X";
			} else { 
				delch();
				insch(".");
				$scene .= "O";
			}
			$livingCells++ if $alive;
			my $livingNeighbors = 0;
			my $xNeighbors = 0;
			my $oNeighbors = 0;
			for (my $nx = $x-1; $nx < $x+2; $nx++) {
				for (my $ny = $y-1; $ny < $y+2; $ny++) {
					last if ($livingNeighbors > 3);
					if ($nx == $x && $ny == $y) {
						next;
					}
					my $neighbor = $grid[$nx % $width][$ny % $height];
					$livingNeighbors++ if $neighbor;
					$xNeighbors++ if $neighbor eq "X";
					$oNeighbors++ if $neighbor eq "O";
				}
			}
			if (($alive && ($livingNeighbors == 2 || $livingNeighbors == 3))
				|| (!$alive && $livingNeighbors == 3)) {
				if ($alive) {
					$nextGrid[$x][$y] = $alive;
				} else {
					if ($xNeighbors > $oNeighbors) {
						$nextGrid[$x][$y] = "X";
					} else {
						$nextGrid[$x][$y] = "O";
					}
				}
				$changes++ if !$alive;
			} else {
				$nextGrid[$x][$y] = "0";
				$changes++ if $alive;
			}
		}
	}
	refresh();
	unless ($changes) {
		$termination = "Starved";
		last;
	}
	$scene =~ s/O*$//;
	if ($scenes{$scene}) {
		my $cyclesize = $generation - $scenes{$scene};
		$termination = "$cyclesize-Period cycle";
		last;
	}
	$scenes{$scene} = $generation;
	@grid = @nextGrid;
}


endwin();


print "$termination after $generation generations\n";
