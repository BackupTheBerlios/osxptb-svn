/*
 *
 * moglcore.c -- MATLAB MEX file interface to OpenGL under OS X
 *
 * 08-May-2005 -- created (RFM)
 * 08-Dec-2005 -- reworked into direct interface to gl, glu, and glm functions (RFM)
 * 05-Mar-2006 -- reworked to make inclusion of glm optional (for Psychtoolbox) (MK)
 * 20-Mar-2006 -- Included support for GLEW lib for auto-detection of OpenGL extensions. (MK)
 *
 */

#include "mogltypes.h"

/* Build and include support for glm if BUILD_GLM is defined.
   Otherwise, only build OpenGL wrappers.
*/

#ifdef BUILD_GLM
extern int glm_map_count;
extern cmdhandler glm_map[];
#endif

extern int gl_manual_map_count, gl_auto_map_count;
extern cmdhandler gl_manual_map[], gl_auto_map[];

static int firsttime = 1;

// command string
#define CMDLEN 64
char cmd[CMDLEN];

// binary search routine
int binsearch(cmdhandler *map, int mapsize, char *str);

// error handler
void mogl_usageerr();

// MEX interface function
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    int i;
    GLenum err;
       
    // see whether there's a string command
    if( nrhs<1 || !mxIsChar(prhs[0]) )
        mogl_usageerr();
    
    // get string command
    mxGetString(prhs[0],cmd,CMDLEN);

	 // Special case. If we're called with the special command "PREINIT", then
	 // we return immediately. moglcore('PREINIT') is called by ptbmoglinit.m
	 // on M$-Windows in order to preload the moglcore Mex-file into Matlab while
	 // the current working directory is set to ..MOGL/core/ . This way, the dynamic
	 // linker can find our own local version of glut32.dll and link it against moglcore.
	 // Without this trick, we would need to install glut32.dll into the Windows system
    // folder which requires admin privileges and makes installation of Psychtoolbox
    // more complicated on M$-Windows...
	 if (strcmp(cmd, "PREINIT")==0) return;

    #ifdef BUILD_GLM
    // GLM module is included and supported in moglcore: This is necessary if
    // one wants to use MOGL independent from Psychtoolbox. GLM is only supported
    // on MacOS-X, not on Linux or Windows...
    
    // We execute glm-commands without performing GLEW first-time initialization,
    // because to execute glewinit() we need a valid OpenGL context. This context is
    // either created by Psychtoolbox or by glm. Therefore glm-commands must be able
    // to execute before glewinit() happened.
    
    // look for command in glm command map
    if( (i=binsearch(glm_map,glm_map_count,cmd))>=0 ) {
        glm_map[i].cmdfn(nlhs,plhs,nrhs-1,prhs+1);
        return;
    }

    #endif

    // Is this the first invocation of moglcore?
    if (firsttime) {
        // Yes. Initialize GLEW, the GL Extension Wrangler Library. This will
        // auto-detect and dynamically link/bind all core OpenGL functionality
        // as well as all possible OpenGL extensions on OS-X, Linux and Windows.
        err = glewInit();
        if (GLEW_OK != err) {
            // Failed! Something is seriously wrong - We have to abort :(
				printf("MOGL: Failed to initialize! Probably you called an OpenGL command *before* opening an onscreen window?!?\n");
            printf("GLEW reported the following error: %s\n", glewGetErrorString(err)); fflush(NULL);
            return;
        }
        // Success. Ready to go...
        printf("MOGL - OpenGL for Matlab initialized - MOGL is (c) 2006 Richard F. Murray, licensed to you under GPL.\n");
        fflush(NULL);
        firsttime = 0;
    }   

    // look for command in manual command map
    if( (i=binsearch(gl_manual_map,gl_manual_map_count,cmd))>=0 ) {
        gl_manual_map[i].cmdfn(nlhs,plhs,nrhs-1,prhs+1);
        return;
    }
    
    // look for command in auto command map
    if( (i=binsearch(gl_auto_map,gl_auto_map_count,cmd))>=0 ) {
        gl_auto_map[i].cmdfn(nlhs,plhs,nrhs-1,prhs+1);
        return;
    }
    
    // no match
    mogl_usageerr();
    
}

// do binary search in a command map for a command string
int binsearch(cmdhandler *map, int mapsize, char *str) {
    int m=0,n=mapsize-1,i,k,count=0;
    while( m<=n && count < 100) {
      count++;
        i=(int)((m+n)/2);
        k=strcmp(str,map[i].cmdstr);
        if( k==0 )
            return( i );
        else if( k<0 )
            n=i-1;
        else
            m=i+1;
    }
    return( -1 );
}

// error handler
void mogl_usageerr() {
    mexErrMsgTxt("invalid moglcore command");
}

// Error handler for unsupported core OpenGL functions or extensions.
// This handler gets called by the subroutines in gl_auto.c and gl_manual.c
// whenever a gl function is not bound == not supported by current OS/driver/gfx-hardware.
// As we use the GLEW library to dynamically detect and bind all OpenGL functions, we can
// easily check if a function is supported, e.g.,
// if (glCreateShader == NULL) mogl_glunsupported("glCreateShader");
//
void mogl_glunsupported(const char* fname)
{
    char errtxt[1000];
    sprintf(errtxt, "MOGL-Error: Your Matlab code tried to call the OpenGL function %s(), which is not supported\n"
                    "MOGL-Error: by your combination of graphics hardware + graphics device driver.\n"
                    "MOGL-Error: You'll have to download+install the latest gfx-drivers for your gfx-hardware\n"
                    "MOGL-Error: or upgrade your gfx-hardware with more recent one to use this function. Aborted.\n\n", fname);

    // Exit to Matlab prompt with error message:
    mexErrMsgTxt(errtxt);
}

