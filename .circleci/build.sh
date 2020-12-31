#!/bin/bash
echo "Cloning dependencies"
git clone --depth=1 -b 11.0 https://github.com/Sohil876/android_kernel_xiaomi_tissot kernel --single-branch
cd kernel
git clone --depth=1 -b master https://github.com/kdrag0n/proton-clang clang
git clone https://github.com/MASTERGUY/AnyKernel3 -b tissot --depth=1 AnyKernel
echo "Done"
KERNEL_DIR=$(pwd)
REPACK_DIR="${KERNEL_DIR}/AnyKernel"
IMAGE="${KERNEL_DIR}/out/arch/arm64/boot/Image.gz-dtb"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
TANGGAL=$(date +"%Y%m%d-%H")
export PATH="$(pwd)/clang/bin:$PATH"
export KBUILD_COMPILER_STRING="$($KERNEL_DIR/clang/bin/clang --version | head -n 1 | perl -pe 's/\((?:http|git).*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//' -e 's/^.*clang/clang/')"
export ARCH=arm64
export KBUILD_BUILD_USER=Sohil876
export KBUILD_BUILD_HOST=CircleCI
# Compile plox
function compile() {
    make -j$(nproc) O=out ARCH=arm64 tissot_defconfig
    make -j$(nproc) O=out \
                    ARCH=arm64 \
                      CC=clang \
                      CROSS_COMPILE=aarch64-linux-gnu- \
                      CROSS_COMPILE_ARM32=arm-linux-gnueabi- \


    if ! [ -a "$IMAGE" ]; then
        echo "Kernel image not found!"
        exit 1
    fi
    cp $IMAGE $REPACK_DIR

}
# Zipping
function zipping() {
    cd $REPACK_DIR || exit 1
    zip -r9 Perf+Kernel.zip *
    curl https://bashupload.com/Perf+Kernel.zip --data-binary @Perf+Kernel.zip
}
compile
zipping
