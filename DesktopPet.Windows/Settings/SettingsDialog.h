#pragma once
#include <windows.h>
#include <string>

struct AppSettings;

void showSettingsDialog(HWND parent, AppSettings& settings, bool* removedOut = nullptr);
std::wstring openFileDialog(HWND parent);
