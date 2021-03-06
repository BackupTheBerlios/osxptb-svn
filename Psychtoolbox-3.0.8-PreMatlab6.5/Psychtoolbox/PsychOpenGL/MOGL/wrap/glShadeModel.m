function glShadeModel( mode )

% glShadeModel  Interface to OpenGL function glShadeModel
%
% usage:  glShadeModel( mode )
%
% C function:  void glShadeModel(GLenum mode)

% 05-Mar-2006 -- created (generated automatically from header files)

if nargin~=1,
    error('invalid number of arguments');
end

moglcore( 'glShadeModel', mode );

return
