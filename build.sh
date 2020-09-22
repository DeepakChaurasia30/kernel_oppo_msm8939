#!/bin/bash
BUILD_START=$(date +"%s")

tcdir=${HOME}/android/TOOLS/GCC

[ -d "out" ] && rm -rf out && mkdir -p out || mkdir -p out
[ -d "venv" ] && rm -rf venv && mkdir -p venv || mkdir -p venv

virtualenv2 venv
source venv/bin/activate

make O=out ARCH=arm64 lineageos_a37f_defconfig

[ -d $tcdir ] && \
echo "ARM64 TC Present." || \
echo "ARM64 TC Not Present. Downloading..." | \
git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 $tcdir/los-4.9-64

[ -d $tcdir ] && \
echo "ARM32 TC Present." || \
echo "ARM32 TC Not Present. Downloading..." | \
git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9 $tcdir/los-4.9-32

PATH="$tcdir/los-4.9-64/bin:$tcdir/los-4.9-32/bin:${PATH}" \
make    O=out \
        ARCH=arm64 \
        CC="ccache $tcdir/los-4.9-64/bin/aarch64-linux-android-gcc" \
        CROSS_COMPILE=aarch64-linux-android- \
        CROSS_COMPILE_ARM32=arm-linux-androideabi- \
        CONFIG_NO_ERROR_ON_MISMATCH=y \
        CONFIG_DEBUG_SECTION_MISMATCH=y \
        -j$(nproc --all) || exit

cc anykernel3/dtbtool.c -o out/arch/arm64/boot/dts/dtbtool
cd out/arch/arm64/boot/dts
./dtbtool -s 2048 -o dt.img
cd ../../../../..

fmt=`date +%d\.%m\.%Y_%H\:%M\:%S`
pre=A37F
cp out/arch/arm64/boot/dts/dt.img anykernel3 && cp out/arch/arm64/boot/Image anykernel3 && cd anykernel3
# cp /path/to/custom/dt.img anykernel3
cp out/arch/arm64/boot/Image anykernel3 && cd anykernel3
zip -r ${pre}_KERNEL_${fmt}.zip . -x 'LICENSE' 'README.md' 'dtbtool.c'
mv *.zip ../out

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
