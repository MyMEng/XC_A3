#include <stdio.h>
#include <platform.h>

#include "Common.h"
#include "Buttons.h"


// Define delays
#define LEDDELAY 100000
#define DEFAULTDELAY 8000000

//READ BUTTONS and send to userAnt
void buttonListener(in port b, out port spkr, chanend toDistributor) {

	// Temp value indicating pressed button
	unsigned int r;

	// Started?
	bool started;

	// Status of buttons
	status_t status;

	// Is button listener running?
	bool running;

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
				//printf("Pause...\n");
			} else if( status == PAUSE && started ) {
				//printf("Resume...\n");
				status = RUNNING;
			}
			break;
		case buttonC:
			status = TERMINATE;
			running = false;
			//printf("Terminate...\n");
			break;
		case buttonD:
			if(!started) {
				toDistributor <: CHANGE_ALGORITHM;
				//printf("Change algorithm...\n");
			}
			break;
		default:
			break;
		}


		// Send new status if changed
		if( old_status == status ) continue;

		toDistributor <: (int)status;

		// Wait before reading next button
		waitMomentCustom(BUTTONDELAY);

		//buttonLed <: (2 * muteSound) + (4 * pause); ;

		// play sound
		//if (!muteSound)
		//	playSound(200000, spkr, 15);


	}
}
