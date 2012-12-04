#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include "pgmio.h"



int createGreyImage(GreyImage *gi, int width, int height) {
    gi->height = height;
    gi->width = width;
    gi->storage = malloc(height * width);
    if (gi->storage == NULL) {
	gi->height = gi->width = 0;
	return 0;
    }
    return 1;
} /* createGreyImage() */




int destroyGreyImage(GreyImage *gi) {
    free(gi->storage);
    gi->height = gi->width = 0;
    return 1; /* always successful! */
} /* destroyGreyImage() */


int readGreyImage(GreyImage *gi, const char *filename) {
    FILE *fimg = fopen(filename,"r");
    int width;
    int height;
    int maxgrey;
    int c;
    int state = 0;
    int retcode;
    size_t amount;
    int finished = 0;
 
    if (fimg == NULL)
	return 0;

    while (!finished) {
	switch (state) {
	case 0:
	    c = fgetc(fimg);
	    if (c != 'P') state = 255;
	    else state = 1;
	    break;
	case 1:
	    c = fgetc(fimg);
	    if (c != '5') state = 255;
	    else state = 2;
	    break;
	case 2:
	    c = fgetc(fimg);
	    if (isspace(c)) state = 3;
	    else state = 255;
	    break;
	case 3:
	    c = fgetc(fimg);
	    if (isdigit(c)) state = 4;
	    else if (c == '#') state = 5;
	    else if (!isspace(c)) state = 255;
	    break;
	case 4:
	    if (ungetc(c,fimg) == EOF) state = 255;
	    else {
		retcode = fscanf(fimg,"%d",&width);
		if (retcode == 0 || retcode == EOF) state = 255;
		else {
		    c = fgetc(fimg);
		    if (isspace(c)) state = 6;
		    else state = 255;
		}
	    }
	    break;
	case 5:
	    c = fgetc(fimg);
	    if (c == EOF) state = 255;
	    else if (c == '\n') state = 3;
	    break;
	case 6:
	    c = fgetc(fimg);
	    if (isdigit(c)) state = 7;
	    else if (c == '#') state = 8;
	    else if (!isspace(c)) state = 255;
	    break;
	case 7:
	    if (ungetc(c,fimg) == EOF) state = 255;
	    else {
		retcode = fscanf(fimg,"%d",&height);
		if (retcode == 0 || retcode == EOF) state = 255;
		else {
		    c = fgetc(fimg);
		    if (isspace(c)) state = 9;
		    else state = 255;
		}
	    }
	    break;
	case 8:
	    c = fgetc(fimg);
	    if (c == EOF) state = 255;
	    else if (c == '\n') state = 6;
	    break;
	case 9:
	    c = fgetc(fimg);
	    if (isdigit(c)) state = 10;
	    else if (c == '#') state = 11;
	    else if (!isspace(c)) state = 255;
	    break;
	case 10:
	    if (ungetc(c,fimg) == EOF) state = 255;
	    else {
		retcode = fscanf(fimg,"%d",&maxgrey);
		if (retcode == 0 || retcode == EOF) state = 255;
		else {
		    c = fgetc(fimg);
		    if (c == '\n') state = 13;
		    else if (isspace(c)) state = 12;
		    else state = 255;
		}
	    }
	    break; 
	case 11:
	    c = fgetc(fimg);
	    if (c == '\n') state = 9;
	    else if (c == EOF) state = 255;
	    break;
	case 12:
	    c = fgetc(fimg);
	    if (c == '\n') state = 13;
	    else if (!isspace(c)) state = 255;
	    break;
	case 13:
	    finished = 1;
	    break;
	case 255:
	    fclose(fimg);
	    return 0;
	}
    } /* while (!finished) */
   
    gi->height = height;
    gi->width = width;
    gi->storage = malloc(height * width);
    
    if (gi->storage == NULL) {
	gi->height = gi->width = 0;
	fclose(fimg);
	return 0;
    }
    
    amount = fread(gi->storage, 1, height*width, fimg);
    if (amount != height*width) {
	gi->height = gi->width = 0;
	free(gi->storage);
	fclose(fimg);
	return 0;
    }
    
    fclose(fimg);
    return 1;
} /* readGrayImage() */




int writeGreyImage(GreyImage *gi, const char *filename) {
    FILE *fimg = fopen(filename,"w");
    size_t amount;
    
    if (fimg == NULL)
	return 0;
    
    fprintf(fimg,"P5\n");
    fprintf(fimg,"#created for DFP course F2002\n");
    fprintf(fimg,"%d %d\n255\n",gi->width, gi->height);
    amount = fwrite(gi->storage, 1,gi->width *  gi->height, fimg);
    if (amount != gi->width *  gi->height) {
	fclose(fimg);
	return 0;
    }
    fclose(fimg);
    return 1;
} /*  writeGreyImage() */
