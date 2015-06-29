test = {
	--__test__ = "terrame -test config/all.lua",
	onerror = "terrame -package onerror -test config/all.lua",
	twoerrors = "terrame -package twoerrors -test config/all.lua",
	onefile = "terrame -test config/oneFile.lua",
	onetest = "terrame -test config/oneTest.lua",
	onefolder = "terrame -test config/oneFolder.lua",
	twofiles = "terrame -test config/twoFiles.lua",
	twotest = "terrame -test config/twoTests.lua",
	twofolder = "terrame -test config/twoFolders.lua",
}

package = {
	nodescription = "terrame -package nodescription",
	nolua = "terrame -package nolua",
	noexamples = "terrame -package noexamples",
	noexamplesexample = "terrame -package noexamples -example",
	example = "terrame -package onerror -example ipd"
}

doc = {
	doc = "terrame -doc",
	onerror = "terrame -package onerror -doc",
	twoerrors = "terrame -package twoerrors -doc",
	nodescription = "terrame -package nodescription -doc",
	nodatadotlua = "terrame -package nodatadotlua -doc",
	wrongdata = "terrame -package wrongdata -doc",
	withoutdata = "terrame -package wrongdata -doc",
}

build = {
	build = "terrame -package build -build",
	onerrorbuild = "terrame -package onerrorbuild -build",
	twoerrorsbuild = "terrame -package twoerrorsbuild -build",
	buildunnecfiles = "terrame -package buildunnecfiles -build",
}

mode = {
	normal = "terrame scripts/basic.lua",
	debug = "terrame -mode=debug scripts/basic.lua",
	strict = "terrame -mode=strict scripts/basic.lua",
	quiet = "terrame -mode=quiet scripts/basic.lua",
}

basic = {
	help = "terrame -help",
	version = "terrame -version",
	trace = "terrame scripts/trace.lua",
	noexample = "terrame -example abc",
	example = "terrame -example ipd",
	nointerface = "terrame -interface abc",
	qwerty4321 = "terrame -package qwerty4321",
}
