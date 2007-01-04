#!/usr/bin/perl -w

=head1 NAME

example-subscribe - Net::GPSD subscribe method example

=cut

use strict;
use lib qw{./lib ../lib};
use Net::GPSD;

my ($host,$port)=split(q{:}, shift()||'');
$host||=q{localhost};
$port||=q{2947};

my $gps=Net::GPSD->new(host=>$host, port=>$port)
    || die("Error: Cannot connect to the gpsd server");

$gps->subscribe(handler=>\&point_handler);

print "Note: Nothing after the subscribe will be executed.\n";

sub point_handler {
  my $last_return=shift()||1; #the return from the last call or undef if first
  my $point=shift(); #current point $point->fix is true!
  my $config=shift();
  print $last_return, " ", $point->latlon. "\n";
  return $last_return + 1; #Return a true scalar type e.g. $a, {}, []
                           #try the interesting return of $point
}
