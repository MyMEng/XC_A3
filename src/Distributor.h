/*
 * Distributor.h
 *
 * Contains declarations of distributor functions
 */



#ifndef DISTRIBUTOR_H_
#define DISTRIBUTOR_H_

typedef struct {
	uchar pixels[PIXELS];
	// How many pixels should a worker blur in this packet?
	int count;
	int x, y;
} data_packet_t;

void distributor(chanend c_in, chanend distToWorker[WORKERNO], chanend fromButtons);

#endif // DISTRIBUTOR_H_
