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
unit UDUIGridData;

interface

uses
  Classes, SysUtils, UDUIGrid, UDUIGridHashMap;

type
  TDUIGridHashData = class(TDUIGridData)
  private
    FData: _THashMap;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetEditText(const ACol, ARow: TDUIRowColID): String; override;
    procedure SetEditText(const ACol, ARow: TDUIRowColID; const AValue: String); override;
  end;

implementation

{ TDUIGridHashData }

constructor TDUIGridHashData.Create(AOwner: TComponent);
begin
  inherited;

  FData := _THashMap.Create;
end;

destructor TDUIGridHashData.Destroy;
begin
  FreeAndNil(FData);

  inherited;
end;

function TDUIGridHashData.GetEditText(const ACol, ARow: TDUIRowColID): String;
var
  gc: TDUIGridCoord;
  it: _IMapIterator;
begin
  Result := '';

  gc := GridCoord(ACol, ARow);
  it := FData.Find(gc);
  if it.IsEqual(FData.itEnd) then
    Exit;

  Result := it.Value;
end;

procedure TDUIGridHashData.SetEditText(const ACol, ARow: TDUIRowColID; const AValue: String);
begin
  FData.Items[GridCoord(ACol, ARow)] := AValue;
end;

end.
