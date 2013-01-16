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
	int result;

	bool buttonDpressed;

	// Set running to true
	running = true;

	//Status of button D
	buttonDpressed = true;

	// Be ready to process threads
	while(running) {

		result = 0;

		if(buttonDpressed == false) {
			// Get pixels to blur from the distributor
			for(int i = 0; i < PIXELS; i++) {
				distToWorker :> temp;
				result += (int)temp;
			}

			// Take the average
			result /= PIXELS;
		} else {
			int val[9];

			// Put pixels to array
			for(int i = 0; i < PIXELS; i++) {
				distToWorker :> temp;
				val[i] = (int)temp;
			}

			for(int i = 0; i < 9; i ++) {
				int temp;
				int min = i;
				for(int y = i; y < 9; y ++) {
					if(val[min] > val[y]) {
						min = y;
					}
				}
				temp = val[i];
				val[i] = val[min];
				val[min] = temp;
			}
			result = val[4];
		}

		/*
		result += 50;

		if(result > 255) {
			result = 255;
		} else if(result < 0) {
			result = 0;
		}
		*/


		// Send result to a collector
		workerToColl <: (uchar)result;
	}


}

