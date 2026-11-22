<!--
Título do PR no padrão Conventional Commits, por exemplo:
feat(ingestao): carregar estoque diario na raw_estoque
O título vira a mensagem do commit no squash merge.
-->

## O que muda

<!-- Em 2 a 5 linhas: o que este PR faz e por quê. -->

## Card

<!-- Troque o número pela issue do card. "Closes" fecha a issue no merge. -->
COL-000 · Closes #

## Como testei

<!-- Comandos que você rodou e o que conferiu. Cole saídas curtas quando ajudarem. -->

- [ ] `pytest` passou localmente
- [ ] Testado em **dev** (`colheita-dev-po14`)
- Comandos:

```bash

```

- Resultado conferido:

## Pontos de atenção

<!-- Apague o que não se aplica. -->

- **Custo:** cria recurso que cobra parado? Aumenta bytes consultados no BigQuery?
- **Segurança:** muda IAM, service account, segredo ou dado pessoal?
- **Terraform:** o `plan` destrói ou recria algum recurso? (cole o resumo `Plan: X to add, Y to change, Z to destroy`)
- **Dados:** muda esquema de tabela ou exige reprocessar datas (backfill)?
- **Dúvidas para quem revisa:**

## Checklist

- [ ] Branch no padrão `tipo/COL-000-descricao`
- [ ] Commits no padrão Conventional Commits
- [ ] Código idempotente (rodar duas vezes a mesma `data_ref` dá o mesmo resultado)
- [ ] Parametrizado por data de referência, sem data fixa no código
- [ ] Logs estruturados em JSON
- [ ] Testes com `pytest` criados ou atualizados (quando há Python)
- [ ] `terraform fmt` e `terraform validate` rodados (quando há Terraform)
- [ ] Nenhuma credencial, chave JSON, `.env` ou `.tfstate` no PR
- [ ] Recursos novos têm as labels `time`, `projeto` e `ambiente`
- [ ] Recursos novos estão em `southamerica-east1`
- [ ] Documentação atualizada (README, `docs/` ou descrição no Dataform)
- [ ] Critérios de aceite do card conferidos
