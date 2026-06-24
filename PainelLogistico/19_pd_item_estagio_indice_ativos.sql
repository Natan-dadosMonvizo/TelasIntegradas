-- =====================================================================
-- Corrige o erro "canceling statement due to statement timeout" que
-- voltou a aparecer em pd_item_estagio, vw_pedido_status_estagio e
-- vw_item_faturado_qtd_pendente ao mesmo tempo.
--
-- CAUSA: pd_item_estagio só cresce desde 2026-01-01 (já passa de 3,6
-- milhões de linhas) e o painel buscava essa tabela INTEIRA (SELECT *
-- sem WHERE, paginado de 1000 em 1000) a cada atualização. Isso varre a
-- tabela toda repetidamente e disputa recursos com as duas views que
-- também leem de pd_item_estagio — daí as três falharem juntas.
--
-- FIX (já feito no index.html): o painel agora só busca itens com
-- flag_estagio < 501, ou seja, pedidos ainda ATIVOS (faturado ou em
-- separação). Pedidos já 100% SEPARADOS (>= 501) nunca eram usados pelo
-- painel mesmo antes, então isso não muda nenhum número exibido — só
-- corta a varredura de milhões de linhas pra só os itens em andamento.
--
-- Este índice parcial deixa esse novo filtro rápido (cobre exatamente a
-- condição usada, então o Postgres não precisa varrer a tabela inteira
-- pra achar as linhas ativas).
-- =====================================================================

CREATE INDEX IF NOT EXISTS idx_pd_item_estagio_ativo
  ON public.pd_item_estagio (flag_estagio)
  WHERE flag_estagio < 501;

-- =====================================================================
-- Como confirmar:
-- 1. Rode este script no SQL Editor do Supabase.
-- 2. Recarregue o link do painel — o card "Faturados e não separados" e
--    "Em separação" devem continuar com os mesmos números de antes, mas
--    sem o erro de timeout.
-- =====================================================================
