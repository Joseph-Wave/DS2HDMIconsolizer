#include <nds.h>

#include <stdio.h>

// git adds a nice header we can include to access the data
// this has the same name as the image
#include "drunkenlogo.h"

int main(void)
{
    // set the mode for 2 text layers and two extended background layers
	videoSetMode(MODE_5_2D);
    vramSetBankA(VRAM_A_MAIN_BG_0x06000000);

	consoleDemoInit();

	iprintf("\t256 color bitmap demo\n");
	iprintf("\t START to switch screens\n");

	int bg3 = bgInit(3, BgType_Bmp8, BgSize_B8_256x256, 0,0);

	dmaCopy(drunkenlogoBitmap, bgGetGfxPtr(bg3), 256*256);
	dmaCopy(drunkenlogoPal, BG_PALETTE, 256*2);

	lcdMainOnBottom();
	
	bool main_scr = true;

	while(1) {
		swiWaitForVBlank();
		
		int keys = 0;

		while(!keys) {
			scanKeys();
			keys = keysDown();
			if(keys & KEY_START) {
				main_scr = !main_scr;
				if (main_scr) lcdMainOnBottom();
				else lcdMainOnTop();
			}
		}
	}

	return 0;
}
