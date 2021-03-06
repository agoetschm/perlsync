#! /usr/bin/perl

use strict;
use warnings;
use feature qw( say );
use Getopt::Long;
use Proc::Daemon;
use Cwd;
use File::Spec::Functions;

use FindBin;
use lib $FindBin::Bin;
use sync qw( sync );
use utils qw( read_settings );

chdir $FindBin::Bin;

my %settings = read_settings();

my $interval = $settings{"interval"} * 60;
my $log_file = $settings{"logfile"};
my $err_file = $settings{"errfile"};

my $pf = catfile(getcwd(), 'pidfile.pid');
my $daemon = Proc::Daemon->new(
  pid_file     => $pf,
  work_dir     => getcwd(),
  child_STDOUT => ">$log_file",
  child_STDERR => ">$err_file"
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

    my $last_sync_time = 0;

    while (1) {
      if (time() - $last_sync_time > $interval){
        say "Start sync at " . localtime();
        eval{ sync(%settings) };
        if ($@) {
            warn $@;
        }
        $last_sync_time = time();
        say "Done sync at " . localtime();
      }
      select()->flush();
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
