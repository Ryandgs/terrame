-------------------------------------------------------------------------------------------
-- TerraME - a software platform for multiple scale spatially-explicit dynamic modeling.
-- Copyright (C) 2001-2017 INPE and TerraLAB/UFOP -- www.terrame.org

-- This code is part of the TerraME framework.
-- This framework is free software; you can redistribute it and/or
-- modify it under the terms of the GNU Lesser General Public
-- License as published by the Free Software Foundation; either
-- version 2.1 of the License, or (at your option) any later version.

-- You should have received a copy of the GNU Lesser General Public
-- License along with this library.

-- The authors reassure the license terms regarding the warranties.
-- They specifically disclaim any warranties, including, but not limited to,
-- the implied warranties of merchantability and fitness for a particular purpose.
-- The framework provided hereunder is on an "as is" basis, and the authors have no
-- obligation to provide maintenance, support, updates, enhancements, or modifications.
-- In no event shall INPE and TerraLAB / UFOP be held liable to any party for direct,
-- indirect, special, incidental, or consequential damages arising out of the use
-- of this software and its documentation.
--
-------------------------------------------------------------------------------------------

local printError   = _Gtme.printError
local printNote    = _Gtme.printNote
local profiler     = _Gtme.Profiler()

_Gtme.ignoredFile = function(fname)
	local ignoredExtensions = {
		".dbf",
		".prj",
		".qpj",
		".shx",
		".sbn",
		".sbx",
		".fbn",
		".fbx",
		".ain",
		".aih",
		".ixs",
		".mxs",
		".atx",
		".shp.xml",
		".cpg",
		".qix",
		".tme",
		".lua"
	}

	local ignore = false
	forEachElement(ignoredExtensions, function(_, ext)
		if string.endswith(fname, ext) then
			ignore = true
		end
	end)

	return ignore
end

local function imageFiles(package)
	local s = sessionInfo().separator
	local imagepath = Directory(packageInfo(package).path..s.."images")

	if not imagepath:exists() then
		return {}
	end

	local result = {}

	forEachFile(imagepath, function(file)
		if file:extension() ~= "lua" then
			result[file:name()] = 0
		end
	end)

	return result
end

local function dataFiles(package)
	local datapath = packageInfo(package).data

	if not datapath:exists() then
		return {}
	end

	local result = {}

	forEachFile(datapath, function(fname)
		table.insert(result, fname:name())
	end)

	return result
end

local function getProjects(package, doc_report)
	local projects = {}
	local layers = {}
	local currentProject

	if not isLoaded("gis") then
		import("gis")
	end

	local oldImport = import

	import = function(pkg)
		if pkg ~= "gis" then
			oldImport(pkg)
		end
	end

	local tl = getPackage("gis")
	local createdFiles = {}

	function processLayer(idx, value)
		local layer = tl.Layer{
			project = filePath(currentProject, package),
			name = idx
		}

		local representation = layer:representation()
		local description

		if representation == "raster" then
			description = "Raster with "..math.floor(layer:bands()).." band"

			if layer:bands() > 1 then
				description = description.."s"
			end
		else
			local cs = CellularSpace{
				file = value
			}

			local quantity = #cs
			description = tostring(quantity).." "..representation

			if quantity > 1 then
				description = description.."s"
			end
		end

		description = description.."."

		if type(value) == "string" then value = File(value) end

		projects[currentProject][idx] = {
			file = value:name(),
			description = description
		}
	end

	Project = function(data)
		currentProject = data.file

		if createdFiles[data.file] then
			printError("File '"..data.file.."' is created more than once.")
			doc_report.project_error = doc_report.project_error + 1
		else
			createdFiles[data.file] = true
		end

		projects[currentProject] = {}

		forEachOrderedElement(data, function(idx, value)
			if belong(idx, {"clean", "file", "author", "title", "layers", "directory"}) then return end

			if type(value) == "string" then
				value = File(value)
			end

			if idx ~= "file" and type(value) == "File" and value:exists() then
				processLayer(idx, value)
			end
		end)

		return filePath(currentProject, package)
	end

	local mLayer_ = {
		fill = function(self, data)
			local name = self.file or self.database
			if not name then return nil end

			if not layers[name] then
				layers[name] = {attributes = {}}
			end

			local description = "Operation "..data.operation

			if data.area then
				description = description.." (weighted by area) "
			end

			description = description.." from layer \""..data.layer.."\""

			if data.band or data.select or data.dummy then
				description = description.." using"
			end

			if data.band then
				description = description.." band "..data.band

				if data.dummy then
					description = description.." and "
				end
			elseif data.select then
				description = description.." selected attribute ".."\""..data.select.."\""
			end

			if data.dummy then
				description = description.." dummy "..data.dummy
			end

			if data.operation == "coverage" then
				local layer = tl.Layer{
					project = filePath(currentProject, package),
					name = self.name
				}

				local attrNames
				local attrs = layer:attributes()
				if attrs then
					attrNames = {}
					for i = 1, #attrs do
						attrNames[i] = attrs[i].name
					end
				end

				forEachElement(attrNames, function(_, mvalue)
					if string.sub(mvalue, 1, string.len(data.attribute)) == data.attribute then
						local v = string.sub(mvalue, string.len(data.attribute) + 2)
						layers[name].attributes[mvalue] = {
							description = description.. " using value "..v..".",
							type = "number"
						}
					end
				end)
			else
				description = description.."."

				layers[name].attributes[data.attribute] = {
					description = description,
					type = "number"
				}
			end
		end
	}

	local mtLayer = {__index = mLayer_}

	Layer = function(data)
		if not data.file and not data.database then return end

		if data.resolution then
			local dataType

			if data.file then
				local mfile = data.file
				dataType = "file"

				if type(mfile) == "string" then
					mfile = File(mfile)
				end

				if createdFiles[mfile:name()] then
					printError("File '"..mfile:name().."' is created more than once.")
					doc_report.project_error = doc_report.project_error + 1
				else
					createdFiles[mfile:name()] = true
				end
			else -- data.database
				dataType = "PostGIS database table"
				if createdFiles[data.database] then
					printError("Database '"..data.database.."' is created more than once.")
					doc_report.project_error = doc_report.project_error + 1
				else
					createdFiles[data.database] = true
				end
			end

			local cs = CellularSpace{
				project = data.project,
				layer = data.name
			}

			local quantity = #cs
			description = tostring(quantity).." cells (polygons) with resolution "..
				data.resolution.." built from layer \""..data.input.."\""

			projects[currentProject][data.name] = {
				file = data.file or data.database,
				database = data.database,
				description = description.."."
			}

			if not layers[data.file or data.database] then
				tl.Layer{
					project = data.project,
					name = data.name
				}

				layers[data.file or data.database] =
				{
					file = {data.file or data.database},
					database = data.database,
					arguments = data,
					title = data.file or data.database,
					summary = "Automatically created "..dataType.." with "..description..
						", in project <a href = \"#"..currentProject.."\">"..currentProject.."</a>.",
					shortsummary = "Automatically created "..dataType.." in project \""..currentProject.."\".",
					attributes = {}
				}
			end
		else
			processLayer(data.name, data.file)
		end

		setmetatable(data, mtLayer)
		return data
	end

	sessionInfo().mode = "quiet"
	printNote("Processing lua files")
	forEachFile(packageInfo(package).data, function(file)
		if file:extension() == "lua" then
			print("Processing '"..file:name().."'")

			_Gtme.loadTmeFile(tostring(file))

			xpcall(function() dofile(tostring(file)) end, function(err)
				printError(_Gtme.traceback(err))
				doc_report.project_error = doc_report.project_error + 1
			end)

			clean()
		end
	end)

	local output = {}
	local allLayers = {}

	-- we need to execute this separately to guarantee that the outputs will be alphabetically ordered
	forEachOrderedElement(projects, function(idx, proj)
		local projFile = File(idx)
		local _, projFileName, projFileExt = projFile:split()
		local luaFile = projFileName..".lua"
		local shortsummary
		if projFileExt == "tview" then
			shortsummary = "Automatically created TerraView project file"
		else
			shortsummary = "Automatically created QGIS project file"
		end
		local summary = shortsummary.." from <a href=\"../../data/"..luaFile.."\">"..luaFile.."</a>."
		local mlayers = {}

		local mproject = {
			summary = summary,
			shortsummary = shortsummary..".",
			file = {idx},
			title = idx
		}

		forEachOrderedElement(proj, function(midx, layer)
			layer.layer = midx
			table.insert(mlayers, layer)
			table.insert(allLayers, layer)
		end)

		mproject.layers = mlayers

		table.insert(output, mproject)
	end)

	forEachOrderedElement(layers, function(_, layer)
		--layer.file = {layer.file}
		table.insert(output, layer)
	end)

	clean()

	import = oldImport

	return output
end

local function removeTview(df, filepath)
	local _, fn = File(filepath):split()
	for i = 1, #df do
		if df[i] == fn..".tview" then
			df[i] = nil
			return
		end
	end
end

local function removeTviewWhenQGisProject(df)
	for i = 1, #df do
		if df[i] and string.endswith(df[i], ".qgs") then
			removeTview(df, df[i])
		end
	end
end

function _Gtme.executeDoc(package)
	profiler:start("DOC_")
	if not isLoaded("luadoc") then
		import("luadoc")
	end

	if not isLoaded("base") then
		import("base")
	end

	printNote("Building documentation for package '"..package.."'")
	local s = sessionInfo().separator
	local package_path = _Gtme.packageInfo(package).path

	printNote("Loading package '"..package.."'")

	local pkg

	xpcall(function() pkg = _G.getPackage(package) end, function(err)
		printError("Package '"..package.."' could not be loaded.")
		printError(_Gtme.traceback(err))
		os.exit(1)
	end)

	local lua_files = {}

	if isDirectory(package_path..s.."lua") then
		lua_files = Directory(package_path..s.."lua"):list()
	end

	local docDir = Directory(package_path..s.."doc")
	if docDir:exists() then
		docDir:delete()
	end

	local example_files = _Gtme.findExamples(package)

	local doc_report = {
		arguments = 0,
		lua_files = 0,
		html_files = 0,
		global_functions = 0,
		functions = 0,
		models = 0,
		model_error = 0,
		projects = 0,
		project_error = 0,
		variables = 0,
		links = 0,
		examples = 0,
		wrong_description = 0,
		undoc_arg = 0,
		undefined_arg = 0,
		duplicated_functions = 0,
		unused_arg = 0,
		unknown_arg = 0,
		undoc_files = 0,
		lack_usage = 0,
		no_call_itself_usage = 0,
		usage_error = 0,
		wrong_links = 0,
		invalid_tags = 0,
		problem_examples = 0,
		duplicated = 0,
		compulsory_arguments = 0,
		undoc_functions = 0,
		error_data = 0,
		error_font = 0,
		fonts = 0,
		wrong_line = 0,
		wrong_tabular = 0,
		wrong_image = 0,
		wrong_descriptions = 0
	}

	local mdata = {}
	local mdirectory = {}
	local filesdocumented = {}
	local df = dataFiles(package)

	removeTviewWhenQGisProject(df)

	sessionInfo().mode = "strict"

	if File(package_path..s.."data.lua"):exists() and #df > 0 then
		printNote("Parsing 'data.lua'")

		directory = function(tab)
			local count = verifyUnnecessaryArguments(tab, {"name", "summary", "source", "reference"})
			doc_report.error_data = doc_report.error_data + count

			if not tab.file then tab.file = "?" end
			if type(tab.file) == "string" then tab.file = {tab.file} end

			local mverify = {
				{"mandatoryTableArgument", "name",      "string"},
				{"mandatoryTableArgument", "summary",   "string"},
				{"mandatoryTableArgument", "source",    "string"},
				{"optionalTableArgument",  "reference", "string"}
			}

			-- it is necessary to implement this way in order to get the line number of the error
			for i = 1, #mverify do
				local func = "return function(tab) "..mverify[i][1].."(tab, \""..mverify[i][2].."\", \""..mverify[i][3].."\") end"

				xpcall(function() load(func)()(tab) end, function(err)
					doc_report.error_data = doc_report.error_data + 1
					printError(err)
				end)
			end

			tab.title = tab.name
			tab.extensions = {}
			tab.files = 0

			local dataDir = Directory(package_path..s.."data")

			if not Directory(dataDir..tab.name):exists() then
				printError("Documented directory '"..dataDir..tab.name.."' does not exist.")
				doc_report.error_data = doc_report.error_data + 1
				return
			end

			extensions = {}
			forEachFile(dataDir..tab.name, function(file)
				tab.files = tab.files + 1

				extensions[file:extension()] = true
			end)

			forEachOrderedElement(extensions, function(idx)
				table.insert(tab.extensions, idx)
			end)

			tab.extensions = table.concat(tab.extensions, ", ")

			if tab.summary then
				tab.shortsummary = string.match(tab.summary, "(.-%.)")

				if not string.endswith(tab.summary, "%.") then
					printError("In '"..tab.name.."', 'summary' should end with '.'")
					doc_report.wrong_descriptions = doc_report.wrong_descriptions + 1
				end
			end

			table.insert(mdirectory, tab)
		end

		data = function(tab)
			local count = verifyUnnecessaryArguments(tab, {"file", "image", "summary", "source", "attributes", "separator", "reference", "title"})
			doc_report.error_data = doc_report.error_data + count

			if not tab.file then tab.file = "?" end
			if type(tab.file) == "string" then tab.file = {tab.file} end

			local mverify = {
				{"mandatoryTableArgument", "file",        "table"},
				{"mandatoryTableArgument", "summary",     "string"},
				{"mandatoryTableArgument", "source",      "string"},
				{"optionalTableArgument",  "image",       "string"},
				{"optionalTableArgument",  "attributes",  "table"},
				{"optionalTableArgument",  "reference",   "string"},
				{"optionalTableArgument",  "title",       "string"},
				{"optionalTableArgument",  "separator",   "string"}
			}

			if not tab.attributes then
				tab.attributes = {}
			end

			if not tab.title then tab.title = tab.file[1] end

			local attributes = {}
			local counter = 0

			forEachElement(tab.attributes, function(idx, value)
				if type(idx) == "table" then
					forEachElement(idx, function(_, _, mtype)
						if mtype ~= "string" then
							counter = counter + 1
						end
					end)
				elseif type(idx) ~= "string" then
					counter = counter + 1
					return
				end

				if type(value) ~= "string" then
					printError("In the documentation of '"..tab.file[1].."', description of attribute '"..idx.."' should be string, got "..type(value)..".")
					value = ""
					doc_report.error_data = doc_report.error_data + 1
				elseif not string.endswith(value, "%.") then
					if type(idx) == "table" then
						printError("In '"..tab.file[1].."', description of attributes '"..table.concat(idx, "', '").."' should end with '.'")
					else
						printError("In '"..tab.file[1].."', description of attribute '"..idx.."' should end with '.'")
					end

					doc_report.wrong_descriptions = doc_report.wrong_descriptions + 1
				end

				attributes[idx] = {description = value}
			end)

			if counter > 0 then
				printError("In the documentation of '"..tab.file[1].."', all names should be string, got "..counter.." invalid names.")
				doc_report.error_data = doc_report.error_data + counter
			end

			tab.attributes = attributes

			-- it is necessary to implement this way in order to get the line number of the error
			for i = 1, #mverify do
				local func = "return function(tab) "..mverify[i][1].."(tab, \""..mverify[i][2].."\", \""..mverify[i][3].."\") end"

				xpcall(function() load(func)()(tab) end, function(err)
					doc_report.error_data = doc_report.error_data + 1
					printError(err)
				end)
			end

			if tab.summary then
				tab.shortsummary = string.match(tab.summary, "(.-%.)")

				if not string.endswith(tab.summary, "%.") then
					printError("In '"..tab.file[1].."', 'summary' should end with '.'")
					doc_report.wrong_descriptions = doc_report.wrong_descriptions + 1
				end
			end

			if tab.file[1] ~= "?" then
				table.insert(mdata, tab)

				forEachElement(tab.file, function(_, mvalue)
					if filesdocumented[mvalue] then
						printError("Data file '"..mvalue.."' is documented more than once.")
						doc_report.error_data = doc_report.error_data + 1
					end

					filesdocumented[mvalue] = 0
				end)
			end
		end

		xpcall(function() dofile(package_path..s.."data.lua") end, function(err)
			printError("Could not load 'data.lua'")
			printError(err)
			os.exit(1)
		end)

		projects = getProjects(package, doc_report)
		doc_report.projects = getn(projects)

		forEachOrderedElement(projects, function(_, value)
			if value.layers or string.find(value.summary, "resolution") and value.file[1] then -- a project or a layer of cells
				filesdocumented[value.file[1]] = 1
			end
		end)

		printNote("Checking directory 'data'")
		forEachOrderedElement(projects, function(_, value)
			local found = false
			forEachElement(mdata, function(_, mvalue)
				if value.file[1] == mvalue.file[1] then
					if value.layers or string.find(value.summary, "resolution") then -- a project or a layer of cells
						printError("File "..value.file[1].." should not be documented as it is automatically created.")
						found = true
						doc_report.error_data = doc_report.error_data + 1
					end
				end
			end)

			if not found and value.file then
				table.insert(mdata, value)
			end
		end)

		table.sort(mdata, function(a, b)
			return a.title < b.title
		end)

		printNote("Checking properties of data files")
		-- add quantity and type for each documented file
		local tl = getPackage("gis")

		myProject = tl.Project{
			file = "tmpproj.tview",
			clean = true
		}

		idx = 1

		forEachElement(mdata, function(_, value)
			if not value.database then
				value.name = value.file[1] or ""
				if not isFile(packageInfo(package).path.."data"..s..value.file[1]) then
					-- this will be recognized as an error afterwards
					return
				end
			end

			local allAttributes = {}

			if value.database or not (string.endswith(value.file[1], ".tview")
									or string.endswith(value.file[1], ".qgs")) then
				forEachElement(value.attributes, function(idx)
					if type(idx) == "table" then
						forEachElement(idx, function(_, mvalue)
							if allAttributes[mvalue] then
								printError("Attribute '"..mvalue.."' is documented more than once.")
								doc_report.error_data = doc_report.error_data + 1
							end

							allAttributes[mvalue] = true
						end)
					else
						if allAttributes[idx] then
							printError("Attribute '"..idx.."' is documented more than once.")
							doc_report.error_data = doc_report.error_data + 1
						end

						allAttributes[idx] = true
					end
				end)
			end

			if value.database then
				print("Processing database '"..value.database.."'")
				value.name = value.database

				layer = tl.Layer{
					project = value.arguments.project,
					name = value.arguments.name,
				}

				value.representation = layer:representation()
				value.projection = layer:projection()
				value.epsg = layer.epsg

				local attributes
				local attrs = layer:attributes()
				if attrs then
					attributes = {}
					for i = 1, #attrs do
						attributes[i] = attrs[i].name
					end
				end

				if value.attributes == nil then value.attributes = {} end

				forEachElement(attributes, function(_, mvalue)
					if mvalue == "id" then
						value.attributes[mvalue] = {
							description = "Unique identifier (internal value).",
							type = "string"
						}
					elseif mvalue == "col" then
						value.attributes[mvalue] = {
							description = "Cell's column.",
							type = "number"
						}
					elseif mvalue == "row" then
						value.attributes[mvalue] = {
							description = "Cell's row.",
							type = "number"
						}
					end
				end)
			elseif string.endswith(value.file[1], ".gal") then
				print("Processing '"..value.file[1].."'")

				local file = filePath(value.file[1], package)
				local firstLine = file:readLine(" ")

				local countOrigins = 0
				local countConnections = 0

				local line = file:readLine(" ")
				while #line > 0 do
					countOrigins = countOrigins + 1
					countConnections = countConnections + tonumber(line[2])
					if tonumber(line[2]) > 0 then
						file:readLine(" ")
					end

					line = file:readLine(" ")
				end

				value.origin = firstLine[3]
				value.origins = countOrigins
				value.connections = countConnections
			elseif string.endswith(value.file[1], ".gwt") then
				print("Processing '"..value.file[1].."'")

				local file = filePath(value.file[1], package)
				local firstLine = file:readLine(" ")

				local countConnections = 0

				local line = file:readLine(" ")
				while #line > 0 do
					countConnections = countConnections + 1
					line = file:readLine(" ")
				end

				value.origin = firstLine[3]
				value.origins = firstLine[2]
				value.connections = countConnections
			elseif string.endswith(value.file[1], ".gpm") then
				print("Processing '"..value.file[1].."'")

				local file = filePath(value.file[1], package)
				local firstLine = file:readLine(" ")

				local countOrigins = 0
				local countConnections = 0

				local line = file:readLine(" ")
				while #line > 0 do
					countOrigins = countOrigins + 1
					countConnections = countConnections + tonumber(line[2])
					if tonumber(line[2]) > 0 then
						file:readLine(" ")
					end

					line = file:readLine(" ")
				end

				value.origin = firstLine[2]
				value.destination = firstLine[3]
				value.origins = countOrigins
				value.connections = countConnections
			elseif string.endswith(value.file[1], ".csv") then
				print("Processing '"..value.file[1].."'")

				if not value.separator then
					doc_report.error_data = doc_report.error_data + 1
					printError("Documentation of CSV files must define 'separator'.")
					return
				end

				local columns
				local csv = {}

				local result, err = pcall(function()
					csvfile = filePath(value.file[1], package)
					columns = csvfile:readLine(value.separator)
					local csvtmp = csvfile:readLine(value.separator)

					forEachElement(columns, function(idx, mvalue)
						csv[mvalue] = tonumber(csvtmp[idx]) or csvtmp[idx]
					end)

					csvfile:close()
				end)

				if not result then
					printError(err)
					doc_report.error_data = doc_report.error_data + 1
					return
				end

				local lines = 0
				for _ in io.lines(tostring(filePath(value.file[1], package))) do
					lines = lines + 1
				end

				if value.attributes == nil then value.attributes = {} end

				forEachElement(value.attributes, function(idx, mvalue)
					if type(idx) == "table" then
						mvalue.type = type(csv[idx[1]])
					else
						mvalue.type = type(csv[idx])
					end
				end)

				forEachElement(columns, function(_, idx)
					if not allAttributes[idx] then
						doc_report.error_data = doc_report.error_data + 1
						printError("Attribute '"..idx.."' is not documented.")

						value.attributes[idx] = {
							description = "<font color=\"red\">undefined</font>",
							type = type(csv[idx])
						}
					end
				end)

				value.quantity = lines
			elseif string.endswith(value.file[1], ".shp") or string.endswith(value.file[1], ".geojson") then
				print("Processing '"..value.file[1].."'")

				local firstfile = value.file[1]

				for i = 1, #value.file do
					if string.endswith(value.file[i], ".shp") then
						local file = File(packageInfo(package).path.."data/"..value.file[i])
						local path, name = file:split()

						table.insert(value.file, name..".shx")
						table.insert(value.file, name..".dbf")

						local prj = File(path..name..".prj")
						if prj:exists() then
							table.insert(value.file, name..".prj")
						end

						prj = File(path..name..".qpj")
						if prj:exists() then
							table.insert(value.file, name..".qpj")
						end
					end
				end

				table.sort(value.file)

				layer = tl.Layer{
					project = myProject,
					file = filePath(firstfile, package),
					name = "layer"..idx
				}

				value.representation = layer:representation()
				value.projection = layer:projection()
				value.epsg = layer.epsg

				local attributes
				local attrs = layer:attributes()
				if attrs then
					attributes = {}
					for i = 1, #attrs do
						attributes[i] = attrs[i].name
					end
				end

				if value.attributes == nil then value.attributes = {} end

				forEachElement(attributes, function(_, mvalue)
					if allAttributes[mvalue] then return end

					if mvalue == "id" then
						value.attributes[mvalue] = {
							description = "Unique identifier (internal value)."
						}
					elseif mvalue == "col" then
						value.attributes[mvalue] = {
							description = "Cell's column."
						}
					elseif mvalue == "row" then
						value.attributes[mvalue] = {
							description = "Cell's row."
						}
					elseif mvalue ~= "FID" then
						printError("Attribute '"..mvalue.."' is not documented.")
						doc_report.error_data = doc_report.error_data + 1
						value.attributes[mvalue] = {
							description = "<font color=\"red\">undefined</font>"
						}
					end
				end)

				forEachElement(value.attributes, function(mvalue)
					if type(mvalue) == "table" then
						forEachElement(mvalue, function(_, mmvalue)
							if not belong(mmvalue, attributes) then
								doc_report.error_data = doc_report.error_data + 1
								printError("Attribute '"..mmvalue.."' is documented but does not exist in the file.")
							end
						end)
					elseif not belong(mvalue, attributes) then
						doc_report.error_data = doc_report.error_data + 1
						printError("Attribute '"..mvalue.."' is documented but does not exist in the file.")
					end
				end)

				local cs = CellularSpace{
					layer = layer
				}

				forEachElement(value.attributes, function(idx, mvalue)
					if type(idx) == "table" then
						mvalue.type = type(cs.cells[1][idx[1]])

						forEachElement(idx, function(_, mmvalue)
							if mvalue.type ~= type(cs.cells[1][mmvalue]) then
								printError("All the attributes documented together should have the same type, got "..mvalue.type.." ('"..idx[1].."') and "..type(cs.cells[1][mmvalue]).." ('"..mmvalue.."').")
								doc_report.error_data = doc_report.error_data + 1
							end
						end)
					else
						mvalue.type = type(cs.cells[1][idx])
					end
				end)

				value.quantity = #cs

				idx = idx + 1
			elseif string.endswith(value.file[1], ".tif") then
				print("Processing '"..value.file[1].."'")

				layer = tl.Layer{
					project = myProject,
					file = filePath(value.file[1], package),
					name = "layer"..idx
				}

				value.representation = layer:representation()
				value.projection = layer:projection()
				value.epsg = layer.epsg
				value.bands = layer:bands()
				value.dummy = {}

				if value.attributes == nil then value.attributes = {} end

				for i = 0, value.bands - 1 do
					table.insert(value.dummy, layer:dummy(i))

					if not value.attributes[tostring(i)] then
						printError("Band "..i.." is not documented.")
						doc_report.error_data = doc_report.error_data + 1
						value.attributes[tostring(i)] = {
							description = "<font color=\"red\">undefined</font>"
						}
					end
				end

				forEachElement(value.attributes, function(idx)
					if tonumber(idx) < 0 or tonumber(idx) >= value.bands then
						doc_report.error_data = doc_report.error_data + 1
						printError("Band "..idx.." is documented but does not exist in the file.")
					end
				end)

				forEachElement(value.attributes, function(_, mvalue)
					mvalue.type = "number"
				end)

				idx = idx + 1
			elseif string.endswith(value.file[1], ".pgm") then
				print("Processing '"..value.file[1].."'")
				forEachElement(value.attributes, function(_, mvalue)
					mvalue.type = "number"
				end)

				idx = idx + 1
			end
		end)

		File("tmpproj.tview"):delete()

		-- convert attributes from
		-- {
		--		attribute1 = {type = ..., description = ...},
		--		attribute2 = {type = ..., description = ...},
		--		attribute3 = {type = ..., description = ...}
		-- }
		-- into tables
		-- {
		--     attributes = {...},
		--     types = {...},
		--     description = {...}
		-- }
		forEachElement(mdata, function(_, value)
			if not value.attributes then return end

			local attributes = value.attributes

			value.attributes = {}
			value.types = {}
			value.description = {}

			singleAttributes = {}

			forEachElement(attributes, function(idx)
				if type(idx) == "table" then
					singleAttributes[idx[1]] = idx
				else
					singleAttributes[idx] = idx
				end
			end)

			forEachOrderedElement(singleAttributes, function(_, mvalue)
				table.insert(value.attributes, mvalue)
				table.insert(value.description, attributes[mvalue].description)
				table.insert(value.types, attributes[mvalue].type)
			end)
		end)

		forEachOrderedElement(df, function(_, mvalue)
			if _Gtme.ignoredFile(mvalue) then
				if filesdocumented[mvalue] == nil then
					filesdocumented[mvalue] = 1
				else
					printError("File '"..mvalue.."' should not be documented")
					doc_report.error_data = doc_report.error_data + 1
				end
			end
		end)

		forEachOrderedElement(df, function(_, mvalue)
			if filesdocumented[mvalue] == nil and not string.endswith(mvalue, ".lua") then
				printError("File '"..mvalue.."' is not documented")
				doc_report.error_data = doc_report.error_data + 1
			else
				filesdocumented[mvalue] = filesdocumented[mvalue] + 1
			end
		end)

		forEachOrderedElement(filesdocumented, function(midx, mvalue)
			if mvalue == 0 then
				printError("File '"..midx.."' is documented but does not exist in directory 'data'")
				doc_report.error_data = doc_report.error_data + 1
			end
		end)
	elseif #df > 0 then
		printNote("Checking directory 'data'")
		printError("Package has data files but data.lua does not exist")
		forEachElement(df, function(_, mvalue)
			if isDirectory(package_path..s.."data"..s..mvalue) then
				return
			end

			printError("File '"..mvalue.."' is not documented")
			doc_report.error_data = doc_report.error_data + 1
		end)
	elseif File(package_path..s.."data.lua"):exists() then
		printError("Package '"..package.."' has data.lua but there is no data")
		doc_report.error_data = doc_report.error_data + 1
	else
		printNote("Package has no data")
	end

	local mfont = {}
	local fontsdocumented = {}
	df = _Gtme.fontFiles(package)
	doc_report.fonts = #df

	if File(package_path..s.."font.lua"):exists() and doc_report.fonts > 0 then
		printNote("Parsing 'font.lua'")
		font = function(tab)
			local count = verifyUnnecessaryArguments(tab, {"name", "file", "summary", "source", "symbol"})
			doc_report.error_font = doc_report.error_font + count

			local mverify = {
				{"optionalTableArgument",  "name",    "string"},
				{"mandatoryTableArgument", "file",    "string"},
				{"mandatoryTableArgument", "source",  "string"},
				{"mandatoryTableArgument", "summary", "string"},
				{"mandatoryTableArgument", "symbol",  "table"},
			}

			-- it is necessary to implement this way in order to get the line number of the error
			for i = 1, #mverify do
				local func = "return function(tab) "..mverify[i][1].."(tab, \""..mverify[i][2].."\", \""..mverify[i][3].."\") end"

				xpcall(function() load(func)()(tab) end, function(err)
					doc_report.error_font = doc_report.error_font + 1
					tab.file = nil
					printError(err)
				end)
			end

			if tab.summary then
				tab.shortsummary = string.match(tab.summary, "(.-%.)")
			end

			if type(tab.symbol) ~= "table" then tab.symbol = {} end

			forEachElement(tab.symbol, function(idx, _, mtype)
				if type(idx) ~= "string" then
					printError("Font '"..tostring(tab.name).."' has a non-string symbol.")
					doc_report.error_font = doc_report.error_font + 1
					tab.file = nil
				elseif mtype ~= "number" then
					printError("Symbol '"..idx.."' has a non-numeric value.")
					tab.file = nil
					doc_report.error_font = doc_report.error_font + 1
				end
			end)

			if type(tab.file) == "string" then
				table.insert(mfont, tab)

				if fontsdocumented[tab.file] then
					printError("Font file '"..tab.file.."' is documented more than once.")
					doc_report.error_font = doc_report.error_font + 1
				end

				fontsdocumented[tab.file] = 0
			end
		end

		xpcall(function() dofile(package_path..s.."font.lua") end, function(err)
			printError("Could not load 'font.lua'")
			printError(err)
			os.exit(1)
		end)

		sessionInfo().mode = "debug"

		table.sort(mfont, function(a, b)
			return a.file < b.file
		end)

		printNote("Checking directory 'font'")
		forEachOrderedElement(df, function(_, mvalue)
			if fontsdocumented[mvalue] == nil then
				printError("Font file '"..mvalue.."' is not documented")
				doc_report.error_font = doc_report.error_font + 1
			else
				fontsdocumented[mvalue] = fontsdocumented[mvalue] + 1
			end
		end)

		forEachOrderedElement(fontsdocumented, function(midx, mvalue)
			if mvalue == 0 then
				printError("Font file '"..midx.."' is documented but does not exist in directory 'font'")
				doc_report.error_font = doc_report.error_font + 1
			end
		end)

		printNote("Checking licenses of fonts")

		forEachElement(df, function(_, mvalue)
			local license = string.sub(mvalue, 0, -5)..".txt"

			if not File(package_path..s.."font"..s..license):exists() then
				printError("License file '"..license.."' for font '"..mvalue.."' does not exist")
				doc_report.error_font = doc_report.error_font + 1
			end
		end)
	elseif #df > 0 then
		printNote("Checking directory 'font'")
		printError("Package has font files but font.lua does not exist")
		forEachElement(df, function(_, mvalue)
			printError("File '"..mvalue.."' is not documented")
			doc_report.error_font = doc_report.error_font + 1
		end)
	elseif File(package_path..s.."font.lua"):exists() then
		printError("Package '"..package.."' has font.lua but there are no fonts")
		doc_report.error_font = doc_report.error_font + 1
	else
		printNote("Package has no fonts")
	end

	local result = luadocMain(package_path, lua_files, example_files, package, mdata, mdirectory, mfont, doc_report)

	if Directory(package_path..s.."font"):exists() then
		local cmd = "cp "..package_path..s.."font"..s.."* "..package_path..s.."doc"..s.."files"
		cmd = _Gtme.makePathCompatibleToAllOS(cmd)
		os.execute(cmd)
	end

	local all_functions = _Gtme.buildCountTable(package)

	local all_doc_functions = {}

	forEachElement(result.files, function(idx, value)
		if type(idx) ~= "string" then return end
		if not string.endswith(idx, ".lua") then return end

		all_doc_functions[idx] = {}
		forEachElement(value.functions, function(midx)
			if type(midx) ~= "string" then return end
			all_doc_functions[idx][midx] = 0
		end)
	end)

	printNote("Checking images")
	local images = imageFiles(package)

	print("Checking data.lua")
	forEachOrderedElement(mdata, function(_, data)
		if data.image then
			if not images[data.image] then
				printError("Image file '"..data.image.."' does not exist in directory 'images'")
				doc_report.wrong_image = doc_report.wrong_image + 1
			else
				images[data.image] = images[data.image] + 1
			end
		end
	end)

	if doc_report.models > 0 then
		print("Checking models")
		forEachOrderedElement(result.files, function(idx, value)
			if type(idx) ~= "string" then return end
			if not string.endswith(idx, ".lua") then return end

			forEachElement(value.models, function(_, mvalue, mtype)
				if mtype == "table" and mvalue.image then
					if not images[mvalue.image] then
						printError("Image file '"..mvalue.image.."' does not exist in directory 'images'")
						doc_report.wrong_image = doc_report.wrong_image + 1
					else
						images[mvalue.image] = images[mvalue.image] + 1
					end
				end
			end)
		end)
	end

	if doc_report.examples > 0 then
		print("Checking examples")
		forEachOrderedElement(result.files, function(idx, value)
			if type(idx) ~= "string" then return end
			if not string.endswith(idx, ".lua") then return end

			if value.image then
				if not images[value.image] then
					printError("Image file '"..value.image.."' does not exist in directory 'images'")
					doc_report.wrong_image = doc_report.wrong_image + 1
				else
					images[value.image] = images[value.image] + 1
				end
			end
		end)
	end

	print("Checking if all images are used")
	forEachOrderedElement(images, function(file, value)
		if value == 0 then
			printError("Image file '"..file.."' in directory 'images' is unnecessary")
			doc_report.wrong_image = doc_report.wrong_image + 1
		end
	end)

	if doc_report.functions > 0 then
		printNote("Checking if all functions are documented")
		forEachOrderedElement(all_functions, function(idx, value)
			print("Checking "..idx)
			forEachOrderedElement(value, function(midx)
				if belong(midx, {"__len", "__tostring", "__concat", "__index", "__newindex", "__call"}) then return end -- TODO: think about this kind of function

				if not result.files[idx] or not result.files[idx].functions[midx] and
				  (not result.files[idx].models or not result.files[idx].models[midx]) then
					printError("Function "..midx.." is not documented")
					doc_report.undoc_functions = doc_report.undoc_functions + 1
				end
			end)
		end)
	end

	if doc_report.models > 0 then
		printNote("Checking if all Models are documented")

		forEachOrderedElement(result.files, function(idx, value)
			if type(idx) ~= "string" then return end
			if not string.endswith(idx, ".lua") then return end

			local documentedArguments = {}

			forEachOrderedElement(value.models, function(_, mvalue, mtype)
				if mtype ~= "table" then return end

				if type(mvalue.arg) == "table" then -- if some argument is documented
					forEachOrderedElement(mvalue.arg, function(mmidx)
						if type(mmidx) == "string" then
							documentedArguments[mmidx] = true
						end
					end)
				end
			end)

			local modelName = string.sub(idx, 0, -5)
			if value.models and type(pkg[modelName]) == "Model" then
				local args = pkg[modelName]:getParameters()

				forEachOrderedElement(args, function(midx)
					if not documentedArguments[midx] then
						printError("Model '"..modelName.."' has undocumented argument '"..midx.."'")
						doc_report.model_error = doc_report.model_error + 1
					end
				end)

				forEachOrderedElement(documentedArguments, function(midx)
					if args[midx] == nil and midx ~= "named" then
						printError("Model '"..modelName.."' does not have documented argument '"..midx.."'")
						doc_report.model_error = doc_report.model_error + 1
					end
				end)
			end
		end)
	end

	local finalTime = profiler:stop("DOC_").strTime
	print("\nDocumentation report for package '"..package.."':")
	printNote("Documentation was built in "..finalTime..".")

	if doc_report.html_files == 1 then
		printNote("One HTML file was created.")
	else
		printNote(doc_report.html_files.." HTML files were created.")
	end

	if doc_report.undoc_files == 1 then
		printError("One out of "..doc_report.lua_files.." files are not documented.")
	elseif doc_report.undoc_files > 1 then
		printError(doc_report.undoc_files.." out of "..doc_report.lua_files.." files are not documented.")
	else
		printNote("All files are documented.")
	end

	if doc_report.wrong_description == 1 then
		printError("One problem was found in 'description.lua'.")
	elseif doc_report.wrong_description > 1 then
		printError(doc_report.wrong_description.." problems were found in 'description.lua'.")
	else
		printNote("All fields of 'description.lua' are correct.")
	end

	if doc_report.error_data == 1 then
		printError("One problem was found in the documentation of data.")
	elseif doc_report.error_data > 1 then
		printError(doc_report.error_data.." problems were found in the documentation of data.")
	else
		printNote("No problems were found in the documentation of data.")
	end

	if doc_report.fonts > 0 then
		if doc_report.error_font == 1 then
			printError("One problem was found in the documentation of fonts.")
		elseif doc_report.error_font > 1 then
			printError(doc_report.error_font.." problems were found in the documentation of fonts.")
		else
			printNote("No problems were found in the documentation of fonts.")
		end
	end

	if doc_report.projects > 0 then
		if doc_report.project_error == 1 then
			printError("One problem was found while processing projects.")
		elseif doc_report.project_error > 1 then
			printError(doc_report.project_error.." problems were found while processing projects.")
		else
			printNote("All projects were successfully processed.")
		end
	end

	if doc_report.wrong_descriptions == 1 then
		printError("One description ends with wrong character.")
	elseif doc_report.wrong_descriptions > 1 then
		printError(doc_report.wrong_descriptions.." descriptions end with wrong characters.")
	else
		printNote("All descriptions end with a correct character.")
	end

	if doc_report.functions > 0 or doc_report.examples > 0 or doc_report.models > 0 then
		if doc_report.models > 0 then
			if doc_report.model_error == 0 then
				if doc_report.models == 1 then
					printNote("The single Model is correctly documented.")
				else
					printNote("All "..doc_report.models.." Models are correctly documented.")
				end
			elseif doc_report.model_error == 1 then
				printError("One error was found in the documentation of Models.")
			else
				printError(doc_report.model_error.." errors were found in the documentation of Models.")
			end
		end

		if doc_report.wrong_line == 1 then
			printError("One source code line starting with --- is invalid.")
		elseif doc_report.wrong_line > 1 then
			printError(doc_report.wrong_line.." source code lines starting with --- are invalid.")
		else
			printNote("All source code lines starting with --- are valid.")
		end

		if doc_report.undoc_functions == 1 then
			printError("One global function is not documented.")
		elseif doc_report.undoc_functions > 1 then
			printError(doc_report.undoc_functions.." global functions are not documented.")
		else
			printNote("All "..doc_report.functions.." global functions of the package are documented.")
		end

		if doc_report.duplicated_functions == 1 then
			printError("One function is declared twice in the source code.")
		elseif doc_report.duplicated_functions > 1 then
			printError(doc_report.duplicated_functions.." functions are declared twice in the source code.")
		else
			printNote("All functions of each file are declared only once.")
		end

		if doc_report.duplicated == 1 then
			printError("One tag is duplicated in the documentation.")
		elseif doc_report.duplicated > 1 then
			printError(doc_report.duplicated.." tags are duplicated in the documentation.")
		else
			printNote("There is no duplicated tag in the documentation.")
		end

		if doc_report.compulsory_arguments == 1 then
			printError("One tag should have a compulsory argument.")
		elseif doc_report.compulsory_arguments > 1 then
			printError(doc_report.compulsory_arguments.." tags should have compulsory arguments.")
		else
			printNote("All tags with compulsory arguments were correctly used.")
		end

		if doc_report.undoc_arg == 1 then
			printError("One non-named argument is not documented.")
		elseif doc_report.undoc_arg > 1 then
			printError(doc_report.undoc_arg.." non-named arguments are not documented.")
		else
			printNote("All "..doc_report.arguments.." non-named arguments are documented.")
		end

		if doc_report.undefined_arg == 1 then
			printError("One undefined argument was found.")
		elseif doc_report.undefined_arg > 1 then
			printError(doc_report.undefined_arg.." undefined arguments were found.")
		else
			printNote("No undefined arguments were found.")
		end

		if doc_report.unused_arg == 1 then
			printError("One documented argument is not used in the HTML tables.")
		elseif doc_report.unused_arg > 1 then
			printError(doc_report.unused_arg.." documented arguments are not used in the HTML tables.")
		else
			printNote("All available arguments of functions are used in their HTML tables.")
		end

		if doc_report.unknown_arg == 1 then
			printError("One argument used in the HTML tables is not documented.")
		elseif doc_report.unknown_arg > 1 then
			printError(doc_report.unknown_arg.." arguments used in the HTML tables are not documented.")
		else
			printNote("All arguments used in the HTML tables are documented.")
		end

		if doc_report.lack_usage == 1 then
			printError("One non-deprecated function does not have @usage.")
		elseif doc_report.lack_usage > 1 then
			printError(doc_report.lack_usage.." non-deprecated functions do not have @usage.")
		else
			printNote("All non-deprecated functions have @usage.")
		end

		if doc_report.no_call_itself_usage == 1 then
			printError("One out of "..doc_report.functions.." documented functions does not call itself in its @usage.")
		elseif doc_report.no_call_itself_usage > 1 then
			printError(doc_report.no_call_itself_usage.." out of "..doc_report.functions.." documented functions do not call themselves in their @usage.")
		else
			printNote("All "..doc_report.functions.." functions call themselves in their @usage.")
		end

		if doc_report.usage_error == 1 then
			printError("One out of "..doc_report.functions.." functions has error in its @usage.")
		elseif doc_report.usage_error > 1 then
			printError(doc_report.usage_error.." out of "..doc_report.functions.." functions have error in their @usage.")
		else
			printNote("All "..doc_report.functions.." functions do not have any error in their @usage.")
		end

		if doc_report.wrong_tabular == 1 then
			printError("One problem was found in @tabular.")
		elseif doc_report.wrong_tabular > 1 then
			printError(doc_report.wrong_tabular.." problems were found in @tabular.")
		else
			printNote("All @tabular are correctly described.")
		end

		if doc_report.invalid_tags == 1 then
			printError("One invalid tag was found in the documentation.")
		elseif doc_report.invalid_tags > 1 then
			printError(doc_report.invalid_tags.." invalid tags were found in the documentation.")
		else
			printNote("No invalid tags were found in the documentation.")
		end

		if doc_report.wrong_image == 1 then
			printError("One problem with image files was found.")
		elseif doc_report.wrong_image > 1 then
			printError(doc_report.wrong_image.." problems with image files were found.")
		else
			printNote("All images are correctly used.")
		end

		if doc_report.wrong_links == 1 then
			printError("One out of "..doc_report.links.." links is invalid.")
		elseif doc_report.wrong_links > 1 then
			printError(doc_report.wrong_links.." out of "..doc_report.links.." links are invalid.")
		else
			printNote("All "..doc_report.links.." links were correctly built.")
		end

		if doc_report.problem_examples == 1 then
			printError("One problem was found in the documentation of examples.")
		elseif doc_report.problem_examples > 1 then
			printError(doc_report.problem_examples.." problems were found in the documentation of examples.")
		else
			printNote("All "..doc_report.examples.." examples are correctly documented.")
		end
	end

	local errors = -doc_report.examples -doc_report.arguments - doc_report.links -doc_report.functions -doc_report.models
	               -doc_report.html_files - doc_report.lua_files - doc_report.fonts - doc_report.projects

	forEachElement(doc_report, function(_, value)
		errors = errors + value
	end)

	if errors == 0 then
		printNote("Summing up, all the documentation was successfully built.")
	elseif errors == 1 then
		printError("Summing up, one problem was found in the documentation.")
	else
		printError("Summing up, "..errors.." problems were found in the documentation.")
	end

	if errors > 255 then errors = 255 end

	return errors, all_doc_functions
end

