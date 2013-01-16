/*
 * Collector.c
 *
 * Contains definition of collector functions
 */
#include <platform.h>
#include <stdio.h>

#include "Common.h"
#include "Collector.h"

/////////////////////////////////////////////////////////////////////////////////////////
//
// Collect results from workers and send to data stream
//
/////////////////////////////////////////////////////////////////////////////////////////
void collector(chanend workerToColl[WORKERNO], chanend c_out) {
	// Declare variables
	bool running;	// Is collector runnning?
	uchar pixel;	// Buffer
	int noPixels;	// Number of pixels read
	int lines;		// Number of lines

	// Initialize variables
	running = true;
	noPixels = 0;
	lines = 0;

	while(running) {
		for(int  w = 0; w < WORKERNO; w++  ) {
			workerToColl[w] :> pixel;
			c_out <: pixel;
			noPixels++;
		}
		if(noPixels == IMHT*IMWD) {
			running = false;
		}
	}
	printf("Collector finished...\n");
}
