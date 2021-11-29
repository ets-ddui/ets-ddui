program Fake360;

uses
  Forms,
  UMain in 'UMain.pas' {FmMain: TDUIForm},
  UWelcome in 'UWelcome.pas' {FrmWelcome: TDUIFrame},
  UNormal in 'UNormal.pas' {FrmNormal: TDUIFrame},
  UGrid in 'UGrid.pas' {FrmGrid: TDUIFrame},
  UWinControl in 'UWinControl.pas' {FrmWinControl: TDUIFrame},
  UAbout in 'UAbout.pas' {FrmAbout: TDUIFrame};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFmMain, FmMain);
  Application.Run;
end.
