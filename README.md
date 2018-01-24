# PerlSync
A small Perl backup script to save local files on my Raspberry Pi. Also my first Perl project.

## Settings
The `.syncinclude` file contains the files you want to back up in a `.gitignore`-like syntax.

```
# include all files at the root and beginning with "test"
/test*
# include ALL the files ending with ".txt"
*.txt
# ignore the files ending with ".mkv"
^.mkv
```

The `sync.conf` file contains a list of key-value mappings:
- `host`: ip address or url of the destination (must accept ssh connections)
- `user`: user for the ssh connection
- `password`: optional password for the ssh connection (the other option is an [ssh key](https://confluence.atlassian.com/bitbucketserver/creating-ssh-keys-776639788.html))
- `source`: local source folder
- `destination`: destination folder on the `host`
- `interval`: the time interval between two backups in minutes
- `logfile`: the name of the log file


## Usage
- `./syncd.pl --start`: start the backup daemon
- `./syncd.pl --stop`: stop the backup daemon
- `./syncd.pl --status`: display the status of the daemon
- `./syncd.pl --restart`: restart the backup daemon
