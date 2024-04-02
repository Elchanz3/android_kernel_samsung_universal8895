#!/bin/bash

rm -rf builds
rm -rf out
rm -rf images

# export some things
export CCACHE
export CCACHE_MAXSIZE=10G
export ARCH=arm64
export PROJECT_NAME=greatlte
export LINUX_COMPILED_BY=Chanz22
export COMPILE_HOST=Xeon_builder
mkdir out
mkdir images
mkdir builds
IMAGE_NAME=HyundraKernel

current_dir=$(pwd)

# clean source before build
make mrproper && make clean

# toolchain dir
BUILD_CROSS_COMPILE=$(pwd)/toolchain/aarch64-linux-gnu/bin/aarch64-linux-gnu-
KERNEL_LLVM_BIN=$(pwd)/toolchain/clang-r353983c/bin/clang
CLANG_TRIPLE=$(pwd)/toolchain/aarch64-linux-gnu/bin/aarch64-linux-gnu-
KERNEL_MAKE_ENV="DTC_EXT=$(pwd)/tools/dtc CONFIG_BUILD_ARM64_DT_OVERLAY=y"

# compile kernel
make -j12 -C $(pwd) O=$(pwd)/out $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE CONFIG_SECTION_MISMATCH_WARN_ONLY=y exynos8895-greatlte_defconfig
make -j12 -C $(pwd) O=$(pwd)/out $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE CONFIG_SECTION_MISMATCH_WARN_ONLY=y

# clean up previous images
cd "$current_dir"/AIK
./cleanup.sh
./unpackimg.sh --nosudo

# back to main dir
cd "$current_dir"

# move generated files to temporary directory
cp "$current_dir"/out/arch/arm64/boot/dtb.img "$current_dir"/images/
mv "$current_dir"/images/dtb.img "$current_dir"/images/boot.img-dt
cp "$current_dir"/out/arch/arm64/boot/Image "$current_dir"/images/
mv "$current_dir"/images/Image "$current_dir"/images/boot.img-kernel

# cleanup past files and move new ones
rm "$current_dir"/AIK/split_img/boot.img-kernel
rm "$current_dir"/AIK/split_img/boot.img-dt
mv "$current_dir"/images/boot.img-kernel "$current_dir"/AIK/split_img/boot.img-kernel
mv "$current_dir"/images/boot.img-dt "$current_dir"/AIK/split_img/boot.img-dt

# delete images dir
rm -r "$current_dir"/images

# goto AIK dir and repack boot.img as not sudo
cd "$current_dir"/AIK
./repackimg.sh --nosudo

# goto main dir
cd "$current_dir"

# move generated image to builds dir renamed as lito_kernel
mv "$current_dir"/AIK/image-new.img "$current_dir"/builds/"$IMAGE_NAME".img

# clean out dir for new builds
rm -r "$current_dir"/out

echo done! you can find your image at /builds
