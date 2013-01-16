/*
 * Common.xc
 *
 * Common functions shared by modules in the project
 */
#include <platform.h>

#include "Common.h"

// WAIT function
// Allow to specify delay
void waitMomentCustom(int delay) {
	timer tmr;
	int waitTime;
	tmr :> waitTime;
	waitTime += delay;
	tmr when timerafter(waitTime) :> void;
}

// Use default delay
void waitMoment() {
	waitMomentCustom(DEFAULTDELAY);
}

