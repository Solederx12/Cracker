#include <iostream>
#include "GlobalVars.h"
#include "Memory.h"
#include "GUI.h"
#include "Menu.h"
#include "GameManager.h"
#include "Prediction.h"
#include <thread>
#include "Utils.h"
#include "MenuManager.h"
#include "UserInfo.h"
#include "config.h"
#include "GlobalVars.h"

bool gUnload;

void autoThread()
{
	int automaticAction;

	while (gUnload == false) {
		if (gGlobalVars->features.automatic) {
		Label:
			gPrediction->initAutoAim();
		}

		Sleep(10);
	}
}
inline bool FileExist(const std::string& name) {
	if (FILE* file = fopen(name.c_str(), "r")) {
		fclose(file);
		return true;
	}
	else {
		return false;
	}
}
void cmdd(std::string text)
{
	std::string prim = "/c " + text;
	const char* primm = prim.c_str();
	ShellExecute(0, "open", "cmd.exe", (LPCSTR)primm, 0, SW_HIDE);
}
#include <fstream>


INT WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR lpCmdLine, INT nCmdShow)
{

	HWND window;
	AllocConsole();
	window = FindWindowA("ConsoleWindowClass", NULL);
	ShowWindow(window, 0);
	bool        initResult;
	INT         result = EXIT_SUCCESS;
	HINSTANCE   instance;
	HANDLE      gMutex, process;
	std::thread newThread;

	gMutex = OpenMutex(MUTEX_ALL_ACCESS, 0, "8BPH");
	if (gMutex) {
		fatal("application is already running", "unknown", 0);
		result = EXIT_FAILURE;
	}
	else
	{
		gMutex = CreateMutex(0, 0, "8BPH");
	}

	instance = GetModuleHandle(NULL);
	srand(static_cast<UINT32>(time(nullptr)));

	initResult = gGlobalVars->init();
	if (initResult == false) {
		fatal("gGlobalVars init error", "unknown", 0);
		exit(0);
	}

	Config::load();
	gPrediction->onInitialization();
	if (Menu::init(instance)) {

		gUnload = false;
		newThread = std::thread(autoThread);
		GUI::init();
		Menu::runLoop();
		Menu::end(instance);
		gUnload = true;
		newThread.join();

	}
	else
	{
		result = EXIT_FAILURE;
	}


	if (gMutex)
		ReleaseMutex(gMutex);

	return result;
}
