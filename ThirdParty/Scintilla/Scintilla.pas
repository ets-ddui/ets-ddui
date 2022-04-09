{
  Copyright (c) 2021-2031 Steven Shi

  ETS_DDUI For Delphi����Ư���������������򵥡�

  ��UI���ǿ�Դ������������������� MIT Э�飬�޸ĺͷ����˳���
  �����˿��Ŀ����ϣ�������ã��������κα�֤��
  ���������������ҵ��Ŀ�����ڱ����е�Bug����������κη��ռ���ʧ�������߲��е��κ����Ρ�

  ��Դ��ַ: https://github.com/ets-ddui/ets-ddui
            https://gitee.com/ets-ddui/ets-ddui
  ��ԴЭ��: The MIT License (MIT)
  ��������: xinghun87@163.com
  �ٷ����ͣ�https://blog.csdn.net/xinghun61
}
unit Scintilla;

interface

uses
  Windows, Classes, SysUtils, StrUtils, Controls, Messages, Graphics, qjson,
  ScintillaConst, ScintillaLexerConst;

const
  CStylePrefix = 'embed:';
  CDefaultStyle = CStylePrefix + 'DefaultStyle';

type
  TWrapStyle = (wsNone, wsWord, wsChar, wsWhiteSpace);
  TLanguage = (lagNone, lagAssembler, lagBash, lagBatch, lagCMake,
    lagConf, lagCpp, lagCss, lagGo, lagIdl,
    lagJava, lagJavaScript, lagLua, lagNsis, lagPascal,
    lagPerl, lagPhp, lagPowerShell, lagProperties, lagMakefile,
    lagPython, lagSql, lagVb, lagVBScript, lagHtml, lagXml);

  TUchardetEntry = function (AValue: PAnsiChar; ALen: Integer): Integer; stdcall;

  TScintilla = class;

  TScintillaItemBase = class(TPersistent)
  strict private
    FOwner: TScintilla;
  protected
    function HandleAllocated: Boolean;
    function Perform(AMessage: Cardinal; AWParam: Longint = 0; ALParam: Longint = 0): Longint;
    property Owner: TScintilla read FOwner;
  public
    constructor Create(AOwner: TScintilla); reintroduce; virtual;
    procedure Backup; virtual; abstract; //��������ǰ�������ھ���е�ֵ��д����Ա������
    procedure Update; virtual; abstract; //���ڴ����󣬽���Ա�����е�ֵ�赽���ھ����
  end;

  TItemType = (itText, itView);
  TScintillaItems = array[TItemType] of TScintillaItemBase;

  TScintillaText = class(TScintillaItemBase)
  private
    FCodePage: Word;
    FReadOnly: Boolean;
    FUseTab: Boolean;
    FValue: String;
    procedure SetCodePage(const AValue: Word);
    function GetCount: Integer;
    function GetLines(AIndex: Integer): String;
    procedure SetLines(AIndex: Integer; const AValue: String);
    procedure SetReadOnly(const AValue: Boolean);
    function GetValue: String;
    procedure SetUseTab(const AValue: Boolean);
    procedure SetValue(const AValue: String);
  protected
    procedure AssignTo(ADest: TPersistent); override;
  public
    constructor Create(AOwner: TScintilla); override;
    procedure Backup; override;
    procedure Update; override;
    procedure LoadFromFile(const AFileName: String);
    procedure LoadFromStream(AStream: TStream);
    property Lines[AIndex: Integer]: String read GetLines write SetLines;
  published
    property CodePage: Word read FCodePage write SetCodePage default 0;
    property Count: Integer read GetCount;
    property ReadOnly: Boolean read FReadOnly write SetReadOnly default False;
    property UseTab: Boolean read FUseTab write SetUseTab default True;
    property Value: String read GetValue write SetValue;
  end;

  TScintillaView = class(TScintillaItemBase)
  private
    FFoldIndicator: Boolean;
    FLanguage: TLanguage;
    FShowLineNumber: Boolean;
    FShowWhiteSpace: Boolean;
    FStyleFile: String;
    FTabSize: Integer;
    FWrap: TWrapStyle;
    procedure ApplyStyle;
    procedure SetLanguageByExt(AExt: String);
    procedure SetFoldIndicator(const AValue: Boolean);
    procedure SetLanguage(const AValue: TLanguage);
    procedure SetShowLineNumber(const AValue: Boolean);
    procedure SetShowWhiteSpace(const AValue: Boolean);
    procedure SetStyleFile(const AValue: String);
    procedure SetTabSize(const AValue: Integer);
    procedure SetWrap(const AValue: TWrapStyle);
  protected
    procedure AssignTo(ADest: TPersistent); override;
  public
    constructor Create(AOwner: TScintilla); override;
    procedure Backup; override;
    procedure Update; override;
  published
    property FoldIndicator: Boolean read FFoldIndicator write SetFoldIndicator default False;
    property Language: TLanguage read FLanguage write SetLanguage default lagNone;
    property ShowLineNumber: Boolean read FShowLineNumber write SetShowLineNumber default False;
    property ShowWhiteSpace: Boolean read FShowWhiteSpace write SetShowWhiteSpace default False;
    property StyleFile: String read FStyleFile write SetStyleFile;
    property TabSize: Integer read FTabSize write SetTabSize default 8;
    {TODO: ���û��к󣬾��ᵼ����������}
    property Wrap: TWrapStyle read FWrap write SetWrap default wsNone;
  end;

  TOnScintillaClick = procedure (ASender: TObject; ARow, ACol: Integer) of object;
  TOnScintillaMouse = procedure (ASender: TObject; AButton: TMouseButton; AShift: TShiftState; ARow, ACol: Integer) of object;
  TOnScintillaMouseMove = procedure (ASender: TObject; AShift: TShiftState; ARow, ACol: Integer) of object;
  TScintilla = class(TWinControl)
  private
    class var FScintillaModule: THandle;
    class var FUchardetModule: THandle;
    class var FUchardetEntry: TUchardetEntry;
    class var FStyleFileList: TStringList;
    class procedure Init;
    class procedure UnInit;
    class function GetStyle(AStyleName: String): TQJson;
  private
    FItems: TScintillaItems;
    FOnClick: TOnScintillaClick;
    FOnDblClick: TOnScintillaClick;
    FOnMouseDown: TOnScintillaMouse;
    FOnMouseMove: TOnScintillaMouseMove;
    FOnMouseUp: TOnScintillaMouse;
    procedure WMGetDlgCode(var AMessage: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMPaint(var AMessage: TWMPaint); message WM_PAINT;
    function GetText: TScintillaText;
    procedure SetText(const AValue: TScintillaText);
    function GetView: TScintillaView;
    procedure SetView(const AValue: TScintillaView);
  protected
    procedure CreateParams(var AParams: TCreateParams); override;
    procedure CreateWnd; override;
    procedure DestroyWnd; override;
    function DefaultPerform(AMessage: Cardinal; AWParam: Longint = 0; ALParam: Longint = 0): Longint;
    procedure InitItems(var AItems: TScintillaItems); virtual;
    function MouseToCell(APoint: TPoint): TPoint;
    procedure Click; override;
    procedure DblClick; override;
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer); override;
    procedure MouseMove(AShift: TShiftState; AX, AY: Integer); override;
    procedure MouseUp(AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Align;
    property Anchors;
    property Text: TScintillaText read GetText write SetText;
    property View: TScintillaView read GetView write SetView;
    property OnClick: TOnScintillaClick read FOnClick write FOnClick;
    property OnDblClick: TOnScintillaClick read FOnDblClick write FOnDblClick;
    property OnMouseDown: TOnScintillaMouse read FOnMouseDown write FOnMouseDown;
    property OnMouseMove: TOnScintillaMouseMove read FOnMouseMove write FOnMouseMove;
    property OnMouseUp: TOnScintillaMouse read FOnMouseUp write FOnMouseUp;
  end;

implementation

{$R *.res}

const
  CLanguage: array[TLanguage] of String = (
    '*', 'Assembler', 'Bash', 'Batch', 'CMake',
    'Apache Conf', 'C C++', 'CSS', 'Go', 'IDL',
    'Java', 'JavaScript', 'Lua', 'NSIS', 'Pascal',
    'Perl', 'PHP', 'PowerShell', 'Properties', 'Makefile',
    'Python', 'SQL', 'VB', 'VBScript', 'Html', 'Xml');

type
  TScintillaStringList = class(TStringList)
  public
    function Add(const AValue: String): Integer; override;
  end;

{ TScintillaStringList }

function TScintillaStringList.Add(const AValue: String): Integer;
var
  sValue: String;
begin
  if Pos(NameValueSeparator, AValue) = 0 then
    sValue := AValue + NameValueSeparator
  else
    sValue := AValue;

  Result := inherited Add(sValue);
end;

{ TScintillaItemBase }

constructor TScintillaItemBase.Create(AOwner: TScintilla);
begin
  inherited Create;

  FOwner := AOwner;
end;

function TScintillaItemBase.HandleAllocated: Boolean;
begin
  Result := FOwner.HandleAllocated;
end;

function TScintillaItemBase.Perform(AMessage: Cardinal; AWParam, ALParam: Integer): Longint;
begin
  Result := FOwner.DefaultPerform(AMessage, AWParam, ALParam);
end;

{ TScintillaText }

constructor TScintillaText.Create(AOwner: TScintilla);
begin
  inherited;

  FUseTab := True;
end;

procedure TScintillaText.Backup;
begin
  //��ȡ�ı��Ĳ�������Scintilla�м�¼��Ϊ׼��ֻ�е�����δ����ʱ���Ż��ȡFValue��ֵ��
  //��ˣ��������ͷ�ʱ����ͬ�����µ�ֵ��FValue�У���֤�ڴ������´���ʱ��FValue��ֵ������ȷ��ʼ��
  FValue := GetValue;
end;

procedure TScintillaText.Update;
begin
  SetCodePage(FCodePage);
  SetReadOnly(FReadOnly); //������SetText֮�����(Scintilla��ReadOnlyΪTrueʱ������������ֵ)
  SetUseTab(FUseTab);
  SetValue(FValue);
end;

procedure TScintillaText.AssignTo(ADest: TPersistent);
begin
  if not Assigned(ADest) or not (ADest is TScintillaText) then
  begin
    inherited;
    Exit;
  end;

  TScintillaText(ADest).FCodePage := FCodePage;
  TScintillaText(ADest).FReadOnly := FReadOnly;
  TScintillaText(ADest).FUseTab := FUseTab;
  TScintillaText(ADest).FValue := FValue;

  TScintillaText(ADest).Owner.Update;
end;

procedure TScintillaText.LoadFromFile(const AFileName: String);
var
  i: Integer;
  stm: TStream;
begin
  i := LastDelimiter('.\/', AFileName);
  if (i > 0) and (AFileName[i] = '.') then
    Owner.View.SetLanguageByExt(Copy(AFileName, i + 1, MaxInt));

  stm := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(stm);
  finally
    FreeAndNil(stm);
  end;
end;

procedure TScintillaText.LoadFromStream(AStream: TStream);
var
  iLen: Integer;
  sText: String;
begin
  iLen := AStream.Size - AStream.Position;
  SetLength(sText, iLen);
  AStream.Read(sText[1], iLen);
  SetValue(sText);
end;

procedure TScintillaText.SetCodePage(const AValue: Word);
begin
  FCodePage := AValue;
  if not HandleAllocated then
    Exit;

  Perform(SCI_SETCODEPAGE, FCodePage);
end;

function TScintillaText.GetCount: Integer;
begin
  Result := Perform(SCI_GETLINECOUNT);
end;

function TScintillaText.GetLines(AIndex: Integer): String;
var
  iLen: Integer;
begin
  Result := '';
  if (AIndex < 0) or (AIndex >= GetCount) then
    Exit;

  iLen := Perform(SCI_LINELENGTH, AIndex);
  SetLength(Result, iLen);
  Perform(SCI_GETLINE, AIndex, Integer(@Result[1]));

  //��ȡWindows����
  if iLen > 1 then
  begin
    if (Result[iLen - 1] = #$D) and (Result[iLen] = #$A) then
    begin
      SetLength(Result, iLen - 2);
      Exit;
    end;
  end;

  //��ȡUnix��Mac����
  if iLen > 0 then
  begin
    if (Result[iLen] = #$D) or (Result[iLen] = #$A) then //�����õ�or
    begin
      SetLength(Result, iLen - 1);
      Exit;
    end;
  end;
end;

procedure TScintillaText.SetLines(AIndex: Integer; const AValue: String);
begin
  if (AIndex < 0) or (AIndex >= GetCount) then
    Exit;

  //ѡ��ָ���е��ı�(���ĵ�������SCI_SETSEL���ƶ����λ�ã���SCI_SETCURRENTPOS��SCI_SETANCHOR����)
  Perform(SCI_SETTARGETSTART, Perform(SCI_POSITIONFROMLINE, AIndex));
  Perform(SCI_SETTARGETEND, Perform(SCI_GETLINEENDPOSITION, AIndex)); //�ĵ�˵SCI_GETLINEENDPOSITION���������з�

  //�滻ѡ�е��ı�(�൱�ڰ�AIndexָ���е������滻ΪAValue)
  Perform(SCI_REPLACETARGET, Length(AValue), Integer(@AValue[1]));
end;

procedure TScintillaText.SetReadOnly(const AValue: Boolean);
begin
  FReadOnly := AValue;
  if not HandleAllocated then
    Exit;

  Perform(SCI_SETREADONLY, Ord(AValue));
end;

procedure TScintillaText.SetUseTab(const AValue: Boolean);
begin
  FUseTab := AValue;
  if not HandleAllocated then
    Exit;

  Perform(SCI_SETUSETABS, Ord(FUseTab));
end;

function TScintillaText.GetValue: String;
var
  iLen: Integer;
begin
  if not HandleAllocated then
  begin
    Result := FValue;
    Exit;
  end;

  iLen := Perform(SCI_GETTEXTLENGTH);
  //����Scintilla��������ַ����ս�β������ˣ�������һ���ַ�����ȡ�����ݺ��ٽص�
  SetLength(Result, iLen + 1);
  Perform(SCI_GETTEXT, iLen + 1, Integer(@Result[1]));
  SetLength(Result, iLen);
end;

function BigToLittleEndian(AValue: Word): Word;
begin
  Result := (AValue shl 8) or (AValue shr 8);
end;

function NoTranslate(AValue: Word): Word;
begin
  Result := AValue;
end;

type
  TTranslate = function (AValue: Word): Word;

procedure TScintillaText.SetValue(const AValue: String);
  function unicodeToUtf8(ATranslate: TTranslate): String;
  var
    iLen: Integer;
    iValue: DWORD;
    piBegin, piEnd: PWORD;
  begin
    //����С�˱��룬���ֽڲ��ֻ�浽UTF-8�ĵ��ֽ���
    piBegin := @AValue[1];
    piEnd := PWORD(DWORD(piBegin) + (Length(AValue) and $FFFFFFFE));

    SetLength(Result, Length(AValue) + Length(AValue) div 2 + 1);
    iLen := 0;
    while DWORD(piBegin) < DWORD(piEnd) do
    begin
      iValue := ATranslate(piBegin^);
      piBegin := PWORD(DWORD(piBegin) + 2);
      if (iValue >= $D800) and (iValue <= $DBFF) then
      begin
        if DWORD(piBegin) >= DWORD(piEnd) then
          Exit;

        iValue := (((iValue and $3FF) shl 10) or (ATranslate(piBegin^) and $3FF)) + $10000;
        piBegin := PWORD(DWORD(piBegin) + 2);
      end;

      if iValue < $80 then
      begin
        Result[iLen + 1] := Char(iValue);
        iLen := iLen + 1;
      end
      else if iValue < $800 then
      begin
        Result[iLen + 1] := Char((iValue shr 6) or $C0);
        Result[iLen + 2] := Char((iValue and $3F) or $80);
        iLen := iLen + 2;
      end
      else if iValue < $10000 then
      begin
        Result[iLen + 1] := Char((iValue shr 12) or $E0);
        Result[iLen + 2] := Char(((iValue shr 6) and $3F) or $80);
        Result[iLen + 3] := Char((iValue and $3F) or $80);
        iLen := iLen + 3;
      end
      else
      begin
        Result[iLen + 1] := Char((iValue shr 18) or $F0);
        Result[iLen + 2] := Char(((iValue shr 12) and $3F) or $80);
        Result[iLen + 3] := Char(((iValue shr 6) and $3F) or $80);
        Result[iLen + 4] := Char((iValue and $3F) or $80);
        iLen := iLen + 4;
      end;     
    end;

    SetLength(Result, iLen);
  end;
var
  ue: TUchardetEntry;
begin
  if not HandleAllocated then
  begin
    FValue := AValue;
    Exit;
  end;

  if AValue = '' then
  begin
    FValue := '';
    SetCodePage(0);
  end
  else if (Length(AValue) >= 2) and (AValue[1] = #$FE) and (AValue[2] = #$FF) then //���
  begin
    FValue := unicodeToUtf8(BigToLittleEndian);
    SetCodePage(65001);
  end
  else if (Length(AValue) >= 2) and (AValue[1] = #$FF) and (AValue[2] = #$FE) then //С��
  begin
    FValue := unicodeToUtf8(NoTranslate);
    SetCodePage(65001);
  end
  else if (Length(AValue) >= 3) and (AValue[1] = #$EF) and (AValue[2] = #$BB) and (AValue[3] = #$BF) then //UTF-8
  begin
    FValue := RightStr(AValue, Length(AValue) - 3);
    SetCodePage(65001);
  end
  else
  begin
    FValue := AValue;
    ue := TScintilla.FUchardetEntry;
    if Assigned(ue) then
      SetCodePage(ue(@FValue[1], Length(FValue)));
  end;

  try
    if FReadOnly then
      Perform(SCI_SETREADONLY, 0);

    Perform(SCI_SETTEXT, 0, Integer(PChar(FValue + #0)));
  finally
    if FReadOnly then
      Perform(SCI_SETREADONLY, 1);

    Perform(SCI_EMPTYUNDOBUFFER);
  end;
end;

{ TScintillaView }

constructor TScintillaView.Create(AOwner: TScintilla);
begin
  inherited;

  FStyleFile := CDefaultStyle;
  FTabSize := 8;
end;

procedure TScintillaView.Backup;
begin

end;

procedure TScintillaView.Update;
begin
  SetLanguage(FLanguage);
  //SetFoldIndicator(FFoldIndicator); //�Ƶ�SetLanguage�е���
  SetShowLineNumber(FShowLineNumber);
  SetShowWhiteSpace(FShowWhiteSpace);
  SetTabSize(FTabSize);
  SetWrap(FWrap);
end;

procedure TScintillaView.AssignTo(ADest: TPersistent);
begin
  if not Assigned(ADest) or not (ADest is TScintillaView) then
  begin
    inherited;
    Exit;
  end;

  TScintillaView(ADest).FFoldIndicator := FFoldIndicator;
  TScintillaView(ADest).FLanguage := FLanguage;
  TScintillaView(ADest).FShowLineNumber := FShowLineNumber;
  TScintillaView(ADest).FShowWhiteSpace := FShowWhiteSpace;
  TScintillaView(ADest).FStyleFile := FStyleFile;
  TScintillaView(ADest).FTabSize := FTabSize;
  TScintillaView(ADest).FWrap := FWrap;

  TScintillaView(ADest).Owner.Update;
end;

function GetJsonPath(AJson: TQJson; APath: String): String;
var
  sTemp: String;
  iBegin, iEnd: Integer;
begin
  Result := '';

  iBegin := 1;
  sTemp := AJson.ValueByPath(APath, '');
  while True do
  begin
    iEnd := PosEx('$(', sTemp, iBegin);
    if iEnd = 0 then
    begin
      if iBegin = 1 then
        Result := sTemp
      else
        Result := Result + RightStr(sTemp, Length(sTemp) - iBegin + 1);

      Exit;
    end;
    Result := Result + MidStr(sTemp, iBegin, iEnd - iBegin);

    iBegin := iEnd + 2;
    iEnd := PosEx(')', sTemp, iBegin);
    if iEnd = 0 then
    begin
      Result := Result + RightStr(sTemp, Length(sTemp) - iBegin + 3);
      Exit;
    end;

    Result := Result + GetJsonPath(AJson, MidStr(sTemp, iBegin, iEnd - iBegin));
    iBegin := iEnd + 1;
  end;
end;

procedure TScintillaView.ApplyStyle;
  function toColor(AValue: String): Integer;
  begin
    if AValue[1] = '#' then
      AValue[1] := '$';
    Result := StringToColor(AValue);
  end;
  procedure setStyle(AStyle: Integer; AName, AValue: String); overload;
  begin
    if 0 = CompareText(AName, 'italics') then
      Perform(SCI_STYLESETITALIC, AStyle, StrToIntDef(AValue, 1))
    else if 0 = CompareText(AName, 'bold') then
    begin
      if (AValue = '0') then
        Perform(SCI_STYLESETWEIGHT, AStyle, SC_WEIGHT_NORMAL)
      else
        Perform(SCI_STYLESETWEIGHT, AStyle, SC_WEIGHT_BOLD);
    end
    else if 0 = CompareText(AName, 'weight') then
      Perform(SCI_STYLESETWEIGHT, AStyle, StrToIntDef(AValue, 0))
    else if 0 = CompareText(AName, 'font') then
      Perform(SCI_STYLESETFONT, AStyle, Integer(@AValue[1]))
    else if 0 = CompareText(AName, 'fore') then
      Perform(SCI_STYLESETFORE, AStyle, toColor(AValue))
    else if 0 = CompareText(AName, 'back') then
      Perform(SCI_STYLESETBACK, AStyle, toColor(AValue))
    else if 0 = CompareText(AName, 'size') then
      Perform(SCI_STYLESETSIZEFRACTIONAL, AStyle, Trunc(StrToFloatDef(AValue, 0) * SC_FONT_SIZE_MULTIPLIER))
    else if 0 = CompareText(AName, 'eolfilled') then
      Perform(SCI_STYLESETEOLFILLED, AStyle, StrToIntDef(AValue, 1))
    else if 0 = CompareText(AName, 'underlined') then
      Perform(SCI_STYLESETUNDERLINE, AStyle, StrToIntDef(AValue, 1))
    else if 0 = CompareText(AName, 'case') then
    begin
      if AValue = 'u' then
        Perform(SCI_STYLESETCASE, AStyle, SC_CASE_UPPER)
      else if AValue = 'l' then
        Perform(SCI_STYLESETCASE, AStyle, SC_CASE_LOWER)
      else
        Perform(SCI_STYLESETCASE, AStyle, SC_CASE_MIXED);
    end
    else if 0 = CompareText(AName, 'visible') then
      Perform(SCI_STYLESETVISIBLE, AStyle, StrToIntDef(AValue, 1))
    else if 0 = CompareText(AName, 'changeable') then
      Perform(SCI_STYLESETCHANGEABLE, AStyle, StrToIntDef(AValue, 1))
    else if (AName <> '') or (AValue <> '') then
      raise Exception.Create(Format('�޷�ʶ�����ʽ(%d, %s, %s)', [AStyle, AName, AValue]));
  end;
  procedure setStyle(AStyle: Integer; ALanguage: TLanguage; AJson: TQJson); overload;
  var
    i: Integer;
    sLexer: String;
  begin
    if ALanguage = lagNone then
      sLexer := '*'
    else
      sLexer := GetJsonPath(AJson, Format('languages.%s.lexer', [CLanguage[ALanguage]]));

    with TScintillaStringList.Create do
      try
        StrictDelimiter := True;
        NameValueSeparator := ':';
        Delimiter := ',';
        DelimitedText := GetJsonPath(AJson, Format('lexers.%s.style.%d', [sLexer, AStyle]));
        for i := 0 to Count - 1 do
          setStyle(AStyle, Names[i], ValueFromIndex[i]);
        if Count > 0 then
          Perform(SCI_STYLESETCHARACTERSET, AStyle, SC_CHARSET_DEFAULT);
      finally
        Free;
      end;
  end;
var
  json: TQJson;
  iStyle, iMaxStyle: Integer;
begin
  json := TScintilla.GetStyle(FStyleFile);
  if not Assigned(json) then
    Exit;

  //SCI_STYLERESETDEFAULT�ǽ�Ĭ����ʽ��Ϊ��ʼֵ(���޸ĵ�STYLE_DEFAULT��ֵ��ֻ������Ҫ�ص�ֵ�ڴ�����д���ˣ���ԴΪ)
  //SCI_STYLECLEARALL�ǽ�STYLE_DEFAULT��ֵ�����ǵ�������ʽ��
  //���ԣ�������߼�Ҫ������STYLE_DEFAULT����ʽ��Ȼ�󣬵���SCI_STYLECLEARALL��������ʽ��ʼ��ΪĬ��ֵ��������Ե������ض���ʽ��ֵ
  setStyle(STYLE_DEFAULT, lagNone, json);
  //DefaultPerform(SCI_STYLERESETDEFAULT);
  Perform(SCI_STYLECLEARALL);

  for iStyle := 0 to STYLE_DEFAULT - 1 do
    setStyle(iStyle, lagNone, json);

  iMaxStyle := (1 shl Perform(SCI_GETSTYLEBITS)) - 1;
  for iStyle := STYLE_DEFAULT + 1 to iMaxStyle do
    setStyle(iStyle, lagNone, json);

  if FLanguage <> lagNone then
  begin
    setStyle(STYLE_DEFAULT, FLanguage, json);
    Perform(SCI_STYLECLEARALL);

    for iStyle := 0 to STYLE_DEFAULT - 1 do
      setStyle(iStyle, FLanguage, json);

    for iStyle := STYLE_DEFAULT + 1 to iMaxStyle do
      setStyle(iStyle, FLanguage, json);
  end;

  Owner.Invalidate;
end;

procedure TScintillaView.SetLanguageByExt(AExt: String);
  function calcLanguage(AExt: String): TLanguage;
  var
    iLanguage, iExt: Integer;
    json, jsonLanguage, jsonExt: TQJson;
  begin
    Result := lagNone;

    json := TScintilla.GetStyle(FStyleFile);
    if not Assigned(json) then
      Exit;

    json := json.ItemByName('languages');
    for iLanguage := 0 to json.Count - 1 do
    begin
      jsonLanguage := json[iLanguage];
      jsonExt := jsonLanguage.ItemByName('file_extension');
      for iExt := 0 to jsonExt.Count - 1 do
        if CompareText(AExt, jsonExt[iExt].Value) = 0 then
        begin
          for Result := Low(TLanguage) to High(TLanguage) do
            if CompareText(jsonLanguage.Name, CLanguage[Result]) = 0 then
              Exit;

          Result := lagNone;
          Exit;
        end;
    end;
  end;
begin
  SetLanguage(calcLanguage(AExt));
end;

procedure TScintillaView.SetFoldIndicator(const AValue: Boolean);
  procedure defineMarker(AMarker: Integer; AType: Integer; AFore, ABack, ABackSelected: TColor);
  begin
    Perform(SCI_MARKERDEFINE, AMarker, AType);
    Perform(SCI_MARKERSETFORE, AMarker, AFore);
    Perform(SCI_MARKERSETBACK, AMarker, ABack);
    Perform(SCI_MARKERSETBACKSELECTED, AMarker, ABackSelected);
  end;
begin
  FFoldIndicator := AValue;
  if not HandleAllocated then
    Exit;

  if FFoldIndicator then
  begin
    //�����۵����Ŀ��
    Perform(SCI_SETMARGINWIDTHN, 2, 14);

    //�����۵���������
    Perform(SCI_SETPROPERTY, Integer(@('fold'#0)[1]), Integer(@('1'#0)[1]));
    Perform(SCI_SETPROPERTY, Integer(@('fold.comment'#0)[1]), Integer(@('1'#0)[1]));
    Perform(SCI_SETMARGINMASKN, 2, Integer(SC_MASK_FOLDERS));
    Perform(SCI_SETAUTOMATICFOLD, SC_AUTOMATICFOLD_CLICK);
    Perform(SCI_SETMARGINSENSITIVEN, 2, 1);

    //�����۵���ť�����
    defineMarker(SC_MARKNUM_FOLDEROPEN, SC_MARK_BOXMINUS, $FFFFFF, $808080, $FF);
    defineMarker(SC_MARKNUM_FOLDER, SC_MARK_BOXPLUS, $FFFFFF, $808080, $FF);
    defineMarker(SC_MARKNUM_FOLDERSUB, SC_MARK_VLINE, $FFFFFF, $808080, $FF);
    defineMarker(SC_MARKNUM_FOLDERTAIL, SC_MARK_LCORNER, $FFFFFF, $808080, $FF);
    defineMarker(SC_MARKNUM_FOLDEREND, SC_MARK_BOXPLUSCONNECTED, $FFFFFF, $808080, $FF);
    defineMarker(SC_MARKNUM_FOLDEROPENMID, SC_MARK_BOXMINUSCONNECTED, $FFFFFF, $808080, $FF);
    defineMarker(SC_MARKNUM_FOLDERMIDTAIL, SC_MARK_TCORNER, $FFFFFF, $808080, $FF);

    Perform(SCI_MARKERENABLEHIGHLIGHT, 0);
  end
  else
    Perform(SCI_SETMARGINWIDTHN, 2, 0);
end;

procedure TScintillaView.SetLanguage(const AValue: TLanguage);
var
  iKeyword: Integer;
  json: TQJson;
  sKeyword, sLexer: String;
begin
  FLanguage := AValue;
  if not HandleAllocated then
    Exit;

  if AValue = lagNone then
    Perform(SCI_SETLEXER, SCLEX_NULL)
  else
  begin
    json := TScintilla.GetStyle(FStyleFile);
    if not Assigned(json) then
      Exit;

    sLexer := GetJsonPath(json, Format('languages.%s.lexer', [CLanguage[FLanguage]]));
    if sLexer = '' then
      Exit;

    Perform(SCI_SETLEXERLANGUAGE, 0, Integer(@sLexer[1]));

    for iKeyword := 0 to 8 do
    begin
      sKeyword := GetJsonPath(json, Format('languages.%s.keywords.%d', [CLanguage[FLanguage], iKeyword]));
      if sKeyword <> '' then
        Perform(SCI_SETKEYWORDS, iKeyword, Integer(@sKeyword[1]));
    end;
  end;

  SetFoldIndicator(FFoldIndicator);

  ApplyStyle;
end;

procedure TScintillaView.SetShowLineNumber(const AValue: Boolean);
var
  iLineCount, iWidth: Integer;
  str: String;
begin
  FShowLineNumber := AValue;
  if not HandleAllocated then
    Exit;

  if AValue then
  begin
    iLineCount := Perform(SCI_GETLINECOUNT);
    while iLineCount > 0 do
    begin
      iLineCount := iLineCount div 10;
      str := str + '9';
    end;

    while Length(str) < 4 do
    begin
      str := str + '9';
    end;

    iWidth := 4 + Perform(SCI_TEXTWIDTH, STYLE_LINENUMBER, Integer(@str[1]));

    Perform(SCI_SETMARGINWIDTHN, 0, iWidth);
  end
  else
  begin
    Perform(SCI_SETMARGINWIDTHN, 0, 0);
  end;
end;

procedure TScintillaView.SetShowWhiteSpace(const AValue: Boolean);
begin
  FShowWhiteSpace := AValue;
  if not HandleAllocated then
    Exit;

  //�ո����ʾģʽ��3�֣�SCWS_VISIBLEAFTERINDENT����ʾģʽ��ʱ���ṩ֧��
  if FShowWhiteSpace then
    Perform(SCI_SETVIEWWS, SCWS_VISIBLEALWAYS)
  else
    Perform(SCI_SETVIEWWS, SCWS_INVISIBLE);
end;

procedure TScintillaView.SetStyleFile(const AValue: String);
begin
  FStyleFile := AValue;
  if not HandleAllocated then
    Exit;

  ApplyStyle;
end;

procedure TScintillaView.SetTabSize(const AValue: Integer);
begin
  if AValue <= 0 then
    Exit;

  FTabSize := AValue;
  if not HandleAllocated then
    Exit;

  //��SciTE�Ĵ���������SCI_SETTABWIDTH����Tab�����������
  //��SCI_SETINDENT��Tab��Backspace����ÿ�����ӡ����ٵĿո����й�
  Perform(SCI_SETTABWIDTH, FTabSize);
  Perform(SCI_SETINDENT, FTabSize);
end;

procedure TScintillaView.SetWrap(const AValue: TWrapStyle);
begin
  FWrap := AValue;
  if not HandleAllocated then
    Exit;

  Perform(SCI_SETWRAPMODE, Ord(AValue));
end;

{ TScintilla }

constructor TScintilla.Create(AOwner: TComponent);
var
  it: TItemType;
begin
  inherited;

  InitItems(FItems);
  for it := Low(TItemType) to High(TItemType) do
  begin
    if Assigned(FItems[it]) then
      Continue;

    case it of
      itText: FItems[it] := TScintillaText.Create(Self);
      itView: FItems[it] := TScintillaView.Create(Self);
    else
      raise Exception.Create('TScintilla����ʧ��');
    end;
  end;
end;

destructor TScintilla.Destroy;
var
  it: TItemType;
begin
  for it := Low(TItemType) to High(TItemType) do
    FreeAndNil(FItems[it]);

  inherited;
end;

procedure TScintilla.InitItems(var AItems: TScintillaItems);
begin
  //�ڴ˺����У��ṩ�����FItems�д�Ŷ�����Զ��崴������
end;

procedure TScintilla.CreateParams(var AParams: TCreateParams);
begin
  inherited CreateParams(AParams);

  if FScintillaModule <> 0 then
  begin
    AParams.WindowClass.hInstance := FScintillaModule;
    CreateSubClass(AParams, 'Scintilla');
  end;
end;

procedure TScintilla.CreateWnd;
var
  it: TItemType;
begin
  inherited;

  //DefaultPerform(SCI_SETBUFFEREDDRAW, 0); //����Scintilla��ͼ�߼�ʱ���򿪴�ע�ͣ��Թر�˫�������

  for it := Low(TItemType) to High(TItemType) do
    FItems[it].Update;
end;

procedure TScintilla.DestroyWnd;
var
  it: TItemType;
begin
  for it := Low(TItemType) to High(TItemType) do
    FItems[it].Backup;

  inherited;
end;

function TScintilla.DefaultPerform(AMessage: Cardinal; AWParam, ALParam: Integer): Longint;
var
  msg: TMessage;
begin
  HandleNeeded;

  msg.Msg := AMessage;
  msg.WParam := AWParam;
  msg.LParam := ALParam;
  msg.Result := 0;
  if Assigned(Self) then
    DefaultHandler(msg);

  Result := msg.Result;
end;

procedure TScintilla.WMGetDlgCode(var AMessage: TWMGetDlgCode);
begin
  inherited;

  //Scintillaֻ������DLGC_WANTALLKEYS or DLGC_HASSETSEL�����¼��̷�����޷���������
  //Delphi��TApplication.IsKeyMsg�лὫ��Ϣת����TWinControl.CNKeyDown�������������ж��Ƿ���Ϣת�����ؼ�����
  AMessage.Result := AMessage.Result or DLGC_WANTARROWS or DLGC_WANTTAB; // or DLGC_WANTCHARS;
end;

procedure TScintilla.WMPaint(var AMessage: TWMPaint);
begin
  AMessage.DC := 0;
  DefaultHandler(AMessage);
end;

function TScintilla.MouseToCell(APoint: TPoint): TPoint;
var
  iPosition: Integer;
begin
  iPosition := DefaultPerform(SCI_POSITIONFROMPOINT, APoint.X, APoint.Y);

  Result.X := DefaultPerform(SCI_LINEFROMPOSITION, iPosition);
  Result.Y := DefaultPerform(SCI_GETCOLUMN, iPosition);
end;

procedure TScintilla.Click;
var
  pt: TPoint;
begin
  if Assigned(FOnClick) then
  begin
    pt := MouseToCell(Mouse.CursorPos);
    FOnClick(Self, pt.X, pt.Y);
  end;
end;

procedure TScintilla.DblClick;
var
  pt: TPoint;
begin
  if Assigned(FOnDblClick) then
  begin
    pt := MouseToCell(Mouse.CursorPos);
    FOnDblClick(Self, pt.X, pt.Y);
  end;
end;

procedure TScintilla.MouseDown(AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
var
  pt: TPoint;
begin
  if Assigned(FOnMouseDown) then
  begin
    pt := MouseToCell(Point(AX, AY));
    FOnMouseDown(Self, AButton, AShift, pt.X, pt.Y);
  end;
end;

procedure TScintilla.MouseMove(AShift: TShiftState; AX, AY: Integer);
var
  pt: TPoint;
begin
  if Assigned(FOnMouseMove) then
  begin
    pt := MouseToCell(Point(AX, AY));
    FOnMouseMove(Self, AShift, pt.X, pt.Y);
  end;
end;

procedure TScintilla.MouseUp(AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
var
  pt: TPoint;
begin
  if Assigned(FOnMouseUp) then
  begin
    pt := MouseToCell(Point(AX, AY));
    FOnMouseUp(Self, AButton, AShift, pt.X, pt.Y);
  end;
end;

function TScintilla.GetText: TScintillaText;
begin
  Result := TScintillaText(FItems[itText]);
end;

procedure TScintilla.SetText(const AValue: TScintillaText);
begin
  FItems[itText].Assign(AValue);
end;

function TScintilla.GetView: TScintillaView;
begin
  Result := TScintillaView(FItems[itView]);
end;

procedure TScintilla.SetView(const AValue: TScintillaView);
begin
  FItems[itView].Assign(AValue);
end;

class procedure TScintilla.Init;
begin
  FScintillaModule := LoadLibrary('SciLexer.dll');
  FStyleFileList := TStringList.Create;

  FUchardetEntry := nil;
  FUchardetModule := LoadLibrary('uchardet.dll');
  if FUchardetModule <> 0 then
    FUchardetEntry := GetProcAddress(FUchardetModule, 'DetectCodePage');
end;

class procedure TScintilla.UnInit;
var
  i: Integer;
begin
  if FUchardetModule <> 0 then
  begin
    FreeLibrary(FUchardetModule);
    FUchardetModule := 0;
    FUchardetEntry := nil;
  end;

  if FScintillaModule <> 0 then
  begin
    FreeLibrary(FScintillaModule);
    FScintillaModule := 0;
  end;

  for i := 0 to FStyleFileList.Count - 1 do
    FStyleFileList.Objects[i].Free;
  FreeAndNil(FStyleFileList);
end;

class function TScintilla.GetStyle(AStyleName: String): TQJson;
var
  i: Integer;
  sResName: String;
  rs: TResourceStream;
begin
  for i := 0 to FStyleFileList.Count - 1 do
    if CompareText(AStyleName, FStyleFileList[i]) = 0 then
    begin
      Result := TQJson(FStyleFileList.Objects[i]);
      Exit;
    end;

  if StrLIComp(@AStyleName[1], CStylePrefix, Length(CStylePrefix)) = 0 then
  begin
    rs := nil;
    try
      sResName := RightStr(AStyleName, Length(AStyleName) - Length(CStylePrefix));
      try
        rs := TResourceStream.Create(HInstance, sResName, RT_RCDATA);
      except
        Result := nil;
        Exit;
      end;

      Result := TQJson.Create;
      Result.LoadFromStream(rs);
      FStyleFileList.AddObject(AStyleName, Result);
    finally
      FreeAndNil(rs);
    end;
  end
  else
  begin
    if not FileExists(AStyleName) then
    begin
      Result := nil;
      Exit;
    end;

    Result := TQJson.Create;
    Result.LoadFromFile(AStyleName);
    FStyleFileList.AddObject(AStyleName, Result);
  end;
end;

initialization
  TScintilla.Init;

finalization
  TScintilla.UnInit;

end.
