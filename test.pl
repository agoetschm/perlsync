use Net::SFTP::Foreign;
use feature qw(say);

my $sftp = Net::SFTP::Foreign->new(host => "192.168.1.158", user => "pi");

# $sftp->put("LICENSE", "test.txt");
say $sftp->stat("test.txt")->mtime
