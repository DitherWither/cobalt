tar xvf llvm-project-17.0.5.src.tar.xz # The source tree will be reused multiple times, won't be removed

pushd llvm-project-17.0.5.src

# Apply patches
patch -Np1 -i chimera-patches/0001-llvm-always-set-a-larger-stack-size-explicitly.patch
patch -Np1 -i chimera-patches/0002-llvm-musl-workarounds.patch
patch -Np1 -i chimera-patches/0003-llvm-fix-some-MF_EXEC-related-test-failures-on-aarch.patch
patch -Np1 -i chimera-patches/0004-llvm-disable-dependency-on-libexecinfo-everywhere.patch
patch -Np1 -i chimera-patches/0005-compiler-rt-ppc-sanitizer-fixes.patch
patch -Np1 -i chimera-patches/0006-compiler-rt-default-to-libc-for-sanitizers.patch
patch -Np1 -i chimera-patches/0007-compiler-rt-build-crt-in-runtimes-build.patch
patch -Np1 -i chimera-patches/0008-compiler-rt-lsan-basic-musl-fixes-on-various-archs.patch
patch -Np1 -i chimera-patches/0009-compiler-rt-HACK-hwasan-build-on-x86_64.patch
patch -Np1 -i chimera-patches/0010-compiler-rt-libcxx-abi-libunwind-HACK-force-fno-lto.patch
patch -Np1 -i chimera-patches/0011-compiler-rt-HACK-always-compile-in-gcc_personality_v.patch
patch -Np1 -i chimera-patches/0012-libc-libc-abi-libunwind-disable-multiarch-locations.patch
patch -Np1 -i chimera-patches/0013-libc-musl-locale-workarounds.patch
patch -Np1 -i chimera-patches/0014-clang-disable-multiarch-layout-on-musl.patch
patch -Np1 -i chimera-patches/0015-clang-drop-incorrect-warning-about-vector-equality-r.patch
patch -Np1 -i chimera-patches/0016-clang-add-fortify-include-paths-for-musl-triplets-en.patch
patch -Np1 -i chimera-patches/0017-clang-use-as-needed-by-default.patch
patch -Np1 -i chimera-patches/0018-clang-switch-on-default-now-relro.patch
patch -Np1 -i chimera-patches/0019-clang-default-to-fno-semantic-interposition.patch
patch -Np1 -i chimera-patches/0020-clang-implicitly-link-to-libatomic-on-linux-targets.patch
patch -Np1 -i chimera-patches/0021-clang-use-strong-stack-protector-by-default.patch
patch -Np1 -i chimera-patches/0022-clang-fix-unwind-chain-inclusion.patch
patch -Np1 -i chimera-patches/0023-Add-accessors-for-MCSubtargetInfo-CPU-and-Feature-ta.patch
patch -Np1 -i chimera-patches/0024-clang-link-libcxxabi-on-linux-when-using-libc.patch
patch -Np1 -i chimera-patches/0025-Get-rid-of-spurious-trailing-space-in-__clang_versio.patch
patch -Np1 -i chimera-patches/ifunc-fail-if-not-supported.patch


# Since, libunwind is for cgnutools, modify the cross-gcc specs to set the dynamic
# loader as  /cgnutools/lib/ld-musl-${MCA}.so.1
export MCGV=$(/cgnutools/bin/gcc  --version | sed 1q | cut -d' ' -f3- )
/cgnutools/bin/${TARGET_TUPLE}-gcc -dumpspecs | sed 's/\/lib\/ld-musl/\/cgnutools\/lib\/ld-musl/g' > /cgnutools/lib/gcc/${TARGET_TUPLE}/$MCGV/specs

export CFLAGS="-fPIC "
export CXXFLAGS=$CFLAGS

# Set the compiler and linker flags...
export LINKERFLAGS="-Wl,-rpath=/cgnutools/lib "
export  CT="-DCMAKE_C_COMPILER=${TARGET_TUPLE}-gcc "
export CT+="-DCMAKE_CXX_COMPILER=${TARGET_TUPLE}-g++ "
export CT+="-DCMAKE_AR=/cgnutools/bin/${TARGET_TUPLE}-ar "
export CT+="-DCMAKE_NM=/cgnutools/bin/${TARGET_TUPLE}-nm "
export CT+="-DCMAKE_RANLIB=/cgnutools/bin/${TARGET_TUPLE}-ranlib "

# Configure source in a build directory
cmake -G Ninja -B build -S libunwind -Wno-dev \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/cgnutools \
      -DCMAKE_INSTALL_OLDINCLUDEDIR=/cgnutools/include \
      -DCMAKE_EXE_LINKER_FLAGS="${LINKERFLAGS}" \
      -DCMAKE_SHARED_LINKER_FLAGS="${LINKERFLAGS}" \
      -DLIBUNWIND_INSTALL_HEADERS=ON \
      -DLIBUNWIND_ENABLE_CROSS_UNWINDING=ON \
      -DLIBUNWIND_ENABLE_STATIC=OFF \
      -DLIBUNWIND_HIDE_SYMBOLS=ON $CT

# compile
ninja -C build unwind

# install to cgnutools
ninja -C build install-unwind-stripped

# Built libunwind.so will have unresolved symbols:
# $ ldd /cgnutools/lib/libunwind.so.1.0
# 	ldd (0x7fa2a96fb000)
# 	libc.so => ldd (0x7fa2a96fb000
# 	libgcc_s.so.1 => /cgnutools/lib/libgcc_s.so.1 (0x7fa2a96bf000)
# Error relocating build/lib/libunwind.so.1.0: __unw_getcontext: symbol not found
# Error relocating build/lib/libunwind.so.1.0: __libunwind_Registers_x86_64_jumpto: symbol not found
# 
# This will not be a problem

# Remove build directory & clear flags
# Do not remove source tree as it will be used later
rm -rf build
unset CXXFLAGS CFLAGS CT LINKERFLAGS

# Set the cross-gcc spec to set the dynamic loader as
# /llvmtools/lib/ld-musl-${MCA}.so.1
/cgnutools/bin/${TARGET_TUPLE}-gcc -dumpspecs | sed 's/\/lib\/ld-musl/\/llvmtools\/lib\/ld-musl/g' > /cgnutools/lib/gcc/${TARGET_TUPLE}/$MCGV/specs

patch -Np1 -i cmlfs-patches/modify-toolchain-dynamic-loader.llvmtools.patch 
patch -Np1 -i cmlfs-patches/modify-test-dynamic-loader.llvmtools.patch 
# Force clang to use dynamic linux loader in /llvmtools
patch -Np1 -i ../patches/llvm-cmlfs/modify-toolchain-dynamic-loader.llvmtools.patch 
patch -Np1 -i ../patches/llvm-cmlfs/modify-test-dynamic-loader.llvmtools.patch 

# Built llvm-tblgen will need libstdc++.so.6 & libgcc_s.so.1.
# Set the rpath
export  CFLAGS='-fPIC -I/cgnutools/include -Wl,-rpath=/cgnutools/lib '
export CXXFLAGS=$CFLAGS

# Set the compiler and linker flags...
export  CT="-DCMAKE_C_COMPILER=${TARGET_TUPLE}-gcc "
export CT+="-DCMAKE_CXX_COMPILER=${TARGET_TUPLE}-g++ "
export CT+="-DCMAKE_AR=/cgnutools/bin/${TARGET_TUPLE}-ar "
export CT+="-DCMAKE_NM=/cgnutools/bin/${TARGET_TUPLE}-nm "
export CT+="-DCMAKE_RANLIB=/cgnutools/bin/${TARGET_TUPLE}-ranlib "
export CT+="-DCLANG_DEFAULT_LINKER=/cgnutools/bin/ld.lld "
export CT+="-DGNU_LD_EXECUTABLE=/cgnutools/bin/${CMLFS_TARGET}-ld.bfd "

# Set the tuples & build target ...
export  CTG="-DLLVM_DEFAULT_TARGET_TRIPLE=${TARGET_TUPLE} "
export CTG+="-DLLVM_HOST_TRIPLE=${TARGET_TUPLE} "
export CTG+="-DCOMPILER_RT_DEFAULT_TARGET_TRIPLE=${TARGET_TUPLE} "
export CTG+="-DLLVM_TARGETS_TO_BUILD=host "
export CTG+="-DLLVM_TARGET_ARCH=host "
export CTG+="-DLLVM_TARGETS_TO_BUILD=Native;host "

# Set the paths ...
export  CP="-DCMAKE_INSTALL_PREFIX=/cgnutools "
export CP+="-DDEFAULT_SYSROOT=/llvmtools "

# Set options for compiler-rt
# + avoid all the optional runtimes:
export  CRT="-DCOMPILER_RT_BUILD_SANITIZERS=OFF "
export CRT+="-DCOMPILER_RT_BUILD_XRAY=OFF "
export CRT+="-DCOMPILER_RT_BUILD_LIBFUZZER=OFF "
export CRT+="-DCOMPILER_RT_BUILD_PROFILE=OFF "
export CRT+="-DCOMPILER_RT_BUILD_MEMPROF=OFF "
# + Avoid need for libexecinfo:
export CRT+="-DCOMPILER_RT_BUILD_GWP_ASAN=OFF "
export CRT+="-DCOMPILER_RT_USE_LLVM_UNWINDER=ON "
export CRT+="-DCOMPILER_RT_USE_BUILTINS_LIBRARY=OFF "

# Set options for clang
# + Set the standard C++ library that clang will use to LLVM's libc++
# + Set compiler-rt as default runtime
export  CLG="-DCLANG_DEFAULT_CXX_STDLIB=libc++ "
export CLG+="-DCLANG_DEFAULT_RTLIB=compiler-rt "
export CLG+="-DCLANG_DEFAULT_UNWINDLIB=libunwind "
export CLG+="-DCLANG_DEFAULT_CXX_STDLIB=libc++ "

# Set options for libc++
export  CLCPP="-DLIBCXX_HAS_MUSL_LIBC=ON "
export CLCPP+="-DLIBCXX_ENABLE_LOCALIZATION=ON "
export CLCPP+="-DLIBCXX_ENABLE_NEW_DELETE_DEFINITIONS=ON "
export CLCPP+="-DLIBCXX_CXX_ABI=libcxxabi "
export CLCPP+="-DLIBCXX_USE_COMPILER_RT=OFF "
export CLCPP+="-DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON "
export CLCPP+="-DLIBCXX_ENABLE_ASSERTIONS=ON "

# Set options fo libc++abi
export  CLCPPA="-DLIBCXXABI_USE_LLVM_UNWINDER=ON "
export CLCPPA+="-DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON "
export CLCPPA+="-DLIBCXXABI_USE_COMPILER_RT=OFF "

# Set options for libunwind
export  CUW="-DLIBUNWIND_INSTALL_HEADERS=ON "
#export CUW+="-DLIBUNWIND_USE_COMPILER_RT=ON "

# Set LLVM options
# + Enable Exception handling and Runtime Type Info
export  CLLVM="-DLLVM_ENABLE_EH=ON -DLLVM_ENABLE_RTTI=ON "
export CLLVM+="-DLLVM_ENABLE_ZLIB=ON "
export CLLVM+="-DLLVM_INSTALL_UTILS=ON "
export CLLVM+="-DLLVM_BUILD_LLVM_DYLIB=ON "
export CLLVM+="-DLLVM_LINK_LLVM_DYLIB=ON "
export CLLVM+="-DENABLE_LINKER_BUILD_ID=ON "
export CLLVM+="-DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=ON "
#export CLLVM+="-DLLVM_ENABLE_LIBCXX=ON "
#export CLLVM+="-DLLVM_ENABLE_LLD=ON "

# Turn off LLVM options
# + Turn off features host may have
export  COFF="-DLLVM_ENABLE_ZSTD=OFF -DLLVM_ENABLE_LIBEDIT=OFF "
export COFF+="-DLLVM_ENABLE_LIBXML2=OFF -DLLVM_ENABLE_LIBEDIT=OFF "
export COFF+="-DLLVM_ENABLE_TERMINFO=OFF -DLLVM_ENABLE_LIBPFM=OFF "

# libunwind is now not considered as a project, but as a runtime
cmake -B build -G Ninja -Wno-dev -S llvm \
      -DCMAKE_BUILD_TYPE=Release \
      -DLLVM_ENABLE_RUNTIMES="compiler-rt;libunwind;libcxx;libcxxabi" \
      -DLLVM_ENABLE_PROJECTS="clang;lld" \
      -DCLANG_VENDOR="cgnutools 4.0.0" -DLLD_VENDOR="cgnutools 4.0.0" \
      $CT $CTG $CP $CRT $CLG $CLCPP $CLCPPA $CUW $CLLVM $COFF

# compile
ninja -C build

# install to cgnutools
cmake --install build --strip

# Make LLD the default linker
rm -v      /cgnutools/bin/ld
ln -sv lld /cgnutools/bin/ld


# Disable cross-gcc ... will use stage0 clang instead
mv -v /cgnutools/lib/gcc{,-disabled}

# Configure stage0 clang
cat > /cgnutools/bin/${TARGET_TUPLE}.cfg <<EOF
-L/cgnutools/lib
-nostdinc++
-I/cgnutools/include/c++/v1
-I/llvmtools/include
EOF

ln -sv clang-17 /cgnutools/bin/${TARGET_TUPLE}-clang
ln -sv clang-17 /cgnutools/bin/${TARGET_TUPLE}-clang++

# Binaries built by stage0 clang will look for libc++ .
# Add a search path for the dynamic linker/loader in llvmtools:
echo "/cgnutools/lib" >> /llvmtools/etc/ld-musl-${MCA}.path

rm -rf build dummy.* atomics-test.* cxx11-test.*
unset CT CTG CP CRT CLG CLCPP CLCPPA CUW CLLVM COFF CFLAGS CXXFLAGS LINKERFLAGS

popd