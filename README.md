Aplicativo de migração de dados de um banco de dados para o outro (Firebird).  

Desenvolvido em Delphi, utilizando  TFDBatchMove, TFDBatchMoveSQLReader e TFDBatchMoveSQLWriter para fazer a migração.

No projeto utilizo Firebird, mas é possível fazer alterações para migrar de Firebird para outros bancos, ou vice versa. Por utilizar firebird, o projeto faz consulta as tabelas de sistema do Firebird, assim como exclui as chaves estrangeiras antes de copiar, desativa as trigguers e após concluir inclui novamente as chaves estrangeiras, triggers e recalcula os indices.

No arquivo "DBConfig_Destino.ini" você informa o banco de dados para onde será copiado os dados e no arquivo "DBConfig_Origem.ini" de onde estão vindo os dados. No arquivo "Mapping.ini" você informa algumas exceções de tabelas que não são para serem copiadas ou quais campos de determinas tabelas devem ser copiados.
