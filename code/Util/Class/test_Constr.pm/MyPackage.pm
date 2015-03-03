package MyPackage;
use Util::Class::Constr ('pre_process', 'initialization');

sub pre_process {
    my ($self, %args) = @_;
    print("Pre-processing ", join(", ", map("$_ => '$args{$_}'", keys(%args))), "\n");
    return %args;
}

sub initialization {
    my ($self) = @_;
    print("Initialization\n");
}

sub my_property {
    my ($self, $value) = @_;
    if (defined($value)) {
        $self->{'my_property'} = $value;
    }
    return $self->{'my_property'};
}
1;
