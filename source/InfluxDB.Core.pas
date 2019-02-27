unit InfluxDB.Core;

interface

uses
  System.SysUtils,
  System.Classes,
  System.StrUtils,
  System.Net.HttpClient,
  System.Net.HttpClientComponent,
  System.NetEncoding,
  System.Generics.Collections;

type
  TRequestMethod = (GET, POST, PUT, DELETE, PATCH);

  TRequest = class abstract (TInterfacedObject)
  private
    FHeaders: TDictionary<String, String>;
    FQueryParams: TDictionary<String, String>;
    FMethod: TRequestMethod;
    FAccept: String;
    FContentType: String;
    FClient: TNetHTTPClient;
    FHttp: TNetHTTPRequest;
  protected
    function GetMethod: TRequestMethod;
    procedure SetMethod(const Value: TRequestMethod);
    function GetHeaders: TDictionary<String, String>;
    function GetQueryParams: TDictionary<String, String>;
    function EncodeQueryParams: String;
    function GetNetHTTPRequest: TNetHTTPRequest;
    procedure InitializeRequest; virtual;
    procedure BeforeExecute; virtual;

    function Execute(Command: TRequestMethod; Url: String; PostData: TStream = nil): IHTTPResponse; overload;
    function Execute(Url: String; PostData: TStream = nil): IHTTPResponse; overload;
  public
    constructor Create;
    destructor Destroy; override;

    function Get(Url: String): IHTTPResponse;
    function Delete(Url: String): IHTTPResponse;
    function Post(Url: String; Data: TStream): IHTTPResponse; overload;
    function Post(Url: String; Data: String): IHTTPResponse; overload;
    function Put(Url: String; Data: TStream): IHTTPResponse; overload;
    function Put(Url: String; Data: String): IHTTPResponse; overload;
    function Patch(Url: String; Data: TStream): IHTTPResponse; overload;
    function Patch(Url: String; Data: String): IHTTPResponse; overload;

    property Header: TDictionary<String, String> read GetHeaders;
    property QueryParams: TDictionary<String, String> read GetQueryParams;
    property Method: TRequestMethod read GetMethod write SetMethod;
    property Accept: String read FAccept write FAccept;
    property ContentType: String read FContentType write FContentType;
  end;

  const HTTP_USER_AGENT = 'InfluxDB Client 1.0';

implementation

{ TRequest }

procedure TRequest.BeforeExecute;
begin
  if not Assigned(FClient) then
    InitializeRequest;
end;

constructor TRequest.Create;
begin
  FHeaders := TDictionary<String, String>.Create;
  FQueryParams := TDictionary<String, String>.Create;
end;

function TRequest.Delete(Url: String): IHTTPResponse;
begin
  Result := Execute(TRequestMethod.DELETE, Url);
end;

destructor TRequest.Destroy;
begin
  FQueryParams.Free;
  FHeaders.Free;

  if Assigned(FClient) then
  begin
    FClient.Free;
    FHttp.Free;
  end;

  inherited;
end;

function TRequest.Execute(Command: TRequestMethod; Url: String; PostData: TStream): IHTTPResponse;
begin
  Self.Method := Command;
  Result := Execute(Url, PostData);
end;

function TRequest.EncodeQueryParams: String;
var
  Param: TPair<String, String>;
begin
  Result := '';
  for Param in QueryParams do
  begin
    if Result <> '' then
      Result := Result + '&';
    Result := Result + TNetEncoding.URL.Encode(Param.Key) + '=' + TNetEncoding.URL.Encode(Param.Value);
  end;
end;

procedure TRequest.InitializeRequest;
begin
  FClient := TNetHTTPClient.Create(nil);
  FHttp := TNetHTTPRequest.Create(nil);
  FHttp.Client := FClient;
  FClient.UserAgent := HTTP_USER_AGENT;
end;

function TRequest.Execute(Url: String; PostData: TStream = nil): IHTTPResponse;
var
  Param: TPair<String, String>;
begin
  BeforeExecute;

  FClient.ContentType := ContentType;
  FClient.Accept := Accept;

  for Param in Header do
    FHttp.CustomHeaders[Param.Key] := Param.Value;

  if QueryParams.Count > 0 then
    Url := Url + IfThen(Pos('?', Url) > 0, '&', '?') + EncodeQueryParams;

  case FMethod of
    TRequestMethod.GET: Result := FHttp.Get(Url);
    TRequestMethod.POST: Result := FHttp.Post(Url, PostData);
    TRequestMethod.PUT: Result := FHttp.Put(Url, PostData);
    TRequestMethod.DELETE: Result := FHttp.Delete(Url);
    TRequestMethod.PATCH: Result := FHttp.Patch(Url, PostData);
  end;
end;

function TRequest.GetNetHTTPRequest: TNetHTTPRequest;
begin
  Result := FHttp;
end;

function TRequest.Get(Url: String): IHTTPResponse;
begin
  Result := Execute(TRequestMethod.GET, Url);
end;

function TRequest.GetHeaders: TDictionary<String, String>;
begin
  Result := FHeaders;
end;

function TRequest.GetMethod: TRequestMethod;
begin
  Result := FMethod;
end;

function TRequest.GetQueryParams: TDictionary<String, String>;
begin
  Result := FQueryParams;
end;

function TRequest.Patch(Url: String; Data: TStream): IHTTPResponse;
begin
  Result := Execute(TRequestMethod.PATCH, Url, Data);
end;

function TRequest.Patch(Url, Data: String): IHTTPResponse;
var
  DataStream: TStringStream;
begin
  DataStream := TStringStream.Create(Data, TEncoding.UTF8);
  Result := Patch(Url, DataStream);
  DataStream.Free;
end;

function TRequest.Post(Url, Data: String): IHTTPResponse;
var
  DataStream: TStringStream;
begin
  DataStream := TStringStream.Create(Data, TEncoding.UTF8);
  Result := Post(Url, DataStream);
  DataStream.Free;
end;

function TRequest.Put(Url, Data: String): IHTTPResponse;
var
  DataStream: TStringStream;
begin
  DataStream := TStringStream.Create(Data, TEncoding.UTF8);
  Result := Put(Url, DataStream);
  DataStream.Free;
end;

function TRequest.Post(Url: String; Data: TStream): IHTTPResponse;
begin
  Result := Execute(TRequestMethod.POST, Url, Data);
end;

function TRequest.Put(Url: String; Data: TStream): IHTTPResponse;
begin
  Result := Execute(TRequestMethod.PUT, Url, Data);
end;

procedure TRequest.SetMethod(const Value: TRequestMethod);
begin
  FMethod := Value;
end;

end.
