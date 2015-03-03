package Util::Class::Constr;
use strict;

##DOC

=head2 import

DESC Creates a constructor (method 'new') in the caller's package
NOTE the constructor takes a hash as argument and will set the value for each key using the method
     of the same name
ARGS List of string parameters. Parameters can contain:
        'pre_process': when present, the pre_process method of the package will be called before the 
            values are set in the object. The hash passed to the constructor will be passed to
            pre_process and replace with the return value of pre_process
        'initialization': when present, the pre_process method of the package will be called before the 
         values are set in the object.
EXMP ==In the MyPackage.pm file==
        package MyPackage;
        use Util::Class::Constr ('pre_process','initialization');
        sub pre_process {
            my ($self, %args) = @_;
            print("Pre-processing ",join(", ", map("$_ => '$args{$_}'",keys(%args))),"\n");
            return %args;
        }
        sub initialization {
            my ($self) = @_;
            print("Initialization\n");
        }
        sub my_property {
            my ($self, $value) = @_;
            if(defined($value)) {
                $self->{'my_property'} = $value;
            }
            return $self->{'my_property'};
        }
        1;
     ==In the MyScript.pl file==
        use MyPackage;
        my $object = MyPackage->new('my_property' => 3012);
        print("My property: ",$object->my_property,"\n");

=cut

sub import {
    my ($pkg, @args) = @_;

    my %args;
    $args{$_}++ for @args;

    my $callpkg     = caller;
    my $pre_process =
      $args{'pre_process'} ? 'my %args = $self->pre_process(@args);' : 'my %args = @args;';
    my $initialization = $args{'initialization'} ? '$self->initialization();' : '';
    my $constr = '
        package ' . $callpkg . ';

        sub new {
            my ($class,@args) = @_;
            my $self = bless({},$class);
            ' . $pre_process . '

            for (keys %args)
            {
              my $subn = "_hardset_$_";
              $self->$subn($args{$_});
            }

            $self->$_($args{$_}) for keys(%args);
            ' . $initialization . '
            return $self;
        }
    ';

    eval($constr);
    die "eval block {$constr} failed: $@" if $@;
}

1;

