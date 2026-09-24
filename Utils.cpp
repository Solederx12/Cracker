#include "Utils.h"

#include <format>
#include <random>
#include <Windows.h>

//#include "skCrypt.h"
#include "Memory.h"

std::string GetLastErrorAsString(DWORD errorCode)
{
    LPSTR       msgBuffer = nullptr;
    std::string msg("");

    if (errorCode != 0)
    {
        SIZE_T size = FormatMessageA(FORMAT_MESSAGE_ALLOCATE_BUFFER |
            FORMAT_MESSAGE_FROM_SYSTEM |
            FORMAT_MESSAGE_IGNORE_INSERTS,
            NULL,
            errorCode,
            MAKELANGID(LANG_NEUTRAL,
                SUBLANG_DEFAULT),
            (LPSTR)&msgBuffer,
            0,
            NULL);
        msg = std::string(msgBuffer, size);

        LocalFree(msgBuffer);
    }

    return msg;
}

void fatal(const char* error, const char* _where, UINT32 errorCode)
{
    std::string errorMsg = GetLastErrorAsString(static_cast<DWORD>(errorCode));
    std::string message;

    auto __error = "Error: {}\n";
    auto __where = "Where: {}\n";
    auto __reason = "Reason: {}\n";
    auto __title = "Fatal Error";

    message.reserve(50UL);
    message  = std::format("Error: {}\n", error);
    message += std::format("Where: {}\n", _where);
    message += std::format("Reason: {}\n", errorMsg.c_str());

    MessageBox(nullptr, message.c_str(), __title, MB_OK | MB_ICONERROR);


    exit(EXIT_FAILURE);
}

void notifyUser(const char* message, const char* title)
{
    MessageBox(nullptr, message, title, MB_OK | MB_TOPMOST);
}


int getRandomInt(const int& min, const int& max)
{
    std::random_device rd;
    std::mt19937 rng(rd());
    std::uniform_int_distribution<int> uni(min, max);

    return uni(rng);
}

float getRandomFloat(const float& min, const float& max)
{
    std::random_device rd;
    std::mt19937 rng(rd());
    std::uniform_real_distribution<float> uni(min, max);

    return uni(rng);
}