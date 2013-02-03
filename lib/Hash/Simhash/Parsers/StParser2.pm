package Hash::Simhash::Parsers::StParser2;

use DateTime::Format::Strptime;
use Moose;
with 'Hash::Simhash::Parsers::StacktraceParser';

has dt_parser => (
	is  => 'rw',
	default => sub {
		DateTime::Format::Strptime->new(
			pattern => "%Y-%m-%d %H:%M:%S.%3N",
			on_error => 'undef');	
		}
);

sub parse {
	my ($self, $fd) = @_;
	# 2013-01-02 00:16:13.994 INFO net.spy.memcached.transcoders.SerializingTranscoder:  Compressed java.util.ArrayList from 35682 to 6473
	if ($fd->cur_line =~ /^(\d+-\d+-\d+\s\d+:\d+:\d+\.\d+)\s(.+)\s(.+):\s(.+)$/) {
		my $st = Stacktrace->new(
			datetime => $self->parse_datetime($1),
			level    => $2,
			class    => $3,
			message  => $4);

		$fd->next_line;

		return $st;
	}

	return undef;
}


sub parse_datetime { 
	my ($self, $str) = @_;
	return $self->dt_parser()->parse_datetime($str);
}

no Moose;

1;
