program OmniumMigDB;

uses
  Vcl.Forms,
  uFrmPrincipal in 'uFrmPrincipal.pas' {FrmPrincipal},
  uDM1 in 'uDM1.pas' {DM1: TDataModule},
  uMigraDados in 'uMigraDados.pas',
  uFrmMapping in 'uFrmMapping.pas' {FrmMapping};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmPrincipal, FrmPrincipal);
  Application.Run;
end.
