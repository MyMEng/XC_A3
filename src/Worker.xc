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

		old_status = status;
		result = 0;
		packet.count = 0;

		if(!started) {
			select {
				case distToWorker :> packet:
					status = packet.status;
					break;
				default:
					break;
			}

			if(status == RUNNING) {
				started = true;
				continue;
			} else if(status == CHANGE_ALGORITHM) {
				if(filter == AVG) filter = MEDIAN;
				else if(filter == MEDIAN) filter = AVG;
				status = old_status;
			}
		}

		select {
			case distToWorker :> packet:
				status = packet.status;
				break;
			default:
				break;
		}

		res.status = status;

		if(status == TERMINATE) {
			//printf("Worker sending termiante to collector\n");
			res.count = 0;
			res.status = TERMINATE;
			workerToColl <: res;
			running = false;
			continue;
		}

		if(status == PAUSE) continue;

		select {
			case distToWorker :> packet:
				status = packet.status;
				break;
			default:
				break;
		}

		// Nothing to be processed, skip
		if(packet.count == 0)
			continue;

		res.count = packet.count;

		for(int j = 0; j < packet.count; j++) {
			int start, end; // Start end indices of pixel and surrounding

			start = j * 3;
			end = 9 + (j * 3);

			switch(filter) {
			case AVG:
				res.pixel[j] = (uchar)average_blur(packet, start, end, j);
				break;
			case MEDIAN:
				res.pixel[j] = (uchar)median_blur(packet, start, end, j);
				break;
			}
		}
		// Send result to a collector
		workerToColl <: res;
	}
}

uchar average_blur(data_packet_t packet, int start, int end, int j) {
	uchar result;
	int sum;
	sum = 0;
	if(packet.blacks == packet.count || packet.blacks == j) {
		result = BLACK;
	} else {
		// Sum all pixels
		for(int i = start; i < end; i++) {
			sum += (int)packet.pixels[i];
		}
		// Take the average
		sum /= 9;
	}

	result = (uchar)sum;
	return result;
}

unsigned int median_blur(data_packet_t packet, int start, int end, int j) {
	unsigned int result;
	// Border pixel, don't bother doing anything
	if(packet.blacks == packet.count || packet.blacks == j) {
		result = BLACK;
	} else {
		int vals[9];
		for(int i = start, k=0; i < end; ++i, ++k) {
			vals[k] = (unsigned int)packet.pixels[i];
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
	}
	return result;
}

