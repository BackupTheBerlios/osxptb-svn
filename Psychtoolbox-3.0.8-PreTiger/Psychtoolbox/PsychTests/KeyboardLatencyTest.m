function KeyboardLatencyTest(triggerlevel, modality, submode)
% KeyboardLatencyTest([triggerlevel=0.01][,modality=0][,submode])
%
% Uses sound capture with high timing precision via
% PsychPortAudio() for measuring keyboard and mouse latency.
%
% Whenever the script tells you, hit a key on the keyboard - or a mouse
% button - Loud enough so the noise of hitting the button or key can be
% recorded by the attached microphone. This noise will be timestamped by
% the code as the "true" key press or mouse press time. Timestamps acquired
% by standard KbCheck or GetMouse query are compared against that reference
% and the difference is computed as device latency.
% 
% Sound is captured from the default recording device, waiting
% until the amplitude exceeds some 'triggerlevel'.
%
% The 'modality' flag chooses between keyboard (==0 - the default), and
% mouse (==1). A setting of 2 queries the keyboard with a (theoretically
% more accurate) method that is only supported on OS/X.
%
% A 'modality' of 3 will test the new driver for the USTCRTBOX reaction
% time button box, if such a box is attached. A setting 4 will also test
% that box, but without opening a connection to it, ie., it is assumed that
% the box is already open from a previous call of this function with
% modality setting '3'. This allows to repeat the test many times without
% recalibrating the box. The optional 'submode' flag selects different ways
% of testing the box: A setting of zero will perform a 'ClockRatio'
% calibration to provide exact live timestamps and to test drift
% correction. A setting of 1 will skip this, so live timestamps will
% exhibit clock-drift and only the post-hoc timestamps will be somewhat
% exact. A setting of 2 will skip collection of post-hoc timestamps.
%
% A 'modality' of 5 will exercise the RB-x30 response pads from Cedrus.
%
% Obviously this method of measuring carries quite a bit of uncertainty
% in exact timing, but with a high quality microphone, proper tuning and
% good sound hardware, it shouldn't be off too much. At least you get a
% rough feeling for the lags inherent to keyboards and mice.
%

% History:
% 08/10/2008 Written (MK)
% 02/15/2009 Updated for Cedrus and RTBox (MK).

tdelay = [];
global tdelay2;
global tSecs;
global toffset;

if nargin < 1 || isempty(triggerlevel)
    triggerlevel = 0.01;
    fprintf('No "triggerlevel" argument in range 0.0 to 1.0 provided: Will use default of 0.01 ...\n\n');
end

if nargin < 2 || isempty(modality)
    modality = 0;
end

if nargin < 3
    submode = 0;
end

if modality == 3
    PsychRTBox('Open');
    if submode == 0
        PsychRTBox('SyncClocks');
        PsychRTBox('ClockRatio', [], 30);
    end
end

if modality == 4
    PsychRTBox('Start');
end

if modality == 5
    cedrusport = FindSerialPort('usbserial', 1);

    % Open box, at high baud-rate (aka lowBaudrate == 0), perform calibration /
    % clock sync (doCalibrate == 1):
    hcedrus=CedrusResponseBox('Open', cedrusport, 0, 1);

    bi = CedrusResponseBox('GetDeviceInfo', hcedrus);
    disp(bi);

    fprintf('Clearing all queues...');
    CedrusResponseBox('ClearQueues', hcedrus);
    fprintf('... done.\n');
end

fprintf('Auditory keyboard / mouse latency test:\n');
fprintf('After you see the instruction "Hit me baby one more time!", hit ');
if modality == 1
    fprintf('a mouse button\n');
else
    if modality == 0
        fprintf('a keyboard button\n');
    else
        fprintf('the keyboard space bar\n');
    end
end

fprintf('hard enough so the microphone can pick up the noise.\n');
fprintf('This measurement will be repeated 10 times and obvious wrong\n');
fprintf('measurements discarded. At the end the mean input device latency\n');
fprintf('and standard deviation will be printed.\n\n');
fprintf('Caution: Only works well with high-quality sound cards and proper\n');
fprintf('adjustment of the "triggerlevel" parameter in a silent room.\n');
fprintf('E.g. should work pretty ok on OS/X and Linux, but will require a\n');
fprintf('ASIO capable sound card and driver on Windows.\n');
fprintf('These numbers are only rough estimates, more meant to illustrate\n');
fprintf('input latencies than to provide hard dependable measurements!!!\n\n');
fprintf('Press a key to continue...\n');
KbStrokeWait;

% Perform basic initialization of the sound driver, initialize for
% low-latency, high timing precision mode:
InitializePsychSound(1);

% Open the default audio device [], with mode 2 (== Only audio capture),
% and a required latencyclass of two 2 == low-latency mode, as well as
% a frequency of 44100 Hz and 2 sound channels for stereo capture. We also
% set the required latency to a pretty high 20 msecs. Why? Because we don't
% actually need low-latency here, we only need low-latency mode of
% operation so we get maximum timing precision -- Therefore we request
% low-latency mode, but loosen our requirement to 20 msecs.
%
% This returns a handle to the audio device:
freq = 44100;
pahandle = PsychPortAudio('Open', [], 2, 2, freq, 2, [], 0.02);

fprintf('\nPress a key to start the measurement...\n');
KbStrokeWait;
clc;

% Do ten trials:
for trial = 1:10
    % Preallocate an internal audio recording buffer with a capacity of 30 seconds:
    PsychPortAudio('GetAudioData', pahandle, 30);

    % Start audio capture immediately and wait for the capture to start.
    % We set the number of 'repetitions' to zero, i.e. record until recording
    % is manually stopped.
    PsychPortAudio('Start', pahandle, 0, 0, 1);

    % Tell user to shout:
    fprintf('Hit me baby one more time! ');
    
    switch (modality)
        case 0
            % Wait for all keys to be released:
            KbReleaseWait;

            % Wait for keypress in a tight loop:
            while ~KbCheck; end;
            tKeypress = GetSecs;
        case 1
            [x y b] = GetMouse;
            while any(b)
                [x y b] = GetMouse;
            end;

            % Wait for mousebutton press in a tight loop:
            while ~any(b)
                [x y b] = GetMouse;
            end;
            tKeypress = GetSecs;
        case 2
            tKeypress = KbTriggerWait(KbName('space'));
        case {3, 4}
            % Test RTbox:
            
            % Clear all buffers:
            PsychRTBox('Clear');
            
            fprintf('From now on... ');
            tKeypress = [];
            
            % Wait for some event on box, return its 'GetSecs' time:
            while isempty(tKeypress)
                [tKeypress, evid, tBox] = PsychRTBox('GetSecs');
            end
            
            tKeypress = tKeypress(1);
            tBox = tBox(1);
            
            % Store raw box timestamp as well:
            tdelay2(end+1, 1) = tBox; %#ok<AGROW>

        case 5
            % Test Cedrus response box:
            CedrusResponseBox('FlushEvents', hcedrus);

            fprintf('From now on... ');
            evt = [];

            % Wait for some event on box, return its 'GetSecs' time:
            while isempty(evt) || evt.port~=0 || evt.action~=1 || evt.button~=2
                evt = CedrusResponseBox('GetButtons', hcedrus);
            end
            disp(evt)
            tKeypress = evt.ptbtime;
            
            while ~isempty(evt)
                evt = CedrusResponseBox('GetButtons', hcedrus);
            end
            
        otherwise
            error('Unknown "modality" specified.');
    end
    
    % Wait in a polling loop until some sound event of sufficient loudness
    % is captured:
    level = 0;    
    offset = 0;
    
    while level < triggerlevel
        % Fetch current audiodata:
        [audiodata offset overflow tCaptureStart]= PsychPortAudio('GetAudioData', pahandle);
        
        % Compute maximum signal amplitude in this chunk of data:
        if ~isempty(audiodata)
            level = max(abs(audiodata(1,:)));
        else
            level = 0;
        end
        
        % Below trigger-threshold?
        if level < triggerlevel
            % Wait for five milliseconds before next scan:
            WaitSecs(0.005);
        end
    end

    % Ok, last fetched chunk was above threshold!
    % Find exact location of first above threshold sample.
    idx = min(find(abs(audiodata(1,:)) >= triggerlevel)); %#ok<MXFND>
        
    % Compute absolute event time:
    tOnset = tCaptureStart + ((offset + idx - 1) / freq);
    
    % Stop sound capture:
    PsychPortAudio('Stop', pahandle);
    
    % Fetch and discard all remaining audio data from the buffer - Needs to be empty
    % before next trial:
    PsychPortAudio('GetAudioData', pahandle);
    
    if offset == 0
        fprintf('--> Keypress registered in 1st audiobuffer ');
    end
    
    % Print RT:
    dt = (tKeypress - tOnset)*1000;
    fprintf('---> Input delay time is %f milliseconds.\n', dt);
        
    % Valid measurement? Must be between 0 and 100 msecs to be considered:
    if (dt > -100) & (dt < 100) %#ok<AND2>
        tdelay = [tdelay dt]; %#ok<AGROW>
    end
    
    if modality == 3 | modality == 4 %#ok<OR2>
        % Store raw box timestamp as well:
        tdelay2(end, 2) = tOnset; %#ok<AGROW>
    end
    
    % Next trial after 2 seconds:
    WaitSecs(2);
end

% Close the audio device:
PsychPortAudio('Close', pahandle);

% Done.
fprintf('\nTest finished. Average delay across valid trials: %f msecs (stddev = %f msecs).\n\n', mean(tdelay), std(tdelay));
if ~isempty(tdelay2) && submode ~= 2
    % Recompute RTBox timestamps via post-hoc remapping:
    [tSecs, sd] = PsychRTBox('BoxsecsToGetsecs', [], tdelay2(:, 1));
    fprintf('Error margin on fit for box->host mapping is %f msecs.\n', sd.norm * 1000);

    % Recompute offset based on remapped timestamps:
    toffset = (tSecs - tdelay2(:, 2)) * 1000;
    
    fprintf('\n\n\n');
    for i=1:length(toffset)
        fprintf('Remapped RTBox delay for trial %i == %f milliseconds.         [delta = %f msecs]\n', i, toffset(i), sd.delta(i)*1000);
    end
    
    toffset = toffset((toffset > -100) & (toffset < 100));
    fprintf('\nTest finished. RTBox 2nd Average delay across valid trials: %f msecs (stddev = %f msecs, range = %f msecs).\n\n', mean(toffset), std(toffset), range(toffset));
end

if modality == 5
    CedrusResponseBox('Close', hcedrus);
end

return;
