#!/bin/bash
# Enable built-in Mac OS NTFS driver for writing
# Very UNSAFE!!!

ARCH=`uname -r | cut -d. -f1`
NMOUNT=/sbin/mount_ntfs
NLIBRA=/System/Library/Extensions/ntfs.kext/Contents/MacOS/ntfs

function usage {
    cat <<USAGE
NTFS writing enabler (http://bolknote.ru Nov 2011)

usage: $0 <action>
  <action> - "enable" for enable NTFS write, "disable" otherwise.
USAGE
    exit
}

function ntfsdisable {
    if [ -e "${NMOUNT}_orig" ] && [[ -e "${NLIBRA}_orig" || $ARCH -eq 10 ]]; then
        sudo /bin/mv "${NMOUNT}_orig" "$NMOUNT"
        [ $ARCH -eq 11 ] && sudo mv "${NLIBRA}_orig" "$NLIBRA"

        echo Disabled
    else
        echo "Error: cannot disable NTFS. Already disabled?"
    fi
}

function ntfsenable {
    ntfsenable$ARCH
    echo Enabled
}

function ntfsenable10 {
    echo -n 'Please enter your administrator password. '

    sudo /bin/mv "$NMOUNT" "${NMOUNT}_orig"
    /bin/cat << MNT | sudo /usr/bin/tee "$NMOUNT" >/dev/null
#!/bin/sh
/sbin/mount_ntfs_orig -o rw "\$@"
MNT
    sudo /usr/sbin/chown root:wheel "$NMOUNT"
    sudo /bin/chmod 755 "$NMOUNT"
}

function ntfsenable11 {
    TEMP=`mktemp -d /tmp/ntfs$$.XXXXXX` || (
        echo 'Cannot create temporary directory.'
        exit
    )

    trap "/bin/rm -rf $TEMP" EXIT

    echo -n 'Please wait. Downloading...'

    curl -o "$TEMP/arch.zip" 'http://dl.dropbox.com/u/9349175/datahost-macdaily/NTFS_Enabler.zip' 2>&- 1>&- ||
    curl -o "$TEMP/arch.zip" 'http://ntfs_enabler.chat.ru/NTFS_Enabler.zip' 2>&- 1>&- || (
        echo 'Cannot download NTFS enabler bundle.'
        exit
    )

    echo ' done'

    unzip "$TEMP/arch.zip" -d "$TEMP" 2>&- 1>&-
    [ `md5 "$TEMP/NTFS_Enabler/ntfs"` == a88031b3257379257086af017891f229 ] || (
        echo "Error: invalid checksum NTFS enabler bundle"
        exit
    )

    ntfsenable10

    sudo /bin/mv "$NLIBRA" "${NLIBRA}_orig"
    sudo /bin/mv "$TEMP/NTFS_Enabler/ntfs" "$NLIBRA"
    sudo /usr/sbin/chown root:wheel "$NLIBRA"
    sudo /bin/chmod 755 "$NLIBRA"
}

if [[ $ARCH -lt 10 || $ARCH -gt 11 ]]; then
    echo 'Unknown Mac OS version (Snow Leopard or Lion required).'
    exit
fi

[ "$1" == "" ] && usage

case "$1" in
    enable)
        ntfsenable
        ;;
    disable)
        ntfsdisable
        ;;
esac
