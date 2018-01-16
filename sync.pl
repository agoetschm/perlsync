use strict;
use warnings;
use feature qw( say );
use File::Copy;
use File::Path;
use File::Basename;
use File::stat;
use File::Find;
use Time::localtime;

use lib ".";
use utils qw( convert_pattern_to_regex display_notification );

sub error {
  my $msg = shift;
  display_notification $msg;
  die $msg;
}

my $syncinclude_file = '.syncinclude';
open(my $fh, '<', $syncinclude_file)
  or error "Could not open file '$syncinclude_file' $!" ;

my @regexps;
my @ignore_regexps;

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


sub test_filename {
  my $filename = shift;
  # say "test " . $filename;

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


my @content;
sub wanted {
  return if -d; # skip directories
  my $name = $File::Find::name;

  if (test_filename $name) {
    push @content, $name;
  }
}


find( \&wanted, '.');

for my $fname (@content) {
  # say $fname;
  my $dest = "saved/" . $fname;
  my $destdir = dirname($dest);

  # create dest dir if necessary
  if (! -d $destdir){
    # say "create $destdir";
    my $dirs = eval { mkpath($destdir) };
    error "Failed to create $destdir: $@\n" unless $dirs;
  }

  # skip if not modified
  next if -e $dest and stat($dest)->mtime >= stat($fname)->mtime;

  # say "copy";
  copy $fname, $destdir or error "Failed to copy $fname";
}

display_notification "Backup complete"
