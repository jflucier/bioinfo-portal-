#!/usr/bin/perl -w
use strict;
use warnings;

use Config::EZConf;
my $ezconf = Config::EZConf->new();

#file
$ezconf->add_option(
    id          => 'file',
    synonyms    => ['-f'],
    label       => 'File',
    description => 'Path of a file.',
    type        => 'file',
    default     => 'example.pl',
);

#integer
$ezconf->add_option(
    id          => 'integer',
    synonyms    => ['-i'],
    label       => 'Integer',
    description => 'An integer value.',
    type        => 'integer',
    default     => 99,
);

#boolean
$ezconf->add_option(
    id          => 'boolean',
    synonyms    => ['-b'],
    label       => 'Boolean',
    description => 'A boolean value.',
    type        => 'boolean',
    default     => 0,
);

#float
$ezconf->add_option(
    id          => 'float',
    synonyms    => ['-F'],
    label       => 'Float',
    description => 'A float value.',
    type        => 'float',
    default     => 0.5,
);

#string
$ezconf->add_option(
    id          => 'string',
    synonyms    => ['-s'],
    label       => 'String',
    description => 'A scalar value.',
    type        => 'string',
    default     => 'Hello world!',
);

#list
$ezconf->add_option(
    id          => 'list',
    synonyms    => ['-l'],
    label       => 'List',
    description => 'A list of scalar values.',
    type        => 'string_list',
    default     => [10..15,'Alpha','Beta']
);

#Group
my $group = $ezconf->add_group(label => 'More options');
$ezconf->add_option(
    id          => 'option_1',
    label       => 'Option 1',
    description => 'The first of additional options.',
    type        => 'string',
    default     => 'value_1',
    group       => $group
);

#Sub group
my $sub_group = $ezconf->add_group(label => 'Even more options', group => $group);
$ezconf->add_option(
    id          => 'option_2',
    label       => 'Option 2',
    description => 'The Second of additional options.',
    type        => 'string',
    default     => 'value_2',
    group       => $sub_group
);

my $conf = $ezconf->parse_config(@ARGV);

#Print contents of configuration hash
foreach my $id (keys(%$conf)) {
    print("$id: ");
    if(ref($conf->{$id}) eq 'ARRAY') {
        print('[',join(',',@{$conf->{$id}}),"]\n");
    }
    else {
        print($conf->{$id},"\n");
    }
}
