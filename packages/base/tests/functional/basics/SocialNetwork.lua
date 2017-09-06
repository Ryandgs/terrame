-------------------------------------------------------------------------------------------
-- TerraME - a software platform for multiple scale spatially-explicit dynamic modeling.
-- Copyright (C) 2001-2014 INPE and TerraLAB/UFOP.
--
-- This code is part of the TerraME framework.
-- This framework is free software; you can redistribute it and/or
-- modify it under the terms of the GNU Lesser General Public
-- License as published by the Free Software Foundation; either
-- version 2.1 of the License, or (at your option) any later version.
--
-- You should have received a copy of the GNU Lesser General Public
-- License along with this library.
--
-- The authors reassure the license terms regarding the warranties.
-- They specifically disclaim any warranties, including, but not limited to,
-- the implied warranties of merchantability and fitness for a particular purpose.
-- The framework provided hereunder is on an "as is" basis, and the authors have no
-- obligation to provide maintenance, support, updates, enhancements, or modifications.
-- In no event shall INPE and TerraLAB / UFOP be held liable to any party for direct,
-- indirect, special, incidental, or caonsequential damages arising out of the use
-- of this library and its documentation.
--
-- Authors: Pedro R. Andrade (pedro.andrade@inpe.br)
--          Rodrigo Reis Pereira
-------------------------------------------------------------------------------------------

return{
	SocialNetwork = function(unitTest)
		local sntw = SocialNetwork()
		unitTest:assertType(sntw, "SocialNetwork")

		sntw = SocialNetwork()
		unitTest:assertType(sntw, "SocialNetwork")

		unitTest:assertEquals(sntw.count, 0)
		unitTest:assertEquals(#sntw.connections, 0)
		unitTest:assertEquals(#sntw.weights, 0)
	end,
	__len = function(unitTest)
		local sntw = SocialNetwork()
		local ag1 = Agent{id = "1"}

		unitTest:assertEquals(#sntw, 0)
		sntw:add(ag1)
		unitTest:assertEquals(#sntw, 1)

		sntw:remove(ag1)
		unitTest:assertEquals(#sntw, 0)
	end,
	__tostring = function(unitTest)
		local sntw = SocialNetwork()
		local ag1 = Agent{id = "1"}

		sntw:add(ag1)
		unitTest:assertEquals(tostring(sntw), [[connections  named table of size 1
count        number [1]
weights      named table of size 1
]])
	end,
	add = function(unitTest)
		local sntw = SocialNetwork()
		local ag1 = Agent{id = "1"}
		local ag2 = Agent{id = "2"}

		sntw:add(ag1)
		unitTest:assertEquals(ag1, sntw.connections["1"])
		unitTest:assertEquals(sntw.weights["1"], 1)
		unitTest:assertEquals(sntw.count, 1)

		sntw:add(ag2, 0.5)
		unitTest:assertEquals(ag1, sntw.connections["1"])
		unitTest:assertEquals(ag2, sntw.connections["2"])
		unitTest:assertEquals(sntw.weights["1"], 1)
		unitTest:assertEquals(sntw.weights["2"], 0.5)
		unitTest:assertEquals(sntw.count, 2)
	end,
	clear = function(unitTest)
		local sntw = SocialNetwork()
		local ag1 = Agent{id = "1"}
		local ag2 = Agent{id = "2"}
		local ag3 = Agent{id = "3"}

		sntw:add(ag1)
		sntw:add(ag2)
		sntw:add(ag3)

		sntw:clear()

		unitTest:assertEquals(sntw.count, 0)
		unitTest:assertEquals(#sntw.connections, 0)
		unitTest:assertEquals(#sntw.weights, 0)
	end,
	getWeight = function(unitTest)
		local sntw = SocialNetwork()
		local ag1 = Agent{id = "1"}
		local ag2 = Agent{id = "2"}
		local ag3 = Agent{id = "3"}

		sntw:add(ag1, 0.5)
		sntw:add(ag2, 0.3)
		sntw:add(ag3, 0.2)

		unitTest:assertEquals(0.5, sntw:getWeight(ag1))
		unitTest:assertEquals(0.3, sntw:getWeight(ag2))
		unitTest:assertEquals(0.2, sntw:getWeight(ag3))
	end,
	isConnection = function(unitTest)
		local sntw = SocialNetwork()
		local ag1 = Agent{id = "1"}
		local ag2 = Agent{id = "2"}
		local ag3 = Agent{id = "3"}

		sntw:add(ag1)
		sntw:add(ag2)

		unitTest:assert(sntw:isConnection(ag1))
		unitTest:assert(sntw:isConnection(ag2))
		unitTest:assert(not sntw:isConnection(ag3))
	end,
	isEmpty = function(unitTest)
		local sntw = SocialNetwork()
		local ag1 = Agent{id = "1"}

		unitTest:assert(sntw:isEmpty())
		sntw:add(ag1)
		unitTest:assert(not sntw:isEmpty())

		sntw:remove(ag1)
		unitTest:assert(sntw:isEmpty())
	end,
	remove = function(unitTest)
		local sntw = SocialNetwork()
		local ag1 = Agent{id = "1"}
		local ag2 = Agent{id = "2"}
		local ag3 = Agent{id = "3"}

		sntw:add(ag1)
		sntw:add(ag2)
		sntw:add(ag3)

		sntw:remove(ag1)
		local warning_func = function()
			sntw:remove(ag1)
		end
		unitTest:assertWarning(warning_func, "Trying to remove an Agent that does not belong to the SocialNetwork.")
		unitTest:assertEquals(#sntw, 2)
		unitTest:assert(not sntw:isConnection(ag1))

		sntw:remove(ag2)
		unitTest:assertEquals(#sntw, 1)
		unitTest:assert(not sntw:isConnection(ag2))

		sntw:remove(ag3)
		unitTest:assertEquals(#sntw, 0)
		unitTest:assert(not sntw:isConnection(ag3))
	end,
	sample = function(unitTest)
		local sntw = SocialNetwork()
		local ag1 = Agent{id = "1"}
		local ag2 = Agent{id = "2"}
		local ag3 = Agent{id = "3"}

		sntw:add(ag1)
		unitTest:assertEquals(sntw:sample(), ag1)

		sntw:add(ag2)
		unitTest:assertEquals(sntw:sample(), ag1)

		sntw:add(ag3)
		unitTest:assertEquals(sntw:sample(), ag3)
		unitTest:assertEquals(sntw:sample(), ag2)
		unitTest:assertEquals(sntw:sample(), ag1)
	end,
	setWeight = function(unitTest)
		local sntw = SocialNetwork()
		local ag1 = Agent{id = "1"}
		local ag2 = Agent{id = "2"}
		local ag3 = Agent{id = "3"}

		sntw:add(ag1, 0.5)
		sntw:add(ag2, 0.3)
		sntw:add(ag3, 0.2)

		sntw:setWeight(ag1, 0.0)
		sntw:setWeight(ag2, 0.1)
		sntw:setWeight(ag3, 0.9)

		unitTest:assertEquals(0.0, sntw:getWeight(ag1))
		unitTest:assertEquals(0.1, sntw:getWeight(ag2))
		unitTest:assertEquals(0.9, sntw:getWeight(ag3))
	end
}

