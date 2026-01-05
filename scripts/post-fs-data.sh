#!/system/bin/sh
# This script will be executed in post-fs-data mode
MODDIR=${0%/*}

# Debloat function: mount empty tmpfs over target directories
debloat_app() {
    local target="$1"
    if [ -d "$target" ]; then
        mount -t tmpfs tmpfs "$target"
    fi
}

if [ -f "/sbin/debloat_list" ]; then
    for pkg in $(cat /sbin/debloat_list); do
        # Search in common app locations
        for base in /system/app /system/priv-app /product/app /product/priv-app /system_ext/app /system_ext/priv-app /vendor/app; do
            for dir in $(find $base -maxdepth 1 -name "*$pkg*" 2>/dev/null); do
                debloat_app "$dir"
            done
        done
    done
fi

# MagiskOnWSA custom logic
if [ -f "$MODDIR/lsp_cust.img" ]; then
    /magiskinit/magiskboot cpio /initrd.img "extract overlay.d/sbin/lsp_cust.img $MODDIR/lsp_cust.img"
    # ... additional custom logic if needed
fi