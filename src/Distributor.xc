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
	bool lines, running, started;

	// No lines are read initially
	lines = false;
	pix = 0;
	running = true;
	started = false;
	totalLines = 0;
	w = 0;
	// Set status to 'paused'
	status = PAUSE;
	sentLine = 0;
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

			// Notify about changed algorithms
			for(int i = 0; i < WORKERNO; i++)
				distToWorker[i] <: p;
			started = true;
		} else if( status == TERMINATE) {
			data_packet_t p;
			p.count = 0;
			p.status = TERMINATE;

			printf("Got terminate\n");

			// Terminate data in stream
			c_in <: TERMINATE;

			// Terminate workers
			for(int i = 0; i < WORKERNO; ++i) {
				printf("Terminate worker %d\n",i);

				distToWorker[i] <: p;
			}

			// Go and terminate yourself
			running = false;
		}

		if(status == PAUSE || status == TERMINATE)
			continue;

		// Read image to an array and save
		if(lines == false) {

			// Fill first row with black
			for( int x = 0; x < IMWD; x++ ) {
				buf[0][x] = BLACK;
			}

			// Read data to new two lines
			for( int y = 1; y < 3; y++ ) {
				c_in <: NEXTLINE;
				for( int x = 0; x < IMWD; x++ ) {
					c_in :> buf[y][x];
				}
			}
			// You read two lines
			totalLines += 2;
			lines = true;
		} else  {



			if(totalLines == IMHT) {
				// Fill black if finished
				for(int i = 0; i < IMWD; i++) {
					// Move image lines up in the buffer
					buf[0][i] = buf[1][i];
					buf[1][i] = buf[2][i];
					buf[2][i] = BLACK;
				}
			} else {
				c_in <: NEXTLINE;
				// Read new line
				for(int i = 0; i < IMWD; i++) {
					// Move image lines up in the buffer
					buf[0][i] = buf[1][i];
					buf[1][i] = buf[2][i];
					c_in :> buf[2][i];
				}
			}
			totalLines++;
		}

		// Now send second lines to workers

		for( pix = 0; pix < IMWD; pix = pix + 3)  {

			// Data packet
			data_packet_t packet;

			packet.status = status;

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
		sentLine++;

		// If you read all lines and processed last one, finish
		if( totalLines == IMHT + 1 ) {
			data_packet_t p;

			printf("Distributor finished\n");
			// No more running
			running = false;

			// Terminate button listener
			fromButtons <: TERMINATE;

			p.count = 0;
			p.status = TERMINATE;

			printf("Got terminate\n");

			// Terminate workers
			for(int i = 0; i < WORKERNO; ++i) {

				printf("Terminate worker %d\n",i);
				distToWorker[i] <: p;
			}
		}
	}
	printf( "ProcessImage:Done...\n" );
}
