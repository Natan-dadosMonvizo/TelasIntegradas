-- =====================================================================
-- Tabela "f_faturamento_hist7" — itens de Nota Fiscal (entrada/saída,
-- com classificação Devolução/Saída/Serviço) dos últimos 7 dias, vindos
-- da consulta "fFaturamento_Hist7" do ERP. Grão: 1 linha por ITEM de
-- nota fiscal (id_filial+serie_nf+id_nota_fiscal+fl_entrada_saida+
-- id_item) — uma mesma nota fiscal pode ter várias linhas aqui, uma
-- para cada item nela.
-- =====================================================================
-- Execute este script no SQL Editor do Supabase ANTES de importar o
-- workflow n8n atualizado. Depois, rode novamente o 01_rls_policies.sql
-- (já atualizado com esta tabela) para liberar a leitura via Anon Key.
--
-- Observação sobre a query original do usuário: ela não trazia FILIAL
-- nem SERIE no SELECT final, só NOTA_FISCAL. Como o restante do projeto
-- já trata filial como parte da chave real (um mesmo número pode se
-- repetir em filiais/séries diferentes — mesma situação já resolvida
-- antes em pd_item_estagio, ver 06_pd_item_estagio_schema.sql), a query
-- do node ERP no n8n foi ajustada para incluir NF.FILIAL e NF.SERIE no
-- SELECT (id_filial, serie_nf). Avise se isso causar diferença nos
-- números.
--
-- "Faturado hoje" no painel passa a usar esta tabela: quantidade de
-- Notas Fiscais distintas (id_filial+serie_nf+id_nota_fiscal+
-- fl_entrada_saida) com tipo_movimentacao = 'Saida', fl_cancelado = 'N'
-- e dt_nf_emissao = hoje, e o valor é valor_total_nf (valor de cabeçalho
-- da NF, NF.VALOR_TOTAL), 1x por nota — não a soma de valor_total dos
-- itens, que ficava menor que o total real da NF.
-- =====================================================================

CREATE TABLE IF NOT EXISTS public.f_faturamento_hist7 (
  id                    bigserial PRIMARY KEY,
  id_filial             text NOT NULL,
  serie_nf              text NOT NULL,
  id_nota_fiscal        text NOT NULL,
  dt_nf_emissao         timestamptz,
  id_cfop               integer,
  natureza_operacao     text,
  fl_entrada_saida      text NOT NULL,
  fl_cancelado          text,
  tipo_movimentacao     text,
  status_pedido         text,
  peso                  numeric,
  id_pedido             text,
  dt_pedido_emissao     timestamptz,
  departamento_vendedor text,
  id_vendedor           text,
  id_tipo_comissao      integer,
  id_cliente            text,
  id_item               text NOT NULL,
  item_descricao        text,
  item_referencia       text,
  qtd_item              numeric,
  valor_unitario        numeric,
  valor_total           numeric,
  valor_total_nf        numeric,
  atualizado_em         timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT f_faturamento_hist7_chave_uk
    UNIQUE (id_filial, serie_nf, id_nota_fiscal, fl_entrada_saida, id_item)
);

-- Caso a tabela já tenha sido criada antes desta coluna existir, garante
-- que seja adicionada mesmo assim (idempotente).
-- valor_total_nf = NF.VALOR_TOTAL (valor de CABEÇALHO da nota, em
-- VDNOTAC) — repete igual em todas as linhas de item da mesma NF. É o
-- valor certo pro card "Faturado no dia": dá pra pegar 1x por nota
-- (MAX/qualquer linha, já que é igual em todas) em vez de somar os
-- itens (valor_total), que sofre com os filtros de FlagTipoComissao e
-- NIVEL01 da query e por isso ficava menor que o total real da NF.
ALTER TABLE public.f_faturamento_hist7
  ADD COLUMN IF NOT EXISTS valor_total_nf numeric;

CREATE INDEX IF NOT EXISTS f_faturamento_hist7_nf_idx
  ON public.f_faturamento_hist7 (id_filial, id_nota_fiscal);
CREATE INDEX IF NOT EXISTS f_faturamento_hist7_dt_emissao_idx
  ON public.f_faturamento_hist7 (dt_nf_emissao);
CREATE INDEX IF NOT EXISTS f_faturamento_hist7_tipo_idx
  ON public.f_faturamento_hist7 (tipo_movimentacao);
CREATE INDEX IF NOT EXISTS f_faturamento_hist7_atualizado_em_idx
  ON public.f_faturamento_hist7 (atualizado_em);

-- =====================================================================
-- Como confirmar:
-- 1. Rode este script no SQL Editor do Supabase.
-- 2. Rode 01_rls_policies.sql de novo (já inclui esta tabela).
-- 3. Importe o workflow n8n atualizado e execute — o branch
--    "ERP - Buscar f_faturamento_hist7" deve popular a tabela sem erros.
-- =====================================================================
