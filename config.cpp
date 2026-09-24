#include "config.h"
#include <fstream>
#include "GlobalVars.h"
//#include "skCrypt.h"
#include "UserSettings.h"
#include "json.hpp"

#define CONFIG_NAME "config.json"

void Config::save()
{
	std::ofstream  configFile;
	nlohmann::json j;

	j.emplace("colorsStyle", gGlobalVars->features.menu.colorsStyle);

	j.emplace("adBlock", gGlobalVars->features.adBlock);
	j.emplace("automatic", gGlobalVars->features.automatic);
	j.emplace("humanizedPower", gGlobalVars->features.humanizedPower);
	j.emplace("humanizedAngleRotation", gGlobalVars->features.humanizedAngleRotation);
	j.emplace("autoPlayDelay", gGlobalVars->features.autoPlayDelay);
	j.emplace("autoPlayDelayBounds[0]", gGlobalVars->features.autoPlayDelayBounds[0]);
	j.emplace("autoPlayDelayBounds[1]", gGlobalVars->features.autoPlayDelayBounds[1]);
	j.emplace("autoPlayDelayMode", gGlobalVars->features.autoPlayDelayMode);
	j.emplace("autoPlayMaxPower", gGlobalVars->features.autoPlayMaxPower);
	j.emplace("maxWinStreak", gGlobalVars->features.maxWinStreak);

	j.emplace("angleRotationStepSize", gGlobalVars->features.angleRotationStepSize);
	j.emplace("delayBetweenAngleSteps", gGlobalVars->features.delayBetweenAngleSteps);
	j.emplace("powerStepSize", gGlobalVars->features.powerStepSize);

	j.emplace("predicionPath", gGlobalVars->features.esp.predicionPath);
	j.emplace("ballLineThickness", gGlobalVars->features.esp.ballLineThickness);
	j.emplace("ballCircleFilled", gGlobalVars->features.esp.ballCircleFilled);
	j.emplace("ballCircleRadius", gGlobalVars->features.esp.ballCircleRadius);

	j.emplace("shotState", gGlobalVars->features.esp.shotState);
	j.emplace("shotStateCircleFilled", gGlobalVars->features.esp.shotStateCircleFilled);
	j.emplace("shotStateCircleRadius", gGlobalVars->features.esp.shotStateCircleRadius);
	j.emplace("shotStateCircleThickness", gGlobalVars->features.esp.shotStateCircleThickness);
	j.emplace("ballTransparency", gGlobalVars->features.esp.ballTransparency);

	j.emplace("displayPercantage", gGlobalVars->features.esp.displayPercantage);
	j.emplace("shotState", gGlobalVars->features.esp.shotState);
	j.emplace("state", gGlobalVars->features.esp.state);
	j.emplace("shotStateTransparency", gGlobalVars->features.esp.shotStateTransparency);

	j.emplace("wideGuideLine", gGlobalVars->features.esp.wideGuideLine);

	configFile = std::ofstream(CONFIG_NAME);
	configFile << std::setw(4) << j << std::endl;
	configFile.close();
}

template <typename T>
inline void loadVarible(const char* varibleName, T& data, const nlohmann::json& j)
{
	const auto& varibleData = j.find(varibleName);
	if (varibleData == j.end())
		return;

	data = (*varibleData).get<T>();
}


void Config::load()
{
	std::ifstream inputFile = std::ifstream(CONFIG_NAME);

	if (!inputFile.good())
		return;

	nlohmann::json j;

	try
	{
		inputFile >> j;
	}
	catch (...)
	{
		goto endLabel;
	}

	if (j.empty())
		goto endLabel;

	loadVarible("colorsStyle", gGlobalVars->features.menu.colorsStyle, j);

	loadVarible("adBlock", gGlobalVars->features.adBlock, j);
	loadVarible("automatic", gGlobalVars->features.automatic, j);
	loadVarible("humanizedPower", gGlobalVars->features.humanizedPower, j);
	loadVarible("humanizedAngleRotation", gGlobalVars->features.humanizedAngleRotation, j);
	loadVarible("autoPlayDelay", gGlobalVars->features.autoPlayDelay, j);
	loadVarible("autoPlayDelayBounds[0]", gGlobalVars->features.autoPlayDelayBounds[0], j);
	loadVarible("autoPlayDelayBounds[1]", gGlobalVars->features.autoPlayDelayBounds[1], j);
	loadVarible("autoPlayDelayMode", gGlobalVars->features.autoPlayDelayMode, j);
	loadVarible("autoPlayMaxPower", gGlobalVars->features.autoPlayMaxPower, j);
	loadVarible("maxWinStreak", gGlobalVars->features.maxWinStreak, j);

	loadVarible("angleRotationStepSize", gGlobalVars->features.angleRotationStepSize, j);
	loadVarible("delayBetweenAngleSteps", gGlobalVars->features.delayBetweenAngleSteps, j);
	loadVarible("powerStepSize", gGlobalVars->features.powerStepSize, j);

	loadVarible("predicionPath", gGlobalVars->features.esp.predicionPath, j);
	loadVarible("ballLineThickness", gGlobalVars->features.esp.ballLineThickness, j);
	loadVarible("ballCircleFilled", gGlobalVars->features.esp.ballCircleFilled, j);
	loadVarible("ballCircleRadius", gGlobalVars->features.esp.ballCircleRadius, j);

	loadVarible("shotState", gGlobalVars->features.esp.shotState, j);
	loadVarible("shotStateCircleFilled", gGlobalVars->features.esp.shotStateCircleFilled, j);
	loadVarible("shotStateCircleRadius", gGlobalVars->features.esp.shotStateCircleRadius, j);
	loadVarible("shotStateCircleThickness", gGlobalVars->features.esp.shotStateCircleThickness, j);
	loadVarible("ballTransparency", gGlobalVars->features.esp.ballTransparency, j);

	loadVarible("displayPercantage", gGlobalVars->features.esp.displayPercantage, j);
	loadVarible("shotState", gGlobalVars->features.esp.shotState, j);
	loadVarible("state", gGlobalVars->features.esp.state, j);
	loadVarible("shotStateTransparency", gGlobalVars->features.esp.shotStateTransparency, j);

	loadVarible("wideGuideLine", gGlobalVars->features.esp.wideGuideLine, j);

	UserSettings::setWideGuideLine(gGlobalVars, gGlobalVars->features.esp.wideGuideLine);

endLabel:
	inputFile.close();
}
