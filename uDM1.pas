unit uDM1;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.FB, FireDAC.Phys.FBDef,
  FireDAC.VCLUI.Wait, FireDAC.Comp.UI, FireDAC.Phys.IBBase, Data.DB, FireDAC.Comp.Client, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.Comp.DataSet, FireDAC.Comp.ScriptCommands, FireDAC.Stan.Util, FireDAC.Comp.Script,
  FireDAC.Comp.BatchMove.SQL, FireDAC.Comp.BatchMove, FireDAC.Comp.BatchMove.DataSet, Math, Datasnap.DBClient;

type
  TDM1 = class(TDataModule)
    FDCon_Destino: TFDConnection;
    FDPhysFBDriverLink1: TFDPhysFBDriverLink;
    FDGUIxWaitCursor1: TFDGUIxWaitCursor;
    FDCon_Origem: TFDConnection;
    FQ_ListaTabelas_Origem: TFDQuery;
    FQ_AddChavesEstrangeiras_Destino: TFDQuery;
    FQ_DropChavesEstrangeiras_Destino: TFDQuery;
    FQ_Generators_Origem: TFDQuery;
    FQ_Execute_Destino: TFDQuery;
    FQ_Execute_Origem: TFDQuery;
    FQ_DesativarTrigger_Destino: TFDQuery;
    FQ_AtivarTrigger_Destino: TFDQuery;
    FQ_ListaTabelas_OrigemNM_TAB: TWideStringField;
    FQ_AddChavesEstrangeiras_DestinoTX_ADD_CHV_ETG: TMemoField;
    FQ_DropChavesEstrangeiras_DestinoTX_DRP_CHV_ETG: TWideStringField;
    FQ_Script_Destino: TFDScript;
    FQ_Generators_OrigemNM_GEN: TWideStringField;
    BatMov: TFDBatchMove;
    BatMovReader: TFDBatchMoveSQLReader;
    BatMovWriter: TFDBatchMoveSQLWriter;
    CDS_Mappings: TClientDataSet;
    CDS_MappingsNM_TAB: TStringField;
    CDS_MappingsNM_CMP_ORG: TStringField;
    CDS_MappingsNM_CMP_DST: TStringField;
    FQ_ListaIndices_Destino: TFDQuery;
    FQ_ListaIndices_DestinoNM_IND: TWideStringField;
  private
  public
    procedure AbreTabelas;
  end;

var
  DM1: TDM1;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}


uses uFrmPrincipal;

{$R *.dfm}


procedure TDM1.AbreTabelas;
begin
  FrmPrincipal.Log('TDM1 - AbreTabelas', 'Abrindo tabelas...');
  try
    FQ_ListaTabelas_Origem.Close;
    FQ_ListaTabelas_Origem.Open;
    FQ_ListaTabelas_Origem.FetchAll;
    FrmPrincipal.QuantTatelas := FQ_ListaTabelas_Origem.RecordCount;
    FQ_ListaTabelas_Origem.First;

    FQ_Generators_Origem.Close;
    FQ_Generators_Origem.Open;
    FQ_Generators_Origem.FetchAll;
    FrmPrincipal.QuantGenerators := FQ_Generators_Origem.RecordCount;
    FQ_Generators_Origem.First;

    FQ_ListaIndices_Destino.Close;
    FQ_ListaIndices_Destino.Open;
    FQ_ListaIndices_Destino.FetchAll;

    FQ_ListaIndices_Destino.First;
    while not DM1.FQ_ListaIndices_Destino.Eof do
    begin
      FrmPrincipal.ScriptRecalculoIndices.Add(DM1.FQ_ListaIndices_DestinoNM_IND.AsString.Trim);
      FQ_ListaIndices_Destino.Next;
    end;
    FQ_ListaIndices_Destino.Close;

    FQ_DropChavesEstrangeiras_Destino.Close;
    FQ_DropChavesEstrangeiras_Destino.Open;
    FQ_DropChavesEstrangeiras_Destino.FetchAll;

    FQ_DropChavesEstrangeiras_Destino.First;
    while not FQ_DropChavesEstrangeiras_Destino.Eof do
    begin
      FrmPrincipal.ScriptDropChaveEstrangeira.Add(FQ_DropChavesEstrangeiras_DestinoTX_DRP_CHV_ETG.AsString.Trim);
      FQ_DropChavesEstrangeiras_Destino.Next;
    end;
    FQ_DropChavesEstrangeiras_Destino.Close;

    FQ_AddChavesEstrangeiras_Destino.Close;
    FQ_AddChavesEstrangeiras_Destino.Open;
    FQ_AddChavesEstrangeiras_Destino.FetchAll;

    FQ_AddChavesEstrangeiras_Destino.First;
    while not FQ_AddChavesEstrangeiras_Destino.Eof do
    begin
      FrmPrincipal.ScriptAddChaveEstrangeira.Add(FQ_AddChavesEstrangeiras_DestinoTX_ADD_CHV_ETG.AsString.Trim);
      FQ_AddChavesEstrangeiras_Destino.Next;
    end;
    FQ_AddChavesEstrangeiras_Destino.Close;

    DM1.BatMov.LogFileAction := laNone;
    DM1.BatMov.Reader := DM1.BatMovReader;
    DM1.BatMov.Writer := DM1.BatMovWriter;
    FrmPrincipal.SalvaScripts;

    FrmPrincipal.Log('TDM1 - AbreTabelas', 'Tabelas abertas.');
  except
    on E: Exception do
    begin
      FrmPrincipal.Log('TDM1 - AbreTabelas', 'Erro ao abrir as tabelas: ' + E.Message);
      raise Exception.Create('Erro ao abrir as tabelas: ' + E.Message);
    end;
  end;

end;

end.
