/************************************************************************************
TerraME - a software platform for multiple scale spatially-explicit dynamic modeling.
Copyright (C) 2001-2017 INPE and TerraLAB/UFOP -- www.terrame.org

This code is part of the TerraME framework.
This framework is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

You should have received a copy of the GNU Lesser General Public
License along with this library.

The authors reassure the license terms regarding the warranties.
They specifically disclaim any warranties, including, but not limited to,
the implied warranties of merchantability and fitness for a particular purpose.
The framework provided hereunder is on an "as is" basis, and the authors have no
obligation to provide maintenance, support, updates, enhancements, or modifications.
In no event shall INPE and TerraLAB / UFOP be held liable to any party for direct,
indirect, special, incidental, or consequential damages arising out of the use
of this software and its documentation.
*************************************************************************************/

#include "Utils.h"

#include <boost/tokenizer.hpp>
#include <boost/algorithm/string.hpp>

std::map<std::string, std::string> terrame::qgis::createAttributesMap(const std::string& content,
																	const std::string& separator)
{
	boost::char_separator<char> sep(separator.c_str());
	boost::tokenizer<boost::char_separator<char>> tokens(content, sep);
	std::map<std::string, std::string> contents;

	for(boost::tokenizer< boost::char_separator<char> >::iterator it = tokens.begin();
		it != tokens.end(); it++)
	{
		std::string token(*it);

		if (token.find("=") != std::string::npos)
		{
			std::vector<std::string> values;
			boost::split(values, token, boost::is_any_of("="));
			std::string key = values.at(0);
			std::string value = values.at(1);
			if(key == "url")
			{
				for (int i = 2; i < values.size(); i++)
				{
					value += "=" + values[i];
				}
			}
			boost::replace_all(key, "'", "");
			boost::replace_all(value, "'", "");
			boost::replace_all(value, "\"", "");
			contents.insert(std::pair<std::string, std::string>(key, value));
		}
	}

	return contents;
}
