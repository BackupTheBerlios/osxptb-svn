function params = glGetMinmaxParameterfv( target, pname )

% glGetMinmaxParameterfv  Interface to OpenGL function glGetMinmaxParameterfv
%
% usage:  params = glGetMinmaxParameterfv( target, pname )
%
% C function:  void glGetMinmaxParameterfv(GLenum target, GLenum pname, GLfloat* params)

% 05-Mar-2006 -- created (generated automatically from header files)

% ---allocate---

if nargin~=2,
    error('invalid number of arguments');
end

params = moglsingle(0);

moglcore( 'glGetMinmaxParameterfv', target, pname, params );

return
