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

#include "QGisProject.h"

#include <boost/smart_ptr/make_unique.hpp>

terrame::qgis::QGisProject::QGisProject() {}
terrame::qgis::QGisProject::~QGisProject() {}

std::string terrame::qgis::QGisProject::getFile()
{
	return file;
}

void terrame::qgis::QGisProject::setFile(const std::string & filepath)
{
	this->file = filepath;
}

std::string terrame::qgis::QGisProject::getTitle()
{
	return title;
}

void terrame::qgis::QGisProject::setTitle(const std::string& title)
{
	this->title = title;
}

std::string terrame::qgis::QGisProject::getAuthor()
{
	return author;
}

void terrame::qgis::QGisProject::setAuthor(const std::string& author)
{
	this->author = author;
}

int terrame::qgis::QGisProject::getVersion()
{
	return version;
}

void terrame::qgis::QGisProject::setVersion(int version)
{
	this->version = version;
}

void terrame::qgis::QGisProject::addLayer(terrame::qgis::QGisLayer* layer)
{
	std::unique_ptr<QGisLayer> nl = boost::make_unique<QGisLayer>(*layer);
	layers.push_back(nl.release());
}

std::vector<terrame::qgis::QGisLayer*> terrame::qgis::QGisProject::getLayers() const
{
	return layers;
}

bool terrame::qgis::QGisProject::hasLayer(const terrame::qgis::QGisLayer* layer)
{
	for (unsigned int i = 0; i < layers.size(); i++)
	{
		if (layers.at(i)->equals(layer))
		{
			return true;
		}
	}
	return false;
}

terrame::qgis::QGisLayer* terrame::qgis::QGisProject::getLayerByName(const std::string& name)
{
	for(int i = 0; i < layers.size(); i++)
	{
		if(layers.at(i)->getName() == name)
		{
			return layers.at(i);
		}
	}

	return nullptr;
}
