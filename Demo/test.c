#include "imshow.h"
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

int main()
{  

    const int width = 600;
    const int height = 800;
    const int bufSize = width * height;
    unsigned char* imageBuffer = (unsigned char*) malloc(bufSize);

    for (int j = 0; j < height; ++j) {
        for (int i = 0; i < width; ++i) {
            imageBuffer[i + width * j] = 255 * (float) i / (float) width;
        }
    }

    for (int i = 0; i < width * height; ++i) {
        if (imshow_u8_c1("My Window", imageBuffer, width, height)) {
            break;
        }
        imageBuffer[i] = 0;
    }

    free(imageBuffer);
    
    return 0;
}