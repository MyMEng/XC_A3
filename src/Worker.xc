/*
 * Worker.c
 *
 * Definition of worker
 */
#include <platform.h>
#include "Worker.h"
#include "Common.h"
#include "Distributor.h"
#include <stdio.h>
/////////////////////////////////////////////////////////////////////////////////////////
//
// Process a chunk of pixels
//
/////////////////////////////////////////////////////////////////////////////////////////
void worker(chanend distToWorker, chanend workerToColl) {
	// Flag indicating state of worker
	bool running, started;

	// Store value sent from the distributor
	data_packet_t packet;

	// Remeber average of nine pixels
	int result;

	// Worker status
	status_t status;

	filter_t filter;

	// processing result
	result_t res;

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
		bool isBlack;

		isBlack = false;
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

		select {
			case workerToColl :> status:
				break;
			default:
				break;
		}
		if(status == FINISHED) {
			distToWorker <: FINISHED;
			running = false;
			break;
		}
		if(status == PAUSE) continue;


		select {
			case workerToColl :> status:
				break;
			case distToWorker :> packet:
				break;
		}


		if(status == FINISHED) {
			distToWorker <: FINISHED;
			running = false;
			break;
		}

		res.count = packet.count;


		for(int j = 0; j < packet.count; j++) {
			int start, end; // Start end indices of pixel and surrounding

			start = j * 3;
			end = 9 + (j * 3);

			if( filter == AVG ) {
				result = 0;

				if(packet.blacks == packet.count || packet.blacks == j) {
					res.pixel[j] = BLACK;
				} else {
					// Sum all pixels
					for(int i = start; i < end; i++) {
						result += (int)packet.pixels[i];
					}
					// Take the average
					result /= 9;

					res.pixel[j] = (uchar)result;
					//printf("Result: %d\n", result);
				}

			} else if( filter == MEDIAN ){
				// Border pixel, don't bother doing anything
				if(packet.blacks == packet.count || packet.blacks == j) {
					res.pixel[j] = BLACK;
				} else {
					uchar vals[9];
					for(int i = start, k=0; i < end; ++i, ++k) {
						vals[k] = packet.pixels[i];
					}
					// Put pixels to array
					for(int i = 0; i < 9; ++i) {
						int temp = 0;
						int min = i;
						for(int y = i; y < 9; y ++) {
							if(vals[min] > vals[y]) {
								min = y;
							}
						}
						temp = vals[i];
						vals[i] = vals[min];
						vals[min] = temp;
					}

					result = vals[4];

					res.pixel[j] = (uchar)result;
				}
			}
		}
		// Send result to a collector
		workerToColl <: res;
	}


}

