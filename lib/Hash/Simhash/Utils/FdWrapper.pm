package Hash::Simhash::Utils::FdWrapper;

use Moose;

has c        => ( is => "rw", default => 0, );
has fd       => (	is => "rw", );
has cur_line => ( is => "rw", );

sub next_line {
	my $self = shift;
	$self->c($self->c + 1);
	my $fd = $self->fd;
	my $line = <$fd>;
	$self->cur_line($line);
	$line;
}

no Moose;

package Stacktrace;

use Moose;

has level      => ( is  => 'rw', );
has class      => ( is  => 'rw', );
has method     => (	is  => 'rw', );
has message    => (	is  => 'rw', );
has datetime   => ( is  => 'rw', isa => 'DateTime', );
has stacktrace => (	is  => 'rw', isa => "ArrayRef[Str]",	default => sub { [] },);

sub string {
	my $self = shift;

	sprintf("{datetime: %s, class: %s, level: %s, method: %s, message: %s, stacktrace: %s}",
		$self->datetime || "", $self->class || "", $self->level || "", $self->method || "", $self->message || "", join("\n", @{$self->stacktrace}));
}

sub string_forhash {
	my $self = shift;

	sprintf("%s %s %s %s %s",
		$self->class || "", $self->level || "", $self->method || "", $self->message || "", join(" ", @{$self->stacktrace}));
}

no Moose;

1;
