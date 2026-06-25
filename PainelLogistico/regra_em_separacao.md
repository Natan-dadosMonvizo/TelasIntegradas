# Painel "Em separação (>1 dia)" — regra e origem dos dados

## 1. Fonte primária: `historico_pedidos`
Colunas usadas: `filial`, `pedido`, `sequencia`, `status_resumo`, `data_hora_inclusao`.

- Para cada pedido (chave `filial+pedido`), pega só o evento **mais recente** (maior `data_hora_inclusao`; em caso de empate, maior `sequencia`).
- Filtra esse último evento por `status_resumo = 'EM SEPARAÇÃO'`.
- Calcula `dias = hoje - data_hora_inclusao` (dias corridos, sem considerar hora).
- Mantém só quem tem `dias > 1` (constante `DIAS_MIN_ESTAGIO` no config do painel).

## 2. Validação cruzada: `pd_item_estagio`
Colunas usadas: `filial`, `pedido`, `flag_estagio` (só linhas com `flag_estagio < 501`, ou seja, ainda ativas).

- Calcula o `MIN(flag_estagio)` por pedido = estágio **atual real** do pedido.
- Só mantém o pedido na lista final se esse mínimo for **exatamente 451** (= SEPARAÇÃO).

Por quê: o histórico (`historico_pedidos`) às vezes não é atualizado quando o item já avançou de estágio no ERP. Sem essa segunda checagem, um pedido já separado de fato continuaria aparecendo como "em separação" (falso positivo). Com as duas condições batendo, esse erro é eliminado.

## 3. Colunas exibidas na tabela (e de onde vêm)

| Coluna no painel | Origem | Regra de fallback |
|---|---|---|
| PD | `historico_pedidos.pedido` | — |
| Cliente | `f_pedido.nome_cliente` (por `id_pedido`) | se vazio, cai para `pd_ultimo_estagio.nome_cliente` (por `pedido`) |
| Vendedor | `f_pedido.nome_vendedor` (por `id_pedido`) | sem fallback (mostra "—" se vazio) |
| Valor | `f_pedido.valor_total_pedido` (por `id_pedido`) | se vazio: `historico_pedidos.valor_pedido` (da própria linha) → se vazio: `vw_pedido_status_estagio.valor_pedido` (por `filial+pedido`) → se vazio: mesma view, só por `pedido` |
| Data fat. | `historico_pedidos.data_hora_inclusao` | — |
| Dias | calculado: `hoje - data_hora_inclusao` | — |

## 4. Indicador visual (bolinha)
- 🔴 vermelha: `dias > 2`
- 🟡 amarela: `dias ≤ 2`

## 5. Badge numérico do card
Quantidade de pedidos distintos que passam pelas regras 1 e 2 acima.
