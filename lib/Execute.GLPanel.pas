unit Execute.GLPanel;
{
  GLFrame Delphi Sydney (c)2011 Execute SARL <contact@execute.fr>
}
interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.OpenGL, Winapi.OpenGLext,
  System.SysUtils, System.Variants, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs;

type
  TMatrix = array[0..15] of Single;

  TGLPanel = class(TFrame)
  private
    { Déclarations privées }
    FDC     : THandle;
    FGL     : THandle;
    FOnSetup: TNotifyEvent;
    FOnPaint: TNotifyEvent;
    FMultiFormat: Integer;
    procedure WMEraseBkGnd(var Msg: TMessage); message WM_ERASEBKGND;
    procedure WMPaint(var Msg: TMessage); message WM_PAINT;
    procedure ResizeGL;
  protected
    procedure CreateWnd; override;
    procedure Resize; override;
    procedure DestroyWnd; override;
  public
    { Déclarations publiques }
    procedure Project3D;
    procedure Project2D;
    property OnSetup:TNotifyEvent read FOnSetup write FOnSetup;
    property OnPaint:TNotifyEvent read FOnPaint write FOnPaint;
  end;

function glxCompileProgram(const VertexShader, FragmentShader: AnsiString): Cardinal;

implementation

{$R *.dfm}

function glxCompileShader(shaderType: Integer; const Source: AnsiString; var Shader: Cardinal): Boolean;
var
  Src: PAnsiChar;
  Len: Integer;
begin
  Shader := glCreateShader(shaderType);
  Src := PAnsiChar(Source);
  Len := Length(Source);
  glShaderSource(Shader, 1, @Src, @Len);
  glCompileShader(Shader);
  glGetShaderiv(Shader, GL_COMPILE_STATUS, @Len);
  Result := Len = GL_TRUE;
end;

function glxGetShaderError(shader: Cardinal): string;
var
  i: Integer;
  s: AnsiString;
begin
  glGetShaderiv(Shader, GL_INFO_LOG_LENGTH, @i);
  SetLength(s, i + 1);
  glGetShaderInfoLog(Shader, i, @i, @s[1]);
  Result := string(s);
end;

function glxLinkProgram(VertexShader, FragmentShader: Cardinal; var Pgm: Cardinal): Boolean;
var
  Err: Integer;
begin
  Pgm := glCreateProgram();
  glAttachShader(Pgm, VertexShader);
  glAttachShader(Pgm, FragmentShader);
  glLinkProgram(Pgm);
  glGetProgramiv(Pgm, GL_LINK_STATUS, @Err);
  Result := Err = GL_TRUE;
end;

function glxGetProgramError(pgm: Cardinal): string;
var
  i: Integer;
  s: AnsiString;
begin
  glGetProgramiv(Pgm, GL_INFO_LOG_LENGTH, @i);
  SetLength(s, i);
  glGetProgramInfoLog(Pgm, i, @i, @s[1]);
  Result := string(s);
end;

function glxCompileProgram(const VertexShader, FragmentShader: AnsiString): Cardinal;
var
  Vertex: Cardinal;
  Fragment: Cardinal;
begin
  if not glxCompileShader(GL_VERTEX_SHADER, VertexShader, Vertex) then
    raise Exception.Create(glxGetShaderError(Vertex));
  if not glxCompileShader(GL_FRAGMENT_SHADER, FragmentShader, Fragment) then
    raise Exception.Create(glxGetShaderError(Fragment));
  if not glxLinkProgram(Vertex, Fragment, Result) then
    raise Exception.Create(glxGetProgramError(Result));
  glDeleteShader(Vertex);
  glDeleteShader(Fragment);
end;

const
  WGL_DRAW_TO_WINDOW_ARB    = $2001;
  WGL_ACCELERATION_ARB      = $2003;
  WGL_SUPPORT_OPENGL_ARB    = $2010;
  WGL_DOUBLE_BUFFER_ARB     = $2011;
  WGL_PIXEL_TYPE_ARB        = $2013;
  WGL_COLOR_BITS_ARB        = $2014;
  WGL_ALPHA_BITS_ARB        = $201B;
  WGL_DEPTH_BITS_ARB        = $2022;
  WGL_STENCIL_BITS_ARB      = $2023;
  WGL_FULL_ACCELERATION_ARB = $2027;
  WGL_SAMPLE_BUFFERS_ARB    = $2041;
  WGL_SAMPLES_ARB           = $2042;
  WGL_TYPE_RGBA_ARB         = $202B;
  GL_MULTISAMPLE_ARB        = $809D;

var
  MultiSampleAttr2i : array[0..9, 0..1] of Integer = (
    (WGL_DRAW_TO_WINDOW_ARB, GL_TRUE),
    (WGL_SUPPORT_OPENGL_ARB, GL_TRUE),
    (WGL_DOUBLE_BUFFER_ARB, GL_TRUE),
    (WGL_PIXEL_TYPE_ARB, WGL_TYPE_RGBA_ARB),
    (WGL_COLOR_BITS_ARB, 32),
    (WGL_DEPTH_BITS_ARB, 24),
    (WGL_STENCIL_BITS_ARB, 8),
    (WGL_SAMPLE_BUFFERS_ARB, 1),
    (WGL_SAMPLES_ARB, 4),
    (0,0)
  );
  MultiSampleAttr2f : array[0..1] of Single = (0,0);

  wglChoosePixelFormatARB : function(HDC: LongWord; const Attr2iv; const Attri2fv; MaxFormat: Integer; var Formats, FormatCount: Integer): Boolean; stdcall;

function initMultiSample: Boolean;
begin
//  Result := False;
  wglChoosePixelFormatARB := wglGetProcAddress('wglChoosePixelFormatARB');
  Result := @wglChoosePixelFormatARB <> nil;
end;

{ TGLPanel }

procedure TGLPanel.CreateWnd;
 var
  pfd: TPIXELFORMATDESCRIPTOR;
  pixelformat: Integer;
  formatCount: Integer;
  Cl: TRGBQuad;
 begin
  inherited;
  FDC := GetDC(Handle);
  if FDC = 0 then
    Exit;
 // set pixel format
  FillChar(pfd, SizeOf(pfd), 0);
  pfd.nSize       := sizeof(pfd);
  pfd.nVersion    := 1;
  pfd.dwFlags     := PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER;
  pfd.iLayerType  := PFD_MAIN_PLANE;
  pfd.iPixelType  := PFD_TYPE_RGBA;
  pfd.cColorBits  := 32;
  pfd.iLayerType  := PFD_MAIN_PLANE;
  pfd.cStencilBits:= 0;

  if FMultiFormat <> 0 then
    PixelFormat := FMultiFormat
  else begin
    PixelFormat := ChoosePixelFormat(FDC, @pfd);
    if PixelFormat = 0 then
      RaiseLastOSError;
  end;

  if not SetPixelFormat(FDC, pixelformat, @pfd) then
    Exit;
 // create OpenGL Context
  FGL := wglCreateContext(FDC);
 // select it
  wglMakeCurrent(FDC, FGL);

  if (FMultiFormat = 0) and InitMultiSample then
  begin
    MultiSampleAttr2i[8, 1] := 4;
    if wglChoosePixelFormatARB(FDC, MultiSampleAttr2i, MultiSampleAttr2f, 1, PixelFormat, FormatCount) then
    begin
      if FormatCount > 0 then
        FMultiFormat := PixelFormat;
    end;
    if FMultiFormat = 0 then
    begin
      MultiSampleAttr2i[8, 1] := 2;
      if wglChoosePixelFormatARB(FDC, MultiSampleAttr2i, MultiSampleAttr2f, 1, pixelFormat, FormatCount)  then
      begin
        if FormatCount > 0 then
          FMultiFormat := PixelFormat;
      end;
    end;
    if FMultiFormat <> 0 then
    begin
      DestroyWnd;
      CreateWnd;
      Exit;
    end;
  end;

  if FMultiFormat <> 0 then
  begin
    glEnable(GL_MULTISAMPLE_ARB);
  end;

 // setup GL mode
  glEnable(GL_DEPTH_TEST);
  glEnable(GL_CULL_FACE);
 // setup the clear color
  Integer(cl) := ColorToRGB(Color);
  glClearColor(cl.rgbRed/255, cl.rgbGreen/255, cl.rgbBlue/255, 1);
 // setup the clear depth
  glClearDepth(1);

  InitOpenGLext;

  if Assigned(FOnSetup) then
    FOnSetup(Self);

  ResizeGL();

  if Assigned(OnResize) then
    OnResize(Self);
end;

procedure TGLPanel.DestroyWnd;
begin
  if FGL <> 0 then
  begin
    wglMakeCurrent(FDC, 0);
    wglDeleteContext(FGL);
    FGL := 0;
  end;
  if FDC <> 0 then
  begin
    DeleteDC(FDC);
    FDC := 0;
  end;
  inherited;
end;

procedure TGLPanel.Project2D;
begin
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  glOrtho(0, ClientWidth, ClientHeight, 0, -100000, +100000);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
end;

procedure TGLPanel.Project3D;
begin
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  gluPerspective(45, ClientWidth/ClientHeight, 0.1, 1000);
  glMatrixMode(GL_MODELVIEW);
  glViewport(0, 0, ClientWidth, ClientHeight);
end;

procedure TGLPanel.Resize;
begin
  if FGL <> 0 then
  begin
    ResizeGL;
    InvalidateRect(Handle, nil, False);
  end;
  inherited;
end;

procedure TGLPanel.ResizeGL;
begin
  Project3D;
  Invalidate;
end;

procedure TGLPanel.WMEraseBkGnd(var Msg: TMessage);
begin
  if FGL <> 0 then
    Msg.Result := 1;
end;

procedure TGLPanel.WMPaint(var Msg: TMessage);
begin
  if FGL <> 0 then
  begin
    wglMakeCurrent(FDC, FGL);
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
    glLoadIdentity;
    if Assigned(FOnPaint) then
      FOnPaint(Self);
    glFlush();
    SwapBuffers(FDC);
    ValidateRect(Handle, nil);
  end else begin
    inherited;
  end;
end;

end.
