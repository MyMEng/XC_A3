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
void collector(chanend workerToColl[WORKERNO], chanend c_out, chanend toVisualizer) {
	// Declare variables
	bool running;	// Is collector runnning?
	uchar pixel;	// Buffer
	int noPixels;	// Number of pixels read
	int signal;
	const int maxPixels = (IMHT*IMWD); // Maxium number of pixels to be processed

	// Initialize variables
	running = true;
	noPixels = 0;
	signal = 0;

	while(running) {
		for(int  w = 0; w < WORKERNO; w++  ) {
			select {
				case c_out :> signal:
					running = false;
					printf("Got finished signal in collector\n");
					break;
				case workerToColl[w] :> pixel:
					c_out <: pixel;
					noPixels++;
					toVisualizer <: (int)(noPixels * 100 / maxPixels);
					break;
			}
			if(signal == FINISHED || !running)
				break;
		}
	}

	for(int  w = 0; w < WORKERNO; w++)
		workerToColl[w] <: FINISHED;

	printf("Collector finished...\n");
}
