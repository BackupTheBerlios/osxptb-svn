function VideoCaptureLatencyTest(texfetch, fullscreen)
% VideoCaptureLatencyTest
%
% This routine tests the latency of Videocapture for
% a given Camera -> Computer -> PTB -> gfx-card -> display combo.
%
% Working principle and usage:
%
% 1. Point camera to monitor so that cameras field of view captures monitor
% display area.
%
% 2. Calibration: First a black screen is shown to the cam and captured to
% find the average intensity of an image of a black display.
% Then (over ten trials), the screen turns white and the script measures
% the time delay between onset of white screen and arrival of a captured
% image with at least 25% more intensity than the 'black'-image -- our
% white image. This procedure is repeated 10 times and latencies averaged.
%
% -> Rough estimate of delay from scene change to arrival of frame.
% -> You have to add the display onset delay if captured image should be
% shown to subject for video feedback loops.
%
% Parameters:
%
% texfetch == 0 Measure only capture latency. 1 == Measure texture fetch
% latency as well. 2 == Measure drawing and onset latency as well.
%
% History:
% 2/9/06 mk Written.

% Running OpenGL-PTB? This is required.
AssertOpenGL;

% Find stimulus display:
screen=max(Screen('Screens'));

if nargin < 1
    texfetch=0;
end;

texfetch

if nargin < 2
   fullscreen=1;
end;

fullscreen

%try
    % Open display with default settings:
    if fullscreen<1
	    win=Screen('OpenWindow', screen, 0, [0 0 800 600]);
    else
       win=Screen('OpenWindow', screen, 0);
    end;
    
    [w h]=Screen('WindowSize', win);
    
    % Setup font and textsize: 24 is also a good size for Linux.
    Screen('TextSize', win, 24);
    Screen('TextStyle', win, 1);
    
    % Show initial blank screen:
    Screen('Flip',win);
    
    % Open default video capture device:
    grabber = Screen('OpenVideoCapture', win, 0, [0 0 640 480], 1);
    
    % Start video capture: We request at least a 100 Hz capture rate and lowlatency (=1) mode:
    fps=Screen('StartVideoCapture', grabber, 100, 1);
    fps
    
    oldpts = 0;
    count = 0;
    t=GetSecs;
    while (GetSecs - t) < 600 
        if KbCheck
            break;
        end;
        
        [tex pts nrdropped intensity]=Screen('GetCapturedImage', win, grabber, 0);
        % fprintf('tex = %i  pts = %f\n', tex, pts);
        if (tex>0)
            % Print instructions:
            Screen('DrawText', win, 'Point camera to center of Display - Then press any key', 10, h-50);
            % Print pts:
            Screen('DrawText', win, ['Capture timestamp (s): ' num2str(pts)], 0, 0, 255);
            if count>0
                % Compute delta:
                delta = (pts - oldpts) * 1000;
                oldpts = pts;
                Screen('DrawText', win, ['Delta since last frame (ms): ' num2str(delta)], 0, 24, 255);
            end;
            
            % Compute and print intensity:
            Screen('DrawText', win, ['Mean intensity: ' num2str(intensity)], 0, 48, 255);
           
            % Print count of dropped frames since last fetch:
            Screen('DrawText', win, ['Dropped frames: ' num2str(nrdropped)], 0, 72, 255);

            % New texture from framegrabber.
            Screen('DrawTexture', win, tex);
            Screen('Flip', win, 0, 0, 2);
            Screen('Close', tex);
            tex=0;
        end;        
        count = count + 1;
    end;
    telapsed = GetSecs - t
    
    % Ok, preview finished. Cam should now point to the screen and
    % we can start the latency measurement procedure:
    ntrials = 10;
    tavgdelay = 0;
    threshold = 0;
    
    for i=1:ntrials
        % Make screen black:
        Screen('FillRect', win, 0);
        Screen('Flip', win);
        
        for j=1:50
           Screen('GetCapturedImage', win, grabber, 2);
        end;
       
        % Capture a black frame:
        tex=0;
        while (tex==0)
            [tex pts nrdropped intensity]=Screen('GetCapturedImage', win, grabber, 0);
        end;

        if (tex>0) Screen('Close', tex); end;
    
        if threshold==0
          blackintensity = intensity;
          threshold = blackintensity * 1.1;
        end;
     
        % Eat up all enqueued images, if any.
        tex=1;
        while (tex>0)
            [tex newpts]=Screen('GetCapturedImage', win, grabber, 0);
            if (tex>0)
                Screen('Close', tex);
                pts = newpts;
            end;
        end;

        % Make display white:
        Screen('FillRect', win, 255);
        % Show it and take onset timestamp:
        tonset = Screen('Flip', win);
        
        % Now we loop and capture until intensity exceeds threshold:
        tex=0;
        intensity=0;
        lagframes=0;
        ptsblack = pts;
        
        while (tex>=0 & intensity < threshold)
            if texfetch>0
                waitmode=1;
            else
                waitmode=2;
            end;
            
            [tex pts nrdropped intensity]=Screen('GetCapturedImage', win, grabber, waitmode);
            
            % Captured! Take timestamp:
            tdelay=(GetSecs - tonset) * 1000;
        
            if tex>0
               lagframes=lagframes+1;
               if texfetch>1 & intensity>=threshold
                  Screen('DrawTexture',win,tex,[],[],[],0);
                  tdelay = (Screen('Flip',win) - tonset) * 1000;
               end;
               Screen('Close', tex);
               tex=0;
            end;
        end;
                
        tdelay
        lagframes
        ptslag = (pts - ptsblack) * 1000
        
        tavgdelay=tavgdelay + tdelay;
      
        % Next trial...
    end;
        
    % Done. Stop and shutdown capture loop:
    Screen('StopVideoCapture', grabber);
    Screen('CloseVideoCapture', grabber);
    Screen('CloseAll');

    tavgdelay = tavgdelay / ntrials;
    tavgdelay

    return;
    
    %catch
   %Screen('CloseAll');
   %rethrow(lasterror);
%end;
