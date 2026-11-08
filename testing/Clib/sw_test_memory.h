/* sw_test_memory.h - the process's own memory, for the leak probes in
   SW_WIDGET_IMAGE_ASSAULT: the bytes it has committed and keeps, or 0 when
   the platform will not say.
   Windows: committed private memory (PagefileUsage), through
   K32GetProcessMemoryInfo looked up at run time (its psapi.h declaration is
   gated above the Windows 2000 target ISE builds for).
   macOS: the task's physical footprint (what Activity Monitor shows).
   Linux: resident pages, from /proc/self/statm. */

#ifndef SW_TEST_MEMORY_H
#define SW_TEST_MEMORY_H

#include <stdint.h>

#if defined(_WIN32)
#include <windows.h>
#include <psapi.h>
static uint64_t sw_test_commit_bytes(void) {
    PROCESS_MEMORY_COUNTERS l_pmc;
    BOOL (WINAPI *l_f)(HANDLE, PROCESS_MEMORY_COUNTERS*, DWORD);
    l_f = (BOOL (WINAPI *)(HANDLE, PROCESS_MEMORY_COUNTERS*, DWORD))
        GetProcAddress(GetModuleHandleW(L"kernel32.dll"), "K32GetProcessMemoryInfo");
    l_pmc.cb = sizeof(l_pmc);
    if (l_f && l_f(GetCurrentProcess(), &l_pmc, sizeof(l_pmc))) return (uint64_t)l_pmc.PagefileUsage;
    return 0;
}
#elif defined(__APPLE__)
#include <mach/mach.h>
static uint64_t sw_test_commit_bytes(void) {
    task_vm_info_data_t l_info;
    mach_msg_type_number_t l_count = TASK_VM_INFO_COUNT;
    if (task_info(mach_task_self(), TASK_VM_INFO, (task_info_t)&l_info, &l_count) != KERN_SUCCESS) return 0;
    return (uint64_t)l_info.phys_footprint;
}
#else
#include <stdio.h>
#include <unistd.h>
static uint64_t sw_test_commit_bytes(void) {
    unsigned long l_size = 0, l_resident = 0;
    FILE *l_f = fopen("/proc/self/statm", "r");
    if (!l_f) return 0;
    if (fscanf(l_f, "%lu %lu", &l_size, &l_resident) != 2) l_resident = 0;
    fclose(l_f);
    return (uint64_t)l_resident * (uint64_t)sysconf(_SC_PAGESIZE);
}
#endif

#endif
