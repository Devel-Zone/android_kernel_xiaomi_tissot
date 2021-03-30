#!/bin/bash
#
## By @Sohil876
#

### Vars ###
export KBUILD_BUILD_USER=Sohil876
export KBUILD_BUILD_HOST=CircleCI
KERNEL_DIR=$(pwd)
REPACK_DIR="${KERNEL_DIR}/AnyKernel"
IMAGE="${KERNEL_DIR}/out/arch/arm64/boot/Image.gz-dtb"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
TANGGAL=$(date +"%Y%m%d-%H")
export PATH="$(pwd)/clang/bin:$PATH"
export KBUILD_COMPILER_STRING="$($KERNEL_DIR/clang/bin/clang --version | head -n 1 | perl -pe 's/\((?:http|git).*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//' -e 's/^.*clang/clang/')"
export ARCH=arm64
export SUBARCH=arm64
KERNEL_DEFCONFIG=tissot_defconfig
MAKE="./makeparallel" # Speed up build process

### Start Build ###
BUILD_START_DATE=$(date +"%Y%m%d")
BUILD_START=$(date +"%s")
# Report to tg group/channel
read -r -d '' MESSAGE <<-_EOL_
<strong>Build Initiated!</strong>
<strong>@</strong> $(date "+%I:%M%p") ($(date +"%Z%:z"))
<strong>CPUs :</strong> $(nproc --all) <strong>|</strong> <strong>RAM :</strong> $(awk '/MemTotal/ { printf "%.1f \n", $2/1024/1024 }' /proc/meminfo)GB
<strong>Building :</strong> Murgi+
<strong>Device :</strong> tissot
<strong>Host :</strong> ${KBUILD_BUILD_HOST}
<strong>User :</strong> @${KBUILD_BUILD_USER}
_EOL_
curl -s -X POST -d chat_id="${CHAT_ID}" -d parse_mode=html -d text="${MESSAGE}" -d disable_web_page_preview="true" https://api.telegram.org/bot"${TOKEN}"/sendMessage

# Clone dependencies
echo "Cloning dependencies"
git clone --depth=1 -b 11.0 https://github.com/Sohil876/android_kernel_xiaomi_tissot kernel --single-branch
cd kernel
git clone --depth=1 -b master https://github.com/kdrag0n/proton-clang clang
git clone https://github.com/MASTERGUY/AnyKernel3 -b tissot --depth=1 AnyKernel
echo "Done"

# Start compiling
function compile() {
    make -j$(nproc --all) O=out ARCH=arm64 $KERNEL_DEFCONFIG
    make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      CC=clang \
                      CROSS_COMPILE=aarch64-linux-gnu- \
                      CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
                      NM=llvm-nm \
                      OBJCOPY=llvm-objcopy \
                      OBJDUMP=llvm-objdump \
                      STRIP=llvm-strip

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
}

compile
zipping

# Build Sucessfull!
BUILD_END=$(date +"%s")
DIFF=$((BUILD_END - BUILD_START))
# Send msg to telegram
read -r -d '' MESSAGE <<-_EOL_
<strong>BUILD SUCCESSFULL!</strong>
<strong>Time :</strong> $((DIFF / 60)) minutes and $((DIFF % 60)) seconds
<strong>Date :</strong> $(date +"%Y-%m-%d")
_EOL_
curl -s -X POST -d chat_id=$CHAT_ID -d parse_mode=html -d text="${MESSAGE}" -d disable_web_page_preview="true" https://api.telegram.org/bot"${TOKEN}"/sendMessage
# Send zip file to telegram
curl -F chat_id="${CHAT_ID}" -F document=@"${REPACK_DIR}"/Perf+Kernel.zip -F caption="" https://api.telegram.org/bot"${TOKEN}"/sendDocument
