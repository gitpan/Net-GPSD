#Copyright (c) 2006 Michael R. Davis (mrdvt92)
#All rights reserved. This program is free software;
#you can redistribute it and/or modify it under the same terms as Perl itself.

package Net::GPSD;

use strict;
use vars qw($VERSION);
use IO::Socket;
use Net::GPSD::Point;
use Net::GPSD::Satellite;

$VERSION = sprintf("%d.%02d", q{Revision: 0.27} =~ /(\d+)\.(\d+)/);

sub new {
  my $this = shift();
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

sub initialize {
  my $self = shift();
  my %param = @_;
  $self->host($param{'host'} || 'localhost');
  $self->port($param{'port'} || '2947');
  unless ($param{'do_not_init'}) { #for testing
    my $data=$self->retrieve('LKIFCB');
    foreach (keys %$data) {
      $self->{$_}=[@{$data->{$_}}]; #there has got to be a better way to do this...
    }
  }
}

sub subscribeget {
  my $self = shift();
  my %param = @_;
  my $last=undef();
  my $handler=$param{'handler'} || \&default_point_handler;
  my $config=$param{'config'} || {};
  while (1) {
    my $point=$self->get();
    if (defined($point) and $point->fix) { #if gps fix
      my $return=&{$handler}($last, $point, $config);
      if (defined($return)) {
        $last=$return;
      } else {
        #  An undefined return does not reset the the $last point variable
      }
    }
    sleep 1; 
  }
}

sub subscribe {
  my $self = shift();
  my %param = @_;
  my $last=undef();
  my $handler=$param{'handler'} || \&default_point_handler;
  my $satlisthandler=$param{'satlisthandler'} || \&default_satellitelist_handler;
  my $config=$param{'config'} || {};
  my $sock = IO::Socket::INET->new(PeerAddr=>$self->host,
                                   PeerPort=>$self->port);
  $sock->send("W\n");
  my $data;
  my $point;
  while (defined($_=$sock->getline)) {
    if (m/,O=/) {
      $point=Net::GPSD::Point->new($self->parse($_));
      $point->mode(defined($point->tag) ? (defined($point->alt) ? 3 : 2) : 0);
      if ($point->fix) {
        my $return=&{$handler}($last, $point, $config);
        $last=$return if (defined($return));
      }
    } elsif (m/,W=/) {
    } elsif (m/,Y=/) {
    } elsif (m/,X=/) {
    } else {
      warn "Unknown: $_\n";
    }
  }
}

sub default_point_handler {
  my $p1=shift(); #last return or undef if first
  my $p2=shift(); #current fix
  my $config=shift(); #configuration data
  print $p2->latlon. "\n";
  return $p2;
}

sub default_satellitelist_handler {
  my $sl=shift();
  my $i=0;
  print join("\t", qw{Count PRN ELEV Azim SNR USED}), "\n";
  foreach (@$sl) {
    print join "\t", ++$i,
                     $_->prn,
                     $_->elev,
                     $_->azim,
                     $_->snr,
                     $_->used;
    print "\n";
  }
  return 1;
}

sub getsatellitelist {
  my $self=shift();
  my $string='Y';
  my $data=$self->retrieve($string);
  my @data = @{$data->{'Y'}};
  shift(@data);             #Drop sentence tag
  my @list = ();
  foreach (@data) {
    #print "$_\n";
    push @list, Net::GPSD::Satellite->new(split " ", $_);
  }
  return @list;
}

sub get {
  my $self=shift();
  my $data=$self->retrieve('SMDO');
  return Net::GPSD::Point->new($data);
}

sub retrieve {
  my $self=shift();
  my $string=shift();
  my $sock=$self->open();
  if (defined($sock)) {
    $sock->send($string) or die("Error: $!");
    my $data=$sock->getline;
    chomp $data;
    return $self->parse($data);
  } else {
    warn "$0: Could not connect to gspd host.\n";
    return undef();
  }
}

sub open {
  my $self=shift();
  my $sock = IO::Socket::INET->new(PeerAddr => $self->host,
                                   PeerPort => $self->port);
  return $sock;
}

sub parse {
  my $self=shift();
  my $line=shift();
  my %data=();
  my @line=split(/[,\n\r]/, $line);  
  foreach (@line) {
    if (m/(.*)=(.*)/) {
      if ($1 eq 'Y') {
        $data{$1}=[split(/:/, $2)]; #Y is : delimited
      } else {
        $data{$1}=[map {$_ eq '?' ? undef() : $_} split(/\s+/, $2)];
      }
    }
  }
  return \%data;
}

sub port {
  my $self = shift();
  if (@_) { $self->{'port'} = shift() } #sets value
  return $self->{'port'};
}

sub host {
  my $self = shift();
  if (@_) { $self->{'host'} = shift() } #sets value
  return $self->{'host'};
}

sub time {
  #seconds between p1 and p2
  my $self=shift();
  my $p1=shift();
  my $p2=shift();
  return abs($p2->time - $p1->time);
}

sub distance {
  #returns meters between p1 and p2
  my $self=shift();
  my $p1=shift();
  my $p2=shift();
  my $earth_polar_circumference_meters_per_degree=6356752.314245 * &PI/180;
  my $earth_equatorial_circumference_meters_per_degree=6378137 * &PI/180;
  my $delta_lat_degrees=$p2->lat - $p1->lat;
  my $delta_lon_degrees=$p2->lon - $p1->lon;
  my $delta_lat_meters=$delta_lat_degrees * $earth_polar_circumference_meters_per_degree;
  my $delta_lon_meters=$delta_lon_degrees * $earth_equatorial_circumference_meters_per_degree * cos(deg2rad($p1->lat + $delta_lat_degrees / 2));
  #print $delta_lat_meters, ":",  $delta_lon_meters, "\n";
  return sqrt($delta_lat_meters**2 + $delta_lon_meters**2);
}

sub track {
  #return calculated point of $p1 in time assuming constant velocity
  my $self=shift();
  my $p1=shift();
  my $time=shift();
  use Geo::Forward;
  my $object = Geo::Forward->new(); # default "WGS-84"
  my $dist=($p1->speed||0) * $time;   #meters
  my ($lat1,$lon1,$faz)=($p1->lat, $p1->lon, $p1->heading||0);
  my ($lat2,$lon2,$baz) = $object->forward($lat1,$lon1,$faz,$dist);

  my $p2=Net::GPSD::Point->new($p1);
  $p2->lat($lat2);
  $p2->lon($lon2);
  $p2->time($p1->time + $time);
  $p2->heading($baz-180);
  return $p2;
}

sub PI {4 * atan2 1, 1;}

sub deg2rad {shift() * &PI/180}

sub baud {
  my $self = shift();
  return q2u $self->{'B'}->[0];
}

sub rate {
  my $self = shift();
  return q2u $self->{'C'}->[0];
}

sub device {
  my $self = shift();
  return q2u $self->{'F'}->[0];
}

sub identification {
  my $self = shift();
  return q2u $self->{'I'}->[0];
}

sub id {
  my $self = shift();
  return $self->identification;
}

sub protocol {
  my $self = shift();
  return q2u $self->{'L'}->[0];
}

sub daemon {
  my $self = shift();
  return q2u $self->{'L'}->[1];
}

sub commands {
  my $self = shift();
  my $string=q2u $self->{'L'}->[2];
  return wantarray ? split(//, $string) : $string
}

sub q2u {
  my $a=shift();
  return $a eq '?' ? undef() : $a;
}

1;
__END__

=pod

=head1 NAME

Net::GPSD - Provides an perl object client interface to the gpsd server daemon. 

=head1 SYNOPSIS

 use Net::GPSD;
 $gps=new Net::GPSD;
 my $point=$gps->get;
 print $point->latlon. "\n";

or

 use Net::GPSD;
 $gps=new Net::GPSD;
 $gps->subscribe;

=head1 DESCRIPTION

Net::GPSD provides a perl interface to gpsd daemon.  gpsd is an open source gps deamon from http://gpsd.berlios.de/.
 
For example the method get() returns a hash reference like

 {S=>[?|0|1|2],
  P=>[lat,lon]}

Fortunately, there are various methods that hide this hash from the user.

=head1 METHODS

=over

=item new

Returns a new gps object.

=item subscribe(handler=>\&sub, config=>{})

Subscribes subroutine to call when a valid fix is obtained.  When the GPS receiver has a good fix this subroutine will be called every second.  The return (in v0.5 must be a ref) from this sub will be sent back as the first argument to the subroutine on the next call.

=item get

Returns a current point object regardless if there is a fix or not.  Application should test if $point->fix is true.

=item getsatellitelist

Returns a list of Net::GPSD::Satellite objects.  (maps to gpsd Y command)

=item port

Get or set the current gpsd TCP port.

=item host

Get or set the current gpsd host.

=item time(p1, p2)

Returns the time difference between two points in seconds.

=item distance(p1, p2)

Returns the distance difference between two points in meters. (plainer calculation)

=item track(p1, time)

Returns a point object at the predicted location of p1 in time seconds. (plainer calculation based on speed and heading)

=item baud

Returns the baud rate of the connect GPS receiver. (maps to gpsd B command first data element)

=item rate

Returns the sampling rate of the GPS receiver. (maps to gpsd C command first data element)

=item device

Returns the GPS device name. (maps to gpsd F command first data element)

=item identification (aka id)

Returns a text string identifying the GPS. (maps to gpsd I command first data element)

=item protocol

Returns the GPSD protocol revision number. (maps to gpsd L command first data element)

=item daemon

Returns the gpsd daemon version. (maps to gpsd L command second data element)

=item commands

Returns a string of accepted request letters. (maps to gpsd L command third data element)

=back

=head1 GETTING STARTED

=head1 KNOWN LIMITATIONS

=head1 BUGS

No known bugs.

=head1 EXAMPLES

 use Net::GPSD;
 $gps=new Net::GPSD;
 my $point=$gps->get;
 if ($point->fix) {
   print $point->latlon. "\n";
 } else {
   print "No fix.\n";
 }

or

 use Net::GPSD;
 $gps=new Net::GPSD;
 $gps->subscribe(handler=>\&point_handler,
                 config=>{key=>"value"});
 sub point_handler {
   my $last_return=shift(); #the return from the last call or undef if first
   my $point=shift(); #current point $point->fix is true!
   my $config=shift();
   print $last_return, " ", $point->latlon. "\n";
   return $last_return + 1; #Return a true scalar type e.g. $a, {}, []
                            #try the interesting return of $point
 }

=over

=item Example Programs

=begin html

<ul>
<li><a href="../../bin/example-information">example-information</a></li>
<li><a href="../../bin/example-get">example-get</a></li>
<li><a href="../../bin/example-subscribe">example-subscribe</a></li>
<li><a href="../../bin/example-getsatellitelist">example-getsatellitelist</a></li>
<li><a href="../../bin/example-tracker">example-tracker</a></li>
<li><a href="../../bin/example-tracker-http">example-tracker-http</a></li>
<li><a href="../../bin/example-check">example-check</a></li>
</ul>

=end html

=back

=head1 AUTHOR

Michael R. Davis, qw/gpsd michaelrdavis com/

=head1 SEE ALSO

gpsd http tracker http://twiki.davisnetworks.com/bin/view/Main/GpsApplications

gpsd home http://gpsd.berlios.de/

=cut
