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

Trajectory_ = {
	type_ = "Trajectory",
	--- Add a new Cell to the Trajectory. It will be added to the end of the list of Cells.
	-- @arg cell A Cell.
	-- @usage cs = CellularSpace{
	--     xdim = 10
	-- }
	--
	-- traj = Trajectory{
	--     target = cs,
	--     select = function(c)
	--         return c.x > 3
	--     end
	-- }
	--
	-- traj:add(cs:get(1, 1))
	add = function(self, cell)
		mandatoryArgument(1, "Cell", cell)

		if self:get(cell.x, cell.y) then
			customError("Cell ("..cell.x..", "..cell.y..") already belongs to the Trajectory.")
		end

		table.insert(self.cells, cell)
		self.cObj_:add(#self, cell.cObj_)
	end,
	--- Remove all Cells from the Trajectory.
	-- @usage cs = CellularSpace{
	--     xdim = 10
	-- }
	--
	-- traj = Trajectory{
	--     target = cs
	-- }
	--
	-- traj:clear()
	--
	-- print(#traj)
	clear = function(self)
		self.cells = {}
		self.cObj_:clear()
	end,
	--- Return a copy of the Trajectory. It has the same parent, select, greater and Cells.
	-- Any change in the cloned Trajectory will not affect the original one.
	-- @usage cell = Cell{
	--     cover = Random{"forest", "deforested"}
	-- }
	--
	-- cs = CellularSpace{
	--     xdim = 10,
	--     instance = cell
	-- }
	--
	-- traj = Trajectory{
	--     target = cs,
	--     select = function(c)
	--         return c.cover == "forest"
	--     end
	-- }
	--
	-- copy = traj:clone()
	-- print(#copy)
	-- print(#traj)
	clone = function(self)
		local cloneT = Trajectory{
			target = self.parent,
			select = self.select,
			greater = self.greater,
			build = false
		}

		forEachCell(self, function(cell)
			table.insert(cloneT.cells, cell)
			cloneT.cObj_:add(#cloneT.cells, cell.cObj_)
		end)

		return cloneT
	end,
	--- Apply the filter over the Cells of the Trajectory.
	-- Cells that belong to the CellularSpace but do not belong to the
	-- Trajectory are ignored. This way, this function creates a subset
	-- over the subset of the CellularSpace.
	-- @usage cell = Cell{
	--     dist = Random{min = 0, max = 50},
	--     increase = function(self)
	--         self.dist = self.dist + 2
	--     end
	-- }
	--
	-- cs = CellularSpace{
	--     xdim = 10,
	--     instance = cell
	-- }
	--
	-- traj = Trajectory{target = cs, select = function(c)
	--     return c.dist > 20
	-- end}
	--
	-- traj:increase()
	-- traj:filter()
	filter = function(self)
		local cells = self.cells
		self.cells = {}
		self.cObj_:clear()

		if type(self.select) == "function" then
			for i, cell in ipairs(cells) do
				if self.select(cell) then
					table.insert(self.cells, cell)
					self.cObj_:add(i, cell.cObj_)
				end
			end
		else
			customError("Cannot filter a Trajectory without a 'select' function.")
		end
	end,
	--- Return a Cell from the Trajectory given its x and y locations.
	-- If the Cell does not belong to the Trajectory then it will return nil.
	-- @arg xIndex The x location.
	-- @arg yIndex The y location.
	-- @usage cs = CellularSpace{xdim = 10}
	--
	-- traj = Trajectory{target = cs}
	--
	-- traj:get(1, 1)
	get = function(self, xIndex, yIndex)
		mandatoryArgument(1, "number", xIndex)
		mandatoryArgument(2, "number", yIndex)

		local result
		forEachCell(self, function(cell)
			if cell.x == xIndex and cell.y == yIndex then
				result = cell
				return false
			end
		end)
		return result
	end,
	--- Randomize the Cells of the Trajectory. It will change the traversing order used by
	-- Utils:forEachCell().
	-- @usage cs = CellularSpace{xdim = 10}
	--
	-- traj = Trajectory{target = cs}
	--
	-- traj:randomize()
	randomize = function(self)
		local randomObj = Random()

		local numcells = #self
		local cells = self.cells

		for i = numcells, 2, -1 do
			local r = randomObj:integer(1, i)
			cells[i], cells[r] = cells[r], cells[i]
		end
	end,
	--- Rebuild the Trajectory. It works as if the Trajectory was declared again with the same arguments.
	-- @usage cell = Cell{
	--     dist = Random{min = 0, max = 50}
	-- }
	--
	-- cs = CellularSpace{
	--     xdim = 10,
	--     instance = cell
	-- }
	--
	-- traj = Trajectory{
	--     target = cs,
	--     select = function(cell) return cell.dist < 20 end,
	--     greater = function(c1, c2) return c1.dist < c2.dist end
	-- }
	--
	-- print(#traj)
	-- forEachCell(cs, function(cell)
	--     cell.dist = cell.dist + 10
	-- end)
	--
	-- traj:rebuild()
	-- print(#traj)
	rebuild = function(self)
		self.cells = {}
		self.cObj_:clear()

		if type(self.select) == "function" then
			for i, cell in ipairs(self.parent.cells) do
				if self.select(cell) then
					table.insert(self.cells, cell)
					self.cObj_:add(i, cell.cObj_)
				end
			end
		else
			for i, cell in ipairs(self.parent.cells) do
				table.insert(self.cells, cell)
				self.cObj_:add(i, cell.cObj_)
			end
		end

		if self.random then
			self:randomize()
		elseif self.greater then
			self:sort()
		end
	end,
	--- Sort the current CellularSpace subset. It updates the traversing order of the Trajectory.
	-- @usage cell = Cell{
	--     dist = Random{min = 0, max = 50},
	--     increase = function(self)
	--         self.dist = self.dist + Random{min = 0, max = 3}:sample()
	--     end
	-- }
	--
	-- cs = CellularSpace{
	--     xdim = 10,
	--     instance = cell
	-- }
	--
	-- traj = Trajectory{target = cs, greater = function(c, d)
	--     return c.dist < d.dist
	-- end}
	--
	-- traj:increase()
	-- traj:sort()
	sort = function(self)
		if type(self.greater) == "function" then
			table.sort(self.cells, self.greater)
			self.cObj_:clear()
			for i, cell in ipairs(self.cells) do
				self.cObj_:add(i, cell.cObj_)
			end
		else
			customError("Cannot sort a Trajectory without a 'greater' function.")
		end
	end,
	--- Save a subset from the target CellularSpace into a file.
	-- @arg file A File which can be a .shp or .geojson extension.
	-- @arg attrs A vector with the names of the attributes to be saved.
	-- If attrs is nil, all attributes will be saved.
	-- @usage -- DONTRUN
	-- cs = CellularSpace{
	--     file = filePath("test/sampa.shp", "gis")
	-- }
	--
	-- t = Trajectory{
	--     target = cs,
	--     select = function(cell)
	--         return cell.ID % 2 == 0
	--     end
	-- }
	--
	-- t:save("odd.shp")
	save = function(self, file, attrs)
		mandatoryArgument(1, "File", file)

		local cs = self.parent

		if (attrs ~= nil) and (attrs ~= "") then
			if type(attrs) == "string" then
				attrs = {attrs}
			elseif type(attrs) ~= "table" then
				customError("Incompatible types. Argument '#2' expected table or string.")
			end

			for _, attr in pairs(attrs) do
				if not self.cells[1][attr] then
					customError("Attribute '"..attr.."' does not exist in the target CellularSpace.")
				end
			end
		end

		local from = {}

		if cs.project then
			from.project = cs.project
			from.layer = cs.layer.name
		elseif cs.file then
			from.file = cs.file
		else
			customError("Trajectory:save() only works properly when the CellularSpace is created from a project.")
		end

		local to = {
			file = tostring(file),
			type = file:extension()
		}

		local gis = getPackage("gis")
		gis.TerraLib().saveLayerAs(from, to, false, attrs, self.cells)
	end
}

setmetatable(Trajectory_, metaTableCellularSpace_)
metaTableTrajectory_ = {
	__index = Trajectory_,
	--- Retrieve the number of Cells in the Trajectory.
	-- @usage cs = CellularSpace{
	--     xdim = 10
	-- }
	--
	-- traj = Trajectory{
	--     target = cs
	-- }
	--
	-- print(#traj)
	__len = function(self)
		return #self.cells
	end,
	__tostring = _Gtme.tostring
}

--- Type that defines an ordered selection over a CellularSpace. It inherits CellularSpace;
-- therefore it is possible to apply all functions of such type to a Trajectory. For instance,
-- calling Utils:forEachCell() also traverses Trajectories.
-- @inherits CellularSpace
-- @arg data.target The CellularSpace over which the Trajectory will take place.
-- @arg data.select A function (Cell)->boolean indicating whether an Cell of the CellularSpace
-- should belong to the Trajectory. If this function returns anything but false or nil for a given
-- Cell, it will be added to the Trajectory. If this argument is missing, all Cells will be
-- included in the Trajectory.
-- @arg data.random A boolean value indicating that the Trajectory must be shuffled. The Trajectory will be
-- shuffled every time one calls Trajectory:rebuild() or when the Trajectory is an action of an Event.
-- This argument cannot be combined with argument greater.
-- @arg data.greater A function (Cell, Cell)->boolean to sort the Trajectory. Such function must
-- return true if the first Cell has priority over the second one. When using this argument,
-- Trajectory compares each pair of Cells to establish an execution order to be used by
-- Utils:forEachCell(). As default, the Trajectory will not be ordered and so Utils:forEachCell()
-- will run in the order the Cells were pushed into the CellularSpace. See
-- Utils:greaterByAttribute() for predefined options for this argument.
-- @arg data.build A boolean value indicating whether the Trajectory should be computed when
-- created. The default value is true.
-- @output cObj_ A pointer to a C++ representation of the Trajectory. Never use this object.
-- @output cells A vector of Cells pointed by the Trajectory.
-- @output parent The CellularSpace where the Trajectory takes place.
-- @output select The last function used to filter the Trajectory.
-- @output greater The last function used to sort the Trajectory.
-- @usage cell = Cell{
--     cover = Random{"forest", "deforested"},
--     dist = Random{min = 0, max = 50}
-- }
--
-- cs = CellularSpace{
--     xdim = 10,
--     instance = cell
-- }
--
-- traj = Trajectory{
--     target = cs,
--     select = function(c)
--         return c.cover == "forest"
--     end,
--     greater = function(c, d)
--         return c.dist < d.dist
--     end
-- }
--
-- traj = Trajectory{
--     target = cs,
--     greater = function(c, d)
--         return c.dist < d.dist
--     end
-- }
--
-- traj = Trajectory{
--     target = cs,
--     build = false
-- }
function Trajectory(data)
	verifyNamedTable(data)

	verifyUnnecessaryArguments(data, {"target", "build", "select", "greater", "random"})
	mandatoryTableArgument(data, "target", {"CellularSpace", "Trajectory"})

	if data.greater and data.random then
		customError("It is not possible to use arguments 'greater' and 'random' at the same time.")
	end

	defaultTableValue(data, "build", true)
	defaultTableValue(data, "random", false)

	data.parent = data.target

	-- Copy the functions from the parent to the Trajectory (only those that do not exist)
	forEachElement(data.parent, function(idx, value, mtype)
		if mtype == "function" and data[idx] == nil then
			data[idx] = value
		end
	end)

	data.target = nil

	optionalTableArgument(data, "select", "function")
	optionalTableArgument(data, "greater", "function")

	local cObj = TeTrajectory()
	data.cObj_ = cObj
	data.cells = {}

	setmetatable(data, metaTableTrajectory_)

	if data.build then
		data:rebuild()
	end

	data.build = nil
	cObj:setReference(data)

	return data
end

