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
#define IMHT 64
#define IMWD 100

// Maximum number of workers
#define WORKERNO 9

// Status of application must be greater than 257 not to confuse it with a value of a pixel
typedef enum {
	PAUSE = 257,
	RUNNING = 258,
	TERMINATE = 259,
	NEXTLINE = 400
} status_t;

// Define avaliable filters
typedef enum {
	AVG = 260,
	MEDIAN = 261,
	CHANGE_ALGORITHM = 262
} filter_t;

// Number of pixels to send/process
#define PIXELS 15

// Define black color
#define BLACK 0

// Default delay used by wait moment
#define DEFAULTDELAY 8000000

// WAIT function
// Allow to specify delay
void waitMomentCustom(int delay);

// Use default delay
void waitMoment();

#endif /* COMMON_H_ */
