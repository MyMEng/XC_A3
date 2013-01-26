/////////////////////////////////////////////////////////////////////////////
//
// COMS20600 - WEEKS 9 to 12
// ASSIGNMENT 3
// CODE SKELETON
// TITLE: "Concurrent Image Filter"
//
/////////////////////////////////////////////////////////////////////////////


#include <platform.h>
#include <stdio.h>
#include "pgmIO.h"

// Include necessary files
#include "Common.h"
#include "Distributor.h"
#include "Worker.h"
#include "Collector.h"
#include "Visualizer.h"
#include "Buttons.h"

// input image path
//char infname[] = "D:\\test.pgm";


//#if defined(WIN32) || defined (__CYGWIN__)
	#define INPATH "D:\\test.pgm"
	#define OUTPATH "D:\\testout.pgm"
//#elif defined(__LINUX__) || defined (__linux__) || defined (__APPLE__)
//	#define INPATH "/Users/kacper/XMOS/XC_A3/test0.pgm"
//	#define OUTPATH "/Users/kacper/XMOS/XC_A3/testOUT.pgm"
//#endif

char infname[] = INPATH;

// output image path
//char outfname[] = "D:\\testout.pgm";
char outfname[] = OUTPATH;

// define ports for led visualization
out port cled0 = PORT_CLOCKLED_0;
out port cled1 = PORT_CLOCKLED_1;
out port cled2 = PORT_CLOCKLED_2;
out port cled3 = PORT_CLOCKLED_3;

in port buttons = PORT_BUTTON;
out port speaker = PORT_SPEAKER;
/////////////////////////////////////////////////////////////////////////////
//
// Read Image from pgm file with path and name infname[] to channel c_out
//
/////////////////////////////////////////////////////////////////////////////
void DataInStream(char infname[], chanend c_out) {
	int res, signal;
	uchar line[ IMWD ];
	printf( "DataInStream:Start...\n" );
	res = _openinpgm( infname, IMWD, IMHT );
	if( res) {
		printf( "DataInStream:Error openening %s\n.", infname );
		return;
	}

	for( int y = 0; y < IMHT; y++ ){
		_readinline( line, IMWD );

		select {
			case c_out :> signal:
				if(signal ==  TERMINATE) {
					_closeinpgm();
					printf( "DataInStream:Done...\n" );
					return;
				} else if (signal == NEXTLINE) {
					for( int x = 0; x < IMWD; x++ ) {
						c_out <: line[ x ];
					}
				}
				break;
		}
				//uncomment to show image values
		//printf( "\n" );
	}

	_closeinpgm();
	printf( "DataInStream:Done...\n" );
	return;
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Write pixel stream from channel c_in to pgm image file
//
/////////////////////////////////////////////////////////////////////////////////////////
void DataOutStream(char outfname[], chanend c_in) {
	int res;
	uchar line[ IMWD ];
	uchar temp;

	printf( "DataOutStream:Start...\n" );
	res = _openoutpgm( outfname, IMWD, IMHT );

	if( res ) {
		printf( "DataOutStream:Error opening %s\n.", outfname );
		return;
	}
	for( int y = 0; y < IMHT; y++ ) {
		for( int x = 0; x < IMWD; x++ ) {
		   c_in :> temp;

		   if(temp == (uchar)(TERMINATE)) {
			   printf( "DataOutStream: close output\n" );
			   _closeoutpgm();
			   	printf( "DataOutStream: Terminate\n" );
			   	return;
		   } else {
			   line[x] = temp;
		   }
		  //printf( "+%4.1d ", line[ x ] );
		}
		//printf( "\n" );
		_writeoutline( line, IMWD );
	}
	_closeoutpgm();

	// Wait for terminate to come
	c_in :> temp;
	printf( "DataOutStream: close output\n" );

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

	// Channel from buttons to distributor
	chan buttonsToDistributor;

	// Channel between collector and visualizer
	chan collToVisualizer;

	// Helper channels for LED visualisation
	chan quadrant0, quadrant1, quadrant2, quadrant3;

	//extend/change this par statement to implement your concurrent filter
	par {
		on stdcore[0] : DataInStream( infname, c_inIO );

		on stdcore[0] : buttonListener(buttons, speaker, buttonsToDistributor);

		// Start distributor thread and connect it with workers
		on stdcore[0] : distributor( c_inIO, distToWorker, buttonsToDistributor );

		on stdcore[0] : visualiser( collToVisualizer, quadrant0, quadrant1, quadrant2, quadrant3 );
		on stdcore[0]: showLED( cled0, quadrant0 );
		on stdcore[1]: showLED( cled1, quadrant1 );
		on stdcore[2]: showLED( cled2, quadrant2 );
		on stdcore[3]: showLED( cled3, quadrant3 );

		// Spin-off worker threads
		// Make sure they run on separate cores
		par( int i = 0; i < WORKERNO; i++ ) {
			on stdcore[i%4] : worker( distToWorker[i], workerToColl[i] );
		}

		// Start collector worker
		on stdcore[3] : collector(workerToColl, c_outIO, collToVisualizer);

		on stdcore[3] : DataOutStream( outfname, c_outIO );
	}


	return 0;
}
