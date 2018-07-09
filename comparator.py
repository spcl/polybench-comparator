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


if len(sys.argv) != 3:
    print("USAGE: comparator.py <REFERENCE FILE> <OUTPUT FILE>")
    sys.exit(2)

ref_file = sys.argv[1]
cmp_file = sys.argv[2]

total_error = 0.0
num_errors = 0
num_values = 0

with open(ref_file, 'rb') as rf:
    with open(cmp_file, 'rb') as cf:
        rlines = rf.readlines()
        clines = cf.readlines()
        if len(rlines) != len(clines):
            print('ERROR: Length mismatch! (%d != %d)' % (len(rlines), 
                                                          len(clines)))
            sys.exit(3)

        # Compare each line
        for lnum, (rline, cline) in enumerate(zip(rlines, clines)):
            rtoks = rline.split()
            ctoks = cline.split()
            if len(rtoks) != len(ctoks):
                print('ERROR: Row length mismatch at line %d' % (lnum+1))
                sys.exit(4)

            # Compare each token
            for i, (rtok, ctok) in enumerate(zip(rtoks, ctoks)):
                try:
                    refval = float(rtok)
                except: # String comparison
                    if rtok != ctok:
                        print('ERROR: Non-numeric token mismatch at ' +
                              '(%d, %d): %s != %s' % (lnum+1, i+1, rtok, ctok))
                        sys.exit(5)
                    continue
                # Float comparison
                try:
                    cmpval = float(ctok)
                except:
                    print('ERROR: Token type mismatch at ' +
                          '(%d, %d): %s != %s' % (lnum+1, i+1, rtok, ctok))
                    sys.exit(6)
                diff = abs(refval - cmpval)
                total_error += diff

                if diff >= VALUE_ATOL:
                    num_errors += 1
                num_values += 1

if num_values == 0:
    print('ERROR: No values to compare')
    sys.exit(7)

absdiff = (total_error / num_values)
err_percentage = (num_errors / num_values * 100.0)
print('Abs. diff: %.8f, errors: %d (%.1f%%)' % (absdiff, num_errors, 
                                                err_percentage))

if absdiff > OVERALL_ATOL or err_percentage > ACCEPTABLE_ERROR_PERCENTAGE:
      sys.exit(1)
