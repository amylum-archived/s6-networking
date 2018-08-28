s6-networking
=========

[![Build Status](https://img.shields.io/travis/com/amylum/s6-networking.svg)](https://travis-ci.com/amylum/s6-networking)
[![GitHub release](https://img.shields.io/github/release/amylum/s6-networking.svg)](https://github.com/amylum/s6-networking/releases)
[![ISC Licensed](https://img.shields.io/badge/license-ISC-green.svg)](https://tldrlegal.com/license/-isc-license)

This is my package repo for [s6-networking](http://www.skarnet.org/software/s6-networking/), a set of network tools by [Laurent Bercot](http://skarnet.org/).

The `upstream/` directory is taken directly from upstream. The rest of the repository is my packaging scripts for compiling a distributable build.

## Usage

To build a new package, update the submodule and run `make`. This launches the docker build container and builds the package.

To start a shell in the build environment for manual actions, run `make manual`.

## License

The s6-networking upstream code is ISC licensed. My packaging code is MIT licensed.

