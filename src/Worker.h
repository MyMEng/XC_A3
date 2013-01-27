/*
 * Worker.h
 *
 * Declarations of worker method for bluring
 */
#include "Common.h"
#include "Distributor.h"

#ifndef WORKER_H_
#define WORKER_H_

#define MAXCOUNT 3

typedef struct {

	// Count of processed pixels
	int count;

	// Processed pixels
	uchar pixel[MAXCOUNT];

	int status;

} result_t;

// Worker thread
void worker(chanend distToWorker, chanend workerToColl);

// Blur pixels between start and end in data packet given
uchar average_blur(data_packet_t packet, int start, int end, int j);

// Blur using median filter
unsigned int median_blur(data_packet_t packet, int start, int end, int j);

#endif /* WORKER_H_ */
