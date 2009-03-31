% Clear
clear all;

% Define screen
whichScreen=max(Screen('Screens'));

% Find the color values which correspond to white and black.  Though on OS
% X we currently only support true color and thus, for scalar color
% arguments,
% black is always 0 and white 255, this rule is not true on other platforms will
% not remain true on OS X after we add other color depth modes.  
white=WhiteIndex(whichScreen);
black=BlackIndex(whichScreen);
gray=GrayIndex(whichScreen);

% Open a double buffered fullscreen window
% does not like opening it 24 bit deep, so stick with 32 bits,
% though we don't want alpha!!
[window,screenRect] = Screen('OpenWindow',whichScreen,0,[],32,2);

% THE FOLLOWING STEP IS IMPORTANT.
% make sure the graphics card LUT is set to a linear ramp
% (else the encoded data will not be recognised by Bits++).
% There is a bug with the underlying OpenGL function, hence the scaling 0 to 255/256.  
% This demo will not work using a default gamma table in the graphics card,
% or even if you set the gamma to 1.0, due to this bug.
% This is NOT a bug with Psychtoolbox!
Screen('LoadNormalizedGammaTable',window,linspace(0,(255/256),256)'*ones(1,3));

% find out how big the window is
[screenWidth, screenHeight]=Screen('WindowSize', window);

% draw a gray background on front and back buffers
Screen('FillRect',window, gray);
Screen('Flip', window);
Screen('FillRect',window, gray);

% =================================================================
% CODE NEEDED HERE !
% "linear_lut" should be replaced here with one giving the inverse
% characteristic of the monitor.
% =================================================================
%   restore the Bits++ LUT to a linear ramp
linear_lut =  repmat(round(linspace(0, 2^16 -1, 256))', 1, 3);
BitsPlusSetClut(window,linear_lut);

% ramp over all possible values of the digital output
Mask=65535; %this controls which bits of the digital output we change
Command=0;

for output_value=0:1024
    Data=ones(1,248)*output_value;
    fprintf('%d\n',output_value);
    bitsEncodeDIO(Mask,Data,Command, window);
end

% reset the digital output data
Mask=0;
Data=zeros(1,248);
bitsEncodeDIO(Mask,Data,Command, window);

% if the system only has one screen, set the LUT in Bits++ to a linear ramp
% if the system has two or more screens, then blank the screen.
if (whichScreen == 0)
    % =================================================================
    % CODE NEEDED HERE !
    % "linear_lut" should be replaced here with one giving the inverse
    % characteristic of the monitor.
    % =================================================================    
    % restore the Bits++ LUT to a linear ramp
    linear_lut =  repmat(round(linspace(0, 2^16 -1, 256))', 1, 3);
    BitsPlusSetClut(window,linear_lut);
    
    % draw a gray background on front and back buffers to clear out any old
    % DIO packets
    Screen('FillRect',window, gray);
    Screen('Flip', window);
    Screen('FillRect',window, gray);
    Screen('Flip', window);

    % Close the window.
    Screen('CloseAll');    
else
    % Blank the screen
    BitsPlusSetClut(window,zeros(256,3));

    % draw a black background on front and back buffers to clear out any
    % old DIO packets
    Screen('FillRect',window, black);
    Screen('Flip', window);
    Screen('FillRect',window, black);
    Screen('Flip', window);

    Screen('CloseAll');
end