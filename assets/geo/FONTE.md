# Limites territoriais

- `br_uf.json`: 27 unidades da federação; `municipios/{UF}.json`: municípios de cada UF.
- Fonte: IBGE — API de Malhas Geográficas v3 (qualidade intermediária) e API de Localidades v1 (nomes).
  https://servicodados.ibge.gov.br/api/docs/malhas?versao=3
- Processamento: coordenadas arredondadas a 4 casas decimais (~11 m), pontos repetidos removidos.
- Propriedades: estados `{uf, n}`; municípios `{c: código IBGE, n: nome}`.
