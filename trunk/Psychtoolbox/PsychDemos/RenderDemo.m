% RenderDemo%% Illustrates calibration interface for simple task of% producing a uniform color patch of desired CIE xyY% coordinates.%% The calculation is done with respect to the current% calibration for screen whichScreen.  We provide a default% with the toolbox, but it won't match your monitor.%% If the RGB values contain 0 or 255, the coordinates% requested may have been out of gamut.%% A 64 by 64 image is left in the clipboard as a PICT% and may be pasted into Photoshop, Word, etc.% 4/26/97  dhb  Wrote it.% 7/25/97  dhb  Better initialization.% 3/12/98  dgp  Use Ask.% 3/14/02  dhb  Update for OpenWindow.% 4/03/02  awi  Merged in Windows changes.  On Windows we do not copy the result to the clipboard. % 4/13/02  awi	Changed "SetColorSpace" to new name "SetSensorColorSpace".%				Changed "LinearToSettings" to new name "SensorToSettings".% 12/21/02 dhb  Remove reliance on now obsolete OpenWindow/CloseWindow.% 11/16/06 dhb  Start getting this to work with PTB-3.% 11/22/06 dhb  Fixed except that Ask() needs to be fixed.% Clear out workspaceclear% Load calibration filecal = LoadCalFile('PTB3TestCal');load T_xyz1931T_xyz1931 = 683*T_xyz1931;cal = SetSensorColorSpace(cal,T_xyz1931,S_xyz1931);cal = SetGammaMethod(cal,0);% Get xyY, render, and report.xyY = input('Enter xyY (as a row vector): ')';XYZ = xyYToXYZ(xyY);RGB = SensorToSettings(cal, XYZ);fprintf('Computed RGB: [%g %g %g]\n', RGB(1), RGB(2), RGB(3));% Show the imagetry     % Screen is able to do a lot of configuration and performance checks on	% open, and will print out a fair amount of detailed information when	% it does.  These commands supress that checking behavior and just let    % the demo go straight into action.  See ScreenTest for an example of    % how to do detailed checking.	oldVisualDebugLevel = Screen('Preference', 'VisualDebugLevel', 3);    oldSupressAllWarnings = Screen('Preference', 'SuppressAllWarnings', 1);    theTable = linspace(0,1,256)'*ones(1,3);        whichScreen = max(Screen('Screens'));    [window, rect] = Screen('OpenWindow', whichScreen, 255);    Screen('LoadNormalizedGammaTable',window, theTable);    Screen('FillRect', window, 1, CenterRect([0 0 64 64],rect));    Screen('Flip', window);    theTable(2,:) = RGB';    Screen('LoadNormalizedGammaTable', window, theTable);        Ask(window,'Here''s the color.  Click to proceed', 0,  255);    Screen('Close', window);    Screen('Preference', 'VisualDebugLevel', oldVisualDebugLevel);    Screen('Preference', 'SuppressAllWarnings', oldSupressAllWarnings);catch        Screen('CloseAll');    Screen('Preference', 'VisualDebugLevel', oldVisualDebugLevel);    Screen('Preference', 'SuppressAllWarnings', oldSupressAllWarnings);    psychrethrow(psychlasterror);end