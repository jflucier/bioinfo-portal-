#
# Module for Util::StringUtil
#
# Cared for by Jean-Francois Lucier <Jean-Francois.Lucier@USherbrooke.ca>
#
# Copyright Jean-Francois Lucier
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Util::StringUtil - General utility class used to manipulate strings.

=head1 SYNOPSIS

    # class provides

  # This is to escape data in sql query
    my $str = Util::StringUtil::escapeForDB($str);

    # This is to escape data for HTML display
    my $str = Util::StringUtil::escapeForHTML($str);

  # This is to escape data for JavaScript function
    my $str = Util::StringUtil::escapeForJS($str);

  # This is to escape really long word with no space. Generally for HTML display purpose.
    my $str = Util::StringUtil::wordWrap($str);

=head1 DESCRIPTION

This utility class was created to help all display escaping. All functions in this class should be called statically. No
constructor was created for this class.

=head1 CONTACT

Post questions to Jean-Francois Lucier: <Jean-Francois.Lucier@USherbrooke.ca>

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut

package Util::StringUtil;

use List::Util 'reduce';
use strict;

=head2 escapeForDB

  Arg [1]    : string str
  Example    : my $str = Util::StringUtil::escapeForDB($str);
  Description: This is a convenience static method. It should be used to escape data found in an SQL query
                       to prevent the failure of query. This function escapes all ' found in data.
  Returntype : string
  Exceptions : none
  Caller     : general

=cut
sub escapeForDB {
  my ($str) = @_;
  $str =~ s/\\/\\\\/g;
  $str =~ s/'/\\'/g;
  return $str;
}

=head2 escapeForHTML

  Arg [1]    : string str
  Example    : my $str = Util::StringUtil::escapeForHTML($str);
  Description: This is a convenience static method. It should be used to escape data to display in HTML.
                      This function escapes all &, < and > found in data.
  Returntype : string
  Exceptions : none
  Caller     : general

=cut
sub escapeForHTML {
  my ($str) = @_;
  $str =~ s/&/&amp;/g;
  $str =~ s/</&lt;/g;
  $str =~ s/>/&gt;/g;
  return $str;
}

=head2 escapeForJS

  Arg [1]    : string str
  Example    : my $str = Util::StringUtil::escapeForJS($str);
  Description: This is a convenience static method. It should be used to escape data encapsulated in JavaScript functions.
                      This function escapes all ' and " found in data.
  Returntype : string
  Exceptions : none
  Caller     : general

=cut
sub escapeForJS {
  my ($str) = @_;
  $str =~ s/\'/\\'/g;
  $str =~ s/\"/\\"/g;
  $str =~ s/(\r\n|\r|\n)/\\n/g;
  return $str;
}

=head2 wordWrap

  Arg [1]    : string str
  Arg [2]    : int number char before space insertion
  Example    : my $str = Util::StringUtil::wordWrap($str);
  Description: This is a convenience static method. It should be used to escape long word with no space (i.e. sequence field).
                      This function insert a  space after specified number of chars passed in argument to function.
  Returntype : string
  Exceptions : none
  Caller     : general

=cut
sub wordWrap {
  my ($str,$numChar) = @_;
  $str =~ s/(.{$numChar})/$1 /g;
  return $str;
}

=head2 currencyFormat

  Arg [1]    : string number
  Example    : my $str = Util::StringUtil::CurrencyFormatted($str);
  Description: This is a convenience static method. It should be used to convert a float number to 2 decimal number
  Returntype : number with 2 decimal
  Exceptions : none
  Caller     : general

=cut
sub currencyFormatted{
  my $n = shift;
  my $minus = $n < 0 ? '-' : '';
  $n = abs($n);
  $n = int(($n + .005) * 100) / 100;
  $n .= '.00' unless $n =~ /\./;
  $n .= '0' if substr($n,(length($n) - 2),1) eq ".";
  chop $n if $n =~ /\.\d\d0$/;
  return "$minus$n";
}

=head2 thousandComma

  Arg [1]    : int number
  Example    : my $str = Util::StringUtil::thousandComma($number);
  Description: This is a convenience static method. It should be used to convert an integer into a string where a comma separate each thousand.
  Returntype : String the formatted number
  Exceptions : none

=cut
sub thousandComma
{
  my $number = shift;
  my $toprint = "";
  
  while ($number =~ /([0-9]*)([0-9]{3})/)
  {
    $toprint = $toprint eq "" ? $2 : $2 . "," . $toprint;
    $number = $1;
  }

  if ("" eq $number)
  {
    $toprint;
  }
  elsif ("" eq $toprint)
  {
    $number;
  }
  else
  {
    $number . "," . $toprint
  }
}

sub isInteger {
    my $string = shift;
    if($string =~ /[\.|\,]/){
        # is real or something no good
        return 0;
    }
    elsif($string =~ /^\-?\d+/){
        return 1;
    }
    return 0;
}

sub isReal {
    my $string = shift;
	if($string =~ /^\-?\d+(\.\d+)?$/){
		return 1;
    }
    return 0;
}

# create a phrase with no '_' and Uppercase for each words from the argument
sub beautify{
    my $phrase = shift;
    my $beautified = '';
    
    my @words = split (/_| |\./,$phrase);
    
    foreach my $word(@words){
        $beautified .= uc(substr($word,0,1)) . substr($word,1) . ' ';   
    }
    return $beautified;
    
}

# Remove whitespace from the start and end of the string
#http://www.somacon.com/blog/page14.php
sub trimwhitespace
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

=head2 filenameEscape

  Arg [1]    : string the filename to escape
  Example    : my $str = Util::StringUtil::filenameEscape($str);
  Description: This is a convenience static method. It should be used to make sure that name used for file creation doesn't contain non conventionnal character. 
  Returntype : String the formatted filename
  Exceptions : none
  Note       : Al unconventionnal characters are modified to "_"

=cut
sub filenameEscape{
    my $filename = shift;
    $filename =~ tr/a-zA-Z0-9/_/c;
    return $filename;
}

=head2 getCommonPrefix

  Arg [1-n]  : strings to compare
  Example    : my ($str,$pos) = Util::StringUtil::getCommonPrefix(@strs);
  Description: This function return the common prefix (beginning) of the set of string
  Returntype : String, the common prefix : pos, the position it stopped
  Exceptions : none
  

=cut

sub getCommonPrefix{
    my @elements = @_;
    
    return ('',0) unless @elements;
    my $max_common_len = length(reduce { length($a) < length($b) ? $a : $b } @elements );
    
    my $common_char = 'defined';
    my $common_beginning;
    
    my $pos = 0;
    for($pos = 0; $pos < $max_common_len && $common_char; $pos++) { 
        $common_char = substr($elements[0],$pos,1);
        for(my $i = 1; $i < @elements and defined($common_char); $i++) {
            if(substr($elements[$i],$pos,1) ne $common_char) {
                $common_char = undef;
            }
        }
        if(defined($common_char)) {
            $common_beginning .= $common_char;
        }
    
    }
    if ($common_beginning =~ /(.+)\d+$/){
        $common_beginning = $1;
    }
    return $common_beginning; # pos is usefull when
}

1;
