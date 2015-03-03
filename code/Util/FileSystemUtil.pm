package Util::FileSystemUtil;
use strict;

sub getFullExecPath {
    my($envVarName,$relFilePath) = @_;
    my $varContent = $ENV{$envVarName};
    my @perlPaths = split(/:/,$varContent);
    my $found = 0;
    foreach my $path (@perlPaths) {
        my $execPath = $path . $relFilePath;
        if (-e $execPath) {
            return $execPath;
        }
    }
    return undef;
}

1;
