function alBufferi( bid, param, value )

% alBufferi  Interface to OpenAL function alBufferi
%
% usage:  alBufferi( bid, param, value )
%
% C function:  void alBufferi(ALuint bid, ALenum param, ALint value)

% 06-Feb-2007 -- created (generated automatically from header files)

if nargin~=3,
    error('invalid number of arguments');
end

moalcore( 'alBufferi', bid, param, value );

return
