function PrepareScreen(screenNumber,screenInfo)% PrepareScreen, if present, is called by Screen 'OpenWindow' when the first% window is opened on a particular screen. PrepareScreen.m is intended to be% the single file that configures each screen (i.e. the graphics driver)% to attain standard driver-independent performance. PrepareScreen doesn't % change the pixelSize or resolution.% % Win: at present PrepareScreen does nothing; it's ok to call it.% % If you want to work with a screen before opening a window, you should% explicitly call PrepareScreen. It's harmless to call it more than once.% For each screen, it sets an "open" flag the first time you call it and% returns immediately if that screen is already open. You may call% PrepareScreen freely. If in doubt, call it.% % You can force PrepareScreen to run again in earnest, redoing all the% work, by first calling RestoreScreen, which clears the "open" flag. See% also RestoreScreen.% % Our intention is that this be the ONLY file that distinguishes specific% graphic drivers. We hope that you will never have to, as that would make% your programs much less portable. We have identified a number of% operational parameters that vary among drivers and that need to be taken% into account when loading the CLUT. Most users won't need to know these% parameters, but if you do, please use them instead of making your code% refer to any drivers by name.% % The main task of PrepareScreen is to set the following Screen Preference% values:%   BlankingDuration% 	DipPriorityAfterSetClut% 	MaximumSetClutPriority% 	MinimumSetClutPriority% 	MinimumEntriesForSetClutToWaitForBlanking% 	UseHighGammaBits% 	DacBits% 	SetClutDuplicates8Bits% 	AskSetClutDriverToWaitForBlanking% 	SetClutCallsWaitBlanking% It also sets:% 	screenGlobal(s).fixATIRadeon7000% % The values are succintly reported by DescribeScreenPrefs. It only % reports unusual non-standard values, omitting the standard ones.% % These parameters are important, but their best settings are hard to% figure out. You can't just ask the driver. Most of them are best% determined by running ScreenTest and looking over the report. If% necessary, we then add driver-specific conditionals here in% PrepareScreen to set up the parameters to achieve standard% machine-independent operation.% % WAIT FOR BLANKING: We set Screen parameters so that SetClut will wait% for blanking. There are many avenues to achieving that behavior; the% last resort is to ask it to wait for the blanking interrupt. See% ClutTimeTest, LoadClut, and Screen 'SetClut' and 'WaitBlanking'.% % MORE-THAN-8-BIT DACS: Some graphics cards have more-than-8-bit DACs. It% used to be tricky to load the CLUT and control all the bits, but we've% done all the work for you. You can just call LoadClut. We set various% Screen parameters appropriately for each of your graphics cards. See% LoadClut. The first call to LoadClut will be slow, as it prepares all % the tables. Subsequent calls should take only slightly longer than a % call to Screen 'SetClut'.% % UseHighGammaBits: There are only two possibilities, so we try both and% choose the one that minimizes error. This should automatically cope with% all new drivers.% 4/21/02 dgp Wrote it.% 6/20/02 dgp Rewrote it, incorporating the contents of ScreenUsesHighGammaBits and ScreenDacBits.% 6/21/02 dgp The ATI Radeon 7000 does NOT use the high gamma bits (i'm sure), despite being "Generation 2" (not sure).% 6/24/02 dgp Correct the polarity of the test for ScreenUsesHighGammaBits. Mistake noted by dhb.% 6/25/02 dgp Set screenGlobal().fixATIRadeon7000% 6/27/02 dgp Fix bug reported by thomasjerde@hotmail.com. We must cope with case in which GetClut is not available.% 6/29/02 dgp Use new version of Screen VideoCard. Incorporate all code from driver-specific subroutines.% 7/23/02 dgp Turn on SetClutDuplicates8Bits always.% 7/30/02 dgp Removed driver version 1.0b25 from isATIRadeon10Gen1 because Tony Jack <ajack@npg.wustl.edu> reported that%             his Radeon 7200 pci with that version fails to support 10-bit gamma.% 7/30/02 dgp Added '.Display_RADEON' to the list of drivers needing priority dipping, based on report from Tony Jack.% 7/31/02 dgp Use fixATIRadeon7000 only for the ATI Radeon 7000; it doesn't help the 7200 or 8500.% 8/7/02  dgp Add fix for ATI Radeon 7200 suggested by David Brainard and confirmed by David Jones.% 8/9/02  dgp Rename "fixATIRadeonGamma" to fixATIRadeon7000, which more accurately reflects its current usage.% 8/10/02 dgp Do runtime test of SetClut timing to set BlankingDuration.% 8/11/02 dgp Remove fix for ATI Radeon 7200 because i think the problem is gone now that we've zeroed BlankingDuration.% 8/11/02 dgp Do runtime test of LoadClutError to set SetClutDuplicates8Bits.% 8/18/02 dgp When runningOnClassic, set AskSetClutDriverToWaitForBlanking=0 and SetClutCallsWaitBlanking=1.% 8/24/02 dgp Based on test results from David Jones, now set BlankingDuration to 0.0003 for all cards.% 9/5/02  dgp Fixed bug. The test for SetClutDuplicates8Bits was getting the wrong answer when pixelSize>8 and dacSize>8 %             because I wasn't reloading the (stale) color table. % 11/5/02 dhb, ly  Set parameter 'BlankingDuration' to 3 ms for ATI Radeon generation 1 and 2 cards.  This%             fixes a spurious extra blanking interrupt problem that we encounterd with these cards.  This%             fix suggested by Denis Pelli.% 11/12/02    Turn off fixATIRadeon7000 since we'll soon be able to flash the 7000 ROM.% 12/16/02 dgp Set MaximumSetClutPriority=1 for the NVIDIA GeForce4MX driver.% 12/16/02 dgp ATI Radeon 9000 works fine with no special settings, so leave it that way.if ~IsOS9	returnendglobal screenGlobalif nargin==0	for s=Screen('Screens')		PrepareScreen(s);	end	returnendif isempty(screenGlobal)	% guarantee that if screenGlobal is not empty, then it will have fields "open" and "fixATIRadeon7000".	n=length(Screen('Screens'));	screenGlobal(n).open=[];	screenGlobal(n).fixATIRadeon7000=[];endscreenNumber=Screen(screenNumber,'WindowScreenNumber');if screenGlobal(screenNumber+1).open	% Skip all the work; it's already done.	returnendscreenGlobal(screenNumber+1).res=Screen(screenNumber,'Resolution');card=Screen(screenNumber,'VideoCard');% Identify cardName. Please also update similar table in DescribeScreen.isRadiusThunder10 = streq(card.driverName,'.Display_Marin') & streq(card.cardName,'RDUS,Marin');isATIRadeonOEM = streq(card.cardName,'ATY,Rage6p') | streq(card.cardName,'ATY,Rage6ag');isATIRadeon7200 = streq(card.cardName,'ATY,RADEONr') | streq(card.cardName,'ATY,RADEONp');isATIRadeon7500 = streq(card.cardName,'ATY,BlueStone_A') | streq(card.cardName,'ATY,BlueStone_B') ...| streq(card.cardName,'ATY,Crown_A') | streq(card.cardName,'ATY,Crown_B');isATIRadeon7000 = streq(card.cardName,'ATY,RV100ad_A') | streq(card.cardName,'ATY,RV100ad_B');isATIRadeon8500 = streq(card.cardName,'ATY,R200i_A') | streq(card.cardName,'ATY,R200i_B');isATIRadeon10Gen1 = (isATIRadeonOEM | isATIRadeon7200) & IsInOrder('1.0f49',card.driverVersion);isATIRadeon10Gen2 = isATIRadeon7000 | isATIRadeon7500 | isATIRadeon8500;isATIRadeon9000 = streq(card.cardName,'ATY,Pheonix_A') | streq(card.cardName,'ATY,Pheonix_B');% Identify driverNameisATIRadeon=streq(card.driverName,'.Display_DualHead');% Identify driverVersion% isOS921 = streq(card.driverVersion,'1.0b25') | streq(card.driverVersion,'1.0f49');% isSeptUpdate = streq(card.driverVersion,'1.0f52');% isJanUpdate = streq(card.driverVersion,'1.0f57');% isOS922 = streq(card.driverVersion,'1.0f58');% isATIRadeon10Gen1 = (isATIRadeonOEM & (isOS921 | isOS922)) | ((isATIRadeonOEM | isATIRadeon7200) & (isSeptUpdate | isJanUpdate));% As of 7/24/02 the fixATIRadeon7000 flag is used (i.e. affects what's % loaded into the CLUT) solely in LoadClut.m and ClutTest.m.% Its value is reported by DescribeScreenPrefs.% As of 7/27/02, ATI is considering the possibility of issuing a ROM upgrade for % the Radeon 7000 to fix this bug, and others.screenGlobal(screenNumber+1).fixATIRadeon7000=0;%screenGlobal(screenNumber+1).fixATIRadeon7000=isATIRadeon7000;% Try to get driver to wait for blanking: cscSetClutBehavior.oldWarning=warning;warning off;Screen(screenNumber,'Preference','AskSetClutDriverToWaitForBlanking',1);warning(oldWarning);% classic% Testing of SetClut for synch to blanking has been consistently indicating failure,% as of 8/18/02, so it seems best to set things up to work, by using the interrupt% instead of SetClut to synch. Tests to date indicate that the interrupt is not coupled% to blanking, but at least it has the right frequency.comp=Screen('Computer');if isfield(comp,'comp.runningOnClassic')	% supported by Screen.mex in release 2.53	classic=comp.runningOnClassic;else	if strncmp(version,'5.2.1',5)		% supported by Matlab 5.21. Earlier versions of Matlab Gestalt produce a fatal error if the selector is unknown.		b=gestalt('bbox');		if length(b)==32			classic=b(32);		else			classic=0;		end	else		s1='WARNING: You''re not running the latest Matlab, which is version 5.2.1. ';		s2='Thus we can''t use Gestalt to determine whether we''re running Mac OS X Classic. ';		s3='The graphics drivers under Classic require different settings. ';		s4='Please upgrade Matlab to 5.2.1 or upgrade the Psychtoolbox to 2.53, when it''s released. ';		s1=WrapString([s1 s2 s3 s4]);		fprintf('%s\n',s1);	endendif classic	warning off;	Screen(screenNumber,'Preference','AskSetClutDriverToWaitForBlanking',0);	warning(oldWarning);	Screen(screenNumber,'Preference','SetClutCallsWaitBlanking',1);end% MinimumEntriesForSetClutToWaitForBlanking% We probably should set this to 256 for MacPicasso, but we need a ScreenTest % to get the card or driver name.Screen(screenNumber,'Preference','MinimumEntriesForSetClutToWaitForBlanking',1);% BlankingDuration% The BlankingDuration parameter was introduced years ago to prevent% multiple counting of the same blanking. Raynald Comtois% <raco@burrhus.harvard.edu> suggested the idea to me in 1992. If one is% using interrupts, excess counting can arise through faulty hardware that% generates multiple interrupts. If one is using SetClut to wait for% blanking, the driver may allow many quick calls during a single% blanking. Both problems are solved by setting BlankingDuration to 3 ms,% but we never checked to find out how low it could be set and still solve% the problem. Just before the 2.52 release we learned from bug reports% (Anthony Helou, David Jones, and David Brainard) that setting% BlankingDuration to 3 ms causes tears in CLUT animations on the Radeon% 7200, and that the tearing is cured by setting BlankingDuration to zero.% However, David Jones reports multiple counting of the blanking on his% Radeon 7200 unless the BlankingDuration is at least 0.2 ms. Looking at% his results for the Radeon 7200 and the ATI Rage128Pro (AGP), it appears% that 0.3 ms would be a good value for both of those cards. So, for the% time being, we're setting the default value to 0.0003. 8/24/02 dgp.% web http://groups.yahoo.com/group/psychtoolbox/message/1320 ;% web http://groups.yahoo.com/group/psychtoolbox/message/1453 ;if (isATIRadeon10Gen1 | isATIRadeon10Gen2)	Screen(screenNumber,'Preference','BlankingDuration',0.003); % 1 mselse	Screen(screenNumber,'Preference','BlankingDuration',0.0003); % 0.3 msend	% Thinking that it was better to do nothing than to do harm by setting the% default too high, we zeroed it, in PrepareScreen, unless a runtime test% indicated that 3 ms helped. However, the runtime test only looked for% the SetClut racing, not the double interrupt.% Not wishing to break old working programs, we've instituted a test to% make the best choice. If SetClut synchs at 3 ms and races at 0, then we% set it to 3 ms. Otherwise we set it to zero.% if ScreenPixelSize(screenNumber)>8% 	clut=[0 0 0];% else% 	clut=[255 255 255];% end% fr=FrameRate(screenNumber);% Screen(screenNumber,'Preference','BlankingDuration',0);% if ~Screen(screenNumber,'Preference','SetClutCallsWaitBlanking')% 	for i=1:4% 		Screen(screenNumber,'SetClut',clut);% 		t(i)=GetSecs;% 	end% 	f=1/median(diff(t));% 	if abs(log(f/fr))<log(1.2) % accept up to 20% error% 		% Works at zero, so leave it there.% 	else% 		% Fails at zero, so try 0.003.% 		Screen(screenNumber,'Preference','BlankingDuration',0.003);% 		for i=1:4% 			Screen(screenNumber,'SetClut',clut);% 			t(i)=GetSecs;% 		end% 		f=1/median(diff(t));% 		if abs(log(f/fr))<log(1.2) % accept up to 20% error% 			% Works at 0.003, so leave it there.% 		else% 			% Failed at 0.003 as well, so revert to zero.% 			Screen(screenNumber,'Preference','BlankingDuration',0);% 		end% 	end% end% MaximumSetClutPriorityif streq(card.driverName,'.Display_NV')	% The NVIDIA GeForce4MX driver is ok at priority 0 or 1, but takes 0.5 s to load clut at priority �2.	Screen(screenNumber,'Preference','MaximumSetClutPriority',1);end	% DipPriorityAfterSetClut and MinimumSetClutPriorityif streq(card.driverName,'.Display_Rage128') | streq(card.driverName,'.Display_RADEON') | isATIRadeon	if ~isATIRadeon9000		% These ATI drivers need priority dipping in order to wait for blanking at high priority.		Screen(screenNumber,'Preference','DipPriorityAfterSetClut',1);		% In 1999 the ATI drivers were slow at low priority. Is this still needed?		Screen(screenNumber,'Preference','MinimumSetClutPriority',2);	endend% DacBitsw=screenNumber;if isRadiusThunder10 | isATIRadeon10Gen1 | isATIRadeon10Gen2	dacBits=10;else	% If the driver has an 8+ table, or will accept one, then we infer that the DACs are 8+.	for i=1 % use FOR so we can BREAK		[oldGammaTable,oldGammaBits,gammaError]=Screen(w,'Gamma'); % save		if gammaError.get			dacBits=8;			break;		end		if oldGammaBits>8			dacBits=oldGammaBits;			break		end		% No hint of 10 bit support, but let's try it anyway and see if it works.		dacBits=10;		gamma=bitshift(257*[0:255]',dacBits-16); % 256 elements, each extended to dacBits bits.		[g,gb,gammaError]=Screen(w,'Gamma',gamma,dacBits); % attempt to load new table		if ~gammaError.set			% Success! We loaded a new gamma table.			break		end		dacBits=8;	end	[g,gb,gammaError]=Screen(w,'Gamma',oldGammaTable,oldGammaBits); % restoreendScreen(w,'Preference','DacBits',dacBits);% Nearly done! Next time we can skip all the work.% We're setting the open flag now, before calling LoadClut, so LoadClut will know the screen has been configured.screenGlobal(screenNumber+1).open=1;% UseHighGammaBitsif dacBits>8	% Try it both ways. Pick the setting that minimizes error.	clut1=ClutDefault(screenNumber,dacBits);	for high=0:1		Screen(screenNumber,'Preference','UseHighGammaBits',high);		rmsError(high+1)=LoadClutError(screenNumber,clut1,dacBits);	end	high=rmsError(1)>rmsError(2);% 	fprintf('rmsError=%.0f,%.0f;high=%d\n',rmsError,high);else	high=0; % doesn't matterendScreen(screenNumber,'Preference','UseHighGammaBits',high);% SetClutDuplicates8Bitsif ScreenClutSize(screenNumber)==256	% Try it both ways. Pick the setting that minimizes error. It only makes a	% difference at high cspec values, so the test is only informative if the	% clut is full length. For short cluts the setting doesn't matter.	% However, the user might have a short clut now and change to a long clut	% later. Note that even if we do have a long clut, some buggy drivers	% refuse to provide cscGetEntries at certain pixelSizes. We could nearly	% always get the information if we changed the pixelSize to 8, but users	% wouldn't like that, since changing pixelSize is slow, visually annoying, and 	% would occur at the start of every program. Instead we resign ourselves to the fact	% that we won't always be able to run this test.	clut1=ClutDefault(screenNumber,dacBits);	clut1=Shuffle(clut1);	for dupe=0:1		Screen(screenNumber,'Preference','SetClutDuplicates8Bits',dupe);		screenGlobal(screenNumber+1).identityColorTableLoaded=0;		rmsError(dupe+1)=LoadClutError(screenNumber,clut1,dacBits);	end	if ~all(isinf(rmsError))		dupe=rmsError(1)>rmsError(2);	else		dupe=nan;	end% 	fprintf('rmsError=%.1f,%.1f;dupe=%d\n',rmsError,dupe);else	dupe=nan;endif ~isfinite(dupe)	% For various reasons we may not have been able to get conclusive test 	% results. In that case we make the setting based on prior knowledge. 	dupe=isATIRadeon;endScreen(screenNumber,'Preference','SetClutDuplicates8Bits',dupe);screenGlobal(screenNumber+1).identityColorTableLoaded=0;% gamma bitsScreen(screenNumber,'Gamma',[0:255]',8); % Use 8-bit gamma table for maximum compatibility.function rmsError=LoadClutError(screenNumber,clut1,dacBits)LoadClut(screenNumber,clut1,0,dacBits);clut2=Screen(screenNumber,'GetClut',dacBits);if ~isempty(clut2) & all(size(clut2)==size(clut1))	rmsError=mean(mean((clut2-clut1).^2)).^0.5;else	rmsError=inf;endreturn