tar xvf 2.1.4.tar.gz
pushd 2.1.4

CC=${TARGET_TUPLE}-gcc \
    CXX=${TARGET_TUPLE}-g++ \
    ./configure --prefix=/llvmtools \
    --libdir=/llvmtools/lib \
    --zlib-compat

make

make install

ln -sv libz.so.1.3.0.zlib-ng /llvmtools/lib/libz.so.1.3.11

popd
rm -rf 2.1.4
