function glColor3fv( v )

% glColor3fv  Interface to OpenGL function glColor3fv
%
% usage:  glColor3fv( v )
%
% C function:  void glColor3fv(const GLfloat* v)

% 05-Mar-2006 -- created (generated automatically from header files)

if nargin~=1,
    error('invalid number of arguments');
end

moglcore( 'glColor3fv', moglsingle(v) );

return