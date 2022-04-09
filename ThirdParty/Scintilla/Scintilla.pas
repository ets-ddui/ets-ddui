{
  Copyright (c) 2021-2031 Steven Shi

  ETS_DDUI For Delphi，让漂亮界面做起来更简单。

  本UI库是开源自由软件，您可以遵照 MIT 协议，修改和发布此程序。
  发布此库的目的是希望其有用，但不做任何保证。
  如果将本库用于商业项目，由于本库中的Bug，而引起的任何风险及损失，本作者不承担任何责任。

  开源地址: https://github.com/ets-ddui/ets-ddui
            https://gitee.com/ets-ddui/ets-ddui
  开源协议: The MIT License (MIT)
  作者邮箱: xinghun87@163.com
  官方博客：https://blog.csdn.net/xinghun61
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
    procedure Backup; virtual; abstract; //窗口销毁前，将窗口句柄中的值回写到成员变量中
    procedure Update; virtual; abstract; //窗口创建后，将成员变量中的值设到窗口句柄中
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
    {TODO: 启用换行后，均会导致中文乱码}
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
  //读取文本的操作均以Scintilla中记录的为准，只有当窗口未创建时，才会读取FValue的值，
  //因此，当窗口释放时，需同步最新的值到FValue中，保证在窗口重新创建时，FValue的值可以正确初始化
  FValue := GetValue;
end;

procedure TScintillaText.Update;
begin
  SetCodePage(FCodePage);
  SetReadOnly(FReadOnly); //必须在SetText之后调用(Scintilla在ReadOnly为True时，不允许设置值)
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

  //截取Windows换行
  if iLen > 1 then
  begin
    if (Result[iLen - 1] = #$D) and (Result[iLen] = #$A) then
    begin
      SetLength(Result, iLen - 2);
      Exit;
    end;
  end;

  //截取Unix或Mac换行
  if iLen > 0 then
  begin
    if (Result[iLen] = #$D) or (Result[iLen] = #$A) then //这里用的or
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

  //选择指定行的文本(按文档描述，SCI_SETSEL会移动光标位置，而SCI_SETCURRENTPOS、SCI_SETANCHOR不会)
  Perform(SCI_SETTARGETSTART, Perform(SCI_POSITIONFROMLINE, AIndex));
  Perform(SCI_SETTARGETEND, Perform(SCI_GETLINEENDPOSITION, AIndex)); //文档说SCI_GETLINEENDPOSITION不包含换行符

  //替换选中的文本(相当于把AIndex指定行的内容替换为AValue)
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
  //由于Scintilla会在最后补字符串空结尾符，因此，需多分配一个字符，获取完内容后，再截掉
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
    //对于小端编码，高字节部分会存到UTF-8的低字节中
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
  else if (Length(AValue) >= 2) and (AValue[1] = #$FE) and (AValue[2] = #$FF) then //大端
  begin
    FValue := unicodeToUtf8(BigToLittleEndian);
    SetCodePage(65001);
  end
  else if (Length(AValue) >= 2) and (AValue[1] = #$FF) and (AValue[2] = #$FE) then //小端
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
  //SetFoldIndicator(FFoldIndicator); //移到SetLanguage中调用
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
      raise Exception.Create(Format('无法识别的样式(%d, %s, %s)', [AStyle, AName, AValue]));
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

  //SCI_STYLERESETDEFAULT是将默认样式改为初始值(即修改的STYLE_DEFAULT的值，只不过各要素的值在代码中写死了，来源为)
  //SCI_STYLECLEARALL是将STYLE_DEFAULT的值，覆盖到其他样式中
  //所以，这里的逻辑要先设置STYLE_DEFAULT的样式，然后，调用SCI_STYLECLEARALL将其他样式初始化为默认值，再有针对的设置特定样式的值
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
    //设置折叠栏的宽度
    Perform(SCI_SETMARGINWIDTHN, 2, 14);

    //设置折叠基本参数
    Perform(SCI_SETPROPERTY, Integer(@('fold'#0)[1]), Integer(@('1'#0)[1]));
    Perform(SCI_SETPROPERTY, Integer(@('fold.comment'#0)[1]), Integer(@('1'#0)[1]));
    Perform(SCI_SETMARGINMASKN, 2, Integer(SC_MASK_FOLDERS));
    Perform(SCI_SETAUTOMATICFOLD, SC_AUTOMATICFOLD_CLICK);
    Perform(SCI_SETMARGINSENSITIVEN, 2, 1);

    //设置折叠按钮的外观
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

  //空格的显示模式有3种，SCWS_VISIBLEAFTERINDENT的显示模式暂时不提供支持
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

  //从SciTE的代码来看，SCI_SETTABWIDTH管理Tab的外观特征，
  //而SCI_SETINDENT与Tab、Backspace按键每次增加、减少的空格数有关
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
      raise Exception.Create('TScintilla创建失败');
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
  //在此函数中，提供子类对FItems中存放对象的自定义创建操作
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

  //DefaultPerform(SCI_SETBUFFEREDDRAW, 0); //调试Scintilla绘图逻辑时，打开此注释，以关闭双缓存机制

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

  //Scintilla只返回了DLGC_WANTALLKEYS or DLGC_HASSETSEL，导致键盘方向键无法正常处理
  //Delphi在TApplication.IsKeyMsg中会将消息转发给TWinControl.CNKeyDown，并根据其结果判断是否将消息转发给控件处理
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
