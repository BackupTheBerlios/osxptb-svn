function glUniform3fv( location, count, value )

% glUniform3fv  Interface to OpenGL function glUniform3fv
%
% usage:  glUniform3fv( location, count, value )
%
% C function:  void glUniform3fv(GLint location, GLsizei count, const GLfloat* value)

% 05-Mar-2006 -- created (generated automatically from header files)

if nargin~=3,
    error('invalid number of arguments');
end

moglcore( 'glUniform3fv', location, count, moglsingle(value) );

return
