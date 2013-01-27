/*
 * Collector.c
 *
 * Contains definition of collector functions
 */
#include <platform.h>
#include <stdio.h>

#include "Common.h"
#include "Collector.h"
#include "Worker.h"

/////////////////////////////////////////////////////////////////////////////////////////
//
// Collect results from workers and send to data stream
//
/////////////////////////////////////////////////////////////////////////////////////////
void collector(chanend workerToColl[WORKERNO], chanend c_out, chanend toVisualizer) {
	// Declare variables
	bool running;	// Is collector runnning?
	result_t res;	// Buffer
	int noPixels;	// Number of pixels read
	int signal;
	const int maxPixels = (IMHT*IMWD); // Maxium number of pixels to be processed
	bool workersRunning[WORKERNO];

	// Initialize variables
	running = true;
	noPixels = 0;
	signal = 0;

	// Assume all workers are running
	for(int i = 0; i < WORKERNO; ++i) {
		workersRunning[i] = true;
	}

	while(running) {
		// Listen to each worker
		for(int w = 0; w < WORKERNO; w++) {

			// unless it is running, skip
			if(workersRunning[w] == false)
				continue;

			workerToColl[w] :> res;

			if(res.status == TERMINATE) {
				workersRunning[w] = false;
			} else {
				workersRunning[w] = true;
				//printf("Worker %d sent me %d pixels\n", w, res.count);
				c_out <: res;
				noPixels += res.count;

				// Send actual progress to visualizer in percentages
				toVisualizer <: (int)(noPixels * 100 / maxPixels);
			}
		}

		// Check if all workers are alive
		running = false;
		for(int i = 0; i < WORKERNO; ++i) {
			if(workersRunning[i] == true) {
				running = true;
			}
		}
	}

	// Notify output about termination
	res.count = 0;
	res.status = TERMINATE;
	c_out <: res;

	// and do so with visualizer
	toVisualizer <: TERMINATE;
}
