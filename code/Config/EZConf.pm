package Config::EZConf;
use strict;
use warnings;

use File::Util;
use File::Slurp;
use File::Temp 'tempfile';
use Storable 'store', 'store_fd', 'retrieve';
use Config::Record;
use Term::ANSIColor;
use Error ':try';
use Text::Wrap;
use List::Util 'min', 'max';
use Data::Dump 'dump';
use Util::ConstantHash;
use Config::EZConf::Common;
use YAML::Any 'LoadFile', 'Dump';
$YAML::Indent = 4;

#This module manages configuration options using command line arguments and a user interface

#Command line arguments have the form
#   key=value
#where key is the identifier of an option or one of it's synonyms, except for boolean values which
#can also have the form
#   key
#setting the value to true.

#Special arguments exist:
#   --abort         abort the execution of the perl program (usefull when one only wants to modify
#                   configuration files
#   --help -h       display a help message
#   --ui            use the user interface to manage configuration
#   --load-config=X loads a configuration file in Config::Record format
#   --save-config=X saves the configuration in Config::Record format

our %valid_types = (
    boolean     => 1,    #values 0 and 1
    string      => 1,    #any scalar value
    integer     => 1,    #any integer
    file        => 1,    #absolute or relative path to a file
    float       => 1,    #any float
    string_list => 1,    #a list of scalar values
                         #if we add anything here, make sure same_config_value() remains functional
);

sub new {
    my ($class) = @_;
    my $self = bless (
        { options => [],    #List of configuration options
            group_options => [[]],        #List of the list of configuration options for each group
            group_labels  => ['Main'],    #List of the names of the configuration groups
            key_options   => {},          #Configuration options hashed by ID and synonyms
            config        => {},          #Active configuration values
            robust        => 1,           #Flag to die if a load-file option not defined here
            doc_sections  => [],          #Sections of the doc to output when user asks for help
            documentation => {},          #Documentation indexed by section
            attachments   => {},          #filename => file content
        },
        $class
    );

    #Add the internal options
    my $group = $self->add_group (label => 'Configuration', internal => 1);
    $self->add_option (
        id          => '--abort',
        label       => 'Abort program execution',
        description => "Aborts the program's execution.",
        type        => 'boolean',
        default     => 0,
        internal    => 1,
        group       => $group
    );
    $self->add_option (
        id          => '--help',
        synonyms    => ['-h'],
        label       => 'Help',
        description => 'Displays this help message.',
        type        => 'boolean',
        default     => 0,
        internal    => 1,
        group       => $group
    );
    $self->add_option (
        id       => '--save-config-yaml',
        synonyms => ['-sy'],
        label    => 'Save configuration to file (YAML format)',
        description =>
          'Saves configuration to this file in YAML format. May be repeated. Configuration is saved after all command line parameters are parsed and the user interace (if needed) has run.',
        type     => 'string_list',
        default  => [],
        internal => 1,
        group    => $group
    );
    $self->add_option (
        id       => '--save-config',
        synonyms => ['-sc'],
        label    => 'Save configuration to file (Config::Record format)',
        description =>
          'Saves configuration to this file in Config::Record format. May be repeated. Configuration is saved after all command line parameters are parsed and the user interace (if needed) has run.',
        type     => 'string_list',
        default  => [],
        internal => 1,
        group    => $group
    );
    $self->add_option (
        id       => '--save-modified-config-yaml',
        label    => 'Save non-default configuration to file (YAML format)',
        synonyms => ['-smy'],
        description =>
          'Saves non-default configuration to this file in YAML format. May be repeated. Configuration is saved after all command line parameters are parsed and the user interace (if needed) has run.',
        type     => 'string_list',
        default  => [],
        internal => 1,
        group    => $group
    );
    $self->add_option (
        id       => '--save-modified-config',
        synonyms => ['-smc'],
        label    => 'Save non-default configuration to file (Config::Record format)',
        description =>
          'Saves non-default configuration to this file in Config::Record format. May be repeated. Configuration is saved after all command line parameters are parsed and the user interace (if needed) has run.',
        type     => 'string_list',
        default  => [],
        internal => 1,
        group    => $group
    );
    $self->add_option (
        id       => '--load-config',
        synonyms => ['-lc'],
        label    => 'Load configuration from file (Config::Record format)',
        description =>
          'Loads configuration from this file in Config::Record format. May be repeated. Configuration files are loaded in the order they appear and before any other command line argument is parsed.',
        type     => 'string_list',
        default  => [],
        internal => 1,
        group    => $group
    );
    $self->add_option (
        id       => '--load-config-yaml',
        synonyms => ['-ly'],
        label    => 'Load configuration from file (YAML format)',
        description =>
          'Loads configuration from this file in YAML format. May be repeated. Configuration files are loaded in the order they appear and before any other command line argument is parsed.',
        type     => 'string_list',
        default  => [],
        internal => 1,
        group    => $group
    );
    $self->add_option (
        id    => '--ui',
        label => 'Use interface',
        description =>
          'Uses the user interface to manage configuration.',
        type     => 'boolean',
        default  => 0,
        internal => 1,
        group    => $group
    );
    $self->add_option (
        id          => '--no-ui',
        label       => 'DEPRECATED',
        description => 'DEPRECATED',
        type        => 'boolean',
        default     => 0,
        internal    => 1,
        group       => $group
    );
    $self->add_option (
        id          => '-keyless-',
        label       => 'Synonym for arguments not having a key',
        description => 'Stores arguments with no key',
        type        => 'string',
        default     => [],
        internal    => 0,
        group       => $group
    );
    return $self;
}

#Adds a section to the documentation to show when user asks for help
#parameters:
#   section: name of the section
#   doc: documentation
sub add_to_documentation {
    my ($self, $section, $doc) = @_;
    $self->{documentation}->{$section} = $doc;
    push (@{ $self->{doc_sections} }, $section);
}

#Retrieves a section of documentation
#parameters:
#   section: name of the section
sub get_documentation {
    my ($self, $section) = @_;
    return $self->{documentation}->{$section};
}

#Retrieves a list of documentation sections
sub get_documentation_sections {
    my ($self) = @_;
    return $self->{doc_sections};
}

#Adds an option to the configuration
#parameters:
#   id: identifier of the option, must be unique.
#   synonyms: list of alternative aliases an option can be refered as (used in command line)
#   label: short description of the option
#   description: longer description of the option
#   type: one of the vallid option_types (see valid_types)
#   default: default value of the option
#   internal: set to true if option is internal to EZConf (like --abort)
#   parent_group: option group containing the current option. defaults to main group
sub add_option {
    my ($self, %args) = @_;
    my %option;

    $option{id} = $args{id} or die ("Option requires an ID");
    if ($args{id} !~ m/^[\w-]+$/) {
        die ("Option id must only be composed of alphanumeric, underscore (_) or dash (-) characters"
        );
    }
    $option{synonyms} = $args{synonyms} || [];
    $option{label} = $args{label} or die ("Option requires a label");
    $option{description} = defined ($args{description}) ? $args{description} : "";
    $option{type} =
      $valid_types{ $args{type} }
      ? $args{type}
      : die (sprintf "Option '%s' type '%s' isn't valid", $args{id}, $args{type});
    $option{default} =
      defined ($args{default}) ? $args{default} : die ("Option requires a default value");
    $option{internal} = $args{internal};
    $option{parent_group} = defined ($args{group}) ? $args{group} : 0;

    push (@{ $self->{options} },                                \%option);
    push (@{ $self->{group_options}->[$option{parent_group}] }, \%option);
    foreach my $synonym ($option{id}, @{ $option{synonyms} }) {
        if ($synonym ne '-keyless-' and exists ($self->{key_options}->{$synonym})) {
            die "duplicate configuration key synonym '$synonym'";
        }
        $self->{key_options}->{$synonym} = \%option;
    }
    $self->{config}->{ $option{id} } = $option{default};

}

#Adds an option group to the configuration
#parameters:
#   label: name of the group
#   group: option group containing the current option group. defaults to main group
sub add_group {
    my ($self, %args) = @_;

    my $label = $args{label} or die ("Option group missing a label");
    my $parent   = defined ($args{group}) ? $args{group} : 0;
    my $internal = $args{internal}        ? 1            : 0;

    push (@{ $self->{group_options} }, []);
    push (@{ $self->{group_labels} }, $label);
    my $id = @{ $self->{group_labels} } - 1;
    if (!$internal) {
        push (
            @{ $self->{group_options}->[$parent] },
            { label => $label,
                parent_group => $parent,
                group        => $id,
                type         => 'group',
                internal     => $internal
            }
        );
    }

    return $id;
}

#Parses the command line, uses the ui if necessary, and returns the config or aborts program
#exectuion if --abort option is valid
#parameters is the list of command line arguments (@ARGV)
sub parse_config {
    my ($self, @args) = @_;
    $self->_parse_command_line (@args);
    my $conf = $self->get_config;

    if ($conf->{'--abort'}) {
        exit (0);
    }
    else {
        return $conf;
    }
}

#Parses a list of command line arguments (@ARGV)
sub _parse_command_line {
    my ($self, @args) = @_;

    my %options;

    foreach my $arg (@args) {
        my ($key, $value) = split (m/=/, $arg, 2);
        if (my $option = $self->key_option ($key)) {

            #Booleans do not require a value
            if ($option->{type} eq 'boolean') {
                if (defined ($value)) {
                    $options{ $option->{id} } = $value ? 1 : 0;
                }
                else {
                    $options{ $option->{id} } = 1;
                }
            }

            #Non boolean require a value
            elsif (defined ($value)) {

                #String list are special, they can be defined by repeating the same key
                if ($option->{type} eq 'string_list') {
                    my $existing = $options{ $option->{id} };
                    if (!defined ($existing)) {
                        $existing = $options{ $option->{id} } = [];
                    }
                    push (@$existing, $value);
                }
                else {
                    $options{ $option->{id} } = $value;
                }
            }
            else {
                die ("Arguments must be in option=value pair. Offending argument: '$arg'");
            }
        }
        elsif (defined ($value)) {
            die "Unrecognized argument: '$arg'";
        }
        else {
            my $existing = $options{'-keyless-'};
            if (!defined ($existing)) {
                $existing = $options{'-keyless-'} = [];
            }
            push (@$existing, $arg);
        }
    }

    if ($options{'--load-config'}) {
        foreach my $file (@{ $options{'--load-config'} }) {
            $self->load_config_file ($file, 'Config::Record');
        }
    }
    if ($options{'--load-config-yaml'}) {
        foreach my $file (@{ $options{'--load-config-yaml'} }) {
            $self->load_config_file ($file, 'YAML');
        }
    }
    foreach my $option_id (keys (%options)) {
        $self->set_option ($option_id, $options{$option_id});
    }
    if ($options{'--help'}) {
        $self->print_help ();
        $self->set_option ('--abort', 1);
    }
    else {
        $self->_ui () if ($options{'--ui'});
        if ($options{'--save-config'}) {
            foreach my $file (@{ $options{'--save-config'} }) {
                $self->save_config_file ($file, 'Config::Record');
            }
        }
        if ($options{'--save-config-yaml'}) {
            foreach my $file (@{ $options{'--save-config-yaml'} }) {
                $self->save_config_file ($file, 'yaml');
            }
        }
        if ($options{'--save-modified-config'}) {
            foreach my $file (@{ $options{'--save-modified-config'} }) {
                $self->save_config_file ($file, 'Config::Record', 1);
            }
        }
        if ($options{'--save-modified-config-yaml'}) {
            foreach my $file (@{ $options{'--save-modified-config-yaml'} }) {
                $self->save_config_file ($file, 'yaml', 1);
            }
        }
    }
}

sub print_help {
    my ($self) = @_;

    my $indent     = '  ';
    my $sub_indent = '    ';

    #Documentation
    foreach my $section (@{ $self->get_documentation_sections }) {
        next unless $self->get_documentation ($section);
        print ($self->_format_heading ($section), "\n");
        print (wrap ($indent, $indent, $self->get_documentation ($section)), "\n\n");
    }

    #Arguments
    print ($self->_format_heading ("Arguments"), "\n");
    my $arg_help =
      'Command line arguments have the form "key=value" where key is the identifier of an '
      . 'option or one of it' . "'" . 's synonyms. Arguments of boolean type do not require the '
      . '"=value" part to set them to true.';
    print (wrap ($indent, $indent, $arg_help), "\n\n");

    # get max column needed for label column
    my $max_label_len = 2 + max (
        map ({ length (join (' ', $_->{id}, @{ $_->{synonyms} })) }
            grep ({ $_->{type} ne 'group' } @{ $self->get_options }))
    );
    my $label_len = min (15, $max_label_len);
    my $arg_indent = $sub_indent . sprintf ('%-' . $label_len . 's', '');

    for (my $i = 0 ; $i < @{ $self->{group_labels} } ; $i++) {

        #Group label
        print (wrap ($indent, $indent, $self->_format_sub_heading ($self->{group_labels}->[$i])), "\n");

        foreach my $option (@{ $self->get_group_options ($i) }) {
            next if $option->{type} eq 'group';

            my $label = join (' ', $option->{id}, @{ $option->{synonyms} }) . ' ';
            my $first_indent;
            if (length ($label) + 1 > $label_len) {
                print (wrap ($sub_indent, $sub_indent, $label), "\n");
                $first_indent = $arg_indent;
            }
            else {
                $first_indent = sprintf ($sub_indent .
                      '%-' . $label_len . 's',
                    $label
                );
            }
            my $default = dump ($option->{default});
            my $value   = dump ($self->get_config_value ($option->{id}));
            my $desc    = $option->{description} . "\n" . 'Default: ' . $default;
            if ($value ne $default) {
                $desc .= "\nCurrent value: $value"
            }
            print (wrap ($first_indent, $arg_indent, $desc), "\n");
        }
        print ("\n");
    }
}

sub _format_heading {
    my ($self, $text) = @_;
    return colored (uc ($text), 'bold') . "\n"
}

sub _format_sub_heading {
    my ($self, $text) = @_;
    return colored ($text, 'underline')
}

sub key_option {
    my ($self, $key) = @_;
    return $self->{key_options}->{$key};
}

sub set_option {
    my ($self, $key, $value) = @_;
    if ($key eq '-keyless-') {
        $self->{config}->{'-keyless-'} = $value;
    }
    else {
        my $option = $self->{key_options}->{$key} or die ("'$key' is not a valid option");
        $self->{config}->{ $option->{id} } = $value;
    }
}

# static method
#
# Get named option. Die if option not found, unless
# soft flag raised.
#
# parameters:
#   opt:  option name.
#   soft: flag raised to inhibit exception throwing.
sub get_option {
    my ($conf, $opt, $soft) = @_;
    $soft = 0 unless defined $soft;
    die "undefined configuration option '$opt'" unless $soft or exists $conf->{$opt};
    return $conf->{$opt};
}

sub _ui {
    my ($self) = @_;

    if (-t STDIN) {

        #We are talking to the terminal, so we can bring up the UI
        my $script = $self->_locate_script ('Config/config_curses_ui.pl')
          or die ("Could not locate 'config_curses_ui.pl' in directories "
              . join (',', map ("'$_/Config/'", @INC))
              . '.');

        my ($fd, $fn) = tempfile ("ez_conf_XXXXXXXXXXX");
        store_fd ($self, $fd);
        close ($fd) or die ("Could not close temporary file '$fn': $!");
        system ("perl $script $fn");
        $self->_set_config (retrieve ($fn));
        unlink ($fn);
    }
}

sub _set_config {
    my ($self, $value) = @_;
    $self->{'config'} = $value;
}

sub get_config {
    my ($self) = @_;

    return $self->{config}
      if tied %{ $self->{config} };

    my $conf = {};
    tie %$conf, 'Util::ConstantHash', $self->{config};
    return ($self->{config} = $conf);
}

sub get_config_value {
    my ($self, $option) = @_;
    $self->get_config->{$option};
}

sub _locate_script {
    my ($self, $script) = @_;
    foreach my $dir (@INC) {
        if (-e "$dir/$script") {
            return "$dir/$script";
        }
    }
    return undef;
}

sub get_options {
    my ($self) = @_;
    return $self->{'options'};
}

sub load_config_file {
    my ($self, $fn, $format) = @_;

    my $current_config = $self->{config};

    my $loaded_hashref;
    if (!defined ($format) || lc ($format) eq 'config::record') {
        $loaded_hashref = Config::Record->new (file => $fn)->record;
    }
    elsif (lc ($format) eq 'yaml') {
        $loaded_hashref = LoadFile ($fn);
    }
    else {
        die ("Unknown format: '$format'");
    }

    while (my ($key, $value) = each (%$loaded_hashref)) {
        my $option = $self->key_option ($key);
        unless ($option) {
            my $msg = sprintf ("no such argument '%s' in configuration file '%s'\n", $key, $fn);
            if ($self->{robust}) {
                die ($msg);
            }
            else {
                printf (STDERR "\nWARNING: %s\n\n", $msg);
            }
        }
        $current_config->{ $option->{id} } = $value;
    }

}

sub save_config_file {
    my ($self, $fn, $format, $changes_only) = @_;

    my $full_config = $self->get_config;
    my %output_config;
    foreach my $key (keys (%$full_config)) {
        next if $self->key_option ($key)->{internal};    #Should not load/save internal options
        next if $changes_only and same_config_value ($full_config->{$key}, $self->key_option ($key)->{default});
        $output_config{$key} = $full_config->{$key};
    }

    if (!defined ($format) || lc ($format) eq 'config::record') {
        my $config_rec = Config::Record->new ();
        $config_rec->set ($_, $output_config{$_}) for (keys (%output_config));
        $config_rec->save ($fn);
    }
    elsif (lc ($format) eq 'yaml') {
        my $fh;
        if (ref ($fn)) {
            if (!$fn->isa ("IO::Handle")) {
                die ("file must be an instance of IO::Handle");
            }
            $fh = $fn;
        } else {
            $fh = IO::File->new (">$fn")
              or die ("cannot write to '$fn': $!");
        }
        print ($fh Dump (\%output_config));
        $fh->close ();
    }
    else {
        die ("Unknown format: '$format'");
    }
}

sub same_config_value {
    my ($first, $second) = @_;
    if (ref ($first) eq 'ARRAY' and ref ($second) eq 'ARRAY') {
        return undef unless @$first == @$second;
        for (my $i = 0 ; $i < @$first ; $i++) {
            return undef if $first->[$i] ne $second->[$i];
        }
        return 1;
    }
    else {
        return $first eq $second;
    }
}

sub get_config_dump {
    my ($self, $keys_to_keep, $keys_to_ignore) = @_;

    my $mem_fh;
    my $dump = '';
    open ($mem_fh, '>', \$dump) or die ("Could not open a filehandle to memory\n");

    $keys_to_ignore = [] unless $keys_to_ignore;
    my %ignore_lookup;
    $ignore_lookup{$_}++ for @$keys_to_ignore;

    my %keep_lookup;
    if ($keys_to_keep) {
        $keep_lookup{$_}++ for @$keys_to_keep;
    }

    my $config_rec = Config::Record->new ();
    my $config = $self->get_config;
    foreach my $key (sort (keys (%$config))) {
        next if $keys_to_keep && !$keep_lookup{$key};
        next if $ignore_lookup{$key};
        next if $self->key_option ($key)->{internal};    #Should not load/save internal options

        print ($mem_fh "$key = ");
        $config_rec->_format ($mem_fh, $config->{$key}, "");
    }
    close ($mem_fh);
    return $dump;
}

sub get_group_options {
    my ($self, $group) = @_;
    $group = 0 unless defined ($group);
    return $self->{'group_options'}->[$group];
}

sub get_group_label {
    my ($self, $group) = @_;
    $group = 0 unless defined ($group);
    return $self->{'group_labels'}->[$group];
}

sub simple {
    my ($class, $options, $documentation) = @_;
    my $ezconf = $class->new ();
    foreach my $option (@$options) {
        if (!ref ($option)) {
            $option = { id => $option };
        }
        if (!defined ($option->{label})) {
            my $label = ucfirst ($option->{id});
            $label =~ s/[_-]/ /g;
            $option->{label} = $label;
        }
        $option->{description} = "Sets the " . lcfirst ($option->{label}) unless defined ($option->{description});
        $option->{type}        = 'string'                                 unless defined ($option->{type});
        $option->{default}     = ''                                       unless defined ($option->{default});
        $ezconf->add_option (%$option);
    }

    if ($documentation) {
        while (my ($section, $doc) = each (%$documentation)) {
            $ezconf->add_to_documentation ($section, $doc);
        }
    }
    return $ezconf->parse_config (@ARGV);
}

sub serialize
{
    my ($self) = @_;

    foreach my $opt (grep { $_->{type} eq 'file' } @{ $self->{options} })
    {
        my $fn = $self->{config}->{ $opt->{id} };

        if ($fn and -e $fn and not -d $fn)
        {
            $self->{attachments}->{ File::Util::strip_path ($fn) } =
              File::Slurp::read_file ($fn, binmode => ':raw');
        }
    }

    return Storable::nfreeze ($self);
}
