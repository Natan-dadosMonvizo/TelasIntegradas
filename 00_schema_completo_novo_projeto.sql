-- =====================================================================
-- SCHEMA COMPLETO para o NOVO projeto Supabase (substituto do projeto
-- atual, que esgotou o Disk IO Budget do plano free).
--
-- Este script recria, do zero, as 9 tabelas + 2 views usadas pelo
-- painel e pelo n8n, já no estado final (reconstruído a partir dos 19
-- arquivos de migração + dos nós do workflow n8n original).
--
-- COMO USAR:
-- 1. Abra o SQL Editor do projeto NOVO no Supabase.
-- 2. Cole este script inteiro e clique em "Run".
-- 3. Pronto — todas as tabelas, views, índices e policies de RLS já
--    ficam criadas de uma vez, prontas para o n8n gravar e o painel ler.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1) etl_controle
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.etl_controle (
  nome_tabela     text PRIMARY KEY,
  ultima_execucao timestamptz NOT NULL DEFAULT '2000-01-01T00:00:00Z',
  atualizado_em   timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- 2) pd_ultimo_estagio
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.pd_ultimo_estagio (
  filial               smallint NOT NULL,
  pedido               text NOT NULL,
  status               text,
  sequencia            integer,
  flag_tipo_alteracao  text,
  data_pedido          timestamptz,
  data_hora_inclusao   timestamptz,
  observacao           text,
  status_resumo        text,
  data_hora_alteracao  timestamptz,
  dias_no_estagio      integer,
  nome_cliente         text,
  atualizado_em        timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT pd_ultimo_estagio_filial_pedido_uk UNIQUE (filial, pedido)
);

-- ---------------------------------------------------------------------
-- 3) mo_3104
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.mo_3104 (
  pedido          text PRIMARY KEY,
  data_emissao    timestamptz,
  cliente         text,
  nome_cliente    text,
  vendedor        text,
  nome_vendedor   text,
  valor_total     numeric,
  qtd_faturada    numeric,
  qtd_entregue    numeric,
  diferenca       numeric,
  nota_fiscal     text,
  dt_faturamento  timestamptz,
  atualizado_em   timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- 4) pd_sem_intelipost
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.pd_sem_intelipost (
  id_pedido         text PRIMARY KEY,
  dt_pedido_emissao timestamptz,
  id_cliente        text,
  id_vendedor       text,
  nome_vendedor     text,
  id_transportadora text,
  transportadora    text,
  atualizado_em     timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- 5) pd_criado_despachado_intelipost
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.pd_criado_despachado_intelipost (
  id                 bigserial PRIMARY KEY,
  id_pedido          text NOT NULL,
  dt_pedido_emissao  timestamptz,
  id_cliente         text,
  id_vendedor        text,
  id_transportadora  text,
  transportadora     text,
  flagperfilcodigo   text,
  flagsituacao       text,
  desc_situacao      text,
  atualizado_em      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT pd_criado_despachado_intelipost_pedido_situacao_uk
    UNIQUE (id_pedido, flagsituacao)
);

CREATE INDEX IF NOT EXISTS pd_criado_despachado_intelipost_situacao_idx
  ON public.pd_criado_despachado_intelipost (flagsituacao);
CREATE INDEX IF NOT EXISTS pd_criado_despachado_intelipost_emissao_idx
  ON public.pd_criado_despachado_intelipost (dt_pedido_emissao);

-- ---------------------------------------------------------------------
-- 6) pd_item_estagio
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.pd_item_estagio (
  id                   bigserial PRIMARY KEY,
  filial               text NOT NULL,
  pedido               text NOT NULL,
  data_emissao         timestamptz,
  nome_vendedor        text,
  nome_cliente         text,
  valor_pedido         numeric,
  item                 text NOT NULL,
  descricao            text,
  flag_estagio         integer,
  qtd_pedida           numeric,
  qtd_faturada         numeric,
  qtd_entregue         numeric,
  valor_unitario       numeric,
  percentual_desconto  numeric,
  valor_desconto       numeric,
  valor_custo          numeric,
  valor_bruto_item     numeric,
  valor_final_item     numeric,
  desc_estagio         text,
  data_hora_inclusao   timestamptz,
  status_resumo_erp    text,
  atualizado_em        timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT pd_item_estagio_filial_pedido_item_uk
    UNIQUE (filial, pedido, item)
);

CREATE INDEX IF NOT EXISTS pd_item_estagio_pedido_idx
  ON public.pd_item_estagio (filial, pedido);
CREATE INDEX IF NOT EXISTS pd_item_estagio_flag_idx
  ON public.pd_item_estagio (flag_estagio);
CREATE INDEX IF NOT EXISTS idx_pd_item_estagio_ativo
  ON public.pd_item_estagio (flag_estagio)
  WHERE flag_estagio < 501;
CREATE INDEX IF NOT EXISTS idx_item_estagio_faturado_qtd_pendente
  ON public.pd_item_estagio (filial, pedido)
  WHERE flag_estagio = 301 AND qtd_pedida > qtd_entregue;

-- ---------------------------------------------------------------------
-- 7) historico_pedidos
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.historico_pedidos (
  id                  bigserial PRIMARY KEY,
  filial              text NOT NULL,
  pedido              text NOT NULL,
  status              text,
  valor_pedido        numeric,
  sequencia           integer NOT NULL,
  flag_tipo_alteracao text,
  data_pedido         timestamptz,
  data_hora_inclusao  timestamptz,
  data_hora_alteracao timestamptz,
  observacao          text,
  status_resumo       text,
  dias_desde_evento   integer,
  atualizado_em       timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT historico_pedidos_filial_pedido_sequencia_uk
    UNIQUE (filial, pedido, sequencia)
);

CREATE INDEX IF NOT EXISTS historico_pedidos_pedido_idx
  ON public.historico_pedidos (filial, pedido);
CREATE INDEX IF NOT EXISTS historico_pedidos_atualizado_em_idx
  ON public.historico_pedidos (atualizado_em);

-- ---------------------------------------------------------------------
-- 8) f_pedido
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.f_pedido (
  id_empresa                text,
  id_filial                 text,
  dt_emissao_pedido         timestamptz,
  dt_entrega_pedido         timestamptz,
  dt_previsao_entrega       timestamptz,
  dt_recebimento_mercadoria timestamptz,
  dt_inclusao               timestamptz,
  id_forma_pagamento        text,
  id_pedido                 text NOT NULL,
  id_pedido_sequencial      text,
  status_pedido             text,
  id_transportadora         text,
  nome_transportadora       text,
  id_coordenador            text,
  id_departamento           text,
  id_departamento_vendedor  text,
  id_vendedor               text,
  nome_vendedor             text,
  id_cliente                text,
  nome_cliente              text,
  cep_obra                  text,
  cidade_obra                text,
  uf_obra                   text,
  valor_total_pedido        numeric,
  valor_total_servico       numeric,
  valor_total_produto       numeric,
  inserido_em                timestamptz NOT NULL DEFAULT now(),
  atualizado_em              timestamptz,
  CONSTRAINT f_pedido_id_pedido_uk UNIQUE (id_pedido)
);

CREATE INDEX IF NOT EXISTS idx_f_pedido_id_pedido ON public.f_pedido (id_pedido);
CREATE INDEX IF NOT EXISTS idx_f_pedido_atualizado_em ON public.f_pedido (atualizado_em);

-- ---------------------------------------------------------------------
-- 9) f_faturamento_hist7
-- ---------------------------------------------------------------------
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

CREATE INDEX IF NOT EXISTS f_faturamento_hist7_nf_idx
  ON public.f_faturamento_hist7 (id_filial, id_nota_fiscal);
CREATE INDEX IF NOT EXISTS f_faturamento_hist7_dt_emissao_idx
  ON public.f_faturamento_hist7 (dt_nf_emissao);
CREATE INDEX IF NOT EXISTS f_faturamento_hist7_tipo_idx
  ON public.f_faturamento_hist7 (tipo_movimentacao);
CREATE INDEX IF NOT EXISTS f_faturamento_hist7_atualizado_em_idx
  ON public.f_faturamento_hist7 (atualizado_em);

-- ---------------------------------------------------------------------
-- 10) Views
-- ---------------------------------------------------------------------

-- View materializada de status agregado por pedido (substitui a view
-- normal, que dava timeout com a tabela grande).
DROP MATERIALIZED VIEW IF EXISTS public.vw_pedido_status_estagio;

CREATE MATERIALIZED VIEW public.vw_pedido_status_estagio AS
SELECT
  filial,
  pedido,
  MIN(flag_estagio)        AS flag_estagio_atual,
  MAX(data_hora_inclusao)  AS data_hora_inclusao,
  MAX(valor_pedido)        AS valor_pedido,
  CASE
    WHEN MIN(flag_estagio) IS NULL          THEN 'OUTROS'
    WHEN MIN(flag_estagio) <= 251           THEN 'OUTROS'
    WHEN MIN(flag_estagio) IN (301,351,401) THEN 'FATURADO'
    WHEN MIN(flag_estagio) = 451            THEN 'SEPARAÇÃO'
    WHEN MIN(flag_estagio) >= 501           THEN 'SEPARADO'
    ELSE 'OUTROS'
  END AS status_resumo
FROM public.pd_item_estagio
GROUP BY filial, pedido;

CREATE UNIQUE INDEX IF NOT EXISTS vw_pedido_status_estagio_uk
  ON public.vw_pedido_status_estagio (filial, pedido);

GRANT SELECT ON public.vw_pedido_status_estagio TO anon;

-- View "Faturado e não separado" (por quantidade)
CREATE OR REPLACE VIEW public.vw_item_faturado_qtd_pendente AS
SELECT
  filial,
  pedido,
  item,
  descricao,
  nome_vendedor,
  nome_cliente,
  data_emissao,
  flag_estagio,
  desc_estagio,
  qtd_pedida,
  qtd_faturada,
  qtd_entregue,
  (qtd_pedida - qtd_entregue) AS qtd_pendente,
  valor_pedido,
  valor_final_item,
  atualizado_em
FROM public.pd_item_estagio
WHERE flag_estagio = 301
  AND qtd_pedida > qtd_entregue;

GRANT SELECT ON public.vw_item_faturado_qtd_pendente TO anon;

-- ---------------------------------------------------------------------
-- 11) RLS — somente leitura (SELECT) para a chave pública (anon) usada
--     no painel. INSERT/UPDATE/DELETE continuam bloqueados para anon.
-- ---------------------------------------------------------------------
ALTER TABLE public.pd_ultimo_estagio              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mo_3104                        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.etl_controle                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pd_sem_intelipost               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pd_criado_despachado_intelipost ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pd_item_estagio                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.historico_pedidos               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.f_pedido                        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.f_faturamento_hist7              ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "tv_dashboard_select_only" ON public.pd_ultimo_estagio;
DROP POLICY IF EXISTS "tv_dashboard_select_only" ON public.mo_3104;
DROP POLICY IF EXISTS "tv_dashboard_select_only" ON public.etl_controle;
DROP POLICY IF EXISTS "tv_dashboard_select_only" ON public.pd_sem_intelipost;
DROP POLICY IF EXISTS "tv_dashboard_select_only" ON public.pd_criado_despachado_intelipost;
DROP POLICY IF EXISTS "tv_dashboard_select_only" ON public.pd_item_estagio;
DROP POLICY IF EXISTS "tv_dashboard_select_only" ON public.historico_pedidos;
DROP POLICY IF EXISTS "tv_dashboard_select_only" ON public.f_pedido;
DROP POLICY IF EXISTS "tv_dashboard_select_only" ON public.f_faturamento_hist7;

CREATE POLICY "tv_dashboard_select_only" ON public.pd_ultimo_estagio              FOR SELECT TO anon USING (true);
CREATE POLICY "tv_dashboard_select_only" ON public.mo_3104                        FOR SELECT TO anon USING (true);
CREATE POLICY "tv_dashboard_select_only" ON public.etl_controle                   FOR SELECT TO anon USING (true);
CREATE POLICY "tv_dashboard_select_only" ON public.pd_sem_intelipost               FOR SELECT TO anon USING (true);
CREATE POLICY "tv_dashboard_select_only" ON public.pd_criado_despachado_intelipost FOR SELECT TO anon USING (true);
CREATE POLICY "tv_dashboard_select_only" ON public.pd_item_estagio                 FOR SELECT TO anon USING (true);
CREATE POLICY "tv_dashboard_select_only" ON public.historico_pedidos               FOR SELECT TO anon USING (true);
CREATE POLICY "tv_dashboard_select_only" ON public.f_pedido                        FOR SELECT TO anon USING (true);
CREATE POLICY "tv_dashboard_select_only" ON public.f_faturamento_hist7              FOR SELECT TO anon USING (true);

-- =====================================================================
-- FIM. Depois de rodar este script:
-- 1. Confirme em Table Editor que as 9 tabelas + 2 views apareceram.
-- 2. Pegue a URL do projeto + a publishable/anon key (painel) e a
--    secret key (n8n) em Project Settings > API Keys.
-- 3. Me passe esses dados para eu atualizar o index.html e o n8n.
-- =====================================================================
