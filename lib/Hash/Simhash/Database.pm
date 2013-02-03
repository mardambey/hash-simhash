package Hash::Simhash::Database;

use strict;
use warnings;
use Moose;
use AnyEvent;
use Async::Queue;

=head1 NAME

Database - Allows for finding and adding hashes in a (sharded) database.

=cut

has shards  => ( is => "ro", isa => "ArrayRef", required => 1, );
has workers => ( is => "rw", isa => "ArrayRef", default => sub { [] });

=head1 METHODS

=head2 BUILD

Connects the given shards and creates ShardWorkers backed
by the given shards to allow for asynchronous querying.

=cut

sub BUILD { 
	my $self = shift;

	return if (!$self->shards);

	$_->connect() for (@{$self->shards});
	
	my $workers = [];

	foreach my $shard (@{$self->shards}) {

		push @$workers, Async::Queue->new(worker => sub {

			my ($args, $cb) = @_;

			if ($args->{method} eq "find") {
				$cb->($shard->find($args->{hash}, $args->{hamming_thresh}));
			} elsif ($args->{method} eq "add") {
				$cb->($shard->add($args->{hash}, $args->{data}));
			} else {
				printf("Unknown method %s encountered.\n", $args->{method});
			}
		});
	}

	$self->workers($workers);
}

=head2 find SCALAR, ARRAYREF 

Looks for the given hash returning
true of false. Optionally accepts permutations,
otherwise calculates them itself.


=cut

sub find {
	my ($self, $sh, $perms, $hamming_thresh) = @_;
	# TODO: handle if $perms is not passed in.
		
	my $cv = AnyEvent->condvar;
	my $results = [];
	my $workers =  $self->workers();

	foreach my $i (0 .. $#$perms) {
		my $worker = $workers->[$i];
		my $hash = $perms->[$i];
		$cv->begin();
		$worker->push({
			method => "find", 
			hash   => $hash, 
			hamming_thresh => $hamming_thresh}, 
			sub {
				my $res = shift;
				$results->[$i] = $res;
				$cv->end();
			}
		);
	}

	$cv->recv;

	for (@$results) { return 1 if $_; }

	return 0;
}

=head2 add SCALAR, ARRAYREF

Adds a hash into the datbase. Optionally accepts permutations,
otherwise calculates them itself.

=cut

sub add {
	my ($self, $sh, $perms, $data) = @_;

	# TODO: handle if $perms is not passed in.
		
	my $cv = AnyEvent->condvar;
	my $results = [];
	my $workers =  $self->workers();

	foreach my $i (0 .. $#$perms) {
		my $worker = $workers->[$i];
		my $hash = $perms->[$i];
		$cv->begin();
		$worker->push({method => "add", hash => $hash, data => $data}, sub {
			my $res = shift;
			$results->[$i] = $res;
			$cv->end();
		});
	}

	$cv->recv;

	for (@$results) { return 0 if (!$_); }

	return 1;
}

no Moose;

1;

