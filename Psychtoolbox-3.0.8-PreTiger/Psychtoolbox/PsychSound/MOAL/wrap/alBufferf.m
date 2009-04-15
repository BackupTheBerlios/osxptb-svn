function alBufferf( bid, param, value )

% alBufferf  Interface to OpenAL function alBufferf
%
% usage:  alBufferf( bid, param, value )
%
% C function:  void alBufferf(ALuint bid, ALenum param, ALfloat value)

% 06-Feb-2007 -- created (generated automatically from header files)

if nargin~=3,
    error('invalid number of arguments');
end

moalcore( 'alBufferf', bid, param, value );

return
