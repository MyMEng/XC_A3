#include "pgmIO.h"


/***********************************************************/
/* PGM FILE IO ROUTINES                                    */
/***********************************************************/
/****************************************/
/* Read PGM formatted image.            */
/****************************************/
void pgmCommentClear(FILE *disk){
uchar  ch;
fpos_t *pos;
   fread(&ch, 1, 1, disk);
   if (ch != '#') {
      fseek(disk, -1, SEEK_CUR);
      return;
   }
   do {
      while (ch != '\n') fread(&ch, 1, 1, disk);
   } while (ch == '#');
   pgmCommentClear(disk);
}


uchar *PGM_FILE_READ(char *FileName, int *Width, int *Height, int *color) { 
int   x, y, k = 0;
int   pmax;
char  ch;
char  type[3];
uchar *temp;
FILE *disk;
   if ((disk = fopen(FileName, "rb")) == NULL) {
      return NULL;
   }
   fscanf(disk, "%s", &type);
   if (!strcmp(type, "P6")) *color = 1;
                       else *color = 0;
   fread(&ch, 1, 1, disk); 
   pgmCommentClear(disk);
   fscanf(disk, "%d", Width);
   fscanf(disk, "%d", Height);
   fscanf(disk, "%d", &pmax);
   fread(&ch, 1, 1, disk);
   if (*color == 1) {
       temp = (uchar *)calloc(*Height**Width, 3);
       fread(temp, 1, *Height**Width*3, disk);
   } else {
       temp = (uchar *)calloc(*Height**Width, 1);
       fread(temp, 1, *Height**Width, disk);
   }
   fclose(disk);
   return temp;
}


/****************************************/
/* Write PGM formatted image.           */
/****************************************/
void PGM_FILE_WRITE(char *FileName, uchar data[], int targetW, int targetH, int color) {
int   x, y, k = 0;
FILE *disk;
   disk = fopen(FileName, "wb");
   if (color == 1) fprintf(disk, "P6\n");
              else fprintf(disk, "P5\n");
   fprintf(disk, "%d %d\n", targetW, targetH);
   fprintf(disk, "255\n");
   if (color == 1) fwrite(data, 1, targetH*targetW*3, disk);
              else fwrite(data, 1, targetH*targetW, disk);
   fclose(disk);
}

