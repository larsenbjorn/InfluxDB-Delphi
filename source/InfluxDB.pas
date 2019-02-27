unit InfluxDB;

interface

uses
  System.SysUtils,
  InfluxDB.Interfaces,
  InfluxDB.Request;

type

  TInfluxDB = class(TInfluxRequest, IInfluxDB)
  public
    constructor Create(AHost: String; APort: Integer);
    class function CreateClient(Host: String; Port: Integer): IInfluxDB;
  end;

implementation

{ TInfluxDBClient }

constructor TInfluxDB.Create(AHost: String; APort: Integer);
begin
  inherited Create;
  Self.Host := AHost;
  Self.Port := APort;
end;

class function TInfluxDB.CreateClient(Host: String; Port: Integer): IInfluxDB;
begin
  Result := TInfluxDB.Create(Host, Port);
end;

end.
