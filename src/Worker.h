/*
 * Worker.h
 *
 * Declarations of worker method for bluring
 */
#include "Common.h"

#ifndef WORKER_H_
#define WORKER_H_

#define MAXCOUNT 3

typedef struct {

	// Count of processed pixels
	int count;

	// Processed pixels
	uchar pixel[MAXCOUNT];

} result_t;

void worker(chanend distToWorker, chanend workerToColl);

#endif /* WORKER_H_ */
