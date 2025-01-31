dnf install -y bash llvm bison diffutils findutils \
  gawk clang grep gzip m4 make patch perl python3 \
  python-unversioned-command sed tar texinfo xz git \
  cmake ninja-build

mkdir -v $SYSROOT/src
chmod -v a+wt $SYSROOT/src
wget --input-file=/builder/sources.list --directory-prefix=$SYSROOT/src
cp /builder/sources.md5 $SYSROOT/src/
pushd $SYSROOT/src
md5sum -c sources.md5
popd
chown root:root $LFS/sources/*

mkdir -pv $SYSROOT/{etc,var} $SYSROOT/usr/{bin,lib,sbin}

for i in bin lib sbin; do
  ln -sv usr/$i $SYSROOT/$i
done

case $(uname -m) in
x86_64) mkdir -pv $SYSROOT/lib64 ;;
esac

mkdir -pv $SYSROOT/{cgnutools,llvmtools}

# Create user
groupadd builder
useradd -s /bin/bash -g builder -m -k /dev/null builder
cp .bash_profile .bashrc /home/builder/

chown -v builder $SYSROOT/{usr{,/*},lib,var,etc,bin,sbin,tools}
case $(uname -m) in
x86_64) chown -v builder $SYSROOT/lib64 ;;
esac

# Create symlinks for build
for i in llvmtools cgnutools; do
  ln -sv $SYSROOT/$i /
done
