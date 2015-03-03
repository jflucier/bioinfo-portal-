package MyPackage;
use Util::Class::Constr;
use Util::Class::Props (
    {name => 'prop1'},
    {   name    => 'prop2',
        default => sub { 5 }
    },
    {   name       => 'prop3',
        validation => sub { m/^\d+$/ }
    },
    {   name    => 'prop4',
        default => 'prop4_default'
    },
    {   name       => 'prop5',
        validation => \&prop5_validation
    },
);

sub prop4_default {
    my ($self) = @_;
    print("prop4_default beiing called!\n");
    return $self->get_prop3 * 2;
}

sub prop5_validation {
    my ($self, $value) = @_;
    print("prop5_validation beiing called!\n");
    if ($value eq 'bad') {
        print("bad is good\n");
        $_ = 'good';
    }
    return 1;
}
1;
