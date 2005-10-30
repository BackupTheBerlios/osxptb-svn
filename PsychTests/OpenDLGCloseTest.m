% OpenDLGCloseTest% This script tests Screen's work around for what seems to% be a bug in Matlab. The two Matlab DLG functions below,% when dismissed by the user, make Screen's window the current port.% This was causing the calls to Screen Close and CloseAll to fail:% "??? GDOpenWindow.c 530: GDDisposeWindow can't dispose of window while it's% the current port."% The solution was to enhance Screen to save the current port when it's% valid and use that value to restore it when it's invalid. This allows% the following two tests to succeed.% These scripts are based on the bug report by Charles Collin:% web http://groups.yahoo.com/group/psychtoolbox/message/840% web http://groups.yahoo.com/group/psychtoolbox/message/868% 2/21/02 dgp% 4/24/02 awi Exit on PC with message.if IsWin    error('Win: OpenDLGCloseTest not yet supported.');endwin=Screen(0,'OpenWindow');info=INPUTDLG('Enter: ', 'Input', 1, {'test'});Screen('CloseAll');win=Screen(0,'OpenWindow');x=QUESTDLG('A question');Screen(win,'Close');