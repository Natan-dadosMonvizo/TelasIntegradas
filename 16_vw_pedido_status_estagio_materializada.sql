-- =====================================================================
-- Corrige o erro "canceling statement due to statement timeout" que
-- está zerando o painel.
--
-- CAUSA: vw_pedido_status_estagio é uma view normal — toda vez que é
-- consultada, o Postgres recalcula o GROUP BY filial,pedido em CIMA DE
-- TODA a tabela pd_item_estagio (que guarda 1 linha por ITEM, desde
-- 2026-01-01, então só cresce). O painel busca essa view em PÁGINAS de
-- 1000 linhas (fetchTodasLinhas), e cada página = um recálculo completo
-- da agregação do zero. Com a tabela maior depois de meses de uso, esse
-- recálculo repetido (a cada 90s, em várias páginas) passou a demorar
-- mais que o limite de tempo do Postgres (statement_timeout) e a
-- consulta é cancelada — daí o painel mostrar tudo zerado.
--
-- SOLUÇÃO: transformar a view em MATERIALIZED VIEW (uma "foto" já
-- calculada, salva em disco) e atualizar essa foto periodicamente em
-- vez de recalcular tudo a cada consulta do painel. Quem lê (o painel)
-- passa a só ler dados já prontos — rápido, sempre.
-- =====================================================================

-- 1) Remove a view antiga (recalculada a cada consulta)
DROP VIEW IF EXISTS public.vw_pedido_status_estagio;

-- 2) Cria a versão materializada (mesma lógica de sempre)
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

-- 3) Índice único exigido pra poder atualizar com REFRESH CONCURRENTLY
--    (atualiza sem bloquear quem está lendo a view ao mesmo tempo).
CREATE UNIQUE INDEX IF NOT EXISTS vw_pedido_status_estagio_uk
  ON public.vw_pedido_status_estagio (filial, pedido);

-- 4) Mesma permissão de leitura de antes
GRANT SELECT ON public.vw_pedido_status_estagio TO anon;

-- =====================================================================
-- IMPORTANTE — isso aqui é só a "foto". Ela só fica atualizada se algo
-- mandar atualizar. Escolha UMA das duas opções abaixo:
--
-- OPÇÃO A (recomendada, mais simples de manter): adicionar 1 nó no
-- workflow n8n, logo depois do nó que grava em pd_item_estagio, com uma
-- query Postgres/Supabase executando exatamente isto:
--
--     REFRESH MATERIALIZED VIEW CONCURRENTLY public.vw_pedido_status_estagio;
--
-- Assim a "foto" é renovada automaticamente sempre que o ETL atualiza
-- os itens — sem depender de nenhum recurso extra do Supabase.
--
-- OPÇÃO B (se preferir não tocar no n8n): habilitar a extensão pg_cron
-- no Supabase (Database > Extensions > pg_cron) e agendar a atualização
-- direto no banco, por exemplo a cada 5 minutos:
--
--     SELECT cron.schedule(
--       'refresh_vw_pedido_status_estagio',
--       '*/5 * * * *',
--       $$REFRESH MATERIALIZED VIEW CONCURRENTLY public.vw_pedido_status_estagio$$
--     );
--
-- Sem uma das duas opções acima, a view materializada vai ficar com os
-- dados "congelados" no momento em que este script foi executado.
-- =====================================================================

-- 5) Roda uma atualização agora, pra já nascer com dados frescos:
REFRESH MATERIALIZED VIEW public.vw_pedido_status_estagio;
