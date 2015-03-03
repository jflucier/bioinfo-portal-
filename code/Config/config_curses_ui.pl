#!/usr/bin/perl -w
use strict;
use warnings;

use Storable;
use Config::EZConf;
use Curses::UI;
use Curses;
use List::Util 'max';

#Parameters:
#   ezconf_fn: filename of a Config::EZConf object saved using Storable
#   out_fm: filename where the resulting configuration (from Config::EZConf::get_config) must be
#       written to (using Storable). Defaults to ezconf_fn.
my ($ezconf_fn, $out_fn) = @ARGV;
if (!defined($ezconf_fn) || !(-e $ezconf_fn)) {
    die("Missing configuration");
}
if (!defined($out_fn)) {
    $out_fn = $ezconf_fn;
}

my $ezconf = retrieve($ezconf_fn) or die("Could not retrieve configuration");

#Might as well save right away, just in case we crash or something
save_config();

my $cui;
build_cui();

#panel_stack contains a stack of opened option panels, starting with the main one
my @panel_stack;
add_option_panel();

$cui->mainloop();

#Build the base of the interface (menu, status bar and bindings)
sub build_cui {
    $cui = new Curses::UI(-color_support => 1);

    my @menu = (
        {   -label   => 'File [Ctrl+X]',
            -submenu => [
                {-label => 'Open...     [Ctrl+O]', -value => \&open_dialog},
                {-label => 'Save as...  [Ctrl+S]', -value => \&save_as_dialog},
                {-label => 'Abort       [Ctrl+C]', -value => \&abort_dialog},
                {-label => 'Done        [Ctrl+Q]', -value => \&exit_dialog}
            ]
        },
    );

    my $menu = $cui->add('menu', 'Menubar', -menu => \@menu,);
    my $status_window = $cui->add('status_window', 'Window', -height => 1, -y => -1);
    $status_window->add('status_bar', 'Label', -reverse => 1, -paddingspaces => 1, -y => -1);

    $cui->set_binding(sub { $menu->focus() }, "\cX");
    $cui->set_binding(\&exit_dialog,    "\cQ");
    $cui->set_binding(\&abort_dialog,   "\cC");
    $cui->set_binding(\&open_dialog,    "\cO");
    $cui->set_binding(\&save_as_dialog, "\cS");

}

#Update the status bar
sub update_status {
    my ($text) = @_;
    $text = "" unless $text;
    my $status_bar = $cui->getobj('status_window')->getobj('status_bar');
    if ($status_bar) {
        $status_bar->text($text);
        $status_bar->draw();
    }
    else {
        $cui->error("Did not find status bar!");
    }
}

sub add_option_panel {
    my ($group) = @_;
    $group = 0 unless defined($group);

    my $options = $ezconf->get_group_options($group);
    my $level   = @panel_stack;

    #The window!
    my $window = $cui->add(
        "panel_$level", 'Window',
        -border    => 1,
        -y         => 1 + $level,
        '-x'       => $level * 3,
        -padtop    => 1,
        -padleft   => 3,
        -padright  => 3,
        -padbottom => 1,
        -height    => scalar(@$options) + 8,
        -title     => $ezconf->get_group_label($group),
        -tfg       => 'blue'
    );

    #The option list!

    my $options_list = $window->add(
        "list_$level", 'Listbox',
        '-values' => [0 .. (@$options - 1)],
        -labels      => option_list_labels($options),
        -onchange    => \&change_config,
        -onselchange => \&change_sel_config,
        -padbottom   => 2,
        -padleft     => 3,
        -padright    => 3,
        -padtop      => 1,
        -height      => scalar(@$options) + 3,
    );

    #The OK button!
    my $ok_button = $window->add(
        "ok_button_panel_$level",
        'Buttonbox',
        -buttons => [
            {   -label    => '< OK >',
                -value    => 1,
                -shortcut => 'O',
                -onpress  => \&remove_option_panel,
            }
        ],
        -buttonalignment => 'right',
        -y               => -2,
        -bg              => 'white',
        -fg              => 'black',
        -padright        => 3,
        -padleft         => 3,
    );

    $options_list->focus();

    push(@panel_stack,
        {window_id => "panel_$level", group => $group, list => $options_list, options => $options});

    change_sel_config();
}

sub option_list_labels {
    my ($options) = @_;

    my $max_label_len = max(map(length($_->{label}), @$options));

    my $labels = {};
    for (my $i = 0; $i < @$options; $i++) {
        my $option = $options->[$i];
        my $type   = $option->{type};
        if ($type eq 'group') {
            $labels->{$i} = '<bold>' . $option->{label} . '...</bold>';
        }
        else {
            $labels->{$i} = sprintf('%-' . $max_label_len . 's : ', $option->{label});
            my $v = $ezconf->get_config->{$option->{id}};
            if ($type eq 'string' || $type eq 'file' || $type eq 'integer' || $type eq 'float') {
                $labels->{$i} .= "<reverse>$v</reverse>";
            }
            elsif ($type eq 'string_list') {
                $labels->{$i} .= '<reverse>' . join('|', @$v) . '</reverse>';
            }
            elsif ($type eq 'boolean') {
                $labels->{$i} .= '<reverse>' . ($v ? 'True' : 'False') . '</reverse>';
            }
        }
    }
    return $labels;
}

sub remove_option_panel {
    my $panel = pop(@panel_stack);
    $cui->delete($panel->{window_id});
    $cui->draw();
    unless (@panel_stack) {

        #Last panel was removed
        save_config();
        exit(0);
    }
}

#Callback, called when the highlited config option changed
sub change_sel_config {
    my $panel = $panel_stack[$#panel_stack];

    #update the status bar with the description of the selected element
    my $desc = $panel->{options}->[$panel->{list}->get_active_value]->{description};
    update_status($desc);
}

#Callback, called when a config option is selected
sub change_config {
    my $panel  = $panel_stack[$#panel_stack];
    my $option = $panel->{options}->[$panel->{list}->get];
    my $type   = $option->{type};
    if ($type eq 'group') {
        add_option_panel($option->{group});
    }
    else {
        my $value = ask_value($option, $ezconf->get_config->{$option->{id}});
        if (defined($value)) {
            $ezconf->set_option($option->{id}, $value);
            $panel->{list}->labels(option_list_labels($panel->{options}));
        }
    }
    $panel->{list}->clear_selection();
}

#Asks the user for a configuration value, usually creates a panel with the appropriate widget, but
#can also call the filebrowser if the option type is a file
sub ask_value {
    my ($option, $default) = @_;

    if ($option->{type} eq 'file') {

        #manque la description
        return $cui->filebrowser(
            -title        => $option->{label} . ': ' . $option->{description},
            -file         => $default,
            -editfilename => 1,
        );
    }
    else {
        my $height = option_widget_height($option);

        #The window!
        my $window = $cui->add(
            "question_window", 'Window',
            -border    => 1,
            -padtop    => 2,
            -padbottom => 2,
            -padleft   => 3,
            -padright  => 3,
            -height    => 11 + $height,
            -title     => $option->{label},
            -tfg       => 'blue'
        );

        #The label
        $window->add(
            'description_label', 'Label',
            -text     => $option->{description},
            -bold     => 1,
            -padtop   => 1,
            -padleft  => 3,
            -padright => 3,
        );

        my $input = add_option_widget($window, $option, $default);

        #The buttons!
        my $buttons = $window->add(
            "buttons",
            'Buttonbox',
            -buttons         => ['ok', 'cancel'],
            -buttonalignment => 'right',
            -y               => -2,
            -bg              => 'white',
            -fg              => 'black',
            -padright        => 3,
            -padleft         => 3,
        );

        $buttons->set_routine('press-button', sub { $window->loose_focus });
        $window->modalfocus;
        $cui->delete("question_window");
        $cui->draw();
        if ($buttons->get) {

            #User clicked OK
            if ($option->{type} eq 'string_list') {
                my $values = $input->values();
                pop(@$values);    #The insert new value line
                return $values;
            }
            else {
                return $input->get();
            }
        }
        else {

            #User clicked cancel
            return undef;
        }
    }
}

#Builds a dialog for updating/deleting/inserting an element in a list configuration option
sub ask_list_element_value {
    my ($default) = @_;

    my $height      = 3;
    my $update_form = defined($default);

    #The window!
    my $window = $cui->add(
        "list_element_window", 'Window',
        -border    => 1,
        -padtop    => 2,
        -padbottom => 2,
        -padleft   => 3,
        -padright  => 3,
        -height    => 10 + $height,
        -title     => $update_form ? "Update list element" : "New list element",
        -tfg       => 'blue'
    );

    my $input = $window->add(
        'list_element_value', 'TextEntry',
        -text => defined($default) ? $default : '',
        -y => 1,
        -border   => 1,
        -padleft  => 3,
        -padright => 3,
    );
    $input->set_binding(sub { $window->loose_focus }, KEY_ENTER());

    #The buttons!
    my $buttons = $window->add(
        "list_element_buttons",
        'Buttonbox',
        -buttons => $update_form
        ? [
            {   -label    => '< Update >',
                -value    => '1',
                -shortcut => 'u'
            },
            {   -label    => '< Delete >',
                -value    => '-1',
                -shortcut => 'd'
            },
            'cancel'
          ]
        : [
            {   -label    => '< Insert >',
                -value    => '1',
                -shortcut => 'i'
            },
            'cancel'
        ],
        -buttonalignment => 'right',
        -y               => -2,
        -bg              => 'white',
        -fg              => 'black',
        -padright        => 3,
        -padleft         => 3,
    );

    $buttons->set_routine('press-button', sub { $window->loose_focus });
    $window->modalfocus;
    $cui->delete("list_element_window");
    $cui->draw();
    if ($buttons->get == 1) {

        #user clicked Updateor insert
        return $input->get();
    }
    elsif ($buttons->get == -1) {

        #user clicked delete
        return wantarray ? (undef, 1) : undef;
    }
    else {

        #User clicked cancel
        return undef;
    }
}

#returns the needed height for the different widgets
sub option_widget_height {
    my ($option) = @_;
    my $type = $option->{type};
    if ($type eq 'string' || $type eq 'integer' || $type eq 'float') {
        return 3;
    }
    elsif ($type eq 'string_list') {
        return 8;
    }
    elsif ($type eq 'boolean') {
        return 4;
    }
    else {
        die("Option of invalid type: '$type'");
    }
}

#adds a widget to the window corresponding to the option type
sub add_option_widget {
    my ($window, $option, $default) = @_;
    my $type = $option->{type};
    if ($type eq 'string' || $type eq 'integer' || $type eq 'float') {

        #The text entry
        my $input = $window->add(
            'value', 'TextEntry',
            -text     => $default,
            -y        => 2,
            -border   => 1,
            -padleft  => 3,
            -padright => 3,
        );
        $input->set_binding(sub { $window->loose_focus }, KEY_ENTER());
    }
    elsif ($type eq 'boolean') {
        return $window->add(
            'value', 'Listbox',
            '-values' => [1, 0],
            -labels   => {0 => 'False', 1 => 'True'},
            -height   => 4,
            -y        => 2,
            -border   => 1,
            -padleft  => 3,
            -padright => 3,
            -radio    => 1,
            -selected => $default ? 0 : 1
        );
    }
    elsif ($type eq 'string_list') {
        return $window->add(
            'string_list', 'Listbox',
            '-values'   => [@$default, '< New value... >'],
            -height     => 8,
            -y          => 2,
            -border     => 1,
            -padleft    => 3,
            -padright   => 3,
            -onchange   => \&change_string_list_value,
            -vscrollbar => 1
        );
    }
    else {
        die("Option of invalid type: '$type'");
    }
}

#Callback, called when an element in a list configuration option is selected
sub change_string_list_value {
    my $list   = $cui->getobj('question_window')->getobj('string_list');
    my $index  = $list->id;
    my $values = $list->values;

    #Is the selected value the last one?
    if ($index == $#$values) {

        #if so, we want to insert a value just before the <insert value>
        if (my $new_value = ask_list_element_value()) {
            splice(@$values, $#$values, 0, $new_value);

            #Place the selection back on the <insert value>
            $index++;
        }
    }
    else {

        #Update or delete value
        my ($new_value, $delete) = ask_list_element_value($values->[$index]);
        if ($new_value) {
            $values->[$index] = $new_value;
        }
        elsif ($delete) {
            splice(@$values, $index, 1);
        }
    }

    $list->values($values);
    $list->clear_selection();
    $list->{-ypos} = $index;
    $list->draw();
}

#Stores the configuration to file
sub save_config {
    store($ezconf->get_config, $out_fn);
}

sub exit_dialog {
    save_config();
    exit(0);
}

sub abort_dialog {
    $ezconf->set_option('--abort', 1);
    save_config();
    exit(0);
}

#Load configuration from file
sub open_dialog {
    my $file = $cui->loadfilebrowser(-tfg => 'blue');
    $ezconf->load_config_file($file);

    #Close all panels because conf has changed
    while (my $panel = pop(@panel_stack)) {
        $cui->delete($panel->{window_id});
    }
    add_option_panel();
}

#Save configuration to file
sub save_as_dialog {
    my $file = $cui->savefilebrowser(-tfg => 'blue');
    $ezconf->save_config_file($file);
}
