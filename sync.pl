use strict;
use warnings;
use feature qw( say );
use File::Copy;
use File::Path;
use File::Basename;
use File::stat;
use File::Find;
use Time::localtime;

my $syncinclude_file = '.syncinclude';
open(my $fh, '<', $syncinclude_file)
  or die "Could not open file '$syncinclude_file' $!";

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

sub convert_pattern_to_regex {
  my $pattern = shift;
  my $regex;

  # handle leading /
  if (substr($pattern, 0, 1) eq "/") {
    $regex = "\\A\.\/";
    $pattern = substr $pattern, 1;
  } else {
    $regex = "\/";
  }
  # loop over the rest
  foreach my $char (split '', $pattern) {
    if ($char =~ /[\w.]/) {
      $regex .= $char;
    } elsif ($char eq '/') {
      $regex .= "\/";
    } elsif ($char eq '*'){
      # TODO may not be safe
      $regex .= "[\\w.]*?";
    } else {
      die "Unknown character '$char' in pattern $pattern";
    }
  }
  # handle absence of trailing /
  if (substr($pattern, -1) ne '/'){
    $regex .= "(\/|\\z)";
  }

  return qr/$regex/;
}

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


# my $timestamp = ctime(stat($fh)->mtime);
# say stat($fh)->mtime;


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
  say $fname;
  my $dest = "saved/" . $fname;
  my $destdir = dirname($dest);

  # create dest dir if necessary
  if (! -d $destdir){
    say "create $destdir";
    my $dirs = eval { mkpath($destdir) };
    die "Failed to create $destdir: $@\n" unless $dirs;
  }

  # skip if not modified
  next if -e $dest and stat($dest)->mtime >= stat($fname)->mtime;

  say "copy";
  copy $fname, $destdir or die "Failed to copy $fname";
}