function handle = LoadGLSLProgramFromFiles(filenames, debug, extraShaders)
% handle = LoadGLSLProgramFromFiles(filenames [, debug] [, extraShaders])
% Loads a GLSL OpenGL shading language program. All shader definition files in
% 'filenames' are read, shaders are built for each definition and all
% shaders are linked together into a new GLSL program. Returns a handle to
% the new program, if successfull. The optional 'debug' flag allows to enable
% debugging output.
%
% The program can then be used at any time by calling glUseProgram(handle). One
% can switch back to the standard OpenGL fixed-function pipeline by calling
% glUseProgram(0). The same handles can be passed to the
% Screen('MakeTexture', ...), Screen('DrawTexture', ...); et al. routines
% to define procedural textures - or some processing operations on them
% via the  'textureShader' argument -- See 'help ProceduralShadingAPI' for
% more info about procedural texturing. The handle is also used to build
% GLOperators for Screen('TransformTexture') or as plugins for the imaging
% pipeline: See 'help CreateGLOperator' or 'help AddToGLOperator' for info.
%
% 'filenames' can have one of two formats: If filenames is a array of
% strings that define the names of the shaders to use, then all shader
% files are loaded, compiled and linked into a single program. E.g.,
% shaderfiles={ 'myshader.vert' , 'myothershader.frag'}; will try to load
% the two shaderfiles myshader.vert and myothershader.frag and link them
% into a valid program.
%
% If only a single filename is given, then all shaders beginning with that
% name are linked into a program. E.g., shaderfiles = 'Phonglighting' will
% try to link all files starting with Phonglighting.
%
% The optional argument 'extraShaders' if present, should be a vector of
% additinal shader handles - Handles returned by the LoadShaderFromFile()
% or by your self-compiled shaders via glCompileShader(). All precompiled
% shaders referenced by those handles get also linked into the final GLSL
% program.

% 29-Mar-2006 written by MK

global GL;

if isempty(GL)
    % Load & Initalize constants and moglcore, but don't set the 3D gfx
    % flag for Screen():
    InitializeMatlabOpenGL([], [], 1);
end;

if nargin < 2
    debug = [];
end;

if isempty(debug)
    debug = 0;
end

if nargin < 1
    filenames = [];
end

if isempty(filenames)
    error('No filenames for GLSL program provided! Aborted.');
end;

if nargin < 3
    extraShaders = [];
end

% Make sure we run on a GLSL capable system.
AssertGLSL;

% Create new program object and get handle to it:
handle = glCreateProgram;
if handle <= 0
    fprintf('The handle created by glCreateProgram is %i -- An invalid handle!\n', handle);
    error('LoadGLSLProgramFromFiles: glCreateProgram failed to create a valid program object! Something is wrong with your graphics drivers!');
end

if ischar(filenames)
    % One single name given. Load and link all shaders starting with that
    % name:
    if debug>1
        fprintf('Compiling all shaders matching %s * into a GLSL program...\n', filenames);
    end;

    % Add default shader path if no path is specified as part of
    % 'filenames':
    if isempty(fileparts(filenames))
        filenames = [ PsychtoolboxRoot 'PsychOpenGL/PsychGLSLShaders/' filenames ];
    end;
    
    shaderobjs=dir([filenames '*']);
    shaderobjpath = [fileparts([filenames '*']) '/'];
    filenames=[];
    numshaders=size(shaderobjs,1)*size(shaderobjs,2);
    
    if numshaders == 0
        fprintf('In LoadGLSLProgramFromFiles: When trying to load shaders matching %s ...\n', filenames);
        error('Could not find any shader definition files matching that name. Check spelling.');
    end
    
    for i=1:numshaders
        [dummy1 curname curext curver] = fileparts(shaderobjs(i).name);
        shadername = [curname curext curver];
        filenames{i} = [shaderobjpath shadername]; %#ok<AGROW>
    end;
end;

% Load, compile and attach each single shader of each single file:
for i=1:length(filenames)
    shadername = char(filenames(i));
    % We only load the shader if its name does not end in tilde or .asv,
    % because that would mean it is a Matlab- or emacs backup file...
    if (shadername(end)~='~') & (isempty(strfind(shadername, '.asv'))) %#ok<AND2>
       % Load, compile and link the shader:
       shader = LoadShaderFromFile(shadername, [], debug);
       glAttachShader(handle, shader);
    end;
end;

% Any additional shader handles provided?
if ~isempty(extraShaders)
    % Attach all of them as well:
    for i=1:length(extraShaders)
       glAttachShader(handle, extraShaders(i));
    end
end

% Link the program:
glLinkProgram(handle);

% Ready to use it? Hopefully.
return;
