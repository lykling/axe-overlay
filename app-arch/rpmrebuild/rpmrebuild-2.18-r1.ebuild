# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit rpm toolchain-funcs

DESCRIPTION="rpmrebuild is a tool to build an RPM file from a package"
HOMEPAGE="https://rpmrebuild.sourceforge.net/"
SRC_URI="https://master.dl.sourceforge.net/project/rpmrebuild/rpmrebuild/${PV}/rpmrebuild-${PV}-${PR#r}.src.rpm"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64"

DEPEND=""
RDEPEND="${DEPEND}"
BDEPEND=""

S="${WORKDIR}"

src_prepare() {
	default
	tc-export CC
}
