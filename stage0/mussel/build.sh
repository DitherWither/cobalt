#!/bin/bash
# 
SRC=/stage0/mussel/

git clone https://github.com/firasuke/mussel $SYSROOT/src/mussel

pushd $SYSROOT/src/mussel

# Custom patches were updated against
# commit: dc8a99c95b72431eb2c6ecdde7ebb0eefef12560
git checkout dc8a99c95b72431eb2c6ecdde7ebb0eefef12560

# Check host for requirements
./check.sh

# Patch to Modify ./mussel.sh to change these:
# MPREFIX="/cgnutools"
# MSYSROOT="/cgnutools"
patch -Np1 -i "$SRC/patches/change-variables.patch"

# Modify ./mussel to add a vendor in target tuple
# Set vendor as 'pc'. If omitted, clang defaults to 'unknown'
patch -Np1 -i "$SRC/patches/add-vendor.patch"

# If host uses clang instead of GCC,
# Do not build ISL:
patch -Np1 -i "$SRC/patches/dont-build-isl.patch"

# Apply patch to add compatibility links for cross AR and RANLIB
patch -Np1 -i "$SRC/patches/add-missing-symlinks.patch"

# If compiling with LLVM, prefix commands with LLVM=1
# to build kernel headers
patch -Np1 -i "$SRC/patches/LLVM_for_headers.patch"

# Build toolchain. Amend PATH to include /cgnutools/bin
# o Ommit -p if not building in parallel to use all
#   the host's CPU cores
sudo CC=gcc CXX=g++ ./mussel.sh x86_64 -l -o -k -p

# Make sure cgnutools is owned by builder
sudo chown -vR builder $SYSROOT/cgnutools

# Unify  headers and libraries:
mv -v /cgnutools/usr/lib/* /cgnutools/lib/
mv -v /cgnutools/usr/include/* /cgnutools/include/
rm -rfv /cgnutools/usr/{include,lib}
ln -sv ../lib /cgnutools/usr/lib
ln -sv ../include /cgnutools/usr/include

# Remove unneeded documentation
rm -rf /cgnutools/share/{man,info}

# The new cross compiler has built-in specs which refer to the musl
# dynamic loader  /lib/ld-musl-x86_64.so.1... which will not exist on
# glibc hosts. We have to adjust this to build up the llvmtools with
# /llvmtools/lib/ld-musl-x86_64.so.1, but keep the cross-gcc in
# cgnutools.
# This will be reached by creating a modified  specs  file in the
# proper location:
export MCGV=$(/cgnutools/bin/${TARGET_TUPLE}-gcc --version | sed 1q | cut -d' ' -f3-)
/cgnutools/bin/${TARGET_TUPLE}-gcc -dumpspecs | sed 's/\/lib\/ld-musl/\/llvmtools\/lib\/ld-musl/g' >/cgnutools/lib/gcc/${TARGET_TUPLE}/$MCGV/specs

# For future reference, copy log from mussel
cp -v log.txt /cgnutools/mussel_build.log

popd
rm -rf $SYSROOT/src/musl
