unit InfluxDB.Interfaces;

interface

uses
  System.SysUtils,
  System.StrUtils,
  System.DateUtils,
  System.RTTI,
  System.Net.HttpClient,
  System.Generics.Collections;

type

  TDurationUnit = (duWeek, duDay, duHour, duMinute, duSecond, duMillisecond, duMicrosecond, duNanosecond);

  TResultRecord = record
    Columns: TArray<TPair<String, TValue>>;
    function Count: Integer;
  end;

  TResultSerie = class
    Name: String;
    Columns: TArray<String>;
    Values: TArray<TResultRecord>;
    function Count: Integer;
    constructor Create;
  end;

  TResultStatement = record
    Id: Integer;
    Series: TArray<TResultSerie>;
  end;

  TInfluxValue = record
    Measurement: String;
    Tags: TArray<TPair<String, String>>;
    Fields: TArray<TPair<String, TValue>>;
    TimeStamp: TDateTime;
    constructor Create(AMeasurement: String; ATimeStamp: TDateTime = 0);
    function AddField(AField: String; AValue: TValue): Integer;
    function AddTag(ATag, AValue: String): Integer;
    function AsString: String;
  end;

  IInfluxResult = interface
    ['{84DFCBCF-00B9-4ECD-965E-92478C943439}']
    function GetHTTPResponse: IHTTPResponse;
    function GetResult: TArray<TResultStatement>;
    function GetNameValues: TArray<String>;
    property Response: IHTTPResponse read GetHTTPResponse;
    property Result: TArray<TResultStatement> read GetResult;
  end;

  IInfluxRequest = interface
    ['{7F42EF85-6B16-4014-A486-A4C0F60C482B}']
    function CreateDatabase(DatabaseName: String; Duration: Integer; DurationUnit: TDurationUnit = duDay): Boolean; overload;
    function CreateDatabase(DatabaseName: String; Duration: Integer; out Response: IHTTPResponse; DurationUnit: TDurationUnit = duDay): Boolean; overload;

    function ShowDatabases: TArray<String>;
    function ShowMeasurements(Database: String): TArray<String>;
    function ServerVersion: String;

    function Query(Database: String; QueryString: String): IInfluxResult; overload;

    function Write(Database: String; ValueString: String): Boolean; overload;
    function Write(Database: String; ValueString: String; out Response: IHTTPResponse): Boolean; overload;
    function Write(Database: String; Value: TInfluxValue): Boolean; overload;
    function Write(Database: String; Value: TInfluxValue; out Response: IHTTPResponse): Boolean; overload;
  end;

  IInfluxDB = interface(IInfluxRequest)
    ['{15BD87B7-CFAD-47DF-BCD7-DC5DA8D61ECC}']
  end;

implementation

{ TInfluxDBValue }

function TInfluxValue.AddField(AField: String; AValue: TValue): Integer;
var
  Val: TPair<String, TValue>;
begin
  Val.Key := AField;
  Val.Value := AValue;

  Result := Length(Fields);
  SetLength(Fields, Result +1);
  Fields[Result] := Val;
end;

function TInfluxValue.AddTag(ATag, AValue: String): Integer;
var
  Val: TPair<String, String>;
begin
  Val.Key := ATag;
  Val.Value := AValue;

  Result := Length(Tags);
  SetLength(Tags, Result +1);
  Tags[Result] := Val;
end;

function TInfluxValue.AsString: String;
var
  ATag: TPair<String, String>;
  AField: TPair<String, TValue>;
  Val, S: String;
begin
  Result := Measurement;
  for ATag in Tags do
    Result := Result + ',' + ATag.Key + '=' + ATag.Value;

  Result := Result + ' ';

  S := '';
  for AField in Fields do
  begin
    if AField.Value.Kind in [tkInteger, tkInt64, tkFloat, tkEnumeration] then
      Val := AField.Key + '=' + AField.Value.ToString
    else
      Val := AField.Key + '=' + AField.Value.ToString.QuotedString('"');
    S := IfThen(S = '', Val, String.Join(',', [S, Val]));
  end;

  Result := Result + S;

  if TimeStamp > 0 then
  begin
    Result := Result + ' ' + System.DateUtils.DateTimeToUnix(TimeStamp).ToString;
  end;
end;

constructor TInfluxValue.Create(AMeasurement: String; ATimeStamp: TDateTime);
begin
  SetLength(Tags, 0);
  SetLength(Fields, 0);
  Measurement := AMeasurement;
  TimeStamp := ATimeStamp;
end;

{ TResultRecord }

function TResultRecord.Count: Integer;
begin
  Result := Length(Columns);
end;

{ TResultSerie }

function TResultSerie.Count: Integer;
begin
  Result := Length(Values);
end;

constructor TResultSerie.Create;
begin
  SetLength(Columns, 0);
  SetLength(Values, 0);
end;

end.
