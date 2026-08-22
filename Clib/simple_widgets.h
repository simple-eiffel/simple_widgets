/* ocr_cairo_win.h - pure Win32 scaffolding for the cairo face.
   v2: adds keyboard input, a frozen-desktop drag overlay (the pure-route
   replacement for the Vision2 region picker) and a screen grabber that
   BitBlts straight into a caller-supplied cairo ARGB32 buffer (the
   pure-route replacement for EV_SCREEN.sub_pixmap). */

#ifndef SIMPLE_WIDGETS_H
#define SIMPLE_WIDGETS_H

#include <windows.h>
#pragma comment(lib, "shell32.lib")

/* Event queue: [type, a, b, c] per slot.
   main window:  2 lbutton(x,y) | 3 char(code) | 4 keydown(vk) | 6 expose | 7 tick
   overlay:     12 move(x,y)   | 13 down(x,y) | 14 up(x,y)    | 15 cancel | 16 expose */
#define SW_QCAP 1024
static HWND s_sw_hwnd = 0;
static LONG s_sw_dbl_time = 0;
static int  s_sw_tracking = 0;
static int  s_sw_dbl_x = 0, s_sw_dbl_y = 0;
static HWND s_sw_overlay = 0;
static int  s_sw_q[SW_QCAP][4];
static int  s_sw_qhead = 0, s_sw_qtail = 0;

static void sw_push(int t, int a, int b, int c) {
    int next = (s_sw_qtail + 1) % SW_QCAP;
    if (next == s_sw_qhead) return;
    s_sw_q[s_sw_qtail][0] = t;
    s_sw_q[s_sw_qtail][1] = a;
    s_sw_q[s_sw_qtail][2] = b;
    s_sw_q[s_sw_qtail][3] = c;
    s_sw_qtail = next;
}

static LRESULT CALLBACK sw_wndproc(HWND h, UINT m, WPARAM w, LPARAM l) {
    switch (m) {
        case WM_LBUTTONDOWN: {
            int cx = (int)(short)LOWORD(l), cy = (int)(short)HIWORD(l);
            SetFocus(h);
            SetCapture(h);
            if (s_sw_dbl_time != 0
                && GetMessageTime() - s_sw_dbl_time <= (LONG)GetDoubleClickTime()
                && abs(cx - s_sw_dbl_x) <= GetSystemMetrics(SM_CXDOUBLECLK)
                && abs(cy - s_sw_dbl_y) <= GetSystemMetrics(SM_CYDOUBLECLK)) {
                s_sw_dbl_time = 0;
                sw_push(12, cx, cy, 0);
            } else {
                sw_push(2, cx, cy, 0);
            }
            return 0;
        }
        case WM_LBUTTONUP:
            ReleaseCapture();
            sw_push(10, (int)(short)LOWORD(l), (int)(short)HIWORD(l), 0);
            return 0;
        case WM_LBUTTONDBLCLK:
            s_sw_dbl_time = GetMessageTime();
            s_sw_dbl_x = (int)(short)LOWORD(l);
            s_sw_dbl_y = (int)(short)HIWORD(l);
            sw_push(8, s_sw_dbl_x, s_sw_dbl_y, 0);
            return 0;
        case WM_RBUTTONDOWN:
            /* eat: the menu opens on BUTTON-UP, or the release event
               dismisses the popup the instant it appears */
            SetFocus(h);
            return 0;
        case WM_RBUTTONUP:
            sw_push(11, (int)(short)LOWORD(l), (int)(short)HIWORD(l), 0);
            return 0;
        case WM_MOUSEMOVE:
            if (!s_sw_tracking) {
                TRACKMOUSEEVENT tme;
                tme.cbSize = sizeof(tme);
                tme.dwFlags = TME_LEAVE;
                tme.hwndTrack = h;
                tme.dwHoverTime = 0;
                TrackMouseEvent(&tme);
                s_sw_tracking = 1;
            }
            if (w & MK_LBUTTON)
                sw_push(9, (int)(short)LOWORD(l), (int)(short)HIWORD(l), 0);
            else {
                /* coalesce plain moves: replace a queued move instead of flooding */
                int last = (s_sw_qtail + SW_QCAP - 1) % SW_QCAP;
                if (s_sw_qtail != s_sw_qhead && s_sw_q[last][0] == 13) {
                    s_sw_q[last][1] = (int)(short)LOWORD(l);
                    s_sw_q[last][2] = (int)(short)HIWORD(l);
                } else
                    sw_push(13, (int)(short)LOWORD(l), (int)(short)HIWORD(l), 0);
            }
            return 0;
        case WM_MOUSEWHEEL: {
            POINT wp;
            wp.x = (int)(short)LOWORD(l);
            wp.y = (int)(short)HIWORD(l);
            ScreenToClient(h, &wp);
            sw_push(15, (int)wp.x, (int)wp.y, (int)(short)HIWORD(w));
            return 0;
        }
        case WM_MOUSELEAVE:
            s_sw_tracking = 0;
            sw_push(14, 0, 0, 0);
            return 0;
        case WM_CHAR:
            sw_push(3, (int)w, 0, 0);
            return 0;
        case WM_KEYDOWN:
            if (w == VK_LEFT || w == VK_RIGHT || w == VK_HOME || w == VK_END ||
                w == VK_DELETE || w == VK_UP || w == VK_DOWN)
                sw_push(4, (int)w, 0, 0);
            return 0;
        case WM_TIMER:
            sw_push(7, 0, 0, 0);
            return 0;
        case WM_PAINT: {
            PAINTSTRUCT ps;
            BeginPaint(h, &ps);
            EndPaint(h, &ps);
            sw_push(6, 0, 0, 0);
            return 0;
        }
        case WM_ERASEBKGND:
            return 1;
        case WM_DESTROY:
            KillTimer(h, 1);
            PostQuitMessage(0);
            return 0;
    }
    return DefWindowProcW(h, m, w, l);
}

static LRESULT CALLBACK sw_overlay_proc(HWND h, UINT m, WPARAM w, LPARAM l) {
    switch (m) {
        case WM_MOUSEMOVE:
            sw_push(12, (int)(short)LOWORD(l), (int)(short)HIWORD(l), 0);
            return 0;
        case WM_LBUTTONDOWN:
            SetCapture(h);
            sw_push(13, (int)(short)LOWORD(l), (int)(short)HIWORD(l), 0);
            return 0;
        case WM_LBUTTONUP:
            ReleaseCapture();
            sw_push(14, (int)(short)LOWORD(l), (int)(short)HIWORD(l), 0);
            return 0;
        case WM_KEYDOWN:
            if (w == VK_ESCAPE) sw_push(15, 0, 0, 0);
            return 0;
        case WM_RBUTTONDOWN:
            sw_push(15, 0, 0, 0);
            return 0;
        case WM_PAINT: {
            PAINTSTRUCT ps;
            BeginPaint(h, &ps);
            EndPaint(h, &ps);
            sw_push(16, 0, 0, 0);
            return 0;
        }
        case WM_ERASEBKGND:
            return 1;
    }
    return DefWindowProcW(h, m, w, l);
}

static void* sw_create_window(const wchar_t* title, int px, int py, int cw, int ch) {
    WNDCLASSW wc;
    RECT r;
    HWND h;
    SetProcessDPIAware();
    ZeroMemory(&wc, sizeof(wc));
    wc.style = CS_DBLCLKS;
    wc.lpfnWndProc = sw_wndproc;
    wc.hInstance = GetModuleHandleW(0);
    wc.hCursor = LoadCursorW(0, (LPCWSTR)IDC_ARROW);
    wc.lpszClassName = L"SimpleViewWindow";
    RegisterClassW(&wc);
    r.left = 0; r.top = 0; r.right = cw; r.bottom = ch;
    AdjustWindowRect(&r, WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX, FALSE);
    h = CreateWindowExW(0, L"SimpleViewWindow", title,
        WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX,
        px, py,
        r.right - r.left, r.bottom - r.top, 0, 0, GetModuleHandleW(0), 0);
    s_sw_hwnd = h;
    if (h) {
        ShowWindow(h, SW_SHOW);
        UpdateWindow(h);
        SetTimer(h, 1, 500, 0);
    }
    return (void*)h;
}

static int sw_pump(void) {
    MSG m;
    BOOL r = GetMessageW(&m, 0, 0, 0);
    if (r <= 0) return 0;
    TranslateMessage(&m);
    DispatchMessageW(&m);
    return 1;
}

static int sw_next_event(int* out4) {
    if (s_sw_qhead == s_sw_qtail) return 0;
    out4[0] = s_sw_q[s_sw_qhead][0];
    out4[1] = s_sw_q[s_sw_qhead][1];
    out4[2] = s_sw_q[s_sw_qhead][2];
    out4[3] = s_sw_q[s_sw_qhead][3];
    s_sw_qhead = (s_sw_qhead + 1) % SW_QCAP;
    return out4[0];
}

static void* sw_get_dc(void)         { return s_sw_hwnd ? (void*)GetDC(s_sw_hwnd) : 0; }
static void  sw_release_dc(void* dc) { if (s_sw_hwnd && dc) ReleaseDC(s_sw_hwnd, (HDC)dc); }

static double sw_now_ms(void) {
    LARGE_INTEGER f, c;
    QueryPerformanceFrequency(&f);
    QueryPerformanceCounter(&c);
    return (double)c.QuadPart * 1000.0 / (double)f.QuadPart;
}

static int sw_shell_open(const wchar_t* path) {
    return (int)(INT_PTR)ShellExecuteW(0, L"open", path, 0, 0, SW_SHOWNORMAL) > 32 ? 1 : 0;
}

/* ---- screen metrics (virtual desktop) ---- */
static int sw_screen_x(void) { return GetSystemMetrics(SM_XVIRTUALSCREEN); }
static int sw_screen_y(void) { return GetSystemMetrics(SM_YVIRTUALSCREEN); }
static int sw_screen_w(void) { return GetSystemMetrics(SM_CXVIRTUALSCREEN); }
static int sw_screen_h(void) { return GetSystemMetrics(SM_CYVIRTUALSCREEN); }

/* ---- pure screen grab: BitBlt the desktop region into a caller-supplied
   cairo ARGB32 buffer (bits/stride), alpha forced opaque. Replaces
   EV_SCREEN.sub_pixmap on the pure route. Returns 1 on success. ---- */
static int sw_grab_screen(int x, int y, int w, int h, void* bits, int stride) {
    HDC screen, mem;
    HBITMAP dib, old;
    BITMAPINFO bi;
    void* dib_bits = 0;
    int row, col, ok = 0;
    if (!bits || w <= 0 || h <= 0) return 0;
    screen = GetDC(0);
    if (!screen) return 0;
    mem = CreateCompatibleDC(screen);
    ZeroMemory(&bi, sizeof(bi));
    bi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bi.bmiHeader.biWidth = w;
    bi.bmiHeader.biHeight = -h;               /* top-down */
    bi.bmiHeader.biPlanes = 1;
    bi.bmiHeader.biBitCount = 32;
    bi.bmiHeader.biCompression = BI_RGB;
    dib = CreateDIBSection(mem, &bi, DIB_RGB_COLORS, &dib_bits, 0, 0);
    if (dib && dib_bits) {
        old = (HBITMAP)SelectObject(mem, dib);
        if (BitBlt(mem, 0, 0, w, h, screen, x, y, SRCCOPY | CAPTUREBLT)) {
            for (row = 0; row < h; row++) {
                unsigned int* src = (unsigned int*)((char*)dib_bits + (size_t)row * w * 4);
                unsigned int* dst = (unsigned int*)((char*)bits + (size_t)row * stride);
                for (col = 0; col < w; col++)
                    dst[col] = src[col] | 0xFF000000u;   /* opaque alpha */
            }
            ok = 1;
        }
        SelectObject(mem, old);
        DeleteObject(dib);
    }
    DeleteDC(mem);
    ReleaseDC(0, screen);
    return ok;
}

/* ---- frozen-desktop drag overlay ---- */
static void* sw_show_overlay(void) {
    WNDCLASSW wc;
    int vx = sw_screen_x(), vy = sw_screen_y();
    int vw = sw_screen_w(), vh = sw_screen_h();
    if (!s_sw_overlay) {
        ZeroMemory(&wc, sizeof(wc));
        wc.lpfnWndProc = sw_overlay_proc;
        wc.hInstance = GetModuleHandleW(0);
        wc.hCursor = LoadCursorW(0, (LPCWSTR)IDC_CROSS);
        wc.lpszClassName = L"SimpleViewOverlay";
        RegisterClassW(&wc);
        s_sw_overlay = CreateWindowExW(WS_EX_TOPMOST, L"SimpleViewOverlay", L"",
            WS_POPUP, vx, vy, vw, vh, 0, 0, GetModuleHandleW(0), 0);
    }
    if (s_sw_overlay) {
        SetWindowPos(s_sw_overlay, HWND_TOPMOST, vx, vy, vw, vh, SWP_SHOWWINDOW);
        SetForegroundWindow(s_sw_overlay);
        SetFocus(s_sw_overlay);
    }
    return (void*)s_sw_overlay;
}

static void sw_hide_overlay(void) {
    if (s_sw_overlay) ShowWindow(s_sw_overlay, SW_HIDE);
}

static void* sw_overlay_dc(void)         { return s_sw_overlay ? (void*)GetDC(s_sw_overlay) : 0; }
static void  sw_overlay_release(void* dc){ if (s_sw_overlay && dc) ReleaseDC(s_sw_overlay, (HDC)dc); }

/* ---- status strip: second topmost tool window ----
   events: 21 strip_lbutton(x,y) | 22 strip_moved(x,y) | 23 strip_expose */
static HWND s_sw_strip = 0;

static LRESULT CALLBACK sw_strip_proc(HWND h, UINT m, WPARAM w, LPARAM l) {
    switch (m) {
        case WM_LBUTTONDOWN: {
            int x = (int)(short)LOWORD(l), y = (int)(short)HIWORD(l);
            sw_push(21, x, y, 0);
            /* drag anywhere except the transport corner (right 90px, top 26px) */
            if (!(y < 26 && x > 0)) { }
            if (y >= 26 || x < 1) {
                ReleaseCapture();
                SendMessageW(h, WM_NCLBUTTONDOWN, HTCAPTION, 0);
            }
            return 0;
        }
        case WM_EXITSIZEMOVE: {
            RECT r;
            GetWindowRect(h, &r);
            sw_push(22, r.left, r.top, 0);
            return 0;
        }
        case WM_PAINT: {
            PAINTSTRUCT ps;
            BeginPaint(h, &ps);
            EndPaint(h, &ps);
            sw_push(23, 0, 0, 0);
            return 0;
        }
        case WM_ERASEBKGND:
            return 1;
    }
    return DefWindowProcW(h, m, w, l);
}

static void* sw_show_strip(int x, int y, int w, int h) {
    WNDCLASSW wc;
    if (!s_sw_strip) {
        ZeroMemory(&wc, sizeof(wc));
        wc.lpfnWndProc = sw_strip_proc;
        wc.hInstance = GetModuleHandleW(0);
        wc.hCursor = LoadCursorW(0, (LPCWSTR)IDC_ARROW);
        wc.lpszClassName = L"SimpleViewAux";
        RegisterClassW(&wc);
        s_sw_strip = CreateWindowExW(WS_EX_TOPMOST | WS_EX_TOOLWINDOW,
            L"SimpleViewAux", L"", WS_POPUP, x, y, w, h,
            0, 0, GetModuleHandleW(0), 0);
    }
    if (s_sw_strip)
        SetWindowPos(s_sw_strip, HWND_TOPMOST, x, y, w, h, SWP_SHOWWINDOW | SWP_NOACTIVATE);
    return (void*)s_sw_strip;
}

static void sw_hide_strip(void) {
    if (s_sw_strip) ShowWindow(s_sw_strip, SW_HIDE);
}

static void* sw_strip_dc(void)          { return s_sw_strip ? (void*)GetDC(s_sw_strip) : 0; }
static void  sw_strip_release(void* dc) { if (s_sw_strip && dc) ReleaseDC(s_sw_strip, (HDC)dc); }

/* ---- helpers for the run engine ---- */
static int sw_buffers_equal(const void* a, const void* b, int len) {
    return (a && b && len > 0 && memcmp(a, b, (size_t)len) == 0) ? 1 : 0;
}

static int sw_minutes_of_day(void) {
    SYSTEMTIME st;
    GetLocalTime(&st);
    return (int)st.wHour * 60 + (int)st.wMinute;
}


/* Private font loading: the vendored TTFs become selectable by family name
   through Cairo's Win32 font backend, process-only (FR_PRIVATE), no install. */
static int sw_add_font (const char *path) {
    return (int) AddFontResourceExA ((LPCSTR) path, FR_PRIVATE, 0);
}

static int sw_shift_down(void) {
    return (GetKeyState(VK_SHIFT) & 0x8000) ? 1 : 0;
}

/* ---- clipboard (CF_UNICODETEXT) ---- */
static int sw_clip_set (const wchar_t *s) {
    size_t n; HGLOBAL h; wchar_t *dst;
    if (!OpenClipboard(s_sw_hwnd)) return 0;
    EmptyClipboard();
    n = wcslen(s);
    h = GlobalAlloc(GMEM_MOVEABLE, (n + 1) * sizeof(wchar_t));
    if (h) {
        dst = (wchar_t*)GlobalLock(h);
        memcpy(dst, s, (n + 1) * sizeof(wchar_t));
        GlobalUnlock(h);
        SetClipboardData(CF_UNICODETEXT, h);
    }
    CloseClipboard();
    return h ? 1 : 0;
}

static int sw_clip_get (wchar_t *buf, int cap) {
    HANDLE h; wchar_t *src; int n = 0;
    if (!OpenClipboard(s_sw_hwnd)) return 0;
    h = GetClipboardData(CF_UNICODETEXT);
    if (h) {
        src = (wchar_t*)GlobalLock(h);
        if (src) {
            while (n < cap - 1 && src[n]) { buf[n] = src[n]; n++; }
            buf[n] = 0;
            GlobalUnlock(h);
        }
    }
    CloseClipboard();
    return n;
}

static int sw_clip_has_text (void) {
    return IsClipboardFormatAvailable(CF_UNICODETEXT) ? 1 : 0;
}

/* ---- native text context menu: returns 1 Cut, 2 Copy, 3 Paste, 4 Select All, 0 none ---- */
static int sw_text_menu (int can_cut, int can_copy, int can_paste, int can_select) {
    HMENU m; POINT pt; int r;
    m = CreatePopupMenu();
    AppendMenuW(m, can_cut ? MF_STRING : MF_STRING | MF_GRAYED, 1, L"Cu&t	Ctrl+X");
    AppendMenuW(m, can_copy ? MF_STRING : MF_STRING | MF_GRAYED, 2, L"&Copy	Ctrl+C");
    AppendMenuW(m, can_paste ? MF_STRING : MF_STRING | MF_GRAYED, 3, L"&Paste	Ctrl+V");
    AppendMenuW(m, MF_SEPARATOR, 0, 0);
    AppendMenuW(m, can_select ? MF_STRING : MF_STRING | MF_GRAYED, 4, L"Select &All	Ctrl+A");
    GetCursorPos(&pt);
    /* Canonical Win32 dance: without SetForegroundWindow the popup can
       open and instantly self-dismiss; the WM_NULL afterwards lets the
       menu close cleanly when the user clicks elsewhere. */
    SetForegroundWindow(s_sw_hwnd);
    r = (int)TrackPopupMenu(m, TPM_RETURNCMD | TPM_RIGHTBUTTON, pt.x, pt.y, 0, s_sw_hwnd, 0);
    PostMessageW(s_sw_hwnd, WM_NULL, 0, 0);
    DestroyMenu(m);
    return r;
}
#endif
