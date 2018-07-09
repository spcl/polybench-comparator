#!/bin/sh
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

# A script that tests and profiles all configurations of Polybench

if [ $# -lt 1 ]; then
    echo "USAGE: $0 <POLYBENCH PATH> [RESULTS PATH]"
    exit 1
fi

# Setup arguments and paths
POLYBENCH_PATH=$1
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

if [ $# -ge 2 ]; then
    # Create results directory if it doesn't exist
    mkdir -p $2
    
    RESULTSPATH="$( cd "$2" ; pwd -P )"
else
    RESULTSPATH=$SCRIPTPATH/results
    
    # Create results directory if it doesn't exist
    mkdir -p $RESULTSPATH
fi


##################################################

# Include sample configurations
source ./configurations.sh

runall() {
    _gcc
    #_clang
    #_polly
    #_polly_par
    #_icc

    #_pluto_clang_base opt "" ""
    #_pluto_clang_base tiled "--tile" ""
    #_pluto_clang_base par "--tile --parallel" "-fopenmp"
    #_pluto_clang_base lbpar "--tile --parallel --partlbtile" "-fopenmp"
    #_pluto_clang_base mlbpar "--tile --parallel --lbtile --multipar" "-fopenmp"
}

# Parametric
EXTRAFLAGS=
LOGSUFFIX=
runall

# Constant sized arrays and loop bounds
EXTRAFLAGS=-DPOLYBENCH_USE_SCALAR_LB
LOGSUFFIX=-constsize
runall
