#!/bin/bash
#
# TerraME - a software platform for multiple scale spatially-explicit dynamic modeling.
# Copyright (C) 2001-2017 INPE and TerraLAB/UFOP -- www.terrame.org
#
# This code is part of the TerraME framework.
# This framework is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library.
#
# The authors reassure the license terms regarding the warranties.
# They specifically disclaim any warranties, including, but not limited to,
# the implied warranties of merchantability and fitness for a particular purpose.
# The framework provided hereunder is on an "as is" basis, and the authors have no
# obligation to provide maintenance, support, updates, enhancements, or modifications.
# In no event shall INPE and TerraLAB / UFOP be held liable to any party for direct,
# indirect, special, incidental, or consequential damages arising out of the use
# of this software and its documentation.

if [ -z "$_TERRALIB_TARGET_3RDPARTY_DIR" ]; then
  export _TERRALIB_TARGET_3RDPARTY_DIR="$HOME/MyDevel/terrame/terralib/3rdparty/libs"
fi

if [ -z "$_TERRAME_TARGET_3RDPARTY_DIR" ]; then
  export _TERRAME_TARGET_3RDPARTY_DIR="$HOME/MyDevel/terrame/3rdparty"
fi

if [ -z "$_TERRALIB_3RDPARTY_NAME" ]; then
  export _TERRALIB_3RDPARTY_NAME="terralib-3rdparty-linux-ubuntu-14.04"
fi

if [ -z "$_TERRALIB_TARGET_URL" ]; then
  if [ -z "$_TERRALIB_VERSION" ]; then
    export _TERRALIB_TARGET_URL="http://www.dpi.inpe.br/terralib5-devel/3rdparty/src/$_TERRALIB_3RDPARTY_NAME.tar.gz"
  else
	export _TERRALIB_TARGET_URL="http://www.dpi.inpe.br/terralib5-devel/3rdparty/src/$_TERRALIB_VERSION/$_TERRALIB_3RDPARTY_NAME.tar.gz"
  fi
fi

#
# Valid parameter val or abort script
#
function valid()
{
  if [ $1 -ne 0 ]; then
    echo $2
    echo ""
    exit $1
  else
    echo "done."
  fi
}

echo ""
echo "#### TerraME Dependencies Compilation on Linux Ubuntu 14.04 ####"
echo ""

echo -ne "Cleaning up old builds ... "
rm -rf $_TERRALIB_TARGET_3RDPARTY_DIR $_TERRAME_TARGET_3RDPARTY_DIR
mkdir -p $_TERRALIB_TARGET_3RDPARTY_DIR $_TERRAME_TARGET_3RDPARTY_DIR
valid $? "Error: Could not enter $_TERRALIB_TARGET_3RDPARTY_DIR"

echo ""

echo -ne "Downloading TerraLib 3rdparty ... "
wget $_TERRALIB_TARGET_URL
valid $? "Error. Check $_TERRALIB_TARGET_URL"

echo -ne "Cloning TerraLib ... "
rm -rf terralib
git clone -b $_TERRALIB_BRANCH https://gitlab.dpi.inpe.br/rodrigo.avancini/terralib.git --quiet
valid $? "Error. Could not clone TerraLib $_TERRALIB_BRANCH"

# Configuring TerraLib 3rdparty compilation
cp terralib/install/$_TERRALIB_3RDPARTY_NAME.sh .

# Configuring TerraME dependencies compilation
cp terrame/build/scripts/linux/terrame-deps-conf.sh $_TERRAME_TARGET_3RDPARTY_DIR

tree -D -L 2

TERRALIB_DEPENDENCIES_DIR="$_TERRALIB_TARGET_3RDPARTY_DIR" ./$_TERRALIB_3RDPARTY_NAME.sh
valid $? "Error: Could not finish TerraLib 3rdparty compilation."

echo ""
echo ""

cd $_TERRAME_TARGET_3RDPARTY_DIR

echo -ne "Downloading Protobuf ... "
curl -L -O https://github.com/google/protobuf/releases/download/v3.1.0/protobuf-cpp-3.1.0.tar.gz --silent
valid $? "Error. Could not download 3rdparty"

echo -ne "Downloading Luacheck ... "
curl -L -O https://github.com/mpeterv/luacheck/archive/0.17.0.tar.gz --silent
valid $? "Error: Could not download LuaCheck"

echo ""
echo -ne "Preparing to compilation ... "
tar zxf protobuf-cpp-3.1.0.tar.gz
valid $? "Error: Could not extract protobuff"
mv protobuf-3.1.0 protobuf
valid $? "Error: Could find 'protobuf' folder inside compressed protobuf"
tar zxf 0.17.0.tar.gz
valid $? "Error: Could not extract Luacheck"
mv luacheck* luacheck
valid $? "Error: Could find luacheck inside luacheck compressed file"

echo -ne "Compiling TerraME dependencies ... "
./terrame-deps-conf.sh
valid $? "Error: Could not finish TerraME 3rdparty compilation."

echo ""
echo "Finished"
echo ""
