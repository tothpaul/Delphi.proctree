unit ProctreeVCL.Main;

interface
{.$DEFINE CLEAR}
uses
  Winapi.OpenGL, Winapi.OpenGLext,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Execute.GLPanel, Vcl.ComCtrls,
  Vcl.Imaging.jpeg, Vcl.Imaging.pngimage, Vcl.ExtCtrls, Vcl.StdCtrls, Execute.Tree3D;

type
  TGLMesh = record
    Buffers : array[0..1] of Integer;

    pVerts  : Pointer;
    pNormals: Pointer;
    pUV     : Pointer;

    pFaces  : Pointer;
    cFaces  : Integer;

    Texture : GLUInt;
    Transparent: Boolean;

    procedure Load(const Verts, Normals: TVertices; const UV: TTexCoords; const Faces: TFaces);
    procedure Render;
  end;

  TMain = class(TForm)
    GLPanel: TGLPanel;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    Label1: TLabel;
    Preset1: TImage;
    Image2: TImage;
    Image3: TImage;
    Image4: TImage;
    Image5: TImage;
    Image6: TImage;
    Image7: TImage;
    Image8: TImage;
    Image9: TImage;
    Image10: TImage;
    Label2: TLabel;
    TreeParam1: TTrackBar;
    Label3: TLabel;
    TreeParam2: TTrackBar;
    Label4: TLabel;
    TreeParam3: TTrackBar;
    Label5: TLabel;
    TreeParam4: TTrackBar;
    Label6: TLabel;
    TreeParam5: TTrackBar;
    BranchingParam2: TTrackBar;
    Label7: TLabel;
    Label8: TLabel;
    BranchingParam3: TTrackBar;
    Label9: TLabel;
    Label10: TLabel;
    BranchingParam5: TTrackBar;
    Label11: TLabel;
    BranchingParam4: TTrackBar;
    BranchingParam1: TTrackBar;
    Label12: TLabel;
    BranchingParam6: TTrackBar;
    Label13: TLabel;
    BranchingParam7: TTrackBar;
    Label14: TLabel;
    BranchingParam8: TTrackBar;
    Label15: TLabel;
    BranchingParam9: TTrackBar;
    TabSheet4: TTabSheet;
    TrunkParam1: TTrackBar;
    TrunkParam3: TTrackBar;
    TrunkParam4: TTrackBar;
    TrunkParam2: TTrackBar;
    TrunkParam5: TTrackBar;
    TrunkParam6: TTrackBar;
    TrunkParam7: TTrackBar;
    TrunkParam8: TTrackBar;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label20: TLabel;
    Label22: TLabel;
    Label23: TLabel;
    Label24: TLabel;
    TabSheet5: TTabSheet;
    Label21: TLabel;
    Image1: TImage;
    Image11: TImage;
    Image12: TImage;
    Image13: TImage;
    Label25: TLabel;
    Image14: TImage;
    Image15: TImage;
    Image16: TImage;
    Image17: TImage;
    Image18: TImage;
    Image19: TImage;
    StatusBar1: TStatusBar;
    procedure PresetClick(Sender: TObject);
    procedure TreeParamChange(Sender: TObject);
    procedure BranchingChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure GLPanelMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure TrunkChange(Sender: TObject);
    procedure TrunkMaterialClick(Sender: TObject);
    procedure TwigMaterialClick(Sender: TObject);
  private
    { Déclarations privées }
    Tree: TTree;
    TreeMesh: TGLMesh;
    TwigsMesh: TGLMesh;
    Mouse: TPoint;
    rx, ry, tz: Single;
    Trunks: array[0..3] of GLUint; // Trunk Textures
    Twigs: array[0..5] of GLUint; // Twigs Textures
    Floading: Boolean;
    procedure LoadTexture(ID: GLUint; Bitmap: TBitmap);
    procedure GLSetup(Sender: TObject);
    procedure GLPaint(Sender: TObject);
    procedure LoadTree(Trunk, Twig: Integer);
    procedure Reload;
  public
    { Déclarations publiques }
  end;

var
  Main: TMain;

implementation

{$R *.dfm}

procedure REVERT(P: Pointer; W, H, D: Integer);
var
  L1, L2: PByte;
  x, y, o: Integer;
  t: Byte;
begin
  L1 := P;
  L2 := P;
  Inc(L2, W * H * D);
  for y := 0 to (H div 2) - 1 do
  begin
    Dec(L2, W * D);
    o := 0;
    for x := 0 to W - 1 do
    begin
      t := L1[o + 0];
      L1[o + 0] := L2[o + 2];
      L2[o + 2] := t;

      t := L1[o + 2];
      L1[o + 2] := L2[o + 0];
      L2[o + 0] := t;

      t := L1[o + 1];
      L1[o + 1] := L2[o + 1];
      L2[o + 1] := t;

      if D = 4 then
      begin
        t := L1[o + 3];
        L1[o + 3] := L2[o + 3];
        L2[o + 3] := t;
      end;

      Inc(o, D);

    end;
    Inc(L1, W * D);
  end;
end;

procedure glTexImage2D(Target,level:integer; components,width,height:integer; border,format,DataType:integer; pixels:pointer); stdcall external opengl32;

procedure TMain.FormCreate(Sender: TObject);
begin
  GLPanel.OnSetup := GLSetup;
  GLPanel.OnPaint := GLPaint;
  TwigsMesh.Transparent := True;
end;

procedure TMain.GLPaint(Sender: TObject);
begin
  GLPanel.Project3D;

  glTranslatef(0, 0, tz - 20);
  glRotatef(20, 1, 0, 0);

  if rx<>0 then glRotatef(rx,1,0,0);
  if ry<>0 then glRotatef(ry,0,1,0);

  glTranslatef(0, -5, 0);

  glDepthMask(GL_FALSE);

  glColor3f(1, 1, 1);
  glBegin(GL_QUADS);
    glVertex3f(-50, 0, +50);
    glVertex3f(+50, 0, +50);
    glVertex3f(+50, 0, -50);
    glVertex3f(-50, 0, -50);
  glEnd();
  glColor3f(0.75, 0.75, 0.75);
  glBegin(GL_LINES);
    for var x := -25 to +25 do
    begin
      var s: Single := 2 * x;
      glVertex3f(s, 0, -50);
      glVertex3f(s, 0, +50);
      glVertex3f(-50, 0, s);
      glVertex3f(+50, 0, s);
    end;
  glEnd;

  glDepthMask(GL_TRUE);

  glScale(2, 2, 2);

  glEnable(GL_LIGHTING);
  glEnable(GL_LIGHT0);

  TreeMesh.Render;
  TwigsMesh.Render;

  glDisable(GL_LIGHTING);
end;

procedure TMain.GLPanelMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if ssLeft in Shift then
  begin
    ry := ry + (x - Mouse.X);
    rx := rx + (y - Mouse.Y);
    GLPanel.Invalidate;
  end;

  if ssRight in Shift then
  begin
    tz := tz + (y - Mouse.Y);
    GLPanel.Invalidate;
  end;

  Mouse.X := X;
  Mouse.Y := Y;
end;

procedure TMain.GLSetup(Sender: TObject);
begin
  var B := TBitmap.Create;
  try
    glGenTextures(4, @Trunks[0]);
    var J := TJPEGImage.Create;
    try
      for var I := 0 to 3 do
      begin
        var R := TResourceStream.Create(hInstance, 'TRUNK' + (I + 1).ToString, RT_RCDATA);
        try
          J.LoadFromStream(R);
          B.Assign(J);
          LoadTexture(Trunks[I], B);
        finally
          R.Free;
        end;
      end;
    finally
      J.Free;
    end;
    glGenTextures(6, @Twigs[0]);
    var P := TPNGImage.Create;
    for var I := 0 to 5 do
    begin
      var R := TResourceStream.Create(hInstance, 'TWIGS' + (I + 1).ToString, RT_RCDATA);
      try
        P.LoadFromStream(R);
        B.Assign(P);
        LoadTexture(Twigs[I], B);
      finally
        R.Free;
      end;
    end;
  finally
    B.Free;
  end;

  glEnable(GL_NORMALIZE);
  glEnable(GL_CULL_FACE);
  PresetClick(Preset1);
end;

procedure TMain.LoadTexture(ID: GLUint; Bitmap: TBitmap);
begin
  glBindTexture(GL_TEXTURE_2D, ID);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  var TEX: PCardinal := Bitmap.ScanLine[Bitmap.Height - 1];
  if Bitmap.PixelFormat = pf24Bit then
  begin
    REVERT(TEX, Bitmap.Width, Bitmap.Height, 3);
    glTexImage2D(GL_TEXTURE_2D, 0, 3, Bitmap.Width, Bitmap.Height, 0, GL_RGB, GL_UNSIGNED_BYTE, TEX);
  end else begin
    Assert(Bitmap.PixelFormat = pf32Bit);
    REVERT(TEX, Bitmap.Width, Bitmap.Height, 4);
    glTexImage2D(GL_TEXTURE_2D, 0, 4, Bitmap.Width, Bitmap.Height, 0, GL_RGBA, GL_UNSIGNED_BYTE, TEX);
  end;
end;

procedure TMain.LoadTree(Trunk, Twig: Integer);
begin
  TreeMesh.Texture := Trunks[Trunk];
  TwigsMesh.Texture := Twigs[Twig];
  Reload;

  FLoading := True;

  TreeParam1.Position := Tree.seed;
  TreeParam2.Position := Tree.segments div 2;
  TreeParam3.Position := Tree.levels;
  TreeParam4.Position := (Round(Tree.vMultiplier * 100) - 1) div 5;
  TreeParam5.Position := Round(Tree.twigScale * 100);

  BranchingParam1.Position := Round(Tree.initialBranchLength * 100);
  BranchingParam2.Position := Round(Tree.lengthFalloffFactor * 100);
  BranchingParam3.Position := Round(Tree.lengthFalloffPower * 100);
  BranchingParam4.Position := Round(Tree.clumpMax * 1000);
  BranchingParam5.Position := Round(Tree.clumpMin * 1000);
  BranchingParam6.Position := Round((Tree.branchFactor - 2) * 20);
  BranchingParam7.Position := Round(Tree.dropAmount * 100);
  BranchingParam8.Position := Round(Tree.growAmount * 1000);
  BranchingParam9.Position := Round(Tree.sweepAmount * 1000);

  TrunkParam1.Position := Round(Tree.maxRadius * 1000);
  TrunkParam2.Position := Round(Tree.climbRate * 1000);
  TrunkParam3.Position := Round(Tree.trunkKink * 1000);
  TrunkParam4.Position := Tree.treeSteps;
  TrunkParam5.Position := Round(Tree.taperRate * 1000);
  TrunkParam6.Position := Round(Tree.radiusFalloffRate * 100);
  TrunkParam7.Position := Round(Tree.twistRate * 100);
  TrunkParam8.Position := Round(Tree.trunkLength * 20);

  FLoading := False;
end;

procedure TMain.PresetClick(Sender: TObject);
begin
  case TControl(Sender).Tag of
    1:
    begin
      Tree.Preset1;
      LoadTree(0, 5);
    end;
    2:
    begin
      Tree.Preset2;
      LoadTree(1, 4);
    end;
    3:
    begin
      Tree.Preset3;
      LoadTree(2, 1);
    end;
    4:
    begin
      Tree.Preset4;
      LoadTree(2, 2);
    end;
    5:
    begin
      Tree.Preset5;
      LoadTree(2, 3);
    end;
    6:
    begin
      Tree.Preset6;
      LoadTree(1, 0);
    end;
    7:
    begin
      Tree.Preset7;
      LoadTree(0, 1);
    end;
    8:
    begin
      Tree.Preset8;
      LoadTree(0, 2);
    end;
  end;
end;

procedure TMain.Reload;
begin
  Tree.Build;

  TreeMesh.Load(Tree.verts, Tree.Normals, Tree.UV, Tree.Faces);
  TwigsMesh.Load(Tree.vertsTwig, Tree.normalsTwig, Tree.uvsTwig, Tree.facesTwig);

{$IFDEF CLEAR}
  Tree.Clear;
{$ENDIF}
  GLPanel.Invalidate;
end;

procedure TMain.BranchingChange(Sender: TObject);
begin
  if FLoading then
    Exit;
  Tree.initialBranchLength := Single(BranchingParam1.Position) * 0.01; // 0.10 .. 1.00, step 0.01
  Tree.lengthFalloffFactor := Single(BranchingParam2.Position) * 0.01; // 0.50 .. 1.00, step 0.01
  Tree.lengthFalloffPower := Single(BranchingParam3.Position) * 0.01; // 0.10 .. 1.50, step 0.01
  Tree.clumpMax := Single(BranchingParam4.Position) * 0.001; // 0..1, step 0.001
  Tree.clumpMin := Single(BranchingParam5.Position) * 0.001; // 0..1, step 0.001
  Tree.branchFactor := 2 + Single(BranchingParam6.Position) * 0.05; // 2..4, step 0.05
  Tree.dropAmount := Single(BranchingParam7.Position) * 0.01; // -1 .. +1, step 0.01
  Tree.growAmount := Single(BranchingParam8.Position) * 0.001; // -0.5 .. +1, step 0.001
  Tree.sweepAmount := Single(BranchingParam9.Position) * 0.001; // -1 .. +1, step 0.001
  Reload;
end;

procedure TMain.TreeParamChange(Sender: TObject);
begin
  if FLoading  then
    Exit;
  Tree.seed := TreeParam1.Position; // 1..1000
  Tree.segments := 2 * TreeParam2.Position; // 6..20, step 2
  Tree.levels := TreeParam3.Position; // 0..7
  Tree.vMultiplier := 0.01 + Single(TreeParam4.Position) * 0.05; // 0.01..10, step 0.05
  Tree.twigScale := Single(TreeParam5.Position) * 0.01; // 0..1, step 0.01
  Reload;
end;

procedure TMain.TrunkChange(Sender: TObject);
begin
  if FLoading then
    Exit;
  Tree.maxRadius := Single(TrunkParam1.Position) * 0.001;
  Tree.climbRate := Single(TrunkParam2.Position) * 0.001;
  Tree.trunkKink := Single(TrunkParam3.Position) * 0.001;
  Tree.treeSteps := TrunkParam4.Position;
  Tree.taperRate := Single(TrunkParam5.Position) * 0.001;
  Tree.radiusFalloffRate := Single(TrunkParam6.Position) * 0.01;
  Tree.twistRate := Single(TrunkParam7.Position) * 0.01;
  Tree.trunkLength := Single(TrunkParam8.Position) * 0.05;
  Reload;
end;

procedure TMain.TrunkMaterialClick(Sender: TObject);
begin
  TreeMesh.Texture := Trunks[TComponent(Sender).Tag];
  GLPanel.Invalidate;
end;

procedure TMain.TwigMaterialClick(Sender: TObject);
begin
  TwigsMesh.Texture := Twigs[TComponent(Sender).Tag];
  GLPanel.Invalidate;
end;

{ TGLMesh }

procedure TGLMesh.Load(const Verts, Normals: TVertices; const UV: TTexCoords;
  const Faces: TFaces);
begin
  if Buffers[0] = 0 then
  begin
    if @glGenBuffers = nil then
    begin
      Buffers[0] := -1;
      pVerts := Pointer(Verts);
      pNormals := Pointer(Normals);
      pUV := Pointer(UV);
      pFaces := Pointer(Faces);
      cFaces := 3 * Length(Faces);
      Exit;
    end;
    glGenBuffers(2, @Buffers);
  end;

  var lVerts := Length(Verts) * SizeOf(TVertex);
  var lNormals := Length(Normals) * SizeOf(TVertex);
  var lUV := Length(UV) * SizeOf(TTexCoord);
  var lFaces := Length(Faces) * SizeOf(TFace);

  pVerts := nil;
  pNormals := Pointer(lVerts);
  pUV := Pointer(lVerts + lNormals);

// Allocate a single buffer for all the data
  glBindBuffer(GL_ARRAY_BUFFER, Buffers[0]);
  glBufferData(GL_ARRAY_BUFFER, lVerts + lNormals + lUV, nil, GL_STATIC_DRAW);

// fill sub data
  glBufferSubData(GL_ARRAY_BUFFER, NativeInt(pVerts), lVerts, Verts);
  glBufferSubData(GL_ARRAY_BUFFER, NativeInt(pNormals), lNormals, Normals);
  glBufferSubData(GL_ARRAY_BUFFER, NativeInt(pUV), lUV, UV);

// Indices buffer
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, Buffers[1]);
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, lFaces, Faces, GL_STATIC_DRAW);

  pFaces := nil;
  cFaces := 3 * Length(Faces);
end;

procedure TGLMesh.Render;
begin
  if Buffers[0] <> -1 then
  begin
    glBindBuffer(GL_ARRAY_BUFFER, Buffers[0]);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, Buffers[1]);
    glEnableClientState(GL_INDEX_ARRAY);
  end;

  glVertexPointer(3, GL_FLOAT, SizeOf(TVertex), pVerts);
  glNormalPointer(GL_FLOAT, SizeOf(TVertex), pNormals);
  glTexCoordPointer(2, GL_FLOAT, SizeOf(TTexCoord), pUV);

  glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientState(GL_NORMAL_ARRAY);
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);

  glEnable(GL_TEXTURE_2D);
  glBindTexture(GL_TEXTURE_2D, Texture);

  if Transparent then
  begin
    glAlphaFunc(GL_GREATER, 0.5);
    glEnable(GL_ALPHA_TEST);
  end else begin
    glDisable(GL_ALPHA_TEST);
  end;

  glDrawElements(GL_TRIANGLES, cFaces, GL_UNSIGNED_INT, pFaces);

  glDisable(GL_TEXTURE_2D);

  glDisableClientState(GL_VERTEX_ARRAY);
  glDisableClientState(GL_NORMAL_ARRAY);
  glDisableClientState(GL_TEXTURE_COORD_ARRAY);
  glDisableClientState(GL_INDEX_ARRAY);
end;

end.
