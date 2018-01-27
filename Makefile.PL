use inc::Module::Install;

# Define metadata
name            'Perlsync';
version         '0.0.1';
include         'Module::AutoInstall';

# Specific dependencies
requires       'Proc::Daemon'           => 0;
requires       'File::Copy'             => 0;
requires       'File::Path'             => 0;
requires       'File::Basename'         => 0;
requires       'File::stat'             => 0;
requires       'File::Find'             => 0;
requires       'Time::localtime'        => 0;
requires       'Net::SFTP::Foreign'     => 0;
requires       'Getopt::Long'           => 0;
requires       'Cwd'                    => 0;
requires       'File::Spec::Functions'  => 0;
requires       'Desktop::Notify'        => 0;
requires       'Config::Simple'         => 0;
requires       'FindBin'         => 0;

auto_install(
    make_args   => '--hello',   # option(s) for CPAN::Config
    force       => 1,           # pseudo-option to force install
    do_once     => 1,           # skip previously failed modules
);

WriteAll;
