/*
 * Worker.c
 *
 * Definition of worker
 */
#include <platform.h>
#include "Worker.h"
#include "Common.h"

/////////////////////////////////////////////////////////////////////////////////////////
//
// Process a chunk of pixels
//
/////////////////////////////////////////////////////////////////////////////////////////
void worker(chanend distToWorker, chanend workerToColl) {
	// Flag indicating state of worker
	bool running;

	// Store value sent from the distributor
	uchar temp;

	// Remeber average of nine pixels
	uchar average;

	// Set running to true
	running = true;


	// Be ready to process threads
	while(running) {

		average = 0;

		// Get pixels to blur from the distributor
		for(int i = 0; i < PIXELS; i++) {
			distToWorker :> temp;
			average += temp;
		}

		// Take the average
		average /= PIXELS;

		// Send result to a collector
		workerToColl <: average;
	}


}

