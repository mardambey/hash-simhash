package Hash::Simhash::Database::Shard;

use Moose::Role;

has id => ( is => "ro", required => 1, );

requires "connect";
requires "disconnect";
requires "find";
requires "add";

no Moose;

1;
