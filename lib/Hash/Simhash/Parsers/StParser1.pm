package Hash::Simhash::Parsers::StParser1;

# Parses the following types of stack traces:
#
# Jan 2, 2013 12:16:12 AM com.edate.web.common.components.widgets.NewsFeedList markFeedsRead
# WARNING: Unable to mark feeds as read for profile 36397649
#

#
# Jan 2, 2013 12:23:17 AM org.apache.catalina.ha.session.DeltaManager messageReceived
# SEVERE: Manager [localhost#/nw]: Unable to receive message through TCP channel
# java.lang.IllegalStateException: setAttribute: Session already invalidated
#   at org.apache.catalina.session.StandardSession.setAttribute(StandardSession.java:1347)
#

#
# Jan 2, 2013 12:35:43 AM com.edate.web.common.utils.PixelUtil replacePixelParams
# WARNING: Could not decompose the query string. java.lang.Exception: Tokenizing mismatch.  Cannot process provided URL.
#
# com.edate.common.util.StringUtil.decomposeURL(Unknown Source)
# com.edate.common.util.StringUtil.decomposeURL(Unknown Source)
# com.edate.web.common.utils.PixelUtil.replacePixelParams(Unknown Source)
#

use DateTime::Format::Strptime;
use Moose;
with 'Hash::Simhash::Parsers::StacktraceParser';

has dt_parser => (
	is  => 'rw',
	default => sub {
		DateTime::Format::Strptime->new(
			pattern => "%b %d, %Y %l:%M:%S %p",
			on_error => 'undef');	
		}
);

sub parse {
	my ($self, $fd) = @_;
	# Look for: DATE CLASSNAME METHODNAME
	#
	# for example:
	# Jan 2, 2013 12:35:43 AM com.edate.web.common.utils.PixelUtil replacePixelParams
	if ($fd->cur_line =~ /^(\w+\s\d+,\s\d+\s\d+:\d+:\d+\s\w+)\s(.+)\s(.+)$/) {

		my $dt = $1;
		my $cls = $2;
		my $method = $3;
		my $msg_line = $fd->next_line;
		my $msg = "";
		my $level = "";
		my $stacktrace = [];

		# Look for: LOGLEVEL: LOGMESSAGE
		#
		# for example:
		#
		# WARNING: Could not decompose the query string. java.lang.Exception: Tokenizing mismatch.  Cannot process provided URL.
		# SEVERE: Manager [localhost#/nw]: Unable to receive message through TCP channel
		# WARNING: Unable to mark feeds as read for profile 36397649
		if ($msg_line =~ /(\w+):\s(.*)$/) {
			$level = $1;
			$msg = $2;

			# clean up stage
			# strip numbers, they are usually id's or bytes etc.
			$msg =~ s/-?\d+//g;
			# strip out the profile's nickname in the following:
			# In the profile Jennyqueen, the profile online
			$msg =~ s/In the profile (\w+), the /In the profile NICK, the /;

			$fd->next_line;

			LAST: while ($fd->cur_line) {
				my $l = $fd->cur_line;
				$l =~ s/^\s+|\s+$//g;

				if ($l =~ /^\s*$/) {
					$fd->next_line;
				} else {
					# Look for: CLASSNAME(LINE INFO)
					#
					# for example:
					# com.edate.common.util.StringUtil.decomposeURL(Unknown Source)
					if ($l =~ /^(\w+\.)+\w+\((.*)\)$/) {
						push(@$stacktrace, $l);
						$fd->next_line;
					# Look for: EXCEPTIONCLASS: MESSAGE
					#
					# for example:
					# java.lang.IllegalStateException: setAttribute: Session already invalidated
					} elsif ($l =~ /^(\w+\.)+\w+:(.*)$/) {
						push(@$stacktrace, $l);
						$fd->next_line;
					# Look for: at CLASS.METHOD(LINE INFO)
					#
					# for example:
					# at org.apache.catalina.session.StandardSession.setAttribute(StandardSession.java:1347)
					} elsif ($l =~ /^at\s(\w+\.)+\w+\((.*)\)$/) {
						push(@$stacktrace, $l);
						$fd->next_line;
					} else {
						last LAST;
					}
				}
			}

		} else {
			$level = $msg = "";
		}

		my $st = Stacktrace->new(
			datetime => $self->parse_datetime($dt),
			class    => $cls,
			method   => $method,
			level    => $level,
			message  => $msg,
			stacktrace => $stacktrace);

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

