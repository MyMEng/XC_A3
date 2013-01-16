/*
 * Common.h
 *
 *  Created on: Jan 16, 2013
 *      Author: Maciek
 */

#ifndef COMMON_H_
#define COMMON_H_

typedef unsigned char uchar;

// Define boolean type
typedef unsigned int bool;
#define true 1
#define false 0

// Image height and width
#define IMHT 16
#define IMWD 16

// Maximum number of workers
#define WORKERNO 4

// Number of pixels to send/process
#define PIXELS 9

// Define black color
#define BLACK 0x0;

// Default delay used by wait moment
#define DEFAULTDELAY 8000000

// WAIT function
// Allow to specify delay
void waitMomentCustom(int delay);

// Use default delay
void waitMoment();


#endif /* COMMON_H_ */
