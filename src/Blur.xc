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
void distributor(chanend c_in, chanend c_out) {
	uchar val;
	uchar image[ IMHT][IMWD];
	printf( "ProcessImage:Start, size = %dx%d\n", IMHT, IMWD );

	//This code is to be replaced � it is a place holder for farming out the work...

	// Read image to array and save
	for( int y = 0; y < IMHT; y++ ) {
		for( int x = 0; x < IMWD; x++ ) {
			c_in :> image[y][x];
			//image[y][x] = val;

		}
	}

	printf("Reading finished\n");

	for( int y = 0; y < IMHT; y++)  {
		for( int x = 0; x < IMWD; x++ ) {
			c_out <: image[y][x];
		}
	}

	printf( "ProcessImage:Done...\n" );
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
	//put your input image path here
	char infname[] = "D:\\test.pgm";

	//put your output image path here
	char outfname[] = "D:\\testout.pgm";

	//extend your channel definitions here
	chan c_inIO, c_outIO;

	//extend/change this par statement to implement your concurrent filter
	par {
		DataInStream( infname, c_inIO );
		distributor( c_inIO, c_outIO );
		DataOutStream( outfname, c_outIO );
	}

	printf( "Main:Done...\n" );
	return 0;
}
