function ProceduralGaborDemo(benchmark)
% ProceduralGaborDemo([benchmark=0])
%
% This demo demonstrates fast drawing of Gabor patches via use procedural
% texture mapping. It only works on hardware with support for the GLSL
% shading language, vertex- and fragment-shaders.
%
% Gabors are not encoded into a texture, but instead a little algorithm - a
% procedural texture shader - is executed on the graphics processor (GPU).
% This is very fast and efficient! All parameters of the gabor patch can be
% set individually.
%
% This demo is both, a speed benchmark, and a correctness test. If executed
% with the optional benchmark flag set to zero, it will execute a loop
% where it repeatedly draws a gabor patch both on the GPU (new style) and
% with Matlab code, then reads back and verifies the images, evaluating the
% maximum error between the old Matlab method and the new GPU method. The
% maximum error value and plotted error map are a means to assess if
% procedural shading works correctly on your setup and if the accuracy is
% sufficient for your purpose. In benchmark mode (flag set to 1), the gabor
% is drawn as fast as possible, testing the maximum rate at which your
% system can draw gabors.
%
% Typical results on a MacBookPro with Radeon X1600 under OS/X 10.4.11 are:
% Accuracy: Error wrt. Matlab reference code is 0.0005536900, i.e., about
% 1 part in 2000, equivalent to a perfect display on a gfx-system with 11 bit 
% DAC resolution. Note that errors scale with spatial frequency and
% absolute magnitude, so real-world errors are usually smaller for typical
% stimuli. This is just the error given the settings in this script.
% Typical speed is 2800 frames per second.
%
% Typical result on Intel Pentium IV, running on WindowsXP with a NVidia
% Geforce7800 and up to date drivers: Error is 0.0000146741 units, ie. one
% part in 68000, therefore perfect even on a display device with 15 bit
% DAC's. The framerate is about 2344 frames per second.
%
% If you want to draw many gabors, you wouldn't do it like in this script,
% but use the batch-drawing version of Screen('DrawTextures', ...) instead,
% as demonstrated, e.g., in DrawingSpeedTest.m
%

% History:
% 11/26/2007 Written (MK).

if nargin < 1
    benchmark = [];
end

if isempty(benchmark)
    benchmark = 0;
end

% Close previous figure plots:
close all;

% Make sure this is running on OpenGL Psychtoolbox:
AssertOpenGL;

% Initial stimulus params for the gabor patch:
res = 1*[323 323];
phase = 0;
sc = 50.0;
freq = .1;
tilt = 0;
contrast = 100.0;

% Disable synctests for this quick demo:
oldSyncLevel = Screen('Preference', 'SkipSyncTests', 2);

% Choose screen with maximum id - the secondary display:
screenid = max(Screen('Screens'));

% Setup imagingMode and window position/size depending on mode:
if ~benchmark
    rect = [0 0 res(1) res(2)];
    imagingMode = kPsychNeed32BPCFloat;
else
    rect = [];
    imagingMode = 0;
end

% Open a fullscreen onscreen window on that display, choose a background
% color of 128 = gray with 50% max intensity:
win = Screen('OpenWindow', screenid, 128, rect, [], [], [], [], imagingMode);

tw = res(1);
th = res(2);
x=tw/2;
y=th/2;

% Build a procedural gabor texture for a gabor with a support of tw x th
% pixels, and a RGB color offset of 0.5 -- a 50% gray.
gabortex = CreateProceduralGabor(win, tw, th, 0, [0.5 0.5 0.5 0.0]);

% Draw the gabor once, just to make sure the gfx-hardware is ready for the
% benchmark run below and doesn't do one time setup work inside the
% benchmark loop: See below for explanation of parameters...
Screen('DrawTexture', win, gabortex, [], [], 90+tilt, [], [], [], [], kPsychDontDoRotation, [phase+180, freq, sc, contrast]);

% Perform initial flip to gray background and sync us to the retrace:
vbl = Screen('Flip', win);
ts = vbl;
count = 0;
totmax = 0;

% Animation loop: Run for 10000 iterations:
while count < 10000
    count = count + 1;
    
    tilt = count/10;

    % In non-benchmark mode, we also compute a gabor patch in Matlab, as a
    % reference for the optimal outcome:
    if ~benchmark
        sf = freq;
        [gab_x gab_y] = meshgrid(0:(res(1)-1), 0:(res(2)-1));
        a=cosd(tilt)*sf*360;
        b=sind(tilt)*sf*360;
        multConst=1/(sqrt(2*pi)*sc);
        x_factor=-1*(gab_x-x).^2;
        y_factor=-1*(gab_y-y).^2;
        sinWave=sind(a*(gab_x - x) + b*(gab_y - y)+phase);
        varScale=2*sc^2;
        m=0.5 + contrast*(multConst*exp(x_factor/varScale+y_factor/varScale).*sinWave)';
        %imshow(m);
        %drawnow;
    end
    
    % Draw the Gabor patch: We simply draw the procedural texture as any other
    % texture via 'DrawTexture', but provide the parameters for the gabor as
    % optional 'auxParameters'.
    Screen('DrawTexture', win, gabortex, [], [], 90+tilt, [], [], [], [], kPsychDontDoRotation, [phase+180 freq sc contrast]);
    
    % Go as fast as you can without any sync to retrace and without
    % clearing the backbuffer -- we want to measure gabor drawing speed,
    % not how fast the display is going etc.
    Screen('Flip', win, 0, 2, 2);

    % In non-benchmark mode, we now readback the drawn gabor from the
    % framebuffer and then compare it against the Matlab reference:
    if ~benchmark
        % Read back, only the first color channel, but in floating point
        % precision:
        mgpu = Screen('GetImage', win, [], 'drawBuffer', 1, 1);

        %imshow(mgpu);
        %drawnow;
        % imagesc(mgpu);
        % colorbar;
        % drawnow;
        % maxval = max(max(mgpu))
        % minval = min(min(mgpu))

        % Compute per-pixel difference image of absolute differences:
        dimg = abs(mgpu - m);
        
        % Compute maximum difference value in 'totmax':
        maxdiff = max(max(dimg));
        totmax = max([maxdiff totmax]);

        % Show color-coded difference image:
        imagesc(dimg);
        colorbar;
        drawnow;
        
        % Abort requested? Test for keypress:
        if KbCheck
            break;
        end
    end
end

% A final synced flip, so we can be sure all drawing is finished when we
% reach this point:
tend = Screen('Flip', win);

% Done. Print some fps stats:
avgfps = count / (tend - ts);
fprintf('The average framerate was %f frames per second.\n', avgfps);

% Print error measure in non-benchmark mode:
if ~benchmark
    fprintf('The maximum difference between GPU and Matlab was %5.10f units.\n', totmax);
end

% Close window, release all ressources:
Screen('CloseAll');

% Restore old settings for sync-tests:
Screen('Preference', 'SkipSyncTests', oldSyncLevel);

% Done.
return;
