/*

  	PsychToolbox3/Source/Linux/Base/PsychTimeGlue.h

	AUTHORS:

  	mario.kleiner@tuebingen.mpg.de		mk

	PLATFORMS: Linux Only

 
  	PROJECTS:

  	HISTORY:

  	2/20/06	mk		Wrote it.  
	1/03/09	mk		Add generic Mutex locking support as service to ptb modules.
	
  	DESCRIPTION:

	TO DO:

*/

//begin include once 
#ifndef PSYCH_IS_INCLUDED_PsychTimeGlue
#define PSYCH_IS_INCLUDED_PsychTimeGlue

#include "Psych.h"

void PsychWaitUntilSeconds(double whenSecs);
void PsychWaitIntervalSeconds(double seconds);
void PsychYieldIntervalSeconds(double seconds);
double	PsychGetKernelTimebaseFrequencyHz(void);
void PsychGetPrecisionTimerTicks(psych_uint64 *ticks);
void PsychGetPrecisionTimerTicksPerSecond(double *frequency);
void PsychGetPrecisionTimerTicksMinimumDelta(psych_uint32 *delta);
void PsychGetPrecisionTimerSeconds(double *secs);
void PsychGetAdjustedPrecisionTimerSeconds(double *secs);
void PsychGetPrecisionTimerAdjustmentFactor(double *factor);
void PsychSetPrecisionTimerAdjustmentFactor(double *factor);
void PsychInitTimeGlue(void);
void PsychExitTimeGlue(void);
void PsychEstimateGetSecsValueAtTickCountZero(void);
double PsychGetEstimatedSecsValueAtTickCountZero(void);
int	PsychInitMutex(psych_mutex* mutex);
int	PsychDestroyMutex(psych_mutex* mutex);
int PsychLockMutex(psych_mutex* mutex);
int PsychUnlockMutex(psych_mutex* mutex);
int PsychCreateThread(psych_thread* threadhandle, void* threadparams, void *(*start_routine)(void *), void *arg);
int PsychDeleteThread(psych_thread* threadhandle);
int PsychAbortThread(psych_thread* threadhandle);
psych_thread PsychGetThreadId(void);
int PsychIsThreadEqual(psych_thread threadOne, psych_thread threadTwo);

//end include once
#endif
