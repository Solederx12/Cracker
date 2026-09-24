#pragma once

#include <basetsd.h>



struct GlobalVars;

struct MenuManager
{

	static INT32 menuState(GlobalVars* globalVars);


	static bool isInGame(GlobalVars* globalVars);

private:
	struct Offsets
	{
		static constexpr UINT32 StateManager = 0x2A0UL;
	};
};
