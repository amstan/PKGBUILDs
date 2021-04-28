#!/bin/bash

image=$1
arch=$2
compression=$3
read -a dtb_list

cat <<-ITS_HEADER_END
/dts-v1/;

/ {
    description = "Chrome OS kernel image with one or more FDT blobs";
    images {
        kernel-archlinuxarm {
            description = "kernel";
            data = /incbin/("${image}");
            type = "kernel_noload";
            arch = "${arch}";
            os = "linux";
            compression = "${compression}";
            load = <0>;
            entry = <0>;
        };

ITS_HEADER_END

for dtb in ${dtb_list[@]}; do
	cat <<-FDT_END
	        $(basename ${dtb}) {
	            description = "$(basename ${dtb})";
	            data = /incbin/("${dtb}");
	            type = "flat_dt";
	            arch = "${arch}";
	            compression = "${compression}";
	            hash {
	                algo = "sha1";
	            };
	        };
	FDT_END
done

cat <<-ITS_MIDDLE_END
    };

    configurations {
ITS_MIDDLE_END

for dtb in "${dtb_list[@]}"; do
	compat_line=""
	dtb_uncompressed=$(echo ${dtb} | sed "s/\(\.dtb\).*/\1/g")
	for compat in $(fdtget "${dtb_uncompressed}" / compatible); do
		compat_line+="\"${compat}\","
	done
	cat <<-ITS_CONF_END
	        $(basename ${dtb} | sed "s/\(\.dtb\).*//g") {
	            kernel = "kernel-archlinuxarm";
	            fdt = "$(basename ${dtb})";
	            compatible = ${compat_line%,};
	        };
	ITS_CONF_END
done

cat <<-ITS_FOOTER_END
    };
};
ITS_FOOTER_END
