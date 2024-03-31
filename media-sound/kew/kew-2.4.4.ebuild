# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="A command-line music player"
HOMEPAGE="https://github.com/ravachol/kew"
SRC_URI="https://github.com/ravachol/kew/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64"

DEPEND="
	media-video/ffmpeg
	sci-libs/fftw
	media-gfx/chafa
	media-libs/freeimage
	media-libs/opus
	media-libs/opusfile
	media-libs/libvorbis
	dev-libs/glib
"
RDEPEND="${DEPEND}"
BDEPEND=""
