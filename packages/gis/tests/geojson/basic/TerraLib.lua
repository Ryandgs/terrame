-------------------------------------------------------------------------------------------
-- TerraME - a software platform for multiple scale spatially-explicit dynamic modeling.
-- Copyright (C) 2001-2017 INPE and TerraLAB/UFOP -- www.terrame.org

-- This code is part of the TerraME framework.
-- This framework is free software; you can redistribute it and/or
-- modify it under the terms of the GNU Lesser General Public
-- License as published by the Free Software Foundation; either
-- version 2.3 of the License, or (at your option) any later version.

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

return {
	addGeoJSONLayer = function(unitTest)
		local title = "TerraLib Tests"
		local author = "Carneiro Heitor"
		local file = "mygeojsonproject.tview"
		local proj = {}
		proj.file = file
		proj.title = title
		proj.author = author

		File(proj.file):deleteIfExists()

		TerraLib().createProject(proj, {})

		local layerName = "GeoJSONLayer"
		local layerFile = filePath("test/Setores_Censitarios_2000_pol.geojson", "gis")

		TerraLib().addGeoJSONLayer(proj, layerName, layerFile)

		local layerInfo = TerraLib().getLayerInfo(proj, layerName)

		unitTest:assertEquals(layerInfo.name, layerName)
		unitTest:assertEquals(layerInfo.file, tostring(layerFile))
		unitTest:assertEquals(layerInfo.type, "OGR")
		unitTest:assertEquals(layerInfo.rep, "polygon")

		proj.file:deleteIfExists()
	end,
	addGeoJSONCellSpaceLayer = function(unitTest)
		local title = "TerraLib Tests"
		local author = "Carneiro Heitor"
		local file = "mygeojsonproject.tview"
		local proj = {}
		proj.file = file
		proj.title = title
		proj.author = author

		File(proj.file):deleteIfExists()

		TerraLib().createProject(proj, {})

		local layerName = "GeoJSONLayer"
		local layerFile = filePath("test/es_limit_sirgas2000_5880.geojson", "gis")
		TerraLib().addGeoJSONLayer(proj, layerName, layerFile)
		local layerInfo1 = TerraLib().getLayerInfo(proj, layerName)

		local clName = "GeoJSON_Cells"
		local geojson1 = File(clName..".geojson")

		geojson1:deleteIfExists()

		local resolution = 20e3
		local mask = true
		TerraLib().addGeoJSONCellSpaceLayer(proj, layerName, clName, resolution, geojson1, mask)

		local layerInfo = TerraLib().getLayerInfo(proj, clName)

		unitTest:assertEquals(layerInfo.name, clName)
		unitTest:assertEquals(layerInfo.file, tostring(geojson1))
		unitTest:assertEquals(layerInfo.type, "OGR")
		unitTest:assertEquals(layerInfo.rep, "polygon")
		unitTest:assertEquals(layerInfo.srid, layerInfo1.srid)

		-- NO MASK TEST
		local clSetSize = TerraLib().getLayerSize(proj, clName)
		unitTest:assertEquals(clSetSize, 154)

		clName = clName.."_NoMask"
		local geojson2 = File(clName..".geojson")

		geojson2:deleteIfExists()

		mask = false
		TerraLib().addGeoJSONCellSpaceLayer(proj, layerName, clName, resolution, geojson2, mask)

		clSetSize = TerraLib().getLayerSize(proj, clName)
		unitTest:assertEquals(clSetSize, 260)
		-- // NO MASK TEST

		unitTest:assertFile(geojson1)
		unitTest:assertFile(geojson2)
		proj.file:delete()
	end,
	getDataSet = function(unitTest)
		local shpFile = filePath("test/malha2015.geojson", "gis")
		local dSet = TerraLib().getDataSet{file = shpFile}

		unitTest:assertEquals(getn(dSet), 102)

		for i = 0, getn(dSet) - 1 do
			unitTest:assertEquals(dSet[i].FID, i)

			for k, v in pairs(dSet[i]) do
				unitTest:assert((k == "FID") or (k == "NM_MUNICIP") or (k == "Proposta") or
								(k == "UF") or (k == "OGR_GEOMETRY") or (k == "masc") or
								(k == "fem") or (k == "PPA") or (k == "IBGE") or (k == "CD_GEOCMU"))
				unitTest:assertNotNil(v)
			end
		end
	end,
	saveLayerAs = function(unitTest)
		local proj = {}
		proj.file = "myproject.tview"
		proj.title = "TerraLib Tests"
		proj.author = "Avancini Rodrigo"

		File(proj.file):deleteIfExists()

		TerraLib().createProject(proj, {})

		local layerName1 = "SampaGeoJson"
		local layerFile1 = filePath("test/sampa.geojson", "gis")
		TerraLib().addGeoJSONLayer(proj, layerName1, layerFile1)

		local fromData = {}
		fromData.project = proj
		fromData.layer = layerName1

		-- SHP
		local toData = {}
		toData.file = "geojson2shp.shp"
		toData.type = "shp"
		File(toData.file):deleteIfExists()

		local overwrite = true

		TerraLib().saveLayerAs(fromData, toData, overwrite)
		unitTest:assert(File(toData.file):exists())

		-- OVERWRITE
		TerraLib().saveLayerAs(fromData, toData, overwrite)
		unitTest:assert(File(toData.file):exists())

		-- OVERWRITE AND CHANGE SRID
		toData.srid = 4326
		TerraLib().saveLayerAs(fromData, toData, overwrite)
		local layerName2 = "SHP"
		TerraLib().addShpLayer(proj, layerName2, File(toData.file))
		local info2 = TerraLib().getLayerInfo(proj, layerName2)
		unitTest:assertEquals(info2.srid, toData.srid)

		-- SAVE THE DATA WITH ONLY ONE ATTRIBUTE
		local file1 = toData.file
		toData.file = "gj2gj.geojson"
		toData.type = "geojson"
		TerraLib().saveLayerAs(fromData, toData, overwrite, {"NM_MICRO"})

		local layerName3 = "GJ2GJ"
		local layerFile3 = File(toData.file)
		TerraLib().addGeoJSONLayer(proj, layerName3, layerFile3)

		local dset3 = TerraLib().getDataSet{project = proj, layer = layerName3}

		unitTest:assertEquals(getn(dset3), 63)

		for k, v in pairs(dset3[0]) do
			unitTest:assert(((k == "FID") and (v == 0)) or ((k == "OGR_GEOMETRY") and (v ~= nil) ) or
							((k == "NM_MICRO") and (v == "VOTUPORANGA")))
		end

		File(toData.file):delete()
		File(file1):delete()

		-- SAVE A DATA SUBSET
		local dset1 = TerraLib().getDataSet{project = proj, layer = layerName1}
		local sjc
		for i = 0, getn(dset1) - 1 do
			if dset1[i].ID == 27 then
				sjc = dset1[i]
			end
		end

		local touches = {}
		local j = 1
		for i = 0, getn(dset1) - 1 do
			if sjc.OGR_GEOMETRY:touches(dset1[i].OGR_GEOMETRY) then
				touches[j] = dset1[i]
				j = j + 1
			end
		end

		toData.file = "touches_sjc.geojson"
		toData.srid = nil
		TerraLib().saveLayerAs(fromData, toData, overwrite, {"NM_MICRO", "ID"}, touches)

		local tchsSjc = TerraLib().getDataSet{file = File(toData.file)}

		unitTest:assertEquals(getn(tchsSjc), 2)
		unitTest:assertEquals(tchsSjc[0].ID, 55)
		unitTest:assertEquals(tchsSjc[1].ID, 109)

		File(toData.file):delete()
		proj.file:delete()

		-- SAVE WITHOUT LAYER
		fromData = {}
		fromData.file = layerFile1
		toData.file = "touches_sjc_2.shp"

		TerraLib().saveLayerAs(fromData, toData, overwrite, {"NM_MICRO", "ID"}, touches)

		local tchsSjc2 = TerraLib().getDataSet{file = File(toData.file)}

		unitTest:assertEquals(getn(tchsSjc2), 2)
		unitTest:assertEquals(tchsSjc2[0].ID, 55)
		unitTest:assertEquals(tchsSjc2[1].ID, 109)

		File(toData.file):delete()
	end,
	getLayerSize = function(unitTest)
		local proj = {}
		proj.file = "myproject.tview"
		proj.title = "TerraLib Tests"
		proj.author = "Avancini Rodrigo"

		local file = File(proj.file)
		file:deleteIfExists()

		TerraLib().createProject(proj, {})

		local layerName1 = "SampaGeoJson"
		local layerFile1 = filePath("test/sampa.geojson", "gis")
		TerraLib().addGeoJSONLayer(proj, layerName1, layerFile1)

		local size = TerraLib().getLayerSize(proj, layerName1)

		unitTest:assertEquals(size, 63.0)

		file:delete()
	end,
	douglasPeucker = function(unitTest)
		local proj = {}
		proj.file = "myproject.tview"
		proj.title = "TerraLib Tests"
		proj.author = "Avancini Rodrigo"

		local file = File(proj.file)
		file:deleteIfExists()

		TerraLib().createProject(proj, {})

		local lnName = "ES_Rails"
		local lnFile = filePath("test/rails.shp", "gis")
		TerraLib().addShpLayer(proj, lnName, lnFile)

		local fromData = {}
		fromData.project = proj
		fromData.layer = lnName

		local toData = {}
		toData.file = "rails.geojson"
		toData.type = "geojson"
		File(toData.file):deleteIfExists()

		TerraLib().saveLayerAs(fromData, toData, true)

		lnName = "ES_Rails_CurrDir"
		lnFile = File(toData.file)
		TerraLib().addGeoJSONLayer(proj, lnName, lnFile)

		local dpLayerName = "ES_Rails_Peucker"
		local dpFile = File(string.lower(dpLayerName)..".geojson"):deleteIfExists()
		TerraLib().douglasPeucker(proj, lnName, dpLayerName, 500)
		TerraLib().addGeoJSONLayer(proj, dpLayerName, dpFile)

		local dpSet = TerraLib().getDataSet{project = proj, layer = dpLayerName, missing = -1}
		unitTest:assertEquals(getn(dpSet), 182)

		local missingCount = 0
		for i = 0, getn(dpSet) - 1 do
			if dpSet[i].PNVCOIN == -1 then
				missingCount = missingCount + 1
			end
		end

		unitTest:assertEquals(missingCount, 177)

		local attrNames = TerraLib().getPropertyNames(proj, dpLayerName)
		unitTest:assertEquals("FID", attrNames[0])
		unitTest:assertEquals("OBSERVACAO", attrNames[3])
		unitTest:assertEquals("PRODUTOS", attrNames[6])
		unitTest:assertEquals("OPERADORA", attrNames[9])
		unitTest:assertEquals("Bitola_Ext", attrNames[12])
		unitTest:assertEquals("COD_PNV", attrNames[14])

		dpFile:delete()
		lnFile:delete()
		proj.file:delete()
	end,
	polygonize = function(unitTest)
		local proj = {}
		proj.file = "myproject.tview"
		proj.title = "TerraLib Tests"
		proj.author = "Avancini Rodrigo"

		File(proj.file):deleteIfExists()

		TerraLib().createProject(proj, {})

		local layerName = "TifLayer"
		local layerFile = filePath("emas-accumulation.tif", "gis")
		TerraLib().addGdalLayer(proj, layerName, layerFile)

		local inInfo = {
			project = proj,
			layer = layerName,
			band = 0,
		}

		local outFile = File("emas-polygonized.geojson")
		outFile:deleteIfExists()

		local outInfo = {
			type = "geojson",
			file = outFile
		}

		TerraLib().polygonize(inInfo, outInfo)

		local polyName = "Polygonized"
		TerraLib().addGeoJSONLayer(proj, polyName, outFile)
		local dsetSize = TerraLib().getLayerSize(proj, polyName)

		unitTest:assertEquals(dsetSize, 381)

		local attrNames = TerraLib().getPropertyNames(proj, polyName)
		unitTest:assertEquals("FID", attrNames[0])
		unitTest:assertEquals("id", attrNames[1])
		unitTest:assertEquals("value", attrNames[2])

		proj.file:delete()
		outFile:delete()
	end,
	attributeFill = function(unitTest)
		-- TODO (#2179)
		-- local createProject = function()
			-- local proj = {
				-- file = "attributefill_geojson_basic.tview",
				-- title = "TerraLib Tests",
				-- author = "Avancini Rodrigo"
			-- }
			-- File(proj.file):deleteIfExists()
			-- TerraLib().createProject(proj, {})
			-- return proj
		-- end

		-- local allSupportedOperation = function()
			-- local proj = createProject()

			-- local layerName1 = "ES"
			-- local layerFile1 = filePath("test/es_limit_sirgas2000_5880.geojson", "gis")
			-- TerraLib().addGeoJSONLayer(proj, layerName1, layerFile1)

			-- local files = {}

			-- local clName = "ES_Cells"
			-- files[1] = File(clName..".geojson")
			-- files[1]:deleteIfExists()
			-- local resolution = 20e3
			-- local mask = true
			-- TerraLib().addGeoJSONCellSpaceLayer(proj, layerName1, clName, resolution, files[1], mask)

			-- local layerName2 = "Protection_Unit"
			-- local layerFile2 = filePath("test/es_protected_areas_sirgas2000_5880.geojson", "gis")
			-- TerraLib().addGeoJSONLayer(proj, layerName2, layerFile2)

			-- local presLayerName = clName.."_"..layerName2.."_Presence"
			-- files[2] = File(presLayerName..".geojson")
			-- files[2]:deleteIfExists()

			-- local operation = "presence"
			-- local attribute = "presence"
			-- local select = "FID"
			-- local area = nil
			-- local default = nil
			-- TerraLib().attributeFill(proj, layerName2, clName, presLayerName, attribute, operation, select, area, default)
		-- end

		-- unitTest:assert(allSupportedOperation) -- SKIP

		unitTest:assert(true)
	end
}
