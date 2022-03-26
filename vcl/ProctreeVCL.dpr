program ProctreeVCL;

{$R *.dres}

uses
  Vcl.Forms,
  ProctreeVCL.Main in 'ProctreeVCL.Main.pas' {Main},
  Execute.GLPanel in '..\lib\Execute.GLPanel.pas' {GLPanel: TFrame},
  Execute.Tree3D in '..\lib\Execute.Tree3D.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMain, Main);
  Application.Run;
end.
