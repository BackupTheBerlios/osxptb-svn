function glTexCoord1fv( v )

% glTexCoord1fv  Interface to OpenGL function glTexCoord1fv
%
% usage:  glTexCoord1fv( v )
%
% C function:  void glTexCoord1fv(const GLfloat* v)

% 05-Mar-2006 -- created (generated automatically from header files)

if nargin~=1,
    error('invalid number of arguments');
end

moglcore( 'glTexCoord1fv', moglsingle(v) );

return
