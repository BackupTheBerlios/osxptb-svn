function r = alIsSource( sid )

% alIsSource  Interface to OpenAL function alIsSource
%
% usage:  r = alIsSource( sid )
%
% C function:  ALboolean alIsSource(ALuint sid)

% 06-Feb-2007 -- created (generated automatically from header files)

if nargin~=1,
    error('invalid number of arguments');
end

r = moalcore( 'alIsSource', sid );

return
