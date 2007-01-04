package Net::GPSD::Satellite;

=pod

=head1 NAME

Net::GPSD::Satellite - Provides an interface for a gps satellite object.

=head1 SYNOPSIS

  use Net::GPSD;
  my $obj=Net::GPSD->new();
  my $i=0;
  print join("\t", qw{Count PRN ELEV Azim SNR USED}), "\n";
  foreach ($obj->getsatellitelist) {
    print join "\t", ++$i,
                     $_->prn,
                     $_->elev,
                     $_->azim,
                     $_->snr,
                     $_->used;
                     $_->oid;
    print "\n";
  }

or to construct a satelite object

  use Net::GPSD::Satelite;
  my $obj=Net::GPSD::Satellite->new(22,80,79,35,1);

or to create a satelite object

  use Net::GPSD::Satelite;
  my $obj=Net::GPSD::Satellite->new();
  $obj->prn(22), 
  $obj->elev(80), 
  $obj->azim(79), 
  $obj->snr(35), 
  $obj->used(1);

=head1 DESCRIPTION

=cut

use strict;
use vars qw($VERSION);
use GPS::PRN;

$VERSION = sprintf("%d.%02d", q{Revision: 0.33} =~ /(\d+)\.(\d+)/);

=head1 CONSTRUCTOR

=head2 new

  my $obj=Net::GPSD::Satellite->new($prn,$elev,$azim,$snr,$used);

=cut

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

=head1 METHODS

=cut

sub initialize {
  my $self = shift();
  $self->{'gpsprn'}=GPS::PRN->new();
  if (scalar(@_)) {
    $self->prn(shift());
    $self->elevation(shift());
    $self->azimuth(shift());
    $self->snr(shift());
    $self->used(shift());
  }
}

=head2 prn

Returns the Satellite PRN number.

  $obj->prn(22); 
  my $prn=$obj->prn; 

=cut

sub prn {
  my $self=shift();
  if (@_) {
    $self->{'prn'}=shift();
    if (int($self->{'prn'})) { #PRN != 0 ?
      $self->{'oid'}=$self->{'gpsprn'}->oid_prn($self->{'prn'});
    }
  } #sets value
  return $self->{'prn'};
}

=head2 oid

Returns the Satellite Object ID from the GPS::PRN package.

  $obj->oid(22216); 
  my $oid=$obj->oid; 

=cut

sub oid {
  my $self=shift();
  if (@_) {
    $self->{'oid'}=shift();
    $self->{'prn'}=$self->{'gpsprn'}->prn_oid($self->{'oid'});
  } #sets value
  return $self->{'oid'};
}

=head2 elevation (aka elev)

Returns the satellite elevation, 0 to 90 degrees.

  $obj->elev(80); 
  my $elev=$obj->elev; 

=cut

sub elevation {
  my $self = shift();
  if (@_) { $self->{'elevation'} = shift() } #sets value
  return $self->{'elevation'};
}

sub elev {
  my $self = shift();
  return $self->elevation(@_);
}

=head2 azimuth (aka azim)

Returns the satellite azimuth, 0 to 359 degrees.

  $obj->azim(79); 
  my $azim=$obj->azim; 

=cut

sub azimuth {
  my $self = shift();
  if (@_) { $self->{'azimuth'} = shift() } #sets value
  return $self->{'azimuth'};
}

sub azim {
  my $self = shift();
  return $self->azimuth(@_);
}

=head2 snr

Returns the Signal to Noise ratio (C/No) 00 to 99 dB, null when not tracking.

  $obj->snr(35); 
  my $snr=$obj->snr; 

=cut

sub snr {
  my $self = shift();
  if (@_) { $self->{'snr'} = shift() } #sets value
  return $self->{'snr'};
}

=head2 used

Returns a 1 or 0 according to if the satellite was or was not used in the last fix.

  $obj->used(1);
  my $used=$obj->used; 

=cut

sub used {
  my $self = shift();
  if (@_) { $self->{'used'} = shift() } #sets value
  return $self->{'used'};
}

sub q2u {
  my $a=shift();
  return $a eq '?' ? undef() : $a;
}

1;
__END__

=head1 GETTING STARTED

=head1 KNOWN LIMITATIONS

=head1 BUGS

No known bugs.

=head1 EXAMPLES

=head1 AUTHOR

Michael R. Davis, qw/gpsd michaelrdavis com/

=head1 LICENSE

Copyright (c) 2006 Michael R. Davis (mrdvt92)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
