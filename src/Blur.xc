/////////////////////////////////////////////////////////////////////////////
//
// COMS20600 - WEEKS 9 to 12
// ASSIGNMENT 3
// CODE SKELETON
// TITLE: "Concurrent Image Filter"
//
/////////////////////////////////////////////////////////////////////////////
typedef unsigned char uchar;

// Define boolean type
typedef unsigned int bool;
#define true 1
#define false 0

#include <platform.h>
#include <stdio.h>
#include "pgmIO.h"
#define IMHT 16
#define IMWD 16

// Maximum number of workers
#define WORKERNO 4

// Number of pixels to send/process
#define PIXELS 9

// Define black color
#define BLACK 0xFF;

// input image path
char infname[] = "D:\\test.pgm";

// output image path
char outfname[] = "D:\\testout.pgm";

/////////////////////////////////////////////////////////////////////////////
//
// Read Image from pgm file with path and name infname[] to channel c_out
//
/////////////////////////////////////////////////////////////////////////////
void DataInStream(char infname[], chanend c_out) {
	int res;
	uchar line[ IMWD ];
	printf( "DataInStream:Start...\n" );
	res = _openinpgm( infname, IMWD, IMHT );
	if( res) {
		printf( "DataInStream:Error openening %s\n.", infname );
		return;
	}

	for( int y = 0; y < IMHT; y++ ){
		_readinline( line, IMWD );

		for( int x = 0; x < IMWD; x++ ) {
			c_out <: line[ x ];
			//uncomment to show image values
			//printf( "-%4.1d ", line[ x ] );
		}
		//uncomment to show image values
		//printf( "\n" );
	}

	_closeinpgm();
	printf( "DataInStream:Done...\n" );
	return;
}

//////////////////////////////////////////////////////////////////////////////
//
// Start your implementation by changing this function to farm out
// parts of the image...
//
//////////////////////////////////////////////////////////////////////////////
void distributor(chanend c_in, chanend distToWorker[WORKERNO]) {

	// Temporary variable to store currently read value
	uchar val;

	// Buffer to store lines read
	uchar buf[3][IMWD];

	// Lines read
	int sentLine, line, totalLines;

	// Remeber current pixel processed
	int pix;
	bool lines, running;
	// No lines are read initially
	lines = false;
	pix = 0;
	running = true;
	totalLines = 0;

	while(running) {
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
		} else {

			for(int i = 0; i < IMWD; i++) {
				// Move image lines up in the buffer
				buf[0][i] = buf[1][i];
				buf[1][i] = buf[2][i];
				// Read new line
				c_in :> buf[2][i];
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

		if( totalLines == IMHT ) {
			running = false;
		}
	}

	printf( "ProcessImage:Done...\n" );
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Process a chunk of pixels
//
/////////////////////////////////////////////////////////////////////////////////////////
void worker(chanend distToWorker, chanend workerToColl) {
	// Flag indicating state of worker
	bool running;

	// Store value sent from the distributor
	uchar temp;

	// Remeber average of nine pixels
	uchar average;

	// Set running to true
	running = true;


	// Be ready to process threads
	while(running) {

		average = 0;

		// Get pixels to blur from the distributor
		for(int i = 0; i < PIXELS; i++) {
			distToWorker :> temp;
			average += temp;
		}

		// Take the average
		average /= PIXELS;

		// Send result to a collector
		workerToColl <: average;
	}


}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Collect results from workers and send to data stream
//
/////////////////////////////////////////////////////////////////////////////////////////
void collector(chanend workerToColl[WORKERNO], chanend c_out) {
	// Declare variables
	bool running;	// Is collector runnning?
	uchar pixel;	// Buffer
	int noPixels;	// Number of pixels read
	int lines;		// Number of lines

	// Initialize variables
	running = true;
	noPixels = 0;
	lines = 0;

	while(running) {
		for(int  w = 0; w < WORKERNO; w++  ) {
			workerToColl[w] :> pixel;
			c_out <: pixel;
			noPixels++;
		}
		if(noPixels == IMHT*IMWD) {
			running = false;
		}
	}
	printf("Collector finished...\n");
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Write pixel stream from channel c_in to pgm image file
//
/////////////////////////////////////////////////////////////////////////////////////////
void DataOutStream(char outfname[], chanend c_in) {
	int res;
	uchar line[ IMWD ];

	printf( "DataOutStream:Start...\n" );
	res = _openoutpgm( outfname, IMWD, IMHT );

	if( res ) {
		printf( "DataOutStream:Error opening %s\n.", outfname );
		return;
	}
	for( int y = 0; y < IMHT; y++ ) {
		for( int x = 0; x < IMWD; x++ ) {
	   c_in :> line[ x ];
		  //printf( "+%4.1d ", line[ x ] );
		}
		//printf( "\n" );
		_writeoutline( line, IMWD );
	}
	_closeoutpgm();
	printf( "DataOutStream:Done...\n" );
	return;
}

//MAIN PROCESS defining channels, orchestrating and starting the threads
int main() {


	//extend your channel definitions here
	chan c_inIO, c_outIO;

	// Channels between distributor and workers
	chan distToWorker[WORKERNO];

	// Channels between workers and collectors
	chan workerToColl[WORKERNO];

	//extend/change this par statement to implement your concurrent filter
	par {
		on stdcore[0] : DataInStream( infname, c_inIO );

		// Start distributor thread and connect it with workers
		on stdcore[0] : distributor( c_inIO, distToWorker );

		// Spin-off worker threads
		// Make sure they run on separate cores
		par(int i = 0; i < WORKERNO; i++) {
			on stdcore[i%4] : worker(distToWorker[i], workerToColl[i]);
		}

		// Start collector worker
		on stdcore[3] : collector(workerToColl, c_outIO);

		on stdcore[3] : DataOutStream( outfname, c_outIO );
	}


	return 0;
}
