program InfluxDBDemo;

uses
  FastMM4,
  Vcl.Forms,
  Demo.Main in 'Demo.Main.pas' {frmMain},
  InfluxDB.Core in '..\source\InfluxDB.Core.pas',
  InfluxDB in '..\source\InfluxDB.pas',
  InfluxDB.Request in '..\source\InfluxDB.Request.pas',
  InfluxDB.Interfaces in '..\source\InfluxDB.Interfaces.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
