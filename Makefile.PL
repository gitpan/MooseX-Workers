
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Simple sub-process management for asynchronous tasks",
  "AUTHOR" => "Chris Prather <perigrin\@cpan.org>",
  "BUILD_REQUIRES" => {
    "DateTime" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "POE::Filter::Line" => 0,
    "POE::Filter::Reference" => 0,
    "Scalar::Util" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "MooseX-Workers",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "MooseX::Workers",
  "PREREQ_PM" => {
    "Moose" => 0,
    "Moose::Role" => 0,
    "POE" => 0,
    "POE::Wheel::Run" => 0
  },
  "VERSION" => "0.19",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



