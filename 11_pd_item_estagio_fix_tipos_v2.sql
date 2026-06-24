-- =====================================================================
-- Correção urgente v2: a tentativa anterior (10) falhou porque a view
-- vw_pedido_status_estagio depende da coluna "filial" (e também usa
-- pedido/item indiretamente via GROUP BY). Postgres não deixa alterar o
-- tipo de uma coluna usada por uma view. Solução: remover a view,
-- alterar as colunas, recriar a view exatamente como era.
-- =====================================================================

-- 1) Remove a view que depende das colunas
DROP VIEW IF EXISTS public.vw_pedido_status_estagio;

-- 2) Corrige os tipos
ALTER TABLE public.pd_item_estagio
  ALTER COLUMN filial TYPE text USING filial::text;

ALTER TABLE public.pd_item_estagio
  ALTER COLUMN pedido TYPE text USING pedido::text;

ALTER TABLE public.pd_item_estagio
  ALTER COLUMN item TYPE text USING item::text;

-- 3) Recria a view (mesma definição de 06_pd_item_estagio_schema.sql)
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

-- 4) Confirma o resultado final
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'pd_item_estagio'
ORDER BY ordinal_position;
