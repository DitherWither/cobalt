#!/bin/bash
set -eoxu pipefail
OLD_PATH=$PATH
PATH=/cgnutools/bin:$PATH
cd /stage0

source ./mussel/build.sh
source ./kernel-headers.sh
source ./zlib-ng.sh
source ./libatomic-chimera.sh
source ./llvm/build-pass1.sh
PATH=$OLD_PATH

source ./llvm/build-pass2.sh