object DM1: TDM1
  OldCreateOrder = False
  Height = 459
  Width = 700
  object FDCon_Destino: TFDConnection
    Params.Strings = (
      'User_Name=sysdba'
      'Password=masterkey'
      
        'Database=D:\Dev\Binarios\Omnium\Convers'#227'o\OmniumMigDB\Bancos\Des' +
        'tino.FDB'
      'DriverID=FB')
    LoginPrompt = False
    Left = 496
    Top = 24
  end
  object FDPhysFBDriverLink1: TFDPhysFBDriverLink
    Left = 352
    Top = 32
  end
  object FDGUIxWaitCursor1: TFDGUIxWaitCursor
    Provider = 'Forms'
    Left = 248
    Top = 32
  end
  object FDCon_Origem: TFDConnection
    Params.Strings = (
      'User_Name=sysdba'
      'Password=masterkey'
      'Database=D:\Omnium\DATABASE.FDB'
      'DriverID=FB')
    LoginPrompt = False
    Left = 48
    Top = 32
  end
  object FQ_ListaTabelas_Origem: TFDQuery
    Connection = FDCon_Origem
    SQL.Strings = (
      'SELECT DISTINCT'
      '  RDB$RELATION_NAME NM_TAB'
      'FROM RDB$RELATIONS'
      'WHERE RDB$VIEW_BLR IS NULL'
      'AND (RDB$SYSTEM_FLAG = 0 OR RDB$SYSTEM_FLAG IS NULL)'
      'AND RDB$RELATION_NAME NOT LIKE '#39'%$%'#39
      'ORDER BY 1;')
    Left = 56
    Top = 120
    object FQ_ListaTabelas_OrigemNM_TAB: TWideStringField
      FieldName = 'NM_TAB'
      Origin = 'RDB$RELATION_NAME'
      FixedChar = True
      Size = 31
    end
  end
  object FQ_AddChavesEstrangeiras_Destino: TFDQuery
    Connection = FDCon_Destino
    SQL.Strings = (
      'SELECT'
      
        '  '#39'ALTER TABLE '#39' || TRIM(I.RDB$RELATION_NAME) || '#39' ADD CONSTRAIN' +
        'T '#39' || TRIM(I.RDB$INDEX_NAME) || '#39' FOREIGN KEY ('#39' || LIST(DISTIN' +
        'CT TRIM(IS1.RDB$FIELD_NAME)) || '#39') '#39' || '#39' REFERENCES '#39' || TRIM(I' +
        '2.RDB$RELATION_NAME) || '#39'('#39' || LIST(DISTINCT TRIM(IS2.RDB$FIELD_' +
        'NAME)) || '#39');'#39' TX_ADD_CHV_ETG'
      'FROM RDB$INDICES I'
      
        'LEFT JOIN RDB$INDEX_SEGMENTS IS1 ON IS1.RDB$INDEX_NAME = I.RDB$I' +
        'NDEX_NAME'
      
        'LEFT JOIN RDB$INDEX_SEGMENTS IS2 ON IS2.RDB$INDEX_NAME = I.RDB$F' +
        'OREIGN_KEY'
      
        'LEFT JOIN RDB$INDICES I2 ON I2.RDB$INDEX_NAME = IS2.RDB$INDEX_NA' +
        'ME'
      'WHERE I.RDB$SYSTEM_FLAG = 0'
      'AND I.RDB$FOREIGN_KEY IS NOT NULL'
      
        'GROUP BY I.RDB$RELATION_NAME, I.RDB$INDEX_NAME, I2.RDB$RELATION_' +
        'NAME')
    Left = 568
    Top = 104
    object FQ_AddChavesEstrangeiras_DestinoTX_ADD_CHV_ETG: TMemoField
      AutoGenerateValue = arDefault
      FieldName = 'TX_ADD_CHV_ETG'
      Origin = 'TX_ADD_CHV_ETG'
      ProviderFlags = []
      ReadOnly = True
      BlobType = ftMemo
    end
  end
  object FQ_DropChavesEstrangeiras_Destino: TFDQuery
    Connection = FDCon_Destino
    SQL.Strings = (
      'SELECT'
      
        '  '#39'ALTER TABLE '#39' || TRIM(I.RDB$RELATION_NAME) || '#39' DROP CONSTRAI' +
        'NT '#39' || TRIM(I.RDB$INDEX_NAME) || '#39';'#39' TX_DRP_CHV_ETG'
      'FROM RDB$INDICES I'
      'WHERE I.RDB$SYSTEM_FLAG = 0'
      'AND I.RDB$FOREIGN_KEY IS NOT NULL    ')
    Left = 568
    Top = 176
    object FQ_DropChavesEstrangeiras_DestinoTX_DRP_CHV_ETG: TWideStringField
      AutoGenerateValue = arDefault
      FieldName = 'TX_DRP_CHV_ETG'
      Origin = 'TX_DRP_CHV_ETG'
      ProviderFlags = []
      ReadOnly = True
      Size = 92
    end
  end
  object FQ_Generators_Origem: TFDQuery
    Connection = FDCon_Origem
    SQL.Strings = (
      'SELECT DISTINCT'
      '  RDB$GENERATOR_NAME NM_GEN'
      'FROM RDB$GENERATORS G'
      'WHERE (RDB$SYSTEM_FLAG = 0 OR RDB$SYSTEM_FLAG IS NULL)'
      'ORDER BY 1;')
    Left = 56
    Top = 184
    object FQ_Generators_OrigemNM_GEN: TWideStringField
      FieldName = 'NM_GEN'
      Origin = 'RDB$GENERATOR_NAME'
      FixedChar = True
      Size = 31
    end
  end
  object FQ_Execute_Destino: TFDQuery
    Connection = FDCon_Destino
    Left = 568
    Top = 376
  end
  object FQ_Execute_Origem: TFDQuery
    Connection = FDCon_Origem
    Left = 56
    Top = 248
  end
  object FQ_DesativarTrigger_Destino: TFDQuery
    Connection = FDCon_Destino
    SQL.Strings = (
      'UPDATE RDB$TRIGGERS SET'
      '  RDB$TRIGGER_INACTIVE = 1'
      'WHERE (RDB$SYSTEM_FLAG = 0 OR RDB$SYSTEM_FLAG IS NULL)'
      'AND RDB$TRIGGER_INACTIVE = 0;')
    Left = 568
    Top = 240
  end
  object FQ_AtivarTrigger_Destino: TFDQuery
    Connection = FDCon_Destino
    SQL.Strings = (
      'UPDATE RDB$TRIGGERS SET'
      '  RDB$TRIGGER_INACTIVE = 0'
      'WHERE (RDB$SYSTEM_FLAG = 0 OR RDB$SYSTEM_FLAG IS NULL)'
      'AND  RDB$TRIGGER_INACTIVE = 1;')
    Left = 568
    Top = 296
  end
  object FQ_Script_Destino: TFDScript
    SQLScripts = <>
    Connection = FDCon_Destino
    Params = <>
    Macros = <>
    Left = 424
    Top = 120
  end
  object BatMov: TFDBatchMove
    Reader = BatMovReader
    Writer = BatMovWriter
    Mappings = <>
    LogFileName = 'Data.log'
    Left = 288
    Top = 344
  end
  object BatMovReader: TFDBatchMoveSQLReader
    Connection = FDCon_Origem
    Left = 200
    Top = 344
  end
  object BatMovWriter: TFDBatchMoveSQLWriter
    Connection = FDCon_Destino
    Left = 376
    Top = 344
  end
  object CDS_Mappings: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 288
    Top = 208
    object CDS_MappingsNM_TAB: TStringField
      FieldName = 'NM_TAB'
      Size = 255
    end
    object CDS_MappingsNM_CMP_ORG: TStringField
      FieldName = 'NM_CMP_ORG'
      Size = 255
    end
    object CDS_MappingsNM_CMP_DST: TStringField
      FieldName = 'NM_CMP_DST'
      Size = 255
    end
  end
  object FQ_ListaIndices_Destino: TFDQuery
    Connection = FDCon_Destino
    SQL.Strings = (
      'SELECT DISTINCT'
      
        '  '#39'SET STATISTICS INDEX '#39' || TRIM(R.RDB$INDEX_NAME) || '#39';'#39' NM_IN' +
        'D'
      'FROM RDB$INDICES R'
      'ORDER BY 1')
    Left = 400
    Top = 256
    object FQ_ListaIndices_DestinoNM_IND: TWideStringField
      AutoGenerateValue = arDefault
      DisplayWidth = 100
      FieldName = 'NM_IND'
      Origin = 'NM_IND'
      ProviderFlags = []
      ReadOnly = True
      Size = 100
    end
  end
end
