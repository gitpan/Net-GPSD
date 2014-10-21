#!/usr/bin/perl -w

=head1 NAME

example-getsatellitelist - Net::GPSD getsatellitelist method example

=cut


use strict;
use lib qw{./lib ../lib};
use Net::GPSD;

my ($host,$port)=split(q{:}, shift()||'');
$host||=q{localhost};
$port||=q{2947};

my $gps=Net::GPSD->new(host=>$host, port=>$port) || die("Error: Cannot connect to the gpsd server");

my $i=0;
print join("\t", qw{Count PRN ELEV Azim SNR USED}), "\n";
foreach ($gps->getsatellitelist) {
  print join "\t", ++$i,
                   $_->prn,
                   $_->elev,
                   $_->azim,
                   $_->snr,
                   $_->used;
  print "\n";
}
