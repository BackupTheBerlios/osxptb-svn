/*
  PsychToolbox2/Source/Common/PsychRegisterProject.cpp		
  
  PROJECTS: All.  
  
  AUTHORS:
  Allen.Ingling@nyu.edu		awi 
  
  PLATFORMS:	Mac OS 9
    

  HISTORY:
  8/23/02  awi		Created. 
 
  
*/


#include "Psych.h"


//file static variable definitions
static PsychFunctionPtr exitFunctionREGISTER = NULL;
static PsychFunctionPtr baseFunctionREGISTER = NULL;
static PsychFunctionTableEntry functionTableREGISTER[PSYCH_MAX_FUNCTIONS];
static char ModuleNameREGISTER[PSYCH_MAX_FUNCTION_NAME_LENGTH+1]; //+1 for term null
static char *currentFunctionNameREGISTER;
static int numFunctionsREGISTER=0;

//file static function declarations
static PsychError PsychRegisterModuleName(char *name);
static PsychError PsychRegisterBase(PsychFunctionPtr baseFunc);



/*
	This function is called by the project to register project functions.
	
	See the documentation in the example RegisterProject.c file.  
	
	It registers this elements of the project:
	
	-subfunctions
	-the project base function
	-the project name
	
	

*/

//for use by projects
PsychError PsychRegister(char *name,  PsychFunctionPtr func)
{
	int i;

	//check to see if name is null which means we register the module base function.  
	if(name==NULL){
		if(func==NULL)
			return(PsychError_internal);
		return(PsychRegisterBase(func));
	}
	
	//check to see if the function is null which means we register the project name.
	if(func==NULL)
		return(PsychRegisterModuleName(name)); 
	

	//check to see if we have space left in the registry
	if(numFunctionsREGISTER == PSYCH_MAX_FUNCTIONS)
		return(PsychError_registerLimit);
		
	//check to see if the name has already been registered
	for(i=0;i<PSYCH_MAX_FUNCTIONS;i++){
		if(strcmp(name, functionTableREGISTER[i].name)==0)
			return(PsychError_registered);
	}
	
	//register the function and enable the subfunction dispatcher
	functionTableREGISTER[numFunctionsREGISTER].function = func;
	if(strlen(name) > PSYCH_MAX_FUNCTION_NAME_LENGTH)
		return(PsychError_longString);
	strcpy(functionTableREGISTER[numFunctionsREGISTER].name, name);
	++numFunctionsREGISTER;
	PsychEnableSubfunctions();
	return(PsychError_none);
}


//for use by projects
PsychError PsychRegisterExit(PsychFunctionPtr exitFunc)
{
	if(exitFunctionREGISTER == NULL){
		exitFunctionREGISTER = exitFunc;
		return(PsychError_none);
	}else
		return(PsychError_registered);
}



/* If null is passed then we return the base function, otherwise 
	we return the named subfuction or NULL if we can't find it.
	
	Also we store a pointer to the current function name string or 
	set that pointer to NULL if we are returning the project base function. 
*/
PsychFunctionPtr PsychGetProjectFunction(char *command)
{
	int i; 

	//return the project base function
	if(command==NULL){
		currentFunctionNameREGISTER = NULL;
		return(baseFunctionREGISTER);
	}
	// See if help is being requested
	if (command[strlen(command)-1] == '?') {
		PsychSetGiveHelp();
		command[strlen(command)-1]=0;
	}else
		PsychClearGiveHelp();
	
	//lookup the function in the table
	for(i=0;i<numFunctionsREGISTER;i++){
		if(PsychMatch(functionTableREGISTER[i].name, command)){
			currentFunctionNameREGISTER = functionTableREGISTER[i].name;
			return(functionTableREGISTER[i].function);
		}
	}

	// Unknown command.
	return NULL;
}


//for use by projects
char *PsychGetFunctionName(void)
{	
	static char noFunction[] = ""; //the string used to name the current subfunction when 
								   //there is none:

	if(currentFunctionNameREGISTER == NULL)
		return(noFunction);
	else
		return(currentFunctionNameREGISTER);
}


//for use by projects
char *PsychGetModuleName(void)
{
	return(ModuleNameREGISTER);
}



PsychFunctionPtr PsychGetProjectExitFunction(void)
{
	return(exitFunctionREGISTER);
}


//file static function definitions


/* 
	Store away the project name when the project init registers it. 
	This function is not called directly by the project init, it is 
	called by PsychRegister if PsychRegister figures out that the 
	project init is registering the project name.
*/
static PsychError PsychRegisterModuleName(char *name)
{
	static boolean nameRegistered=FALSE; 
	
	if(nameRegistered)
		return(PsychError_registered);
	else{
		if(strlen(name) > PSYCH_MAX_FUNCTION_NAME_LENGTH)
			return(PsychError_longString);
		strcpy(ModuleNameREGISTER, name); 
		nameRegistered=TRUE;
	}
	return(PsychError_none);
}

/* 
	Store a pointer to the project base function in a static variable.
	This function is not called directly by the project init, it is 
	called by PsychRegister if PsychRegister figures out that the 
	project init is registering the project base function.
*/
 
static PsychError PsychRegisterBase(PsychFunctionPtr baseFunc)
{
	if(baseFunctionREGISTER != NULL)
		return(PsychError_registered);
	else
		baseFunctionREGISTER = baseFunc;
		
	return(PsychError_none);
}





 


