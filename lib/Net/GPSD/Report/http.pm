package Net::GPSD::Report::http;

=pod

=head1 NAME

Net::GPSD::Report::http - Provides a perl interface to report position data. 

=head1 SYNOPSIS

  use Net::GPSD::Report::http;
  my $obj=Net::GPSD::Report::http->new();
  my $return=$obj->send(\%data);

=head1 DESCRIPTION

=cut

use strict;
use vars qw($VERSION);

$VERSION = sprintf("%d.%02d", q{Revision: 0.30} =~ /(\d+)\.(\d+)/);

=head1 CONSTRUCTOR

=head2 new

  my $obj=Net::GPSD::Report::http->new({url=>$url});

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
  my $self=shift();
  my $data=shift();
  $data->{'url'}||='http://maps.davisnetworks.com/tracking/position_report.cgi';
  foreach (keys %$data) {
    $self->{$_}=$data->{$_};
  }
}

=head2 url

  $obj->url("http://localhost/path/script.cgi");
  my $url=$obj->url;

=cut

sub url {
  my $self = shift();
  if (@_) { $self->{'url'} = shift() } #sets value
  return $self->{'url'};
}

=head2 send

  my $httpreturn=$obj->send({device=>$int,
                             lat=>$lat,
                             lon=>$lon,
                             dtg=>"yyyy-mm-dd 24:mm:ss.sss",
                             speed=>$meterspersecond,
                             heading=>$degrees});

=cut

sub send {
  my $self=shift();
  my $data=shift(); #{}
  use LWP::UserAgent;
  my $ua=LWP::UserAgent->new();
  my $res = $ua->post($self->url, $data);
  return $res->is_success ? $res->content : undef();
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

http://maps.davisnetworks.com/tracking/position_report.cgi

http://maps.davisnetworks.com/tracking/display_device.cgi

LWP::UserAgent

=cut
