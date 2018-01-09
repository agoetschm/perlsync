use strict;
use warnings;
use feature qw( say );
use File::Copy qw(copy);
use File::stat;
use Time::localtime;
use File::Find;

my $filename = '.syncinclude';
open(my $fh, '<', $filename)
  or die "Could not open file '$filename' $!";

my @patterns;

while (my $row = <$fh>) {
  chomp $row;
  push @patterns, $row;
}


# copy("text.txt", "text-copy.txt");

# my $timestamp = ctime(stat($fh)->mtime);
# say stat($fh)->mtime;

# = ("heads/", "/test*", "*.txt", "a*");

my @content;
sub wanted {
  return if -d; # skip directories
  my $name = $File::Find::name;

  foreach (@patterns){
    my $pattern = $_; # avoid aliasing
    my $regex;

    ### tranform pattern into regex ###

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
        die "Unknown character $char in pattern $pattern"
      }
    }
    # handle absence of trailing /
    if (substr($pattern, -1) ne '/'){
      $regex .= "(\/|\\z)";
    }

    #$regex = qr/\A\.\/t[\w.]*?(\/|\z)/;

    # perform filtering
    if ($name =~ /$regex/) {
      push @content, $name;
      last;
    }
  }
}
find( \&wanted, '.');
for my $f (@content) {
  say $f;
  copy $f, "saved/" . $f or die "copy of $f failed";
}
