pushd llvm-project-17.0.5.src

export CFLAGS="-fPIC -I/cgnutools/include"
export CXXFLAGS=$CFLAGS

# Set the compiler and linker flags...
export CT="-DCMAKE_C_COMPILER=${TARGET_TUPLE}-clang "
export CT+="-DCMAKE_CXX_COMPILER=${TARGET_TUPLE}-clang++ "
export CT+="-DCMAKE_AR=/cgnutools/bin/llvm-ar "
export CT+="-DCMAKE_NM=/cgnutools/bin/llvm-nm "
export CT+="-DCMAKE_RANLIB=/cgnutools/bin/llvm-ranlib "
export CT+="-DCLANG_DEFAULT_LINKER=/llvmtools/bin/ld.lld "

# Set the tuples & build target ...
export CTG="-DLLVM_DEFAULT_TARGET_TRIPLE=${TARGET_TUPLE} "
export CTG+="-DLLVM_HOST_TRIPLE=${TARGET_TUPLE} "
export CTG+="-DCOMPILER_RT_DEFAULT_TARGET_TRIPLE=${TARGET_TUPLE} "
export CTG+="-DLLVM_TARGET_ARCH=host "
export CTG+="-DLLVM_TARGETS_TO_BUILD=Native;host "

# Set the paths ...
export CP="-DCMAKE_INSTALL_PREFIX=/llvmtools "
export CP+="-DDEFAULT_SYSROOT=/llvmtools "

# Set options for compiler-rt
# + avoid all the optional runtimes:
export CRT="-DCOMPILER_RT_BUILD_SANITIZERS=OFF "
export CRT+="-DCOMPILER_RT_BUILD_XRAY=OFF "
export CRT+="-DCOMPILER_RT_BUILD_LIBFUZZER=OFF "
export CRT+="-DCOMPILER_RT_BUILD_PROFILE=OFF "
export CRT+="-DCOMPILER_RT_BUILD_MEMPROF=OFF "
# + Avoid need for libexecinfo:
export CRT+="-DCOMPILER_RT_BUILD_GWP_ASAN=OFF "
export CRT+="-DCOMPILER_RT_USE_BUILTINS_LIBRARY=ON "
export CRT+="-DCOMPILER_RT_CXX_LIBRARY=libcxx "
export CRT+="-DCOMPILER_RT_USE_LLVM_UNWINDER=ON "

# Set options for clang
# + Set the standard C++ library that clang will use to LLVM's libc++
# + Set compiler-rt as default runtime
export CLG="-DCLANG_DEFAULT_CXX_STDLIB=libc++ "
export CLG+="-DCLANG_DEFAULT_RTLIB=compiler-rt "
export CLG+="-DCLANG_DEFAULT_UNWINDLIB=libunwind "
export CLG+="-DCLANG_DEFAULT_CXX_STDLIB=libc++ "

# Set options for libc++
export CLCPP="-DLIBCXX_HAS_MUSL_LIBC=ON "
export CLCPP+="-DLIBCXX_ENABLE_LOCALIZATION=ON "
export CLCPP+="-DLIBCXX_ENABLE_NEW_DELETE_DEFINITIONS=ON "
export CLCPP+="-DLIBCXX_CXX_ABI=libcxxabi "
export CLCPP+="-DLIBCXX_USE_COMPILER_RT=ON "
export CLCPP+="-DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON "
export CLCPP+="-DLIBCXX_ENABLE_ASSERTIONS=ON "

# Set options fo libc++abi
export CLCPPA="-DLIBCXXABI_USE_LLVM_UNWINDER=ON "
export CLCPPA+="-DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON "
export CLCPPA+="-DLIBCXXABI_USE_COMPILER_RT=ON "

# Set options for libunwind
export CUW="-DLIBUNWIND_INSTALL_HEADERS=ON "
export CUW+="-DLIBUNWIND_USE_COMPILER_RT=ON "

# Set LLVM options
# + Enable Exception handling and Runtime Type Info
export CLLVM="-DLLVM_ENABLE_EH=ON -DLLVM_ENABLE_RTTI=ON "
export CLLVM+="-DLLVM_ENABLE_ZLIB=ON "
export CLLVM+="-DLLVM_INSTALL_UTILS=ON "
export CLLVM+="-DLLVM_BUILD_LLVM_DYLIB=ON "
export CLLVM+="-DLLVM_LINK_LLVM_DYLIB=ON "
export CLLVM+="-DENABLE_LINKER_BUILD_ID=ON "
export CLLVM+="-DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=ON "
export CLLVM+="-DLLVM_ENABLE_LIBCXX=ON "
export CLLVM+="-DLLVM_ENABLE_LLD=ON "
export CLLVM+="-DZLIB_INCLUDE_DIR=/llvmtools/include "
export CLLVM+="-DZLIB_LIBRARY_RELEASE=/llvmtools/lib/libz.so "

# Turn off LLVM options
# + Turn off features host may have
export COFF="-DLLVM_ENABLE_ZSTD=OFF -DLLVM_ENABLE_LIBEDIT=OFF "
export COFF+="-DLLVM_ENABLE_LIBXML2=OFF -DLLVM_ENABLE_LIBEDIT=OFF "
export COFF+="-DLLVM_ENABLE_TERMINFO=OFF -DLLVM_ENABLE_LIBPFM=OFF "
export COFF+="-DLLVM_INCLUDE_BENCHMARKS=OFF "

# Configure source...
cmake -B build -G Ninja -Wno-dev -S llvm \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_ENABLE_PROJECTS="compiler-rt;libunwind;libcxx;libcxxabi;lld;clang" \
    -DCLANG_VENDOR="llvmtools 3.0.0" -DLLD_VENDOR="llvmtools 3.0.0" \
    $CT $CTG $CP $CRT $CLG $CLCPP $CLCPPA $CUW $CLLVM $COFF

# libunwind is now not considered as a project, but as a runtime
cmake -B build -G Ninja -Wno-dev -S llvm \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_ENABLE_RUNTIMES="compiler-rt;libunwind;libcxx;libcxxabi" \
    -DLLVM_ENABLE_PROJECTS="lld;clang" \
    -DCLANG_VENDOR="llvmtools 4.0.0" -DLLD_VENDOR="llvmtools 4.0.0" \
    $CT $CTG $CP $CRT $CLG $CLCPP $CLCPPA $CUW $CLLVM $COFF

# compile
ninja -C build

# install to llvmtools
cmake --install build --strip

# Make LLD the default linker
ln -sv lld /llvmtools/bin/ld

# Many packages use the name cc to call the C compiler. To
# satisfy those packages, create a symlink
ln -sv clang-17 /llvmtools/bin/cc

# Clear variables used in the CMake invocation:
unset CFLAGS CXXFLAGS CT CTG CP CRT CLG CLCPP CLCPPA CUW CLLVM COFF

mkdir -pv /llvmtools/usr
ln -sv $SYSROOT/include /llvmtools/usr/include

rm -rf build dummy.* atomics-test.* cxx11-test.*
unset CT CTG CP CRT CLG CLCPP CLCPPA CUW CLLVM COFF CFLAGS CXXFLAGS

popd