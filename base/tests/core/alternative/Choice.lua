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
-- indirect, special, incidental, or consequential damages arising out of the use
-- of this library and its documentation.
--
-- Authors: Tiago Garcia de Senna Carneiro (tiago@dpi.inpe.br)
--          Pedro R. Andrade (pedro.andrade@inpe.br)
-------------------------------------------------------------------------------------------

return{
	Choice = function(unitTest)
		local error_func = function()
			local c = Choice()
		end
		unitTest:assert_error(error_func, tableArgumentMsg())

		error_func = function()
			local c = Choice{}
		end
		unitTest:assert_error(error_func, "There are no options for the Choice (table is empty).")

		error_func = function()
			local c = Choice{1, 2, "3"}
		end
		unitTest:assert_error(error_func, "All the elements of Choice should have the same type.")

		error_func = function()
			local c = Choice{1, 2, 3, default = 1}
		end
		unitTest:assert_error(error_func, defaultValueMsg("default", 1))

		error_func = function()
			local c = Choice{1, 2, 3, default = 4}
		end
		unitTest:assert_error(error_func, "Default value (4) does not belong to Choice.")

		error_func = function()
			local c = Choice{1, 2, 3, max = 4}
		end
		unitTest:assert_error(error_func, unnecessaryArgumentMsg("max"))

		error_func = function()
			local c = Choice{false, true}
		end
		unitTest:assert_error(error_func, "The elements should be number or string, got boolean.")

		error_func = function()
			local c = Choice{min = false}
		end
		unitTest:assert_error(error_func, incompatibleTypeMsg("min", "number", false))

		error_func = function()
			local c = Choice{min = 2, max = false}
		end
		unitTest:assert_error(error_func, incompatibleTypeMsg("max", "number", false))

		error_func = function()
			local c = Choice{min = 2, max = 4, step = false}
		end
		unitTest:assert_error(error_func, incompatibleTypeMsg("step", "number", false))

		error_func = function()
			local c = Choice{min = 2, max = 4, w = false}
		end
		unitTest:assert_error(error_func, unnecessaryArgumentMsg("w"))

		error_func = function()
			local c = Choice{10, 20, "30"}
		end
		unitTest:assert_error(error_func, "All the elements of Choice should have the same type.")

		error_func = function()
			local c = Choice{min = 1, max = 10, step = 1, default = 1}
		end
		unitTest:assert_error(error_func, defaultValueMsg("default", 1))

		error_func = function()
			local c = Choice{min = 1, max = 10, step = 1, default = "a"}
		end
		unitTest:assert_error(error_func, incompatibleTypeMsg("default", "number", "a"))

		error_func = function()
			local c = Choice{min = 1, max = 10, step = 1, default = 1.2}
		end
		unitTest:assert_error(error_func, "Invalid 'default' value (1.2). It could be 1 or 2.")

		error_func = function()
			local c = Choice{min = 1, max = 10, step = 1, default = 11}
		end
		unitTest:assert_error(error_func, "Argument 'default' should be less than or equal to 'max'.")

		error_func = function()
			local c = Choice{min = 1, max = 10, step = 1, default = 0}
		end
		unitTest:assert_error(error_func, "Argument 'default' should be greater than or equal to 'min'.")

		error_func = function()
			local c = Choice{min = 1, max = 0}
		end
		unitTest:assert_error(error_func, "Argument 'max' should be greater than 'min'.")

		error_func = function()
			local c = Choice{min = 1, max = 10, step = 1, default = 1}
		end
		unitTest:assert_error(error_func, defaultValueMsg("default", 1))

		error_func = function()
			local c = Choice{min = 1, max = 10, step = 4}
		end
		unitTest:assert_error(error_func, "Invalid 'max' value (10). It could be 9 or 13.")

		error_func = function()
			local c = Choice{min = 1, step = 3}
		end
		unitTest:assert_error(error_func, "It is not possible to have 'step' and not 'max'.")
	end
}


