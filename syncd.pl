#! /usr/bin/perl

use strict;
use warnings;
use feature qw( say );
use Getopt::Long;
use Proc::Daemon;
use Cwd;
use File::Spec::Functions;

use lib ".";
use sync qw( sync );


my $pf = catfile(getcwd(), 'pidfile.pid');
my $daemon = Proc::Daemon->new(
	pid_file     => $pf,
	work_dir     => getcwd(),
  child_STDOUT => "log.txt",
  child_STDERR => "log.txt"
);

my $pid = $daemon->Status($pf);
my $daemonize = 1;

# check for args
usage() unless (@ARGV);

GetOptions(
    'daemon!' => \$daemonize,
    "help"    => \&usage,
    "restart" => \&restart,
    "start"   => \&run,
    "status"  => \&status,
    "stop"    => \&stop
    );
# check for unused args
usage() if (@ARGV);
exit(0);

sub usage {
    say "Usage: syncd.pl [--start|--stop|--status|--restart]";
    exit(0);
}

sub stop {
  if ($pid) {
    say "Stopping pid $pid...";
    if ($daemon->Kill_Daemon($pf)) {
      say "Successfully stopped";
    } else {
      say "Could not find $pid. Was it running?";
    }
  } else {
    say "Not running, nothing to stop";
  }
}

sub status {
	if ($pid) {
		say "Running with pid $pid";
	} else {
		say "Not running";
	}
}

sub run {
	if (!$pid) {
		say "Starting...";
		if ($daemonize) {
			$daemon->Init;
		}

		while (1) {
      # open(my $FH, '>>', catfile(getcwd(), "log.txt"));
			say "Start sync at " . time();
      sync();
      say "Donc sync at " . time();
			# close $FH;
      sleep 30;
		}
	} else {
		say "Already running with pid $pid";
	}
}

sub restart {
  stop();
  run();
}
