/*
 * Distributor.h
 *
 * Contains declarations of distributor functions
 */

#ifndef DISTRIBUTOR_H_
#define DISTRIBUTOR_H_

// Data packet for workers
typedef struct {
	// Pixel set to process
	uchar pixels[PIXELS];

	// Should any of them be black? (for borders)
	int blacks;

	// How many pixels should a worker blur in this packet?
	unsigned int count;

	// Distributor status
	int status;
} data_packet_t;

// Line from data_in
typedef struct {
	uchar data[IMWD];
} line_t;

// Prepares packet of data for a given pixel in a buffer of three lines
data_packet_t prepare_packet(line_t buffer[3], int pix, int sentLine);

// Distributor thread
void distributor(streaming chanend c_in, chanend distToWorker[WORKERNO], chanend fromButtons);

#endif // DISTRIBUTOR_H_
