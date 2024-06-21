tar xvf v0.90.0.tar.gz

pushd v0.90.0

CC=${TARGET_TUPLE}-gcc \
    CXX=${TARGET_TUPLE}-g++ \
    AR=${TARGET_TUPLE}-ar \
    RANLIB=${TARGET_TUPLE}-ranlib \
    make PREFIX="/llvmtools"

# Install to llvmtools
make PREFIX="/llvmtools" install

popd
rm -rf v0.90.0
