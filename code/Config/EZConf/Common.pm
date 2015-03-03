package Config::EZConf::Common;
use strict;
use warnings;

#Commonly used config options

our $MONALogin = {
     id          => 'monadb',
     synonyms    => ['db'],
     label       => 'MONA DB File',
     description => 'MONA DB file containing connection information',
     type        => 'file',
     default     => defined $ENV{MONAPR} ? $ENV{MONAPR} : 'MONALogin.conf',
};

our $SQLiteDB = {
     id          => 'sqlitedb',
     label       => 'SQLite DB File',
     description => 'Sets the SQLite DB file',
     type        => 'file',
     default     => 'sqlite.db',
};

1;
