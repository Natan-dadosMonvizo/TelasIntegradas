-- =====================================================================
-- Nova condição: "Faturado e não separado", calculada por QUANTIDADE
-- em vez de depender só do status/flag_estagio (que o usuário relatou
-- não estar sendo atualizado corretamente pelo ERP em alguns casos).
--
-- REGRA PEDIDA:
--   1) o ITEM do pedido está com status "FATURADO" (flag_estagio = 301,
--      mesmo valor já usado em todo o projeto pra essa classificação —
--      ver vw_pedido_status_estagio e pedidosFaturadoNaoSeparado() no
--      dashboard); E
--   2) a quantidade pedida é MAIOR que a quantidade entregue
--      (qtd_pedida > qtd_entregue) — ou seja, mesmo marcado como
--      faturado, o item ainda não foi 100% separado/entregue.
--
-- Quando qtd_pedida = qtd_faturada = qtd_entregue, o item está
-- totalmente concluído (não aparece aqui). Só entram os itens onde
-- ainda falta entregar parte (ou toda) a quantidade pedida.
--
-- Fonte: public.pd_item_estagio (1 linha por item, já alimentada pelo
-- ETL n8n a cada 20 min, colunas qtd_pedida/qtd_faturada/qtd_entregue
-- já existentes nessa tabela — não precisa de nó novo no n8n).
-- =====================================================================

-- 1) Índice parcial: cobre exatamente o filtro usado pela view, então
--    a consulta não precisa varrer a tabela inteira (pd_item_estagio só
--    cresce desde 2026-01-01). Mantém o custo de Disk IO baixo.
CREATE INDEX IF NOT EXISTS idx_item_estagio_faturado_qtd_pendente
  ON public.pd_item_estagio (filial, pedido)
  WHERE flag_estagio = 301 AND qtd_pedida > qtd_entregue;

-- 2) View (não materializada — é um filtro simples, sem GROUP BY, então
--    não tem o problema de timeout que obrigou vw_pedido_status_estagio
--    a virar materialized view; o índice parcial acima já garante que
--    fique rápida e barata).
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
WHERE flag_estagio = 301          -- item com status FATURADO
  AND qtd_pedida > qtd_entregue;  -- ainda falta entregar/separar parte da quantidade pedida

-- 3) Views não usam RLS/policy, usam GRANT direto (mesmo padrão das
--    outras views do projeto, ver nota em 01_rls_policies.sql).
GRANT SELECT ON public.vw_item_faturado_qtd_pendente TO anon;

-- =====================================================================
-- Como usar (a confirmar com o líder qual tela vai exibir isso):
--
-- - Granularidade é por ITEM (filial+pedido+item), igual pd_item_estagio.
--   Pra contar PEDIDOS distintos (não itens), agrupe por filial+pedido,
--   exatamente como o dashboard já faz em countDistinctPedidos() pras
--   outras tabelas.
-- - Pra ver no SQL Editor agora:
--     SELECT * FROM public.vw_item_faturado_qtd_pendente ORDER BY data_emissao;
-- - Pra contar pedidos distintos:
--     SELECT COUNT(DISTINCT (filial, pedido))
--     FROM public.vw_item_faturado_qtd_pendente;
-- =====================================================================
