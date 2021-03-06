/*
    SCREENDrawText.c	
  
    AUTHORS:
    
		Allen.Ingling@nyu.edu		awi 
  
    PLATFORMS:
		
		Only OS X for now.
    
    HISTORY:
	
		11/17/03	awi		Spun off from SCREENTestTexture which also used Quartz and Textures to draw text but did not match the 'DrawText' specifications.
		10/12/04	awi		In useString: changed "SCREEN" to "Screen", and moved commas to inside [].
		2/25/05		awi		Added call to PsychUpdateAlphaBlendingFactorLazily().  Drawing now obeys settings by Screen('BlendFunction').


 
    DESCRIPTION:
  
    REFERENCES:
	
		http://oss.sgi.com/projects/ogl-sample/registry/APPLE/client_storage.txt
		http://developer.apple.com/samplecode/Sample_Code/Graphics_3D/TextureRange.htm
	
  
    TO DO:
  
		- Set the alpha channel value in forground and background text correctly so that we only overwrite the portions of the target window where the text goes.
	
		- If we fail to set the font before calling this function we crash.  Fix that. 
	
		- Drawing White text works but othewise the colors don't seem to map onto the componenets correctlty.  Need to fix that.
	
		- By the way, there is something wrong with FillRect and the alpha channel does not clear the screen.
		
		- Accept 16-bit characters
	
		And remember:
	
		Destroy the shadow window after we are done with it. 
	
		Fix the color bug  See RBGA not in code below.  
	
*/


#include "Screen.h"

#define CHAR_TO_UNICODE_LENGTH_FACTOR		4			//Apple recommends 3 or 4 even though 2 makes more sense.
#define USE_ATSU_TEXT_RENDER				1

// If you change useString then also change the corresponding synopsis string in ScreenSynopsis.
static char useString[] = "[newX,newY]=Screen('DrawText', windowPtr, text [,x] [,y] [,color]);";
//                                                        1          2      3    4    5       
static char synopsisString[] = 
    "Draw text. \"text\" may include two-byte (16 bit) characters (e.g. Chinese). "
    "Default \"x\" \"y\" is current pen location. \"color\" is the CLUT index (scalar or [r "
    "g b] triplet) that you want to poke into each pixel; default produces black with "
    "the standard CLUT for this window's pixelSize. \"newX, newY\" return the final pen "
    "location.";
static char seeAlsoString[] = "";


//Specify arguments to glTexImage2D when creating a texture to be held in client RAM. The choices are dictated  by our use of Apple's 
//GL_UNPACK_CLIENT_STORAGE_APPLE constant, an argument to glPixelStorei() which specifies the packing format of pixel the data passed to 
//glTexImage2D().  
#define texImage_target				GL_TEXTURE_2D
#define texImage_level				0
#define	texImage_internalFormat		GL_RGBA
#define texImage_sourceFormat		GL_BGRA
#define texImage_sourceType			GL_UNSIGNED_INT_8_8_8_8_REV

//Specify arguments to CGBitmapContextCreate() when creating a CG context which matches the pixel packing of the texture stored in client memory.
//The choice of values is dictated by our use arguments to    
#define cg_RGBA_32_BitsPerPixel		32
#define cg_RGBA_32_BitsPerComponent	8
//#define cg_RGBA_32_AlphaOption		kCGImageAlphaPremultipliedLast
#define cg_RGBA_32_AlphaOption			kCGImageAlphaPremultipliedFirst

PsychError SCREENDrawText(void) 
{
    PsychWindowRecordType 	*winRec;
	double				invertedY;
    CGContextRef		cgContext;
    unsigned int		memoryTotalSizeBytes, memoryRowSizeBytes;
    UInt32				*textureMemory;
    GLuint				myTexture;
    CGColorSpaceRef		cgColorSpace;
	PsychRectType		windowRect;
	double				textureSizeX, textureSizeY;
	char				*textString;
	Boolean				doSetColor;
	PsychColorType			colorArg;
	CGImageAlphaInfo	quartzAlphaMode, correctQuartzAlphaMode, correctQuartzAlphaModeMaybe;
	CGRect				quartzRect;
	float				quartzBackground[4]= {0, 0, 0, 0,};	
	//for creating the layout object and setting the run attributes.  (we can get rid of these after we unify parts of DrawText and TextBounds).
	char					*textCString;
	int						stringLengthChars;
	Str255					textPString;
	int						uniCharBufferLengthElements, uniCharBufferLengthChars, uniCharBufferLengthBytes;
	UniChar					*textUniString;
	TextEncoding			textEncoding;
	OSStatus				callError;
	TextToUnicodeInfo		textToUnicodeInfo;
	ByteCount				uniCharStringLengthBytes;
	ATSUStyle				atsuStyle;
	ATSUTextLayout			textLayout;				//layout is a pointer to an opaque struct.
	
	//added for debugging:
	const GLubyte		*gluVersionString;
	const GLubyte		*glExtensionsString;
	GLboolean		rectangleExtensionFlag;
	
	
	//for layout attributes.  (not the same as run style attributes set by PsychSetATSUTStyleAttributes or line attributes which we do not set.) 	
	ATSUAttributeTag		saTags[] =  {kATSUCGContextTag };
	ByteCount				saSizes[] = {sizeof(CGContextRef)};
	ATSUAttributeValuePtr   saValue[] = {&cgContext};
    
    			
    //all subfunctions should have these two lines.  
    PsychPushHelp(useString, synopsisString, seeAlsoString);
    if(PsychIsGiveHelp()){PsychGiveHelp();return(PsychError_none);};
    

	
	
    //Get the window structure for the onscreen window.  It holds the onscreein GL context which we will need in the
    //final step when we copy the texture from system RAM onto the screen.
    PsychErrorExit(PsychCapNumInputArgs(5));   	
    PsychErrorExit(PsychRequireNumInputArgs(2)); 	
    PsychErrorExit(PsychCapNumOutputArgs(1));  
    PsychAllocInWindowRecordArg(1, TRUE, &winRec);
//    if(!PsychIsOnscreenWindow(winRec))
//        PsychErrorExitMsg(PsychError_user, "Onscreen window pointer required");
        
	//Get the dimensions of the target window
	PsychGetRectFromWindowRecord(windowRect, winRec);
	textureSizeX=PsychGetWidthFromRect(windowRect);
	textureSizeY=PsychGetHeightFromRect(windowRect);
	
	//Get the text string (it is required)
	PsychAllocInCharArg(2, kPsychArgRequired, &textString);
	
	//Get the X and Y positions.
	PsychCopyInDoubleArg(3, kPsychArgOptional, &(winRec->textAttributes.textPositionX));
	PsychCopyInDoubleArg(4, kPsychArgOptional, &(winRec->textAttributes.textPositionY));
	
	//Get the color
    //Get the new color record, coerce it to the correct mode, and store it.  
    doSetColor=PsychCopyInColorArg(5, kPsychArgOptional, &colorArg);
	if(doSetColor)
		PsychSetTextColorInWindowRecord(&colorArg,  winRec);
		
	//Allocate memory for the surface
    memoryRowSizeBytes=sizeof(UInt32) * textureSizeX;
    memoryTotalSizeBytes= memoryRowSizeBytes * textureSizeY;
    textureMemory=(UInt32 *)malloc(memoryTotalSizeBytes);
    if(!textureMemory)
            PsychErrorExitMsg(PsychError_internal, "Failed to allocate surface memory\n");
    

	//Create the Core Graphics bitmap graphics context.  We have to be careful to specify arguments which will allow us to store it as a texture in the following step. 
	//The choice of color space needs to be checked.  
	cgColorSpace=CGColorSpaceCreateDeviceRGB();
	//there is a bug here.  the format constant should be ARGB not RBGA to agree with the texture format.   
	cgContext= CGBitmapContextCreate(textureMemory, textureSizeX, textureSizeY, cg_RGBA_32_BitsPerComponent, memoryRowSizeBytes, cgColorSpace, cg_RGBA_32_AlphaOption);
	if(!cgContext){
		free((void *)textureMemory);
		PsychErrorExitMsg(PsychError_internal, "Failed to allocate CG Bimap Context\n");
	}
		
	//check that we are in the correct alpha mode (for the debugger... should change this to exit with error)
	correctQuartzAlphaMode= kCGImageAlphaPremultipliedLast;
	correctQuartzAlphaModeMaybe=kCGImageAlphaPremultipliedFirst;
	quartzAlphaMode=CGBitmapContextGetAlphaInfo(cgContext);

	//Set the alpha channel of the background to transparent so that we copy only the letters to the target surface.
	quartzRect.origin.x=(float)winRec->rect[kPsychLeft];
	quartzRect.origin.y=(float)winRec->rect[kPsychTop];
	quartzRect.size.width=(float)PsychGetWidthFromRect(winRec->rect);
	quartzRect.size.height=(float)PsychGetHeightFromRect(winRec->rect);
	CGContextSetFillColor(cgContext, quartzBackground);
	CGContextFillRect(cgContext, quartzRect);

	
		
//	#ifdef USE_ATSU_TEXT_RENDER
	/////////////common to TextBounds and DrawText:create the layout object////////////////// 
	//read in the string and get its length and convert it to a unicode string.
	PsychAllocInCharArg(2, kPsychArgRequired, &textCString);
	stringLengthChars=strlen(textCString);
	if(stringLengthChars > 255)
		PsychErrorExitMsg(PsychError_unimplemented, "Cut corners and TextBounds will not accept a string longer than 255 characters");
	CopyCStringToPascal(textCString, textPString);
	uniCharBufferLengthChars= stringLengthChars * CHAR_TO_UNICODE_LENGTH_FACTOR;
	uniCharBufferLengthElements= uniCharBufferLengthChars + 1;		
	uniCharBufferLengthBytes= sizeof(UniChar) * uniCharBufferLengthElements;
	textUniString=(UniChar*)malloc(uniCharBufferLengthBytes);
	//Using a TextEncoding type describe the encoding of the text to be converteed.  
	textEncoding=CreateTextEncoding(kTextEncodingMacRoman, kMacRomanDefaultVariant, kTextEncodingDefaultFormat);
	//Create a structure holding conversion information from the text encoding type we just created.
	callError=CreateTextToUnicodeInfoByEncoding(textEncoding,&textToUnicodeInfo);
	//Convert the text to a unicode string
	callError=ConvertFromPStringToUnicode(textToUnicodeInfo, textPString, (ByteCount)uniCharBufferLengthBytes,	&uniCharStringLengthBytes,	textUniString);
	//create the text layout object
	callError=ATSUCreateTextLayout(&textLayout);			
	//associate our unicode text string with the text layout object
	callError=ATSUSetTextPointerLocation(textLayout, textUniString, kATSUFromTextBeginning, kATSUToTextEnd, (UniCharCount)stringLengthChars);
	//create an ATSU style object and tie it to the layout object in a style run.
	callError=ATSUCreateStyle(&atsuStyle);
	callError=ATSUClearStyle(atsuStyle);
	PsychSetATSUStyleAttributesFromPsychWindowRecord(atsuStyle, winRec);
	callError=ATSUSetRunStyle(textLayout, atsuStyle, (UniCharArrayOffset)0, (UniCharCount)stringLengthChars);
	/////////////end common to TextBounds and DrawText//////////////////
	
	//associate the core graphics context with text layout object holding our unicode string.
	//callError=QDBeginCGContext (CGrafPtr inPort, &cgContext);
	callError=ATSUSetLayoutControls (textLayout, 1, saTags, saSizes, saValue);
	//CGContextRotateCTM (myCGContext, myAngle);
	invertedY=PsychGetHeightFromRect(winRec->rect) - winRec->textAttributes.textPositionY;
	ATSUDrawText(textLayout, kATSUFromTextBeginning, kATSUToTextEnd, Long2Fix((long)winRec->textAttributes.textPositionX), Long2Fix((long)invertedY)); 
	CGContextFlush(cgContext); 	//this might not be necessary but do it just in case.
	//we need to get the new text location and put it back into the window record's X and Y locations.
		
	//Old demo code which renders a string with using ATS instead of ATSUI.  

	/*
	#else   
		CGContextSelectFont(cgContext, "Helvetica", (float)24, kCGEncodingMacRoman);			//set the font and its size.
		CGContextSetTextDrawingMode(cgContext, kCGTextFill);									//set the pen to be a filled pen
		CGContextSetRGBStrokeColor(cgContext, (float)0.5, (float)0.5, (float)0.0, (float)1.0);	//set the stroke color and alpha
		CGContextSetRGBFillColor(cgContext, (float)0.5, (float)0.5, (float)0.0, (float)1.0);	//set the fill color and alpha
		stringLength=strlen(textString);
		CGContextShowTextAtPoint(cgContext, (float)(winRec->textAttributes.textPositionX), (float)(winRec->textAttributes.textPositionY), textString, stringLength);	//draw at specified location.
		CGContextFlush(cgContext); 	//this might not be necessary but do it just in case.
	#endif
	*/

    //Convert the CG graphics bitmap into a CG texture.  GL thinks we are loading the texture from memory we indicate to glTexImage2D, but really
    //we are just setting the texture to be that memory.
    PsychSetGLContext(winRec);

//	gluVersionString=gluGetString(GLU_VERSION);
//	glExtensionsString=glGetString(GL_EXTENSIONS);
	//printf("gluVersionString: %s\n",gluVersionString);
//	printf("glVersionExtensions: %s\n",glExtensionsString);
//	rectangleExtensionFlag=gluCheckExtension("GL_EXT_texture_rectangle", glExtensionsString);
//	if(rectangleExtensionFlag)
//		printf("found the GL_EXT_texture_rectangle extension\n");
//	else
//		printf("did not find the GL_EXT_texture_rectangle extension\n");

//	PsychUpdateAlphaBlendingFactorLazily(winRec);
    glEnable(GL_TEXTURE_RECTANGLE_EXT);
    glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
    glGenTextures(1, &myTexture);								//create an index "name" for our texture
    glBindTexture(GL_TEXTURE_RECTANGLE_EXT, myTexture);			//instantiate a texture of type associated with the index and set it to be the target for subsequent gl texture operators.
    glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, 1);			//tell gl how to unpack from our memory when creating a surface, namely don't really unpack it but use it for texture storage.
    glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_NEAREST);	//specify interpolation scaling rule for copying from texture.  
    glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_NEAREST);  //specify interpolation scaling rule from copying from texture.
    glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA,  textureSizeX, textureSizeY, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, textureMemory);
//  glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA,  textureSizeX, textureSizeY, 0, GL_RGBA, GL_UNSIGNED_INT_8_8_8_8_REV, textureMemory);
    
    //Copy the texture to the display.  What are the s and  t indices  of the first pixel of the texture ? 0 or 1 ?
    //set the GL context to be the onscreen window

	glBegin(GL_QUADS);
        glTexCoord2d(0.0, 0.0);							glVertex2d(0.0, 0.0);
        glTexCoord2d(textureSizeX, 0.0 );				glVertex2d(textureSizeX, 0.0);
        glTexCoord2d(textureSizeX, textureSizeY);		glVertex2d(textureSizeX, textureSizeY);
        glTexCoord2d(0.0, textureSizeY);				glVertex2d(0.0, textureSizeY);
    glEnd();
	

	
	
	
	


//  glFlush();	
    glDisable(GL_TEXTURE_RECTANGLE_EXT);
	
	//store the new X and Y positions

    //Close  up shop.  Unlike with normal textures is important to release the context before deallocating the memory which glTexImage2D() was given. 
    //First release the GL context, then the CG context, then free the memory.
    glDeleteTextures(1, &myTexture);	//Remove references from gl to the texture memory  & free gl's associated resources  
    CGContextRelease(cgContext);	//Remove references from Core Graphics to the texture memory & free Core Graphics' associated resources.
    free((void *)textureMemory);	//Free the memory
	//clean up for ATSU and unicode 
	free((void*)textUniString);
	callError=ATSUDisposeStyle(atsuStyle);

    return(PsychError_none);
}


	
	





