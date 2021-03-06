#! /bin/bash
#
# Free Image
# cross platform image io
# http://freeimage.sourceforge.net
#
# Makefile build system, 
# some Makefiles are out of date so patching/modification may be required

FORMULA_TYPES=( "osx" "osx-clang-libc++" "vs" "win_cb" "ios" "android" )

# define the version
VER=3154 # 3.15.4

# tools for git use
GIT_URL=
GIT_TAG=

# download the source code and unpack it into LIB_NAME
function download() {
	curl -LO http://downloads.sourceforge.net/freeimage/FreeImage"$VER".zip
	unzip -qo FreeImage"$VER".zip
	rm FreeImage"$VER".zip
}

# prepare the build environment, executed inside the lib src dir
function prepare() {
	
	if [ "$TYPE" == "osx" ] ; then

		# patch outdated Makefile.osx, check if patch was appllied first
		if patch -p1 -u -N --dry-run --silent < $FORMULA_DIR/Makefile.osx.patch 2>/dev/null ; then
			patch -p1 -u < $FORMULA_DIR/Makefile.osx.patch
		fi

		# @tgfrerer patch FreeImage source - clang is much less forgiving about
		# type overruns and missing standard header files. 
		# this patch replicates gcc's behaviour
		if patch -p1 -u -N --dry-run --silent < $FORMULA_DIR/freeimage.clang.source.patch 2>/dev/null ; then
			patch -p1 -u -N  < $FORMULA_DIR/freeimage.clang.source.patch
		fi

		# set SDK
		sed -i tmp "s|MACOSX_SDK =.*|MACOSX_SDK = $OSX_SDK_VER|" Makefile.osx
		sed -i tmp "s|MACOSX_MIN_SDK =.*|MACOSX_MIN_SDK = $OSX_MIN_SDK_VER|" Makefile.osx

	elif [ "$TYPE" == "osx-clang-libc++" ] ; then

		# patch outdated Makefile.osx
		if patch -p1 -u -N --dry-run --silent < $FORMULA_DIR/Makefile.osx-clang-libc++.patch 2>/dev/null ; then
			patch -p1 -u < $FORMULA_DIR/Makefile.osx-clang-libc++.patch
		fi
		
		# @tgfrerer patch FreeImage source - clang is much less forgiving about
		# type overruns and missing standard header files. 
		# this patch replicates gcc's behaviour
		if patch -p1 -u -N --dry-run --silent < $FORMULA_DIR/freeimage.clang.source.patch 2>/dev/null ; then
			patch -p1 -u -N  < $FORMULA_DIR/freeimage.clang.source.patch
		fi

		# set SDK
		sed -i tmp "s|MACOSX_SDK =.*|MACOSX_SDK = $OSX_SDK_VER|" Makefile.osx
		sed -i tmp "s|MACOSX_MIN_SDK =.*|MACOSX_MIN_SDK = $OSX_MIN_SDK_VER|" Makefile.osx

	elif [ "$TYPE" == "ios" ] ; then

		# patch outdated Makefile.iphone to build universal sim/armv7/armv7s lib
		if patch -p1 -u -N --dry-run --silent < $FORMULA_DIR/Makefile.iphone.patch 2>/dev/null ; then
			patch -p1 -u < $FORMULA_DIR/Makefile.iphone.patch
		fi

		# @tgfrerer patch FreeImage source - clang is much less forgiving about
		# type overruns and missing standard header files. 
		# this patch replicates gcc's behaviour
		if patch -p1 -u -N --dry-run --silent < $FORMULA_DIR/freeimage.clang.source.patch 2>/dev/null ; then
			patch -p1 -u -N  < $FORMULA_DIR/freeimage.clang.source.patch
		fi

		# set SDKs
		sed -i tmp "s|MACOSX_DEPLOYMENT_TARGET =.*|MACOSX_DEPLOYMENT_TARGET = $OSX_SDK_VER|" Makefile.iphone
		sed -i tmp "s|MACOSX_MIN_SDK =.*|MACOSX_MIN_SDK = $OSX_MIN_SDK_VER|" Makefile.iphone
		sed -i tmp "s|IPHONEOS_SDK =.*|IPHONEOS_SDK = $IOS_SDK_VER|" Makefile.iphone
		sed -i tmp "s|IPHONEOS_MIN_SDK =.*|IPHONEOS_MIN_SDK = $IOS_MIN_SDK_VER|" Makefile.iphone
	fi
}

# executed inside the lib src dir
function build() {
	
	if [ "$TYPE" == "osx" ] ; then
		make -f Makefile.osx

	elif [ "$TYPE" == "osx-clang-libc++" ] ; then
		make -f Makefile.osx
	
	elif [ "$TYPE" == "vs" ] ; then
		echoWarning "TODO: vs build"

	elif [ "$TYPE" == "win_cb" ] ; then
		#make -f Makefile.minigw
		echoWarning "TODO: win_cb build"

	elif [ "$TYPE" == "ios" ] ; then

		# armv7 (+ simulator)
		sed -i tmp "s|ARCH_PHONE =.*|ARCH_PHONE = armv7|" Makefile.iphone
		make -f Makefile.iphone

		# armv7s
		sed -i tmp "s|ARCH_PHONE =.*|ARCH_PHONE = armv7s|" Makefile.iphone
		make -f Makefile.iphone

		# link into universal lib
		lipo -c Dist/libfreeimage-simulator.a Dist/libfreeimage-armv7.a Dist/libfreeimage-armv7s.a -o Dist/libfreeimage-ios.a

	elif [ "$TYPE" == "android" ] ; then
		echoWarning "TODO: android build"
	fi
}

# executed inside the lib src dir, first arg $1 is the dest libs dir root
function copy() {
	
	# headers
	mkdir -p $1/include
	cp -v Dist/*.h $1/include

	# lib
	if [ "$TYPE" == "osx" -o "$TYPE" == "osx-clang-libc++" ] ; then
		mkdir -p $1/lib/$TYPE
		cp -v Dist/libfreeimage.a $1/lib/$TYPE/freeimage.a

	elif [ "$TYPE" == "vs" ] ; then
		mkdir -p $1/lib/$TYPE
		cp -v Dist/FreeImage.lib $1/lib/$TYPE/FreeImage.lib

	elif [ "$TYPE" == "win_cb" ] ; then
		mkdir -p $1/lib/$TYPE
		cp -v Dist/libfreeimage.lib $1/lib/$TYPE/freeimage.lib

	elif [ "$TYPE" == "ios" ] ; then
		mkdir -p $1/lib/$TYPE
		cp -v Dist/libfreeimage-ios.a $1/lib/$TYPE/freeimage.a

	elif [ "$TYPE" == "android" ] ; then
		echoWarning "TODO: copy android lib"
	fi	
}

# executed inside the lib src dir
function clean() {
	
	if [ "$TYPE" == "vs" ] ; then
		echoWarning "TODO: clean vs"

	elif [ "$TYPE" == "android" ] ; then
		echoWarning "TODO: clean android"
		
	else
		make clean
	fi

	# run dedicated clean script
	clean.sh
}
