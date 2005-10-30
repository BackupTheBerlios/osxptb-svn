function clutSize=ScreenClutSize(windowOrScreen)% clutSize=ScreenClutSize(windowOrScreen)% This is the number of entries in the hardware CLUT for a video card.% It depends solely on the pixelSize.% 	pixelSize  clutSize% 	        1    2% 	        2    4% 	        4   16% 	        8  256% 	       16   32% 	       32  256% % See also LoadClut, ScreenPixelSize, ScreenUsesHighGammaBits, ScreenDacBits.% 6/8/02 dgp Wrote it.pixelSize=Screen(windowOrScreen,'PixelSize');clutSizeList=[2 4 16 256 32 256];clutSize=clutSizeList(round(log(2*pixelSize)/log(2)));