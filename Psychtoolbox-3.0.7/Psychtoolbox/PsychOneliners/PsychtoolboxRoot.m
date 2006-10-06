function path=PsychtoolboxRoot
% path=PsychtoolboxRoot
% Returns the path to the Psychtoolbox folder, even if it's been renamed.
% Also see MatlabRoot, DiskRoot, DesktopFolder.

% 6/29/02 dgp Wrote it, based on a suggestion by David Jones <djones@ece.mcmaster.ca>.
% 9/10/02 dgp Cosmetic.

path=which('PsychtoolboxRoot.m');
i=find(filesep==path);
path=path(1:i(end-1));
