#include "imshow.h"
#include <stdlib.h>
#include <stdio.h>


int main() {  

    const int width = 600;
    const int height = 900;
    const int bufSize = width * height;
    unsigned char* imageBuffer = (unsigned char*) malloc(bufSize);

    for (int j = 0; j < height; ++j) {
        for (int i = 0; i < width; ++i) {
            imageBuffer[i + width * j] = 255 * (float) i / (float) width;
        }
    }

    if (imshow_u8_c1("My Window", imageBuffer, width, height)) {
        printf("something went wrong\n");
    }

    free(imageBuffer);
    
    return 0;
}