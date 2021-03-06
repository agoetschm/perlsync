package sync;

use parent 'Exporter';
our @EXPORT_OK = qw( sync );

use strict;
use warnings;
use feature qw( say );

use File::Copy;
use File::Path;
use File::Basename;
use File::stat;
use File::Find;
use Time::localtime;
use Net::SFTP::Foreign;

use lib ".";
use utils qw( convert_pattern_to_regex display_notification update_notification );

sub error {
  my $msg = shift;
  display_notification $msg;
  die $msg;
}

# easier to keep them outside
my @regexps;
my @ignore_regexps;

sub read_syncinclude {
  my $syncinclude_file = '.syncinclude';
  open(my $fh, '<', $syncinclude_file)
    or error "Could not open file '$syncinclude_file' $!" ;

  while (my $row = <$fh>) {
    chomp $row;
    # filter blanks or comments
    next if ($row =~ /^\s*$/ or substr($row, 0, 1) eq '#');

    if (substr($row, 0, 1) eq '^') {
      push @ignore_regexps, convert_pattern_to_regex( substr $row, 1 );
    } else {
      push @regexps, convert_pattern_to_regex($row);
    }
  }

  close $fh;
}


sub test_filename {
  my $filename = shift;

  # if to be ignored
  foreach my $regex (@ignore_regexps){
    return 0 if $filename =~ $regex;
  }
  # if to be included
  foreach my $regex (@regexps){
    return 1 if $filename =~ $regex;
  }
  return 0;
}

sub sync {
  my %settings = @_;
  my $host = $settings{"host"};
  my $user = $settings{"user"};
  my $password = $settings{"password"};
  my $src = $settings{"source"};
  my $backup_dir = $settings{"destination"};

  read_syncinclude();

  my @content;
  my $wanted = sub {
    return if -d; # skip directories
    my $name = $File::Find::name;
    my $rel_name = File::Spec->abs2rel($name, $src);

    if (test_filename $rel_name) {
      push @content, $rel_name;
    }
  };

  display_notification "Scanning files in $src...";
  find($wanted, $src);
  update_notification "Found " . scalar @content . " files to back up";

  my $sftp = Net::SFTP::Foreign->new(host => $host, user => $user, password => $password);
  $sftp->error and error "Failed to connect to $host: " . $sftp->error;
  say "Connected to $host";

  update_notification "Backup in progress...";
  my $counter = 0;
  my $total = scalar @content;
  my $last_notif_time = 0;
  my $last_log_time = 0;
  for my $fname (@content) {
    $counter += 1;
    my $src_path = File::Spec->rel2abs($fname, $src);
    my $dest = $backup_dir . "/" . $fname;
    my $destdir = dirname($dest);

    select()->flush(); # flush stdout, otherwise log file isn't informative enough

    if (time() - $last_notif_time > 60) {
      update_notification "Backup in progress... [$counter/$total]";
      $last_notif_time = time();
    }

    # skip if not modified
    my $dest_stat;
    if ($dest_stat = $sftp->stat($dest) and $dest_stat->mtime >= stat($src_path)->mtime) {
      if (time() - $last_log_time > 10) { # prevent too big log file
        say "[$counter/$total] skipped file";
        $last_log_time = time();
      }
      next;
    }

    say "[$counter/$total] backup $fname"; # copy $src_path to $host/$dest
    $last_log_time = time();
    $sftp->put($src_path, $dest, copy_time => 0, copy_perm => 0) or error "Failed to copy $src_path to $host: " .$sftp->error;
  }
  update_notification "Backup complete";
}

1;
