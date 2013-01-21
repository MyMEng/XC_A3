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

	// Is button listener running?
	bool running = true;

	status_t status = PAUSE;

	while ( running ) {
		// Used to check status changes
		status_t old_status;

		// check if some buttons are pressed
		b when pinsneq(15) :> r;

		old_status = status;
		switch( r ) {

		// Start the process
		case buttonA:
			status = RUNNING;
			break;
		case buttonB:
			status = PAUSE;
			break;
		case buttonC:
			status = TERMINATE;
			running = false;
			break;
		case buttonD:
			break;
		default:
			break;
		}

		// Send new status if changed
		if( old_status != status)
			toDistributor <: status;

		//buttonLed <: (2 * muteSound) + (4 * pause); ;

		// play sound
		//if (!muteSound)
		//	playSound(200000, spkr, 15);

		// send button pattern to userAnt
		//if(sendToUser)
		//	toUserAnt <: r;
	}
}
