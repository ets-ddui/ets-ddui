unit UDictionary;

interface

uses
  Classes;

type
  TOnCreateItem = function : TPersistent of object;
  //TDictionary���Objects���������Ȩ���й���
  TDictionary = class(TStringList)
  private
    FOnCreateItem: TOnCreateItem;
  protected
    //AObject������Ȩ����TDictionary�ӹ�
    procedure InsertItem(AIndex: Integer; const AKey: String; AObject: TObject); override;
    procedure PutObject(AIndex: Integer; AObject: TObject); override;
  public
    constructor Create(AOnCreateItem: TOnCreateItem); reintroduce;
    destructor Destroy; override;
    //ASource.Objects[n]�����������Ǳ����ƣ�����Ȩû�з���ת��
    procedure AddStrings(ASource: TStrings); override;
    procedure Assign(ASource: TPersistent); override;
    procedure Clear; override;
    procedure Delete(AIndex: Integer); override;
  end;

implementation

uses
  RTLConsts;

{ TDictionary }

constructor TDictionary.Create(AOnCreateItem: TOnCreateItem);
begin
  inherited Create;
  FOnCreateItem := AOnCreateItem;
  Sorted := True;
end;

destructor TDictionary.Destroy;
begin
  Clear;
  inherited;
end;

procedure TDictionary.AddStrings(ASource: TStrings);
var
  i: Integer;
  obj: TPersistent;
begin
  if not (ASource is TDictionary) then
    Error('�������Ͳ��Ϸ�', 0);

  BeginUpdate;
  try
    for i := 0 to Count - 1 do
    begin
      obj := FOnCreateItem();
      obj.Assign(TPersistent(ASource.Objects[i]));
      AddObject(ASource[i], obj);
    end;
  finally
    EndUpdate;
  end;
end;

procedure TDictionary.Assign(ASource: TPersistent);
begin
  if not (ASource is TDictionary) then
    Error('�������Ͳ��Ϸ�', 0);

  inherited;
end;

procedure TDictionary.Clear;
var
  i: Integer;
begin
  if Count = 0 then
    Exit;

  BeginUpdate;
  try
    for i := Count - 1 downto 0 do
      Objects[i].Free;

    inherited;
  finally
    EndUpdate;
  end;
end;

procedure TDictionary.Delete(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= Count) then
    Error(@SListIndexError, AIndex);

  BeginUpdate;
  try
    Objects[AIndex].Free;
    inherited;
  finally
    EndUpdate;
  end;
end;

procedure TDictionary.InsertItem(AIndex: Integer; const AKey: String; AObject: TObject);
begin
  if Assigned(AObject) and not (AObject is TPersistent) then
    Error('�������Ͳ��Ϸ�', 0);

  inherited;
end;

procedure TDictionary.PutObject(AIndex: Integer; AObject: TObject);
var
  obj: TObject;
begin
  if Assigned(AObject) and not (AObject is TPersistent) then
    Error('�������Ͳ��Ϸ�', 0);
  if (AIndex < 0) or (AIndex >= Count) then
    Error(@SListIndexError, AIndex);

  BeginUpdate;
  try
    obj := Objects[AIndex];
    inherited;
    obj.Free;
  finally
    EndUpdate;
  end;
end;

end.
