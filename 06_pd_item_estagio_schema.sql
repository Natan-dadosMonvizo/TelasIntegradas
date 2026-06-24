-- =====================================================================
-- Tabela "pd_item_estagio" — grão por ITEM do pedido, com o estágio
-- exato (FlagEstagio) em que cada item está, a partir de 2026-01-01.
-- =====================================================================
-- Execute este script no SQL Editor do Supabase ANTES de importar o
-- workflow n8n atualizado. Depois, rode novamente o 01_rls_policies.sql
-- (já atualizado com esta tabela e a view abaixo) para liberar a
-- leitura via Anon Key no dashboard.
--
-- valor_pedido: o valor do pedido saiu de pd_ultimo_estagio (ver
-- 07_pd_ultimo_estagio_drop_valor.sql) e passou a morar aqui. Como esta
-- tabela é por ITEM, o mesmo valor_pedido se repete em todas as linhas
-- de um mesmo pedido — a view vw_pedido_status_estagio agrega isso com
-- MAX(valor_pedido) pra entregar 1 valor por pedido pro painel.
--
-- Observação sobre a query original do usuário: ela não trazia FILIAL
-- no SELECT final, só PEDIDO. Como o restante do projeto já trata
-- pedido+filial como a chave real (um mesmo número de pedido pode se
-- repetir em filiais diferentes — é assim em pd_ultimo_estagio), a
-- query do node ERP no n8n foi ajustada para incluir PVI.FILIAL no
-- SELECT. Avise se isso causar diferença nos números.
--
-- Por que uma VIEW agregando por pedido:
-- A tabela guarda 1 linha por item (várias linhas por pedido). Pro
-- painel, o que importa é o estágio "atual" do pedido como um todo —
-- e a regra usada é: o pedido só avança quando TODOS os itens
-- avançaram, então o item mais atrasado (MIN(flag_estagio), já que os
-- códigos crescem na ordem do fluxo: 000 → 251 aprovações → 301/351
-- faturado → 401 liberado p/ separação → 451 em separação → 501
-- separado → 601 enviado → 701 entregue) é quem define o status real
-- do pedido. Essa é uma decisão de modelagem minha — se a regra de
-- negócio for outra (ex.: MAX em vez de MIN, ou olhar só itens não
-- cancelados), me avise para ajustar.
-- =====================================================================

CREATE TABLE IF NOT EXISTS public.pd_item_estagio (
  id                 bigserial PRIMARY KEY,
  filial             text NOT NULL,
  pedido             text NOT NULL,
  data_emissao       timestamptz,
  nome_vendedor      text,
  nome_cliente       text,
  valor_pedido       numeric,
  item               text NOT NULL,
  descricao          text,
  flag_estagio       integer,
  qtd_pedida           numeric,
  qtd_faturada         numeric,
  qtd_entregue         numeric,
  valor_unitario       numeric,
  percentual_desconto  numeric,
  valor_desconto       numeric,
  valor_custo          numeric,
  valor_bruto_item     numeric,
  valor_final_item     numeric,
  desc_estagio       text,
  data_hora_inclusao timestamptz,
  status_resumo_erp  text,   -- status_resumo antigo (texto da OBSERVACAO), mantido só de referência
  atualizado_em      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT pd_item_estagio_filial_pedido_item_uk
    UNIQUE (filial, pedido, item)
);

-- Caso a tabela já tenha sido criada antes destas colunas existirem,
-- garante que sejam adicionadas mesmo assim (idempotente).
ALTER TABLE public.pd_item_estagio
  ADD COLUMN IF NOT EXISTS valor_pedido numeric;

-- Novas colunas (item: qtde pedida/faturada/entregue, preço unitário,
-- desconto, custo e valores bruto/final do item) — pedido do usuário.
ALTER TABLE public.pd_item_estagio
  ADD COLUMN IF NOT EXISTS qtd_pedida          numeric,
  ADD COLUMN IF NOT EXISTS qtd_faturada        numeric,
  ADD COLUMN IF NOT EXISTS qtd_entregue        numeric,
  ADD COLUMN IF NOT EXISTS valor_unitario      numeric,
  ADD COLUMN IF NOT EXISTS percentual_desconto numeric,
  ADD COLUMN IF NOT EXISTS valor_desconto      numeric,
  ADD COLUMN IF NOT EXISTS valor_custo         numeric,
  ADD COLUMN IF NOT EXISTS valor_bruto_item    numeric,
  ADD COLUMN IF NOT EXISTS valor_final_item    numeric;

CREATE INDEX IF NOT EXISTS pd_item_estagio_pedido_idx
  ON public.pd_item_estagio (filial, pedido);
CREATE INDEX IF NOT EXISTS pd_item_estagio_flag_idx
  ON public.pd_item_estagio (flag_estagio);

-- ---------------------------------------------------------------------
-- View: status agregado por pedido, derivado do estágio dos itens.
-- É essa view que o dashboard passa a consultar para classificar cada
-- pedido (substituindo o status_resumo baseado em texto da OBSERVACAO).
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW public.vw_pedido_status_estagio AS
SELECT
  filial,
  pedido,
  MIN(flag_estagio)        AS flag_estagio_atual,
  MAX(data_hora_inclusao)  AS data_hora_inclusao,
  MAX(valor_pedido)        AS valor_pedido, -- mesmo valor em todos os itens do pedido; MAX só pra agregar
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

GRANT SELECT ON public.vw_pedido_status_estagio TO anon;

-- Não esqueça de rodar 01_rls_policies.sql novamente depois deste
-- script, para habilitar RLS + policy de SELECT também na tabela
-- pd_item_estagio (a view já recebe GRANT explícito acima).
