/*
 * Common.xc
 *
 * Common functions shared by modules in the project
 */
#include <platform.h>
#include <stdio.h>

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

void timerThread(chanend fromDistributor, chanend fromCollector) {
	bool running;
	int seconds;
	int t;

	running = true;
	seconds = 0;
	// Get timer readings
	fromDistributor :> t;

	while(running) {
		select {
			case fromCollector :> t: {
				running = false;
				break;
			}
			default: {
				seconds++;
				waitMomentCustom(100000000);
				break;
			}
		}
	}

	printf("It took %ds to blur image.\n", seconds);
}

