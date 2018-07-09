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

# Sample configuration functions for popular compilers and polyhedral toolchains
# NOTE: Assumed to be sourced from test.sh! Requires variable definitions to run correctly.

# Loops over all polybench tests and calls the arguments with the path and the kernel name
foralltests() {
    CATEGORIES=("linear-algebra/blas" "linear-algebra/kernels" "linear-algebra/solvers" "datamining" "stencils" "medley")
    for cat in $CATEGORIES; do
        for dir in $POLYBENCH_PATH/$cat/*; do 
            if [ -d "$dir" ]; then
                $* $dir `basename $dir`
            fi
        done
    done
}

# Generic test function
runtest() {
    LOGFILE=$1
    KPATH=$2
    KERNEL=$3
    FILE=$RESULTSPATH/$LOGFILE
    cd $KPATH
    
    # Clean folder (except for reference output)
    make clean
    if [ $? -ne 0 ]; then
        echo "ERROR in $KERNEL: make clean"
        cd -
        return
    fi

    # Compare results
    make cmp |& tee -a $FILE$LOGSUFFIX.cmp
    if [ $? -ne 0 ]; then
        echo "ERROR in $KERNEL: make cmp"
        cd -
        return
    fi

    # Benchmark
    make time |& tee -a $FILE$LOGSUFFIX.log
    if [ $? -ne 0 ]; then
        echo "ERROR in $KERNEL: make time"
        cd -
        return
    fi
    cd -
}

# Creates a default makefile for a specific kernel
gen_makefile() {
    KPATH=$1
    KERNEL=$2
    POLYBENCH_UTILITIES=$POLYBENCH_PATH/utilities

    cat > $KPATH/Makefile <<EOF
KERNEL=$KERNEL
EXTRA_FLAGS=-lm

include $POLYBENCH_PATH/config.mk

_PHONY: all

all: $KERNEL ${KERNEL}_ref.out

$KERNEL: $KERNEL.c $KERNEL.h
	\${CC} -o $KERNEL $KERNEL.c \${CFLAGS} -I. -I$POLYBENCH_UTILITIES $POLYBENCH_UTILITIES/polybench.c \${EXTRA_FLAGS}

${KERNEL}_ref.out: $KERNEL.c $KERNEL.h
	gcc -O0 -DPOLYBENCH_DUMP_ARRAYS -DPOLYBENCH_USE_C99_PROTO -o ${KERNEL}_ref $KERNEL.c -I. -I$POLYBENCH_UTILITIES $POLYBENCH_UTILITIES/polybench.c \${EXTRA_FLAGS}
	./${KERNEL}_ref 2> ${KERNEL}_ref.out

ref: ${KERNEL}_ref.out

cmp: ${KERNEL}_ref.out $KERNEL.c $KERNEL.h
	\${CC} -DPOLYBENCH_DUMP_ARRAYS -o ${KERNEL}_dump $KERNEL.c \${CFLAGS} -I. -I$POLYBENCH_UTILITIES $POLYBENCH_UTILITIES/polybench.c \${EXTRA_FLAGS}
	./${KERNEL}_dump 2> ${KERNEL}_dump.out
	$SCRIPTPATH/comparator.py ${KERNEL}_ref.out ${KERNEL}_dump.out

time: $KERNEL.c $KERNEL.h
	\${VERBOSE} \${CC} -o ${KERNEL}_time $KERNEL.c \${CFLAGS} -I. -I$POLYBENCH_UTILITIES $POLYBENCH_UTILITIES/polybench.c \${EXTRA_FLAGS} -DPOLYBENCH_TIME
	$POLYBENCH_UTILITIES/time_benchmark.sh ./${KERNEL}_time

clean:
	@ rm -f $KERNEL ${KERNEL}_time ${KERNEL}_dump ${KERNEL}_dump.out ${KERNEL}_ref
EOF
}

#####################################################################
#####################################################################
# Sample configurations

_gcc() {
    foralltests gen_makefile
    compilerpath=`which gcc`
    cat > $POLYBENCH_PATH/config.mk <<EOF
CC=$compilerpath
CFLAGS=$EXTRAFLAGS -O3 -march=native -mtune=native
EOF
    foralltests runtest "gcc"
}

_clang() {
    foralltests gen_makefile
    compilerpath=`which clang`
    cat > $POLYBENCH_PATH/config.mk <<EOF
CC=$compilerpath
CFLAGS=$EXTRAFLAGS -O3 -march=native -mtune=native
EOF
    foralltests runtest "clang"
}

_polly() {
    foralltests gen_makefile
    compilerpath=`which clang`
    cat > $POLYBENCH_PATH/config.mk <<EOF
CC=$compilerpath
CFLAGS=$EXTRAFLAGS -O3 -march=native -mtune=native -mllvm -polly
EOF
    foralltests runtest "polly"
}

_polly_par() {
    foralltests gen_makefile
    compilerpath=`which clang`
    cat > $POLYBENCH_PATH/config.mk <<EOF
CC=$compilerpath
CFLAGS=$EXTRAFLAGS -O3 -march=native -mtune=native -mllvm -polly -mllvm -polly-parallel -lgomp
EOF
    foralltests runtest "polly-par"
}

_icc() {
    foralltests gen_makefile
    compilerpath=`which icc`
    cat > $POLYBENCH_PATH/config.mk <<EOF
CC=$compilerpath
CFLAGS=$EXTRAFLAGS -O3 -march=native -mtune=native
EOF
    foralltests runtest "icc"
}

# Create a custom makefile for pluto
_gen_pluto_makefile() {
    name=$1
    plutoflags=$2
    compilerflags=$3
    KPATH=$4
    KERNEL=$5
    
    pccpath=`which polycc`
    compilerpath=`which clang`
    
    cat > $KPATH/Makefile <<EOF
KERNEL=$KERNEL
COMPFLAGS=$EXTRAFLAGS -O3 -march=native -mtune=native -ftree-vectorize

_PHONY: all

all: $KERNEL ${KERNEL}_ref.out

$KERNEL: $KERNEL.c $KERNEL.h
	$compilerpath -o $KERNEL $KERNEL.c \${CFLAGS} -I. -I$POLYBENCH_UTILITIES $POLYBENCH_UTILITIES/polybench.c -lm

${KERNEL}.pluto.c: ${KERNEL}.c
	timeout 10m $pccpath ${KERNEL}.c $plutoflags -o \$@

${KERNEL}_ref.out: $KERNEL.c $KERNEL.h
	gcc -O0 -DPOLYBENCH_DUMP_ARRAYS -DPOLYBENCH_USE_C99_PROTO -o ${KERNEL}_ref $KERNEL.c -I. -I$POLYBENCH_UTILITIES $POLYBENCH_UTILITIES/polybench.c \${EXTRA_FLAGS}
	./${KERNEL}_ref 2> ${KERNEL}_ref.out

ref: ${KERNEL}_ref.out

cmp: ${KERNEL}.pluto.c ${KERNEL}_ref.out
	$compilerpath ${KERNEL}.pluto.c $compilerflags \$(COMPFLAGS) -I. -I\$(UTILITY_DIR) \$(UTILITY_DIR)/polybench.c -DPOLYBENCH_DUMP_ARRAYS -o ${KERNEL}_dump -lm
	./${KERNEL}_dump 2> ${KERNEL}_dump.out
	$SCRIPTPATH/comparator.py ${KERNEL}_ref.out ${KERNEL}_dump.out

time: ${KERNEL}.pluto.c
	$compilerpath ${KERNEL}.pluto.c $compilerflags \$(COMPFLAGS) -I. -I\$(UTILITY_DIR) \$(UTILITY_DIR)/polybench.c -DPOLYBENCH_TIME -o ${KERNEL}_time -lm
	\$(UTILITY_DIR)/time_benchmark.sh ./${KERNEL}_time

clean:
	@ rm -f ${KERNEL}.pluto.c ${KERNEL}_dump.out ${KERNEL}_dump ${KERNEL}_ref ${KERNEL}_time
EOF

}

_pluto_clang_base() {
    name=$1
    plutoflags=$2
    compilerflags=$3

    foralltests _gen_pluto_makefile $name $plutoflags $compilerflags
    
    foralltests runtest "pluto-$name"
}
