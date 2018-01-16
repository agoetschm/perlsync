use Desktop::Notify;

# Open a connection to the notification daemon
my $notify = Desktop::Notify->new();

# Create a notification to display
my $notification = $notify->create(summary => 'Perlsync',
                                  body => 'Hello, world!',
                                  timeout => -1);

# Display the notification
$notification->show();

# $notification->close();
