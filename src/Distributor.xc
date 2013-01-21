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
void distributor(chanend c_in, chanend distToWorker[WORKERNO], chanend fromButtons) {

	// Temporary variable to store currently read value
	uchar val;

	// Buffer to store lines read
	uchar buf[3][IMWD];

	// Status of the program
	status_t status;

	// Lines read
	int sentLine, line, totalLines;

	// Remeber current pixel processed
	int pix;
	bool lines, running, started;

	// No lines are read initially
	lines = false;
	pix = 0;
	running = true;
	started = false;
	totalLines = 0;

	// Set status to 'paused'
	status = PAUSE;

	while(running) {

		select {
			case fromButtons :> status:
				break;
			default:
				break;
		}

		if(status == PAUSE)
			continue;

		if(status == CHANGE_ALGORITHM && !started) {

			// Notify about changed algorithms
			for(int i = 0; i < WORKERNO; i++)
				distToWorker[i] <: CHANGE_ALGORITHM;

			// Switch back to pause
			status = PAUSE;
			continue;
		}

		// Read image to an array and save
		if(lines == false) {
			// Fill first row with black
			for( int x = 0; x < IMWD; x++ ) {
				buf[0][x] = BLACK;

			}
			// Read data to new two lines

			for( int y = 1; y < 3; y++ ) {
				for( int x = 0; x < IMWD; x++ ) {
					c_in :> buf[y][x];
				}
			}
			// You read two lines
			totalLines += 2;
			lines = true;
		} else  {

			for(int i = 0; i < IMWD; i++) {
				// Move image lines up in the buffer
				buf[0][i] = buf[1][i];
				buf[1][i] = buf[2][i];

				if(totalLines == IMHT) {
					// Fill black if finished
					buf[2][i] = BLACK;
				} else {
					// Read new line
					c_in :> buf[2][i];
				}
			}
			totalLines++;
		}

		// Now send second lines to workers
		sentLine = 1;
		for( pix = 0; pix < IMWD; pix++)  {

			int w; // Worker number
			w = pix % WORKERNO;
			// Top line

			// Send left top
			if( pix - 1 < 0 ) {
				val = BLACK;
			} else {
				val = buf[ 0 ][ pix - 1 ];
			}
			distToWorker[ w ] <: val;


			// Send top
			val = buf[ 0 ][ pix ];
			distToWorker[ w ] <: val;

			// Send top right
			if( pix + 1 >= IMWD ) {
				val = BLACK;
			} else {
				val = buf[ 0 ][ pix + 1 ];
			}
			distToWorker[ w ] <: val;

			// Send middle left
			if(  pix - 1 < 0 ) {
				val = BLACK;
			} else {
				val = buf[ 1 ][ pix - 1 ];
			}
			distToWorker[w] <: val;

			// Send middle
			val = buf[ 1 ][ pix ];
			distToWorker[ w ] <: val;

			// Send middle right
			if( pix + 1 >= IMWD ) {
				val = BLACK;
			} else {
				val = buf[ 1 ][ pix + 1 ];
			}
			distToWorker[ w ] <: val;

			// Send bottom left
			if( pix - 1 < 0) {
				val = BLACK;
			} else {
				val = buf[ 2 ][ pix - 1 ];
			}
			distToWorker[ w ] <: val;

			val = buf[ 2 ][ pix ];
			distToWorker[ w ] <: val;

			// Send bottom right
			if( line < 0 || pix + 1 >= IMWD ) {
				val = BLACK;
			} else {
				val = buf[ 2 ][ pix + 1 ];
			}

			distToWorker[ w ] <: val;
		}

		// If you read all lines and processed last one, finish
		if( totalLines == IMHT + 1 ) {
			running = false;
		}
	}

	printf( "ProcessImage:Done...\n" );
}
