package Util::Class::Props;
use strict;

our %validation_methods;
our %default_methods;

##DOC

=head2 import

DESC Creates property setters (property name) and getters ('get_' property name) in the caller's
     package
ARGS List of hash ref, one hash ref for each property, each hash ref may contain:
        'name': name of the property
        'default': either a reference to a function or the name of a function. That function will be
            called to provide a default when an accessed property is not defined
        'validation': either a reference to a function or the name of a function. That function will
            be called to validate the value of the property. $_ is set to the value of the property
            and can be modified. The setter will croak if the validation function returns false.
            The function is not called for the default value.
            Note that a validation method for a property cannot expected other properties to
            have been validated already.
EXMP ==In the MyPackage.pm file==
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
     ==In the MyScript.pl file==
        use MyPackage;
        my $object = MyPackage->new(
            prop1 => 3012,
            prop3 => 42,
            prop5 => 'fine',
        );
        print("prop1: ", $object->get_prop1, "\n");
        print("prop2: ", $object->get_prop2, "\n");
        print("prop3: ", $object->get_prop3, "\n");
        print("prop4: ", $object->get_prop4, "\n");
        print("prop5: ", $object->get_prop5, "\n");
        print("Changing the value of prop5 to 'bad'\n");
        $object->prop5('bad');
        print("prop5: ", $object->get_prop5, "\n");

=cut

sub import {
    my ($tool, @args) = @_;
    my $pkg = scalar caller;
    foreach my $prop (@args) {
        $tool->_add_prop($pkg, $prop);
    }
}

sub _add_prop {
    my ($tool, $pkg, $prop) = @_;

    my $validation = $prop->{validation};
    my $default    = $prop->{default};
    my $n          = $prop->{name};

    my $head = 'package ' . $pkg . '; ';
    $head .= 'use Carp; ';

    my $hard_setter = sprintf 'sub _hardset_%s { $_[0]->{\'%s\'} = $_[1]; }', $n, $n;
    my $setter .= 'sub ' . $n . ' { ';
    my $getter .= 'sub get_' . $n . ' { ';

    #We have a value
    $setter .= '    if(@_ == 2) { ';
    if ($validation) {
        $validation_methods{"$pkg\::$n"} = $validation;
        $setter .= '        local $_ = $_[1]; ';
        if(ref($validation)) {
            $setter .= '                if($Util::Class::Props::validation_methods{\''.$pkg.'::'.$n.'\'}->($_[0],$_)) { ';
        }
        else {
            $setter .= '                if($_[0]->'.$validation.'($_)) { ';
        }
        $setter .= '            $_[0]->{\''.$n.'\'} = $_; ';
        $setter .= '        } ';
        $setter .= '        else { ';
        $setter .= '            croak("Invalid value for attribute '.$n.'"); ';
        $setter .= '        } ';
    }
    else {
        $setter .= '        $_[0]->{\''.$n.'\'} = $_[1]; ';
    }
    $setter .= '    } ';
    
    #We don't have a value
    $setter .= '    else { ';
    my $get = '';
    if($default) {
        $default_methods{"$pkg\::$n"} = $default;
        $get .= '        if(defined($_[0]->{\''.$n.'\'})) { ';
        $get .= '            $_[0]->{\''.$n.'\'}; ';
        $get .= '        } ';
        $get .= '        else { ';
        $get .= '            $_[0]->{\''.$n.'\'} = ';
        if(ref($default)) {
            $get .= '                $Util::Class::Props::default_methods{\''.$pkg.'::'.$n.'\'}->($_[0]); ';
        }
        else {
            $get .= '                $_[0]->'.$default.'(); ';
        }
        $get .= '        } ';
    }
    else {
        $get .= '        $_[0]->{\''.$n.'\'} ';
    }
    $setter .= $get;
    $getter .= $get;
    $setter .= '    } ';

    $setter .= '} ';
    $getter .= '} ';

    my $block = "$head $setter $getter $hard_setter";
    eval ($block);
    die "eval block {$block} failed: $@" if $@;
}

1;

