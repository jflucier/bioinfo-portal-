package Config::Role::EZConfigurable;

use Moose::Role;
use MooseX::StrictConstructor;    # dies if constructor argument not in class definition

use String::CamelCase;
use Config::Meta::Attribute::Trait::EZOption;
use Config::Meta::Attribute::Trait::EZConfigurable;
use Config::EZConf;

has ezconf =>
  (
    is        => 'ro',
    isa       => 'Config::EZConf',
    predicate => 'has_ezconf',
    writer    => '_set_ezconf',
  );

has ezconf_prefix =>
  (
    is      => 'rw',
    builder => '_default_ezconf_prefix',
  );

sub _default_ezconf_prefix
{
    return '';
}

has ezconf_group =>
  (
    is      => 'rw',
    builder => '_default_ezconf_group',
  );

sub _default_ezconf_group
{
    return (ref shift);
}

has _active_prefix =>
  (
    is     => 'ro',
    writer => '_set_active_prefix',
  );

has _active_group_id =>
  (
    is     => 'ro',
    writer => '_set_active_group_id',
  );
  
#
# The type for the EZConf parameter will be matching the attribute's 'isa' type constraint
# unless this is used.
#

my %__type_dict =
  (
    Any  => 'string',
    Str  => 'string',
    Int  => 'integer',
    Num  => 'float',
    Bool => 'boolean',

    ArrayRef         => 'string_list',
    'ArrayRef[Any]'  => 'string_list',
    'ArrayRef[Str]'  => 'string_list',
    'ArrayRef[Int]'  => 'string_list',
    'ArrayRef[Num]'  => 'string_list',
    'ArrayRef[Bool]' => 'string_list',
  );


sub _prefix_setup
{
    
    my $self = shift;
    
    return $self->_active_prefix
    if $self->_active_prefix;
    
    my $prefix = $self->ezconf_prefix;

    if ($prefix)
    {
        $prefix =~ s/\W/_/g;
        $prefix .= '_' unless $prefix =~ /_$/;
    }
    
    $self->_set_active_prefix ($prefix);
    return $prefix;
}

requires 'fillConfiguration';
before 'fillConfiguration' => sub
{
    my ($self) = @_;

    # prefix formatting
    my $prefix = $self->_prefix_setup;
    

    # group label formatting

    my $grp_label = $prefix;

    if ($grp_label)
    {
        $grp_label =~ s/_+$//;
        $grp_label = String::CamelCase::camelize ($grp_label) . ' ';
    }

    $grp_label .= $self->ezconf_group;
    my $grp = $self->ezconf->add_group (label => $grp_label);
    $self->_set_active_group_id ($grp);

    foreach my $attr ($self->meta->get_all_attributes)    # traverses inheritance
    {
        if ($attr->does ('Config::Meta::Attribute::Trait::EZOption')
            and not $attr->hidden)
        {

            # add prefix to id, label, and synonyms

            my $label_prefix = $prefix;
            $label_prefix =~ s/_+$//;
            my $label = sprintf
              (
                '%s %s',
                String::CamelCase::camelize ($label_prefix),
                $attr->ezconf_label
              );

            # obtain ezconf type from attribute type constraint if any

            my $ezconf_type = $attr->ezconf_type;

            if (
                not defined $ezconf_type   and
                $attr->has_type_constraint and
                exists $__type_dict{ $attr->type_constraint }
              )
            {
                $ezconf_type = $__type_dict{ $attr->type_constraint };
            }

            $ezconf_type = 'string' unless $ezconf_type;

            $self->ezconf->add_option
              (
                id          => $prefix . $attr->ezconf_id,
                label       => $label,
                description => $attr->ezconf_description,
                type        => $ezconf_type,
                default     => $attr->get_value ($self),
                group       => $grp,
                synonyms =>
                  [map { $prefix . $_ } @{ $attr->ezconf_synonyms }],
              );

        }
        elsif ($attr->does ('Config::Meta::Attribute::Trait::EZConfigurable'))
        {
            $attr->get_value ($self)->_set_ezconf ($self->ezconf);

            # needs to use accessor method to get method modifiers (e.g. 'around')
            if (my $accessor = $attr->accessor)
            {
                $self->$accessor->fillConfiguration;
            }
            else
            {
                $attr->get_value ($self)->fillConfiguration
            }
        }
    }
};

requires 'loadFromConfiguration';
before 'loadFromConfiguration' => sub
{
    my ($self) = @_;
    my $conf = $self->ezconf->get_config;
    my $prefix = $self->_prefix_setup;

    foreach my $attr ($self->meta->get_all_attributes)
    {
        if ($attr->does ('Config::Meta::Attribute::Trait::EZOption')
            and not $attr->hidden)
        {
            my $v = $conf->{ $prefix . $attr->ezconf_id };
            $attr->set_value ($self, $v);
        }
        elsif ($attr->does ('Config::Meta::Attribute::Trait::EZConfigurable'))
        {

            # needs to use accessor method to get method modifiers (e.g. 'around')
            if (my $accessor = $attr->accessor)
            {
                $self->$accessor->loadFromConfiguration;
            }
            else
            {
                $attr->get_value ($self)->loadFromConfiguration
            }
        }
    }
};

sub addOption
{
    my ($self, %opth) = @_;
    
    $opth{id} = $self->_active_prefix . $opth{id};
    foreach (@{$opth{synonyms}})
    {
        $_ = $self->_active_prefix . $_;
    }
    $opth{group} = $self->_active_group_id
    unless exists $opth{group};
    
    $self->ezconf->add_option (%opth);
}

sub getOption
{
    my ($self, $id) = @_;
    return $self->ezconf->get_config->{$self->_active_prefix . $id};
}

1;

