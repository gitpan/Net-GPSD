use ExtUtils::MakeMaker;
WriteMakefile(
  NAME      => q{Net::GPSD},
  VERSION_FROM => q{lib/Net/GPSD.pm},
  PREREQ_PM => {
                 strict             => 0,
                 vars               => 0,
                 Geo::Forward       => 0,
                 Geo::Inverse       => 0,
                 IO::Socket::INET   => 0,
                 LWP::UserAgent     => 0,
               },
               ($] >= 5.005 ? 
                 (
                   ABSTRACT_FROM => 'lib/Net/GPSD.pm',
                 ) : ()
               ),
             );
