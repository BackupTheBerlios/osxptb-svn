function DescribeComputer
% DescribeComputer prints out several lines of text about the computing
% environment that your programs are running in. It is called by many of
% the programs in PsychTest to document the computing environment of the
% test. E.g. try running ScreenTest. Also see DescribeScreen and 
% DescribeScreenPrefs.
 
% 8/1/98  dgp Print PsychtoolboxDate.
% 4/12/99 dgp Suggest calling Screen('Preference','Backgrounding',0)
% 12/23/99 dgp Report whether screen saver is present.
% 12/23/99 dgp Report if VM is on.
% 1/24/00 dgp Updated for enhanced ScreenSaver.mex.
% 1/26/00 dgp Updated for Screen Preference Available.
% 1/29/00 dgp Suggest upgrading to Mac OS 8.6 or better, to get UpTime.
% 1/30/00 dgp Omit stuff that's no longer interesting: fpu,cache,pci.
% 2/6/00  dgp Updated to use new struct return arg from Screen Computer.
% 3/14/00 dgp Test for serial port arbitration.
% 6/17/00 dgp Test for mirroring.
% 8/22/00 dgp Distinguish good new from bad old version of Keyspan Digital Media Remote.
% 2/24/02 dgp Warn against PopChar Pro.
% 4/9/02  dgp Add explanation to VM warning.
% 4/13/02 dgp Added ~MAC2 conditional.
% 4/29/02 awi Replaced ~MAC2 with Win conditional, added detection and display of info.  
% 5/5/02  dgp Streamlined the OS9 report, commenting out the default case for QuickTime, 
%             screen save, UpTime, and serial-port arbitration.
% 6/2/02  dgp Extend initial line to be 74 characters wide, to match DescribeScreen.
% 6/23/02 dgp Remove initial '\n'.
% 12/20/04 awi  Added OS X section.
% 1/29/05 dgp  Cosmetic.
 
if IsWin
    cpuNumNames={'Single', 'Dual', 'Triple', 'Quad', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten', 'Eleven', 'Twelve' ...
            'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen' };
    comp=Screen('Computer');
    %****** VALKYRIE with Intel Pentium Pro|Pentium II, Windows 2000 Service Pack 1 ****    
    fprintf('****** %s running %s %s ******\n',comp.computerName,comp.OSName, comp.OSRevision);
    % Dual CPU with 255MB RAM, 61MB free and 76% load.
    fprintf('%s %s %s with %dMB RAM, %dMB free and %d%s load.\n', cpuNumNames{comp.CPUCount}, comp.CPUArchitecture,comp.CPULevel, ...
        round(Bytes('SystemRAM')/2^20), round(Bytes('SystemRAMFree')/2^20), round(Bytes('SystemRAMLoad')*100), '%'); 
    fprintf('DirectX %d.%d release %d.%d\n',comp.directxVersion.major, comp.directxVersion.minor, comp.directxVersion.release,...
        comp.directxVersion.build);
    % Psychtoolbox 2.45, 1 August 2001, Matlab 6.1.0.450 (R12.1)
    fprintf('Psychtoolbox %g, %s, Matlab %s\n',PsychtoolboxVersion,PsychtoolboxDate,version);
    return;
end
 
if IsOSX
% ************************ Denis Pelli on Weber ************************
% Single-CPU PowerBook G4 17" at 1.50 GHz
% Memory 1.00 GB at 166.40 MHz. 33 Mflop/s
% Mac OS 10.3.8, MATLAB 7.0.1.24704 (R14) Service Pack 1
% Psychtoolbox 1.0.5, ?? February 2005
    
    % get all the information
    c=Screen('Computer');
    thisMacTytpe=MacModelName;
    pyschtoolboxV=PsychtoolboxVersion;
    pyschtoolboxD=PsychtoolboxDate;
    matlabV=version;
    quicktimeV=AppleVersion('qtim');
    
    %line 1
    unpaddedLine=[c.processUserLongName ' on ' c.localHostName];
    padtoWidth=70;
    lineChars=length(unpaddedLine);
    halfStars=floor((padtoWidth-lineChars)/2) - 1;
    outputLines{1}= [repmat('*', 1, halfStars) ' ' unpaddedLine ' ' repmat('*', 1, halfStars)];
    %line 2
    numCPUsStrings={'Single-', 'Dual-', 'Triple-', 'Quad-', 'Five-' 'Six-' 'Seven-' 'Eight-'};
    numCPUsString=numCPUsStrings{c.hw.ncpu};
    roundedSpeed=NameFrequency(c.hw.cpufreq);
    outputLines{2}=[numCPUsString 'CPU ' MacModelName ' at ' roundedSpeed ];
    %line 3
    outputLines{3}=['Memory ' NameBytes(c.hw.physmem) ' at ' NameFrequency(c.hw.busfreq) sprintf(', %.0f Mflop/s',FlopPerSec/1e6)]; 
    %line 4
    outputLines{4}=[c.system ', MATLAB ' version ];
    %line 5
    outputLines{5}=['Psychtoolbox ' PsychtoolboxVersion ', '  PsychtoolboxDate];
    %line 6
%     outputLines{6}=['QuickTime ' AppleVersion('qtim') '\n'];
 
    for i=1:length(outputLines)
        fprintf('%s\n',outputLines{i});
    end
   
end %if IsOSX
 
if IsOS9
% *** Denis Pelli's Classic Mac OS Compatibility/1499 ********
% G4, 1500 MHz, memory at 166 MHz, 57 Mflop/s
% Mac OS 9.2.2, Matlab 5.2.1.1421
% Psychtoolbox 2.55, 12 March 2005
    comp=Screen('Computer');
    string=sprintf('*** %s''s %s',comp.owner,comp.model);
    if length(comp.vm)>0
        string=sprintf('%s, %s',string,comp.vm);
    end
    string=[string ' '];
    while length(string)<74
        string=[string '*'];
    end
    fprintf('%s\n',string);
 
    % G4, 1500 MHz, memory at 166 MHz, 57 Mflop/s
    fprintf('%s',comp.processor);
    if isfinite(comp.hz) & comp.hz>0
        % The processor and bus Hz information is only available (from Gestalt) on PCI Macs.
        fprintf(', %.0f MHz%s, memory at %.0f MHz',comp.hz/1e6,comp.emulating,comp.busHz/1e6);
    else
        fprintf('%s',comp.emulating);
    end
    fprintf(', %.0f Mflop/s\n',FlopPerSec/1e6);
 
    % Mac OS 9.2.2, Matlab 5.2.1.1421
    % Psychtoolbox 2.55, 12 March 2005
    fprintf('%s, MATLAB %s\n',comp.system,version);
    fprintf('Psychtoolbox %g, %s\n',PsychtoolboxVersion,PsychtoolboxDate);
 
    % QuickTime 4.1.2
    q=AppleVersion('qtim');
    if length(q)>0
    %   fprintf('QuickTime %s\n',AppleVersion('qtim'));
    else
        fprintf('No QuickTime.\n');
    end
 
    % FileSharing is on.
    %if FileShare>-3
    %    fprintf('FileSharing is on.\n');
    %end
 
    % WARNING: Virtual Memory (VM) is on. This makes it unsafe to raise priority to
    %          minimize interrupts. VM uses the hard disk to swap pages of memory. 
    %          Thus any memory access, eg using a Matlab array, may require a disk 
    %          access. Any attempt to access the disk at raised priority will hang 
    %          forever. For this reason, MaxPriority always returns zero when VM is 
    %          on, which is safe but sacrifices the interrupt-reducing benefit of 
    %          Rush. Please use the Memory control panel to turn off Virtual Memory. 
    %          And buy more memory. It's cheap. E.g.
    %          web http://dealram.com/ ;
    g=gestalt('vm  ');
    if length(g)==32 & any(g) % MaxPriority.m considers VM to be on only if bit 32 is set.
        global VMWarning
        if isempty(VMWarning)
            VMWarning=0;
        end
        VMWarning=VMWarning+1;
        fprintf('WARNING: Virtual Memory (VM) is on. This makes it unsafe to raise priority to\n');
        fprintf('         minimize interrupts. VM uses the hard disk to swap pages of memory. \n');
        fprintf('         Thus any memory access, eg using a Matlab array, may require a disk \n');
        fprintf('         access. Any attempt to access the disk at raised priority will hang \n');
        fprintf('         forever. For this reason, MaxPriority always returns zero when VM is \n');
        fprintf('         on, which is safe but sacrifices the interrupt-reducing benefit of \n');
        fprintf('         Rush. Please use the Memory control panel to turn off Virtual Memory. \n');
        fprintf('         Buy more memory. It''s cheap. E.g.\n');
        fprintf('         web http://dealram.com/ ;\n');
    end
 
    % WARNING: Please remove the Control Panel "PopChar Pro". 
    %          PopChar Pro can cause Matlab to fail. See PopCharTest.
    if IsPopCharProInstalled
        fprintf('WARNING: Please remove the Control Panel "PopChar Pro". \n');
        fprintf('         PopChar Pro can cause Matlab to fail. See PopCharTest.\n');
    end
 
    % Screen saver present, now disabled.
    ScreenSaver(1,1);
    [a,b]=ScreenSaver(0,0);
    if a|b
        fprintf('Screen saver present, now disabled.\n');
    else
    %   fprintf('No screen saver.\n');
    end
 
    % Using UpTime-based timing, which is very accurate and reliable.
    available=Screen('Preference','Available');
    if available.UpTime
    %   fprintf('Using UpTime-based timing, which is very accurate and reliable.\n');
    else
        fprintf('Using interrupt-based timing, because UpTime is not available.\n');
        fprintf('SUGGESTION: upgrading to Mac OS 8.6 or better will make your\n');
        fprintf('timing more accurate and immune from interrupts.\n');
    end
 
    % Has serial port arbitration.
    if strncmp(version,'5.2.1',5) % the old (pre 5.2.1) GESTALT terminates if selector is unknown
        b=gestalt('arb ');
        if length(b)==32 & b(32)
    %       fprintf('Has serial port arbitration.\n');
        else
    %        fprintf('No serial port arbitration.\n');
        end
    end
 
    % SUGGESTION: Disable Matlab's Backgrounding if you want maximum speed.
    % The easiest way is to call Screen('Preference','Backgrounding',0);
    if Screen('Preference','Backgrounding')
        fprintf('SUGGESTION: disable Matlab''s Backgrounding if you want maximum speed.\n');
        fprintf('The easiest way is to call Screen(''Preference'',''Backgrounding'',0);\n');
    end
 
    % WARNING! Your displays overlap ("mirroring" each other), making CopyBits very slow.
    if Screen('Preference','MirroringIsOn')
        fprintf('WARNING: Your displays overlap ("mirroring" each other). On some computers this makes CopyBits very slow.\n');
    end
 
    % Keyspan Digital Remote Media mapper daemon is running, slowing everything down by 30% or so.
    proc=Screen('preference','process','KEYj');
    if ~isempty(proc) & proc.size<1000000
        fprintf('The old Keyspan Digital Remote Media mapper daemon version 1.x is running,\n');
        fprintf(' slowing everything down by 30%% or so. Eliminate the slow down by upgrading\n');
        fprintf(' to version 2 beta or better:\n');
        fprintf(' web http://www.keyspan.com/products/usb/remote/downloads/ ;\n');
    end
    return
 
end %if IsOS9
 
function r=FlopPerSec
    % r=FlopPerSec
    % Measure flop/s for FFT2. The ops increase as n*n*log(n). We first do n=8.
    % If the machine is fast (i.e. not using SoftwareFPU) then we do n=256, a typical
    % image width.
    r=fps(8);
    if r>10000
        % use bigger matrix if machine is fast
        r=fps(256);
    end
return
 
function r=fps(n)
% r=fps(n)
f=0;
t=getsecs;fft2(1);  % load functions into memory
x=magic(n);
if exist('flops','builtin')
    f=flops;
end
for i=1 % precompile
%   Priority(7);
    t=getsecs;
    fft2(x);
    t=getsecs-t;
%   Priority(0);
end
if exist('flops','builtin')
    f=flops-f;
else
    fft2flops=[94 572 2712 12240 54752 244288 1085824 4799744 21081600 91997184]; % as reported by MATLAB 5.2.1
    f=fft2flops(round(log2(n)));
end
r=f/t;
return

