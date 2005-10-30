function CRSMeasureSyncTime(prompt)% CRSMeasureSyncTime([prompt])%% prompt == 0 -- no user prompt.% prompt == 1 -- wait for user (default).%% Issue VRD command to set meter measured proper% integration time for use with a monitor.%% 03/07/03 jb	Added GetClicks for CRSColorTest sequencing.% 03/08/03 dhb	GetClicks should come before command write, not after.  Fixed.%          dhb  Extend error checking.%          dhb  Control whether or not there is a user prompt.global crsColorInfo% Set default value for prompt.if (nargin < 1 | isempty(prompt))	prompt = 1;end% Command to device is 'VRD'cmd = '                                ';cmd(1:3) = 'VRD';cmd(4) = char(10);% Wait for userif (prompt)	fprintf('Attach the CRS color meter to the desired screen. Click mouse to continue.\n');	GetClicks;end% Write command and get responsePSYCHSERIAL('Write',crsColorInfo,cmd);response = PSYCHSERIAL('ReadRaw',crsColorInfo,32);rawResponse = PSYCHSERIAL('ReadRaw',crsColorInfo,32);if strncmp(rawResponse,'ER',2)	fprintf('Response to VRD command was: %s\n',response);	error('Error during CRSColorSyncTime');elseif strncmp(rawResponse,'OK',2)	fprintf('CRSColorZeroCal: success!\n');else	fprintf('Response to VRD command was: %s\n',response);	error('Error during CRSColoSyncTime');end