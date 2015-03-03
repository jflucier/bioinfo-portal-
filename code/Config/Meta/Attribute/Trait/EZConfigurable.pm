package Config::Meta::Attribute::Trait::EZConfigurable;

use Moose::Role;

package Moose::Meta::Attribute::Custom::Trait::EZConfigurable;
sub register_implementation { 'Config::Meta::Attribute::Trait::EZConfigurable' }

1;
