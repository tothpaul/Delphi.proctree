unit ProctreeFMX.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Math,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Viewport3D,
  System.Math.Vectors, FMX.Controls3D, FMX.Objects3D, Execute.Tree3D,
  FMX.Materials, FMX.MaterialSources, FMX.Types3D, FMX.Effects, FMX.Objects,
  FMX.Layouts, FMX.TabControl, FMX.Controls.Presentation, FMX.StdCtrls,
  Execute.TransparentTexture;

type
  TMain = class(TForm)
    Viewport3D1: TViewport3D;
    Dummy1: TDummy;
    Trunk0: TLightMaterialSource;
    Light1: TLight;
    Twig0: TLightMaterialSource;
    Dummy2: TDummy;
    Grid3D1: TGrid3D;
    BlurEffect1: TBlurEffect;
    Dummy3: TDummy;
    Twig1: TLightMaterialSource;
    Twig2: TLightMaterialSource;
    Twig3: TLightMaterialSource;
    Twig5: TLightMaterialSource;
    Twig4: TLightMaterialSource;
    Trunk1: TLightMaterialSource;
    Trunk2: TLightMaterialSource;
    Trunk3: TLightMaterialSource;
    lbTrunkMaterial: TText;
    Layout5: TLayout;
    TrunkMaterial1: TImage;
    TrunkMaterial2: TImage;
    TrunkMaterial3: TImage;
    TrunkMaterial4: TImage;
    lbTwigMaterial: TText;
    TwigMaterial1: TImage;
    TwigMaterial2: TImage;
    TwigMaterial4: TImage;
    TwigMaterial3: TImage;
    TwigMaterial6: TImage;
    TwigMaterial5: TImage;
    ButtonsLayout: TLayout;
    Rectangle1: TRectangle;
    txButton0: TText;
    rtButton0: TRectangle;
    rtButton5: TRectangle;
    txButton5: TText;
    Layouts: TLayout;
    Layout0: TLayout;
    lbPresets: TText;
    Preset1: TImage;
    Preset2: TImage;
    Preset3: TImage;
    Preset4: TImage;
    Preset5: TImage;
    Preset6: TImage;
    Preset7: TImage;
    Preset8: TImage;
    Dummy0: TDummy;
    Layout2: TLayout;
    rtButton2: TRectangle;
    txButton2: TText;
    Text1: TText;
    TrackBar1: TTrackBar;
    Text2: TText;
    TrackBar2: TTrackBar;
    Text3: TText;
    TrackBar3: TTrackBar;
    Text4: TText;
    TrackBar4: TTrackBar;
    Text5: TText;
    TrackBar5: TTrackBar;
    Layout3: TLayout;
    Text6: TText;
    Branching1: TTrackBar;
    Text7: TText;
    Branching2: TTrackBar;
    Text8: TText;
    Branching3: TTrackBar;
    Text9: TText;
    Branching4: TTrackBar;
    Text10: TText;
    Branching5: TTrackBar;
    Text11: TText;
    Branching6: TTrackBar;
    Text12: TText;
    Branching7: TTrackBar;
    Text13: TText;
    Branching8: TTrackBar;
    Text14: TText;
    Branching9: TTrackBar;
    rtButton3: TRectangle;
    txButton3: TText;
    rtButton4: TRectangle;
    txButton4: TText;
    Layout4: TLayout;
    Text15: TText;
    pTrunk1: TTrackBar;
    Text16: TText;
    pTrunk2: TTrackBar;
    Text17: TText;
    pTrunk3: TTrackBar;
    Text18: TText;
    pTrunk4: TTrackBar;
    Text19: TText;
    pTrunk5: TTrackBar;
    Text20: TText;
    pTrunk6: TTrackBar;
    Text21: TText;
    pTrunk7: TTrackBar;
    Text22: TText;
    pTrunk8: TTrackBar;
    Text23: TText;
    procedure FormCreate(Sender: TObject);
    procedure Viewport3D1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure Viewport3D1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Single);
    procedure Viewport3D1MouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; var Handled: Boolean);
    procedure TrunkClick(Sender: TObject);
    procedure TwigMaterial1Click(Sender: TObject);
    procedure PresetClick(Sender: TObject);
    procedure rtButton0Click(Sender: TObject);
    procedure TreeChange(Sender: TObject);
    procedure BranchChange(Sender: TObject);
    procedure pTrunkChange(Sender: TObject);
  private
    { Déclarations privées }
    Tree: TTree;
    TreeMesh: TMesh;
    TwigsMesh: TMesh;
    Down: TPointF;
    RY, RX: Single;
    FLoading: Boolean;
    procedure LoadTree(Trunk, Twigs: TMaterialSource);
    procedure Reload;
    procedure LoadMesh(Mesh: TMesh; const Verts, Normals: TVertices; const UV: TTexCoords; const Faces: TFaces);
  public
    { Déclarations publiques }
  end;

var
  Main: TMain;

implementation

{$R *.fmx}

function clamp(s: Single): Single;
begin
  while s > 1 do
    s := s - 1;
  Result := s;
end;

procedure TMain.BranchChange(Sender: TObject);
begin
  if FLoading then
    Exit;
  Tree.initialBranchLength := Branching1.Value;
  Tree.lengthFalloffFactor := Branching2.Value;
  Tree.lengthFalloffPower := Branching3.Value;
  Tree.clumpMax := Branching4.Value;
  Tree.clumpMin := Branching5.Value;
  Tree.branchFactor := Branching6.Value;
  Tree.dropAmount := Branching7.Value;
  Tree.growAmount := Branching8.Value;
  Tree.sweepAmount := Branching9.Value;
  Reload;
end;

procedure TMain.FormCreate(Sender: TObject);
begin
  TreeMesh := TMesh.Create(Self);
  TreeMesh.Parent := Dummy3;
  TreeMesh.WrapMode := TMeshWrapMode.Original;
  TreeMesh.HitTest := False;

  TwigsMesh := TMesh.Create(Self);
  TwigsMesh.Parent := Dummy2;
  TwigsMesh.WrapMode := TMeshWrapMode.Original;
  TwigsMesh.HitTest := False;

  PresetClick(Preset1);
end;

procedure TMain.TreeChange(Sender: TObject);
begin
  if FLoading then
    Exit;
  Tree.seed := Round(TrackBar1.Value);
  Tree.segments := Round(TrackBar2.Value);
  Tree.levels := Round(TrackBar3.Value);
  Tree.vMultiplier := TrackBar4.Value;
  Tree.twigScale := TrackBar5.Value;
  Reload;
end;

procedure TMain.TrunkClick(Sender: TObject);
begin
  TreeMesh.MaterialSource := FindComponent('Trunk' + TControl(Sender).Tag.ToString) as TMaterialSource;
  ViewPort3D1.Repaint;
end;

procedure TMain.PresetClick(Sender: TObject);
begin
  case TControl(Sender).Tag of
    1:
    begin
      Tree.Preset1;
      LoadTree(Trunk0, Twig5);
    end;
    2:
    begin
      Tree.Preset2;
      LoadTree(Trunk1, Twig4);
    end;
    3:
    begin
      Tree.Preset3;
      LoadTree(Trunk2, Twig1);
    end;
    4:
    begin
      Tree.Preset4;
      LoadTree(Trunk2, Twig2);
    end;
    5:
    begin
      Tree.Preset5;
      LoadTree(Trunk2, Twig3);
    end;
    6:
    begin
      Tree.Preset6;
      LoadTree(Trunk1, Twig0);
    end;
    7:
    begin
      Tree.Preset7;
      LoadTree(Trunk0, Twig1);
    end;
    8:
    begin
      Tree.Preset8;
      LoadTree(Trunk0, Twig2);
    end;
  end;
  FLoading := True;

  TrackBar1.Value := Tree.seed;
  TrackBar2.Value := Tree.segments;
  TrackBar3.Value := Tree.levels;
  TrackBar4.Value := Tree.vMultiplier;
  TrackBar5.Value := Tree.twigScale;

  Branching1.Value := Tree.initialBranchLength;
  Branching2.Value := Tree.lengthFalloffFactor;
  Branching3.Value := Tree.lengthFalloffPower;
  Branching4.Value := Tree.clumpMax;
  Branching5.Value := Tree.clumpMin;
  Branching6.Value := Tree.branchFactor;
  Branching7.Value := Tree.dropAmount;
  Branching8.Value := Tree.growAmount;
  Branching9.Value := Tree.sweepAmount;

  pTrunk1.Value := Tree.maxRadius;
  pTrunk2.Value := Tree.climbRate;
  pTrunk3.Value := Tree.trunkKink;
  pTrunk4.Value := Tree.treeSteps;
  pTrunk5.Value := Tree.taperRate;
  pTrunk6.Value := Tree.radiusFalloffRate;
  pTrunk7.Value := Tree.twistRate;
  pTrunk8.Value := Tree.trunkLength;

  FLoading := False;

  ViewPort3D1.Repaint;
end;

procedure TMain.pTrunkChange(Sender: TObject);
begin
  if FLoading then
    Exit;
  Tree.maxRadius := pTrunk1.Value;
  Tree.climbRate := pTrunk2.Value;
  Tree.trunkKink := pTrunk3.Value;
  Tree.treeSteps := Round(pTrunk4.Value);
  Tree.taperRate := pTrunk5.Value;
  Tree.radiusFalloffRate := pTrunk6.Value;
  Tree.twistRate := pTrunk7.Value;
  Tree.trunkLength := pTrunk8.Value;
  Reload;
end;

procedure TMain.rtButton0Click(Sender: TObject);
begin
  var tag := TControl(Sender).Tag;
  for var I := 0 to 5 do
  begin
    var rt := FindComponent('rtButton' + I.ToString);
    if rt <> nil then
    begin
      if I = tag then
      begin
        (rt as TRectangle).Fill.Color := TAlphaColorRec.White;
        (TRectangle(rt).Children[0] as TText).TextSettings.FontColor := $FF51C9AF;
        (FindComponent('Layout' + I.ToString) as TLayout).Visible := True;
      end else begin
        (rt as TRectangle).Fill.Color := $FFFAFAFA;
        (TRectangle(rt).Children[0] as TText).TextSettings.FontColor := TAlphaColorRec.Black;
        (FindComponent('Layout' + I.ToString) as TLayout).Visible := False;
      end;
    end;
  end;
end;

procedure TMain.TwigMaterial1Click(Sender: TObject);
begin
  TwigsMesh.MaterialSource := FindComponent('Twig' + TControl(Sender).Tag.ToString) as TMaterialSource;
  ViewPort3D1.Repaint;
end;

procedure TMain.LoadMesh(Mesh: TMesh; const Verts, Normals: TVertices;
  const UV: TTexCoords; const Faces: TFaces);
begin
  Mesh.Data.VertexBuffer.Length := Length(Verts);
  Mesh.Data.IndexBuffer.Length := 3 * Length(Faces);
  for var I := 0 to Length(Verts) - 1 do
  begin
    with Verts[I] do
     Mesh.Data.VertexBuffer.Vertices[i] := TPoint3D.Create(x, -y, z);
    with Normals[I] do
     Mesh.Data.VertexBuffer.Normals[i] := TPoint3D.Create(x, -y, z);
    with UV[I] do
     Mesh.Data.VertexBuffer.TexCoord0[i] := TPointF.Create(u, v);
  end;
  for var I := 0 to Length(Faces) - 1 do
  begin
    with Faces[I] do
    begin
      Mesh.Data.IndexBuffer[3 * I + 0] := a;
      Mesh.Data.IndexBuffer[3 * I + 1] := b;
      Mesh.Data.IndexBuffer[3 * I + 2] := c;
    end;
  end;
end;

procedure TMain.LoadTree(Trunk, Twigs: TMaterialSource);
begin
  TreeMesh.MaterialSource := Trunk;
  TwigsMesh.MaterialSource := Twigs;
  Reload;
end;

procedure TMain.Reload;
begin
  Tree.Build;
  LoadMesh(TreeMesh, Tree.verts, Tree.Normals, Tree.UV, Tree.Faces);
  LoadMesh(TwigsMesh, Tree.vertsTwig, Tree.normalsTwig, Tree.uvsTwig, Tree.facesTwig);
  Tree.Clear;
  ViewPort3D1.Repaint;
end;

procedure TMain.Viewport3D1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  Down.X := X;
  Down.Y := Y;
  RY := Dummy2.RotationAngle.Y;
  RX := Dummy1.RotationAngle.X;
end;

procedure TMain.Viewport3D1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Single);
begin
  if ssLeft in Shift then
  begin
    Dummy1.RotationAngle.X := RX + (Y - Down.Y) * 200 / ClientHeight;
    Dummy2.RotationAngle.Y := RY + (Down.X - X) * 200 / ClientWidth;
  end;
end;

procedure TMain.Viewport3D1MouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; var Handled: Boolean);
begin
  Dummy2.Position.Z := Dummy2.Position.Z - WheelDelta / 100;
end;

end.
