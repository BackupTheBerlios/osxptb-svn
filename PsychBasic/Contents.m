% Psychtoolbox:PsychBasic.%% help Psychtoolbox % For an overview, triple-click me & hit enter.% help PsychDemos   % For demos, triple-click me & hit enter.%%   ButtonAvai          - Is there a mouse-button message in the event queue?%   Bytes               - How much memory is free? (MEX)%   CharAvail           - Is a keypress available for GetChar? (Uses EventAvail.mex)%   Debugger            - Enter low-level debugger. (MEX)%   DoNothing           - Does nothing. Used to time Matlab's overhead. (MEX)%   EventAvail          - Check for events: mouse, keyboard, etc. (MEX)%   FlushEvents         - Flush any unprocessed events. (MEX)%   FrameRate           - Quick accurate old measurement of frame rate, in Hz.%   GetChar             - Wait for keyboard character and return it (with time & modifiers).%   GetClicks           - Wait for mouse click(s); get location and number. (MEX)%   GetMouse            - Get mouse position. (MEX)%   GetSecs             - Time since startup (20 us precision, or better). (MEX)%   GetSecsTick         - Duration of one tick of the GetSecs clock.%   GetTicks            - Number of 60.15 Hz ticks since startup. (MEX)%   HideCursor          - Hide cursor. Doesn't always work, alas. (MEX)%   KbCheck             - Get instantaneous keyboard state. (MEX, fast)%   KbName              - Convert keycode to key name.%   KbWait              - Wait for key press and return its time. (MEX, fast)%   LoadClut            - Loads the CLUT, supports all DAC sizes and pixelSizes.%   MaxPriority         - The maximum priority compatible with a list of functions. %   PatchTrap           - Disable Mac OS routines. Dangerous! (MEX)%   PrepareScreen       - Called by Screen when first window is opened on a screen.%   Priority            - Disable interrupts. Dangerous! (MEX)%   PsychSerial         - OS9, Win: Use Mac serial port. (MEX)%   SERIAL              - Win: Send and receive through serial ports. %                         Standard Matlab function. Requires Java, so it's %                         not available if you run Matlab with the%                         -NOJVM switch. In Win we use the -NOJVM switch %                         to fix the problem with GetChar.%   COMM                - OSX: Send and receive through serial ports.%                         web http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=4952&objectType=file -browser ;%   PsychtoolboxDate    - Current version date, e.g. '1 August 1998'%   PsychtoolboxVersion - Current version number, e.g. 2.32%   RestoreScreen       - Called by Screen when last window is closed (among all screens) or Screen.mex is flushed.%   Rush                - Execute code quickly, minimizing interrupts. (MEX)%   Screen              - Fifty display functions. ** Type "screen" for a list. ** (MEX)%   ScreenSaver         - Control screen savers, eg AfterDark, Sleeper. (MEX)%   SetMouse            - Set mouse position. (MEX)%   ShowCursor          - Show the cursor, and set cursor type. (MEX)%   Showtime            - Create and show QuickTime movies. (MEX)%   Snd                 - Play sounds. (MEX)%   WaitSecs            - Wait specified time. (MEX)%   WaitTicks           - Wait specified number of 60.15 Hz ticks.% Copyright (c) 1997-2005 by David Brainard & Denis Pelli