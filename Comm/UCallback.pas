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
unit UCallback;

interface

uses
  Windows, SysUtils;

const
  CItemCount = 313;

type
  TCustomParam = packed record
    FParam1: Pointer;
    FParam2: Pointer;
  end;
  PMemoryItem = ^TMemoryItem;
  TMemoryItem = packed record
    FCode: Byte; //与FCallOffset一起，构造了一条汇编代码
                 //CALL FCallOffset
    FCallOffset: Integer;
    case Integer of
      0: (FNext: PMemoryItem);
      1: (FMethod: TMethod);
      2: (FCustom: TCustomParam);
  end;

  PMemoryHeader = ^TMemoryHeader;
  TMemoryHeader = packed record
    FNext: PMemoryHeader; //用于构造链表的指针
    FCode: array[1..2] of Byte; //与FJmpOffset一起，构造了两条汇编代码
                                //POP ECX
                                //JMP FJmpOffset ; FJmpOffset为FCode后面定义的变量FJmpOffset
    FJmpOffset: Integer;
    FInstances: array[0..CItemCount] of TMemoryItem;
  end;

  //此类是从Classes.pas的MakeObjectInstance实现移植而来
  //作用是将静态函数调用(必须声明为stdcall调用协议)转化成对象成员函数的调用
  //本质上来说就是在原入参的基础上，增加一个新的对象地址的入参，并跳转到对象成员函数继续执行
  //实现原理如下：
  //1.0 从TMemoryHeader.FInstances[i].FCode开始执行
  //    FCode保存的是CALL FCallOffset指令，执行后跳转到TMemoryHeader.FCode
  //    CALL调用后，会将下一条指令的地址压入堆栈，这个地址保存的不是汇编地址，而是TMemoryItem.FMethod
  //2.0 执行流跳转到TMemoryHeader.FCode
  //    将TMemoryItem.FMethod的地址从栈中弹出，并保存到ECX
  //    调用FFunctionAddress的函数(通过JMP直接跳转过去)，函数中实现对ECX中函数地址的调用
  //3.0 FFunctionAddress默认通过DoStdcall实现
  //    将TMemoryItem.FMethod中保存的函数地址和对象地址取出
  //    将返回地址前移4字节(在栈中预留出存放对象的内存)，并将对象放入栈中
  //    跳转到函数地址继续执行
  //    经过此处理后，函数调用实际上被转换为对TMethod的调用，入参的栈平衡由TMethod实现
  //    因此，TMethod的入参及调用协议必须与外部函数的调用方式完全一致
  //    同时，返回值不能为String或结构体，否则，返回值的地址需进行调整(正常调用，先压入对象地址，再压入返回值地址)
  TCallConv = (ccStdcall, ccCdecl);
  TCallback = class
  private
    FMemory: PMemoryHeader; //4K内存块的链表
    FFreeList: PMemoryItem; //空闲内存链表
    FFunctionAddress: Pointer;
    procedure Allocate;
    function AllocItem: PMemoryItem;
  public
    constructor Create(ACallConv: TCallConv);
    destructor Destroy; override;
    function RegistMethod(AMethod: TMethod): Pointer;
    function FreeMethod(AFunctionEntry: Pointer): Boolean;
  end;

implementation

{ TCallback }

procedure DoStdcall;
asm
  //1.0 函数返回地址前移4字节
  MOV EAX, [ESP]
  PUSH EAX

  //2.0 将对象地址压入堆栈中
  {TODO: 如果返回值是复杂类型(例如String或结构体)，ESP + 4存放的是}
  //if 复杂返回值 then
  //  MOV EAX, [ESP + 8]
  //  MOV [ESP + 4], EAX
  //  MOV EAX, [ECX].TMethod.Data
  //  MOV [ESP + 8], EAX
  //else
      MOV EAX, [ECX].TMethod.Data
      MOV [ESP + 4], EAX
  //endif

  //3.0 跳转到对象成员函数继续执行
  JMP [ECX].TMethod.Code
end;

var
  GGlobalCallback: TCallback;

procedure DoCdeclEnd;
asm
  //1.0 对手工添加的类对象的入参进行修正
  ADD ESP, 4

  //2.0 释放调用时申请的GGlobalCallback内存
  PUSH EAX //保存返回值
  PUSH [ECX].TCustomParam.FParam1 //保存真实的返回地址
  MOV EDX, [ECX].TCustomParam.FParam2
  MOV EAX, GGlobalCallback
  CALL TCallback.FreeMethod
  POP EDX //读取真实的返回地址
  POP EAX //读取返回值(不是TCallback.FreeMethod的返回值，而是目标类成员函数的返回值)

  //3.0 跳转到真实返回地址继续执行
  JMP EDX
end;

function GetCdeclEndMemory(AReturnAddress: Pointer): PMemoryItem;
begin
  if not Assigned(GGlobalCallback) then
  begin
    GGlobalCallback := TCallback.Create(ccStdcall);
    GGlobalCallback.FFunctionAddress := @DoCdeclEnd;
  end;

  Result := GGlobalCallback.AllocItem;
  if not Assigned(Result) then
    raise Exception.Create('not enough memory');

  Result.FCustom.FParam1 := AReturnAddress;
  Result.FCustom.FParam2 := Result;
end;

procedure DoCdecl;
asm
  //1.0 保存真实函数返回地址
  PUSH ECX
  MOV EAX, [ESP + 4]
  CALL GetCdeclEndMemory
  POP ECX

  //2.0 将对象地址压入堆栈中
  MOV EDX, [ECX].TMethod.Data
  MOV [ESP], EDX

  //3.0 对象成员函数
  PUSH EAX //重新构造返回地址
  JMP [ECX].TMethod.Code
end;

constructor TCallback.Create(ACallConv: TCallConv);
begin
  case ACallConv of
    ccStdcall: FFunctionAddress := @DoStdcall;
    ccCdecl: FFunctionAddress := @DoCdecl;
  end;
end;

destructor TCallback.Destroy;
var
  mh: PMemoryHeader;
begin
  while Assigned(FMemory) do
  begin
    mh := FMemory;
    FMemory := FMemory.FNext;

    VirtualFree(mh, 0, MEM_RELEASE);
  end;

  FFreeList := nil;

  inherited;
end;

procedure TCallback.Allocate;
const
  cBlockCode: array[1..2] of Byte = (
    $59,       { POP ECX }
    $E9);      { JMP FFunctionAddress }
  cPageSize = 4096;
var
  mh: PMemoryHeader;
  i: Integer;
begin
  //1.0 分配内存并初始化内存头信息
  mh := VirtualAlloc(nil, cPageSize, MEM_COMMIT, PAGE_EXECUTE_READWRITE);
  mh.FNext := FMemory;
  Move(cBlockCode, mh.FCode, SizeOf(cBlockCode));
  mh.FJmpOffset := Integer(FFunctionAddress) - Integer(@mh.FJmpOffset) - SizeOf(mh.FJmpOffset); //FFunctionAddress - FJmpOffset的下一条汇编指令地址

  //2.0 对内存进行切割，构造空闲内存链表(空闲链表是反向引用的<即后面的内存指向前面的内存>)
  for i := 0 to CItemCount do
  begin
    with mh.FInstances[i] do
    begin
      FCode := $E8; //CALL FCallOffset
      FCallOffset := Integer(@mh.FCode) - Integer(@FCallOffset) - SizeOf(FCallOffset); //TMemoryHeader.FCode - TMemoryHeader.FInstances[i].FCode的下一条汇编指令地址
      FNext := FFreeList;
    end;

    FFreeList := @mh.FInstances[i];
  end;

  FMemory := mh;
end;

function TCallback.AllocItem: PMemoryItem;
begin
  if not Assigned(FFreeList) then
  begin
    Allocate;

    if not Assigned(FFreeList) then
    begin
      Result := nil;
      Exit;
    end;
  end;

  Result := FFreeList;
  FFreeList := FFreeList.FNext;
end;

function TCallback.RegistMethod(AMethod: TMethod): Pointer;
begin
  Result := AllocItem;
  if not Assigned(Result) then
    Exit;

  PMemoryItem(Result).FMethod := AMethod;
end;

function TCallback.FreeMethod(AFunctionEntry: Pointer): Boolean;
{$IFDEF DEBUG}
var
  mh: PMemoryHeader;
{$ENDIF}
begin
{$IFDEF DEBUG}
  mh := FMemory;
  while Assigned(mh) do
  begin
    if (Integer(AFunctionEntry) >= Integer(@mh.FInstances[0]))
      and (Integer(AFunctionEntry) <= (Integer(@mh.FInstances[CItemCount])))
      and ((Integer(AFunctionEntry) - Integer(@mh.FInstances[0])) mod SizeOf(TMemoryItem) = 0) then
    begin
      PMemoryItem(AFunctionEntry).FNext := FFreeList;
      FFreeList := AFunctionEntry;

      Result := True;
      Exit;
    end;

    mh := mh.FNext;
  end;

  Result := False;
{$ELSE}
  Result := False;
  if not Assigned(AFunctionEntry) then
    Exit;

  PMemoryItem(AFunctionEntry).FNext := FFreeList;
  FFreeList := AFunctionEntry;

  Result := True;
{$ENDIF}
end;

initialization

finalization
  FreeAndNil(GGlobalCallback);

end.
