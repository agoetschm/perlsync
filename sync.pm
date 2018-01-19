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

# TODO remove
$| = 1; # autoflush

use lib ".";
use utils qw( convert_pattern_to_regex display_notification );

my $host = "192.168.1.158";
my $user = "pi";
my $src = "/home/agoetschm/Documents";
my $backup_dir = "backup";

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

  say "Scanning files in $src...";
  find($wanted, $src);
  say "Found " . scalar @content . " files to back up";

  my $sftp = Net::SFTP::Foreign->new(host => $host, user => $user);
  $sftp->error and error "Failed to connect to $host: " . $sftp->error;
  say "Connected to $host";

  for my $fname (@content) {
    say "considering $fname...";
    my $src_path = File::Spec->rel2abs($fname, $src);
    my $dest = $backup_dir . "/" . $fname;
    my $destdir = dirname($dest);

    # skip if not modified
    my $dest_stat;
    next if $dest_stat = $sftp->stat($dest) and $dest_stat->mtime >= stat($src_path)->mtime;

    say "copy $src_path to $host/$dest";
    $sftp->put($src_path, $dest) or error "Failed to copy $src_path to $host: " .$sftp->error;
  }

  display_notification "Backup complete"

}

1;
