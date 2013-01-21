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
	bool running, started;

	// Store value sent from the distributor
	uchar temp;

	// Remeber average of nine pixels
	int result;

	// Worker status
	status_t status;

	filter_t filter;

	// Set running to true
	running = true;

	// Default filter
	filter = AVG;

	// Status of worker is initally pause
	status = PAUSE;

	started = false;

	// Be ready to process threads
	while(running) {
		status_t old_status;

		result = 0;
		old_status = status;

		if(!started) {
			select {
				case distToWorker :> status:
					break;
				default:
					break;
			}

			if(status == RUNNING) {
				started = true;
				continue;
			}

			if(status == CHANGE_ALGORITHM) {
				if(filter == AVG) filter = MEDIAN;
				else if(filter == MEDIAN) filter = AVG;
				status = old_status;
			}
		}

		if(status == PAUSE) continue;

		if( filter == AVG ) {
			// Get pixels to blur from the distributor
			for(int i = 0; i < PIXELS; i++) {
				distToWorker :> temp;
				result += (int)temp;
			}

			// Take the average
			result /= PIXELS;
		} else if( filter == MEDIAN ){
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

