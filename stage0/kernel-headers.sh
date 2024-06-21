tar xvf linux-6.6.2.tar.xz
pushd linux-6.6.2

LLVM=1 LLVM_IAS=1 make mrproper
LLVM=1 LLVM_IAS=1 make headers

find usr/include \( -name .install -o -name ..install.cmd \) -exec rm -vf {} \;
mkdir -pv /llvmtools/include
cp -rv usr/include/* /llvmtools/include/
rm -v /llvmtools/include/Makefile

popd
rm -rf linux-6.6.2
