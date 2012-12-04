/***********************************************************/
/*                                                         */
/* PGM                                                     */
/*                                                         */
/***********************************************************/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>


/***********************************************************/
/* GLOBAL DEFINES                                          */
/***********************************************************/
typedef unsigned char uchar;


/***********************************************************/
/* FUNTION PROTOTYPES                                      */
/***********************************************************/
uchar *PGM_FILE_READ(char *filename, int *targetW, int *targetH, int *color);
void PGM_FILE_WRITE(char *filename, uchar data[], int targetW, int targetH, int color);

