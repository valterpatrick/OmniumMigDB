unit uFrmMapping;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons, Vcl.Menus;

type
  TFrmMapping = class(TForm)
    GroupBox1: TGroupBox;
    Label1: TLabel;
    EdtTabela: TEdit;
    Label2: TLabel;
    EdtCampoOrigem: TEdit;
    Label3: TLabel;
    EdtCampoDestino: TEdit;
    BtnAdd: TBitBtn;
    GroupBox2: TGroupBox;
    Label4: TLabel;
    ListCamposImportados: TListBox;
    PopupMenu1: TPopupMenu;
    Remover1: TMenuItem;
    Label5: TLabel;
    CB_IgnorarTabela: TCheckBox;
    procedure BtnAddClick(Sender: TObject);
    procedure Remover1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure RemoveItem(Indice: Integer);
    procedure PreencheListBox;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmMapping: TFrmMapping;

implementation

{$R *.dfm}


uses uDM1, uFrmPrincipal;

procedure TFrmMapping.BtnAddClick(Sender: TObject);
begin
  if Trim(EdtTabela.Text) = '' then
  begin
    if EdtTabela.CanFocus then
      EdtTabela.SetFocus;
    raise Exception.Create('Tabela não informada.');
  end;

  if (Trim(EdtCampoOrigem.Text) = '') and not CB_IgnorarTabela.Checked then
  begin
    if EdtCampoOrigem.CanFocus then
      EdtCampoOrigem.SetFocus;
    raise Exception.Create('Campo Origem não informado.');
  end;

  if (Trim(EdtCampoDestino.Text) = '') and not CB_IgnorarTabela.Checked then
  begin
    if EdtCampoDestino.CanFocus then
      EdtCampoDestino.SetFocus;
    raise Exception.Create('Campo Destino não informado.');
  end;

  if DM1.CDS_Mappings.Locate('NM_TAB;NM_CMP_ORG;NM_CMP_DST', VarArrayOf([Trim(EdtTabela.Text), Trim(EdtCampoOrigem.Text), Trim(EdtCampoDestino.Text)]), []) then
    raise Exception.Create('Campo já informado.');

  DM1.CDS_Mappings.Append;
  DM1.CDS_MappingsNM_TAB.AsString := UpperCase(Trim(EdtTabela.Text));
  DM1.CDS_MappingsNM_CMP_ORG.AsString := UpperCase(Trim(EdtCampoOrigem.Text));
  DM1.CDS_MappingsNM_CMP_DST.AsString := UpperCase(Trim(EdtCampoDestino.Text));
  DM1.CDS_Mappings.Post;
  FrmPrincipal.SalvarArquivoMapping;

  PreencheListBox;
end;

procedure TFrmMapping.PreencheListBox;
begin
  ListCamposImportados.Clear;

  DM1.CDS_Mappings.First;
  while not DM1.CDS_Mappings.Eof do
  begin
    ListCamposImportados.Items.Add(DM1.CDS_MappingsNM_TAB.AsString.Trim + ' = ' + DM1.CDS_MappingsNM_CMP_ORG.AsString.Trim + ' > ' + DM1.CDS_MappingsNM_CMP_DST.AsString.Trim);
    DM1.CDS_Mappings.Next;
  end;
end;

procedure TFrmMapping.FormCreate(Sender: TObject);
begin
  PreencheListBox;
end;

procedure TFrmMapping.RemoveItem(Indice: Integer);
var
  str, tabela, origem, destino: String;
  posIgual, posMaior: Integer;
begin
  str := ListCamposImportados.Items[Indice].Trim;

  posIgual := Pos('=', str);
  posMaior := Pos('>', str);

  tabela := Trim(Copy(str, 1, posIgual - 1));
  origem := Trim(Copy(str, posIgual + 1, posMaior - posIgual - 1));
  destino := Trim(Copy(str, posMaior + 1, str.Length - posMaior));

  ListCamposImportados.Items.Delete(Indice);
  DM1.CDS_Mappings.Locate('NM_TAB;NM_CMP_ORG;NM_CMP_DST', VarArrayOf([tabela, origem, destino]), []);
  DM1.CDS_Mappings.Delete;

  FrmPrincipal.SalvarArquivoMapping;
end;

procedure TFrmMapping.Remover1Click(Sender: TObject);
var
  I: Integer;
begin
  if (ListCamposImportados.ItemIndex < 0) then
    Exit;

  for I := 0 to ListCamposImportados.Count - 1 do
  begin
    if ListCamposImportados.Selected[I] then
    begin
      RemoveItem(I);
      Break;
    end;
  end;
end;

end.
