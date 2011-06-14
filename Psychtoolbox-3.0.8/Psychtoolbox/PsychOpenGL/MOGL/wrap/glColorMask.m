function glColorMask( red, green, blue, alpha )

% glColorMask  Interface to OpenGL function glColorMask
%
% usage:  glColorMask( red, green, blue, alpha )
%
% C function:  void glColorMask(GLboolean red, GLboolean green, GLboolean blue, GLboolean alpha)

% 05-Mar-2006 -- created (generated automatically from header files)

if nargin~=4,
    error('invalid number of arguments');
end

moglcore( 'glColorMask', red, green, blue, alpha );

return
