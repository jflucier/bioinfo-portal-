#!/usr/bin/perl -w
use strict;
use warnings;

use Config::EZConf;
my $conf =
  Config::EZConf->simple(
    [$Config::EZConf::Common::MONALogin, {id => 'other_param', default => 'value'}],
    {'Warning' => 'This is simple'});

