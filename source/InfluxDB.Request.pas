unit InfluxDB.Request;

interface

uses
  System.SysUtils,
  System.Net.HttpClient,
  System.NetEncoding,
  System.Generics.Collections,
  System.JSON,
  System.Variants,
  System.RTTI,
  InfluxDB.Core,
  InfluxDB.Interfaces,
  System.DateUtils;

type

  TInfluxResult = class(TInterfacedObject, IInfluxResult)
  private
    FResponse: IHTTPResponse;
    FResult: TArray<TResultStatement>;
  protected
    procedure ParseResponse(Response: IHTTPResponse);
    function GetHTTPResponse: IHTTPResponse;
    function GetResult: TArray<TResultStatement>;
  public
    property Response: IHTTPResponse read GetHTTPResponse;
    property Result: TArray<TResultStatement> read GetResult;
    function GetNameValues: TArray<String>;
    class function CreateResult: IInfluxResult; overload;
    class function CreateResult(Response: IHTTPResponse): IInfluxResult; overload;
  end;

  TInfluxRequest = class(TRequest, IInfluxRequest)
  private
    FPort: Integer;
    FHost: String;
  protected
    function EndPoint: String;
  public
    property Host: String read FHost write FHost;
    property Port: Integer read FPort write FPort;

    function CreateDatabase(DatabaseName: String; Duration: Integer; DurationUnit: TDurationUnit = duDay): Boolean; overload;
    function CreateDatabase(DatabaseName: String; Duration: Integer; out Response: IHTTPResponse; DurationUnit: TDurationUnit = duDay): Boolean; overload;

    function ShowDatabases: TArray<String>;
    function ShowMeasurements(Database: String): TArray<String>;
    function ServerVersion: String;

    function Query(Database: String; QueryString: String): IInfluxResult;

    function Write(Database: String; ValueString: String): Boolean; overload;
    function Write(Database: String; ValueString: String; out Response: IHTTPResponse): Boolean; overload;
    function Write(Database: String; Value: TInfluxValue): Boolean; overload;
    function Write(Database: String; Value: TInfluxValue; out Response: IHTTPResponse): Boolean; overload;
  end;

implementation

{ TInfluxDBRequest }

function TInfluxRequest.CreateDatabase(DatabaseName: String; Duration: Integer; DurationUnit: TDurationUnit = duDay): Boolean;
var
  LResp: IHTTPResponse;
begin
  Result := CreateDatabase(DatabaseName, Duration, LResp, DurationUnit);
end;

function TInfluxRequest.CreateDatabase(DatabaseName: String; Duration: Integer; out Response: IHTTPResponse;
  DurationUnit: TDurationUnit = duDay): Boolean;
var
  LUrl, LStmt: String;
  LUnit: String;
begin
  LUrl := EndPoint + '/query';

  case DurationUnit of
    duWeek: LUnit := 'w';
    duDay: LUnit := 'd';
    duHour: LUnit := 'h';
    duMinute: LUnit := 'm';
    else
      LUnit := 'd';
  end;

  LStmt := 'CREATE DATABASE ' + DatabaseName.QuotedString('"') +
          ' WITH DURATION ' + Duration.ToString + LUnit +
          ' REPLICATION 1';
  QueryParams.AddOrSetValue('q', LStmt);
  Response := Post(LUrl, '');
  Result := Response.StatusCode = 200;
end;

function TInfluxRequest.EndPoint: String;
begin
  Result := 'http://' + Host + ':' + Port.ToString;
end;

function TInfluxRequest.Query(Database, QueryString: String): IInfluxResult;
var
  LUrl: String;
  LResp: IHTTPResponse;
begin
  LUrl := EndPoint + '/query';
  QueryParams.AddOrSetValue('db', Database);
  QueryParams.AddOrSetValue('q', QueryString);
  LResp := Get(LUrl);
  Result := TInfluxResult.CreateResult(LResp);
end;

function TInfluxRequest.Write(Database, ValueString: String): Boolean;
var
  LResp: IHTTPResponse;
begin
  Result := Write(Database, ValueString, LResp);
end;

function TInfluxRequest.Write(Database: String; Value: TInfluxValue): Boolean;
var
  LResp: IHTTPResponse;
begin
  Result := Write(Database, Value, LResp);
end;

function TInfluxRequest.ServerVersion: String;
var
  LUrl: String;
  LResp: IHTTPResponse;
  LObj: TJSONObject;
  LVal: TJSONValue;
begin
  Result := '';

  LUrl := EndPoint + '/ping';
  QueryParams.AddOrSetValue('verbose', 'true');
  LResp := Get(LUrl);

  if LResp.StatusCode = 200 then
  begin
    LObj := TJSONObject.ParseJSONValue(LResp.ContentAsString(TEncoding.UTF8)) as TJSONObject;
    if LObj <> nil then
    begin
      if LObj.TryGetValue('version', LVal) then
        Result := LVal.Value;
      LObj.Free;
    end;
  end;
end;

function TInfluxRequest.ShowDatabases: TArray<String>;
var
  LUrl, LStmt: String;
  LResp: IHTTPResponse;
  LResult: IInfluxResult;
begin
  LUrl := EndPoint + '/query';
  LStmt := 'SHOW DATABASES';
  Self.QueryParams.AddOrSetValue('q', LStmt);
  LResp := Self.Get(LUrl);

  SetLength(Result, 0);
  if LResp.StatusCode = 200 then
  begin
    LResult := TInfluxResult.CreateResult(LResp);
    Result := LResult.GetNameValues;
  end;
end;

function TInfluxRequest.ShowMeasurements(Database: String): TArray<String>;
var
  LUrl, LStmt: String;
  LResp: IHTTPResponse;
  LResult: IInfluxResult;
begin
  LUrl := EndPoint + '/query';
  LStmt := 'SHOW MEASUREMENTS ON ' + Database;
  Self.QueryParams.AddOrSetValue('q', LStmt);
  LResp := Self.Get(LUrl);

  SetLength(Result, 0);
  if LResp.StatusCode = 200 then
  begin
    LResult := TInfluxResult.CreateResult(LResp);
    Result := LResult.GetNameValues;
  end;
end;

function TInfluxRequest.Write(Database: String; Value: TInfluxValue; out Response: IHTTPResponse): Boolean;
begin
  if Value.TimeStamp > 0 then
    QueryParams.AddOrSetValue('precision', 's');
  Result := Write(Database, Value.AsString, Response);
end;

function TInfluxRequest.Write(Database, ValueString: String; out Response: IHTTPResponse): Boolean;
var
  LUrl: String;
begin
  LUrl := EndPoint + '/write';
  QueryParams.AddOrSetValue('db', Database);
  Response := Post(LUrl, ValueString);
  Result := (Response.StatusCode = 204);
end;

{ TInfluxResult }

class function TInfluxResult.CreateResult: IInfluxResult;
begin
  Result := TInfluxResult.Create;
end;

class function TInfluxResult.CreateResult(Response: IHTTPResponse): IInfluxResult;
var
  R: TInfluxResult;
begin
  R := TInfluxResult.Create;
  R.ParseResponse(Response);
  Result := R;
end;

function TInfluxResult.GetHTTPResponse: IHTTPResponse;
begin
  Result := FResponse;
end;

function TInfluxResult.GetNameValues: TArray<String>;
var
  LObj: TJSONObject;
  LVal: TJSONValue;
  LArr: TJSONArray;
  I: Integer;
begin
  LObj := TJSONObject.ParseJSONValue(FResponse.ContentAsString(TEncoding.UTF8)) as TJSONObject;
  if LObj.TryGetValue('results', LArr) then
  begin
    LVal := LArr.Items[0];
    if TJSONObject(LVal).TryGetValue('series', LArr) then
    begin
      LVal := LArr.Items[0];
      if TJSONObject(LVal).TryGetValue('values', LArr) then
      begin
        SetLength(Result, LArr.Count);
        for I := 0 to LArr.Count -1 do
          Result[I] := TJSONArray(LArr.Items[I]).Items[0].Value;
      end;
    end;
  end;
  LObj.Free;
end;

function TInfluxResult.GetResult: TArray<TResultStatement>;
begin
  ParseResponse(FResponse);
  Result := FResult;
end;

procedure TInfluxResult.ParseResponse(Response: IHTTPResponse);
var
  LObj: TJSONObject;
  LStArr, LSerArr, LValArr, LFieldArr: TJSONArray;
  I, J, K, L, Cols: Integer;
begin
  FResponse := Response;
  SetLength(FResult, 0);
  Cols := 0;

  LObj := TJSONObject.ParseJSONValue(FResponse.ContentAsString(TEncoding.UTF8)) as TJSONObject;
  if LObj <> nil then
  begin
    if LObj.TryGetValue('results', LStArr) then
    begin
      SetLength(FResult, LStArr.Count);
      for I := 0 to LStArr.Count -1 do
      begin
        FResult[I].Id := LStArr.Items[I].GetValue<Integer>('statement_id', -1);
        LSerArr := LStArr.Items[I].GetValue<TJSONArray>('series', nil);

        if LSerArr <> nil then
        begin
          SetLength(FResult[I].Series, LSerArr.Count);
          for J := 0 to LSerArr.Count -1 do
          begin
            FResult[I].Series[J] := TResultSerie.Create;
            FResult[I].Series[J].Name := LSerArr.Items[J].P['name'].Value;

            LValArr := LSerArr.Items[J].GetValue<TJSONArray>('columns', nil);
            if LValArr <> nil then
            begin
              Cols := LValArr.Count;
              SetLength(FResult[I].Series[J].Columns, Cols);
              for K := 0 to LValArr.Count -1 do
                FResult[I].Series[J].Columns[K] := LValArr.Items[K].Value;
            end;

            LValArr := LSerArr.Items[J].GetValue<TJSONArray>('values', nil);
            if LValArr <> nil then
            begin
              SetLength(FResult[I].Series[J].Values, LValArr.Count);
              for K := 0 to LValArr.Count -1 do
              begin
                LFieldArr := LValArr.Items[K].GetValue<TJSONArray>();
                if LFieldArr <> nil then
                begin
                  SetLength(FResult[I].Series[J].Values[K].Columns, Cols);
                  for L := 0 to Cols -1 do
                  begin
                    FResult[I].Series[J].Values[K].Columns[L].Key := FResult[I].Series[J].Columns[L];

                    if FResult[I].Series[J].Columns[L] = 'time' then
                      FResult[I].Series[J].Values[K].Columns[L].Value := TValue.From<TDateTime>(System.DateUtils.ISO8601ToDate(LFieldArr.Items[L].Value))
                    else
                    begin
                      if LFieldArr.Items[L] is TJSONString then
                        FResult[I].Series[J].Values[K].Columns[L].Value := TValue.From<String>(LFieldArr.Items[L].Value)
                      else if LFieldArr.Items[L] is TJSONNull then
                        FResult[I].Series[J].Values[K].Columns[L].Value := TValue.FromVariant(null)
                      else if LFieldArr.Items[L] is TJSONNumber then
                        FResult[I].Series[J].Values[K].Columns[L].Value := TValue.From<Double>(LFieldArr.Items[L].GetValue<Double>)
                      else if LFieldArr.Items[L] is TJSONTrue then
                        FResult[I].Series[J].Values[K].Columns[L].Value := TValue.From<Boolean>(True)
                      else if LFieldArr.Items[L] is TJSONFalse then
                        FResult[I].Series[J].Values[K].Columns[L].Value := TValue.From<Boolean>(False);
                    end;
                  end;
                end;
              end;
            end;
          end;

        end;
      end;
    end;

    LObj.Free;
  end;
end;

end.
