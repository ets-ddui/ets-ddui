{
  Copyright (c) 2021-2031 Steven Shi

  ETS_DDUI For Delphi，让漂亮界面做起来更简单。

  本UI库是开源自由软件，您可以遵照 MIT 协议，修改和发布此程序。
  发布此库的目的是希望其有用，但不做任何保证。
  如果将本库用于商业项目，由于本库中的Bug，而引起的任何风险及损失，本作者不承担任何责任。

  开源地址: https://github.com/ets-ddui/ets-ddui
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

  FUchardetEntry = function (AValue: PAnsiChar; ALen: Integer): Integer; stdcall;

  TScintilla = class(TWinControl)
  private
    class var FScintillaModule: THandle;
    class var FUchardetModule: THandle;
    class var FUchardetEntry: FUchardetEntry;
    class var FStyleFileList: TStringList;
    class procedure Init;
    class procedure UnInit;
    class function GetStyle(AStyleName: String): TQJson;
  private
    FStyleFile: String;
    FShowLineNumber: Boolean;
    FCodePage: Word;
    FLanguage: TLanguage;
    FWrap: TWrapStyle;
    FText: String;
    FReadOnly: Boolean;
    FFoldIndicator: Boolean;
    FTabSize: Integer;
    FUseTab: Boolean;
    FShowWhiteSpace: Boolean;
    procedure WMGetDlgCode(var AMessage: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMPaint(var AMessage: TWMPaint); message WM_PAINT;
    procedure ApplyStyle;
    procedure SetCodePage(const AValue: Word);
    procedure SetReadOnly(const AValue: Boolean);
    procedure SetShowLineNumber(const AValue: Boolean);
    procedure SetWrap(const AValue: TWrapStyle);
    procedure SetLanguage(const AValue: TLanguage);
    procedure SetStyleFile(const AValue: String);
    function GetText: String;
    procedure SetText(const AValue: String);
    procedure SetFoldIndicator(const AValue: Boolean);
    procedure SetTabSize(const AValue: Integer);
    procedure SetUseTab(const AValue: Boolean);
    procedure SetShowWhiteSpace(const AValue: Boolean);
  protected
    procedure CreateParams(var AParams: TCreateParams); override;
    procedure CreateWnd; override;
    procedure DestroyWnd; override;
    function DefaultPerform(AMessage: Cardinal; AWParam: Longint = 0; ALParam: Longint = 0): Longint;
  public
    constructor Create(AOwner: TComponent); override;
    procedure LoadFromFile(const AFileName: String);
    procedure LoadFromStream(AStream: TStream);
  published
    property Align;
    property Anchors;
    property CodePage: Word read FCodePage write SetCodePage default 0;
    property FoldIndicator: Boolean read FFoldIndicator write SetFoldIndicator default False;
    property Language: TLanguage read FLanguage write SetLanguage default lagNone;
    property ReadOnly: Boolean read FReadOnly write SetReadOnly default False;
    property ShowLineNumber: Boolean read FShowLineNumber write SetShowLineNumber default False;
    property ShowWhiteSpace: Boolean read FShowWhiteSpace write SetShowWhiteSpace default False;
    property StyleFile: String read FStyleFile write SetStyleFile;
    property TabSize: Integer read FTabSize write SetTabSize default 8;
    property Text: String read GetText write SetText;
    property UseTab: Boolean read FUseTab write SetUseTab default True;
    {TODO: 启用换行后，均会导致中文乱码}
    property Wrap: TWrapStyle read FWrap write SetWrap default wsNone;
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

{ TScintilla }

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

procedure TScintilla.ApplyStyle;
  function toColor(AValue: String): Integer;
  begin
    if AValue[1] = '#' then
      AValue[1] := '$';
    Result := StringToColor(AValue);
  end;
  procedure setStyle(AStyle: Integer; AName, AValue: String); overload;
  begin
    if 0 = CompareText(AName, 'italics') then
      DefaultPerform(SCI_STYLESETITALIC, AStyle, StrToIntDef(AValue, 1))
    else if 0 = CompareText(AName, 'bold') then
    begin
      if (AValue = '0') then
        DefaultPerform(SCI_STYLESETWEIGHT, AStyle, SC_WEIGHT_NORMAL)
      else
        DefaultPerform(SCI_STYLESETWEIGHT, AStyle, SC_WEIGHT_BOLD);
    end
    else if 0 = CompareText(AName, 'weight') then
      DefaultPerform(SCI_STYLESETWEIGHT, AStyle, StrToIntDef(AValue, 0))
    else if 0 = CompareText(AName, 'font') then
      DefaultPerform(SCI_STYLESETFONT, AStyle, Integer(@AValue[1]))
    else if 0 = CompareText(AName, 'fore') then
      DefaultPerform(SCI_STYLESETFORE, AStyle, toColor(AValue))
    else if 0 = CompareText(AName, 'back') then
      DefaultPerform(SCI_STYLESETBACK, AStyle, toColor(AValue))
    else if 0 = CompareText(AName, 'size') then
      DefaultPerform(SCI_STYLESETSIZEFRACTIONAL, AStyle, Trunc(StrToFloatDef(AValue, 0) * SC_FONT_SIZE_MULTIPLIER))
    else if 0 = CompareText(AName, 'eolfilled') then
      DefaultPerform(SCI_STYLESETEOLFILLED, AStyle, StrToIntDef(AValue, 1))
    else if 0 = CompareText(AName, 'underlined') then
      DefaultPerform(SCI_STYLESETUNDERLINE, AStyle, StrToIntDef(AValue, 1))
    else if 0 = CompareText(AName, 'case') then
    begin
      if AValue = 'u' then
        DefaultPerform(SCI_STYLESETCASE, AStyle, SC_CASE_UPPER)
      else if AValue = 'l' then
        DefaultPerform(SCI_STYLESETCASE, AStyle, SC_CASE_LOWER)
      else
        DefaultPerform(SCI_STYLESETCASE, AStyle, SC_CASE_MIXED);
    end
    else if 0 = CompareText(AName, 'visible') then
      DefaultPerform(SCI_STYLESETVISIBLE, AStyle, StrToIntDef(AValue, 1))
    else if 0 = CompareText(AName, 'changeable') then
      DefaultPerform(SCI_STYLESETCHANGEABLE, AStyle, StrToIntDef(AValue, 1))
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
          DefaultPerform(SCI_STYLESETCHARACTERSET, AStyle, SC_CHARSET_DEFAULT);
      finally
        Free;
      end;
  end;
var
  json: TQJson;
  iStyle, iMaxStyle: Integer;
begin
  json := GetStyle(FStyleFile);
  if not Assigned(json) then
    Exit;

  //SCI_STYLERESETDEFAULT是将默认样式改为初始值(即修改的STYLE_DEFAULT的值，只不过各要素的值在代码中写死了，来源为)
  //SCI_STYLECLEARALL是将STYLE_DEFAULT的值，覆盖到其他样式中
  //所以，这里的逻辑要先设置STYLE_DEFAULT的样式，然后，调用SCI_STYLECLEARALL将其他样式初始化为默认值，再有针对的设置特定样式的值
  setStyle(STYLE_DEFAULT, lagNone, json);
  //DefaultPerform(SCI_STYLERESETDEFAULT);
  DefaultPerform(SCI_STYLECLEARALL);

  for iStyle := 0 to STYLE_DEFAULT - 1 do
    setStyle(iStyle, lagNone, json);

  iMaxStyle := (1 shl DefaultPerform(SCI_GETSTYLEBITS)) - 1;
  for iStyle := STYLE_DEFAULT + 1 to iMaxStyle do
    setStyle(iStyle, lagNone, json);

  if FLanguage <> lagNone then
  begin
    setStyle(STYLE_DEFAULT, FLanguage, json);
    DefaultPerform(SCI_STYLECLEARALL);

    for iStyle := 0 to STYLE_DEFAULT - 1 do
      setStyle(iStyle, FLanguage, json);

    for iStyle := STYLE_DEFAULT + 1 to iMaxStyle do
      setStyle(iStyle, FLanguage, json);
  end;

  Invalidate;
end;

constructor TScintilla.Create(AOwner: TComponent);
begin
  inherited;

  FStyleFile := CDefaultStyle;
  FTabSize := 8;
  FUseTab := True;
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
begin
  inherited;

  //DefaultPerform(SCI_SETBUFFEREDDRAW, 0); //调试Scintilla绘图逻辑时，打开此注释，以关闭双缓存机制

  SetCodePage(FCodePage);
  SetLanguage(FLanguage);
  //SetFoldIndicator(FFoldIndicator); //移到SetLanguage中调用
  SetShowLineNumber(FShowLineNumber);
  SetShowWhiteSpace(FShowWhiteSpace);
  SetTabSize(FTabSize);
  SetText(FText);
  SetUseTab(FUseTab);
  SetReadOnly(FReadOnly); //必须在SetText之后调用(Scintilla在ReadOnly为True时，不允许设置值)
  SetWrap(FWrap);
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

procedure TScintilla.DestroyWnd;
begin
  //读取文本的操作均以Scintilla中记录的为准，只有当窗口未创建时，才会读取FText的值，
  //因此，当窗口释放时，需同步最新的值到FText中，保证在窗口重新创建时，FText的值可以正确初始化
  FText := GetText;

  inherited;
end;

procedure TScintilla.LoadFromFile(const AFileName: String);
  function calcLanguage(AExt: String): TLanguage;
  var
    iLanguage, iExt: Integer;
    json, jsonLanguage, jsonExt: TQJson;
  begin
    Result := lagNone;

    json := GetStyle(FStyleFile);
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
var
  i: Integer;
  stm: TStream;
begin
  i := LastDelimiter('.\/', AFileName);
  if (i > 0) and (AFileName[i] = '.') then
    SetLanguage(calcLanguage(Copy(AFileName, i + 1, MaxInt)));

  stm := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(stm);
  finally
    FreeAndNil(stm);
  end;
end;

procedure TScintilla.LoadFromStream(AStream: TStream);
var
  iLen: Integer;
  sText: String;
begin
  iLen := AStream.Size - AStream.Position;
  SetLength(sText, iLen);
  AStream.Read(sText[1], iLen);
  SetText(sText);
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

procedure TScintilla.SetCodePage(const AValue: Word);
begin
  FCodePage := AValue;
  if not HandleAllocated then
    Exit;

  DefaultPerform(SCI_SETCODEPAGE, FCodePage);
end;

procedure TScintilla.SetFoldIndicator(const AValue: Boolean);
  procedure defineMarker(AMarker: Integer; AType: Integer; AFore, ABack, ABackSelected: TColor);
  begin
    DefaultPerform(SCI_MARKERDEFINE, AMarker, AType);
    DefaultPerform(SCI_MARKERSETFORE, AMarker, AFore);
    DefaultPerform(SCI_MARKERSETBACK, AMarker, ABack);
    DefaultPerform(SCI_MARKERSETBACKSELECTED, AMarker, ABackSelected);
  end;
begin
  FFoldIndicator := AValue;
  if not HandleAllocated then
    Exit;

  if FFoldIndicator then
  begin
    //设置折叠栏的宽度
    DefaultPerform(SCI_SETMARGINWIDTHN, 2, 14);

    //设置折叠基本参数
    DefaultPerform(SCI_SETPROPERTY, Integer(@('fold'#0)[1]), Integer(@('1'#0)[1]));
    DefaultPerform(SCI_SETPROPERTY, Integer(@('fold.comment'#0)[1]), Integer(@('1'#0)[1]));
    DefaultPerform(SCI_SETMARGINMASKN, 2, Integer(SC_MASK_FOLDERS));
    DefaultPerform(SCI_SETAUTOMATICFOLD, SC_AUTOMATICFOLD_CLICK);
    DefaultPerform(SCI_SETMARGINSENSITIVEN, 2, 1);

    //设置折叠按钮的外观
    defineMarker(SC_MARKNUM_FOLDEROPEN, SC_MARK_BOXMINUS, $FFFFFF, $808080, $FF);
    defineMarker(SC_MARKNUM_FOLDER, SC_MARK_BOXPLUS, $FFFFFF, $808080, $FF);
    defineMarker(SC_MARKNUM_FOLDERSUB, SC_MARK_VLINE, $FFFFFF, $808080, $FF);
    defineMarker(SC_MARKNUM_FOLDERTAIL, SC_MARK_LCORNER, $FFFFFF, $808080, $FF);
    defineMarker(SC_MARKNUM_FOLDEREND, SC_MARK_BOXPLUSCONNECTED, $FFFFFF, $808080, $FF);
    defineMarker(SC_MARKNUM_FOLDEROPENMID, SC_MARK_BOXMINUSCONNECTED, $FFFFFF, $808080, $FF);
    defineMarker(SC_MARKNUM_FOLDERMIDTAIL, SC_MARK_TCORNER, $FFFFFF, $808080, $FF);

    DefaultPerform(SCI_MARKERENABLEHIGHLIGHT, 0);
  end
  else
    DefaultPerform(SCI_SETMARGINWIDTHN, 2, 0);
end;

procedure TScintilla.SetLanguage(const AValue: TLanguage);
var
  iKeyword: Integer;
  json: TQJson;
  sKeyword, sLexer: String;
begin
  FLanguage := AValue;
  if not HandleAllocated then
    Exit;

  if AValue = lagNone then
    DefaultPerform(SCI_SETLEXER, SCLEX_NULL)
  else
  begin
    json := GetStyle(FStyleFile);
    if not Assigned(json) then
      Exit;

    sLexer := GetJsonPath(json, Format('languages.%s.lexer', [CLanguage[FLanguage]]));
    if sLexer = '' then
      Exit;

    DefaultPerform(SCI_SETLEXERLANGUAGE, 0, Integer(@sLexer[1]));

    for iKeyword := 0 to 8 do
    begin
      sKeyword := GetJsonPath(json, Format('languages.%s.keywords.%d', [CLanguage[FLanguage], iKeyword]));
      if sKeyword <> '' then
        DefaultPerform(SCI_SETKEYWORDS, iKeyword, Integer(@sKeyword[1]));
    end;
  end;

  SetFoldIndicator(FFoldIndicator);

  ApplyStyle;
end;

procedure TScintilla.SetReadOnly(const AValue: Boolean);
begin
  FReadOnly := AValue;
  if not HandleAllocated then
    Exit;

  DefaultPerform(SCI_SETREADONLY, Ord(AValue));
end;

procedure TScintilla.SetShowLineNumber(const AValue: Boolean);
var
  iLineCount, iWidth: Integer;
  str: String;
begin
  FShowLineNumber := AValue;
  if not HandleAllocated then
    Exit;

  if AValue then
  begin
    iLineCount := DefaultPerform(SCI_GETLINECOUNT);
    while iLineCount > 0 do
    begin
      iLineCount := iLineCount div 10;
      str := str + '9';
    end;

    while Length(str) < 4 do
    begin
      str := str + '9';
    end;

    iWidth := 4 + DefaultPerform(SCI_TEXTWIDTH, STYLE_LINENUMBER, Integer(@str[1]));

    DefaultPerform(SCI_SETMARGINWIDTHN, 0, iWidth);
  end
  else
  begin
    DefaultPerform(SCI_SETMARGINWIDTHN, 0, 0);
  end;
end;

procedure TScintilla.SetShowWhiteSpace(const AValue: Boolean);
begin
  FShowWhiteSpace := AValue;
  if not HandleAllocated then
    Exit;

  //空格的显示模式有3种，SCWS_VISIBLEAFTERINDENT的显示模式暂时不提供支持
  if FShowWhiteSpace then
    DefaultPerform(SCI_SETVIEWWS, SCWS_VISIBLEALWAYS)
  else
    DefaultPerform(SCI_SETVIEWWS, SCWS_INVISIBLE);
end;

procedure TScintilla.SetStyleFile(const AValue: String);
begin
  FStyleFile := AValue;
  if not HandleAllocated then
    Exit;

  ApplyStyle;
end;

procedure TScintilla.SetTabSize(const AValue: Integer);
begin
  if AValue <= 0 then
    Exit;

  FTabSize := AValue;
  if not HandleAllocated then
    Exit;

  //从SciTE的代码来看，SCI_SETTABWIDTH管理Tab的外观特征，
  //而SCI_SETINDENT与Tab、Backspace按键每次增加、减少的空格数有关
  DefaultPerform(SCI_SETTABWIDTH, FTabSize);
  DefaultPerform(SCI_SETINDENT, FTabSize);
end;

function TScintilla.GetText: String;
var
  iLen: Integer;
begin
  if not HandleAllocated then
  begin
    Result := FText;
    Exit;
  end;

  iLen := DefaultPerform(SCI_GETTEXTLENGTH);
  //由于Scintilla会在最后补字符串空结尾符，因此，需多分配一个字符，获取完内容后，再截掉
  SetLength(Result, iLen + 1);
  DefaultPerform(SCI_GETTEXT, iLen + 1, Integer(@Result[1]));
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

procedure TScintilla.SetText(const AValue: String);
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
begin
  if not HandleAllocated then
  begin
    FText := AValue;
    Exit;
  end;

  if AValue = '' then
  begin
    FText := '';
    SetCodePage(0);
  end
  else if (Length(AValue) >= 2) and (AValue[1] = #$FE) and (AValue[2] = #$FF) then //大端
  begin
    FText := unicodeToUtf8(BigToLittleEndian);
    SetCodePage(65001);
  end
  else if (Length(AValue) >= 2) and (AValue[1] = #$FF) and (AValue[2] = #$FE) then //小端
  begin
    FText := unicodeToUtf8(NoTranslate);
    SetCodePage(65001);
  end
  else if (Length(AValue) >= 3) and (AValue[1] = #$EF) and (AValue[2] = #$BB) and (AValue[3] = #$BF) then //UTF-8
  begin
    FText := RightStr(AValue, Length(AValue) - 3);
    SetCodePage(65001);
  end
  else
  begin
    FText := AValue;
    if Assigned(FUchardetEntry) then
      SetCodePage(FUchardetEntry(@FText[1], Length(FText)));
  end;

  DefaultPerform(SCI_BEGINUNDOACTION);
  try
    if FReadOnly then
      DefaultPerform(SCI_SETREADONLY, 0);

    DefaultPerform(SCI_CLEARALL);

    DefaultPerform(SCI_ALLOCATE, Length(FText) + 1000);
    DefaultPerform(SCI_ADDTEXT, Length(FText), Integer(@FText[1]));
  finally
    if FReadOnly then
      DefaultPerform(SCI_SETREADONLY, 1);
    
    DefaultPerform(SCI_ENDUNDOACTION);
  end;
end;

procedure TScintilla.SetUseTab(const AValue: Boolean);
begin
  FUseTab := AValue;
  if not HandleAllocated then
    Exit;

  DefaultPerform(SCI_SETUSETABS, Ord(FUseTab));
end;

procedure TScintilla.SetWrap(const AValue: TWrapStyle);
begin
  FWrap := AValue;
  if not HandleAllocated then
    Exit;

  DefaultPerform(SCI_SETWRAPMODE, Ord(AValue));
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
