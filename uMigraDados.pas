unit uMigraDados;

interface

uses Classes, SysUtils, StrUtils, ActiveX, Forms, DateUtils, FireDAC.Comp.BatchMove, Math;

type
  TMigraDados = class(TThread)
  private
    vSucesso, vPularTabela: Boolean;
    vErro: String;
    vTotRegTab: Integer;
    procedure FinalizaThread;
    procedure GetData;
    procedure DesativarTriggers;
    procedure AtivarTriggers;
    procedure CopiarDados;
    procedure ExcluirChavesEstrangeiras;
    procedure AddChavesEstrangeiras;
    procedure SetarGenerators;
    procedure SetaValorGaugeItemChaveEstrangeira;
    procedure SetaValorGaugeItemTriggers;
    procedure SetaValorGaugeItemGenerators;
    procedure SetaValorGaugeItemTotRegTab;
    procedure AddMappings;
    procedure ProgressoBatch(ASender: TObject; APhase: TFDBatchMovePhase);
    procedure ProgressoBatchSync;
    procedure RecalculaIndices;
    procedure SetaValorGaugeItemRecalcIndices;
  protected
    procedure Execute; override;
  public
    constructor Create; reintroduce;
  end;

implementation

{ TMigraDados }

uses uDM1, uFrmPrincipal;

procedure TMigraDados.AddChavesEstrangeiras;
begin
  Synchronize(FrmPrincipal.GaugeTotal_Progresso);
  Synchronize(SetaValorGaugeItemChaveEstrangeira);

  FrmPrincipal.Log('TMigraDados - AddChavesEstrangeiras', 'Adicionando Chaves Estrangeiras...');
  DM1.FQ_Script_Destino.SQLScripts.Clear;
  DM1.FQ_Script_Destino.ExecuteScript(FrmPrincipal.ScriptAddChaveEstrangeira);
  FrmPrincipal.Log('TMigraDados - AddChavesEstrangeiras', 'Chaves Estrangeiras adicionadas.');

  Synchronize(FrmPrincipal.GaugeItem_Progresso);
  Synchronize(FrmPrincipal.SalvaLog);
end;

procedure TMigraDados.AtivarTriggers;
begin
  Synchronize(FrmPrincipal.GaugeTotal_Progresso);
  Synchronize(SetaValorGaugeItemTriggers);

  FrmPrincipal.Log('TMigraDados - AtivarTriggers', 'Ativando Triggers...');
  DM1.FQ_AtivarTrigger_Destino.Close;
  DM1.FQ_AtivarTrigger_Destino.ExecSQL;
  FrmPrincipal.Log('TMigraDados - AtivarTriggers', 'Triggers ativadas.');

  Synchronize(FrmPrincipal.GaugeItem_Progresso);
  Synchronize(FrmPrincipal.SalvaLog);
end;

procedure TMigraDados.CopiarDados;
var
  vTotReg: Integer;
begin
  DM1.FQ_ListaTabelas_Origem.First;
  while not DM1.FQ_ListaTabelas_Origem.Eof do
  begin
    FrmPrincipal.FNomeTabelaCopiando := DM1.FQ_ListaTabelas_OrigemNM_TAB.AsString.Trim;

    DM1.FQ_Execute_Origem.Close;
    DM1.FQ_Execute_Origem.SQL.Text := 'SELECT COUNT(*) NR_QTD_TOT_REG FROM ' + FrmPrincipal.FNomeTabelaCopiando + ';'; // Quantidade de registros a serem inseridos
    DM1.FQ_Execute_Origem.Open;
    vTotReg := DM1.FQ_Execute_Origem.FieldByName('NR_QTD_TOT_REG').AsInteger;

    FrmPrincipal.Log('TMigraDados - CopiarDados', 'Tabela ' + FrmPrincipal.FNomeTabelaCopiando + ', ' + IntToStr(vTotReg) + ' registros.');
    Synchronize(FrmPrincipal.GaugeTotal_Progresso);

    if vTotReg > 0 then
    begin
      vTotRegTab := vTotReg + 1;
      Synchronize(SetaValorGaugeItemTotRegTab);

      DM1.BatMovReader.TableName := FrmPrincipal.FNomeTabelaCopiando;
      DM1.BatMovWriter.TableName := FrmPrincipal.FNomeTabelaCopiando;
      vPularTabela := False;
      AddMappings;

      if not vPularTabela then
      begin
        FrmPrincipal.Log('TMigraDados - CopiarDados', 'Deletando dados da tabela ' + FrmPrincipal.FNomeTabelaCopiando + ' do banco de destino.');
        DM1.FQ_Execute_Destino.Close;
        DM1.FQ_Execute_Destino.SQL.Text := 'DELETE FROM ' + FrmPrincipal.FNomeTabelaCopiando + ';';
        DM1.FQ_Execute_Destino.ExecSQL;

        FrmPrincipal.Log('TMigraDados - CopiarDados', 'Copiando dados da tabela ' + FrmPrincipal.FNomeTabelaCopiando + ' do banco de origem para o destino...');
        DM1.BatMov.Execute;
        FrmPrincipal.Log('TMigraDados - CopiarDados', 'Dados da tabela ' + FrmPrincipal.FNomeTabelaCopiando + ' copiados com sucesso.');
      end
      else
        FrmPrincipal.Log('TMigraDados - CopiarDados', 'Os dados da tabela ' + FrmPrincipal.FNomeTabelaCopiando + ' não fora copiados devido estarem na lista de exceção.');
      vPularTabela := False;
    end;

    Synchronize(FrmPrincipal.SalvaLog);
    Synchronize(FrmPrincipal.ProcessarMensagens);
    DM1.FQ_ListaTabelas_Origem.Next;
  end;
end;

procedure TMigraDados.AddMappings;
var
  I: Integer;
begin
  if DM1.CDS_Mappings.RecordCount = 0 then
    Exit;

  DM1.BatMov.Mappings.Clear;
  if DM1.CDS_Mappings.Locate('NM_TAB', DM1.BatMovReader.TableName.Trim, []) then
  begin
    I := 0;
    DM1.CDS_Mappings.First;
    while not DM1.CDS_Mappings.Eof do
    begin
      if UpperCase(DM1.CDS_MappingsNM_TAB.AsString.Trim) = UpperCase(DM1.BatMovReader.TableName.Trim) then
      begin
        if DM1.CDS_MappingsNM_CMP_ORG.AsString.Trim = '' then
        begin
          vPularTabela := True;
          FrmPrincipal.Log('TMigraDados - AddMappings', 'Mappin[' + IntToStr(I) + ']. Tabela: ' + FrmPrincipal.FNomeTabelaCopiando + ' na lista de exceção.');
        end
        else
        begin
          DM1.BatMov.Mappings.Add;
          DM1.BatMov.Mappings.Items[I].SourceFieldName := DM1.CDS_MappingsNM_CMP_ORG.AsString;
          DM1.BatMov.Mappings.Items[I].DestinationFieldName := IfThen(DM1.CDS_MappingsNM_CMP_DST.AsString.Trim = '', DM1.CDS_MappingsNM_CMP_ORG.AsString, DM1.CDS_MappingsNM_CMP_DST.AsString);

          FrmPrincipal.Log('TMigraDados - AddMappings', 'Adicionando Mappings[' + IntToStr(I) + ']. Tabela: ' + FrmPrincipal.FNomeTabelaCopiando + '. Campo Origem: ' + DM1.BatMov.Mappings.Items[I].SourceFieldName + ' > Campo Destino: ' +
            DM1.BatMov.Mappings.Items[I].DestinationFieldName);
        end;
        I := I + 1;
      end;

      DM1.CDS_Mappings.Next;
    end;
  end;

end;

constructor TMigraDados.Create;
begin
  inherited Create(True);

  FreeOnTerminate := True;
  vSucesso := False;
  DM1.BatMov.OnProgress := ProgressoBatch;
end;

procedure TMigraDados.DesativarTriggers;
begin
  Synchronize(FrmPrincipal.GaugeTotal_Progresso);
  Synchronize(SetaValorGaugeItemTriggers);

  FrmPrincipal.Log('TMigraDados - DesativarTriggers', 'Desativando Triggers...');
  DM1.FQ_DesativarTrigger_Destino.Close;
  DM1.FQ_DesativarTrigger_Destino.ExecSQL;
  FrmPrincipal.Log('TMigraDados - DesativarTriggers', 'Triggers desativadas.');

  Synchronize(FrmPrincipal.GaugeItem_Progresso);
  Synchronize(FrmPrincipal.SalvaLog);
end;

procedure TMigraDados.ExcluirChavesEstrangeiras;
begin
  Synchronize(FrmPrincipal.GaugeTotal_Progresso);
  Synchronize(SetaValorGaugeItemChaveEstrangeira);

  FrmPrincipal.Log('TMigraDados - ExcluirChavesEstrangeiras', 'Excluindo Chaves Estrangeiras...');
  DM1.FQ_Script_Destino.SQLScripts.Clear;
  DM1.FQ_Script_Destino.ExecuteScript(FrmPrincipal.ScriptDropChaveEstrangeira);
  FrmPrincipal.Log('TMigraDados - ExcluirChavesEstrangeiras', 'Chaves Estrangeiras excluídas.');

  Synchronize(FrmPrincipal.GaugeItem_Progresso);
  Synchronize(FrmPrincipal.SalvaLog);
end;

procedure TMigraDados.Execute;
begin
  CoInitialize(nil);
  try
    try
      Synchronize(GetData);
      DesativarTriggers;
      ExcluirChavesEstrangeiras;
      CopiarDados;
      AtivarTriggers;
      AddChavesEstrangeiras;
      SetarGenerators;
      RecalculaIndices;
      vSucesso := True;
      Synchronize(FinalizaThread);
    except
      on E: Exception do
      begin
        if not Terminated then
        begin
          vErro := E.Message.Trim;
          Synchronize(FinalizaThread);
        end;
      end;
    end;
  finally
    CoUnInitialize;
  end;
end;

procedure TMigraDados.FinalizaThread;
begin
  FrmPrincipal.TempoFim := Now;
  if not vSucesso then
    FrmPrincipal.Erro := vErro;

  FrmPrincipal.FinalizaProcesso;
  FrmPrincipal.StopThread;
end;

procedure TMigraDados.GetData;
begin
  FrmPrincipal.TempoInicio := Now;
  DM1.AbreTabelas;
  FrmPrincipal.SetaValorGaugeTotal;
  Synchronize(FrmPrincipal.SalvaLog);
end;

procedure TMigraDados.ProgressoBatch(ASender: TObject; APhase: TFDBatchMovePhase);
begin
  FrmPrincipal.Log('TMigraDados - ProgressoBatch', 'Tabela: ' + FrmPrincipal.FNomeTabelaCopiando + '. Total Inserido: ' + DM1.BatMov.WriteCount.ToString);
  Synchronize(ProgressoBatchSync);
end;

procedure TMigraDados.ProgressoBatchSync;
begin
  FrmPrincipal.GaugeItem_ProgressoGeral(DM1.BatMov.WriteCount);
end;

procedure TMigraDados.RecalculaIndices;
begin
  Synchronize(FrmPrincipal.GaugeTotal_Progresso);
  Synchronize(SetaValorGaugeItemRecalcIndices);

  FrmPrincipal.Log('TMigraDados - RecalculaIndices', 'Recalculando indices...');
  DM1.FQ_Script_Destino.SQLScripts.Clear;
  DM1.FQ_Script_Destino.ExecuteScript(FrmPrincipal.ScriptRecalculoIndices);
  FrmPrincipal.Log('TMigraDados - RecalculaIndices', 'Indices recalculados.');

  Synchronize(FrmPrincipal.GaugeItem_Progresso);
  Synchronize(FrmPrincipal.SalvaLog);
end;

procedure TMigraDados.SetarGenerators;
var
  vScript: TStringList;
begin
  FrmPrincipal.Log('TMigraDados - SetarGenerators', 'Gerando script dos generators...');
  vScript := TStringList.Create;
  Synchronize(FrmPrincipal.GaugeTotal_Progresso);
  Synchronize(SetaValorGaugeItemGenerators);

  DM1.FQ_Generators_Origem.First;
  while not DM1.FQ_Generators_Origem.Eof do
  begin
    DM1.FQ_Execute_Origem.Close;
    DM1.FQ_Execute_Origem.SQL.Text := 'SELECT GEN_ID(' + DM1.FQ_Generators_OrigemNM_GEN.AsString.Trim + ', 0) NR_VLR_GEN FROM RDB$DATABASE';
    DM1.FQ_Execute_Origem.Open;

    vScript.Add('ALTER SEQUENCE ' + DM1.FQ_Generators_OrigemNM_GEN.AsString.Trim + ' RESTART WITH ' + DM1.FQ_Execute_Origem.FieldByName('NR_VLR_GEN').AsString + ';');
    DM1.FQ_Generators_Origem.Next;
    Synchronize(FrmPrincipal.GaugeItem_Progresso);
  end;
  DM1.FQ_Execute_Origem.Close;

  FrmPrincipal.Log('TMigraDados - SetarGenerators', 'Executando script dos generators...');
  DM1.FQ_Script_Destino.SQLScripts.Clear;
  DM1.FQ_Script_Destino.ExecuteScript(vScript);
  FrmPrincipal.Log('TMigraDados - SetarGenerators', 'Generators setados.');

  Synchronize(FrmPrincipal.GaugeItem_Progresso);
  Synchronize(FrmPrincipal.SalvaLog);
end;

procedure TMigraDados.SetaValorGaugeItemChaveEstrangeira;
begin
  FrmPrincipal.SetaValorGaugeItem(1);
end;

procedure TMigraDados.SetaValorGaugeItemRecalcIndices;
begin
  FrmPrincipal.SetaValorGaugeItem(1);
end;

procedure TMigraDados.SetaValorGaugeItemTriggers;
begin
  FrmPrincipal.SetaValorGaugeItem(1);
end;

procedure TMigraDados.SetaValorGaugeItemGenerators;
begin
  FrmPrincipal.SetaValorGaugeItem(FrmPrincipal.QuantGenerators + 1);
end;

procedure TMigraDados.SetaValorGaugeItemTotRegTab;
begin
  FrmPrincipal.SetaValorGaugeItem(vTotRegTab); // O mais 1, é em relação a exclusão dos registros da tabela destino.
end;

end.
