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
void DataInStream(char infname[], streaming chanend c_out) {
	int res, signal;
	line_t line;
	//printf( "DataInStream:Start...\n" );
	res = _openinpgm( infname, IMWD, IMHT );
	if( res) {
		printf( "DataInStream:Error openening %s\n.", infname );
		return;
	}

	for( int y = 0; y < IMHT; y++ ){
		_readinline( line.data, IMWD );

		select {
			case c_out :> signal:
				if(signal ==  TERMINATE) {
					_closeinpgm();
					//printf( "DataInStream:Done...\n" );
					return;
				} else if (signal == NEXTLINE) {
					c_out <: line;
				}
				break;
		}
				//uncomment to show image values
		//printf( "\n" );
	}

	_closeinpgm();
	//printf( "DataInStream:Done...\n" );
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Write pixel stream from channel c_in to pgm image file
//
/////////////////////////////////////////////////////////////////////////////////////////
void DataOutStream(char outfname[], chanend c_in) {
	int ret;
	uchar line[ IMWD ];
	int count;
	result_t res;
	bool running;

	running = true;
	count = 0;
	//printf( "DataOutStream:Start...\n" );
	ret = _openoutpgm( outfname, IMWD, IMHT );

	if( ret ) {
		printf( "DataOutStream:Error opening %s\n.", outfname );
		return;
	}

	while(running) {
		c_in :> res;

		if(res.status == TERMINATE) {
			//printf("Going to send terminate\n");
		   _closeoutpgm();
			running = false;
			continue;
	   } else {
		   // Read pixels sent into the line
		   for(int i = 0; i < res.count; ++i) {
			line[count] = res.pixel[i];
			count++;
			// If line buffer is full, write it to the file
			if(count >= IMWD) {
				count = 0;
				_writeoutline(line, IMWD);
			}
         }
	   }
	}
	//printf("Going to send terminate\n");
}

//MAIN PROCESS defining channels, orchestrating and starting the threads
int main() {

	//Channels from data in and to data out
	streaming chan c_inIO;
	chan c_outIO;

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
			on stdcore[(i%3)+1] : worker( distToWorker[i], workerToColl[i] );
		}

		// Start collector worker
		on stdcore[3] : collector(workerToColl, c_outIO, collToVisualizer);

		on stdcore[3] : DataOutStream( outfname, c_outIO );
	}


	return 0;
}
