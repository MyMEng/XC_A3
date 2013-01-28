#include <platform.h>
#include <stdio.h>

#include "Common.h"
#include "Distributor.h"

//////////////////////////////////////////////////////////////////////////////
//
// Start your implementation by changing this function to farm out
// parts of the image...
//
//////////////////////////////////////////////////////////////////////////////
void distributor(streaming chanend c_in, chanend distToWorker[WORKERNO], chanend fromButtons, chanend toTimer) {

	// Temporary variable to store currently read value
	uchar val;

	// Buffer to store lines read
	line_t buf[3];
	line_t blackLine;

	// Status of the program
	status_t status;

	// Lines read
	int sentLine, line, totalLines;

	// Next worker number
	int w;

	// Remeber current pixel processed
	int pix;

	// Keep track of state
	bool lines, running, started;

	// No lines are read initially
	lines = false;

	// Running initially
	running = true;

	// but not started
	started = false;

	// No lines read
	totalLines = 0;

	// First worker to be 'loaded' with work
	w = 0;

	// Set status to 'paused'
	status = PAUSE;

	// You haven't sent any lines
	sentLine = 0;

	// Set up a line full of black pixels
	for(int i = 0; i < IMWD; ++i) {
		blackLine.data[i] = BLACK;
	}

	while(running) {

		select {
			case fromButtons :> status:
				break;
			default:
				break;
		}

		if(status == CHANGE_ALGORITHM && !started) {
			data_packet_t p;
			p.count = 0;
			p.status = CHANGE_ALGORITHM;
			// Notify about changed algorithms
			for(int i = 0; i < WORKERNO; i++)
				distToWorker[i] <: p;

			// Switch back to pause
			status = PAUSE;
			continue;
		} else if( status == RUNNING && !started ) {
			data_packet_t p;
			p.count = 0;
			p.status = RUNNING;

			// Measure time
			toTimer <: 1;

			// Notify about changed algorithms
			for(int i = 0; i < WORKERNO; i++)
				distToWorker[i] <: p;

			started = true;
		} else if( status == TERMINATE) {

			// If not started and terminated:
			data_packet_t p;

			// No pixels, just sending status
			p.count = 0;
			p.status = TERMINATE;

			// Terminate data in stream
			c_in <: TERMINATE;

			// Terminate workers
			for(int i = 0; i < WORKERNO; ++i) {
				distToWorker[i] <: p;
			}

			// Go and terminate yourself
			running = false;
		}

		// Skip if not running
		if(status == PAUSE || status == TERMINATE)
			continue;

		// Read image to an array and save
		if(lines == false) {

			// Fill first row with black
			buf[0] = blackLine;

			// Read data to new two lines
			for( int y = 1; y < 3; y++ ) {
				line_t line;
				c_in <: NEXTLINE;
				c_in :> line;
				buf[y] = line;
			}
			// You read two lines
			totalLines += 2;
			lines = true;
		} else  {
			// Is it time to finish?
			if(totalLines == IMHT) {
				// Fill black if finished
				for(int i = 0; i < IMWD; i++) {
					// Move image lines up in the buffer
					buf[0] = buf[1];
					buf[1] = buf[2];
					buf[2] = blackLine;
				}
			} else {
				// Otherwise read next line
				line_t line;
				c_in <: NEXTLINE;
				// Read new line
				c_in :> line;
				// Move image lines up in the buffer
				buf[0] = buf[1];
				buf[1] = buf[2];
				buf[2] = line;
			}
			totalLines++;
		}

		// Now send second lines to workers
		for(pix = 0; pix < IMWD; pix = pix + 3) {
			data_packet_t packet = prepare_packet(buf, pix, sentLine);
			packet.status = status;
			distToWorker[w] <: packet;
			w++;
			if(w >= WORKERNO) {
				w = 0;
			}
		}
		// Remember how many lines you sent
		sentLine++;

		// If you read all lines and processed last one, finish
		if( totalLines == IMHT + 1 ) {
			data_packet_t p;

			// No more running
			running = false;

			// Terminate button listener
			fromButtons <: TERMINATE;

			p.count = 0;
			p.status = TERMINATE;

			// Terminate workers
			for(int i = 0; i < WORKERNO; ++i) {
				distToWorker[i] <: p;
			}
		}
	}
	//printf("dist: terminate\n");
}

data_packet_t prepare_packet(line_t buf[3], int pix, int sentLine) {
	// Data packet
	data_packet_t packet;

	// Helper variable
	int val;

	// How many pixels will I send?
	packet.count = 3;

	if(IMWD - pix == 1)
		packet.count = 1;
	else if(IMWD - pix == 2)
		packet.count = 2;

	// First line is entire black
	if(sentLine == 0 || sentLine == IMHT - 1) {
		// First and last line are entierly black
		packet.blacks = packet.count;
	} else if(IMWD - pix == 3) {
		// The only pixel left is black
		packet.blacks = 2;
	} else if(IMWD - pix == 2) {
		// One of two pixels left is black
		packet.blacks = 1;
	} else if(IMWD - pix == 1 || pix == 0) {
		packet.blacks = 0;
	} else {
		packet.blacks = -1; // Nothing is black
	}

	// Send left top
	if( pix - 1 < 0 ) {
		val = BLACK;
	} else {
		val = buf[ 0 ].data[ pix - 1 ];
	}
	packet.pixels[0] = val;

	// Send middle left
	if(  pix - 1 < 0 ) {
		val = BLACK;
	} else {
		val = buf[ 1 ].data[ pix - 1 ];
	}
	packet.pixels[1] = val;

	// Send bottom left
	if( pix - 1 < 0) {
		val = BLACK;
	} else {
		val = buf[ 2 ].data[ pix - 1 ];
	}
	packet.pixels[2] = val;

	// Send top
	val = buf[ 0 ].data[ pix ];
	packet.pixels[3] = val;

	// Send middle
	val = buf[ 1 ].data[ pix ];
	packet.pixels[4] = val;

	val = buf[ 2 ].data[ pix ];
	packet.pixels[5] = val;

	// Send top right
	if( pix + 1 >= IMWD ) {
		val = BLACK;
	} else {
		val = buf[ 0 ].data[ pix + 1 ];
	}
	packet.pixels[6] = val;


	// Send middle right
	if( pix + 1 >= IMWD ) {
		val = BLACK;
	} else {
		val = buf[ 1 ].data[ pix + 1 ];
	}
	packet.pixels[7] = val;

	// Send bottom right
	if(pix + 1 >= IMWD ) {
		val = BLACK;
	} else {
		val = buf[ 2 ].data[ pix + 1 ];
	}

	packet.pixels[8] = val;

	// Send most-right top
	if( pix + 2 >= IMWD) {
		val = BLACK;
	} else {
		val = buf[ 0 ].data[ pix + 2 ];
	}
	packet.pixels[9] = val;

	if( pix + 2 >= IMWD) {
		val = BLACK;
	} else {
		val = buf[ 1 ].data[ pix + 2 ];
	}
	packet.pixels[10] = val;

	// Send bottom right
	if(pix + 2 >= IMWD ) {
		val = BLACK;
	} else {
		val = buf[ 2 ].data[ pix + 2 ];
	}

	packet.pixels[11] = val;

	// Send most-right top
	if( pix + 3 >= IMWD) {
		val = BLACK;
	} else {
		val = buf[ 0 ].data[ pix + 3 ];
	}
	packet.pixels[12] = val;

	if( pix + 3 >= IMWD) {
		val = BLACK;
	} else {
		val = buf[ 1 ].data[ pix + 3 ];
	}
	packet.pixels[13] = val;

	// Send bottom right
	if(pix + 3 >= IMWD ) {
		val = BLACK;
	} else {
		val = buf[ 2 ].data[ pix + 3 ];
	}
	packet.pixels[14] = val;
	return packet;
}
