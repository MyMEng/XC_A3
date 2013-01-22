/*
 * Visualizer.xc
 *
 *  Definition of functions used to control LEDs
 */
#include <platform.h>

#include "Common.h"
#include "Visualizer.h"

// Define ports

// Leds, buttons and speaker ports
out port cledG = PORT_CLOCKLED_SELG;
out port cledR = PORT_CLOCKLED_SELR;

//DISPLAYS an LED pattern in one quadrant of the clock LEDs
int showLED(out port p, chanend fromVisualiser) {
	unsigned int lightUpPattern;

	while (true) {
		fromVisualiser :> lightUpPattern; //read LED pattern from visualiser process
		p <: lightUpPattern; //send pattern to LEDs
	}
	return 0;
}

void visualiser(chanend fromCollector,
		chanend toQuadrant0, chanend toQuadrant1,
		chanend toQuadrant2, chanend toQuadrant3) {

	// Is visualizer running?
	bool running;

	// Progress from collector
	unsigned int progress;

	// Values to be sent to showLED
	int q0, q1, q2, q3;

	// Set running to true initially
	running = true;

	// Turn green on
	cledG <: true;
	cledR <: false;

	//
	// LED I = 16
    // I + II = 48
	// I + II + III = 112
	// Clear quadrants
	toQuadrant0 <: 0;
	toQuadrant1 <: 0;
	toQuadrant2 <: 0;
	toQuadrant3 <: 0;


	while(running) {
		select {
			// Check for progress updates
			case fromCollector :> progress:
				break;
		}
		q0 = 0; q1 = 0; q2 = 0; q3 = 0;

		// Set value quadrants according to the progreess
		if( progress >= 8 && progress < 16) {
			q0 = 16;
		} else if(progress >= 16 && progress < 24) {
			q0 = 48;
		} else if(progress >= 24 && progress < 40) {
			q0 = 112;
		} else if(progress >= 40 && progress < 48) {
			q0 = 112; q1 = 16;
		} else if(progress >= 48 && progress < 56) {
			q0 = 112; q1 = 48;
		} else if(progress >= 56 && progress < 64) {
			q0 = 112; q1 = 112;
		} else if(progress >= 64 && progress < 72) {
			q0 = 112; q1 = 112; q2 = 16;
		} else if(progress >= 72 && progress < 80) {
			q0 = 112; q1 = 112; q2 = 48;
		} else if(progress >= 80 && progress < 88) {
			q0 = 112; q1 = 112; q2 = 112;
		} else if(progress >= 88 && progress < 96) {
			q0 = 112; q1 = 112; q2 = 112; q3 = 16;
		} else if(progress >= 96 && progress < 100) {
			q0 = 112; q1 = 112; q2 = 112; q3 = 48;
		} else if(progress >= 100 ) {
			q0 = 112; q1 = 112; q2 = 112; q3 = 112;
		}

		toQuadrant0 <: q0;
		toQuadrant1 <: q1;
		toQuadrant2 <: q2;
		toQuadrant3 <: q3;
	}
}
