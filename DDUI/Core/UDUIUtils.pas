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
unit UDUIUtils;

interface

uses
  Windows, Classes, SysUtils, Controls, qjson;

type
  TControlsList = class(TList)
  public
    //TList的标准排序(TList.Sort)无法保证元素的顺序，改用归并排序重新实现
    procedure MergeSort(ACompare: TListSortCompare);
  end;

  TWriterHook = class
  private
    type
      PJmp = ^TJmp;
      TJmp = packed record
        FCode: Byte;
        FOffset: Longint;
      end;
      PData = ^TData;
      TData = record
        FInstance, FAncestor: TComponent;
      end;
    class var
      FList: TList;
      FBackupInstruction: TJmp;
      FHookCount: Integer;
      FHookAddress: Pointer;
    class procedure Init;
    class procedure UnInit;
    class function IndexOf(AComponent: TComponent): Integer;
    class procedure Delete(AIndex: Integer);
  private
    procedure NewWriteProperties(AInstance: TPersistent);
  public
    class procedure Hook;
    class procedure UnHook;
    class procedure RegisterComponent(AComponent, AAncestor: TComponent);
    class procedure UnRegisterComponent(AComponent: TComponent);
  end;

function JsonToComponent(var AObject: TObject; AJson: TQJson; AParent: TObject): Boolean;
function ComponentToJson(var AJson: TQJson; AObject: TObject): Boolean;

implementation

uses
  TypInfo, Variants, UDUICore, UDUIForm, UTool;

{ TControlsList }

procedure TControlsList.MergeSort(ACompare: TListSortCompare);
  procedure merge(ASrc1, ASrc1End, ASrc2, ASrc2End, ADest: PPointer);
  begin
    while True do
    begin
      if (Int64(ASrc1) < Int64(ASrc1End)) and (Int64(ASrc2) < Int64(ASrc2End)) then
      begin
        if ACompare(ASrc1^, ASrc2^) <= 0 then
        begin
          ADest^ := ASrc1^;
          ASrc1 := Pointer(Int64(ASrc1) + SizeOf(Pointer));
        end
        else
        begin
          ADest^ := ASrc2^;
          ASrc2 := Pointer(Int64(ASrc2) + SizeOf(Pointer));
        end;
      end
      else if Int64(ASrc1) < Int64(ASrc1End) then
      begin
        ADest^ := ASrc1^;
        ASrc1 := Pointer(Int64(ASrc1) + SizeOf(Pointer));
      end
      else if Int64(ASrc2) < Int64(ASrc2End) then
      begin
        ADest^ := ASrc2^;
        ASrc2 := Pointer(Int64(ASrc2) + SizeOf(Pointer));
      end
      else
        Exit;

      ADest := Pointer(Int64(ADest) + SizeOf(Pointer));
    end;
  end;
  procedure exchange(var ALeft, ARight: PPointerList);
  var
    pplTemp: PPointerList;
  begin
    pplTemp := ALeft;
    ALeft := ARight;
    ARight := pplTemp;
  end;
var
  pplBack, pplLeft, pplRight: PPointerList;
  iBegin, iCount: Integer;
  plTempBack: array[0..31] of Pointer; //如果元素较少，则不从堆中分配内存，改用堆栈实现，提升性能
begin
  if Count = 0 then
    Exit;

  if Count > 32 then
    pplBack := AllocMem(Count * SizeOf(Pointer))
  else
    pplBack := @plTempBack[0];

  try
    pplLeft := List;
    pplRight := pplBack;
    iCount := 1;
    while iCount < Count do
    begin
      iBegin := 0;
      while iBegin < Count do
      begin
        if (iBegin + 2 * iCount) <= Count then //2个区段均完整
          merge(@pplLeft^[iBegin], @pplLeft^[iBegin + iCount],
            @pplLeft^[iBegin + iCount], @pplLeft^[iBegin + 2 * iCount],
            @pplRight^[iBegin])
        else if (iBegin + iCount) < Count then //第1区段完整，第2区段不完整(不含“=”，则第2个区段至少含1个元素)
          merge(@pplLeft^[iBegin], @pplLeft^[iBegin + iCount],
            @pplLeft^[iBegin + iCount], @pplLeft^[Count],
            @pplRight^[iBegin])
        else //第1区段不完整(此时没有第2区段，直接拷贝)
          System.Move(pplLeft^[iBegin], pplRight^[iBegin], (Count - iBegin) * SizeOf(Pointer));
             
        iBegin := iBegin + 2 * iCount;
      end;

      iCount := iCount * 2;
      exchange(pplLeft, pplRight);
    end;

    if pplLeft = pplBack then
      System.Move(pplLeft^, List^, Count * SizeOf(Pointer));
  finally
    if Count > 32 then
      FreeMem(pplBack);
  end;
end;

{ TWriterHook }

type
  TJsonPersistent = class(TPersistent)
    //定义此类仅是为了访问TPersistent中的DefineProperties函数，不要添加任何定义
  end;
  TWriterWrapper = class(TWriter)
    //定义此类仅是为了访问TWriter中的protected类型的函数，不要添加任何定义
  end;

class procedure TWriterHook.Init;
begin
  FList := TList.Create;
  FHookCount := 0;
  FHookAddress := nil;
end;

class procedure TWriterHook.UnInit;
begin
  while FList.Count > 0 do
    Delete(FList.Count - 1);

  FreeAndNil(FList);
end;

class function TWriterHook.IndexOf(AComponent: TComponent): Integer;
begin
  for Result := 0 to FList.Count - 1 do
    if PData(FList[Result]).FInstance = AComponent then
      Exit;

  Result := -1;
end;

class procedure TWriterHook.Delete(AIndex: Integer);
var
  p: PData;
begin
  if (AIndex < 0) or (AIndex >= FList.Count) then
    Exit;

  p := FList[AIndex];
  FList.Delete(AIndex);
  p^.FAncestor.Free;
  Dispose(p);
end;

class procedure TWriterHook.Hook;
var
  iNew, iOld: DWORD;
begin
  Inc(FHookCount);
  if FHookCount > 1 then
    Exit;

  FHookAddress := Pointer(@TWriterWrapper.WriteProperties);
  if PWord(FHookAddress)^ = $25FF then //如果UDUIUtils与Classes被编译到不同的dll中，这里取到的是远地址跳转指令，因此，需要根据跳转的目标地址，才能取到真正的TWriter.WriteProperties地址
  begin
    FHookAddress := PPointer(Int64(FHookAddress) + 2)^;
    FHookAddress := PPointer(FHookAddress)^;
  end;
  if PByte(FHookAddress)^ <> $55 then
  begin
    FHookAddress := nil;
    Exit;
  end;
  Move(FHookAddress^, FBackupInstruction, SizeOf(TJmp));

  iNew := PAGE_EXECUTE_READWRITE;
  if VirtualProtect(FHookAddress, SizeOf(TJmp), iNew, @iOld) then
    try
      with PJmp(FHookAddress)^ do
      begin
        FCode := $E9; //JMP
        FOffset := Longint(@TWriterHook.NewWriteProperties)
          - Longint(FHookAddress)
          - SizeOf(TJmp);
      end;
    finally
      VirtualProtect(FHookAddress, SizeOf(TJmp), iOld, @iNew);
    end;
end;

class procedure TWriterHook.UnHook;
var
  iNew, iOld: DWORD;
begin
  Dec(FHookCount);
  if FHookCount > 0 then
    Exit;

  if not Assigned(FHookAddress) then
    Exit;

  iNew := PAGE_EXECUTE_READWRITE;
  if VirtualProtect(FHookAddress, SizeOf(TJmp), iNew, @iOld) then
    try
      Move(FBackupInstruction, FHookAddress^, SizeOf(TJmp));
    finally
      VirtualProtect(FHookAddress, SizeOf(TJmp), iOld, @iNew);
    end;
end;

class procedure TWriterHook.RegisterComponent(AComponent, AAncestor: TComponent);
var
  i: Integer;
  p: PData;
begin
  i := IndexOf(AComponent);
  if i >= 0 then
  begin
    PData(FList[i])^.FAncestor := AAncestor;
    Exit;
  end;

  New(p);
  p^.FInstance := AComponent;
  p^.FAncestor := AAncestor;
  FList.Add(p);
end;

class procedure TWriterHook.UnRegisterComponent(AComponent: TComponent);
begin
  Delete(IndexOf(AComponent));
end;

procedure TWriterHook.NewWriteProperties(AInstance: TPersistent);
  procedure stdWriteProperties;
  var
    I, Count: Integer;
    PropInfo: PPropInfo;
    PropList: PPropList;
  begin
    Count := GetTypeData(AInstance.ClassInfo)^.PropCount;
    if Count > 0 then
    begin
      GetMem(PropList, Count * SizeOf(Pointer));
      try
        GetPropInfos(AInstance.ClassInfo, PropList);
        for I := 0 to Count - 1 do
        begin
          PropInfo := PropList^[I];
          if PropInfo = nil then
            Break;
          if IsStoredProp(AInstance, PropInfo) then
            TWriterWrapper(Self).WriteProperty(AInstance, PropInfo);
        end;
      finally
        FreeMem(PropList, Count * SizeOf(Pointer));
      end;
    end;
    TJsonPersistent(AInstance).DefineProperties(TWriter(Self));
  end;
var
  i: Integer;
  objAncestor: TPersistent;
  objRoot, objRootAncestor: TComponent;
begin
  i := IndexOf(TComponent(AInstance));
  if i < 0 then
  begin
    stdWriteProperties;
    Exit;
  end;

  objAncestor := TWriter(Self).Ancestor;
  objRoot := TWriter(Self).Root;
  objRootAncestor := TWriter(Self).RootAncestor;
  try
    TWriter(Self).Ancestor := PData(FList[i])^.FAncestor;
    TWriter(Self).Root := TComponent(AInstance).Owner;
    TWriter(Self).RootAncestor := PData(FList[i])^.FAncestor.Owner;

    stdWriteProperties;
  finally
    TWriter(Self).Ancestor := objAncestor;
    TWriter(Self).Root := objRoot;
    TWriter(Self).RootAncestor := objRootAncestor;
  end;
end;

var
  GStream: TStringStream;

type
  TJsonReader = class(TReader)
  end;

function SetProperty(AObject: TObject; AJson: TQJson): Boolean;
  function setInteger(AObject: TObject; APropInfo: PPropInfo; AValue: TQJson): Boolean;
  var
    iti: TIdentToInt;
    iValue: Integer;
  begin
    Result := False;

    if AValue.IsString then
    begin
      iti := FindIdentToInt(APropInfo^.PropType^);
      if not Assigned(iti) or not iti(AValue.Value, iValue) then
        Exit;
    end
    else
      iValue := AValue.AsInteger;

    SetOrdProp(AObject, APropInfo, iValue);
    Result := True;
  end;
  function setClass(AObject: TObject; APropInfo: PPropInfo; AValue: TQJson): Boolean;
  var
    co: TCollection;
    i: Integer;
    obj: TObject;
  begin
    Result := False;

    if AValue.IsNull then
      SetOrdProp(AObject, APropInfo, 0)
    else if AValue.IsArray then
    begin
      co := TCollection(GetOrdProp(AObject, APropInfo));
      co.BeginUpdate;
      try
        co.Clear;

        for i := 0 to AValue.Count - 1 do
        begin
          obj := co.Add;
          if not JsonToComponent(obj, AValue[i], nil) then
            Exit;
        end;
      finally
        co.EndUpdate;
      end;
    end
    else if AValue.IsObject then
    begin
      obj := TObject(GetOrdProp(AObject, APropInfo));
      if not JsonToComponent(obj, AValue, nil) then
        Exit;
    end;
    
    Result := True;
  end;
  function setMethod(AObject: TObject; APropInfo: PPropInfo; AValue: TQJson): Boolean;
  var
    me: TMethod;
  begin
    Result := False;

    if AValue.IsNull then
    begin
      me.Code := nil;
      me.Data := nil;
    end
    else
    begin
      Exit;
    end;

    SetMethodProp(AObject, APropInfo, me);
    Result := True;
  end;
  function setInterface(AObject: TObject; APropInfo: PPropInfo; AValue: TQJson): Boolean;
  var
    itf: IInterface;
  begin
    if AValue.IsNull then
    begin
      itf := nil;
      SetInterfaceProp(AObject, APropInfo, itf);
    end;

    Result := True;
  end;
var
  i: Integer;
  nd: TQJson;
  pi: PPropInfo;
begin
  Result := False;

  for i := 0 to AJson.Count - 1 do
  begin
    nd := AJson[i];
    pi := GetPropInfo(AObject, nd.Name);
    if not Assigned(pi) then
    begin
      WriteView('属性[%s]不存在，其值为[%s]', [nd.Name, nd.Value]);
      Continue;
    end;

    {TODO: 补充类型处理}
    case pi^.PropType^.Kind of
      tkInteger:
        if not setInteger(AObject, pi, nd) then
          Exit;
      tkClass:
        if not setClass(AObject, pi, nd) then
          Exit;
      tkMethod:
        if not setMethod(AObject, pi, nd) then
          Exit;
      tkInterface:
        if not setInterface(AObject, pi, nd) then
          Exit;
      tkEnumeration:
        SetOrdProp(AObject, pi, GetEnumValue(pi^.PropType^, nd.Value));
      tkVariant:
        SetVariantProp(AObject, pi, nd.Value);
    else
      SetPropValue(AObject, pi, nd.Value);
    end;
  end;

  Result := True;
end;

function JsonToComponent(var AObject: TObject; AJson: TQJson; AParent: TObject): Boolean;
var
  i: Integer;
  nd: TQJson;
  cc: TComponentClass;
  objChild: TObject;
begin
  Result := False;

  if not Assigned(AObject) then
  begin
    if AJson.HasChild('__class__', nd) then
    begin
      try
        cc := TComponentClass(FindClass(nd.Value));
      except
        on e: EClassNotFound do
        begin
          WriteView('无法找到类信息(%s)', [nd.Value]);
          Exit;
        end;
      end;

      if Assigned(AParent) and not (AParent is TComponent) then
      begin
        WriteView('父对象(%s)不是TComponent类型', [AParent.ClassName]);
        Exit;
      end;

      AObject := cc.Create(TComponent(AParent));
      if AObject is TDUIBase then
      begin
        if AParent is TDUIForm then
          TDUIBase(AObject).Parent := TWinControl(AParent)
        else if AParent is TDUIBase then
          TDUIBase(AObject).DUIParent := TDUIBase(AParent)
        else
        begin
          AObject.Free;
          WriteView('父对象(%s)类型不合法', [AParent.ClassName]);
          Exit;
        end;
      end
      else if (AObject is TControl) and (AParent is TWinControl) then
        TControl(AObject).Parent := TWinControl(AParent);
    end
    else if AJson.HasChild('__reference__', nd) then
    begin
      nd := AJson.Root.ItemByPath(nd.Value + '.' + AJson.Name);
      if not Assigned(nd) then
      begin
        WriteView('无法找到引用类型(%s.%s)', [nd.Value, AJson.Name]);
        Exit;
      end;

      if not JsonToComponent(AObject, nd, AParent) then
        Exit;
    end
    else
    begin
      WriteView('无法创建对象实例(%s/%s)', [AJson.Path, AJson.Name]);
      Exit;
    end;
  end;

  if AJson.HasChild('__property__', nd) then
  begin
    if not nd.IsObject then
    begin
      WriteView('属性不合法(%s/%s)', [nd.Path, nd.Name]);
      Exit;
    end;

    if not SetProperty(AObject, nd) then
    begin
      WriteView('属性初始化失败(%s/%s)', [nd.Path, nd.Name]);
      Exit;
    end;
  end;

  if AJson.HasChild('__custom_property__', nd) then
  begin
    GStream.Position := 0; //保证后面的修改会覆盖整个流的数据
    GStream.WriteString(Base64ToMem(nd.Value));
    GStream.Position := 0; //写完后，当前位置会被移到最后，而后续的TJsonReader需要从头开始读取

    with TJsonReader.Create(GStream, 4096) do
      try
        while not EndOfList do
          ReadProperty(TPersistent(AObject));
      finally
        Free;
      end;
  end;

  if AJson.HasChild('__child__', nd) then
  begin
    if not nd.IsArray then
    begin
      WriteView('子对象不合法(%s/%s)', [nd.Path, nd.Name]);
      Exit;
    end;

    for i := 0 to nd.Count - 1 do
    begin
      objChild := nil;
      if not JsonToComponent(objChild, nd[i], AObject) then
        Exit;
    end;
  end;

  Result := True;
end;

type
  TJsonWriter = class(TWriter)
  strict private
    class var FWriter: TJsonWriter;
  public
    class function GetWriter: TJsonWriter;
    class procedure UnInit;
  end;

  TComponentToJson = class
  strict private
    class procedure WriteOrdProp(AJson: TQJson; AObject, AReference: TObject; APropInfo: PPropInfo);
    class procedure WriteInt64Prop(AJson: TQJson; AObject, AReference: TObject; APropInfo: PPropInfo);
    class procedure WriteFloatProp(AJson: TQJson; AObject, AReference: TObject; APropInfo: PPropInfo);
    class procedure WriteStrProp(AJson: TQJson; AObject, AReference: TObject; APropInfo: PPropInfo);
    class procedure WriteObjectProp(AJson: TQJson; AObject, AReference: TObject; APropInfo: PPropInfo);
    class procedure WriteVariantProp(AJson: TQJson; AObject, AReference: TObject; APropInfo: PPropInfo);
    class procedure WriteProperty(AJson: TQJson; AObject, AReference: TObject; APropInfo: PPropInfo);
  public
    class function ComponentToJsonImpl(var AJson: TQJson; AObject, AReference: TObject): Boolean;
  end;

{ TJsonWriter }

class function TJsonWriter.GetWriter: TJsonWriter;
begin
  if not Assigned(FWriter) then
    FWriter := TJsonWriter.Create(GStream, 4096);

  Result := FWriter;
end;

class procedure TJsonWriter.UnInit;
begin
  FreeAndNil(FWriter);
end;

{ TComponentToJson }

class procedure TComponentToJson.WriteOrdProp(AJson: TQJson; AObject, AReference: TObject; APropInfo: PPropInfo);
  procedure writeSet(AValue: Longint);
  var
    i: Integer;
    piBaseType: PTypeInfo;
    nd: TQJson;
  begin
    nd := AJson.Add(APropInfo^.Name, jdtArray);

    piBaseType := GetTypeData(APropInfo^.PropType^)^.CompType^;
    for i := 0 to SizeOf(TIntegerSet) * 8 - 1 do
      if i in TIntegerSet(AValue) then
        nd.Add('', GetSetElementName(piBaseType, i), jdtString);
  end;
var
  vValue: Longint;
begin
  vValue := GetOrdProp(AObject, APropInfo);
  if Assigned(AReference) then
  begin
    if vValue = GetOrdProp(AReference, APropInfo) then
      Exit;
  end;

  case APropInfo^.PropType^.Kind of
    tkInteger:
      AJson.Add(APropInfo^.Name, vValue);
    tkChar:
      AJson.Add(APropInfo^.Name, Chr(vValue), jdtString);
    tkWChar:
      AJson.Add(APropInfo^.Name, WideChar(vValue), jdtString);
    tkSet:
      writeSet(vValue);
    tkEnumeration:
      AJson.Add(APropInfo^.Name, GetEnumName(APropInfo^.PropType^, vValue), jdtString);
  end;
end;

class procedure TComponentToJson.WriteInt64Prop(AJson: TQJson; AObject, AReference: TObject; APropInfo: PPropInfo);
var
  vValue: Int64;
begin
  vValue := GetInt64Prop(AObject, APropInfo);
  if Assigned(AReference) then
  begin
    if vValue = GetInt64Prop(AReference, APropInfo) then
      Exit;
  end;

  AJson.Add(APropInfo^.Name, vValue);
end;

class procedure TComponentToJson.WriteFloatProp(AJson: TQJson; AObject, AReference: TObject; APropInfo: PPropInfo);
var
  vValue: Extended;
begin
  vValue := GetFloatProp(AObject, APropInfo);
  if Assigned(AReference) then
  begin
    if vValue = GetFloatProp(AReference, APropInfo) then
      Exit;
  end;

  AJson.Add(APropInfo^.Name, vValue);
end;

class procedure TComponentToJson.WriteStrProp(AJson: TQJson; AObject, AReference: TObject; APropInfo: PPropInfo);
var
  vValue: WideString;
begin
  vValue := GetWideStrProp(AObject, APropInfo);
  if Assigned(AReference) then
  begin
    if vValue = GetWideStrProp(AReference, APropInfo) then
      Exit;
  end;

  AJson.Add(APropInfo^.Name, vValue, jdtString);
end;

class procedure TComponentToJson.WriteObjectProp(AJson: TQJson; AObject, AReference: TObject; APropInfo: PPropInfo);
  function isBlank(ANode: TQJson): Boolean;
  var
    nd: TQJson;
    i, iArray: Integer;
  begin
    Result := False;

    if ANode.HasChild('__property__', nd) then
    begin
      for i := 0 to nd.Count - 1 do
        case nd[i].DataType of
          jdtObject:
          begin
            if not isBlank(nd[i]) then
              Exit;
          end;
          jdtArray:
          begin
            for iArray := 0 to nd[i].Count - 1 do
              if not isBlank(nd[i][iArray]) then
                Exit;
          end;
        else
          Exit;
        end;
    end;

    if ANode.HasChild('__custom_property__', nd) then
      Exit;

    if ANode.HasChild('__child__', nd) then
    begin
      for i := 0 to nd.Count - 1 do
        if not isBlank(nd[i]) then
          Exit;
    end;

    Result := True;
  end;
var
  vValue, vReference, objItem: TObject;
  nd, ndItem: TQJson;
  i: Integer;
begin
  vValue := TObject(GetOrdProp(AObject, APropInfo));
  vReference := nil;
  if Assigned(AReference) then
    vReference := TObject(GetOrdProp(AReference, APropInfo));

  if vValue = vReference then
    Exit;

  if not Assigned(vValue) then
  begin
    AJson.Add(APropInfo^.Name, jdtNull);
    Exit;
  end
  else if vValue is TCollection then
  begin
    nd := nil;
    ndItem := nil;
    try
      nd := TQJson.Create(APropInfo^.Name, '[]', jdtArray);
      for i := 0 to TCollection(vValue).Count - 1 do
      begin
        ndItem := TQJson.Create('', '{}', jdtObject);
        objItem := nil;
        if Assigned(vReference) then
          objItem := TCollection(vReference).Items[i];

        if not ComponentToJsonImpl(ndItem, TCollection(vValue).Items[i], objItem) then
          Exit;

        if not isBlank(ndItem) then
        begin
          nd.Add(ndItem);
          ndItem := nil;
        end;

        FreeAndNil(ndItem);
      end;

      if nd.Count > 0 then
      begin
        AJson.Add(nd);
        nd := nil;
      end;
    finally
      FreeAndNil(nd);
      FreeAndNil(ndItem);
    end;
  end
  else
  begin
    nd := TQJson.Create(APropInfo^.Name, '{}', jdtObject);
    if not ComponentToJsonImpl(nd, vValue, vReference) then
      Exit;

    if not isBlank(nd) then
      AJson.Add(nd);
  end;
end;

class procedure TComponentToJson.WriteVariantProp(AJson: TQJson; AObject, AReference: TObject; APropInfo: PPropInfo);
var
  vValue: Variant;
begin
  vValue := GetVariantProp(AObject, APropInfo);
  if Assigned(AReference) then
  begin
    if vValue = GetVariantProp(AReference, APropInfo) then
      Exit;
  end;

  AJson.Add(APropInfo^.Name, VarToStr(vValue), jdtString);
end;

class procedure TComponentToJson.WriteProperty(AJson: TQJson; AObject, AReference: TObject; APropInfo: PPropInfo);
begin
  case APropInfo^.PropType^.Kind of
    tkInteger, tkChar, tkWChar, tkEnumeration, tkSet:
      WriteOrdProp(AJson, AObject, AReference, APropInfo);
    tkFloat:
      WriteFloatProp(AJson, AObject, AReference, APropInfo);
    tkString, tkLString, tkWString:
      WriteStrProp(AJson, AObject, AReference, APropInfo);
    tkClass:
      WriteObjectProp(AJson, AObject, AReference, APropInfo);
    tkMethod: ;
//      WriteMethodProp(AJson, AObject, AReference, APropInfo);
    tkVariant:
      WriteVariantProp(AJson, AObject, AReference, APropInfo);
    tkInt64:
      WriteInt64Prop(AJson, AObject, AReference, APropInfo);
//    tkInterface:
//      WriteInterfaceProp(AJson, AObject, AReference, APropInfo);
  else
    WriteView('属性(%s)不存在', [APropInfo^.Name]);
  end;
end;

class function TComponentToJson.ComponentToJsonImpl(var AJson: TQJson; AObject, AReference: TObject): Boolean;
var
  i, iCount: Integer;
  pl: array of Pointer;
  pi: PPropInfo;
  nd: TQJson;
  objReference: TObject;
  obj: TObject;
begin
  objReference := nil;
  try
    //1.0 清理数据
    AJson.Delete('__class__');
    AJson.Delete('__property__');
    AJson.Delete('__child__');
    AJson.Delete('__custom_property__');

    if AJson.HasChild('__reference__', nd) then
    begin
      nd := AJson.Root.ItemByPath(nd.Value + '.' + AJson.Name);
      if Assigned(nd) and not JsonToComponent(objReference, nd, nil) then
        FreeAndNil(objReference);

      if not Assigned(objReference) or (objReference.ClassInfo <> AObject.ClassInfo) then
      begin
        AJson.Delete('__reference__');
        FreeAndNil(objReference);
      end;
    end;

    //2.0 写入类信息
    if not Assigned(objReference) then
      AJson.Add('__class__', AObject.ClassName, jdtString);

    //3.0 遍历属性值，写入json对象中
    nd := nil;
    if (AObject is TComponent) and (TComponent(AObject).Name <> '') then
    begin
      nd := AJson.Add('__property__', jdtObject);
      nd.Add('Name', TComponent(AObject).Name, jdtString); //TComponent将Name定义为不保存，因此，这里特殊处理下
    end;

    iCount := GetTypeData(AObject.ClassInfo)^.PropCount;
    if iCount > 0 then
    begin
      Setlength(pl, iCount);
      GetPropInfos(AObject.ClassInfo, @pl[0]);

      for i := 0 to iCount - 1 do
      begin
        pi := pl[i];
        if not Assigned(pi) then
          Break;

        if not IsStoredProp(AObject, pi) then
          Continue;

        if not Assigned(pi^.GetProc) then
          Continue;

        if not Assigned(pi^.SetProc) then
        begin
          if pi^.PropType^.Kind <> tkClass then
            Continue;

          obj := TObject(GetOrdProp(AObject, pi));
          if not (obj is TComponent) then
            Continue;

          if not (csSubComponent in TComponent(obj).ComponentStyle) then
            Continue;
        end;

        if not Assigned(objReference)
          and (pi^.PropType^.Kind <> tkMethod)
          and IsDefaultPropertyValue(AObject, pi, nil, nil) then
          Continue;

        if not Assigned(nd) then
          nd := AJson.Add('__property__', jdtObject);

        WriteProperty(nd, AObject, objReference, pi);
      end;
    end;

    //3.0 写入自定义属性
    GStream.Size := 0;
    TJsonPersistent(AObject).DefineProperties(TJsonWriter.GetWriter);
    TJsonWriter.GetWriter.FlushBuffer;
    if GStream.Size > 0 then
    begin
      TJsonWriter.GetWriter.WriteListEnd;
      TJsonWriter.GetWriter.FlushBuffer;
      AJson.Add('__custom_property__', MemToBase64(GStream.DataString), jdtString);
    end;
  finally
    FreeAndNil(objReference);
  end;

  Result := True;
end;

function ComponentToJson(var AJson: TQJson; AObject: TObject): Boolean;
begin
  Result := TComponentToJson.ComponentToJsonImpl(AJson, AObject, nil);
end;

initialization
  GStream := TStringStream.Create('');
  TWriterHook.Init;

finalization
  TJsonWriter.UnInit;
  FreeAndNil(GStream);
  TWriterHook.UnInit;

end.
