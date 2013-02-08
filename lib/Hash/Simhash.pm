package Hash::Simhash;

use Exporter "import";
@EXPORT_OK = qw(sh_simhash permutations);

use Inline C => <<"END_C";

#include <string.h>

#define SIMHASH_BIT 64

// siphash implementation based on Redis

static uint8_t sh_seed[16] = {6,4,7,9,2,4,8,3,5,9,0,2,5,7,0,1};

unsigned long sh_hash(const char *buf, int len) {
	uint64_t n = len;
	uint64_t v0, v1, v2, v3;
	uint64_t k0, k1;
	uint64_t mi, mask, length;
	size_t i, k;
    
	k0 = *((uint64_t*)(sh_seed + 0));
	k1 = *((uint64_t*)(sh_seed + 8));

	v0 = k0 ^ 0x736f6d6570736575ULL;
	v1 = k1 ^ 0x646f72616e646f6dULL;
	v2 = k0 ^ 0x6c7967656e657261ULL;
	v3 = k1 ^ 0x7465646279746573ULL;

#define rotl64(x, c) ( ((x) << (c)) ^ ((x) >> (64-(c))) )

#define HALF_ROUND(a, b, c, d, s, t) \\
	do { \\
		a += b;  c += d; \\
		b = rotl64(b, s); d = rotl64(d, t); \\
		b ^= a;  d ^= c; \\
	} while(0)

#define COMPRESS(v0,v1,v2,v3) \\
	do { \\
		HALF_ROUND(v0,v1,v2,v3,13,16); \\
		v0 = rotl64(v0,32); \\
		HALF_ROUND(v2,v1,v0,v3,17,21); \\
		v2 = rotl64(v2, 32); \\
	} while(0)

	for (i = 0; i < (n-n%8); i += 8) {
		mi = *((uint64_t*)(buf + i));
		v3 ^= mi;
		for (k = 0; k < 2; ++k) COMPRESS(v0,v1,v2,v3);
		v0 ^= mi;
	}

	mi = *((uint64_t*)(buf + i));
	length = (n&0xff) << 56;
	mask = n%8 == 0 ? 0 : 0xffffffffffffffffULL >> (8*(8-n%8));
	mi = (mi&mask) ^ length;

	v3 ^= mi;
	for (k = 0; k < 2; ++k) COMPRESS(v0,v1,v2,v3);
	v0 ^= mi;

	v2 ^= 0xff;
	for (k = 0; k < 4; ++k) COMPRESS(v0,v1,v2,v3);

#undef rotl64
#undef COMPRESS
#undef HALF_ROUND
	return (unsigned long)((v0 ^ v1) ^ (v2 ^ v3));
}

unsigned long sh_simhash(AV* tokens, unsigned int length) {
	float hash_vector[SIMHASH_BIT];
	memset(hash_vector, 0, SIMHASH_BIT * sizeof(float));
	unsigned long int token_hash = 0;
	unsigned long int simhash = 0;
	int current_bit = 0;
	int i;

	for (i=0; i<length; i++) {
		STRLEN l;
		char *token = (char*) SvPV(*av_fetch(tokens, i, 0), l);
		token_hash = sh_hash(token, l);
		int j;

		for (j=SIMHASH_BIT-1; j>=0; j--) {
			current_bit = token_hash & 0x1;
			if (current_bit == 1) {
				hash_vector[j] += 1;
			} else {
				hash_vector[j] -= 1;
			}

			token_hash = token_hash >> 1;
		}
	}

	for (i=0; i<SIMHASH_BIT; i++) {
		if (hash_vector[i] > 0) {
			simhash = (simhash << 1) + 0x1;
		} else {
			simhash = simhash << 1;
		}
	}

	return simhash;
}

END_C

sub permutations {
	my ($h, $bits) = @_;
	my @ret = ();

	for (1 .. $bits) {
		$h = rotate_left($h, 1, $bits);
		push @ret, $h;
	}

	return \@ret;
}

sub dec2bin {
	my $str = unpack("B64", pack("Q", shift));
	#$str =~ s/^0+(?=\d)//;   # otherwise we'll get leading zeros
	return $str;
}

sub rotate_left {
	my ($bits, $n, $width) = @_;
	return ($bits << $n) | ($bits >> ($width - $n));
}

=head1 NAME

Hash::Simhash - Store values and search for similarity using the Simhash algorithm and sharded databases.

=head1 VERSION

Version 0.9

=cut

our $VERSION = '0.9';

1;
