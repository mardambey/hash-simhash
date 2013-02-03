use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Hash::Simhash',
    AUTHOR              => q{Hisham Mardam-Bey <hisham.mardambey+simhash@gmail.com>},
    VERSION_FROM        => 'lib/Hash/Simhash.pm',
    ABSTRACT_FROM       => 'lib/Hash/Simhash.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Async::Queue' => 0,
        'Getopt::Long' => 0,
        'Moose' => 0,
        'AnyEvent' => 0,
	'Inline::C' => 0,
	'DBI' => 0,
    },
    BUILD_REQUIRES => {
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Hash-Simhash-*' },
);
