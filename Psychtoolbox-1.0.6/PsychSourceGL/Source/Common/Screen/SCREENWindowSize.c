/*
  SCREENWindowSize.c		
  
  AUTHORS:
  
		Allen.Ingling@nyu.edu		awi 
  
  PLATFORMS:
  
		Only OS X for now.    

  HISTORY:
  
		2/26/05  awi		Created.  Inspired by Frans Cornelissen's script "WindowSize".   
 
  
  TO DO:
  

*/


#include "Screen.h"



// If you change the useString then also change the corresponding synopsis string in ScreenSynopsis.c
static char useString[] = "[width, height]=Screen('WindowSize', windowPointerOrScreenNumber);";
//                                             1
static char synopsisString[] = 
	"Return the width and height of a window or screen.";
static char seeAlsoString[] = "Screen('Rect')";	

PsychError SCREENWindowSize(void)  
{
	
	PsychWindowRecordType *windowRecord;
	int screenNumber;
	PsychRectType rect;
	double	rectWidth, rectHeight;
    
	//all sub functions should have these two lines
	PsychPushHelp(useString, synopsisString,seeAlsoString);
	if(PsychIsGiveHelp()){PsychGiveHelp();return(PsychError_none);};
	
	//check for superfluous arguments
	PsychErrorExit(PsychCapNumInputArgs(1));		//The maximum number of inputs
	PsychErrorExit(PsychRequireNumInputArgs(1));	//Insist that the argument be present.   
	PsychErrorExit(PsychCapNumOutputArgs(2));		//The maximum number of outputs

	if(PsychIsScreenNumberArg(1)){
		PsychCopyInScreenNumberArg(1, TRUE, &screenNumber);
		PsychGetScreenRect(screenNumber, rect);
		rectWidth=PsychGetWidthFromRect(rect);
		rectHeight=PsychGetHeightFromRect(rect);
		PsychCopyOutDoubleArg(1, kPsychArgOptional, rectWidth);
		PsychCopyOutDoubleArg(2, kPsychArgOptional, rectHeight);
	}else if(PsychIsWindowIndexArg(1)){
		PsychAllocInWindowRecordArg(1, TRUE, &windowRecord);
		rectWidth=PsychGetWidthFromRect(windowRecord->rect);
		rectHeight=PsychGetHeightFromRect(windowRecord->rect);
		PsychCopyOutDoubleArg(1, kPsychArgOptional, rectWidth);
		PsychCopyOutDoubleArg(2, kPsychArgOptional, rectHeight);
	}else
		PsychErrorExitMsg(PsychError_user, "Argument was recognized as neither a window index nor a screen pointer");

	return(PsychError_none);
}

