package Config::Configurable;

use strict;
use warnings;

use Util::Class::Constr qw/pre_process initialization/;
use Util::Class::Props
    (
     { name => '_prefix', } # used to differentiate configurable instances       
    );

# Abstract Base Class for configurable object. Gives methods to fill a EZConf with
# options set in object, and a object creation method from the configuration hash of an EZConf.

sub pre_process
{
    my ($self, @args) = @_;
    return @args;
}


sub initialization
{
    my $self = shift;
}




sub fillConfiguration
{
    my ($self,     
        $ezconf,   # EZConf instance to be filled
        $grpid,  # EZConf option group id (obtain after addition to EZConf obj)
       ) = @_;
    die "abstract: override me!";
}


sub loadFromConfiguration
{
    my ($self,     
        $conf,  # EZConf's hash
       ) = @_;
    die "abstract: override me!";
}


sub _load_primitives
{
    my ($self, $confh, @members) = @_;

    my $template = '$self->%s (Config::EZConf::get_option ($confh, \'%s\'));';
    foreach my $attr (@members)
    {
        eval sprintf ($template, $attr, $attr);
        die "$@" if $@;
    }
}


# static
sub createFromConfiguration
{
    my (
        $conf # EZConf's hash
       ) = @_;
    die "abstract: override me!";
}

1;

