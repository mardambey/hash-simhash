package Hash::Simhash;

use Exporter "import";
@EXPORT_OK = qw(sh_simhash permutations);

use Inline C => <<"END_C";

#include <string.h>

#define SIMHASH_BIT 64

unsigned long int sh_hash(const char *arKey, unsigned int nKeyLength)
{
    int i = 0;
    register unsigned long int hash = 5381;

    for(; nKeyLength >= 8; nKeyLength -= 8) {
        hash = ((hash << 5) + hash) + *arKey++;
        hash = ((hash << 5) + hash) + *arKey++;
        hash = ((hash << 5) + hash) + *arKey++;
        hash = ((hash << 5) + hash) + *arKey++;
        hash = ((hash << 5) + hash) + *arKey++;
        hash = ((hash << 5) + hash) + *arKey++;
        hash = ((hash << 5) + hash) + *arKey++;
        hash = ((hash << 5) + hash) + *arKey++;
    }
    switch(nKeyLength) {
        case 7: hash = ((hash << 5) + hash) + *arKey++;
        case 6: hash = ((hash << 5) + hash) + *arKey++;
        case 5: hash = ((hash << 5) + hash) + *arKey++;
        case 4: hash = ((hash << 5) + hash) + *arKey++;
        case 3: hash = ((hash << 5) + hash) + *arKey++;
        case 2: hash = ((hash << 5) + hash) + *arKey++;
        case 1: hash = ((hash << 5) + hash) + *arKey++;break;
        case 0: break;
    }

    return hash;
}

unsigned long sh_simhash(AV* tokens, unsigned int length) {
    float hash_vector[SIMHASH_BIT];
    memset(hash_vector, 0, SIMHASH_BIT * sizeof(float));
    unsigned long int token_hash = 0;
    unsigned long int simhash = 0;
    int current_bit = 0;
		int i;

    for(i=0; i<length; i++) {
        STRLEN l;
				char *token = (char*) SvPV(*av_fetch(tokens, i, 0), l);
        token_hash = sh_hash(token, l);
				int j;
        for(j=SIMHASH_BIT-1; j>=0; j--) {
            current_bit = token_hash & 0x1;
            if(current_bit == 1) {
                hash_vector[j] += 1;
            } else {
                hash_vector[j] -= 1;
            }
            token_hash = token_hash >> 1;
        }
    }

    for(i=0; i<SIMHASH_BIT; i++) {
        if(hash_vector[i] > 0) {
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
