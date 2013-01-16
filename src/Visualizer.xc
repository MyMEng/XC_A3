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

	cledG <: true;
	cledR <: false;
	// Clear the LEDs
	toQuadrant0 <: 16;
	toQuadrant1 <: 32;
	toQuadrant2 <: 0;
	toQuadrant3 <: 8;
	waitMoment();
}
