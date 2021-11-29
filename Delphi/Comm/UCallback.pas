{
  Copyright (c) 2021-2031 Steven Shi

  ETS_DDUI For Delphi����Ư���������������򵥡�

  ��UI���ǿ�Դ������������������� MIT Э�飬�޸ĺͷ����˳���
  �����˿��Ŀ����ϣ�������ã��������κα�֤��
  ���������������ҵ��Ŀ�����ڱ����е�Bug����������κη��ռ���ʧ�������߲��е��κ����Ρ�

  ��Դ��ַ: https://github.com/ets-ddui/ets-ddui
  ��ԴЭ��: The MIT License (MIT)
  ��������: xinghun87@163.com
  �ٷ����ͣ�https://blog.csdn.net/xinghun61
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
    FCode: Byte; //��FCallOffsetһ�𣬹�����һ��������
                 //CALL FCallOffset
    FCallOffset: Integer;
    case Integer of
      0: (FNext: PMemoryItem);
      1: (FMethod: TMethod);
      2: (FCustom: TCustomParam);
  end;

  PMemoryHeader = ^TMemoryHeader;
  TMemoryHeader = packed record
    FNext: PMemoryHeader; //���ڹ��������ָ��
    FCode: array[1..2] of Byte; //��FJmpOffsetһ�𣬹���������������
                                //POP ECX
                                //JMP FJmpOffset ; FJmpOffsetΪFCode���涨��ı���FJmpOffset
    FJmpOffset: Integer;
    FInstances: array[0..CItemCount] of TMemoryItem;
  end;

  //�����Ǵ�Classes.pas��MakeObjectInstanceʵ����ֲ����
  //�����ǽ���̬��������(��������Ϊstdcall����Э��)ת���ɶ����Ա�����ĵ���
  //��������˵������ԭ��εĻ����ϣ�����һ���µĶ����ַ����Σ�����ת�������Ա��������ִ��
  //ʵ��ԭ�����£�
  //1.0 ��TMemoryHeader.FInstances[i].FCode��ʼִ��
  //    FCode�������CALL FCallOffsetָ�ִ�к���ת��TMemoryHeader.FCode
  //    CALL���ú󣬻Ὣ��һ��ָ��ĵ�ַѹ���ջ�������ַ����Ĳ��ǻ���ַ������TMemoryItem.FMethod
  //2.0 ִ������ת��TMemoryHeader.FCode
  //    ��TMemoryItem.FMethod�ĵ�ַ��ջ�е����������浽ECX
  //    ����FFunctionAddress�ĺ���(ͨ��JMPֱ����ת��ȥ)��������ʵ�ֶ�ECX�к�����ַ�ĵ���
  //3.0 FFunctionAddressĬ��ͨ��DoStdcallʵ��
  //    ��TMemoryItem.FMethod�б���ĺ�����ַ�Ͷ����ַȡ��
  //    �����ص�ַǰ��4�ֽ�(��ջ��Ԥ������Ŷ�����ڴ�)�������������ջ��
  //    ��ת��������ַ����ִ��
  //    �����˴���󣬺�������ʵ���ϱ�ת��Ϊ��TMethod�ĵ��ã���ε�ջƽ����TMethodʵ��
  //    ��ˣ�TMethod����μ�����Э��������ⲿ�����ĵ��÷�ʽ��ȫһ��
  //    ͬʱ������ֵ����ΪString��ṹ�壬���򣬷���ֵ�ĵ�ַ����е���(�������ã���ѹ������ַ����ѹ�뷵��ֵ��ַ)
  TCallConv = (ccStdcall, ccCdecl);
  TCallback = class
  private
    FMemory: PMemoryHeader; //4K�ڴ�������
    FFreeList: PMemoryItem; //�����ڴ�����
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
  //1.0 �������ص�ַǰ��4�ֽ�
  MOV EAX, [ESP]
  PUSH EAX

  //2.0 �������ַѹ���ջ��
  {TODO: �������ֵ�Ǹ�������(����String��ṹ��)��ESP + 4��ŵ���}
  //if ���ӷ���ֵ then
  //  MOV EAX, [ESP + 8]
  //  MOV [ESP + 4], EAX
  //  MOV EAX, [ECX].TMethod.Data
  //  MOV [ESP + 8], EAX
  //else
      MOV EAX, [ECX].TMethod.Data
      MOV [ESP + 4], EAX
  //endif

  //3.0 ��ת�������Ա��������ִ��
  JMP [ECX].TMethod.Code
end;

var
  GGlobalCallback: TCallback;

procedure DoCdeclEnd;
asm
  //1.0 ���ֹ���ӵ���������ν�������
  ADD ESP, 4

  //2.0 �ͷŵ���ʱ�����GGlobalCallback�ڴ�
  PUSH EAX //���淵��ֵ
  PUSH [ECX].TCustomParam.FParam1 //������ʵ�ķ��ص�ַ
  MOV EDX, [ECX].TCustomParam.FParam2
  MOV EAX, GGlobalCallback
  CALL TCallback.FreeMethod
  POP EDX //��ȡ��ʵ�ķ��ص�ַ
  POP EAX //��ȡ����ֵ(����TCallback.FreeMethod�ķ���ֵ������Ŀ�����Ա�����ķ���ֵ)

  //3.0 ��ת����ʵ���ص�ַ����ִ��
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
  //1.0 ������ʵ�������ص�ַ
  PUSH ECX
  MOV EAX, [ESP + 4]
  CALL GetCdeclEndMemory
  POP ECX

  //2.0 �������ַѹ���ջ��
  MOV EDX, [ECX].TMethod.Data
  MOV [ESP], EDX

  //3.0 �����Ա����
  PUSH EAX //���¹��췵�ص�ַ
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
  //1.0 �����ڴ沢��ʼ���ڴ�ͷ��Ϣ
  mh := VirtualAlloc(nil, cPageSize, MEM_COMMIT, PAGE_EXECUTE_READWRITE);
  mh.FNext := FMemory;
  Move(cBlockCode, mh.FCode, SizeOf(cBlockCode));
  mh.FJmpOffset := Integer(FFunctionAddress) - Integer(@mh.FJmpOffset) - SizeOf(mh.FJmpOffset); //FFunctionAddress - FJmpOffset����һ�����ָ���ַ

  //2.0 ���ڴ�����и��������ڴ�����(���������Ƿ������õ�<��������ڴ�ָ��ǰ����ڴ�>)
  for i := 0 to CItemCount do
  begin
    with mh.FInstances[i] do
    begin
      FCode := $E8; //CALL FCallOffset
      FCallOffset := Integer(@mh.FCode) - Integer(@FCallOffset) - SizeOf(FCallOffset); //TMemoryHeader.FCode - TMemoryHeader.FInstances[i].FCode����һ�����ָ���ַ
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
