#include <stdio.h>
#include <platform.h>

#include "Common.h"
#include "Buttons.h"


// Define delays
#define LEDDELAY 100000
#define DEFAULTDELAY 8000000

//Buttons LED port
out port buttonLed = PORT_BUTTONLED;

//READ BUTTONS and send to userAnt
void buttonListener(in port b, out port spkr, chanend toDistributor) {

	// Temp value indicating pressed button
	unsigned int r;

	// Started?
	bool started, paused, filter;

	// Status of buttons
	status_t status;

	// Is button listener running?
	bool running;

	filter = false;
	paused = false;
	running = true;
	started = false;

	status = PAUSE;

	while ( running ) {
		// Used to check status changes
		status_t old_status;

		// check if some buttons are pressed
		b when pinsneq(15) :> r;

		old_status = status;
		switch( r ) {

		// Start the process
		case buttonA:
			if( !started ) {
				status = RUNNING;
				started = true;
				//printf("Start...\n");
			}
			break;
		case buttonB:
			if( status == RUNNING ) {
				status = PAUSE;
				paused = !paused;
				//printf("Pause...\n");
			} else if( status == PAUSE && started ) {
				//printf("Resume...\n");
				status = RUNNING;
				paused = !paused;
			}
			break;
		case buttonC:
			status = TERMINATE;
			if(old_status != status) {
				toDistributor <: PAUSE;
				toDistributor <: TERMINATE;
				running = false;
			}

			//printf("Terminate...\n");
			break;
		case buttonD:
			if(!started) {
				toDistributor <: CHANGE_ALGORITHM;
				filter = !filter;
				//printf("Change algorithm...\n");
			}
			break;
		default:
			break;
		}

		if(!running)
			continue;

		buttonLed <: (2 * paused) + (1 * started) + (filter * 8);

		// Wait before reading next button
		waitMomentCustom(BUTTONDELAY);

		// Send new status if changed
		if( old_status == status ) continue;

		toDistributor <: (int)status;



		// play sound
		//if (!muteSound)
		//	playSound(200000, spkr, 15);


	}
	printf("Buttons shut down\n");
}
