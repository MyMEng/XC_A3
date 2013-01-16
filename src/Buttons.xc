#include <stdio.h>
#include <platform.h>

#include "Common.h"
#include "Buttons.h"

// Port for buttons' leds
out port buttonLed = PORT_BUTTONLED;
in port buttons = PORT_BUTTON;
out port speaker = PORT_SPEAKER;


// Define delays
#define LEDDELAY 100000
#define DEFAULTDELAY 8000000

//READ BUTTONS and send to userAnt
void buttonListener(in port b, out port spkr, chanend toDistributor) {

	// Temp value indicating pressed button
	unsigned int r;

	// Is button listener running?
	bool running = true;

	while (running) {

		// check if some buttons are pressed
		b when pinsneq(15) :> r;

		switch(r){
			case buttonB:
			case buttonC:
			case buttonA:
			case buttonD:
				break;
			default:
				break;
		}

		//buttonLed <: (2 * muteSound) + (4 * pause); ;

		// play sound
		//if (!muteSound)
		//	playSound(200000, spkr, 15);

		// send button pattern to userAnt
		//if(sendToUser)
		//	toUserAnt <: r;
	}
}
