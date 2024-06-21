tar xvf musl-1.2.4.tar.gz

pushd musl-1.2.4

# Configure with freshly built GCC
./configure \
    CROSS_COMPILE=${TARGET_TUPLE}- \
    --prefix=/ \
    --target=${TARGET_TUPLE}

# Buid and install
make && make DESTDIR=/llvmtools install

# Fix a symlink
rm -v /llvmtools/lib/ld-musl-$(uname -m).so.1
ln -sv libc.so /llvmtools/lib/ld-musl-$(uname -m).so.1

# Create a symlink that can be used to print
# the required shared objects of a program or
# shared object
mkdir /llvmtools/{etc,bin}
ln -sv ../lib/libc.so /llvmtools/bin/ldd

# Configure the dynamic linker
cat >/llvmtools/etc/ld-musl-${MCA}.path <<EOF
/llvmtools/lib
/llvmtools/${TARGET_TUPLE}/lib
/llvmtools/lib/${TARGET_TUPLE}
EOF

# Since llvmtools now has a libc, the cross GCC compiler (located
# in /cgnutools) will need a built-in specs that refers to the freshly
# compile musl dynamic loader /llvmtools/lib/ld-musl-x86_64.so.1.
# We have to adjust this to build up the llvmtools with
# /llvmtools/lib/ld-musl-x86_64.so.1, but keep the cross-gcc in
# cgnutools.
# This will be reached by creating a modified  specs  file in the
# proper location:

export MCGV=$(/cgnutools/bin/gcc  --version | sed 1q | cut -d' ' -f3- )

/cgnutools/bin/${TARGET_TUPLE}-gcc -dumpspecs | sed 's/\/lib\/ld-musl/\/llvmtools\/lib\/ld-musl/g' > /cgnutools/lib/gcc/${TARGET_TUPLE}/$MCGV/specs

popd
rm -rf musl-1.2.4
