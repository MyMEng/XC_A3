/////////////////////////////////////////////////////////////////////////////
//
// COMS20600 - WEEKS 9 to 12
// ASSIGNMENT 3
// CODE SKELETON
// TITLE: "Concurrent Image Filter"
//
/////////////////////////////////////////////////////////////////////////////
typedef unsigned char uchar;
#include <platform.h>
#include <stdio.h>
#include "pgmIO.h"
#define IMHT 16
#define IMWD 16
#define WORKERNO 4

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
	uchar val;
	uchar buf[IMHT][IMWD];

	//This code is to be replaced � it is a place holder for farming out the work...

	// Read image to array and save
	for( int y = 0; y < IMHT; y++ ) {
		for( int x = 0; x < IMWD; x++ ) {
			c_in :> val;
		}
	}

	printf("Reading finished\n");

	for( int y = 0; y < IMHT; y++)  {
		for( int x = 0; x < IMWD; x++ ) {
			distToWorker[0] <: val;
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

}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Collect results from workers and send to data stream
//
/////////////////////////////////////////////////////////////////////////////////////////
void collector(chanend workerToColl[WORKERNO], chanend c_out) {

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
		on stdcore[0] :distributor( c_inIO, distToWorker );

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
