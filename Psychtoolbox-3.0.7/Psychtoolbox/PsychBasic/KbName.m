function kbNameResult = KbName(arg)
% kbNameResult = KbName(arg)
% 	
% 	KbName maps between KbCheck-style keyscan codes and key names.
% 	
% 	� If arg is a string designating a key label then KbName returns the 
% 	  keycode of the indicated key.  
% 	� If arg is a keycode, KbName returns the label of the designated key. 
% 	� If no argument is supplied then KbName waits one second and then 
%     calls KbCheck.  KbName then returns a cell array holding the names of
%     all keys which were down at the time of the KbCheck call. The 
%     one-second delay preceeding the call to KbCheck avoids catching the 
%     <return> keypress used to execute the KbName function. 
% 			
% 	KbName deals with keys, not characters. See KbCheck help for an 
% 	explanation of keys, characters, and keycodes.   
% 	
% 	There are standard character sets, but there are no standard key 
% 	names.  The convention KbName follows is to name keys with  the primary
% 	key label printed on the key.  For example, the the "]}"  key is named
% 	"]" because "]" is the primary key label and "}" is the  shifted key
% 	function.  In the case of  labels such as "5", which appears  on two
% 	keys, the name "5" designates the "5" key on the numeric keypad  and
% 	"5%" designates the QWERTY "5" key. Here, "5" specifies the primary 
% 	label of the key and the shifted label, "%" refines the specification, 
% 	distinguishing it from keypad "5".  Keys labeled with symbols not 
% 	represented in character sets are assigned names describing those
% 	symbols  or the key function, for example the space bar is named
% 	"space" and the apple  key is named "apple".  Some keyboards have
% 	identically-labelled keys distinguished 
%   only by their positions on the keyboard, for example, left and right
%   shift  keys.  Windows operating systems more recent than Windows 95 can
%   distinguish between such keys.  To name such keys, we precede the key
%   label with either  "left_" or "right_", to create the key name.  For
%   example, the left shift key  is called "left_shift".
% 	
% 	Use KbName to make your scripts more readable and portable, using key 
% 	labels instead of keycodes, which are cryptic and vary between Mac and
% 	Windows computers.  
% 	For example, 
% 	
% 	yesKey = KbName('return');           
% 	[a,b,keyCode] = KbCheck;
% 	if keyCode(yesKey)
% 		flushevents('keyDown');
% 		...
% 	end;
%
% OS X _ OS9 _ Windows __________________________________________________
%
%   OS X, OS 9 and Windows versions of KbCheck return different keycodes.
%   You can mostly  overcome those differences by using KbName, but with
%   some complications:
%
%   While most keynames are shared between Windows and Macintosh, not all
%   are. Some key names are used only on Windows, and other key names are
%   used only on Macintosh. For a lists of key names common to both
%   platforms and unique to each see the comments in the  body of KbName.m.
%
%   Your computer might be able to distinguish between identically named
%   keys.  For example, left and right shift keys, or the "enter" key on
%   the keyboard and the enter key on the numeric keypad. Which of these
%   keys it can destinguish depends on the operating system. For details,
%   see comments in the body of KbName.m.
%
%   Historically, different operating systems used different keycodes
%   becuase they used different types of keyboards: PS/2 for Windows, ADB
%   for OS 9, and USB for OS 9, Windows, and OSX.  KbCheck on OS X returns
%   USB keycodes. 
% 	
% _________________________________________________________________________
%
% 	See also KbCheck, KbDemo, KbWait.

%   HISTORY 
%
% 	12/16/98    awi     wrote it
% 	02/12/99    dgp     cosmetic editing of comments
% 	03/19/99    dgp     added "enter" and "function" keys. Cope with hitting multiple keys.
%   02/07/02    awi     added Windows keycodes
%   02/10/02    awi     modified to return key names within a cell array in the case
%                       where no arguments are passed to KbName and it calls KbCheck.
%   02/10/02    awi     Modifed comments for changes made to Windows version. 
%   04/10/02	awi		-Cosmetic
%						-Fixed bug where "MAC2"  case was not in quotes
%						-Fixed bug where Mac loop searching for empty cells overran max index.
%   09/27/02    awi     Wrapped an index in Find() becasue Matlab will no longer index
%						matrices with logicals. 
%   06/18/03    awi     Complete rewrite featuring recursive calls to KbName, new key names, and 
%						a shared execution path for all platforms.  The key codes have been renamed
%                       to be abbreviations of standard USB keycode names.  This breaks scripts
%                       which relied on the old names but fixes the problem
%                       that KbName returned different names on Mac and Windows. See www.usb.org
%						for a table of USB HID keycodes and key names.  
%   06/24/03    awi     Added keycodes for OS 9 KbCheck  
%   06/25/03    awi     -Lowered all keycodes by 1 to match official USB table.  Previously
%						the KbCheck keycodes were the offical USB keycodes + 1 because
%						the USB table is zero-indexed whereas Matlab matrices are one-indexed.
%						As a consequence of this change KbName and KbCheck will not handle keycode
%						0, but that is ok because keycode 0 is not really used for anything.  
%						-Moved test for logical above the the test for doubles  
%						because on OS 9 logicals are also doubles.
%						-Declared the cell arrays to be persistent to conserve 
%						resources.
%	06/25/03	awi		The comment of 09/27/02 (see above) is incorrect, Matlab does still
%						support indexing with logical vectors.  Really the problem
%						was that with Matlab 6 the C mex API had changed and mxSetLogical
%						was unsupported.  KbCheck was not returning an array marked as 
%						type logical. Mex files should use mxCreateLogicalArray() or 
%						mxCreateLogicalMatrix() instead of mxSetLogical.  
% 	
%   10/12/04    awi     Cosmetic changes to comments.
%	   10/4/05   awi Note here cosmetic changes by dgp on unknown date between 10/12/04 and 10/4/05   

%   TO DO
%
%   -Add feature where we accept a matrix of logical row vectors.   
%
%   -Update help documentation:  Add OS X section, Explain new key names, the feature which returns
%   the table, that k=KbName;streq(KbName(KbName(k)),k) is one test of KbName,
%   that keyboards do not distinquish between left and right versions of
%   keys though the standard specifies different keycodes, the problem with the 'a' key.  

persistent kkOSX kkOS9 kkWin kk


if isempty(kkOSX)
	kkOSX = cell(1,256);
	kkOS9 = cell(1,256);
	kkWin = cell(1,256);
	
	%OS X column                                    OS 9 column             	Win Column
	
	% kk{0} = 'Undefined (no event indicated)';									%Wait until there is PsychHID 
	kkOSX{1} = 'ErrorRollOver';                              					%for Windows then use the OS X 
	kkOSX{2} = 'POSTFail';														%table.  
	kkOSX{3} = 'ErrorUndefined';
	kkOSX{4} = 'a';                                 kkOS9{1}='a';
	kkOSX{5} = 'b';                                 kkOS9{12}='b';                                                                                                       
	kkOSX{6} = 'c';                                 kkOS9{9}='c';                                         
	kkOSX{7} = 'd';                                 kkOS9{3}='d';                                          
	kkOSX{8} = 'e';                                 kkOS9{15}='e';                                          
	kkOSX{9} = 'f';                                 kkOS9{4}='f';                                          
	kkOSX{10} = 'g';                                kkOS9{6}='g';                                         
	kkOSX{11} = 'h';                                kkOS9{5}='h'; 
	kkOSX{12} = 'i';                                kkOS9{35}='i';  
	kkOSX{13} = 'j';                                kkOS9{39}='j';
	kkOSX{14} = 'k';                                kkOS9{41}='k';
	kkOSX{15} = 'l';                                kkOS9{38}='l'; 
	kkOSX{16} = 'm';                                kkOS9{47}='m'; 
	kkOSX{17} = 'n';                                kkOS9{46}='n'; 
	kkOSX{18} = 'o';                                kkOS9{32}='o';   
	kkOSX{19} = 'p';                                kkOS9{36}='p';  
	kkOSX{20} = 'q';                                kkOS9{13}='q';  
	kkOSX{21} = 'r';                                kkOS9{16}='r'; 
	kkOSX{22} = 's';                                kkOS9{2}='s';
	kkOSX{23} = 't';                                kkOS9{18}='t';
	kkOSX{24} = 'u';                                kkOS9{33}='u';
	kkOSX{25} = 'v';                                kkOS9{10}='v'; 
	kkOSX{26} = 'w';                                kkOS9{14}='w'; 
	kkOSX{27} = 'x';                                kkOS9{8}='x'; 
	kkOSX{28} = 'y';                                kkOS9{17}='y';  
	kkOSX{29} = 'z';                                kkOS9{7}='z'; 
	kkOSX{30} = '1!';                               kkOS9{19}='1!'; 
	kkOSX{31} = '2@';                               kkOS9{20}='2@';
	kkOSX{32} = '3#';                               kkOS9{21}='3#';  
	kkOSX{33} = '4$';                               kkOS9{22}='4$';
	kkOSX{34} = '5%';                               kkOS9{24}='5%'; 
	kkOSX{35} = '6^';                               kkOS9{23}='6^';  
	kkOSX{36} = '7&';                               kkOS9{27}='7&'; 
	kkOSX{37} = '8*';                               kkOS9{29}='8*';
	kkOSX{38} = '9(';                               kkOS9{26}='9(';
	kkOSX{39} = '0)';                               kkOS9{30}='0)';
	kkOSX{40} = 'Return';                           kkOS9{37}='Return';
	kkOSX{41} = 'ESCAPE';                           kkOS9{54}='ESCAPE';
	kkOSX{42} = 'DELETE';                           kkOS9{52}='DELETE';
	kkOSX{43} = 'tab';                              kkOS9{49}='tab';
	kkOSX{44} = 'space';                            kkOS9{50}='space';
	kkOSX{45} = '-_';                               kkOS9{28}='-_';
	kkOSX{46} = '=+';                               kkOS9{25}='=+'; 
	kkOSX{47} = '[{';                               kkOS9{34}='[{'; 
	kkOSX{48} = ']}';                               kkOS9{31}=']}'; 
	kkOSX{49} = '\|';                               kkOS9{43}='\|';
	
	% Typical language mappings: US: \| Belg: �`� FrCa: <}> Dan:�* Dutch: <> Fren:*� Ger: #� Ital: �� LatAm: }`] Nor:,* Span: }� Swed: ,* Swiss: $� UK: #~.
	kkOSX{50} = '#-';                               
	
	kkOSX{51} = ';:';                               kkOS9{42}=';:';   
	kkOSX{52} = '''"';                              kkOS9{40}='''"';                    
	kkOSX{53} = '`~';                               kkOS9{51}='`~';
	kkOSX{54} = ',<';                               kkOS9{44}=',<'; 
	kkOSX{55} = '.>';                               kkOS9{48}='.>';
	kkOSX{56} = '/?';                               kkOS9{45}='/?';     
	kkOSX{57} = 'CapsLock';                         kkOS9{58}='CapsLock'; %FIX if other capslock
	kkOSX{58} = 'F1';                               kkOS9{123}='F1'; 
	kkOSX{59} = 'F2';                               kkOS9{121}='F2';
	kkOSX{60} = 'F3';                               kkOS9{100}='F3'; 
	kkOSX{61} = 'F4';                               kkOS9{119}='F4'; 
	kkOSX{62} = 'F5';                               kkOS9{97}='F5';
	kkOSX{63} = 'F6';                               kkOS9{98}='F6';
	kkOSX{64} = 'F7';                               kkOS9{99}='F7';   
	kkOSX{65} = 'F8';                               kkOS9{101}='F8';     
	kkOSX{66} = 'F9';                               kkOS9{102}='F9'; 
	kkOSX{67} = 'F10';                              kkOS9{110}='F10'; 
	kkOSX{68} = 'F11';                              kkOS9{104}='F11'; 
	kkOSX{69} = 'F12';                              kkOS9{112}='F12';
	kkOSX{70} = 'PrintScreen';                       
	kkOSX{71} = 'ScrollLock';                       
	kkOSX{72} = 'Pause';                            
	kkOSX{73} = 'Insert';                           
	kkOSX{74} = 'Home';                             kkOS9{116}='Home'; 
	kkOSX{75} = 'PageUp';                           kkOS9{117}='PageUp';   
	kkOSX{76} = 'DeleteForward';                    kkOS9{118}='DeleteForward';
	kkOSX{77} = 'End';                              kkOS9{120}='End';
	kkOSX{78} = 'PageDown';                         kkOS9{122}='PageDown'; 
	kkOSX{79} = 'RightArrow';                       kkOS9{125}='RightArrow'; 
	kkOSX{80} = 'LeftArrow';                        kkOS9{124}='LeftArrow';
	kkOSX{81} = 'DownArrow';                        kkOS9{126}='DownArrow';
	kkOSX{82} = 'UpArrow';                          kkOS9{127}='UpArrow';
	kkOSX{83} = 'NumLockClear';                     kkOS9{72}='NumLockClear';
	kkOSX{84} = '/';                                kkOS9{76}='/'; 
	kkOSX{85} = '*';                                kkOS9{68}='*';
	kkOSX{86} = '-';                                kkOS9{79}='-';
	kkOSX{87} = '+';                                kkOS9{70}='+';
	kkOSX{88} = 'ENTER';                            kkOS9{77}='ENTER';   
	kkOSX{89} = '1';                                kkOS9{84}='1';
	kkOSX{90} = '2';                                kkOS9{85}='2';  
	kkOSX{91} = '3';                                kkOS9{86}='3'; 
	kkOSX{92} = '4';                                kkOS9{87}='4';
	kkOSX{93} = '5';                                kkOS9{88}='5'; 
	kkOSX{94} = '6';                                kkOS9{89}='6';  
	kkOSX{95} = '7';                                kkOS9{90}='7'; 
	kkOSX{96} = '8';                                kkOS9{92}='8'; 
	kkOSX{97} = '9';                                kkOS9{93}='9';
	kkOSX{98} = '0';                                kkOS9{83}='0'; 
	kkOSX{99} = '.';                                kkOS9{66}='.';
	
	% Non-US.  
	% Typical language mappings: Belg:<\> FrCa:ǡ� Dan:<\> Dutch:]|[ Fren:<> Ger:<|> Ital:<> LatAm:<> Nor:<> Span:<> Swed:<|> Swiss:<\> UK:\| Brazil: \|.
	% Typically near the Left-Shift key in AT-102 implementations.
	kkOSX{100} = 'NonUS\|';                              
	
	% Windows key for Windows 95, and �Compose.�
	kkOSX{101} = 'Application';                     
	
	% Reserved for typical keyboard status or keyboard errors. Sent as a member of the keyboard array. Not a physical key.
	kkOSX{102} = 'Power';                                       
	kkOSX{103} = '=';                               kkOS9{82}='=';
	kkOSX{104} = 'F13';                             kkOS9{106}='F13';
	kkOSX{105} = 'F14';                             kkOS9{108}='F14';   
	kkOSX{106} = 'F15';                             kkOS9{114}='F15'; 
	kkOSX{107} = 'F16';                            
	kkOSX{108} = 'F17';                            
	kkOSX{109} = 'F18';                            
	kkOSX{110} = 'F19';                             
	kkOSX{111} = 'F20';                           
	kkOSX{112} = 'F21';                           
	kkOSX{113} = 'F22';                            
	kkOSX{114} = 'F23';                             
	kkOSX{115} = 'F24';                            
	kkOSX{116} = 'Execute';                        
	kkOSX{117} = 'Help';                            kkOS9{115}='Help';
	kkOSX{118} = 'Menu';                            
	kkOSX{119} = 'Select';                         
	kkOSX{120} = 'Stop';                            
	kkOSX{121} = 'Again';                          
	kkOSX{122} = 'Undo';                           
	kkOSX{123} = 'Cut';                          
	kkOSX{124} = 'Copy';                            
	kkOSX{125} = 'Paste';                           
	kkOSX{126} = 'Find';                            
	kkOSX{127} = 'Mute';                           
	kkOSX{128} = 'VolumeUp';                        
	kkOSX{129} = 'VolumeDown';                      
	
	%Implemented as a locking key; sent as a toggle button. Available for legacy support; however, most systems should use the non-locking version of this key.
	kkOSX{130} = 'LockingCapsLock';                  
	
	%Implemented as a locking key; sent as a toggle button. Available for legacy support; however, most systems should use the non-locking version of this key.
	kkOSX{131} = 'LockingNumLock';                  
	
	%Implemented as a locking key; sent as a toggle button. Available for legacy support; however, most systems should use the non-locking version of this key.
	kkOSX{132} = 'LockingScrollLock';               
	
	% Keypad Comma is the appropriate usage for the Brazilian keypad period (.) key. 
	%This represents the closest possible match, and system software should do the correct mapping based on the current locale setting.
	kkOSX{133} = 'Comma';                            
	
	kkOSX{134} = 'EqualSign';                       
	kkOSX{135} = 'International1';                 
	kkOSX{136} = 'International2';                  
	kkOSX{137} = 'International3';                  
	kkOSX{138} = 'International4';                  
	kkOSX{139} = 'International5';                  
	kkOSX{140} = 'International6';                  
	kkOSX{141} = 'International7';                  
	kkOSX{142} = 'International8';                  
	kkOSX{143} = 'International9';                  
	kkOSX{144} = 'LANG1';                           
	kkOSX{145} = 'LANG2';                           
	kkOSX{146} = 'LANG3';                          
	kkOSX{147} = 'LANG4';                          
	kkOSX{148} = 'LANG5';                          
	kkOSX{149} = 'LANG6';                         
	kkOSX{150} = 'LANG7';                           
	kkOSX{151} = 'LANG8';                          
	kkOSX{152} = 'LANG9';                           
	kkOSX{153} = 'AlternateErase';                 
	kkOSX{154} = 'SysReq/Attention';               
	kkOSX{155} = 'Cancel';                         
	kkOSX{156} = 'Clear';                          
	kkOSX{157} = 'Prior';                        
	kkOSX{158} = 'Return';                         
	kkOSX{159} = 'Separator';                       
	kkOSX{160} = 'Out';                          
	kkOSX{161} = 'Oper';                        
	kkOSX{162} = 'Clear/Again';                 
	kkOSX{163} = 'CrSel/Props';                  
	kkOSX{164} = 'ExSel';                           
	kkOSX{165} = 'Undefined';                       
	kkOSX{166} = 'Undefined';                       
	kkOSX{167} = 'Undefined';                       
	kkOSX{168} = 'Undefined';                       
	kkOSX{169} = 'Undefined';                       
	kkOSX{170} = 'Undefined';                       
	kkOSX{171} = 'Undefined';                       
	kkOSX{172} = 'Undefined';                      
	kkOSX{173} = 'Undefined';                       
	kkOSX{174} = 'Undefined';                      
	kkOSX{175} = 'Undefined';                       
	kkOSX{176} = '00';                              
	kkOSX{177} = '000';                            
	kkOSX{178} = 'ThousandsSeparator';             
	kkOSX{179} = 'DecimalSeparator';               
	kkOSX{180} = 'CurrencyUnit';                    
	kkOSX{181} = 'CurrencySub-unit';                
	kkOSX{182} = '(';                              
	kkOSX{183} = ')';                               
	kkOSX{184} = '{';                               
	kkOSX{185} = '}';                               
	kkOSX{186} = 'KeypadTab';                       
	kkOSX{187} = 'KeypadBackspace';                 
	kkOSX{188} = 'KeypadA';                         
	kkOSX{189} = 'KeypadB';                        
	kkOSX{190} = 'KeypadC';                         
	kkOSX{191} = 'KeypadD';                        
	kkOSX{192} = 'KeypadE';                        
	kkOSX{193} = 'KeypadF';                         
	kkOSX{194} = 'XOR';                            
	kkOSX{195} = '^';                               
	kkOSX{196} = '%';                               
	kkOSX{197} = '<';                               
	kkOSX{198} = '>';                               
	kkOSX{199} = '&';                              
	kkOSX{200} = '&&';                              
	kkOSX{201} = '|';                              
	kkOSX{202} = '||';                            
	kkOSX{203} = ':';                            
	kkOSX{204} = '#';                               
	kkOSX{205} = 'KeypadSpace';                     
	kkOSX{206} = '@';                              
	kkOSX{207} = '!';                               
	kkOSX{208} = 'MemoryStore';                     
	kkOSX{209} = 'MemoryRecall';                   
	kkOSX{210} = 'MemoryClear';                     
	kkOSX{211} = 'MemoryAdd';                      
	kkOSX{212} = 'MemorySubtract';                 
	kkOSX{213} = 'MemoryMultiply';                 
	kkOSX{214} = 'MemoryDivide';                   
	kkOSX{215} = '+/-';                             
	kkOSX{216} = 'KeypadClear';                    
	kkOSX{217} = 'KeypadClearEntry';                
	kkOSX{218} = 'KeypadBinary';                    
	kkOSX{219} = 'KeypadOctal';                     
	kkOSX{220} = 'KeypadDecimal';                  
	kkOSX{221} = 'Undefined';                       
	kkOSX{222} = 'Undefined';                       
	kkOSX{223} = 'Undefined';                       
	kkOSX{224} = 'LeftControl';                     kkOS9{60}='LeftControl';    %double entry  
	kkOSX{225} = 'LeftShift';                       kkOS9{57}='LeftShift';      %double entry
	kkOSX{226} = 'LeftAlt';                         kkOS9{59}='LeftAlt';        %double entry
	
	%Windows key for Windows 95, and �Compose.�  Windowing environment key, examples are Microsoft Left Win key, Mac Left Apple key, Sun Left Meta key
	kkOSX{227} = 'LeftGUI';                         kkOS9{56}='LeftGUI';        %double entry
	
	kkOSX{228} = 'RightControl';                    %kkOS9{60}='RightControl'; % FIX double entry
	kkOSX{229} = 'RightShift';                      %kkOS9{57}='RightShift'; % FIX double entry
	kkOSX{230} = 'RightAlt';                        %kkOS9{59}='RightAlt';   % FIX double entry
	kkOSX{231} = 'RightGUI';                        %kkOSX{56} ='RightGUI';  % FIX double entry                                              
	kkOSX{232} = 'Undefined';                      
	kkOSX{233} = 'Undefined';                     
	kkOSX{234} = 'Undefined';                   
	kkOSX{235} = 'Undefined';                      
	kkOSX{236} = 'Undefined';                   
	kkOSX{237} = 'Undefined';                       
	kkOSX{238} = 'Undefined';                      
	kkOSX{239} = 'Undefined';                      
	kkOSX{240} = 'Undefined';                       
	kkOSX{241} = 'Undefined';                      
	kkOSX{242} = 'Undefined';                    
	kkOSX{243} = 'Undefined';                      
	kkOSX{244} = 'Undefined';                    
	kkOSX{245} = 'Undefined';                       
	kkOSX{246} = 'Undefined';                      
	kkOSX{247} = 'Undefined';                       
	kkOSX{248} = 'Undefined';                      
	kkOSX{249} = 'Undefined';                       
	kkOSX{250} = 'Undefined';                       
	kkOSX{251} = 'Undefined';                       
	kkOSX{252} = 'Undefined';                      
	kkOSX{253} = 'Undefined';                     
	kkOSX{254} = 'Undefined';                       
	kkOSX{255} = 'Undefined';                       
	kkOSX{256} = 'Undefined';                                              
	% 257-65535 E8-FFFF Reserved
	
	% Platform-specific key names.  The PowerBook G3 built-in keyboard might
	% not be 
	kkOS9{64}='MacPowerbookG3Function';
	kkOS9{53}='MacPowerbookG3Enter';
	
	% Fill in holes in the OS9 table
	for i=1:256
	    if(isempty(kkOS9{i}))
	        kkOS9{i}='Undefined';
	    end
	end

	% Choose the default table according to the platform
	if IsOS9
	        kk=kkOS9;
	elseif IsOSX
	    	kk=kkOSX;
	elseif IsWin
	        kk=kkWin;
	end
	

end %if ~exist(kkOSX)
        
%if there are no inputs then use KbCheck to get one and call KbName on
%it.
if nargin==0
    WaitSecs(1);
    keyPressed = 0;
    while (~keyPressed)
        [keyPressed, secs, keyCodes] = KbCheck;
    end
    kbNameResult= KbName(keyCodes);  %note that keyCodes should be of type logical here.

%if the argument is a logical array then convert to a list of doubles and
%recur on the result. 
%Note that this case must come before the test for double below.  In Matlab 5 logicals are also
%doubles but in Matlab 6.5 logicals are not doubles.  
elseif islogical(arg)
    kbNameResult=KbName(find(arg));
	
%if the argument is a double or a list of doubles 
elseif isa(arg,'double')
    %single element, the base case, we look up the name.
    if length(arg) == 1
        if(arg < 1 | arg > 65535)
            error('Argument exceeded allowable range of 1-65536');
        elseif arg > 255 
            kbNameResult='Undefined';
        else
            kbNameResult=kk{arg};
        end;
    else
        %multiple numerical values, we iterate accross the list and recur
        %on each element.
        for i = 1:length(arg)
            kbNameResult{i}=KbName(arg(i));
        end
    end

%argument is  a single string so either it is a...
% - command requesting a table, so return the table.
% - key name, so lookup and return the corresponding key code.  
elseif ischar(arg)      % argument is a character, so find the code
    if strcmpi(arg, 'Undefined')
        kbNameResult=[];            % is is not certain what we should do in this case.  It might be better to issue an error.
    elseif strcmpi(arg, 'KeyNames')  %list all keynames for this platform
        kbNameResult=kk;
    elseif strcmpi(arg, 'KeyNamesOSX')  %list all kenames for the OS X platform
        kbNameResult=kkOSX;
	elseif strcmpi(arg, 'KeyNamesOS9') 
		kbNameResult=kkOS9; 
	else
        kbNameResult=find(strcmpi(kk, arg));
        if isempty(kbNameResult)
            error(['Key name "' arg '" not recognized.']);
        end
    end
    
% we have a cell arry of strings so iterate over the cell array and recur on each element.    
elseif isa(arg, 'cell')
    kbNameResult=[]
    for i = 1:length(arg)
        kbNameResult(i)=KbName(arg{i});
    end
end

