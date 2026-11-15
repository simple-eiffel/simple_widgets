/* simple_widgets #90: keep a test run at full speed on macOS.

   A long test process that has made the application object (NSApp) and is not the frontmost
   app is put to sleep by App Nap after a while: macOS moves it to the efficiency cores, and
   every frame is about 2.5 times slower (the atlas test failed its budget after some 490
   tests, at 13 ms alone and 33 ms there). A frontmost app, the one a user is looking at, is
   not napped, so a frame-timing test should not be either. This holds a user-initiated,
   latency-critical activity for the life of the process. Elsewhere it does nothing. */
#ifndef SW_TEST_ACTIVITY_H
#define SW_TEST_ACTIVITY_H

#ifdef __APPLE__
#include <objc/runtime.h>
#include <objc/message.h>
#include <CoreFoundation/CoreFoundation.h>
static void sw_test_hold_activity(void)
{
	id l_info = ((id (*)(id, SEL)) objc_msgSend) ((id) objc_getClass ("NSProcessInfo"), sel_registerName ("processInfo"));
	if (!l_info) return;
	/* NSActivityUserInitiated | NSActivityLatencyCritical */
	id l_token = ((id (*)(id, SEL, unsigned long long, id)) objc_msgSend) (l_info,
		sel_registerName ("beginActivityWithOptions:reason:"), 0x00FFFFFFULL | 0xFF00000000ULL, (id) CFSTR ("simple_widgets tests"));
	if (l_token) CFRetain ((CFTypeRef) l_token);   /* held until the process ends */
}
#else
static void sw_test_hold_activity(void) { }
#endif

#endif
