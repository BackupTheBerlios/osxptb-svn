function makeitviaFunky(what)

dos('copy T:\projects\OpenGLPsychtoolbox\trunk\PsychSourceGL\Source\Common\Base\PsychScriptingGlue.cc T:\projects\OpenGLPsychtoolbox\trunk\PsychSourceGL\Source\Common\Base\PsychScriptingGlue.c');

if nargin < 1
   what = 0;
end

if what == 0
   % Default: Build Screen.dll
   mex -v -outdir T:\projects\OpenGLPsychtoolbox\trunk\PsychSourceGL\Projects\Windows\build\ -output Screen -DPTBMODULE_Screen -DPTBVIDEOCAPTURE_QT -IC:\Programme\QuickTimeSDK\CIncludes -IC:\Programme\MicrosoftVisualStudio\VC98\Include -ICommon\Base -ICommon\Screen -IWindows\Base -IWindows\Screen Windows\Screen\*.c Windows\Base\*.c Common\Base\*.c Common\Screen\*.c kernel32.lib user32.lib gdi32.lib advapi32.lib glu32.lib opengl32.lib qtmlClient.lib ddraw.lib winmm.lib  
   dos('copy T:\projects\OpenGLPsychtoolbox\trunk\PsychSourceGL\Projects\Windows\build\Screen.dll T:\projects\OpenGLPsychtoolbox\trunk\Psychtoolbox\PsychBasic\MatlabWindowsFilesR11\');
end

if what == 1
   % Build WaitSecs.dll
   mex -v -outdir T:\projects\OpenGLPsychtoolbox\trunk\PsychSourceGL\Projects\Windows\build\ -output WaitSecs -DPTBMODULE_WaitSecs -IC:\Programme\MicrosoftVisualStudio\VC98\Include -ICommon\Base -ICommon\WaitSecs -IWindows\Base Windows\Base\*.c Common\Base\*.c Common\WaitSecs\*.c kernel32.lib user32.lib winmm.lib
   dos('copy T:\projects\OpenGLPsychtoolbox\trunk\PsychSourceGL\Projects\Windows\build\WaitSecs.dll T:\projects\OpenGLPsychtoolbox\trunk\Psychtoolbox\PsychBasic\MatlabWindowsFilesR11\');
end

if what == 2
   % Build PsychPortAudio.dll
   mex -v -outdir T:\projects\OpenGLPsychtoolbox\trunk\PsychSourceGL\Projects\Windows\build\ -output PsychPortAudio -DPTBMODULE_PsychPortAudio -IC:\Programme\MicrosoftVisualStudio\VC98\Include -ICommon\Base -ICommon\PsychPortAudio -IWindows\Base Windows\Base\*.c Common\Base\*.c Common\PsychPortAudio\*.c kernel32.lib user32.lib winmm.lib portaudio_x86.lib
   dos('copy T:\projects\OpenGLPsychtoolbox\trunk\PsychSourceGL\Projects\Windows\build\PsychPortAudio.dll T:\projects\OpenGLPsychtoolbox\trunk\Psychtoolbox\PsychBasic\MatlabWindowsFilesR11\');
end

if what == 3
   % Build GetSecs.dll
   mex -v -outdir T:\projects\OpenGLPsychtoolbox\trunk\PsychSourceGL\Projects\Windows\build\ -output GetSecs -DPTBMODULE_GetSecs -IC:\Programme\MicrosoftVisualStudio\VC98\Include -ICommon\Base -ICommon\GetSecs -IWindows\Base Windows\Base\*.c Common\Base\*.c Common\GetSecs\*.c kernel32.lib user32.lib winmm.lib
   dos('copy T:\projects\OpenGLPsychtoolbox\trunk\PsychSourceGL\Projects\Windows\build\GetSecs.dll T:\projects\OpenGLPsychtoolbox\trunk\Psychtoolbox\PsychBasic\MatlabWindowsFilesR11\');
end

if what == 4
   % Build IOPort.dll
   mex -v -outdir T:\projects\OpenGLPsychtoolbox\trunk\PsychSourceGL\Projects\Windows\build\ -output IOPort -DPTBMODULE_IOPort -IC:\Programme\MicrosoftVisualStudio\VC98\Include -ICommon\Base -ICommon\IOPort -IWindows\Base -IWindows\IOPort Windows\Base\*.c Common\Base\*.c Common\IOPort\*.c Windows\IOPort\*.c kernel32.lib user32.lib winmm.lib
   dos('copy T:\projects\OpenGLPsychtoolbox\trunk\PsychSourceGL\Projects\Windows\build\IOPort.dll T:\projects\OpenGLPsychtoolbox\trunk\Psychtoolbox\PsychBasic\MatlabWindowsFilesR11\');
end

delete('T:\projects\OpenGLPsychtoolbox\trunk\PsychSourceGL\Source\Common\Base\PsychScriptingGlue.c');
return;
