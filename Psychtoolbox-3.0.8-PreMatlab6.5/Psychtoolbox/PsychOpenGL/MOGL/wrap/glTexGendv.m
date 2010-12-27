function glTexGendv( coord, pname, params )

% glTexGendv  Interface to OpenGL function glTexGendv
%
% usage:  glTexGendv( coord, pname, params )
%
% C function:  void glTexGendv(GLenum coord, GLenum pname, const GLdouble* params)

% 05-Mar-2006 -- created (generated automatically from header files)

if nargin~=3,
    error('invalid number of arguments');
end

moglcore( 'glTexGendv', coord, pname, double(params) );

return
