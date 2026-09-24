#include "MenuManager.h"


#include "GlobalVars.h"
#include "Memory.h"
#include "Offsets.h"

bool MenuManager::isInGame(GlobalVars* globalVars)
{

	return true;
	//auto getted = MenuManager::menuState(globalVars);
	//return true;
	//return (getted == 4); // inMenu = state == 3
}



INT32 MenuManager::menuState(GlobalVars* globalVars)
{
	UINT32 stateManager, objectEntry, lastObject, objectCount, buffer, stateAddress;


	//auto testGlobal = globalVars->memory->read<UINT32>(globalVars->sharedMenuManager + );
	stateManager = globalVars->memory->read<UINT32>(globalVars->sharedMenuManager + 0x278);
	//stateManager = globalVars->memory->read<UINT32>(stateManager + 0x2A0);
	/*stateManager = globalVars->memory->read<UINT32>(globalVars->sharedMenuManager + Offsets::StateManager);*/
	buffer = globalVars->memory->read<UINT32>(stateManager + 0x4UL);
	objectCount = globalVars->memory->read<UINT32>(buffer + 0x4UL);
	objectEntry = globalVars->memory->read<UINT32>(buffer + 0xCUL);
	lastObject = globalVars->memory->read<UINT32>(objectEntry + objectCount * 0x4UL - 0x4UL);
	stateAddress = lastObject;
	if (stateAddress) {
		stateAddress += 0xCUL;
		auto result = globalVars->memory->read<INT32>(stateAddress);
		return globalVars->memory->read<INT32>(stateAddress);
	}

	return stateManager;
}
