package utils;

use parent 'Exporter';
our @EXPORT_OK = qw( convert_pattern_to_regex display_notification update_notification read_settings );

use Desktop::Notify;
use Config::Simple;

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

my $notification;
sub display_notification {
  my $msg = shift;
  my $notify = Desktop::Notify->new();
  $notification = $notify->create(summary => 'Perlsync',
                                    body => $msg,
                                    timeout => 10000);
  $notification->show();
  # $notification->close();
}

sub update_notification {
  die "No previous notification" unless $notification;

  my $updated_msg = shift;
  $notification->body($updated_msg);
  $notification->show();
}

sub read_settings {
  my %settings;
  Config::Simple->import_from('sync.conf', \%settings);
  return %settings;
}

1;
