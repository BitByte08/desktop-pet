#include "SettingsDialog.h"
#include "AppSettings.h"
#include "../Resource.h"
#include <windows.h>
#include <commctrl.h>
#include <commdlg.h>
#include <algorithm>

static AppSettings* g_dlgSettings = nullptr;
static HWND g_hDlg = nullptr;
static bool g_removeRequested = false;

static void applyFromUI(HWND hDlg) {
    if (!g_dlgSettings) return;

    g_dlgSettings->playing = (IsDlgButtonChecked(hDlg, IDC_CHK_PLAYING) == BST_CHECKED);
    g_dlgSettings->alwaysOnTop = (IsDlgButtonChecked(hDlg, IDC_CHK_ONTOP) == BST_CHECKED);
    g_dlgSettings->clickThrough = (IsDlgButtonChecked(hDlg, IDC_CHK_CLICKTHRU) == BST_CHECKED);
    g_dlgSettings->lockPosition = (IsDlgButtonChecked(hDlg, IDC_CHK_LOCKPOS) == BST_CHECKED);
    g_dlgSettings->flipHorizontal = (IsDlgButtonChecked(hDlg, IDC_CHK_FLIPH) == BST_CHECKED);
    g_dlgSettings->flipVertical = (IsDlgButtonChecked(hDlg, IDC_CHK_FLIPV) == BST_CHECKED);

    g_dlgSettings->speed = (double)SendMessageW(GetDlgItem(hDlg, IDC_SLD_SPEED), TBM_GETPOS, 0, 0) / 100.0;
    g_dlgSettings->opacity = (double)SendMessageW(GetDlgItem(hDlg, IDC_SLD_OPACITY), TBM_GETPOS, 0, 0) / 100.0;
    g_dlgSettings->scale = (double)SendMessageW(GetDlgItem(hDlg, IDC_SLD_SCALE), TBM_GETPOS, 0, 0) / 100.0;

    wchar_t buf[128];
    GetDlgItemTextW(hDlg, IDC_EDT_LABEL, buf, 128);
    g_dlgSettings->label = std::string(buf, buf + wcslen(buf));

    g_dlgSettings->save();
}

// Scale a 96-DPI pixel value to the window's actual DPI
static int S(int px, UINT dpi) { return MulDiv(px, (int)dpi, 96); }

static HWND createSlider(HWND parent, int id, int x, int y, int w, int h,
                          int minVal, int maxVal, int initVal, UINT dpi) {
    HWND sld = CreateWindowExW(0, TRACKBAR_CLASSW, L"",
        WS_CHILD | WS_VISIBLE | TBS_AUTOTICKS,
        S(x,dpi), S(y,dpi), S(w,dpi), S(h,dpi),
        parent, (HMENU)(LONG_PTR)id,
        (HINSTANCE)GetWindowLongPtrW(parent, GWLP_HINSTANCE), nullptr);
    SendMessageW(sld, TBM_SETRANGE, TRUE, MAKELPARAM(minVal, maxVal));
    SendMessageW(sld, TBM_SETPOS, TRUE, initVal);
    return sld;
}

static HWND createCheckBox(HWND parent, int id, const wchar_t* text,
                            int x, int y, int w, int h, bool checked, UINT dpi) {
    HWND cb = CreateWindowExW(0, L"BUTTON", text,
        WS_CHILD | WS_VISIBLE | BS_AUTOCHECKBOX,
        S(x,dpi), S(y,dpi), S(w,dpi), S(h,dpi),
        parent, (HMENU)(LONG_PTR)id,
        (HINSTANCE)GetWindowLongPtrW(parent, GWLP_HINSTANCE), nullptr);
    SendMessageW(cb, BM_SETCHECK, checked ? BST_CHECKED : BST_UNCHECKED, 0);
    return cb;
}

static void createControls(HWND hDlg, AppSettings& s, UINT dpi) {
    int fontPx = S(16, dpi);
    HFONT hFont = CreateFontW(-fontPx, 0, 0, 0, FW_NORMAL, 0, 0, 0,
        DEFAULT_CHARSET, 0, 0, CLEARTYPE_QUALITY, 0, L"Segoe UI");
    int y = 10;

    CreateWindowExW(0, L"STATIC", L"Name:", WS_CHILD | WS_VISIBLE,
        S(10,dpi), S(y+3,dpi), S(50,dpi), S(20,dpi), hDlg, nullptr, nullptr, nullptr);
    CreateWindowExW(0, L"EDIT", L"", WS_CHILD | WS_VISIBLE | WS_BORDER | ES_AUTOHSCROLL,
        S(60,dpi), S(y,dpi), S(150,dpi), S(24,dpi),
        hDlg, (HMENU)(LONG_PTR)IDC_EDT_LABEL, nullptr, nullptr);
    CreateWindowExW(0, L"BUTTON", L"Import...", WS_CHILD | WS_VISIBLE,
        S(220,dpi), S(y,dpi), S(70,dpi), S(24,dpi),
        hDlg, (HMENU)(LONG_PTR)IDC_BTN_IMPORT, nullptr, nullptr);
    y += 35;

    CreateWindowExW(0, L"BUTTON", L"Playback", WS_CHILD | WS_VISIBLE | BS_GROUPBOX,
        S(5,dpi), S(y,dpi), S(290,dpi), S(70,dpi), hDlg, nullptr, nullptr, nullptr);
    y += 15;
    createCheckBox(hDlg, IDC_CHK_PLAYING, L"Playing", 15, y, 80, 20, s.playing, dpi);
    y += 25;
    CreateWindowExW(0, L"STATIC", L"Speed:", WS_CHILD | WS_VISIBLE,
        S(15,dpi), S(y+3,dpi), S(50,dpi), S(16,dpi), hDlg, nullptr, nullptr, nullptr);
    createSlider(hDlg, IDC_SLD_SPEED, 65, y, 170, 20, 10, 400, (int)(s.speed * 100), dpi);
    CreateWindowExW(0, L"STATIC", L"", WS_CHILD | WS_VISIBLE,
        S(240,dpi), S(y+3,dpi), S(50,dpi), S(16,dpi),
        hDlg, (HMENU)(LONG_PTR)IDC_LBL_SPEED, nullptr, nullptr);
    y += 40;

    CreateWindowExW(0, L"BUTTON", L"Appearance", WS_CHILD | WS_VISIBLE | BS_GROUPBOX,
        S(5,dpi), S(y,dpi), S(290,dpi), S(100,dpi), hDlg, nullptr, nullptr, nullptr);
    y += 18;
    CreateWindowExW(0, L"STATIC", L"Opacity:", WS_CHILD | WS_VISIBLE,
        S(15,dpi), S(y+3,dpi), S(50,dpi), S(16,dpi), hDlg, nullptr, nullptr, nullptr);
    createSlider(hDlg, IDC_SLD_OPACITY, 65, y, 170, 20, 10, 100, (int)(s.opacity * 100), dpi);
    CreateWindowExW(0, L"STATIC", L"", WS_CHILD | WS_VISIBLE,
        S(240,dpi), S(y+3,dpi), S(50,dpi), S(16,dpi),
        hDlg, (HMENU)(LONG_PTR)IDC_LBL_OPACITY, nullptr, nullptr);
    y += 28;
    CreateWindowExW(0, L"STATIC", L"Scale:", WS_CHILD | WS_VISIBLE,
        S(15,dpi), S(y+3,dpi), S(50,dpi), S(16,dpi), hDlg, nullptr, nullptr, nullptr);
    createSlider(hDlg, IDC_SLD_SCALE, 65, y, 170, 20, 25, 400, (int)(s.scale * 100), dpi);
    CreateWindowExW(0, L"STATIC", L"", WS_CHILD | WS_VISIBLE,
        S(240,dpi), S(y+3,dpi), S(50,dpi), S(16,dpi),
        hDlg, (HMENU)(LONG_PTR)IDC_LBL_SCALE, nullptr, nullptr);
    y += 28;
    createCheckBox(hDlg, IDC_CHK_FLIPH, L"Flip H",  15,  y, 80, 20, s.flipHorizontal, dpi);
    createCheckBox(hDlg, IDC_CHK_FLIPV, L"Flip V", 110,  y, 80, 20, s.flipVertical,   dpi);
    y += 35;

    CreateWindowExW(0, L"BUTTON", L"Behavior", WS_CHILD | WS_VISIBLE | BS_GROUPBOX,
        S(5,dpi), S(y,dpi), S(290,dpi), S(85,dpi), hDlg, nullptr, nullptr, nullptr);
    y += 18;
    createCheckBox(hDlg, IDC_CHK_ONTOP,    L"Always on Top", 15, y, 120, 20, s.alwaysOnTop,  dpi);
    y += 22;
    createCheckBox(hDlg, IDC_CHK_CLICKTHRU, L"Click-Through", 15, y, 120, 20, s.clickThrough, dpi);
    y += 22;
    createCheckBox(hDlg, IDC_CHK_LOCKPOS,  L"Lock Position", 15, y, 120, 20, s.lockPosition, dpi);
    y += 35;

    CreateWindowExW(0, L"BUTTON", L"Remove Pet", WS_CHILD | WS_VISIBLE,
        S(10,dpi), S(y,dpi), S(90,dpi), S(28,dpi),
        hDlg, (HMENU)(LONG_PTR)IDC_BTN_REMOVE, nullptr, nullptr);
    CreateWindowExW(0, L"BUTTON", L"Close", WS_CHILD | WS_VISIBLE | BS_DEFPUSHBUTTON,
        S(220,dpi), S(y,dpi), S(70,dpi), S(28,dpi),
        hDlg, (HMENU)(LONG_PTR)IDOK, nullptr, nullptr);

    std::wstring wlabel(s.label.begin(), s.label.end());
    SetDlgItemTextW(hDlg, IDC_EDT_LABEL, wlabel.c_str());

    EnumChildWindows(hDlg, [](HWND child, LPARAM lp) -> BOOL {
        SendMessageW(child, WM_SETFONT, (WPARAM)lp, TRUE);
        return TRUE;
    }, (LPARAM)hFont);
}

static LRESULT CALLBACK dlgProc(HWND hDlg, UINT msg, WPARAM wp, LPARAM lp) {
    switch (msg) {
    case WM_CREATE:
        return 0;
    case WM_COMMAND:
        switch (LOWORD(wp)) {
        case IDC_BTN_IMPORT:
            applyFromUI(hDlg);
            return 0;
        case IDC_BTN_REMOVE:
            g_removeRequested = true;
            DestroyWindow(hDlg);
            return 0;
        case IDOK:
            applyFromUI(hDlg);
            DestroyWindow(hDlg);
            return 0;
        }
        break;
    case WM_HSCROLL: {
        HWND hSlider = (HWND)lp;
        int id = GetDlgCtrlID(hSlider);
        int pos = (int)SendMessageW(hSlider, TBM_GETPOS, 0, 0);
        wchar_t buf[32];
        if (id == IDC_SLD_SPEED) {
            swprintf(buf, 31, L"%.1fx", pos / 100.0);
            SetDlgItemTextW(hDlg, IDC_LBL_SPEED, buf);
        } else if (id == IDC_SLD_OPACITY) {
            swprintf(buf, 31, L"%d%%", pos);
            SetDlgItemTextW(hDlg, IDC_LBL_OPACITY, buf);
        } else if (id == IDC_SLD_SCALE) {
            swprintf(buf, 31, L"%.2fx", pos / 100.0);
            SetDlgItemTextW(hDlg, IDC_LBL_SCALE, buf);
        }
        applyFromUI(hDlg);
        return 0;
    }
    case WM_CLOSE:
        applyFromUI(hDlg);
        DestroyWindow(hDlg);
        return 0;
    }
    return DefWindowProcW(hDlg, msg, wp, lp);
}

static bool dlgClassRegistered = false;
static const wchar_t* DLG_CLASS = L"DesktopPetSettingsDlg";

void showSettingsDialog(HWND parent, AppSettings& settings, bool* removedOut) {
    g_dlgSettings = &settings;
    g_removeRequested = false;

    if (!dlgClassRegistered) {
        WNDCLASSEXW wc = {};
        wc.cbSize = sizeof(wc);
        wc.lpfnWndProc = dlgProc;
        wc.hInstance = GetModuleHandle(nullptr);
        wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
        wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
        wc.lpszClassName = DLG_CLASS;
        RegisterClassExW(&wc);
        dlgClassRegistered = true;
    }

    UINT dpi = GetDpiForWindow(parent ? parent : GetDesktopWindow());

    HWND hDlg = CreateWindowExW(WS_EX_DLGMODALFRAME, DLG_CLASS,
        L"Desktop Pet Settings",
        WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU,
        CW_USEDEFAULT, CW_USEDEFAULT,
        MulDiv(310, (int)dpi, 96), MulDiv(460, (int)dpi, 96),
        parent, nullptr, GetModuleHandle(nullptr), nullptr);

    g_hDlg = hDlg;
    createControls(hDlg, settings, dpi);
    ShowWindow(hDlg, SW_SHOW);
    UpdateWindow(hDlg);

    MSG msg;
    while (IsWindow(hDlg) && GetMessageW(&msg, nullptr, 0, 0)) {
        if (!IsDialogMessageW(hDlg, &msg)) {
            TranslateMessage(&msg);
            DispatchMessageW(&msg);
        }
    }
    if (removedOut) *removedOut = g_removeRequested;
    g_dlgSettings = nullptr;
    g_hDlg = nullptr;
    g_removeRequested = false;
}

std::wstring openFileDialog(HWND parent) {
    OPENFILENAMEW ofn = {};
    wchar_t szFile[MAX_PATH] = {};

    ofn.lStructSize = sizeof(ofn);
    ofn.hwndOwner = parent;
    ofn.lpstrFile = szFile;
    ofn.nMaxFile = MAX_PATH;
    ofn.lpstrFilter = L"Animations\0*.gif;*.png;*.apng\0Video\0*.mp4;*.mov;*.m4v;*.avi;*.mkv\0All\0*.*\0";
    ofn.nFilterIndex = 1;
    ofn.Flags = OFN_FILEMUSTEXIST | OFN_PATHMUSTEXIST;

    if (GetOpenFileNameW(&ofn)) {
        return szFile;
    }
    return {};
}
