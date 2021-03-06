function glUniformMatrix2fv( location, count, transpose, value )

% glUniformMatrix2fv  Interface to OpenGL function glUniformMatrix2fv
%
% usage:  glUniformMatrix2fv( location, count, transpose, value )
%
% C function:  void glUniformMatrix2fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value)

% 05-Mar-2006 -- created (generated automatically from header files)

if nargin~=4,
    error('invalid number of arguments');
end

moglcore( 'glUniformMatrix2fv', location, count, transpose, moglsingle(value) );

return
