#!/usr/bin/perl -w

=head1 NAME

gps-replay.pl - opens a file (e.g. NMEA) and plays that file in a loop to a pty device.

=cut

use IO::Pty;
use Time::HiRes qw(sleep);
use Getopt::Std;

my $opt={};
getopts('P:T:S:', $opt);
$opt->{'S'}||=0.5;

my $file=shift()||'';
if (-r $file) {
  if ($opt->{'P'}) {
    open(FILE, ">".$opt->{'P'}) || die;
    print FILE "$$\n";
    close(FILE);
  }
  my $pty=new IO::Pty;
  if ($opt->{'T'}) {
    open(FILE, ">".$opt->{'T'}) || die;
    print FILE $pty->ttyname,"\n";
    close(FILE);
  } else {
    print "pty: ",$pty->ttyname,"\n";
  }

  my $i=0;
  while (1) {
    open(FH, $file);
    while (<FH>) {
      $pty->print($_);
      $|=1;
      sleep 0.2;
    }
    close FH;
  }
} else {
  print "usage: $0 [-P pidfile] [-T ptyfile] [-S seconds] filename\n";
}
