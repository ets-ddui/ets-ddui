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
  ScintillaConst, ScintillaLexerConst, UDictionary;

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
    procedure Assign(ASource: TPersistent); override;
    procedure BackupData; virtual; abstract; //窗口销毁前，将窗口句柄中的值回写到成员变量中
    procedure UpdateData; virtual; abstract; //窗口创建后，将成员变量中的值设到窗口句柄中
  end;

  TItemType = (itText, itView, itMarker);
  TScintillaItems = array[TItemType] of TScintillaItemBase;

  TScintillaMargin = (smLineNumber, smSymbol, smFold{, smText, smOther});
  TScintillaMargins = set of TScintillaMargin;
  //Marker编号定义(可用值区间[0, 24]，[25, 31]已被Scintilla的代码折叠使用)
  TScintillaSymbol = (ssBreakPoint, ssCurrentLine, ssLowLight, ssHighLight);
  TScintillaSymbols = set of TScintillaSymbol;
  TScintillaMarker = class(TScintillaItemBase)
  private
    FMargins: TScintillaMargins;
    FSymbol: TDictionary;
    function DoCreate: TPersistent;
    function GetMargins: TScintillaMargins;
    procedure SetMargins(const AValue: TScintillaMargins);
    function GetSymbol(ALine: Integer): TScintillaSymbols;
    procedure SetSymbol(ALine: Integer; const AValue: TScintillaSymbols);
  protected
    procedure AssignTo(ADest: TPersistent); override;
  public
    constructor Create(AOwner: TScintilla); override;
    destructor Destroy; override;
    procedure BackupData; override;
    procedure UpdateData; override;
    property Symbol[ALine: Integer]: TScintillaSymbols read GetSymbol write SetSymbol; default;
  published
    property Margins: TScintillaMargins read GetMargins write SetMargins default [smSymbol];
  end;

  TScintillaText = class(TScintillaItemBase)
  private
    FCodePage: Word;
    FReadOnly: Boolean;
    FUseTab: Boolean;
    FValue: String;
    procedure SetCodePage(const AValue: Word);
    function GetCount: Integer;
    function GetLines(ALine: Integer): String;
    procedure SetLines(ALine: Integer; const AValue: String);
    procedure SetReadOnly(const AValue: Boolean);
    function GetValue: String;
    procedure SetUseTab(const AValue: Boolean);
    procedure SetValue(const AValue: String);
    function GetIsDirty: Boolean;
  protected
    procedure AssignTo(ADest: TPersistent); override;
  public
    constructor Create(AOwner: TScintilla); override;
    procedure BackupData; override;
    procedure UpdateData; override;
    procedure LoadFromFile(const AFileName: String);
    procedure LoadFromStream(AStream: TStream);
    procedure SavePoint;
    property Lines[ALine: Integer]: String read GetLines write SetLines;
  published
    property CodePage: Word read FCodePage write SetCodePage default 0;
    property Count: Integer read GetCount;
    property IsDirty: Boolean read GetIsDirty;
    property ReadOnly: Boolean read FReadOnly write SetReadOnly default False;
    property UseTab: Boolean read FUseTab write SetUseTab default True;
    property Value: String read GetValue write SetValue;
  end;

  TScintillaView = class(TScintillaItemBase)
  private
    FConfig: TQJson; //FConfig是对TScintilla.FStyleFileList中的对象的引用，不对引用对象的生命周期进行管理
    FLanguage: TLanguage;
    FShowWhiteSpace: Boolean;
    FStyleFile: String;
    FTabSize: Integer;
    FWrap: TWrapStyle;
    procedure ApplyStyle;
    procedure SetLanguageByExt(AExt: String);
    procedure SetLanguage(const AValue: TLanguage);
    procedure SetShowWhiteSpace(const AValue: Boolean);
    procedure SetStyleFile(const AValue: String);
    procedure SetTabSize(const AValue: Integer);
    procedure SetWrap(const AValue: TWrapStyle);
  protected
    procedure AssignTo(ADest: TPersistent); override;
  public
    constructor Create(AOwner: TScintilla); override;
    procedure BackupData; override;
    procedure UpdateData; override;
    function GetStyleConfig(APath: String): String;
  published
    property Language: TLanguage read FLanguage write SetLanguage default lagNone;
    property ShowWhiteSpace: Boolean read FShowWhiteSpace write SetShowWhiteSpace default False;
    property StyleFile: String read FStyleFile write SetStyleFile;
    property TabSize: Integer read FTabSize write SetTabSize default 8;
    {TODO: 启用换行后，均会导致中文乱码}
    property Wrap: TWrapStyle read FWrap write SetWrap default wsNone;
  end;

  TChangeType = (ctAdd, ctDelete);
  //ALine从0开始计数，APos从1开始计数(和String类型的索引保持一致)
  TOnScintillaChanging = procedure (ASender: TObject; AType: TChangeType;
    ALine, APos, ALen: Integer; var AText: String) of object;
  TOnScintillaChanged = procedure (ASender: TObject; AType: TChangeType;
    ALine, APos, ALen: Integer; AText: String) of object;
  TOnScintillaClick = procedure (ASender: TObject; ALine, APos: Integer) of object;
  TOnScintillaMarginClick = procedure (ASender: TObject; AMargin: TScintillaMargin;
    ALine: Integer; AShift: TShiftState) of object;
  TOnScintillaMouse = procedure (ASender: TObject; AButton: TMouseButton; AShift: TShiftState; ALine, APos: Integer) of object;
  TOnScintillaMouseMove = procedure (ASender: TObject; AShift: TShiftState; ALine, APos: Integer) of object;
  TOnScintillaSavePointChanged = procedure (AModified: Boolean) of object;
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
    FCore: TWinControl;
    FItems: TScintillaItems;
    FOnChanged: TOnScintillaChanged;
    FOnChanging: TOnScintillaChanging;
    FOnClick: TOnScintillaClick;
    FOnDblClick: TOnScintillaClick;
    FOnMarginClick: TOnScintillaMarginClick;
    FOnMouseDown: TOnScintillaMouse;
    FOnMouseMove: TOnScintillaMouseMove;
    FOnMouseUp: TOnScintillaMouse;
    FOnSavePointChanged: TOnScintillaSavePointChanged;
    procedure WMNotify(var AMessage: TWMNotify); message WM_NOTIFY;
    function GetMarker: TScintillaMarker;
    procedure SetMarker(const AValue: TScintillaMarker);
    function GetText: TScintillaText;
    procedure SetText(const AValue: TScintillaText);
    function GetView: TScintillaView;
    procedure SetView(const AValue: TScintillaView);
  protected
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
    procedure BackupData;
    procedure UpdateData;
  published
    property Align;
    property Anchors;
    property Marker: TScintillaMarker read GetMarker write SetMarker;
    property Text: TScintillaText read GetText write SetText;
    property View: TScintillaView read GetView write SetView;
    property OnChanging: TOnScintillaChanging read FOnChanging write FOnChanging;
    property OnChanged: TOnScintillaChanged read FOnChanged write FOnChanged;
    property OnClick: TOnScintillaClick read FOnClick write FOnClick;
    property OnDblClick: TOnScintillaClick read FOnDblClick write FOnDblClick;
    property OnMarginClick: TOnScintillaMarginClick read FOnMarginClick write FOnMarginClick;
    property OnMouseDown: TOnScintillaMouse read FOnMouseDown write FOnMouseDown;
    property OnMouseMove: TOnScintillaMouseMove read FOnMouseMove write FOnMouseMove;
    property OnMouseUp: TOnScintillaMouse read FOnMouseUp write FOnMouseUp;
    property OnSavePointChanged: TOnScintillaSavePointChanged read FOnSavePointChanged write FOnSavePointChanged;
  end;

implementation

{$R *.res}

function ToColor(AValue: String): Integer;
begin
  if AValue[1] = '#' then
    AValue[1] := '$';
  Result := StringToColor(AValue);
end;

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

type
  //Scintilla的通知消息直接发送给了父窗口，Scintilla本身不会收到这些通知消息，
  //因此，将Scintilla抽离出来，单独封装成控件TScintillaCore，
  //TScintilla则提供对通知消息的处理
  TScintillaCore = class(TWinControl)
  private
    procedure WMGetDlgCode(var AMessage: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMPaint(var AMessage: TWMPaint); message WM_PAINT;
    function GetContainer: TScintilla;
    function DefaultPerform(AMessage: Cardinal; AWParam, ALParam: Integer): Longint;
  protected
    procedure CreateParams(var AParams: TCreateParams); override;
    procedure CreateWnd; override;
    procedure DestroyWnd; override;
    procedure WndProc(var AMessage: TMessage); override;
  end;

{ TScintillaCore }

procedure TScintillaCore.CreateParams(var AParams: TCreateParams);
begin
  inherited CreateParams(AParams);

  if TScintilla.FScintillaModule <> 0 then
  begin
    AParams.WindowClass.hInstance := TScintilla.FScintillaModule;
    CreateSubClass(AParams, 'Scintilla');
  end;
end;

procedure TScintillaCore.CreateWnd;
var
  it: TItemType;
begin
  inherited;

  //DefaultPerform(SCI_SETBUFFEREDDRAW, 0, 0); //调试Scintilla绘图逻辑时，打开此注释，以关闭双缓存机制

  GetContainer.UpdateData;
  for it := Low(TItemType) to High(TItemType) do
    GetContainer.FItems[it].UpdateData;
end;

procedure TScintillaCore.DestroyWnd;
var
  it: TItemType;
begin
  for it := Low(TItemType) to High(TItemType) do
    GetContainer.FItems[it].BackupData;
  GetContainer.BackupData;

  inherited;
end;

function TScintillaCore.DefaultPerform(AMessage: Cardinal; AWParam, ALParam: Integer): Longint;
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

function TScintillaCore.GetContainer: TScintilla;
begin
  Result := TScintilla(Parent);
end;

procedure TScintillaCore.WMGetDlgCode(var AMessage: TWMGetDlgCode);
begin
  inherited;

  //Scintilla只返回了DLGC_WANTALLKEYS or DLGC_HASSETSEL，导致键盘方向键无法正常处理
  //Delphi在TApplication.IsKeyMsg中会将消息转发给TWinControl.CNKeyDown，并根据其结果判断是否将消息转发给控件处理
  AMessage.Result := AMessage.Result or DLGC_WANTARROWS or DLGC_WANTTAB; // or DLGC_WANTCHARS;
end;

procedure TScintillaCore.WMPaint(var AMessage: TWMPaint);
begin
  AMessage.DC := 0;
  DefaultHandler(AMessage);
end;

procedure TScintillaCore.WndProc(var AMessage: TMessage);
begin
  case AMessage.Msg of
    WM_MOUSEFIRST..WM_MOUSELAST: GetContainer.WindowProc(AMessage);
  end;

  inherited;
end;

{ TScintillaItemBase }

constructor TScintillaItemBase.Create(AOwner: TScintilla);
begin
  inherited Create;

  FOwner := AOwner;
end;

procedure TScintillaItemBase.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TScintillaItemBase) then
  begin
    if TScintillaItemBase(ASource).HandleAllocated then
      TScintillaItemBase(ASource).BackupData;

    inherited;

    if HandleAllocated then
      UpdateData;
  end
  else
    inherited;
end;

function TScintillaItemBase.HandleAllocated: Boolean;
begin
  Result := FOwner.FCore.HandleAllocated;
end;

function TScintillaItemBase.Perform(AMessage: Cardinal; AWParam, ALParam: Integer): Longint;
begin
  Result := FOwner.DefaultPerform(AMessage, AWParam, ALParam);
end;

{ TScintillaMarker }

type
  TSymbol = class(TPersistent)
  strict private
    FValue: TScintillaSymbols;
  private
    function GetMarker: Integer;
  protected
    procedure AssignTo(ADest: TPersistent); override;
  public
    constructor Create(AValue: Integer); reintroduce; overload;
    constructor Create(AValue: TScintillaSymbols); reintroduce; overload;
    property Value: TScintillaSymbols read FValue write FValue;
    property Marker: Integer read GetMarker;
  published
  public
    class function SetToInt(AValue: TScintillaSymbols): Integer;
    class function IntToSet(AValue: Integer): TScintillaSymbols;
    class function Key(AKey: Integer): String;
  end;

class function TSymbol.SetToInt(AValue: TScintillaSymbols): Integer;
var
  ss: TScintillaSymbol;
begin
  Result := 0;
  for ss := Low(TScintillaSymbol) to High(TScintillaSymbol) do
    if ss in AValue then
      Result := Result or (1 shl Ord(ss));
end;

class function TSymbol.IntToSet(AValue: Integer): TScintillaSymbols;
var
  ss: TScintillaSymbol;
begin
  Result := [];
  for ss := Low(TScintillaSymbol) to High(TScintillaSymbol) do
    if (AValue and (1 shl Ord(ss))) <> 0 then
      Include(Result, ss);
end;

class function TSymbol.Key(AKey: Integer): String;
begin
  Result := Format('%10d', [AKey]);
end;

constructor TSymbol.Create(AValue: Integer);
begin
  FValue := IntToSet(AValue);
end;

constructor TSymbol.Create(AValue: TScintillaSymbols);
begin
  FValue := AValue;
end;

procedure TSymbol.AssignTo(ADest: TPersistent);
begin
  if not Assigned(ADest) or not (ADest is TSymbol) then
  begin
    inherited;
    Exit;
  end;

  TSymbol(ADest).FValue := FValue;
end;

function TSymbol.GetMarker: Integer;
begin
  Result := SetToInt(FValue);
end;

constructor TScintillaMarker.Create(AOwner: TScintilla);
begin
  inherited;

  FMargins := [smSymbol];
  FSymbol := TDictionary.Create(DoCreate);
end;

destructor TScintillaMarker.Destroy;
begin
  FreeAndNil(FSymbol);

  inherited;
end;

procedure TScintillaMarker.AssignTo(ADest: TPersistent);
begin
  if not Assigned(ADest) or not (ADest is TScintillaMarker) then
  begin
    inherited;
    Exit;
  end;

  TScintillaMarker(ADest).FMargins := FMargins;
  TScintillaMarker(ADest).FSymbol.Assign(FSymbol);
end;

procedure TScintillaMarker.BackupData;
var
  iMask, iLine: Integer;
  ss: TScintillaSymbol;
begin
  iMask := 0;
  for ss := Low(TScintillaSymbol) to High(TScintillaSymbol) do
    iMask := iMask or (1 shl Ord(ss));

  FSymbol.Clear;
  iLine := 0;
  while True do
  begin
    iLine := Perform(SCI_MARKERNEXT, iLine, iMask);
    if iLine < 0 then
      Exit;

    FSymbol.AddObject(TSymbol.Key(iLine), TSymbol.Create(Perform(SCI_MARKERGET, iLine)));
    Inc(iLine);
  end;
end;

procedure TScintillaMarker.UpdateData;
  procedure setStyle(AMarker: Integer; AName, AValue: String); overload;
  begin
    if 0 = CompareText(AName, 'fore') then
      Perform(SCI_MARKERSETFORE, AMarker, ToColor(AValue))
    else if 0 = CompareText(AName, 'back') then
      Perform(SCI_MARKERSETBACK, AMarker, ToColor(AValue))
    else if 0 = CompareText(AName, 'backselected') then
      Perform(SCI_MARKERSETBACKSELECTED, AMarker, ToColor(AValue))
    else if (AName <> '') or (AValue <> '') then
      raise Exception.Create(Format('无法识别的样式(%d, %s, %s)', [AMarker, AName, AValue]));
  end;
  procedure setStyle(AMarker: Integer; AStyle: String); overload;
  var
    i: Integer;
  begin
    if AStyle = '' then
      Exit;

    with TScintillaStringList.Create do
      try
        StrictDelimiter := True;
        NameValueSeparator := ':';
        Delimiter := ',';
        DelimitedText := AStyle;
        for i := 0 to Count - 1 do
          setStyle(AMarker, Names[i], ValueFromIndex[i]);
      finally
        Free;
      end;
  end;
  procedure defineMarker(AMarker: Integer; AType: Integer; AConfigPath: String);
  begin
    Perform(SCI_MARKERDEFINE, AMarker, AType);
    setStyle(AMarker, Owner.View.GetStyleConfig(AConfigPath));
  end;
var
  i: Integer;
begin
  //定义Symbol编号
  defineMarker(Ord(ssBreakPoint), SC_MARK_CIRCLE, 'colour.marker.breakpoint');
  defineMarker(Ord(ssCurrentLine), SC_MARK_SHORTARROW, 'colour.marker.currentline');
  defineMarker(Ord(ssLowLight), SC_MARK_BACKGROUND, 'colour.marker.lowlight');
  defineMarker(Ord(ssHighLight), SC_MARK_BACKGROUND, 'colour.marker.highlight');

  //设置Symbol栏参数
  Perform(SCI_SETMARGINSENSITIVEN, Ord(smSymbol), 1);

  //定义Fold按钮
  defineMarker(SC_MARKNUM_FOLDEROPEN, SC_MARK_BOXMINUS, 'colour.marker.folder');
  defineMarker(SC_MARKNUM_FOLDER, SC_MARK_BOXPLUS, 'colour.marker.folder');
  defineMarker(SC_MARKNUM_FOLDERSUB, SC_MARK_VLINE, 'colour.marker.folder');
  defineMarker(SC_MARKNUM_FOLDERTAIL, SC_MARK_LCORNER, 'colour.marker.folder');
  defineMarker(SC_MARKNUM_FOLDEREND, SC_MARK_BOXPLUSCONNECTED, 'colour.marker.folder');
  defineMarker(SC_MARKNUM_FOLDEROPENMID, SC_MARK_BOXMINUSCONNECTED, 'colour.marker.folder');
  defineMarker(SC_MARKNUM_FOLDERMIDTAIL, SC_MARK_TCORNER, 'colour.marker.folder');

  //设置Fold栏参数
  Perform(SCI_SETPROPERTY, Integer(@('fold'#0)[1]), Integer(@('1'#0)[1]));
  Perform(SCI_SETPROPERTY, Integer(@('fold.comment'#0)[1]), Integer(@('1'#0)[1]));
  Perform(SCI_SETMARGINMASKN, Ord(smFold), Integer(SC_MASK_FOLDERS));
  Perform(SCI_SETAUTOMATICFOLD, SC_AUTOMATICFOLD_CLICK);
  Perform(SCI_SETMARGINSENSITIVEN, Ord(smFold), 1);

  //设置Fold栏背景色
  //Fold的背景色是通过Bitmap绘制的，Bitmap由SCI_SETFOLDMARGINCOLOUR、SCI_SETFOLDMARGINHICOLOUR两种颜色交叉绘制而成
  Perform(SCI_SETFOLDMARGINCOLOUR, 1, ToColor(Owner.View.GetStyleConfig('colour.marker.folderbackground[0]')));
  Perform(SCI_SETFOLDMARGINHICOLOUR, 1, ToColor(Owner.View.GetStyleConfig('colour.marker.folderbackground[1]')));

  Perform(SCI_MARKERENABLEHIGHLIGHT, 0);

  //将TScintillaMarker成员中的值，同步到窗口句柄中
  SetMargins(FMargins);

  for i := 0 to FSymbol.Count - 1 do
    Perform(SCI_MARKERADDSET, StrToInt(FSymbol[i]), TSymbol(FSymbol.Objects[i]).Marker);
  FSymbol.Clear; //数据同步后，后续操作以窗口句柄为准，FSymbol可清空(节省内存)
end;

function TScintillaMarker.DoCreate: TPersistent;
begin
  Result := TSymbol.Create([]);
end;

function TScintillaMarker.GetMargins: TScintillaMargins;
var
  sm: TScintillaMargin;
  iWidth: Integer;
begin
  if not HandleAllocated then
  begin
    Result := FMargins;
    Exit;
  end;

  Result := [];
  for sm := Low(TScintillaMargin) to High(TScintillaMargin) do
  begin
    iWidth := Perform(SCI_GETMARGINWIDTHN, Ord(sm));
    if iWidth > 0 then
      Include(Result, sm);
  end;
end;

procedure TScintillaMarker.SetMargins(const AValue: TScintillaMargins);
  function calcLineNumberWidth: Integer;
  var
    iLineCount: Integer;
    str: String;
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

    str := str + #0;

    Result := 4 + Perform(SCI_TEXTWIDTH, STYLE_LINENUMBER, Integer(@str[1]));
  end;
var
  sm: TScintillaMargin;
  smsOldMargins: TScintillaMargins;
begin
  FMargins := AValue;
  if not HandleAllocated then
    Exit;

  smsOldMargins := GetMargins;
  for sm := Low(TScintillaMargin) to High(TScintillaMargin) do
  begin
    if not (sm in FMargins) and (sm in smsOldMargins) then
      Perform(SCI_SETMARGINWIDTHN, Ord(sm), 0)
    else if (sm in FMargins) and not (sm in smsOldMargins) then
    begin
      case sm of
        smLineNumber: Perform(SCI_SETMARGINWIDTHN, Ord(sm), calcLineNumberWidth);
        smSymbol: Perform(SCI_SETMARGINWIDTHN, Ord(sm), 16);
        smFold: Perform(SCI_SETMARGINWIDTHN, Ord(sm), 14);
      end;
    end;
  end;
end;

function TScintillaMarker.GetSymbol(ALine: Integer): TScintillaSymbols;
var
  i: Integer;
begin
  Result := [];
  if not HandleAllocated then
  begin
    i := FSymbol.IndexOf(TSymbol.Key(ALine));
    if i >= 0 then
      Result := TSymbol(FSymbol.Objects[i]).Value;

    Exit;
  end;

  Result := TSymbol.IntToSet(Perform(SCI_MARKERGET, ALine));
end;

procedure TScintillaMarker.SetSymbol(ALine: Integer; const AValue: TScintillaSymbols);
var
  i: Integer;
begin
  if not HandleAllocated then
  begin
    i := FSymbol.IndexOf(TSymbol.Key(ALine));
    if i >= 0 then
      TSymbol(FSymbol.Objects[i]).Value := AValue
    else
      FSymbol.AddObject(TSymbol.Key(ALine), TSymbol.Create(AValue));

    Exit;
  end;

  Perform(SCI_MARKERADDSET, ALine, TSymbol.SetToInt(AValue));
end;

{ TScintillaText }

constructor TScintillaText.Create(AOwner: TScintilla);
begin
  inherited;

  FUseTab := True;
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
end;

procedure TScintillaText.BackupData;
begin
  //读取文本的操作均以Scintilla中记录的为准，只有当窗口未创建时，才会读取FValue的值，
  //因此，当窗口释放时，需同步最新的值到FValue中，保证在窗口重新创建时，FValue的值可以正确初始化
  FValue := GetValue;
end;

procedure TScintillaText.UpdateData;
begin
  SetCodePage(FCodePage);
  SetReadOnly(FReadOnly); //必须在SetText之后调用(Scintilla在ReadOnly为True时，不允许设置值)
  SetUseTab(FUseTab);
  SetValue(FValue);
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
  SavePoint;
end;

procedure TScintillaText.SavePoint;
begin
  Perform(SCI_SETSAVEPOINT);
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

function TScintillaText.GetIsDirty: Boolean;
begin
  Result := Perform(SCI_GETMODIFY) <> 0;
end;

function TScintillaText.GetLines(ALine: Integer): String;
var
  iLen: Integer;
begin
  Result := '';
  if (ALine < 0) or (ALine >= GetCount) then
    Exit;

  iLen := Perform(SCI_LINELENGTH, ALine);
  SetLength(Result, iLen);
  Perform(SCI_GETLINE, ALine, Integer(@Result[1]));

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

procedure TScintillaText.SetLines(ALine: Integer; const AValue: String);
begin
  if (ALine < 0) or (ALine >= GetCount) then
    Exit;

  //选择指定行的文本(按文档描述，SCI_SETSEL会移动光标位置，而SCI_SETCURRENTPOS、SCI_SETANCHOR不会)
  Perform(SCI_SETTARGETSTART, Perform(SCI_POSITIONFROMLINE, ALine));
  Perform(SCI_SETTARGETEND, Perform(SCI_GETLINEENDPOSITION, ALine)); //文档说SCI_GETLINEENDPOSITION不包含换行符

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
  FConfig := nil;
  FTabSize := 8;
end;

procedure TScintillaView.AssignTo(ADest: TPersistent);
begin
  if not Assigned(ADest) or not (ADest is TScintillaView) then
  begin
    inherited;
    Exit;
  end;

  TScintillaView(ADest).FLanguage := FLanguage;
  TScintillaView(ADest).FShowWhiteSpace := FShowWhiteSpace;
  TScintillaView(ADest).FStyleFile := FStyleFile;
  TScintillaView(ADest).FTabSize := FTabSize;
  TScintillaView(ADest).FWrap := FWrap;
end;

procedure TScintillaView.BackupData;
begin
end;

procedure TScintillaView.UpdateData;
begin
  SetLanguage(FLanguage);
  SetShowWhiteSpace(FShowWhiteSpace);
  SetTabSize(FTabSize);
  SetWrap(FWrap);
end;

procedure TScintillaView.ApplyStyle;
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
      Perform(SCI_STYLESETFORE, AStyle, ToColor(AValue))
    else if 0 = CompareText(AName, 'back') then
      Perform(SCI_STYLESETBACK, AStyle, ToColor(AValue))
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
  procedure setStyle(AStyle: Integer; ALanguage: TLanguage); overload;
  var
    i: Integer;
    sLexer, sConfig: String;
  begin
    if ALanguage = lagNone then
      sLexer := '*'
    else
      sLexer := GetStyleConfig(Format('languages.%s.lexer', [CLanguage[ALanguage]]));

    sConfig := GetStyleConfig(Format('lexers.%s.style.%d', [sLexer, AStyle]));
    if sConfig = '' then
      Exit;

    with TScintillaStringList.Create do
      try
        StrictDelimiter := True;
        NameValueSeparator := ':';
        Delimiter := ',';
        DelimitedText := sConfig;
        for i := 0 to Count - 1 do
          setStyle(AStyle, Names[i], ValueFromIndex[i]);
      finally
        Free;
      end;

    Perform(SCI_STYLESETCHARACTERSET, AStyle, SC_CHARSET_DEFAULT);
  end;
var
  iStyle, iMaxStyle: Integer;
begin
  //SCI_STYLERESETDEFAULT是将默认样式改为初始值(即修改的STYLE_DEFAULT的值，各要素写的固定值)
  //SCI_STYLECLEARALL是将STYLE_DEFAULT的值，覆盖到其他样式中(覆盖后，又将STYLE_LINENUMBER、STYLE_CALLTIP的颜色设置成了固定值)
  //所以，这里的逻辑要先设置STYLE_DEFAULT的样式，然后，调用SCI_STYLECLEARALL将其他样式初始化为默认值，再有针对的设置特定样式的值
  setStyle(STYLE_DEFAULT, lagNone);
  if FLanguage <> lagNone then
    setStyle(STYLE_DEFAULT, FLanguage);
  //DefaultPerform(SCI_STYLERESETDEFAULT);
  Perform(SCI_STYLECLEARALL);

  for iStyle := 0 to STYLE_DEFAULT - 1 do
    setStyle(iStyle, lagNone);

  iMaxStyle := (1 shl Perform(SCI_GETSTYLEBITS)) - 1;
  for iStyle := STYLE_DEFAULT + 1 to iMaxStyle do
    setStyle(iStyle, lagNone);

  if FLanguage <> lagNone then
  begin
    for iStyle := 0 to STYLE_DEFAULT - 1 do
      setStyle(iStyle, FLanguage);

    for iStyle := STYLE_DEFAULT + 1 to iMaxStyle do
      setStyle(iStyle, FLanguage);
  end;

  Owner.Invalidate;
end;

function TScintillaView.GetStyleConfig(APath: String): String;
var
  sTemp: String;
  iBegin, iEnd: Integer;
begin
  Result := '';

  if not Assigned(FConfig) then
  begin
    FConfig := TScintilla.GetStyle(FStyleFile);
    if not Assigned(FConfig) then
      Exit;
  end;

  iBegin := 1;
  sTemp := FConfig.ValueByPath(APath, '');
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

    Result := Result + GetStyleConfig(MidStr(sTemp, iBegin, iEnd - iBegin));
    iBegin := iEnd + 1;
  end;
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

procedure TScintillaView.SetLanguage(const AValue: TLanguage);
var
  iKeyword: Integer;
  sKeyword, sLexer: String;
begin
  FLanguage := AValue;
  if not HandleAllocated then
    Exit;

  if AValue = lagNone then
    Perform(SCI_SETLEXER, SCLEX_NULL)
  else
  begin
    sLexer := GetStyleConfig(Format('languages.%s.lexer', [CLanguage[FLanguage]]));
    if sLexer = '' then
      Exit;

    Perform(SCI_SETLEXERLANGUAGE, 0, Integer(@sLexer[1]));

    for iKeyword := 0 to 8 do
    begin
      sKeyword := GetStyleConfig(Format('languages.%s.keywords.%d', [CLanguage[FLanguage], iKeyword]));
      if sKeyword <> '' then
        Perform(SCI_SETKEYWORDS, iKeyword, Integer(@sKeyword[1]));
    end;
  end;

  ApplyStyle;
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
  FConfig := nil;
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

  FCore := TScintillaCore.Create(Self);
  FCore.Parent := Self;
  FCore.Align := alClient;

  InitItems(FItems);
  for it := Low(TItemType) to High(TItemType) do
  begin
    if Assigned(FItems[it]) then
      Continue;

    case it of
      itText: FItems[it] := TScintillaText.Create(Self);
      itView: FItems[it] := TScintillaView.Create(Self);
      itMarker: FItems[it] := TScintillaMarker.Create(Self);
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

  FreeAndNil(FCore);

  inherited;
end;

procedure TScintilla.BackupData;
begin
end;

procedure TScintilla.UpdateData;
begin
  //设置触发SCN_MODIFIED消息(TScintilla.WMNotify)的事件类型
  DefaultPerform(SCI_SETMODEVENTMASK,
    SC_MOD_BEFOREINSERT or SC_MOD_BEFOREDELETE
      or SC_MOD_INSERTTEXT or SC_MOD_DELETETEXT);
end;

procedure TScintilla.InitItems(var AItems: TScintillaItems);
begin
  //在此函数中，提供子类对FItems中存放对象的自定义创建操作
end;

function TScintilla.DefaultPerform(AMessage: Cardinal; AWParam, ALParam: Integer): Longint;
begin
  Result := TScintillaCore(FCore).DefaultPerform(AMessage, AWParam, ALParam);
end;

function TScintilla.MouseToCell(APoint: TPoint): TPoint;
var
  iPosition: Integer;
begin
  iPosition := DefaultPerform(SCI_POSITIONFROMPOINT, APoint.X, APoint.Y);

  Result.X := DefaultPerform(SCI_LINEFROMPOSITION, iPosition);
  Result.Y := iPosition - DefaultPerform(SCI_POSITIONFROMLINE, Result.X) + 1;
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
    pt := MouseToCell(ScreenToClient(Mouse.CursorPos));
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

procedure TScintilla.WMNotify(var AMessage: TWMNotify);
type
  PSciNotification = ^TSciNotification;
  TSciNotification = record
    FNotifyHeader         : TNMHdr;           // 此字段用于与TWMNotify.NMHdr保持兼容(可以理解为类继承)
    position              : Integer;          // SCN_STYLENEEDED, SCN_MODIFIED
    ch                    : Integer;          // SCN_CHARADDED, SCN_KEY
    modifiers             : Integer;          // SCN_KEY
    modificationType      : Integer;          // SCN_MODIFIED
    text                  : PChar;            // SCN_MODIFIED
    length                : Integer;          // SCN_MODIFIED
    linesAdded            : Integer;          // SCN_MODIFIED
//{$ifdef MACRO_SUPPORT}
    message               : Integer;          // SCN_MACRORECORD
    wParam                : Integer;          // SCN_MACRORECORD
    lParam                : Integer;          // SCN_MACRORECORD
//{$endif}
    line                  : Integer;          // SCN_MODIFIED
    foldLevelNow          : Integer;          // SCN_MODIFIED
    foldLevelPrev         : Integer;          // SCN_MODIFIED
    margin                : Integer;          // SCN_MARGINCLICK
    listType              : Integer;          // SCN_USERLISTSELECTION
    x                     : Integer;          // SCN_DWELLSTART, SCN_DWELLEND
    y                     : Integer;          // SCN_DWELLSTART, SCN_DWELLEND
    token                 : Integer;          // SCN_MODIFIED with SC_MOD_CONTAINER
    annotationLinesAdded  : Integer;          // SCN_MODIFIED with SC_MOD_CHANGEANNOTATION
    updated               : Integer;          // SCN_UPDATEUI
  end;
  procedure doSavePointChanged(ANotification: PSciNotification);
  begin
    if Assigned(FOnSavePointChanged) then
      FOnSavePointChanged(AMessage.NMHdr.code = SCN_SAVEPOINTLEFT);
  end;
  procedure doModified(ANotification: PSciNotification);
  var
    bIsChanging: Boolean;
    ct: TChangeType;
    iLine, iPos: Integer;
    strText: String;
  begin
    if (SC_MOD_BEFOREINSERT and ANotification.modificationType) <> 0 then
    begin
      bIsChanging := True;
      ct := ctAdd;
    end
    else if (SC_MOD_BEFOREDELETE and ANotification.modificationType) <> 0 then
    begin
      bIsChanging := True;
      ct := ctDelete;
    end
    else if (SC_MOD_INSERTTEXT and ANotification.modificationType) <> 0 then
    begin
      bIsChanging := False;
      ct := ctAdd;
    end
    else if (SC_MOD_DELETETEXT and ANotification.modificationType) <> 0 then
    begin
      bIsChanging := False;
      ct := ctDelete;
    end
    else
    begin
      Exit;
    end;

    if bIsChanging and not Assigned(FOnChanging) then
      Exit
    else if not bIsChanging and not Assigned(FOnChanged) then
      Exit;

    iLine := DefaultPerform(SCI_LINEFROMPOSITION, ANotification.position);
    iPos := ANotification.position - DefaultPerform(SCI_POSITIONFROMLINE, iLine) + 1;
    strText := '';
    if (ct = ctAdd) and Assigned(ANotification.text) then
      strText := Copy(ANotification.text, 0, ANotification.length);

    if bIsChanging then
      FOnChanging(Self, ct, iLine, iPos, ANotification.length, strText)
    else
      FOnChanged(Self, ct, iLine, iPos, ANotification.length, strText);
  end;
  procedure doMarginClick(ANotification: PSciNotification);
  var
    ss: TShiftState;
  begin
    if not Assigned(FOnMarginClick) then
      Exit;

    ss := [];
    if (SCMOD_SHIFT and ANotification.modifiers) <> 0 then
      Include(ss, ssShift);
    if (SCMOD_CTRL and ANotification.modifiers) <> 0 then
      Include(ss, ssCtrl);
    if (SCMOD_ALT and ANotification.modifiers) <> 0 then
      Include(ss, ssAlt);

    FOnMarginClick(Self,
      TScintillaMargin(ANotification.margin),
      DefaultPerform(SCI_LINEFROMPOSITION, ANotification.position),
      ss);
  end;
begin
  case AMessage.NMHdr.code of
    //Save Point只表示文本是否有被改过(多次修改，仅第一次触发消息)，常用于更新文件的修改状态
    //另一个消息SCN_MODIFIED，在每次文本或样式发生变化时，都会触发
    SCN_SAVEPOINTREACHED, SCN_SAVEPOINTLEFT: doSavePointChanged(PSciNotification(AMessage.NMHdr));
    SCN_MODIFIED: doModified(PSciNotification(AMessage.NMHdr));
    SCN_MARGINCLICK: doMarginClick(PSciNotification(AMessage.NMHdr));
  end;
end;

function TScintilla.GetMarker: TScintillaMarker;
begin
  Result := TScintillaMarker(FItems[itMarker]);
end;

procedure TScintilla.SetMarker(const AValue: TScintillaMarker);
begin
  FItems[itMarker].Assign(AValue);
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
