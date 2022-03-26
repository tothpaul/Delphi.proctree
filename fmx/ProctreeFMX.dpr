program ProctreeFMX;

uses
  System.StartUpCopy,
  FMX.Forms,
  ProctreeFMX.Main in 'ProctreeFMX.Main.pas' {Main},
  Execute.Tree3D in '..\lib\Execute.Tree3D.pas',
  Execute.TransparentTexture in '..\lib\Execute.TransparentTexture.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMain, Main);
  Application.Run;
end.
