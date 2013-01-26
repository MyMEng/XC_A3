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

	// Next worker number
	int w;

	// Remeber current pixel processed
	int pix;
	bool lines, running, started, processing;

	// No lines are read initially
	lines = false;
	pix = 0;
	running = true;
	started = false;
	processing = true;
	totalLines = 0;
	w = 0;
	// Set status to 'paused'
	status = PAUSE;

	while(running) {

		select {
			case fromButtons :> status:
				break;
			default:
				break;
		}

		if(status == CHANGE_ALGORITHM && !started) {

			// Notify about changed algorithms
			for(int i = 0; i < WORKERNO; i++)
				distToWorker[i] <: CHANGE_ALGORITHM;

			// Switch back to pause
			status = PAUSE;
			continue;
		} else if( status == RUNNING && !started ) {
			// Notify about changed algorithms
			for(int i = 0; i < WORKERNO; i++)
				distToWorker[i] <: RUNNING;
			started = true;
		}

		if(status == PAUSE)
			continue;

		// Listen for workers
		for(int i = 0; i < WORKERNO; i++) {
			select {
				case distToWorker[i] :> status:
					if(status == FINISHED) {
						running = false;
						processing = false;
					}
				break;
				default:
					break;
			}
		}
		if(processing == false) {
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
		for( pix = 0; pix < IMWD; pix = pix + 3)  {

			// Data packet
			data_packet_t packet;


			// How many pixels will I send?
			packet.count = 3;

			if(IMWD - pix == 1)
				packet.count = 1;
			else if(IMWD - pix == 2)
				packet.count = 2;

			// Send left top
			if( pix - 1 < 0 ) {
				val = BLACK;
			} else {
				val = buf[ 0 ][ pix - 1 ];
			}
			packet.pixels[0] = val;

			// Send middle left
			if(  pix - 1 < 0 ) {
				val = BLACK;
			} else {
				val = buf[ 1 ][ pix - 1 ];
			}
			packet.pixels[1] = val;

			// Send bottom left
			if( pix - 1 < 0) {
				val = BLACK;
			} else {
				val = buf[ 2 ][ pix - 1 ];
			}
			packet.pixels[2] = val;

			// Send top
			val = buf[ 0 ][ pix ];
			packet.pixels[3] = val;

			// Send middle
			val = buf[ 1 ][ pix ];
			packet.pixels[4] = val;

			val = buf[ 2 ][ pix ];
			packet.pixels[5] = val;

			// Send top right
			if( pix + 1 >= IMWD ) {
				val = BLACK;
			} else {
				val = buf[ 0 ][ pix + 1 ];
			}
			packet.pixels[6] = val;


			// Send middle right
			if( pix + 1 >= IMWD ) {
				val = BLACK;
			} else {
				val = buf[ 1 ][ pix + 1 ];
			}
			packet.pixels[7] = val;

			// Send bottom right
			if( line < 0 || pix + 1 >= IMWD ) {
				val = BLACK;
			} else {
				val = buf[ 2 ][ pix + 1 ];
			}

			packet.pixels[8] = val;

			// Send most-right top
			if( pix + 2 >= IMWD) {
				val = BLACK;
			} else {
				val = buf[ 0 ][ pix + 2 ];
			}
			packet.pixels[9] = val;

			if( pix + 2 >= IMWD) {
				val = BLACK;
			} else {
				val = buf[ 1 ][ pix + 2 ];
			}
			packet.pixels[10] = val;

			// Send bottom right
			if(pix + 2 >= IMWD ) {
				val = BLACK;
			} else {
				val = buf[ 2 ][ pix + 2 ];
			}

			packet.pixels[11] = val;

			// Send most-right top
			if( pix + 3 >= IMWD) {
				val = BLACK;
			} else {
				val = buf[ 0 ][ pix + 3 ];
			}
			packet.pixels[12] = val;

			if( pix + 3 >= IMWD) {
				val = BLACK;
			} else {
				val = buf[ 1 ][ pix + 3 ];
			}
			packet.pixels[13] = val;

			// Send bottom right
			if(pix + 3 >= IMWD ) {
				val = BLACK;
			} else {
				val = buf[ 2 ][ pix + 3 ];
			}

			packet.pixels[14] = val;

			distToWorker[w] <: packet;
			w++;
			if(w >= WORKERNO)
				w = 0;
		}

		// If you read all lines and processed last one, finish
		if( totalLines == IMHT + 1 ) {
			processing = false;
		}
	}
	c_in <: FINISHED;
	printf( "ProcessImage:Done...\n" );
}
