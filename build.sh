#!/bin/bash
# kernel build script by Tkkg1994 v0.6 (optimized from apq8084 kernel source)

export MODEL=dreamlte
export VARIANT=eur
export ARCH=arm64
export SUBARCH=arm64
#export BUILD_CROSS_COMPILE=/media/Lollipop/Oreo/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-
export BUILD_CROSS_COMPILE=/media/Lollipop/Oreo/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-gnu-gcc-6.4.1/bin/aarch64-linux-gnu-
#export BUILD_CROSS_COMPILE=/media/Lollipop/Oreo/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-gnu-linaro-6.4/bin/aarch64-linux-gnu-
export BUILD_JOB_NUMBER=`grep processor /proc/cpuinfo|wc -l`

RDIR=$(pwd)
OUTDIR=$RDIR/arch/$ARCH/boot
DTSDIR=$RDIR/arch/$ARCH/boot/dts/exynos
DTBDIR=$OUTDIR/dtb
DTCTOOL=$RDIR/scripts/dtc/dtc
INCDIR=$RDIR/include

PAGE_SIZE=2048
DTB_PADDING=0

case $MODEL in
dreamlte)
	case $VARIANT in
	can|duos|eur|xx)
		KERNEL_DEFCONFIG=exynos8895-dreamlte_defconfig
		;;
	*)
		echo "Unknown variant: $VARIANT"
		exit 1
		;;
	esac
;;
dream2lte)
	case $VARIANT in
	can|duos|eur|xx)
		KERNEL_DEFCONFIG=exynos8895-dream2lte_defconfig
		;;
	*)
		echo "Unknown variant: $VARIANT"
		exit 1
		;;
	esac
;;
*)
	echo "Unknown device: $MODEL"
	exit 1
	;;
esac

FUNC_CLEAN_DTB()
{
	if ! [ -d $RDIR/arch/$ARCH/boot/dts ] ; then
		echo "no directory : "$RDIR/arch/$ARCH/boot/dts""
	else
		echo "rm files in : "$RDIR/arch/$ARCH/boot/dts/*.dtb""
		rm $RDIR/arch/$ARCH/boot/dts/*.dtb
		rm $RDIR/arch/$ARCH/boot/dtb/*.dtb
		rm $RDIR/arch/$ARCH/boot/boot.img-dtb
		rm $RDIR/arch/$ARCH/boot/boot.img-zImage
	fi
}

FUNC_BUILD_DTIMAGE_TARGET()
{
	[ -f "$DTCTOOL" ] || {
		echo "You need to run ./build.sh first!"
		exit 1
	}

	case $MODEL in
	dreamlte)
		case $VARIANT in
		can|duos|eur|xx)
			DTSFILES="exynos8895-dreamlte_eur_open_00 exynos8895-dreamlte_eur_open_01
					exynos8895-dreamlte_eur_open_02 exynos8895-dreamlte_eur_open_03
					exynos8895-dreamlte_eur_open_04 exynos8895-dreamlte_eur_open_05
					exynos8895-dreamlte_eur_open_07 exynos8895-dreamlte_eur_open_08
					exynos8895-dreamlte_eur_open_09 exynos8895-dreamlte_eur_open_10"
			;;
		*)
			echo "Unknown variant: $VARIANT"
			exit 1
			;;
		esac
	;;
	dream2lte)
		case $VARIANT in
		can|duos|eur|xx)
			DTSFILES="exynos8895-dream2lte_eur_open_03 exynos8895-dream2lte_eur_open_04
					exynos8895-dream2lte_eur_open_05 exynos8895-dream2lte_eur_open_06
					exynos8895-dream2lte_eur_open_07 exynos8895-dream2lte_eur_open_08
					exynos8895-dream2lte_eur_open_09 exynos8895-dream2lte_eur_open_10"
			;;
		*)
			echo "Unknown variant: $VARIANT"
			exit 1
			;;
		esac
	;;
	*)
		echo "Unknown device: $MODEL"
		exit 1
		;;
	esac

	mkdir -p $OUTDIR $DTBDIR

	cd $DTBDIR || {
		echo "Unable to cd to $DTBDIR!"
		exit 1
	}

	rm -f ./*

	echo "Processing dts files..."

	for dts in $DTSFILES; do
		echo "=> Processing: ${dts}.dts"
		${CROSS_COMPILE}cpp -nostdinc -undef -x assembler-with-cpp -I "$INCDIR" "$DTSDIR/${dts}.dts" > "${dts}.dts"
		echo "=> Generating: ${dts}.dtb"
		$DTCTOOL -p $DTB_PADDING -i "$DTSDIR" -O dtb -o "${dts}.dtb" "${dts}.dts"
	done

	echo "Generating dtb.img..."
	$RDIR/scripts/dtbTool/dtbTool -o "$OUTDIR/dtb.img" -d "$DTBDIR/" -s $PAGE_SIZE

	echo "Done."
}

FUNC_BUILD_KERNEL()
{
	echo ""
        echo "=============================================="
        echo "START : FUNC_BUILD_KERNEL"
        echo "=============================================="
        echo ""
        echo "build common config="$KERNEL_DEFCONFIG ""
        echo "build model config="$MODEL ""

	FUNC_CLEAN_DTB

	make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
			CROSS_COMPILE=$BUILD_CROSS_COMPILE \
			$KERNEL_DEFCONFIG || exit -1

	make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
			CROSS_COMPILE=$BUILD_CROSS_COMPILE || exit -1

	FUNC_BUILD_DTIMAGE_TARGET
	
	echo ""
	echo "================================="
	echo "END   : FUNC_BUILD_KERNEL"
	echo "================================="
	echo ""
}

FUNC_BUILD_RAMDISK()
{
	mv $RDIR/arch/$ARCH/boot/Image $RDIR/arch/$ARCH/boot/boot.img-zImage
	mv $RDIR/arch/$ARCH/boot/dtb.img $RDIR/arch/$ARCH/boot/boot.img-dtb

	case $MODEL in
	dreamlte)
		case $VARIANT in
		can|duos|eur|xx)
			rm -f $RDIR/ramdisk/SM-G950F/split_img/boot.img-zImage
			rm -f $RDIR/ramdisk/SM-G950F/split_img/boot.img-dtb
			mv -f $RDIR/arch/$ARCH/boot/boot.img-zImage $RDIR/ramdisk/SM-G950F/split_img/boot.img-zImage
			mv -f $RDIR/arch/$ARCH/boot/boot.img-dtb $RDIR/ramdisk/SM-G950F/split_img/boot.img-dtb
			cd $RDIR/ramdisk/SM-G950F
			./repackimg.sh --nosudo
			echo SEANDROIDENFORCE >> image-new.img
			;;
		*)
			echo "Unknown variant: $VARIANT"
			exit 1
			;;
		esac
	;;
	dream2lte)
		case $VARIANT in
		can|duos|eur|xx)
			rm -f $RDIR/ramdisk/SM-G955F/split_img/boot.img-zImage
			rm -f $RDIR/ramdisk/SM-G955F/split_img/boot.img-dtb
			mv -f $RDIR/arch/$ARCH/boot/boot.img-zImage $RDIR/ramdisk/SM-G955F/split_img/boot.img-zImage
			mv -f $RDIR/arch/$ARCH/boot/boot.img-dtb $RDIR/ramdisk/SM-G955F/split_img/boot.img-dtb
			cd $RDIR/ramdisk/SM-G955F
			./repackimg.sh --nosudo
			echo SEANDROIDENFORCE >> image-new.img
			;;
		*)
			echo "Unknown variant: $VARIANT"
			exit 1
			;;
		esac
	;;
	*)
		echo "Unknown device: $MODEL"
		exit 1
		;;
	esac
}

FUNC_BUILD_ZIP()
{
	cd $RDIR/build
	rm $MODEL-$VARIANT.img
	case $MODEL in
	dreamlte)
		case $VARIANT in
		can|duos|eur|xx)
			mv -f $RDIR/ramdisk/SM-G950F/image-new.img $RDIR/build/$MODEL-$VARIANT.img
			;;
		*)
			echo "Unknown variant: $VARIANT"
			exit 1
			;;
		esac
	;;
	dream2lte)
		case $VARIANT in
		can|duos|eur|xx)
			mv -f $RDIR/ramdisk/SM-G955F/image-new.img $RDIR/build/$MODEL-$VARIANT.img
			;;
		*)
			echo "Unknown variant: $VARIANT"
			exit 1
			;;
		esac
	;;
	*)
		echo "Unknown device: $MODEL"
		exit 1
		;;
	esac
}

# MAIN FUNCTION
rm -rf ./build.log
(
	START_TIME=`date +%s`

	FUNC_BUILD_KERNEL
	FUNC_BUILD_RAMDISK
	FUNC_BUILD_ZIP

	END_TIME=`date +%s`
	
	let "ELAPSED_TIME=$END_TIME-$START_TIME"
	echo "Total compile time was $ELAPSED_TIME seconds"

) 2>&1	 | tee -a ./build.log
