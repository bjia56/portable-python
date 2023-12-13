#!/bin/bash

set -e

libpython=$1
python=$2
libfolder=$(realpath $(dirname $libpython))
rpath_prefix="\$ORIGIN/../lib"

library_allowlist=$(cat <<-END
libexpat.so
libz.so
libbz2.so
liblzma.so
libcrypto.so
libssl.so
libffi.so
libsqlite3.so
libreadline.so
libhistory.so
libpanel.so
libmenu.so
libform.so
libncurses.so
libncursesw.so
libcurses.so
libtinfo.so
libuuid.so
libgdbm.so
libgdbm_compat.so
libtk.so
libXft.so
libfontconfig.so
libX11.so
libXss.so
libfreetype.so
libXrender.so
libxcb.so
libXext.so
libpng12.so
libXau.so
libXdmcp.so
libtcl8.6.so
libtk8.6.so
libSM.so
libICE.so
libbsd.so
libpng16.so
libmpdec.so
END
)

library_blocklist=$(dpkg -L libc6 | grep lib | grep \.so)

patch_object () {
    local deps=$(ldd $libpython | awk '/=>/{print $(NF-1)}' | grep /)

    if [ -z "$deps" ]; then
        return
    fi

    local add_needed=()
    local replace_needed=()
    while read line; do
        local libsource=$line
        local libname=$(basename $libsource)

        local good=0
        while read libpatch; do
            if [[ "$libname" == "$libpatch"* ]]; then
                good=1
                break
            fi
        done <<< "$library_allowlist"

        while read lib; do
            if [[ "$libname"* == "$lib" ]]; then
                if [[ "$good" == "1" ]]; then
                    echo "WARNING: $libname is not allowed, will not proceed with patching"
                fi
                good=0
                break
            fi
        done <<< "$library_blocklist"

        if [[ "$good" == "0" ]]; then
            continue
        fi

        if [[ $(echo ${add_needed[@]} | fgrep -w $libname) ]]; then
            echo "$libname already added"
            continue
        fi

        cp $libsource $libfolder/$libname
        add_needed+=(--add-needed $libname)
        replace_needed+=(--replace-needed $libname $rpath_prefix/$libname)
    done <<< "$deps"

    patchelf "${add_needed[@]}" $python
    patchelf "${replace_needed[@]}" $python
}

patch_object
