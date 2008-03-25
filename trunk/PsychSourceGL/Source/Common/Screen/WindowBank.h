/*
PsychToolbox2/Source/Common/WindowBank.h		

AUTHORS:

	Allen.Ingling@nyu.edu               awi
	mario.kleiner at tuebingen.mpg.de   mk

PLATFORMS: 

	All. Only the PsychTargetSpecificWindowRecordType struct
	is different for the different operating systems.

HISTORY:
	
	07/18/02  awi			Wrote it.
	04/22/05  mk            Added new flags to PsychWindowRecordType for stereo mode, skipped frames, IFI estimate and timestamping
							- These functions are mostly used by Screen('Flip') and Screen('DrawingFinished').
	07/22/05  mk            Removed constants for max number of windows. We resize dynamically now (see WindowBank.c)
	10/11/05  mk            Support for special Quicktime movie textures in .targetSpecific part of PsychWindowRecord added.
	12/27/05  mk            Added new targetSpecific - struct for the Win32 port of PTB.

DESCRIPTION:

	WindowBank contains functions for storing records of open  onscreen and offscreen windows.

	We don't use real window pointers when we return a window pointer to the scripting 
	environment.  Instead, we return an index which the PsychToolbox maps to a window
	pointer. Since the mapping is always from the index passed from the scripting environment,
	we can implement this with array lookup. 

	The window pointer or screen number is frequently passed as a single number, and by using
	our own indices we make things easier for ourselves when disambiguating the meaning of a 
	windowPointerOrScreenNumber value, because the value itself is a direct and unambiguouis 
	reference.  


TO DO: 

*/

//begin include once 
#ifndef PSYCH_IS_INCLUDED_WindowBank
#define PSYCH_IS_INCLUDED_WindowBank

/*
	includes
*/

#include "Screen.h"


//constants
#define PSYCH_MAX_SCREENS				10		//the total possible number of screens
#define PSYCH_LAST_SCREEN				9		//the highest possible screen index
#define PSYCH_FIRST_SCREEN				0		//the lowest possible screen index
#define PSYCH_ALLOC_SCREEN_RECORDS		        10		//length of static array allocated to hold screen pointers.
#define PSYCH_FIRST_WINDOW				10		//the lowest possible windox index
					

//constants
#define PSYCH_INVALID_WINDEX 				-1
#define PSYCH_INVALID_SCUMBER				-1

// Maximum number of different hook chains:
#define MAX_SCREEN_HOOKS 13

// Maximum number of slots in windowRecords fboTable:
#define MAX_FBOTABLE_SLOTS 2+3+3+2

// Type of hook function attached to a specific hook chain slot:
#define kPsychShaderFunc	0
#define kPsychCFunc			1
#define kPsychMFunc			2
#define kPsychBuiltinFunc	3

// Detected capabilities of the gfx-hardware, as interrogated by PsychDetectAndAssignGfxCapabilities()
// at onscreen window creation time and stored in windowRecord->gfxcaps as part of a bitfield:
#define kPsychGfxCapFBO			1			// Hw supports OpenGL FBOs as rendertargets.
#define kPsychGfxCapFPTex16		2			// Hw supports 16bpc float textures.
#define kPsychGfxCapFPTex32		4			// Hw supports 32bpc float textures.
#define kPsychGfxCapFPFBO16		8			// Hw supports 16bpc float FBOs.
#define kPsychGfxCapFPFBO32		16			// Hw supports 32bpc float FBOs.
#define kPsychGfxCapFPFilter16	32			// Hw supports bilinear filtering of 16bpc float textures.
#define kPsychGfxCapFPFilter32	64			// Hw supports bilinear filtering of 32bpc float textures.
#define kPsychGfxCapFPBlend16	128			// Hw supports alpha blending on 16 bpc float FBOs.
#define kPsychGfxCapFPBlend32	256			// Hw supports alpha blending on 32 bpc float FBOs.
#define kPsychGfxCapFP32Shading	512			// Hw supports IEEE 32 bit float precision throughout shaders.
#define kPsychGfxCapVCGood		1024		// Hw supports unclamped vertex colors of high (at least 16 bit effective) precision.

// Definition of flags for imagingMode of Image processing pipeline.
// These are used internally, but need to be exposed to Matlab as well.
#define kPsychNeedFastBackingStore 1		// Any FBO's needed at all?
#define kPsychNeedImageProcessing  2		// Any image processing needed at all?
#define kPsychNeedOutputConversion 4		// Output conversion blit needed?
#define kPsychNeedSeparateStreams  8		// Quad-buffered stereo needed?
#define kPsychNeedStereoMergeOp	   16		// Merging stereo -> single fb needed?
#define kPsychNeed32BPCFloat	   32		// float32 FBO's needed?
#define kPsychNeed16BPCFloat	   64		// float16 FBO's needed?
#define kPsychNeed16BPCFixed	   128		// fixed point 16 bpc FBO's needed?
#define kPsychNeedDualPass         256      // At least support for dual-pass processing needed?
#define kPsychNeedMultiPass        512      // Support for multi-pass processing needed?
#define kPsychNeedFastOffscreenWindows 1024 // Only support for fast FBO-backed Offscreen windows, everything else off.
#define kPsychHalfWidthWindow		   2048 // This flag is also used as 'specialflag' for onscreen windows. Ask for windows with half-width, e.g., for dualview stereo...
#define kPsychUse32BPCFloatAsap		   4096 // This flag asks to use 32 bpc float FBOs for all stages of the pipeline after the initial drawBufferFBO. The initial drawBufferFBO
											// should also be a 32 bpc float FBO if the hardware reliably supports framebuffer blending in 32bpc. Otherwise it should be a 16 bpc
											// float FBO to allow for hardware accelerated framebuffer blending.
#define kPsychUseTextureMatrixForRotation 1 // Setting for 'specialflags' field of windowRecords that describe textures. If set, drawtexture routine should implement
											// rotated drawing of textures via texture matrix, not via modelview matrix. To be set as flag in 'DrawTexture(s)'
#define kPsychDontDoRotation			  2	// Setting for 'specialflags' field of windowRecords that describe textures. If set, drawtexture routine should implement
											// rotated drawing of textures via shader, not via matrices, ie., just pass rotation angle to shader. To be set as flag in 'DrawTexture(s)'
#define kPsychHalfHeightWindow		   8192 // This flag is also used as 'specialflag' for onscreen windows. Ask for windows with half-height, e.g., for interleaved stereo...
#define kPsychNative10bpcFBActive	   1024 // Setting for 'specialflags' field of windowRecords: Means that this windowRecord is attached to a native 10bpc system framebuffer
											// and needs some special handling it init, shutdown and during operation.

// The following numbers are allocated to imagingMode flag above: A (S) means, shared with specialFlags:
// 1,2,4,8,16,32,64,128,256,512,1024,S-2048,4096,S-8192. --> Flags above 16384 and higher are available...

// The following numbers are allocated to specialFlags flag above: A (S) means, shared with imagingMode:
// 1,2,1024,S-2048,S-8192. --> Flags above 16384 and higher are available, as well as 4,8,16,32,64,128,256,512,4096

// Definition of a single hook function spec:
typedef struct PsychHookFunction*	PtrPsychHookFunction;
typedef struct PsychHookFunction {
	PtrPsychHookFunction	next;
	char*					idString;
	int						hookfunctype;
	char*					pString1;
	void*					cprocfunc;
	unsigned int			shaderid;
	unsigned int			luttexid1;
} PsychHookFunction;

// Definition of an OpenGL Framebuffer object (FBO) for internal use.
typedef struct PsychFBO {
	GLuint					fboid;		// Handle to FBO.
	GLuint					coltexid;	// Texture handle for color buffer texture (color attachment zero).
	GLuint					ztexid;		// Texture handle for z-Buffer texture, if any. Zero otherwise.
	GLuint					stexid;		// Texture handle for stencil-Buffer texture, if any. Zero otherwise.
	int						width;		// Width of FBO.
	int						height;		// Height of FBO.
} PsychFBO;

// Typedefs for WindowRecord in WindowBank.h

// This support structure for async flips is supported on all non-Windows platforms, aka all Unix platforms:
// It gets attached to the asyncFlipInfo* of a windowRecord whenever async flips are used.
typedef struct PsychFlipInfoStruct {
	unsigned char			asyncstate;			// Current execution state of flip.
	unsigned char			flipperState;
	// Parameters that specify the flip request: See prototype of PsychFlipWindowBuffers() for meaning of arguments:
	int						opmode;
	int						multiflip;
	int						vbl_synclevel;
	int						dont_clear;
	double					flipwhen;
	// Return arguments with results of flip: See prototype of PsychFlipWindowBuffers() for meaning of arguments:
	int						beamPosAtFlip;
	double					miss_estimate;
	double					time_at_flipend;
	double					time_at_onset;
	double					vbl_timestamp;

	// OS specific variables for thread handling and thread synchronization:
#if PSYCH_SYSTEM != PSYCH_WINDOWS
	// UNIX: POSIX threads for threading and mutex locking/sync:
	pthread_t				flipperThread;		// Thread handle for background flipping thread.
	pthread_mutex_t			performFlipLock;	// Primary lock.
	pthread_cond_t			flipperGoGoGo;		// Signalling condition variable to trigger execution of a flip request by the flipper thread.
#else
	// Windows: Not implemented. Just dummy variables to make compiler happy:
	void*					flipperThread;		// Thread handle for background flipping thread.
	unsigned int			performFlipLock;	// Primary lock.
	unsigned int			flipperGoGoGo;		// Signalling condition variable to trigger execution of a flip request by the flipper thread.
#endif
} PsychFlipInfoStruct;


#if PSYCH_SYSTEM == PSYCH_OSX
// Definition of OS-X core graphics and Core OpenGL handles:
typedef struct{
        CGLContextObj		contextObject;
        CGLPixelFormatObj	pixelFormatObject;
		CGLContextObj		glusercontextObject;    // OpenGL context for userspace rendering code, e.g., moglcore...
        CVOpenGLTextureRef  QuickTimeGLTexture;     // Used for textures returned by movie routines in PsychMovieSupport.c
        void*				deviceContext;          // Pointer to an AGLContext object, or a NULL-pointer.
		WindowRef			windowHandle;			// Handle for Carbon + AGL window when using windowed mode. (NULL in non-windowed mode).
} PsychTargetSpecificWindowRecordType;
#endif 

#if PSYCH_SYSTEM == PSYCH_WINDOWS
// Definition of Win32 Window handles, device handles and OpenGL contexts
typedef struct{
  HGLRC		              contextObject;      // OpenGL rendering context.
  HDC                     deviceContext;      // Device context of the window.
  HWND                    windowHandle;       // The window handle.
  PIXELFORMATDESCRIPTOR   pixelFormatObject;  // The context's pixel format object.
  HGLRC					  glusercontextObject;	   // OpenGL context for userspace rendering code, e.g., moglcore...
  CVOpenGLTextureRef      QuickTimeGLTexture; // Used for textures returned by movie routines in PsychMovieSupport.c
  // CVOpenGLTextureRef is not ready yet. Its typedefd to a void* to make the compiler happy.
} PsychTargetSpecificWindowRecordType;
#endif 

#if PSYCH_SYSTEM == PSYCH_LINUX
// Definition of Linux/X11 specific information:
typedef struct{
  GLXContext		contextObject;       // GLX OpenGL rendering context.
  int             	pixelFormatObject;   // Just here for compatibility. Its a dummy entry without meaning.
  Display*              deviceContext;       // Pointer to the X11 display connection.
  Window                windowHandle;        // Handle to the onscreen window.
  GLXContext		glusercontextObject; // OpenGL context for userspace rendering code, e.g., moglcore...
  CVOpenGLTextureRef QuickTimeGLTexture;     // Used for textures returned by movie routines in PsychMovieSupport.c
  // CVOpenGLTextureRef is not ready yet. Its typedefd to a void* to make the compiler happy.
} PsychTargetSpecificWindowRecordType;
#endif 

#define kPsychUnaffiliatedWindow	-1		// valid value for screenNumber field of a window record meaning that that pixel format
											// and alignment of the window are not set to match those of any display surface.

typedef struct _PsychWindowRecordType_ *PsychWindowRecordPntrType;												

//typedefs for the window bank.  We use the same structure for both windows and textures.   
typedef struct _PsychWindowRecordType_{

	//need to be divided up according to use for textures, windows, or both.
	PsychWindowType                         windowType;
	int					screenNumber;   // kPsychUnaffiliated is -1 and means the offscreen window is unaffiliated.
	PsychWindowIndexType                    windowIndex;
	void					*surface; 
	int					surfaceSizeBytes;	// Estimate of used system memory in bytes. Only used for accounting and debugging output.
	PsychRectType                           rect;
	boolean					isValid;		//between when we allocate the record and when we fill in values.
	int					depth;
	int					nrchannels;
	int					redSize;		
	int					greenSize;
	int					blueSize;
	int					alphaSize;
        int                                     multiSample;            // Number of samples to use for anti-aliasing of each drawn pixel:
                                                                        // 0=Standard GL, n>0 : Use Multisampling, try to get at least n samples/pixel.
	//used only when this structure holds a window
	Boolean					actualEnableBlending;
	GLenum					actualSourceAlphaBlendingFactor;
	GLenum					actualDestinationAlphaBlendingFactor;
	GLenum					nextSourceAlphaBlendingFactor;
	GLenum					nextDestinationAlphaBlendingFactor;
	
	
	//Used only when this structure holds a texture:    
	GLuint					*textureMemory;
	size_t					textureMemorySizeBytes;
	GLuint					textureNumber;
        int                                     textureOrientation;     // Orientation of texture data in internal storage. Defines texcoord assingment.  
        int					texturecache_slot;      // Reference of cache structure for this texture, if any...
        GLenum                                  texturetarget;          // Explicit target type of texture (GL_TEXTURE_2D, ...)
        // The following three are only used for injecting special textures into PTB, e.g., High Dynamic range textures in floating point format.
        // They default to zero, which means: Derive texture representation from depth.
        GLint                                   textureinternalformat;  // Explicit definition of glinternalformat for texture creation.
        GLenum                                  textureexternalformat;  // Explicit definitin of external format for texture creation.
        GLenum                                  textureexternaltype;    // Explicit definition of data type for texture creation.
		GLint				textureFilterShader;	// Optional GLSL program handle for a shader to apply during PsychBlitTextureToDisplay().
		GLint				textureLookupShader;	// Optional GLSL handle for nearest neighbour texture drawing shader.
		
	//line stipple attributes, for windows not textures.
	GLushort				stipplePattern;
	GLint					stippleFactor;
	boolean					stippleEnabled;
        
		unsigned int							gfxcaps;				// Bitfield of gfx-cards capabilities and limitations: See constants kPsychGfxCapXXXX above.
		unsigned int							specialflags;			// Container for all kind of special flags...
        int                                     stereomode;             // MK: Is this a stereo window? 0=non-stereo, >0 == specific type of stero.
        int                                     stereodrawbuffer;       // MK: Which drawbuffer is active in stereo? 0=left, 1=right, 2=none
		PsychWindowRecordPntrType				slaveWindow;			// MK: In stereomode 10 (dual-window stereo) Either NULL or windowrecord of right view window.
		PsychWindowRecordPntrType				parentWindow;			// MK: Ptr. to windowRecord of the parent window, or NULL if this window doesn't have a parent.
		int										targetFlipFieldType;	// MK: Usually == -1 (=Don't care). Can select that bufferswap should always happen in even frames (=0) or odd frames (=1). Useful for frame sequential stereo.
        bool                                    auxbuffer_dirty[2];     // MK: State of auxbuffers 0 and 1: Dirty or not? (For stereo algs.)
        int                                     nrIFISamples;           // MK: nrIFISamples and IFIRunningSum are used to calculate an
        double                                  IFIRunningSum;          // MK: accurate estimate of the real interframe interval (IFI) in Flip.
		double                                  time_at_last_vbl;       // MK: Timestamp (system-time) at last VBL detected by Flip.
        double                                  VideoRefreshInterval;   // MK: Estimated video refresh interval of display. Can be different to IFI.
		double									ifi_beamestimate;		// MK: Yet another video refresh estimate, based on beamposition method (or 0 if invalid).
        int                                     VBL_Endline;            // MK: Estimated scanline which marks end of VBL area.
        bool                                    PipelineFlushDone;      // MK: Will be set by SCREENDrawingFinished to signal pipeline flush.
        bool                                    backBufferBackupDone;   // MK: Will be set by SCREENDrawingFinished to signal backbuffer backup.
        int                                     nr_missed_deadlines;    // MK: Counter, incremented by Flip if it detects a missed/skipped frame.

	// Pointers to temporary arrays with gamma tables to upload to the gfx-card at next Screen('Flip'):
	// They default to NULL and get possibly set in Screen('LoadNormalizedGammaTable'):
	float* inRedTable;
	float* inGreenTable;
	float* inBlueTable;
	int    inTableSize;					// Number of slots in the LUT tables.
	int    loadGammaTableOnNextFlip;	// Type of upload operation: 0 = None, 1 = Load on next Flip via OS gamma table routines, then reset flag.
	
	// Settings for the image processing and hook callback pipeline: See PsychImagingPipelineSupport.hc for definition and implementation:
	double					colorRange;								// Maximum allowable color component value. See SCREENColorRange.c for explanation.
	GLuint					unclampedDrawShader;					// Handle of GLSL shader object for drawing of non-texture stims without vertex color clamping. Zero by default.
	GLuint					defaultDrawShader;						// Default GLSL shader object for drawing of non-texture stims. Zero by default.
	double					currentColor[4];						// Current unclamped but colorrange remapped RGBA drawcolor for whatever drawop, as spec'd by PsychSetGLColor().
	double					clearColor[4];							// Window clear color (as GL double vector) to use in PsychGLClear();
	int						imagingMode;							// Master mode switch for imaging and callback hook pipeline.
	PtrPsychHookFunction	HookChain[MAX_SCREEN_HOOKS];			// Array of pointers to the hook-chains for different hooks.
	Boolean					HookChainEnabled[MAX_SCREEN_HOOKS];		// Array of Booleans to en-/disable single chains temporarily.

	// Indices into our FBO table: The special value -1 means: Don't use.
	int						drawBufferFBO[2];						// Storage for drawing FBOs: These are the targets of all drawing operations before
																	// Screen('DrawingFinished') or Screen('Flip') is called. They are read-only wrt.
																	// to all following processing stages: 0=Left eye (or mono) channel, 1=Right eye channel.
	int						processedDrawBufferFBO[3];				// These contain the final output of all per-view channel postprocessing operations:
																	// 0=Left eye (or mono) channel, 1=Right eye channel, 2=Temporary bounce buffer for iterative
																	// multi-pass processing. These provide the input for the stereo merger in stereo modes that
																	// require merging of the two views, e.g., anaglyph stereo.
	int						preConversionFBO[3];					// preConversion FBO's: FBO zero/one are the targets for any stereo merge operations. FBO two is
																	// (optionally) a temporary bounce buffer for multipass post processing.
	int						finalizedFBO[2];						// This is the final framebuffer: Usually the system backbuffer, but could be something special.

	PsychFBO*				fboTable[MAX_FBOTABLE_SLOTS];			// This array contains pointers to the FBO structs which are referenced by the indices above.
	int						fboCount;								// This contains the number of FBO's in fboTable.
	
	// Cached handles for display lists -- used for recycling in compute intense drawing functions:
	GLuint					fillOvalDisplayList;
	GLuint					frameOvalDisplayList;

	// Pointer to double-array of auxiliary parameters for bound shaders - or NULL by default.
	double*					auxShaderParams;
	int						auxShaderParamsCount;
	
	//Used only when this structure holds a window:
	//platform specific stuff goes within the targetSpecific structure.  Defined in PsychVideoGlue and accessors are in PsychWindowGlue.c
	//Only use abstracted accessors on this structure, otherwise you will break platform portability.
	PsychTargetSpecificWindowRecordType	targetSpecific;  //defined within 
	
	PsychFlipInfoStruct*	flipInfo;								// This is either a NULL-Ptr, or it points to structure with all the info
																	// needed for implementing asynchronous flip operations. Its always NULL on
																	// MS-Windows, non-NULL on Linux/OSX as soon as async flips are used at least once.
																	// See SCREENFlip.c and flipping routines in PsychWindowSupport.c for more details...

	// Used only when this structure holds a window:
	// CAUTION FIXME TODO: Due to some pretty ugly circular include dependencies in the #include chain of
	// PTB, this field can not be used in files that #define PSYCH_DONT_INCLUDE_TEXTATTRIBUTES_IN_WINDOWRECORD,
	// e.g., PsychGraphicsHardwareHALSupport.c/h. Reason: The order of #include's in Screen.h prevents the
	// definition of this field of being available when PsychGraphicsHardwareHALSupport.h is included,
	// and we can't move that file down the include chain due to other nasty dependency issues!
	// So in such files, which need definition of PsychWindowRecordType, but are not related to
	// any text handling, we redef this to a void*. Important: This *must* be the last definition
	// of the struct PsychWindowRecordType, otherwise memory-alignment of the datastructure would
	// change in a corruptive way!!! So use the PSYCH_DONT_INCLUDE_TEXTATTRIBUTES_IN_WINDOWRECORD with
	// great caution! A proper fix would be to redesign the include dependency chain - either the whole
	// design, or at least the parts related to PsychTextAttributes, but that's unlikely to be a pain-free
	// procedure - it will cause severe breakage and the need for lot's of fixups and auditing, so defer
	// this to a later point in time :-(
	#ifndef PSYCH_DONT_INCLUDE_TEXTATTRIBUTES_IN_WINDOWRECORD
	PsychTextAttributes                     textAttributes;
	#else
	void*									textAttributes;
	#endif
} PsychWindowRecordType;


//various window and screen related
void			PsychFindScreenWindowFromScreenNumber(int screenNumber, PsychWindowRecordType **winRec);
PsychError 		InitWindowBank(void);
PsychError 		CloseWindowBank(void);
void 			PsychCreateWindowRecord(PsychWindowRecordType **winRec);
PsychError 		FreeWindowRecordFromIndex(PsychWindowIndexType windowIndex);
PsychError 		FreeWindowRecordFromPntr(PsychWindowRecordType *winRec);
int 			PsychCountOpenWindows(PsychWindowType winType);
boolean 		IsValidScreenNumber(PsychNumdexType numdex);
boolean			IsValidScreenNumberOrUnaffiliated(PsychNumdexType numdex);
boolean 		IsWindowIndex(PsychNumdexType numdex);
boolean			IsScreenNumberUnaffiliated(PsychNumdexType numdex);
PsychError 		FindWindowRecord(PsychWindowIndexType windowIndex, PsychWindowRecordType **windowRecord);
PsychError 		FindScreenRecord(int screenNumber, PsychScreenRecordType **screenRecord);
boolean 		PsychIsLastOnscreenWindow(PsychWindowRecordType *windowRecord);
void			PsychCreateVolatileWindowRecordPointerList(int *numWindows, PsychWindowRecordType ***pointerList);
void 			PsychDestroyVolatileWindowRecordPointerList(PsychWindowRecordType **pointerList);
void			PsychAssignParentWindow(PsychWindowRecordType *childWin, PsychWindowRecordType *parentWin);
PsychWindowRecordType* PsychGetParentWindow(PsychWindowRecordType *windowRecord);

//end include once
#endif
