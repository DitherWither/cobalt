FROM fedora:40
LABEL description="Cobalt Builder"
LABEL version="0.1"
LABEL maintainer="hi@vardhanpatil.com"

RUN dnf update -y

ENV SYSROOT="/sysroot"
ENV LC_ALL=POSIX
ENV LFS_TGT=x86_64-lfs-linux-gnu
ENV PATH=/tools/bin:/bin:/usr/bin:/sbin:/usr/sbin
ENV CC=clang
ENV CXX=clang++
ENV MAKEFLAGS="-j8"
ENV CFLAGS="-O2 -pipe"

COPY stage0 /stage0
RUN /stage0/build.sh
RUN rm -rf /stage0

COPY . /src
WORKDIR /src

USER builder