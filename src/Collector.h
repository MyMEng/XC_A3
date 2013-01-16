/*
 * Collector.h
 *
 * Contains declarations of collector functions 
 */

#ifndef COLLECTOR_H_
#define COLLECTOR_H_

/////////////////////////////////////////////////////////////////////////////////////////
//
// Collect results from workers and send to data stream
//
/////////////////////////////////////////////////////////////////////////////////////////
void collector(chanend workerToColl[WORKERNO], chanend c_out, chanend toVisualizer);

#endif /* COLLECTOR_H_ */
