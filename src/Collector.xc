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
	for(int i = 0; i < WORKERNO; ++i)
		workersRunning[i] = true;

	while(running) {
		int status;

		for(int  w = 0; w < WORKERNO; ++w ) {

			if(!workersRunning[w])
				continue;

			select {
				case c_out :> signal:
					running = false;
					//printf("Got finished signal in collector\n");
					break;
				case workerToColl[w] :> res:

					if(res.status == TERMINATE) {
						workersRunning[w] = false;
					} else {
						//printf("Worker %d sent me %d pixels\n", w, res.count);
						for(int i = 0; i < res.count; ++i) {
							c_out <: res.pixel[i];
						}
						noPixels += res.count;
						toVisualizer <: (int)(noPixels * 100 / maxPixels);

					}
					break;
			}

			// Check if all workers are alive
			for(int i = 0; i < WORKERNO; ++i) {
				running = running & workersRunning[i];
			}
		}
	}

	printf("Collector send terminate to c_out\n");
	c_out <: (uchar)TERMINATE;
	toVisualizer <: TERMINATE;

	printf("Collector finished...\n");
}
