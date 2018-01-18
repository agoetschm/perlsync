use feature qw(say);
use File::stat;

say stat("~/Documents")->mtime;
