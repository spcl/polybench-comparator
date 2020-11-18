#!/usr/bin/env python3
# Polybench Comparator
# https://github.com/spcl/polybench-comparator
# Copyright 2018 ETH Zurich
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the follo
# wing conditions are met:
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following
# disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following
# disclaimer in the documentation and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote
# products derived from this software without specific prior written permission.
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# ==============================================================================

import sys

# Tolerance values (per-value, overall, acceptable #errors)
VALUE_ATOL = 1e-5
OVERALL_ATOL = 1e-4
ACCEPTABLE_ERROR_PERCENTAGE = 25.0


def usage():
    print("USAGE: comparator.py [-i] <REFERENCE FILE> <OUTPUT FILE>")
    print("-i ignores newlines")
    sys.exit(2)


def compare(ref_file, cmp_file, ignore_newlines=False):
    """
    Compares a reference and result file for a Polybench experiment.

    :return: True if the files are identical within a tolerance,
             False otherwise.
    """

    total_error = 0.0
    num_errors = 0
    num_values = 0

    with open(ref_file, 'rb') as rf:
        with open(cmp_file, 'rb') as cf:
            rlines = rf.readlines()
            clines = cf.readlines()

            # Ignore newlines by pasting all the lines together
            if ignore_newlines:
                rlines = [b' '.join(rlines)]
                clines = [b' '.join(clines)]

            if len(rlines) != len(clines):
                print('ERROR: Line count mismatch! (%d != %d)' % (len(rlines), len(clines)))
                return False

            # Compare each line
            for lnum, (rline, cline) in enumerate(zip(rlines, clines)):
                rtoks = rline.split()
                ctoks = cline.split()
                if len(rtoks) != len(ctoks):
                    print('ERROR: Row length mismatch at line %d' % (lnum + 1))
                    return False

                # Compare each token
                for i, (rtok, ctok) in enumerate(zip(rtoks, ctoks)):
                    try:
                        refval = float(rtok)
                    except:  # String comparison
                        if rtok != ctok:
                            print('ERROR: Non-numeric token mismatch at ' + '(%d, %d): %s != %s' %
                                  (lnum + 1, i + 1, rtok, ctok))
                            return False
                        continue
                    # Float comparison
                    try:
                        cmpval = float(ctok)
                    except:
                        print('ERROR: Token type mismatch at ' + '(%d, %d): %s != %s' % (lnum + 1, i + 1, rtok, ctok))
                        return False
                    diff = abs(refval - cmpval)
                    total_error += diff

                    if diff >= VALUE_ATOL:
                        num_errors += 1
                    num_values += 1

    if num_values == 0:
        print('ERROR: No values to compare')
        return False

    absdiff = (total_error / num_values)
    err_percentage = (num_errors / num_values * 100.0)
    print('Abs. diff: %.8f, errors: %d (%.1f%%)' % (absdiff, num_errors, err_percentage))

    if absdiff > OVERALL_ATOL or err_percentage > ACCEPTABLE_ERROR_PERCENTAGE:
        return False


if __name__ == "__main__":
    if len(sys.argv) < 3 or len(sys.argv) > 4:
        usage()
    if sys.argv[1] == '-i':
        if len(sys.argv) != 4:
            usage()
        ref_file = sys.argv[2]
        cmp_file = sys.argv[3]
        ignore_newlines = True
    else:
        ref_file = sys.argv[1]
        cmp_file = sys.argv[2]
        ignore_newlines = False
    if compare(ref_file, cmp_file, ignore_newlines):
        sys.exit(0)
    else:
        sys.exit(1)
