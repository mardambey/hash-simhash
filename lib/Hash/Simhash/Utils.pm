package Hash::Simhash::Utils;

use Moose::Role;

sub hd {
	my ($self, $x, $y) = @_;
	my $dist = 0;
	my $val = $x ^ $y;

	while($val)
  {
     ++$dist; 
     $val &= $val - 1;
  }

	return $dist;
}

no Moose;

1;
