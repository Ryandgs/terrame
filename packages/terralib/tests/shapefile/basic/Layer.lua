-------------------------------------------------------------------------------------------
-- TerraME - a software platform for multiple scale spatially-explicit dynamic modeling.
-- Copyright (C) 2001-2016 INPE and TerraLAB/UFOP -- www.terrame.org

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

return {
	CellularLayer = function(unitTest)
		local projName = "cellular_layer_basic.tview"

		if isFile(projName) then
			os.execute("rm -f "..projName)
		end
		
		-- ###################### 1 #############################
		local author = "Avancini"
		local title = "Cellular Layer"
	
		local proj = Project {
			file = projName,
			create = true,
			author = "Avancini",
			title = "Cellular Layer"
		}		

		local layerName1 = "Sampa"
		proj:addLayer {
			layer = layerName1,
			file = filePath("sampa.shp", "terralib")
		}	
		
		local clName1 = "Sampa_Cells_DB"
		local tName1 = "sampa_cells"
		
		local host = "localhost"
		local port = "5432"
		local user = "postgres"
		local password = "postgres"
		local database = "postgis_22_sample"
		local encoding = "CP1252"	
		
		local pgData = {
			type = "POSTGIS",
			host = host,
			port = port,
			user = user,
			password = password,
			database = database,
			table = tName1,
			encoding = encoding
		}
		
		local tl = TerraLib{}
		tl:dropPgTable(pgData)
		
		proj:addCellularLayer {
			source = "postgis",
			input = layerName1,
			layer = clName1,
			resolution = 0.3,
			user = user,
			password = password,
			database = database,
			table = tName1
		}	
		
		local cl = CellularLayer{
			project = proj,
			layer = clName1
		}		
		
		unitTest:assertEquals(projName, cl.project.file)
		unitTest:assertEquals(clName1, cl.layer)
		
		-- ###################### 2 #############################
		proj = nil
		tl = TerraLib{}
		tl:finalize()
		
		local cl2 = CellularLayer{
			project = projName,
			layer = clName1
		}
		
		local clProj = cl2.project
		local clProjInfo = clProj:info()
		
		unitTest:assertEquals(clProjInfo.title, title)
		unitTest:assertEquals(clProjInfo.author, author)
		
		local clLayerInfo = clProj:infoLayer(clName1)
		unitTest:assertEquals(clLayerInfo.source, "postgis")
		unitTest:assertEquals(clLayerInfo.host, host)
		unitTest:assertEquals(clLayerInfo.port, port)
		unitTest:assertEquals(clLayerInfo.user, user)
		unitTest:assertEquals(clLayerInfo.password, password)
		unitTest:assertEquals(clLayerInfo.database, database)
		unitTest:assertEquals(clLayerInfo.table, tName1)
		
		-- ###################### END #############################
		if isFile(projName) then
			os.execute("rm -f "..projName)
		end
		
		tl:dropPgTable(pgData)
		
		tl = TerraLib{}
		tl:finalize()		
	end,
	fillCells = function(unitTest)
		local projName = "cellular_layer_fillcells_basic.tview"

		if isFile(projName) then
			os.execute("rm -f "..projName)
		end
		
		-- ###################### 1 #############################
		local author = "Avancini"
		local title = "Cellular Layer"
	
		local proj = Project {
			file = projName,
			create = true,
			author = author,
			title = title
		}		

		local layerName1 = "Sampa"
		proj:addLayer {
			layer = layerName1,
			file = filePath("sampa.shp", "terralib")
		}	
		
		local clName1 = "Sampa_Cells_DB"
		local tName1 = "sampa_cells"
		
		local host = "localhost"
		local port = "5432"
		local user = "postgres"
		local password = "postgres"
		local database = "postgis_22_sample"
		local encoding = "CP1252"	
		
		local pgData = {
			type = "POSTGIS",
			host = host,
			port = port,
			user = user,
			password = password,
			database = database,
			table = tName1,
			encoding = encoding
		}
		
		local tl = TerraLib{}
		tl:dropPgTable(pgData)
		
		proj:addCellularLayer {
			source = "postgis",
			input = layerName1,
			layer = clName1,
			resolution = 0.9,
			user = user,
			password = password,
			database = database,
			table = tName1
		}	
		
		local cl = CellularLayer{
			project = proj,
			layer = clName1
		}
		
		local presenceLayerName = clName1.."_Presence"
		pgData.table = presenceLayerName
		tl:dropPgTable(pgData)

		cl:fillCells{
			operation = "presence",
			layer = layerName1,
			attribute = "presence",
			output = presenceLayerName
		}
		
		local presenceLayerInfo = proj:infoLayer(presenceLayerName)
		unitTest:assertEquals(presenceLayerInfo.source, "postgis")
		unitTest:assertEquals(presenceLayerInfo.host, host)
		unitTest:assertEquals(presenceLayerInfo.port, port)
		unitTest:assertEquals(presenceLayerInfo.user, user)
		unitTest:assertEquals(presenceLayerInfo.password, password)
		unitTest:assertEquals(presenceLayerInfo.database, database)
		unitTest:assertEquals(presenceLayerInfo.table, string.lower(presenceLayerName))		

		-- ###################### 2 #############################
		
		local areaLayerName = clName1.."_Area"
		pgData.table = areaLayerName
		tl:dropPgTable(pgData)
		
		local c2 = CellularLayer{
			project = proj,
			layer = presenceLayerName
		}		
		
		c2:fillCells{
			operation = "area",
			layer = layerName1,
			attribute = "area",
			output = areaLayerName
		}
		
		local areaLayerInfo = proj:infoLayer(areaLayerName)
		unitTest:assertEquals(areaLayerInfo.source, "postgis")
		unitTest:assertEquals(areaLayerInfo.host, host)
		unitTest:assertEquals(areaLayerInfo.port, port)
		unitTest:assertEquals(areaLayerInfo.user, user)
		unitTest:assertEquals(areaLayerInfo.password, password)
		unitTest:assertEquals(areaLayerInfo.database, database)
		unitTest:assertEquals(areaLayerInfo.table, string.lower(areaLayerName))			
		
		-- ###################### 3 #############################	
		local countLayerName = clName1.."_Count"
		pgData.table = countLayerName
		tl:dropPgTable(pgData)
		
		local c3 = CellularLayer{
			project = proj,
			layer = areaLayerName
		}		
		
		c3:fillCells{
			operation = "count",
			layer = layerName1,
			attribute = "count",
			output = countLayerName
		}
		
		local countLayerInfo = proj:infoLayer(countLayerName)
		unitTest:assertEquals(countLayerInfo.source, "postgis")
		unitTest:assertEquals(countLayerInfo.host, host)
		unitTest:assertEquals(countLayerInfo.port, port)
		unitTest:assertEquals(countLayerInfo.user, user)
		unitTest:assertEquals(countLayerInfo.password, password)
		unitTest:assertEquals(countLayerInfo.database, database)
		unitTest:assertEquals(countLayerInfo.table, string.lower(countLayerName))

		-- ###################### 4 #############################	
		local distanceLayerName = clName1.."_Distance"
		pgData.table = distanceLayerName
		tl:dropPgTable(pgData)	
		
		cl:fillCells{
			operation = "distance",
			layer = layerName1,
			attribute = "distance",
			output = distanceLayerName
		}
		
		local distanceLayerInfo = proj:infoLayer(distanceLayerName)
		unitTest:assertEquals(distanceLayerInfo.source, "postgis")
		unitTest:assertEquals(distanceLayerInfo.host, host)
		unitTest:assertEquals(distanceLayerInfo.port, port)
		unitTest:assertEquals(distanceLayerInfo.user, user)
		unitTest:assertEquals(distanceLayerInfo.password, password)
		unitTest:assertEquals(distanceLayerInfo.database, database)
		unitTest:assertEquals(distanceLayerInfo.table, string.lower(distanceLayerName))		

		-- ###################### 5 #############################	
		local minValueLayerName = clName1.."_Minimum"
		pgData.table = minValueLayerName
		tl:dropPgTable(pgData)	
		
		cl:fillCells{
			operation = "minimum",
			layer = layerName1,
			attribute = "minimum",
			output = minValueLayerName,
			select = "FID"
		}
		
		local minValueLayerInfo = proj:infoLayer(minValueLayerName)
		unitTest:assertEquals(minValueLayerInfo.source, "postgis")
		unitTest:assertEquals(minValueLayerInfo.host, host)
		unitTest:assertEquals(minValueLayerInfo.port, port)
		unitTest:assertEquals(minValueLayerInfo.user, user)
		unitTest:assertEquals(minValueLayerInfo.password, password)
		unitTest:assertEquals(minValueLayerInfo.database, database)
		unitTest:assertEquals(minValueLayerInfo.table, string.lower(minValueLayerName))			

		-- ###################### 6 #############################	
		local maxValueLayerName = clName1.."_Maximum"
		pgData.table = maxValueLayerName
		tl:dropPgTable(pgData)	
		
		cl:fillCells{
			operation = "maximum",
			layer = layerName1,
			attribute = "maximum",
			output = maxValueLayerName,
			select = "FID"
		}
		
		local maxValueLayerInfo = proj:infoLayer(maxValueLayerName)
		unitTest:assertEquals(maxValueLayerInfo.source, "postgis")
		unitTest:assertEquals(maxValueLayerInfo.host, host)
		unitTest:assertEquals(maxValueLayerInfo.port, port)
		unitTest:assertEquals(maxValueLayerInfo.user, user)
		unitTest:assertEquals(maxValueLayerInfo.password, password)
		unitTest:assertEquals(maxValueLayerInfo.database, database)
		unitTest:assertEquals(maxValueLayerInfo.table, string.lower(maxValueLayerName))	
		
		-- ###################### 7 #############################	
		local percentageLayerName = clName1.."_Percentage"
		pgData.table = percentageLayerName
		tl:dropPgTable(pgData)	
		
		cl:fillCells{
			operation = "percentage",
			layer = layerName1,
			attribute = "percentage",
			output = percentageLayerName,
			select = "NM_MICRO"
		}
		
		local percentageLayerInfo = proj:infoLayer(percentageLayerName)
		unitTest:assertEquals(percentageLayerInfo.source, "postgis")
		unitTest:assertEquals(percentageLayerInfo.host, host)
		unitTest:assertEquals(percentageLayerInfo.port, port)
		unitTest:assertEquals(percentageLayerInfo.user, user)
		unitTest:assertEquals(percentageLayerInfo.password, password)
		unitTest:assertEquals(percentageLayerInfo.database, database)
		unitTest:assertEquals(percentageLayerInfo.table, string.lower(percentageLayerName))	
		
		-- ###################### 8 #############################	
		local stdevLayerName = clName1.."_Stdev"
		pgData.table = stdevLayerName
		tl:dropPgTable(pgData)	
		
		cl:fillCells{
			operation = "stdev",
			layer = layerName1,
			attribute = "stdev",
			output = stdevLayerName,
			select = "FID"
		}
		
		local stdevLayerInfo = proj:infoLayer(stdevLayerName)
		unitTest:assertEquals(stdevLayerInfo.source, "postgis")
		unitTest:assertEquals(stdevLayerInfo.host, host)
		unitTest:assertEquals(stdevLayerInfo.port, port)
		unitTest:assertEquals(stdevLayerInfo.user, user)
		unitTest:assertEquals(stdevLayerInfo.password, password)
		unitTest:assertEquals(stdevLayerInfo.database, database)
		unitTest:assertEquals(stdevLayerInfo.table, string.lower(stdevLayerName))
		
		-- ###################### 9 #############################	
		local meanLayerName = clName1.."_Average_Mean"
		pgData.table = meanLayerName
		tl:dropPgTable(pgData)	
		
		cl:fillCells{
			operation = "average",
			layer = layerName1,
			attribute = "mean",
			output = meanLayerName,
			select = "FID"
		}
		
		local meanLayerInfo = proj:infoLayer(meanLayerName)
		unitTest:assertEquals(meanLayerInfo.source, "postgis")
		unitTest:assertEquals(meanLayerInfo.host, host)
		unitTest:assertEquals(meanLayerInfo.port, port)
		unitTest:assertEquals(meanLayerInfo.user, user)
		unitTest:assertEquals(meanLayerInfo.password, password)
		unitTest:assertEquals(meanLayerInfo.database, database)
		unitTest:assertEquals(meanLayerInfo.table, string.lower(meanLayerName))		

		-- ###################### 10 #############################	
		local weighLayerName = clName1.."_Average_Weighted"
		pgData.table = weighLayerName
		tl:dropPgTable(pgData)	
		
		cl:fillCells{
			operation = "average",
			layer = layerName1,
			attribute = "weighted",
			output = weighLayerName,
			select = "FID",
			area = true
		}
		
		local weighLayerInfo = proj:infoLayer(weighLayerName)
		unitTest:assertEquals(weighLayerInfo.source, "postgis")
		unitTest:assertEquals(weighLayerInfo.host, host)
		unitTest:assertEquals(weighLayerInfo.port, port)
		unitTest:assertEquals(weighLayerInfo.user, user)
		unitTest:assertEquals(weighLayerInfo.password, password)
		unitTest:assertEquals(weighLayerInfo.database, database)
		unitTest:assertEquals(weighLayerInfo.table, string.lower(weighLayerName))

		-- ###################### 11 #############################	
		local intersecLayerName = clName1.."_Majority_Intersection"
		pgData.table = intersecLayerName
		tl:dropPgTable(pgData)	
		
		cl:fillCells{
			operation = "majority",
			layer = layerName1,
			attribute = "high_intersection",
			output = intersecLayerName,
			select = "CD_GEOCODU",
			area = true
		}
		
		local intersecLayerInfo = proj:infoLayer(intersecLayerName)
		unitTest:assertEquals(intersecLayerInfo.source, "postgis")
		unitTest:assertEquals(intersecLayerInfo.host, host)
		unitTest:assertEquals(intersecLayerInfo.port, port)
		unitTest:assertEquals(intersecLayerInfo.user, user)
		unitTest:assertEquals(intersecLayerInfo.password, password)
		unitTest:assertEquals(intersecLayerInfo.database, database)
		unitTest:assertEquals(intersecLayerInfo.table, string.lower(intersecLayerName))
		
		-- ###################### 12 #############################	
		local occurrenceLayerName = clName1.."_Majority_Occurrence"
		pgData.table = occurrenceLayerName
		tl:dropPgTable(pgData)	
		
		cl:fillCells{
			operation = "majority",
			layer = layerName1,
			attribute = "high_occurrence",
			output = occurrenceLayerName,
			select = "CD_GEOCODU"
		}
		
		local occurrenceLayerInfo = proj:infoLayer(occurrenceLayerName)
		unitTest:assertEquals(occurrenceLayerInfo.source, "postgis")
		unitTest:assertEquals(occurrenceLayerInfo.host, host)
		unitTest:assertEquals(occurrenceLayerInfo.port, port)
		unitTest:assertEquals(occurrenceLayerInfo.user, user)
		unitTest:assertEquals(occurrenceLayerInfo.password, password)
		unitTest:assertEquals(occurrenceLayerInfo.database, database)
		unitTest:assertEquals(occurrenceLayerInfo.table, string.lower(occurrenceLayerName))		

		-- ###################### 13 #############################	
		local sumLayerName = clName1.."_Sum"
		pgData.table = sumLayerName
		tl:dropPgTable(pgData)	
		
		cl:fillCells{
			operation = "sum",
			layer = layerName1,
			attribute = "sum",
			output = sumLayerName,
			select = "FID"
		}
		
		local sumLayerInfo = proj:infoLayer(sumLayerName)
		unitTest:assertEquals(sumLayerInfo.source, "postgis")
		unitTest:assertEquals(sumLayerInfo.host, host)
		unitTest:assertEquals(sumLayerInfo.port, port)
		unitTest:assertEquals(sumLayerInfo.user, user)
		unitTest:assertEquals(sumLayerInfo.password, password)
		unitTest:assertEquals(sumLayerInfo.database, database)
		unitTest:assertEquals(sumLayerInfo.table, string.lower(sumLayerName))

		-- ###################### 14 #############################	
		local wsumLayerName = clName1.."_Weighted_Sum"
		pgData.table = wsumLayerName
		tl:dropPgTable(pgData)	
		
		cl:fillCells{
			operation = "sum",
			layer = layerName1,
			attribute = "wsum",
			output = wsumLayerName,
			select = "FID",
			area = true
		}
		
		local wsumLayerInfo = proj:infoLayer(wsumLayerName)
		unitTest:assertEquals(wsumLayerInfo.source, "postgis")
		unitTest:assertEquals(wsumLayerInfo.host, host)
		unitTest:assertEquals(wsumLayerInfo.port, port)
		unitTest:assertEquals(wsumLayerInfo.user, user)
		unitTest:assertEquals(wsumLayerInfo.password, password)
		unitTest:assertEquals(wsumLayerInfo.database, database)
		unitTest:assertEquals(wsumLayerInfo.table, string.lower(wsumLayerName))		
		
		-- RASTER TESTS ------------------------------------------	
		-- ###################### 15 #############################
		local layerName2 = "Setores"
		proj:addLayer {
			layer = layerName2,
			file = filePath("Setores_Censitarios_2000_pol.shp", "fillcell")		
		}
		
		local layerName3 = "Desmatamento"
		proj:addLayer {
			layer = layerName3,
			file = filePath("Desmatamento_2000.tif", "fillcell")		
		}			
		
		local tName2 = "setores_cells"
		local clName2 = "Setores_Cells"
		
		pgData.table = tName2
		tl:dropPgTable(pgData)
		
		proj:addCellularLayer {
			source = "postgis",
			input = layerName2,
			layer = clName2,
			resolution = 3e4,
			user = user,
			password = password,
			database = database,
			table = tName2
		}		
		
		local rmeanLayerName = clName2.."_Mean"
		pgData.table = rmeanLayerName
		tl:dropPgTable(pgData)
		
		local c4 = CellularLayer{
			project = proj,
			layer = clName2
		}		
		
		c4:fillCells{
			operation = "average",
			layer = layerName3,
			attribute = "mean",
			output = rmeanLayerName,
			select = 0
		}		

		local rmeanLayerInfo = proj:infoLayer(rmeanLayerName)
		unitTest:assertEquals(rmeanLayerInfo.source, "postgis")
		unitTest:assertEquals(rmeanLayerInfo.host, host)
		unitTest:assertEquals(rmeanLayerInfo.port, port)
		unitTest:assertEquals(rmeanLayerInfo.user, user)
		unitTest:assertEquals(rmeanLayerInfo.password, password)
		unitTest:assertEquals(rmeanLayerInfo.database, database)
		unitTest:assertEquals(rmeanLayerInfo.table, string.lower(rmeanLayerName))	
		
		-- ###################### 16 #############################
		local rminLayerName = clName2.."_Minimum"
		pgData.table = rminLayerName
		tl:dropPgTable(pgData)
		
		c4:fillCells{
			operation = "minimum",
			layer = layerName3,
			attribute = "minimum",
			output = rminLayerName,
			select = 0
		}		

		local rminLayerInfo = proj:infoLayer(rminLayerName)
		unitTest:assertEquals(rminLayerInfo.source, "postgis")
		unitTest:assertEquals(rminLayerInfo.host, host)
		unitTest:assertEquals(rminLayerInfo.port, port)
		unitTest:assertEquals(rminLayerInfo.user, user)
		unitTest:assertEquals(rminLayerInfo.password, password)
		unitTest:assertEquals(rminLayerInfo.database, database)
		unitTest:assertEquals(rminLayerInfo.table, string.lower(rminLayerName))	

		-- ###################### 17 #############################
		local rmaxLayerName = clName2.."_Maximum"
		pgData.table = rmaxLayerName
		tl:dropPgTable(pgData)
		
		c4:fillCells{
			operation = "maximum",
			layer = layerName3,
			attribute = "maximum",
			output = rmaxLayerName,
			select = 0
		}		

		local rmaxLayerInfo = proj:infoLayer(rmaxLayerName)
		unitTest:assertEquals(rmaxLayerInfo.source, "postgis")
		unitTest:assertEquals(rmaxLayerInfo.host, host)
		unitTest:assertEquals(rmaxLayerInfo.port, port)
		unitTest:assertEquals(rmaxLayerInfo.user, user)
		unitTest:assertEquals(rmaxLayerInfo.password, password)
		unitTest:assertEquals(rmaxLayerInfo.database, database)
		unitTest:assertEquals(rmaxLayerInfo.table, string.lower(rmaxLayerName))		

		-- ###################### 18 #############################
		local rpercentLayerName = clName2.."_Percentage"
		pgData.table = rpercentLayerName
		tl:dropPgTable(pgData)
		
		c4:fillCells{
			operation = "percentage",
			layer = layerName3,
			attribute = "percentage",
			output = rpercentLayerName,
			select = 0
		}		

		local rpercentLayerInfo = proj:infoLayer(rpercentLayerName)
		unitTest:assertEquals(rpercentLayerInfo.source, "postgis")
		unitTest:assertEquals(rpercentLayerInfo.host, host)
		unitTest:assertEquals(rpercentLayerInfo.port, port)
		unitTest:assertEquals(rpercentLayerInfo.user, user)
		unitTest:assertEquals(rpercentLayerInfo.password, password)
		unitTest:assertEquals(rpercentLayerInfo.database, database)
		unitTest:assertEquals(rpercentLayerInfo.table, string.lower(rpercentLayerName))

		-- ###################### 19 #############################
		local rstdevLayerName = clName2.."_Stdev"
		pgData.table = rstdevLayerName
		tl:dropPgTable(pgData)
		
		c4:fillCells{
			operation = "stdev",
			layer = layerName3,
			attribute = "stdev",
			output = rstdevLayerName,
			select = 0
		}		

		local rstdevLayerInfo = proj:infoLayer(rstdevLayerName)
		unitTest:assertEquals(rstdevLayerInfo.source, "postgis")
		unitTest:assertEquals(rstdevLayerInfo.host, host)
		unitTest:assertEquals(rstdevLayerInfo.port, port)
		unitTest:assertEquals(rstdevLayerInfo.user, user)
		unitTest:assertEquals(rstdevLayerInfo.password, password)
		unitTest:assertEquals(rstdevLayerInfo.database, database)
		unitTest:assertEquals(rstdevLayerInfo.table, string.lower(rstdevLayerName))

		-- ###################### 20 #############################
		local rsumLayerName = clName2.."_Sum"
		pgData.table = rsumLayerName
		tl:dropPgTable(pgData)
		
		c4:fillCells{
			operation = "sum",
			layer = layerName3,
			attribute = "sum",
			output = rsumLayerName,
			select = 0
		}		

		local rsumLayerInfo = proj:infoLayer(rsumLayerName)
		unitTest:assertEquals(rsumLayerInfo.source, "postgis")
		unitTest:assertEquals(rsumLayerInfo.host, host)
		unitTest:assertEquals(rsumLayerInfo.port, port)
		unitTest:assertEquals(rsumLayerInfo.user, user)
		unitTest:assertEquals(rsumLayerInfo.password, password)
		unitTest:assertEquals(rsumLayerInfo.database, database)
		unitTest:assertEquals(rsumLayerInfo.table, string.lower(rsumLayerName))		

		-- CELLULAR SPACE TESTS ---------------------------------------------------
		-- ###################### 21 #############################
		local cs = CellularSpace{
			project = proj,
			layer = rsumLayerName
		}
		
		forEachCell(cs, function(cell)
			cell.past_sum = cell.sum
			cell.sum = cell.sum + 10000
		end)		
		
		local cellSpaceLayerName = clName2.."_CellSpace_Sum"
		
		pgData.table = string.lower(cellSpaceLayerName)
		tl:dropPgTable(pgData)			
		
		cs:save(cellSpaceLayerName, "past_sum")
		
		local cellSpaceLayerInfo = proj:infoLayer(cellSpaceLayerName)
		unitTest:assertEquals(cellSpaceLayerInfo.source, "postgis")
		unitTest:assertEquals(cellSpaceLayerInfo.host, host)
		unitTest:assertEquals(cellSpaceLayerInfo.port, port)
		unitTest:assertEquals(cellSpaceLayerInfo.user, user)
		unitTest:assertEquals(cellSpaceLayerInfo.password, password)
		unitTest:assertEquals(cellSpaceLayerInfo.database, database)
		unitTest:assertEquals(cellSpaceLayerInfo.table, cellSpaceLayerName)	-- TODO: VERIFY LOWER CASE IF CHANGED

		-- ###################### END #############################
		if isFile(projName) then
			os.execute("rm -f "..projName)
		end
		
		pgData.table = string.lower(tName1)
		tl:dropPgTable(pgData)
		pgData.table = string.lower(presenceLayerName)
		tl:dropPgTable(pgData)
		pgData.table = string.lower(areaLayerName)
		tl:dropPgTable(pgData)
		pgData.table = string.lower(countLayerName)
		tl:dropPgTable(pgData)		
		pgData.table = string.lower(distanceLayerName)
		tl:dropPgTable(pgData)			
		pgData.table = string.lower(minValueLayerName)
		tl:dropPgTable(pgData)	
		pgData.table = string.lower(maxValueLayerName)
		tl:dropPgTable(pgData)	
		pgData.table = string.lower(percentageLayerName)
		tl:dropPgTable(pgData)	
		pgData.table = string.lower(stdevLayerName)
		tl:dropPgTable(pgData)	
		pgData.table = string.lower(meanLayerName)
		tl:dropPgTable(pgData)	
		pgData.table = string.lower(weighLayerName)
		tl:dropPgTable(pgData)
		pgData.table = string.lower(intersecLayerName)
		tl:dropPgTable(pgData)	
		pgData.table = string.lower(occurrenceLayerName)
		tl:dropPgTable(pgData)		
		pgData.table = string.lower(sumLayerName)
		tl:dropPgTable(pgData)	
		pgData.table = string.lower(wsumLayerName)
		tl:dropPgTable(pgData)	
		pgData.table = string.lower(tName2)
		tl:dropPgTable(pgData)
		pgData.table = string.lower(rmeanLayerName)
		tl:dropPgTable(pgData)		
		pgData.table = string.lower(rminLayerName)
		tl:dropPgTable(pgData)			
		pgData.table = string.lower(rmaxLayerName)
		tl:dropPgTable(pgData)			
		pgData.table = string.lower(rpercentLayerName)
		tl:dropPgTable(pgData)		
		pgData.table = string.lower(rstdevLayerName)
		tl:dropPgTable(pgData)		
		pgData.table = string.lower(rsumLayerName)
		tl:dropPgTable(pgData)	
		pgData.table = string.lower(cellSpaceLayerName)
		tl:dropPgTable(pgData)
		
		tl:finalize()		
	end
}