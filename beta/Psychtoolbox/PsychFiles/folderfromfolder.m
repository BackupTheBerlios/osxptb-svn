function [fold,teller] = folderfromfolder(folder,mode)
% [fold,nfold] = folderfromfolder(folder,mode)
%
% Returns struct with all directories in directory FOLDER.
% MODE specifies whether an error is displayed when no directories are
% found (default). If MODE is 'silent', only a message will will be
% displayed in the command window.

% 2007 IH        Wrote it.
% 2007 IH&DN     Various additions
% 2008-08-06 DN  All file properties now in output struct

if nargin == 2 && strcmp(mode,'silent')
    silent = true;
else
    silent = false;
end

A           = double('A');                          % asci-code A
Z           = double('Z');                          % asci-code Z
a           = double('a');                          % asci-code a
z           = double('z');                          % asci-code z
nul         = double('0');                          % asci-code 0
negen       = double('9');                          % asci-code 9
filelist    = dir(folder);

teller = 0;
for p=1:length(filelist),
    fc = double(filelist(p).name(1));               % fc is ascii code first character
    if ((fc >= A && fc <= Z)||(fc >= a && fc <= z)||(fc >= nul && fc <= negen)) && filelist(p).isdir==1,
        teller = teller +1;
        fold(teller) = filelist(p);
    end
end

if teller == 0,
    if silent
        disp(sprintf(['folderfromfolder: No folders found in: ' strrep(folder,'\','\\')]));
        fold = [];
    elseif ~silent
        error(['folderfromfolder: No folders found in: ' folder]);
    end
end