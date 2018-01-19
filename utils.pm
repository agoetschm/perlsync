package utils;

use parent 'Exporter';
our @EXPORT_OK = qw( convert_pattern_to_regex display_notification );

use Desktop::Notify;

sub convert_pattern_to_regex {
  my $pattern = shift;
  my $regex;

  # handle leading /
  if (substr($pattern, 0, 1) eq "/") {
    $regex = "\\A";
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

sub display_notification {
  my $msg = shift;
  my $notify = Desktop::Notify->new();
  my $notification = $notify->create(summary => 'Perlsync',
                                    body => $msg,
                                    timeout => 10000);
  $notification->show();
  # $notification->close();
}

1;
