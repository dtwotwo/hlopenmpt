#define HL_NAME(n) testinput_##n

#include <hl.h>

#ifdef _WIN32
#include <conio.h>
#endif

// need for fixing looping playback with input skip, cuz Sys,getChar(false) works incorrect
HL_PRIM bool HL_NAME(poll_space)() {
#ifdef _WIN32
	if (!_kbhit())
		return false;

	return _getch() == ' ';
#else
	return false;
#endif
}

DEFINE_PRIM(_BOOL, poll_space, _NO_ARG);
