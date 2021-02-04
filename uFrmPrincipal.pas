unit uFrmPrincipal;

{
  Desenvolvido por Valter Patrick - valterpatrick@hotmail.com - 2020
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons, Vcl.Samples.Gauges, FireDAC.VCLUI.ConnEdit,
  IniFiles, Math, Vcl.ExtCtrls, MidasLib;

type
  TFrmPrincipal = class(TForm)
    GauMigItem: TGauge;
    GauMigTotal: TGauge;
    BtnMigrar: TBitBtn;
    BtnConectar: TBitBtn;
    Lb_Descricao: TLabel;
    CB_Log: TCheckBox;
    BtnParar: TBitBtn;
    BtnMapping: TBitBtn;
    procedure BtnMigrarClick(Sender: TObject);
    procedure BtnConectarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure BtnMappingClick(Sender: TObject);
    procedure BtnPararClick(Sender: TObject);
  private
    vLog: TStringList;
    procedure ConectaBancoDados;
    procedure DesabilitaControles(DesabBotaoConectar: Boolean = False);
    procedure HabilitaControles;
  public
    Thread: TThread;
    Mensagem, Erro, FCaminhoArquivo, FNomeTabelaCopiando: String;
    ScriptAddChaveEstrangeira, ScriptDropChaveEstrangeira, ScriptRecalculoIndices: TStringList;
    TempoInicio, TempoFim: TDateTime;
    QuantTatelas, QuantGenerators: Integer;
    procedure StopThread;
    procedure FinalizaProcesso;
    procedure Log(Modulo, Mensagem: String; AlteraLabDesc: Boolean = True);
    procedure SetaValorGaugeTotal;
    procedure SetaValorGaugeItem(Quant: Integer);
    procedure GaugeItem_Progresso;
    procedure GaugeItem_ProgressoGeral(Quant: Integer = 1);
    procedure GaugeTotal_Progresso;
    procedure SalvaLog;
    procedure ProcessarMensagens;
    procedure LerArquivoMapping;
    procedure SalvarArquivoMapping;
    procedure SalvaScripts;
    function CalcTempoDecorrido(aDateStart, aDateEnd: TDateTime): String;
  end;

var
  FrmPrincipal: TFrmPrincipal;

implementation

{$R *.dfm}


uses uDM1, uMigraDados, uFrmMapping;

function TFrmPrincipal.CalcTempoDecorrido(aDateStart, aDateEnd: TDateTime): String;
var
  Hour, Minute, Second: Integer;
begin
  Result := '';

  if (aDateStart < aDateEnd) then
    Second := Round(86400 * (aDateEnd - aDateStart))
  else
    Second := Round(86400 * (aDateStart - aDateEnd));

  Hour := Second div 3600;
  Second := Second - (Hour * 3600);
  Minute := Second div 60;
  Second := Second - (Minute * 60);

  if (Hour > 0) then
  begin
    if (Length(inttostr(Hour)) > 2) then
      Result := inttostr(Hour)
    else
      Result := FormatFloat('00', Hour);
  end
  else
    Result := FormatFloat('00', 0);

  Result := Result + ':' + FormatFloat('00', Minute) + ':' + FormatFloat('00', Second);
end;


procedure TFrmPrincipal.BtnConectarClick(Sender: TObject);
begin
  ConectaBancoDados;
  LerArquivoMapping;
end;

procedure TFrmPrincipal.BtnMappingClick(Sender: TObject);
begin
  LerArquivoMapping;

  FrmMapping := TFrmMapping.Create(Application);
  FrmMapping.ShowModal;
  FrmMapping.Free;
end;

procedure TFrmPrincipal.BtnMigrarClick(Sender: TObject);
begin
  DesabilitaControles(True);
  Application.ProcessMessages;
  GauMigItem.Progress := 0;
  GauMigTotal.Progress := 0;
  Lb_Descricao.Caption := 'Migrando dados...';

  Thread := TMigraDados.Create();
  Thread.Start;
end;

procedure TFrmPrincipal.BtnPararClick(Sender: TObject);
begin
  if Application.MessageBox('Tem certeza que deseja parar o processo?', 'Confirmação', MB_ICONQUESTION + MB_YESNO) = ID_NO then
    Exit;

  try
    TempoFim := Now;
    Erro := 'Processo finalizado pelo usuário.';
    StopThread;
    Sleep(100);
    try
      DM1.BatMov.AbortJob;
      DM1.BatMov.Writer := nil;
    except
    end;
    FinalizaProcesso;
  finally
    Lb_Descricao.Caption := Erro;
    GauMigItem.Progress := 0;
    GauMigTotal.Progress := 0;
    HabilitaControles;
  end;
end;

procedure TFrmPrincipal.SalvarArquivoMapping;
var
  MappingIni: TIniFile;
begin
  MappingIni := TIniFile.Create(ExtractFileDir(Application.ExeName) + '\Mapping.ini');
  DM1.CDS_Mappings.First;
  while not DM1.CDS_Mappings.Eof do
  begin
    MappingIni.EraseSection(DM1.CDS_MappingsNM_TAB.AsString.Trim);
    DM1.CDS_Mappings.Next;
  end;

  DM1.CDS_Mappings.First;
  while not DM1.CDS_Mappings.Eof do
  begin
    MappingIni.WriteString(DM1.CDS_MappingsNM_TAB.AsString, DM1.CDS_MappingsNM_CMP_ORG.AsString, DM1.CDS_MappingsNM_CMP_DST.AsString);
    DM1.CDS_Mappings.Next;
  end;
end;

procedure TFrmPrincipal.LerArquivoMapping;
var
  MappingIni: TIniFile;
  TabelaLista, CamposLista: TStringList;
  I, J: Integer;
begin
  MappingIni := TIniFile.Create(ExtractFileDir(Application.ExeName) + '\Mapping.ini');
  TabelaLista := TStringList.Create;
  CamposLista := TStringList.Create;
  MappingIni.ReadSections(TabelaLista);

  if DM1.CDS_Mappings.Active then
  begin
    DM1.CDS_Mappings.EmptyDataSet;
    DM1.CDS_Mappings.Close;
  end;
  DM1.CDS_Mappings.CreateDataSet;

  for I := 0 to TabelaLista.Count - 1 do
  begin
    MappingIni.ReadSection(TabelaLista[I], CamposLista);
    if CamposLista.Count > 0 then
    begin
      for J := 0 to CamposLista.Count - 1 do
      begin
        DM1.CDS_Mappings.Append;
        DM1.CDS_MappingsNM_TAB.AsString := UpperCase(TabelaLista[I].Trim);
        DM1.CDS_MappingsNM_CMP_ORG.AsString := UpperCase(CamposLista[J].Trim);
        DM1.CDS_MappingsNM_CMP_DST.AsString := UpperCase(MappingIni.ReadString(TabelaLista[I].Trim, CamposLista[J].Trim, CamposLista[J].Trim));
        DM1.CDS_Mappings.Post;
      end;
    end
    else
    begin
      DM1.CDS_Mappings.Append;
      DM1.CDS_MappingsNM_TAB.AsString := UpperCase(TabelaLista[I].Trim);
      DM1.CDS_MappingsNM_CMP_ORG.AsString := '';
      DM1.CDS_MappingsNM_CMP_DST.AsString := '';
      DM1.CDS_Mappings.Post;
    end;
  end;
end;

procedure TFrmPrincipal.ConectaBancoDados;
var
  vConectado: Boolean;
begin
  DesabilitaControles;
  vConectado := True;
  try
    if FileExists(FCaminhoArquivo + '\DBConfig_Origem.ini') then
      DM1.FDCon_Origem.Params.LoadFromFile(FCaminhoArquivo + '\DBConfig_Origem.ini')
    else
    begin
      Application.MessageBox('Não foi possível carregar o arquivo de configuração do banco de dados origem. Informe as configurações de conexão para prosseguir.', 'Informação', MB_ICONWARNING + MB_OK);
      DM1.FDCon_Origem.Close;
      if TfrmFDGUIxFormsConnEdit.Execute(DM1.FDCon_Origem, '') then
      begin
        DM1.FDCon_Origem.Params.SaveToFile(FCaminhoArquivo + '\DBConfig_Origem.ini');
        DM1.FDCon_Origem.Open;
      end
      else
      begin
        DM1.FDCon_Origem.Connected := False;
        Abort;
      end;
    end;

    DM1.FDCon_Origem.Open;
  except
    on E: Exception do
    begin
      vConectado := False;
      Application.MessageBox(PChar('Erro ao carregar configurações da Conexão de Origem: ' + E.Message), 'Erro', MB_ICONERROR + MB_OK);
    end;
  end;

  try
    if FileExists(FCaminhoArquivo + '\DBConfig_Destino.ini') then
      DM1.FDCon_Destino.Params.LoadFromFile(FCaminhoArquivo + '\DBConfig_Destino.ini')
    else
    begin
      Application.MessageBox('Não foi possível carregar o arquivo de configuração do banco de dados destino. Informe as configurações de conexão para prosseguir.', 'Informação', MB_ICONWARNING + MB_OK);
      DM1.FDCon_Destino.Close;
      if TfrmFDGUIxFormsConnEdit.Execute(DM1.FDCon_Destino, '') then
      begin
        DM1.FDCon_Destino.Params.SaveToFile(FCaminhoArquivo + '\DBConfig_Destino.ini');
        DM1.FDCon_Destino.Open;
      end
      else
      begin
        DM1.FDCon_Destino.Connected := False;
        Abort;
      end;
    end;

    DM1.FDCon_Destino.Open;
  except
    on E: Exception do
    begin
      vConectado := False;
      Application.MessageBox(PChar('Erro ao carregar configurações da Conexão de Destino: ' + E.Message), 'Erro', MB_ICONERROR + MB_OK);
    end;
  end;

  if vConectado then
  begin
    HabilitaControles;
    Application.MessageBox('Bancos de dados conectados com sucesso.', 'Informação', MB_ICONINFORMATION + MB_OK);
  end;
end;

procedure TFrmPrincipal.DesabilitaControles(DesabBotaoConectar: Boolean = False);
begin
  BtnMigrar.Enabled := False;
  BtnMigrar.Visible := not DesabBotaoConectar;
  BtnParar.Enabled := DesabBotaoConectar;
  BtnParar.Top := IfThen(DesabBotaoConectar, BtnMigrar.Top, BtnMigrar.Top + 50);

  CB_Log.Enabled := BtnMigrar.Enabled;
  BtnMapping.Enabled := BtnMigrar.Enabled;
  BtnConectar.Enabled := not DesabBotaoConectar;
end;

procedure TFrmPrincipal.FinalizaProcesso;
var
  vTempo: String;
begin
  vTempo := 'Tempo decorrido: ' + CalcTempoDecorrido(TempoInicio, TempoFim) + '.';

  if Erro.Trim <> '' then
  begin
    Log('FinalizaProcesso - Erro', 'Erro durante a migração: ' + Erro.Trim + '. ' + vTempo);
    SalvaLog;
    Application.MessageBox(PChar('Erro durante a migração: ' + Erro.Trim + '. ' + vTempo), 'Erro', MB_ICONERROR + MB_OK);
  end
  else
  begin
    Log('FinalizaProcesso - Mensagem', 'Registros migrados com sucesso. ' + vTempo);
    SalvaLog;
    Application.MessageBox(PChar('Registros migrados com sucesso. ' + vTempo), 'Informação', MB_ICONINFORMATION + MB_OK);
  end;

  HabilitaControles;
end;

procedure TFrmPrincipal.FormCreate(Sender: TObject);
begin
  Height := Constraints.MinHeight;
  Width := Constraints.MinWidth;
  FCaminhoArquivo := ExtractFileDir(Application.ExeName);
  FNomeTabelaCopiando := '';
  vLog := TStringList.Create;
  ScriptAddChaveEstrangeira := TStringList.Create;
  ScriptDropChaveEstrangeira := TStringList.Create;
  ScriptRecalculoIndices := TStringList.Create;
  DesabilitaControles;

  DM1 := TDM1.Create(Application);
end;

procedure TFrmPrincipal.HabilitaControles;
begin
  BtnMigrar.Enabled := True;
  BtnMigrar.Visible := True;
  BtnParar.Enabled := False;
  BtnParar.Top := BtnMigrar.Top + 50;

  CB_Log.Enabled := BtnMigrar.Enabled;
  BtnConectar.Enabled := BtnMigrar.Enabled;
  BtnMapping.Enabled := BtnMigrar.Enabled;
end;

procedure TFrmPrincipal.Log(Modulo, Mensagem: String; AlteraLabDesc: Boolean = True);
begin
  vLog.Add(FormatDateTime('dd/MM/yyyy hh:mm:ss', Now) + ' - > Módulo: ' + Modulo + ' - > ' + Mensagem);

  if AlteraLabDesc then
    Lb_Descricao.Caption := Mensagem;
end;

procedure TFrmPrincipal.SalvaScripts;
begin
  if not CB_Log.Checked then
    Exit;

  Log('SalvaScripts', 'Salvando scripts.');
  ScriptRecalculoIndices.SaveToFile(FCaminhoArquivo + '\ScriptRecalculoIndices.sql');
  ScriptDropChaveEstrangeira.SaveToFile(FCaminhoArquivo + '\ScriptDropChaveEstrangeira.sql');
  ScriptAddChaveEstrangeira.SaveToFile(FCaminhoArquivo + '\ScriptAddChaveEstrangeira.sql');
end;

procedure TFrmPrincipal.ProcessarMensagens;
begin
  Application.ProcessMessages;
end;

procedure TFrmPrincipal.SalvaLog;
begin
  if CB_Log.Checked then
    vLog.SaveToFile(FCaminhoArquivo + '\OmniumMigDB.log');
end;

procedure TFrmPrincipal.SetaValorGaugeItem(Quant: Integer);
begin
  GauMigItem.MinValue := 0;
  GauMigItem.MaxValue := Quant;
  GauMigItem.Progress := 0;
end;

procedure TFrmPrincipal.GaugeItem_Progresso;
begin
  GauMigItem.Progress := GauMigItem.Progress + 1;
end;

procedure TFrmPrincipal.GaugeItem_ProgressoGeral(Quant: Integer = 1);
begin
  GauMigItem.Progress := Quant;
  Lb_Descricao.Font.Size := 8;
  Lb_Descricao.Font.Name := 'Tahoma';
end;

procedure TFrmPrincipal.GaugeTotal_Progresso;
begin
  GauMigTotal.Progress := GauMigTotal.Progress + 1;
end;

procedure TFrmPrincipal.SetaValorGaugeTotal;
begin
  GauMigTotal.MinValue := 0;
  GauMigTotal.MaxValue := QuantTatelas + 6;
  // O + 6 se refere as triggers e chaves estrangeiras que serão inseridas e excluídas em um script só, além dos generators e recalculo dos indices
end;

procedure TFrmPrincipal.StopThread;
begin
  if Assigned(Thread) then
    Thread.Terminate;
  Thread := nil;
end;

end.
