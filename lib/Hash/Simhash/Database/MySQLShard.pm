package Hash::Simhash::Database::MySQLShard;

use strict;
use warnings;
use Moose;
use DBI;
with 'Hash::Simhash::Database::Shard';
with 'Hash::Simhash::Utils';

has dsn  => ( is => "ro", isa => "Str", required => 1, );
has user => ( is => "ro", isa => "Str", required => 1, );
has pass => ( is => "ro", isa => "Str", required => 1, );
has table_prefix => ( is => "ro", isa => "Str", default => "simhash_", );

# private
has dbh   => ( is => "rw", );
has table => ( is => "rw", );

sub BUILD {
	my $self = shift;
	$self->table($self->table_prefix . $self->id);
}

sub connect { 
	my $self = shift;

	return 0 unless $self->dbh(DBI->connect($self->dsn, $self->user, $self->pass, {RaiseError => 1, PrintError => 0}));
	return 1;
}
sub disconnect { 
	my $self = shift;
	$self->dbh()->disconnect();
	return 1;
}
sub find { 
	my ($self, $hash, $hamming_thresh) = @_;
	my $limit = 2;
	my $query = sprintf("(SELECT * FROM %s WHERE hash < ? ORDER BY hash DESC LIMIT ?) UNION (SELECT * FROM %s WHERE hash >= ? ORDER BY hash ASC LIMIT ?) ORDER BY hash ASC",
		$self->table, $self->table);

	my $hashes = $self->dbh()->selectall_hashref($query, "hash", {}, $hash, $limit, $hash, $limit);

	return 0 if (scalar keys %$hashes == 0);

  foreach my $key (keys %$hashes) {
		return 1 if ($self->hd($hash, $key) < $hamming_thresh);
  }

	return 0;

}
sub add {
	my ($self, $hash, $data) = @_;

	eval {
		my $query = sprintf("INSERT INTO %s values(?, ?)", $self->table);
		my $sth = $self->dbh()->prepare($query);
		$sth->execute($hash, $data);
		return 1;
	};	

	return 0 if ($@); # eval failed
	return 1;
}

no Moose;

1;
