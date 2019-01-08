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

return{
	area = function(unitTest)
		local projName = "cell_area.tview"

		local author = "Avancini"
		local title = "Cellular Space"

		local gis = getPackage("gis")

		local proj = gis.Project{
			file = projName,
			clean = true,
			author = author,
			title = title
		}

		local layerName1 = "Brazil"

		gis.Layer{
			project = proj,
			name = layerName1,
			file = filePath("brazilstates.shp", "base"),
			epsg = 4326
		}

		-- SHAPE
		local shp1 = "brazil_cells.shp"
		local filePath1 = currentDir()..shp1

		File(filePath1):deleteIfExists()

		local clName1 = "Brazil_Cells"
		gis.Layer{
			project = proj,
			input = layerName1,
			name = clName1,
			resolution = 100e3,
			file = filePath1,
			progress = false
		}

		local cs = CellularSpace{
			project = projName,
			layer = clName1
		}

		for _ = 1, 10 do
			unitTest:assertEquals(cs:sample():area(), 10000000000)
		end

		-- POSTGIS
		local clName2 = "Brazil_Cells_PG"
		local password = getConfig().password
		local database = "postgis_22_sample"

		local pgLayer = gis.Layer{
			project = proj,
			source = "postgis",
			input = layerName1,
			name = clName2,
			resolution = 100e3,
			password = password,
			database = database,
			clean = true,
			progress = false
		}

		cs = CellularSpace{
			project = projName,
			layer = clName2
		}

		for _ = 1, 10 do
			unitTest:assertEquals(cs:sample():area(), 10000000000)
		end

		File(projName):deleteIfExists()
		File(filePath1):deleteIfExists()

		pgLayer:delete()
	end,
	distance = function(unitTest)
		local projName = "cell_area.tview"

		local author = "Avancini"
		local title = "Cellular Space"

		local gis = getPackage("gis")

		local proj = gis.Project{
			file = projName,
			clean = true,
			author = author,
			title = title
		}

		local layerName1 = "Brazil"

		gis.Layer{
			project = proj,
			name = layerName1,
			file = filePath("brazilstates.shp", "base"),
			epsg = 4326
		}

		-- SHAPE
		local shp1 = "brazil_cells.shp"
		local filePath1 = currentDir()..shp1

		File(filePath1):deleteIfExists()

		local clName1 = "Brazil_Cells"
		gis.Layer{
			project = proj,
			input = layerName1,
			name = clName1,
			resolution = 100e3,
			file = filePath1,
			progress = false
		}

		local cs = CellularSpace{
			project = projName,
			layer = clName1
		}

		local cell = cs.cells[1]
		unitTest:assertEquals(cell:distance(cell), 0)

		local othercell = cs.cells[#cs - 1]
		local dist = cell:distance(othercell)

		unitTest:assertEquals(dist, 4257933.7712088, 1.0e-7)

		-- POSTGIS
		local clName2 = "Brazil_Cells_PG"
		local password = "postgres"
		local database = "postgis_22_sample"

		local pgLayer = gis.Layer{
			project = proj,
			source = "postgis",
			input = layerName1,
			name = clName2,
			resolution = 100e3,
			password = password,
			database = database,
			clean = true,
			progress = false
		}

		cs = CellularSpace{
			project = projName,
			layer = clName2
		}

		cell = cs.cells[1]
		unitTest:assertEquals(cell:distance(cell), 0)

		othercell = cs.cells[#cs - 1]
		dist = cell:distance(othercell)

		unitTest:assertEquals(dist, 4257933.7712088, 1.0e-7)

		File(projName):deleteIfExists()
		File(filePath1):deleteIfExists()

		pgLayer:delete()
	end
}
