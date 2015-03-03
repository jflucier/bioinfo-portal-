package Config::Meta::Attribute::Trait::EZOption;

use Moose::Role;

use String::CamelCase;

#
# These are required
#
has ezconf_description => (is => 'rw', isa => 'Str', required => 1);

#
# The ID for the EZConf parameter will be the attribute's name
# unless this is used.
#
has ezconf_id =>
  (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_ezconf_id'
  );

around ezconf_id => sub
{
    my ($orig, $self, @args) = @_;

    return $self->$orig (@args) if @args > 0;

    $self->ezconf_id ($self->name)
      unless $self->has_ezconf_id;

    return $self->$orig;
};

#
# The label for the EZConf parameter will be formed using the attribute's name
# unless this is used.
#
has ezconf_label =>
  (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_ezconf_label'
  );

around ezconf_label => sub
{
    my ($orig, $self, @args) = @_;

    return $self->$orig (@args) if @args > 0;

    $self->ezconf_label
      (
        join
          (
            ' ',
            String::CamelCase::wordsplit (String::CamelCase::camelize ($self->ezconf_id))
          )
      )
      unless $self->has_ezconf_label;

    return $self->$orig;
};

##
## The type for the EZConf parameter will be matching the attribute's 'isa' type constraint
## unless this is used.
##
#
#my %__type_dict =
#  (
#    Any  => 'string',
#    Str  => 'string',
#    Int  => 'integer',
#    Num  => 'float',
#    Bool => 'boolean',
#
#    ArrayRef         => 'string_list',
#    'ArrayRef[Any]'  => 'string_list',
#    'ArrayRef[Str]'  => 'string_list',
#    'ArrayRef[Int]'  => 'string_list',
#    'ArrayRef[Num]'  => 'string_list',
#    'ArrayRef[Bool]' => 'string_list',
#  );

has ezconf_type =>
  (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_ezconf_type'
  );

#around ezconf_type => sub
#{
#    my ($orig, $self, @args) = @_;
#
#    return $self->$orig (@args) if @args > 0;
#
#    unless ($self->has_ezconf_type)
#    {
#        my $attr = $self->meta->get_attribute ('ezconf_type');
#
#        if ($attr->has_type_constraint and exists $__type_dict{ $attr->type_constraint })
#        {
#            $self->ezconf_type ($__type_dict{ $attr->type_constraint })
#        }
#        else
#        {
#            $self->ezconf_type ('string');
#        }
#    }
#
#    $self->ezconf_type ($self->name)
#      unless $self->has_ezconf_id;
#
#    return $self->$orig;
#};

#
# This is optional
#
has ezconf_synonyms =>
  (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { [] }
  );

#
# Raise this to hide the parameter from the configuration
#
has hidden =>
  (
    is      => 'rw',
    isa     => 'Bool',
    default => 0
  );

package Moose::Meta::Attribute::Custom::Trait::EZOption;
sub register_implementation { 'Config::Meta::Attribute::Trait::EZOption' }

1;
