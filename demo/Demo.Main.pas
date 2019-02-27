unit Demo.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
    System.Net.HttpClient;

type
  TfrmMain = class(TForm)
    Button1: TButton;
    Memo1: TMemo;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

uses
  InfluxDB, InfluxDB.Interfaces, System.Diagnostics, System.TimeSpan, System.Threading;

{$R *.dfm}

procedure TfrmMain.Button1Click(Sender: TObject);
var
  Influx: IInfluxDB;
begin
  Influx := TInfluxDB.CreateClient('localhost', 8086);
  Influx.CreateDatabase('MyDB', 1, duWeek);
end;

procedure TfrmMain.Button2Click(Sender: TObject);
var
  Influx: IInfluxDB;
begin
  Influx := TInfluxDB.CreateClient('localhost', 8086);
  Memo1.Lines.AddStrings(Influx.ShowDatabases);
end;

procedure TfrmMain.Button3Click(Sender: TObject);
var
  Influx: IInfluxDB;
begin
  Influx := TInfluxDB.CreateClient('localhost', 8086);
  if Influx.Write('TestDB', 'bucket,id=ABC temp=45') then
    ShowMessage('1. Data written to DB');
end;

procedure TfrmMain.Button4Click(Sender: TObject);
var
  Influx: IInfluxDB;
  Val: TInfluxValue;
begin
  Influx := TInfluxDB.CreateClient('localhost', 8086);
  Val := TInfluxValue.Create('MyMeasurement', Now);
  Val.AddField('temp', 77);
  Val.AddField('value', 77);
  Val.AddTag('id', '5498');
  if Influx.Write('TestDB', Val) then
    ShowMessage('2. Data written to DB');
end;

procedure TfrmMain.Button5Click(Sender: TObject);
var
  Influx: IInfluxDB;
  Stopwatch: TStopwatch;
  Elapsed: TTimeSpan;
  I: Integer;
begin
  Stopwatch := TStopwatch.StartNew;

  Influx := TInfluxDB.CreateClient('localhost', 8086);

  for I := 0 to 1000 do
  begin
    Influx.Write('TestDB', 'temp temp=' + Random(200).ToString);
  end;

  Elapsed := Stopwatch.Elapsed;
  ShowMessage(Elapsed.TotalSeconds.ToString);
end;

procedure TfrmMain.Button6Click(Sender: TObject);
var
  Influx: IInfluxDB;
begin
  Influx := TInfluxDB.CreateClient('localhost', 8086);
  Memo1.Lines.Text := Influx.ServerVersion;
end;

end.
