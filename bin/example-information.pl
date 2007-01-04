#!/usr/bin/perl -w

=head1 NAME

example-information - Net::GPSD example to get gpsd server and perl module information

=cut

use strict;
use lib qw{./lib ../lib};
use Net::GPSD;

my ($host,$port)=split(q{:}, shift()||'');
$host||=q{localhost};
$port||=q{2947};

my $gps=Net::GPSD->new(host=>$host, port=>$port) || die("Error: Cannot connect to the gpsd server");

print "Net::GPSD Version:\t", $gps->VERSION. "\n";
print "gpsd Version:\t\t", $gps->daemon. "\n";
print "gpsd Commands:\t\t", $gps->commands. "\n";
print "Host:\t\t\t", $gps->host. "\n";
print "Port:\t\t\t", $gps->port. "\n";
print "Baud:\t\t\t", $gps->baud. "\n";
print "Rate:\t\t\t", $gps->rate. "\n";
print "Device:\t\t\t", $gps->device. "\n";
print "ID:\t\t\t", $gps->id. "\n";
print "Protocol:\t\t", $gps->protocol. "\n";
