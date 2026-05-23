# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop unpacker xdg

DESCRIPTION="China Mobile Cloud Drive (中国移动云盘) - cloud storage client"
HOMEPAGE="https://yun.139.com/"
SRC_URI="https://yun.mcloud.139.com/mCloudPc/uosV111/com.cmic.mcloud_${PV}_amd64.deb"

S="${WORKDIR}"

LICENSE="mCloud-EULA"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="strip mirror bindist"

# Bundled Qt5 5.13.2 links to ICU 63 (e.g. u_strToUpper_63) which is incompatible
# with the system's ICU 78. We remove the bundled Qt5 libs and use system Qt5 instead.
# Qt5 maintains ABI compatibility across minor versions (same SONAME .5).
RDEPEND="
	dev-qt/qtconcurrent:5
	dev-qt/qtcore:5
	dev-qt/qtdbus:5
	dev-qt/qtgui:5
	dev-qt/qtmultimedia:5
	dev-qt/qtnetwork:5
	dev-qt/qtprintsupport:5
	dev-qt/qtsql:5
	dev-qt/qtwidgets:5
	dev-qt/qtxml:5
	x11-libs/libX11
	x11-libs/libxcb
"
BDEPEND="dev-util/patchelf"

QA_PREBUILT="opt/apps/com.cmic.mcloud/*"

src_prepare() {
	default

	# Remove bundled Qt5 libraries - they link to ICU 63 which is
	# incompatible with the system's ICU 78 (hardcoded symbol suffixes
	# like u_strToUpper_63 cannot be resolved by ICU 78).
	# System Qt5 5.15.x is ABI compatible (same SONAME .5).
	rm -f "${S}"/opt/apps/com.cmic.mcloud/files/processes/libQt5*.so* || die

	# Fix RUNPATH on remaining bundled .so files:
	# - libcommon.so: RUNPATH missing $ORIGIN, only has build-machine path
	# - libboost_json.so.1.87.0: RUNPATH is empty, cannot find libboost_container.so
	# - Other .so files: ensure $ORIGIN is present for sibling library resolution
	cd "${S}"/opt/apps/com.cmic.mcloud/files/processes || die
	local f cur
	for f in *.so*; do
		[[ -f "${f}" ]] || continue
		cur=$(readelf -d "${f}" 2>/dev/null \
			| grep -E 'RUNPATH|RPATH' \
			| sed -n 's/.*\[\(.*\)\]/\1/p')
		if [[ -z "${cur}" ]]; then
			patchelf --set-rpath '$ORIGIN' "${f}" \
				|| die "patchelf --set-rpath failed for ${f}"
		elif ! echo "${cur}" | grep -qF '$ORIGIN'; then
			patchelf --set-rpath "\$ORIGIN:${cur}" "${f}" \
				|| die "patchelf --set-rpath failed for ${f}"
		fi
	done

	# Fix desktop entry: use icon name instead of hardcoded absolute path
	sed -e 's|Icon=/opt/apps/com.cmic.mcloud/files/resources/app.asar.unpacked/resources/icons/com.cmic.mcloud.png|Icon=com.cmic.mcloud|' \
		-i "${S}"/opt/apps/com.cmic.mcloud/entries/applications/com.cmic.mcloud.desktop \
		|| die "sed failed for desktop file"
}

src_install() {
	insinto /opt/apps/com.cmic.mcloud
	doins -r "${S}"/opt/apps/com.cmic.mcloud/entries
	doins -r "${S}"/opt/apps/com.cmic.mcloud/files

	# Executable permissions for main Electron binary
	fperms +x /opt/apps/com.cmic.mcloud/files/mcloud
	fperms +x /opt/apps/com.cmic.mcloud/files/chrome_crashpad_handler
	fperms +x /opt/apps/com.cmic.mcloud/files/libEGL.so
	fperms +x /opt/apps/com.cmic.mcloud/files/libGLESv2.so
	fperms +x /opt/apps/com.cmic.mcloud/files/libffmpeg.so
	fperms +x /opt/apps/com.cmic.mcloud/files/libvk_swiftshader.so
	fperms +x /opt/apps/com.cmic.mcloud/files/libvulkan.so.1

	# Executable permissions for Qt5 subprocesses
	fperms +x /opt/apps/com.cmic.mcloud/files/processes/backupDisk
	fperms +x /opt/apps/com.cmic.mcloud/files/processes/uploadDownload
	fperms +x /opt/apps/com.cmic.mcloud/files/processes/notes
	fperms -R +x /opt/apps/com.cmic.mcloud/files/plugins

	# Symlink main binary to PATH
	dosym -r /opt/apps/com.cmic.mcloud/files/mcloud /usr/bin/mcloud

	# Desktop entry
	domenu "${S}"/opt/apps/com.cmic.mcloud/entries/applications/com.cmic.mcloud.desktop

	# Icons
	local size
	for size in 16 24 32 48 64 128 256 512 1024; do
		local icon="${S}/opt/apps/com.cmic.mcloud/entries/icons/hicolor/${size}x${size}/apps/com.cmic.mcloud.png"
		[[ -f "${icon}" ]] && newicon -s ${size} "${icon}" com.cmic.mcloud.png
	done
}

pkg_postinst() {
	xdg_pkg_postinst

	elog "中国移动云盘 (mCloud) ${PV} has been installed."
	elog ""
	elog "Bundled Qt5 5.13.2 libraries have been removed because they are"
	elog "incompatible with the system ICU 78 (ICU 63 symbol suffixes)."
	elog "System Qt5 5.15.x libraries are used instead."
	elog ""
	elog "If backupDisk or other subprocesses fail to start, verify that"
	elog "all required Qt5 modules are installed:"
	elog "  emerge -av dev-qt/qt{core,gui,widgets,dbus,network,sql,xml,concurrent,multimedia,printsupport}:5"
	elog ""
	elog "The app runs with --no-sandbox (Electron sandbox disabled)."
}
