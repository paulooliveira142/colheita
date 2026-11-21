# COL-001 Ativar conta e faturamento
<!-- fase: 1 | pontos: 1 -->
**Fase 1 · Fundação** · Estimativa: **1 ponto**

## História de usuário
Como responsável pela plataforma de dados da Rede Sabiá, quero uma conta Google Cloud com faturamento ativo e alertas de orçamento, para poder criar recursos sem risco de gastos inesperados.

## Contexto técnico
- Conta Google com verificação em duas etapas (2FA) ativa.
- Conta de faturamento (billing account) com o crédito de avaliação gratuita, se disponível.
- Orçamento (budget) na conta de faturamento com alertas por e-mail em 50%, 90% e 100%.
- Budget **só avisa, não bloqueia** gastos. O bloqueio de verdade vem depois, em COL-025.

## Critérios de aceite
- [ ] `gcloud billing accounts list` mostra a conta de faturamento com `OPEN: True`.
- [ ] Existe um budget com valor mensal definido e alertas em 50%, 90% e 100%, enviados ao e-mail do responsável.
- [ ] A 2FA está ativa na conta Google usada no projeto.
- [ ] O valor do budget e a data de fim do crédito gratuito estão anotados no README do repositório.

## Fora do escopo
- Criar projetos (COL-002).
- Exportar o faturamento para o BigQuery (COL-025).
- Organização (Organization) e pastas do Resource Manager.

---

# COL-002 Criar projetos de dev e prd
<!-- fase: 1 | pontos: 2 -->
**Fase 1 · Fundação** · Estimativa: **2 pontos**
Depende de: COL-001

## História de usuário
Como engenheiro de dados, quero ambientes separados de desenvolvimento e produção, para testar mudanças sem afetar os dados que o negócio usa.

## Contexto técnico
- Projetos `colheita-dev-po14` e `colheita-prd-po14`, ambos vinculados à conta de faturamento.
- Labels: `time=dados`, `projeto=colheita`, `ambiente=dev|prd`.
- Ativar só as APIs mínimas para o Terraform começar: `cloudresourcemanager`, `serviceusage`, `iam`, `storage`. O resto será ativado por Terraform em COL-008.
- Configuração do gcloud por ambiente (`colheita-dev` e `colheita-prd`).

## Critérios de aceite
- [ ] `gcloud projects describe colheita-dev-po14` e `gcloud projects describe colheita-prd-po14` retornam `lifecycleState: ACTIVE`.
- [ ] `gcloud billing projects describe <projeto>` retorna `billingEnabled: true` para os dois projetos.
- [ ] `gcloud projects describe <projeto> --format="value(labels)"` mostra as três labels nos dois projetos.
- [ ] Duas configurações do gcloud existem e apontam para os projetos e a região `southamerica-east1`.

## Fora do escopo
- Criar datasets, buckets e service accounts (COL-008).
- Configurar IAM fino (COL-008 e COL-027).

---

# COL-003 Preparar a máquina
<!-- fase: 1 | pontos: 2 -->
**Fase 1 · Fundação** · Estimativa: **2 pontos**

## História de usuário
Como engenheiro de dados, quero minha máquina com todas as ferramentas do projeto instaladas e autenticadas, para rodar código, Terraform e containers localmente.

## Contexto técnico
- Seguir `setup/checklist-ambiente-windows.md` (Windows 10 + WSL2).
- Ferramentas: Git, Python 3.12, VS Code com extensões, Google Cloud CLI, Terraform, Docker Desktop e **GitHub CLI** (`winget install --id GitHub.cli -e`).
- Autenticação com ADC (`gcloud auth application-default login`), nunca com chave JSON de service account.

## Critérios de aceite
- [ ] `git --version`, `py -3.12 --version`, `gcloud version`, `terraform -version`, `docker version` (Client e Server) e `gh --version` funcionam em um terminal novo.
- [ ] `gh auth status` mostra login ativo com os escopos `repo` e `project`.
- [ ] O arquivo de ADC existe e **não** está dentro de nenhum repositório.
- [ ] `docker run --rm hello-world` termina com sucesso.
- [ ] Dificuldades encontradas foram registradas no checklist.

## Fora do escopo
- Airflow local (COL-020).
- Configurar o repositório e o pre-commit (COL-005).

---

# COL-004 Board e backlog
<!-- fase: 2 | pontos: 2 -->
**Fase 2 · Forma de trabalho** · Estimativa: **2 pontos**
Depende de: COL-003

## História de usuário
Como membro do time, quero um board com todo o backlog do projeto, para enxergar o que está planejado, em andamento e pronto.

## Contexto técnico
- GitHub Projects com nome `Colheita`.
- Colunas (campo Status): Backlog, A fazer, Em andamento, Em revisão, Feito.
- Campos extras: `Fase` (seleção única, Fase 1 a Fase 10) e `Pontos` (número).
- Labels `fase-1` a `fase-10`.
- Issues COL-001 a COL-032 criadas pelo script `scripts/criar_issues.ps1`, a partir de `docs/backlog/issues-colheita.md`.

## Critérios de aceite
- [ ] O board existe e tem as 5 colunas na ordem acima.
- [ ] As 32 issues aparecem no board, cada uma com `Fase` e `Pontos` preenchidos.
- [ ] Rodar o script uma segunda vez não cria issues duplicadas.
- [ ] Existe uma visão do board agrupada por `Fase`.

## Fora do escopo
- Automação de mudança de coluna por PR (pode virar card futuro).
- Sprints com campo de Iteração.

---

# COL-005 Repositório com proteções
<!-- fase: 2 | pontos: 3 -->
**Fase 2 · Forma de trabalho** · Estimativa: **3 pontos**
Depende de: COL-003

## História de usuário
Como engenheiro de dados, quero um repositório com regras que impeçam mudanças sem revisão e vazamento de segredos, para que a branch `main` seja sempre confiável.

## Contexto técnico
- Repositório `colheita` (monorepo) com pastas `terraform/`, `ingestao/`, `dataform/`, `airflow/`, `docs/`, `scripts/`.
- Ruleset na `main`: exigir pull request, exigir status check do Cloud Build (ativado após COL-009), bloquear force push e exclusão da branch.
- `.gitignore` com `*.tfstate*`, `.terraform/`, `.venv/`, `.env`, `*credentials*.json`.
- `.gitattributes` com `* text=auto eol=lf`, `.editorconfig`, template de PR e `CODEOWNERS`.
- `pre-commit` com `gitleaks` (detector de segredos), `ruff` e `terraform fmt`.

## Critérios de aceite
- [ ] Um `git push` direto na `main` é recusado pelo GitHub.
- [ ] Um commit de teste contendo uma chave falsa é bloqueado pelo `pre-commit`.
- [ ] Abrir um PR mostra o template preenchível.
- [ ] O README explica o padrão Conventional Commits com 3 exemplos (`feat:`, `fix:`, `chore:`).

## Fora do escopo
- Pipeline de CI no Cloud Build (COL-009).
- Validação automática da mensagem de commit (commitlint).

---

# COL-006 Rotina do time
<!-- fase: 2 | pontos: 1 -->
**Fase 2 · Forma de trabalho** · Estimativa: **1 ponto**

## História de usuário
Como membro do time, quero uma rotina combinada de planejamento, acompanhamento e revisão, para que o trabalho tenha ritmo e eu aprenda as cerimônias de um time de dados.

## Contexto técnico
- Documento `docs/rotina.md` com: duração da sprint (1 semana), planning, daily assíncrona, review e retro.
- Definição de Pronto para Começar (Definition of Ready) e Definição de Pronto (Definition of Done).
- Modelo de registro da daily (o que fiz, o que farei, bloqueios) em `docs/daily/`.

## Critérios de aceite
- [ ] `docs/rotina.md` existe com as quatro cerimônias, cada uma com objetivo, duração e saída esperada.
- [ ] A Definition of Done inclui: testes passando, PR revisado, documentação atualizada, custo verificado.
- [ ] A primeira planning foi registrada, com os cards escolhidos para a sprint 1.

## Fora do escopo
- Métricas de velocidade e gráfico de burndown.

---

# COL-007 Bucket de state do Terraform
<!-- fase: 3 | pontos: 2 -->
**Fase 3 · Infraestrutura como código** · Estimativa: **2 pontos**
Depende de: COL-002

## História de usuário
Como engenheiro de dados, quero o state do Terraform guardado em um bucket seguro e versionado, para não perder o controle da infraestrutura e poder voltar versões.

## Contexto técnico
- Um bucket por projeto: `colheita-dev-po14-tfstate` e `colheita-prd-po14-tfstate`, em `southamerica-east1`.
- Versionamento de objetos ativo, uniform bucket-level access, public access prevention `enforced`.
- Problema do ovo e da galinha (bootstrap): o bucket é criado uma única vez com `gcloud storage buckets create` e documentado em `terraform/bootstrap/README.md`.
- Backend `gcs` configurado em `terraform/envs/dev` e `terraform/envs/prd`.

## Critérios de aceite
- [ ] `gcloud storage buckets describe gs://colheita-dev-po14-tfstate` mostra versionamento ativo e `public_access_prevention: enforced`.
- [ ] `terraform init` em `envs/dev` usa o backend remoto sem erro.
- [ ] Depois de um `terraform apply`, o arquivo de state aparece no bucket e **não** aparece no repositório.
- [ ] Os comandos de bootstrap estão documentados e podem ser repetidos sem erro.

## Fora do escopo
- Recursos do projeto (COL-008).
- Criptografia com chave gerenciada pelo cliente (CMEK).

---

# COL-008 Recursos base com Terraform
<!-- fase: 3 | pontos: 8 -->
**Fase 3 · Infraestrutura como código** · Estimativa: **8 pontos**
Depende de: COL-007

## História de usuário
Como engenheiro de dados, quero todos os recursos base criados por código, para recriar os ambientes de forma igual e revisar mudanças em PR.

## Contexto técnico
- Módulos em `terraform/modules/`, ambientes em `terraform/envs/dev` e `terraform/envs/prd`.
- APIs: BigQuery, Cloud Storage, Cloud Run, Pub/Sub, Dataform, Secret Manager, Artifact Registry, Cloud Build, Logging, Monitoring.
- Service accounts: `sa-ingestao`, `sa-dataform`, `sa-airflow`, `sa-cloudbuild`, com papéis mínimos (por exemplo, `roles/bigquery.dataEditor` só nos datasets necessários).
- Datasets `raw_estoque`, `raw_vendas`, `raw_externo`, `raw_app`, `trusted`, `refined`, todos em `southamerica-east1`.
- Bucket de landing `colheita-<amb>-po14-landing` com regra de ciclo de vida (apagar após 30 dias em dev).
- Artifact Registry Docker `colheita`; tópico Pub/Sub `eventos_app`; segredos vazios no Secret Manager quando necessários.
- Labels `time`, `projeto`, `ambiente` em todo recurso que aceita labels.

## Critérios de aceite
- [ ] `terraform plan` em `envs/dev` logo após um `apply` mostra `No changes` (idempotência).
- [ ] `bq ls --project_id=colheita-dev-po14` lista os 6 datasets, todos com `location: southamerica-east1`.
- [ ] As 4 service accounts existem e nenhuma tem `roles/owner` ou `roles/editor`.
- [ ] Nenhuma chave de service account foi criada (`gcloud iam service-accounts keys list` mostra só chaves gerenciadas pelo Google).
- [ ] `terraform validate` e `terraform fmt -check` passam.

## Fora do escopo
- Ambiente do Airflow gerenciado (COL-022).
- Políticas de dados pessoais e policy tags (COL-028).
- Aplicar em `prd` (fica para depois do CI/CD, COL-009).

---

# COL-009 CI/CD no Cloud Build
<!-- fase: 3 | pontos: 5 -->
**Fase 3 · Infraestrutura como código** · Estimativa: **5 pontos**
Depende de: COL-005, COL-008

## História de usuário
Como engenheiro de dados, quero que cada PR seja validado e cada merge seja aplicado automaticamente, para entregar mudanças com segurança e sem passos manuais.

## Contexto técnico
- Conexão do Cloud Build com o GitHub (repositório de 2ª geração).
- Gatilho de PR (`cloudbuild/pr.yaml`): `ruff`, `pytest`, `terraform fmt -check`, `terraform validate`, `terraform plan` em dev.
- Gatilho de merge na `main` (`cloudbuild/deploy.yaml`): `terraform apply` em dev; build e push das imagens no Artifact Registry.
- Deploy em prd com **aprovação manual** no gatilho.
- Execução com `sa-cloudbuild`, impersonation, sem chave JSON.

## Critérios de aceite
- [ ] Um PR com teste quebrado fica com o check vermelho e não pode ser mergeado.
- [ ] Um PR válido mostra o resultado do `terraform plan` no log do build.
- [ ] Após o merge, o build de deploy roda e termina com sucesso em dev.
- [ ] O deploy em prd só começa depois de aprovado no console.
- [ ] O status check do Cloud Build está marcado como obrigatório no ruleset da `main`.

## Fora do escopo
- Deploy de DAGs no Airflow gerenciado (COL-022).
- Ambientes efêmeros por PR.

---

# COL-010 Gerador de dados fictícios
<!-- fase: 4 | pontos: 5 -->
**Fase 4 · Ingestão em lote** · Estimativa: **5 pontos**
Depende de: COL-008

## História de usuário
Como engenheiro de dados, quero gerar arquivos diários realistas de vendas e estoque das 40 lojas, para ter dados para ingerir e testar o pipeline inteiro.

## Contexto técnico
- Script Python 3.12 em `ingestao/gerador/`, com `Faker` (locale `pt_BR`).
- Cadastros fixos: 40 lojas, ~500 produtos, ~5.000 clientes (com CPF, e-mail e telefone **falsos**).
- Arquivos diários: `estoque/data_ref=AAAA-MM-DD/estoque.csv` e `vendas/data_ref=AAAA-MM-DD/vendas.jsonl`.
- Semente aleatória derivada da data de referência: a mesma data gera sempre os mesmos dados.
- Defeitos propositais e controlados (~1% de duplicados, nulos, datas inválidas) para testar a qualidade depois.
- Parâmetros: `--data-ref`, `--destino` (pasta local ou `gs://`).

## Critérios de aceite
- [ ] Rodar duas vezes com a mesma `--data-ref` gera arquivos idênticos (mesmo hash).
- [ ] Cada dia gera estoque para as 40 lojas e vendas em todas as lojas abertas.
- [ ] Existem produtos com estoque zero em algumas lojas (para o indicador de ruptura).
- [ ] `pytest` cobre: semente determinística, esquema das colunas e taxa de defeitos.
- [ ] Logs em JSON com `data_ref`, quantidade de linhas e destino.

## Fora do escopo
- Eventos do app (COL-014).
- Carga no BigQuery (COL-011 e COL-012).

---

# COL-011 Ingestão diária de estoque
<!-- fase: 4 | pontos: 5 -->
**Fase 4 · Ingestão em lote** · Estimativa: **5 pontos**
Depende de: COL-010

## História de usuário
Como analista de abastecimento, quero o estoque de cada loja carregado diariamente no BigQuery, para acompanhar a ruptura de produtos.

## Contexto técnico
- Cloud Run job `ingestao-estoque` (Python 3.12, imagem no Artifact Registry), executado com `sa-ingestao`.
- Lê `gs://colheita-<amb>-po14-landing/estoque/data_ref=<data>/` e grava em `raw_estoque.estoque_diario`.
- Tabela particionada por `data_ref`. Carga com `WRITE_TRUNCATE` **só na partição do dia** (`estoque_diario$AAAAMMDD`): rodar de novo substitui, não duplica.
- Colunas técnicas: `_arquivo_origem`, `_carregado_em`, `_id_execucao`.
- Dado gravado **como chegou** (tudo como STRING); a tipagem acontece na trusted.

## Critérios de aceite
- [ ] Executar o job duas vezes para a mesma data deixa a mesma contagem de linhas na partição.
- [ ] Executar para uma data sem arquivo termina com erro claro no log e código de saída diferente de zero.
- [ ] Logs em JSON aparecem no Cloud Logging com `data_ref`, `linhas_carregadas` e `duracao_segundos`.
- [ ] `pytest` cobre a montagem do caminho e da partição a partir da data.
- [ ] Nenhuma outra partição é alterada pela execução.

## Fora do escopo
- Agendamento (COL-021).
- Limpeza e tipagem (COL-017).

---

# COL-012 Ingestão diária de vendas
<!-- fase: 4 | pontos: 3 -->
**Fase 4 · Ingestão em lote** · Estimativa: **3 pontos**
Depende de: COL-011

## História de usuário
Como analista de vendas, quero as vendas de cada loja carregadas diariamente no BigQuery, para montar o painel diário de vendas.

## Contexto técnico
- Reaproveita o código do COL-011 (mesma imagem, parâmetro `--fonte vendas`) em vez de duplicar.
- Lê `vendas/data_ref=<data>/vendas.jsonl` e grava em `raw_vendas.vendas_diarias`, particionada por `data_ref`.
- Mesmo padrão de idempotência (substituir a partição) e de colunas técnicas.

## Critérios de aceite
- [ ] Executar duas vezes para a mesma data mantém a contagem de linhas.
- [ ] A soma de linhas no BigQuery é igual à quantidade de linhas do arquivo de origem (log mostra os dois números).
- [ ] O código compartilhado com o COL-011 tem testes e ambos os jobs continuam passando.
- [ ] Logs em JSON com os mesmos campos do COL-011.

## Fora do escopo
- Deduplicação de vendas repetidas (COL-017).
- Agendamento (COL-021).

---

# COL-013 Job de clima e feriados
<!-- fase: 5 | pontos: 3 -->
**Fase 5 · Fontes externas e streaming** · Estimativa: **3 pontos**
Depende de: COL-011

## História de usuário
Como analista de vendas, quero clima e feriados junto das vendas, para entender por que um dia vendeu mais ou menos.

## Contexto técnico
- Cloud Run job `ingestao-externo` com `sa-ingestao`.
- Clima diário por cidade das lojas em uma API pública sem chave (ex.: Open-Meteo); feriados nacionais (ex.: BrasilAPI). Confirmar termos de uso antes.
- Destino: `raw_externo.clima_diario` e `raw_externo.feriados`, particionadas.
- Retentativas com espera crescente (backoff) e tempo limite por chamada.
- Se alguma API exigir chave no futuro: guardar no Secret Manager, nunca no código.

## Critérios de aceite
- [ ] Executar duas vezes para a mesma data não duplica linhas.
- [ ] Com a API fora do ar (simulado em teste), o job tenta 3 vezes e falha com mensagem clara.
- [ ] `pytest` usa respostas gravadas (mock), sem chamar a internet.
- [ ] Clima existe para todas as cidades com loja.

## Fora do escopo
- Previsão do tempo futura.
- Feriados municipais.

---

# COL-014 Eventos do app em streaming
<!-- fase: 5 | pontos: 5 -->
**Fase 5 · Fontes externas e streaming** · Estimativa: **5 pontos**
Depende de: COL-008

## História de usuário
Como analista de produto, quero os eventos do app de delivery chegando no BigQuery em poucos segundos, para analisar o funil de compra.

## Contexto técnico
- Simulador Python em `ingestao/simulador_app/` que publica eventos JSON no tópico `eventos_app` (abrir app, buscar, adicionar ao carrinho, finalizar pedido).
- Assinatura BigQuery do Pub/Sub gravando direto em `raw_app.eventos`, com esquema definido.
- Tópico de mensagens com erro (dead-letter) `eventos_app_dlq`.
- Tabela particionada por dia de ingestão e com expiração de partição em dev.

## Critérios de aceite
- [ ] Eventos publicados aparecem em `raw_app.eventos` em menos de 1 minuto.
- [ ] Uma mensagem fora do esquema vai para a dead-letter, sem travar as demais.
- [ ] O simulador tem parâmetros de volume e duração e para sozinho ao fim.
- [ ] `pytest` valida o formato dos eventos gerados.

## Fora do escopo
- App real ou SDK de analytics.
- Processamento com Dataflow.

---

# COL-015 Spike opcional de CDC com Datastream
<!-- fase: 5 | pontos: 3 -->
**Fase 5 · Fontes externas e streaming** · Estimativa: **3 pontos** (tempo fixo de 1 dia)

## História de usuário
Como engenheiro de dados, quero experimentar a captura de mudanças (CDC) de um banco transacional, para saber se vale usar essa abordagem no lugar de arquivos diários.

## Contexto técnico
- Spike: investigação com tempo limitado, cuja entrega é **conhecimento**, não código de produção.
- Cloud SQL para PostgreSQL pequeno → Datastream → BigQuery, só em dev.
- **Risco de custo:** Cloud SQL e Datastream cobram enquanto existirem. Destruir tudo no mesmo dia.

## Critérios de aceite
- [ ] Um `INSERT` e um `UPDATE` no Postgres aparecem no BigQuery.
- [ ] `docs/adr/` tem um registro de decisão (ADR) com: o que funcionou, custo observado, prós, contras e recomendação.
- [ ] Todos os recursos do spike foram destruídos e o faturamento do dia seguinte confirma isso.

## Fora do escopo
- Levar CDC para produção.
- Card obrigatório: pode ser pulado sem afetar o projeto.

---

# COL-016 Configurar o Dataform
<!-- fase: 6 | pontos: 3 -->
**Fase 6 · Transformação** · Estimativa: **3 pontos**
Depende de: COL-008, COL-011

## História de usuário
Como engenheiro de dados, quero o Dataform conectado ao GitHub e aos ambientes, para versionar e executar as transformações SQL.

## Contexto técnico
- Repositório Dataform em `southamerica-east1`, ligado ao GitHub (token em Secret Manager).
- Decidir e registrar em ADR: projeto Dataform na raiz de um repositório próprio ou no monorepo.
- `workflow_settings.yaml` com variável `data_ref` e configurações por ambiente.
- Configuração de release (compilação) e de workflow (execução) para dev, executando com `sa-dataform`.
- Declarações (`declare`) das tabelas raw como fontes.

## Critérios de aceite
- [ ] `dataform compile` roda sem erro localmente e no console.
- [ ] Uma execução manual em dev cria uma tabela de teste no dataset `trusted`.
- [ ] As execuções usam `sa-dataform`, não a conta pessoal.
- [ ] O ADR da estrutura do repositório está escrito.

## Fora do escopo
- Modelos de negócio (COL-017 a COL-019).
- Agendamento pelo Airflow (COL-021).

---

# COL-017 Camada trusted
<!-- fase: 6 | pontos: 5 -->
**Fase 6 · Transformação** · Estimativa: **5 pontos**
Depende de: COL-016

## História de usuário
Como analista, quero dados limpos, tipados e sem duplicidade, para confiar nos números que uso.

## Contexto técnico
- Modelos `.sqlx` incrementais em `trusted`: `estoque`, `vendas`, `clima`, `feriados`, `eventos_app`, `lojas`, `produtos`, `clientes`.
- Converter tipos (STRING → DATE, NUMERIC, INT64), padronizar nomes em snake_case, remover duplicados por chave de negócio com `QUALIFY ROW_NUMBER()`.
- Reprocessar só a partição de `data_ref` (idempotente).
- Tabelas particionadas e clusterizadas; filtro de partição obrigatório.
- Linhas inválidas separadas em tabelas `_rejeitados`, em vez de descartadas em silêncio.

## Critérios de aceite
- [ ] Nenhuma chave de negócio aparece duplicada em `trusted.vendas` e `trusted.estoque` (assertion de unicidade).
- [ ] Reexecutar uma data mantém as contagens.
- [ ] Os defeitos propositais do gerador aparecem nas tabelas `_rejeitados`.
- [ ] Toda tabela e coluna tem descrição no Dataform.

## Fora do escopo
- Mascaramento de dados pessoais (COL-028).
- Modelo dimensional (COL-018).

---

# COL-018 Modelo estrela na refined
<!-- fase: 6 | pontos: 8 -->
**Fase 6 · Transformação** · Estimativa: **8 pontos**
Depende de: COL-017

## História de usuário
Como analista de negócio, quero fatos e dimensões organizados em modelo estrela, para fazer análises com consultas simples e rápidas.

## Contexto técnico
- Dimensões: `dim_loja`, `dim_produto`, `dim_data`, `dim_cliente` (sem dados pessoais diretos).
- Fatos: `fato_vendas` (grão: item vendido por cupom) e `fato_estoque_diario` (grão: produto × loja × dia).
- Chaves substitutas (surrogate keys) geradas por hash das chaves de negócio.
- Grão de cada fato documentado na descrição da tabela.

## Critérios de aceite
- [ ] Toda chave estrangeira dos fatos encontra correspondência na dimensão (assertion de integridade).
- [ ] O total de vendas da `fato_vendas` bate com o total da `trusted.vendas` para a mesma data.
- [ ] `docs/modelo_dados.md` tem o diagrama do modelo estrela e o grão de cada fato.
- [ ] Uma consulta de vendas por loja e mês processa menos de 100 MB (verificado com dry run).

## Fora do escopo
- Histórico de mudanças de cadastro (SCD tipo 2).
- Agregados do painel (COL-019).

---

# COL-019 Tabelas do painel
<!-- fase: 6 | pontos: 3 -->
**Fase 6 · Transformação** · Estimativa: **3 pontos**
Depende de: COL-018

## História de usuário
Como gerente regional, quero vendas diárias e o indicador de ruptura prontos para o painel, para agir rápido nas lojas com problema.

## Contexto técnico
- `refined.agg_vendas_diarias_loja`: receita, itens e ticket médio por loja e dia.
- `refined.agg_ruptura_diaria`: percentual de produtos ativos com estoque zero por loja e dia.
- Definição de ruptura escrita e aprovada **antes** do código (ex.: produto ativo, vendido nos últimos 30 dias, com estoque zero no fechamento).

## Critérios de aceite
- [ ] A definição de ruptura está em `docs/metricas.md`.
- [ ] Para uma loja e um dia escolhidos, o valor da tabela bate com um cálculo manual.
- [ ] As tabelas são atualizadas só na partição do dia.
- [ ] Nenhuma coluna de dado pessoal existe nessas tabelas.

## Fora do escopo
- Painel visual (COL-030).
- Previsão de ruptura.

---

# COL-020 Airflow local
<!-- fase: 7 | pontos: 3 -->
**Fase 7 · Orquestração** · Estimativa: **3 pontos**
Depende de: COL-003

## História de usuário
Como engenheiro de dados, quero rodar o Airflow na minha máquina, para desenvolver e testar DAGs sem custo de nuvem.

## Contexto técnico
- Docker Compose com a imagem oficial do Airflow, **na mesma versão** que será usada no Managed Service for Apache Airflow (versão a definir neste card e registrar nas instruções do projeto).
- Pasta `airflow/dags/` montada no container.
- Acesso ao GCP via ADC montado como volume somente leitura, com impersonation de `sa-airflow`.
- Teste de DAG com `pytest` (`DagBag` sem erros de importação).

## Critérios de aceite
- [ ] `docker compose up` sobe a interface em `http://localhost:8080`.
- [ ] A versão do Airflow local é igual à versão escolhida para o ambiente gerenciado.
- [ ] Uma DAG de exemplo executa uma consulta no BigQuery de dev com sucesso.
- [ ] `pytest airflow/tests` passa sem erros de importação.
- [ ] Nenhuma credencial é copiada para dentro da imagem ou do repositório.

## Fora do escopo
- DAG de produção (COL-021).
- Ambiente gerenciado (COL-022).

---

# COL-021 DAG diária de ponta a ponta
<!-- fase: 7 | pontos: 5 -->
**Fase 7 · Orquestração** · Estimativa: **5 pontos**
Depende de: COL-011, COL-012, COL-013, COL-019, COL-020

## História de usuário
Como gerente regional, quero o painel atualizado todo dia sem intervenção manual, para começar o dia com os números de ontem.

## Contexto técnico
- DAG `colheita_diaria`, agendada para rodar todo dia, com `data_ref` = `{{ ds }}`.
- Ordem: conferir arquivos na landing → jobs Cloud Run (estoque, vendas, externo) em paralelo → compilação e execução do Dataform → testes de qualidade → aviso de sucesso.
- Operadores do Google (`CloudRunExecuteJobOperator`, operadores do Dataform).
- Retentativas, tempo limite por tarefa e `catchup` controlado para reprocessar datas passadas (backfill).

## Critérios de aceite
- [ ] Uma execução para uma data passada atualiza raw, trusted, refined e as tabelas do painel.
- [ ] Rodar a mesma data duas vezes deixa os números iguais.
- [ ] Se um job falhar, as tarefas seguintes não rodam e a DAG fica vermelha.
- [ ] Backfill de 7 dias funciona com um único comando, documentado no README.

## Fora do escopo
- Alertas (COL-024).
- Streaming de eventos (já roda contínuo pelo Pub/Sub).

---

# COL-022 Publicar no Airflow gerenciado
<!-- fase: 7 | pontos: 5 -->
**Fase 7 · Orquestração** · Estimativa: **5 pontos**
Depende de: COL-009, COL-021

## História de usuário
Como engenheiro de dados, quero a DAG rodando em um Airflow gerenciado, para que o pipeline funcione sem depender da minha máquina.

## Contexto técnico
- Ambiente Managed Service for Apache Airflow criado por Terraform, no menor tamanho, em `southamerica-east1`, com `sa-airflow`.
- Deploy das DAGs pelo Cloud Build: copiar `airflow/dags/` para o bucket do ambiente após o merge.
- **Risco de custo alto:** o ambiente cobra por hora mesmo parado. Planejar janela de uso e destruir quando não precisar.

## Critérios de aceite
- [ ] O ambiente aparece como saudável no console.
- [ ] Um merge que altera uma DAG atualiza a DAG no ambiente em poucos minutos.
- [ ] A DAG diária executa com sucesso no ambiente gerenciado.
- [ ] O custo diário do ambiente foi medido e anotado no README, com o comando para destruí-lo.

## Fora do escopo
- Ambiente gerenciado em prd (decidir após medir o custo).
- Alta disponibilidade.

---

# COL-023 Testes de qualidade
<!-- fase: 8 | pontos: 3 -->
**Fase 8 · Operação** · Estimativa: **3 pontos**
Depende de: COL-019

## História de usuário
Como analista, quero que dados com problema sejam barrados antes do painel, para não tomar decisões com números errados.

## Contexto técnico
- Assertions do Dataform: unicidade, não nulo, valores aceitos, condições de linha.
- Verificações de atualidade (freshness) e de volume (ex.: vendas do dia entre 50% e 150% da média de 7 dias).
- Falha de qualidade interrompe a DAG antes de atualizar as tabelas do painel.

## Critérios de aceite
- [ ] Injetar um dia com vendas duplicadas faz a DAG falhar na etapa de qualidade.
- [ ] Um dia sem arquivo de vendas falha na verificação de atualidade.
- [ ] Os resultados das verificações ficam registrados em uma tabela de auditoria.
- [ ] Cobertura mínima: todas as tabelas `fato_*` e `agg_*` têm pelo menos 2 testes.

## Fora do escopo
- Ferramentas externas de observabilidade de dados.

---

# COL-024 Alertas e logs
<!-- fase: 8 | pontos: 3 -->
**Fase 8 · Operação** · Estimativa: **3 pontos**
Depende de: COL-021

## História de usuário
Como responsável pelo pipeline, quero ser avisado quando algo falhar, para corrigir antes que o negócio perceba.

## Contexto técnico
- Canal de notificação por e-mail no Cloud Monitoring.
- Políticas de alerta: falha de Cloud Run job, falha de DAG, mensagens acumuladas na dead-letter do Pub/Sub, falha de execução do Dataform.
- Métricas baseadas em logs a partir dos logs JSON (`nivel="ERROR"`).
- Consultas salvas no Logs Explorer para investigação.

## Critérios de aceite
- [ ] Forçar a falha de um job gera um e-mail de alerta em até 10 minutos.
- [ ] O alerta tem link direto para os logs da execução.
- [ ] Existem consultas salvas para: erros do dia, execuções por `data_ref` e mensagens na dead-letter.
- [ ] Alertas configurados por Terraform.

## Fora do escopo
- Integração com Slack ou PagerDuty.
- Plantão (on-call).

---

# COL-025 Controles de custo
<!-- fase: 8 | pontos: 3 -->
**Fase 8 · Operação** · Estimativa: **3 pontos**
Depende de: COL-008

## História de usuário
Como responsável pelo orçamento, quero limites técnicos de gasto e visibilidade de custos, para que um erro não gere uma conta alta.

## Contexto técnico
- Cota personalizada de bytes consultados por dia no BigQuery (por projeto e por usuário).
- `maximum_bytes_billed` nos jobs de consulta; `require_partition_filter` nas tabelas grandes.
- Exportação do faturamento para um dataset no BigQuery e consulta de custo por label.
- Ciclo de vida no bucket de landing e expiração de tabelas em dev.

## Critérios de aceite
- [ ] Uma consulta que excede a cota diária é bloqueada pelo BigQuery.
- [ ] Uma consulta sem filtro de partição em tabela grande é recusada.
- [ ] Existe uma consulta que mostra o custo por `ambiente` e por serviço.
- [ ] `docs/custos.md` lista os recursos que cobram mesmo parados e como desligá-los.

## Fora do escopo
- Desligamento automático por budget (Cloud Function de corte de faturamento).
- Reservas de capacidade do BigQuery.

---

# COL-026 Incidente simulado
<!-- fase: 8 | pontos: 2 -->
**Fase 8 · Operação** · Estimativa: **2 pontos**
Depende de: COL-023, COL-024

## História de usuário
Como membro do time, quero treinar a resposta a um incidente, para saber agir com calma quando um problema real acontecer.

## Contexto técnico
- Cenário: arquivo de vendas corrompido chega na landing e o painel do dia fica errado.
- Seguir o runbook: detectar, comunicar, conter, corrigir, reprocessar (backfill) e verificar.
- Pós-incidente sem culpados (postmortem blameless) em `docs/incidentes/`.

## Critérios de aceite
- [ ] O incidente foi detectado por alerta, não por acaso.
- [ ] Os dados da data afetada foram reprocessados e conferidos.
- [ ] O postmortem tem linha do tempo, causa raiz, impacto e pelo menos 2 ações de melhoria viradas em cards.

## Fora do escopo
- Incidentes de segurança.

---

# COL-027 Revisão de acessos
<!-- fase: 9 | pontos: 2 -->
**Fase 9 · Segurança e governança** · Estimativa: **2 pontos**
Depende de: COL-022

## História de usuário
Como responsável pela segurança, quero revisar quem acessa o quê, para garantir o menor privilégio possível.

## Contexto técnico
- Inventário de papéis IAM por projeto, dataset e bucket.
- Recomendações do IAM Recommender para papéis não usados.
- Matriz de acessos em `docs/acessos.md` (quem, qual papel, onde, por quê).

## Critérios de aceite
- [ ] Nenhuma service account tem papel básico (`owner`, `editor`, `viewer`) no projeto.
- [ ] Toda permissão na matriz tem justificativa.
- [ ] As recomendações aceitas foram aplicadas por Terraform.
- [ ] Nenhuma chave de service account existe nos dois projetos.

## Fora do escopo
- Políticas de organização (Organization Policies).
- Dados pessoais (COL-028).

---

# COL-028 Clientes com dados pessoais
<!-- fase: 9 | pontos: 5 -->
**Fase 9 · Segurança e governança** · Estimativa: **5 pontos**
Depende de: COL-017

## História de usuário
Como encarregado de dados pessoais (DPO), quero que CPF, e-mail e telefone dos clientes fiquem protegidos, para cumprir a LGPD.

## Contexto técnico
- Taxonomia de policy tags (Dataplex/Data Catalog) com a tag `dado_pessoal`, aplicada às colunas sensíveis na trusted.
- Mascaramento dinâmico de dados (ex.: hash ou nulo) para quem não tem o papel de leitor fino.
- Pseudonimização: `dim_cliente` usa chave derivada por hash com sal guardado no Secret Manager.
- Retenção definida para dados pessoais nas camadas raw.

## Critérios de aceite
- [ ] Um usuário sem permissão vê as colunas sensíveis mascaradas.
- [ ] `refined` não tem CPF, e-mail ou telefone em texto aberto.
- [ ] O sal não aparece no código nem nos logs.
- [ ] `docs/lgpd.md` lista os dados pessoais, onde estão, quem acessa e por quanto tempo ficam guardados.

## Fora do escopo
- Atendimento a pedidos de titulares (exclusão, portabilidade).
- Descoberta automática de dados sensíveis (Sensitive Data Protection).

---

# COL-029 Acesso do marketing
<!-- fase: 9 | pontos: 3 -->
**Fase 9 · Segurança e governança** · Estimativa: **3 pontos**
Depende de: COL-028

## História de usuário
Como analista de marketing, quero consultar vendas e clientes de forma agregada, para planejar campanhas sem ver dados pessoais.

## Contexto técnico
- Dataset `compartilhado_marketing` com views autorizadas (authorized views) sobre a refined.
- Papel de leitor só nesse dataset, concedido a um grupo ou usuário de teste.
- Opcional: segurança por linha (row-level security) por região.

## Critérios de aceite
- [ ] O usuário de marketing consulta as views, mas recebe erro de acesso negado ao tentar ler `refined` ou `trusted` direto.
- [ ] Nenhuma view expõe dado pessoal.
- [ ] Permissões criadas por Terraform e registradas na matriz de acessos.

## Fora do escopo
- Painel do marketing.
- Exportação de dados para ferramentas externas.

---

# COL-030 Painel no Looker Studio
<!-- fase: 10 | pontos: 3 -->
**Fase 10 · Entrega** · Estimativa: **3 pontos**
Depende de: COL-019, COL-021

## História de usuário
Como gerente regional, quero um painel com vendas diárias e ruptura por loja, para acompanhar a operação sem escrever SQL.

## Contexto técnico
- Fontes de dados: `refined.agg_vendas_diarias_loja` e `refined.agg_ruptura_diaria`.
- Páginas: visão geral, vendas por loja, ruptura por loja e produto.
- Filtros de data, região e loja; intervalo padrão = ontem.
- Credencial da fonte de dados: escolher entre "dono" e "visualizador" e registrar o motivo (impacta segurança e custo).

## Critérios de aceite
- [ ] Os números do painel batem com consultas diretas no BigQuery para a mesma data.
- [ ] O painel carrega com filtro de partição (verificado no histórico de jobs do BigQuery).
- [ ] O compartilhamento é restrito a pessoas específicas.

## Fora do escopo
- Looker (versão paga) e modelos LookML.
- Painéis para o app de delivery.

---

# COL-031 Runbook e documentação
<!-- fase: 10 | pontos: 3 -->
**Fase 10 · Entrega** · Estimativa: **3 pontos**
Depende de: COL-026

## História de usuário
Como pessoa nova no time, quero documentação clara da plataforma, para operar e evoluir o projeto sem depender de quem o construiu.

## Contexto técnico
- README com visão geral, diagrama da arquitetura e como rodar em dev.
- Runbook em `docs/runbook.md`: falha de ingestão, falha de Dataform, reprocessamento, rotação de segredo.
- Dicionário de dados gerado a partir das descrições do Dataform.
- Índice dos ADRs.

## Critérios de aceite
- [ ] Uma pessoa que não participou consegue reprocessar uma data seguindo só o runbook (teste de leitura).
- [ ] Cada falha conhecida do runbook tem sintoma, causa provável, passos e como confirmar a correção.
- [ ] Todos os links da documentação funcionam.

## Fora do escopo
- Site de documentação publicado.

---

# COL-032 Review, retro e encerramento
<!-- fase: 10 | pontos: 2 -->
**Fase 10 · Entrega** · Estimativa: **2 pontos**
Depende de: COL-030, COL-031

## História de usuário
Como membro do time, quero apresentar o resultado, refletir sobre o processo e desligar o que não for mais usado, para encerrar o projeto com aprendizado e sem custos esquecidos.

## Contexto técnico
- Review: demonstração do painel e do pipeline de ponta a ponta.
- Retro: o que funcionou, o que não funcionou, o que eu faria diferente.
- Encerramento (teardown): `terraform destroy` do que não ficará ativo, começando pelo Airflow gerenciado.

## Critérios de aceite
- [ ] A demo foi gravada ou registrada em `docs/review.md`.
- [ ] A retro tem pelo menos 3 aprendizados e 3 melhorias.
- [ ] O faturamento dos 3 dias seguintes ao encerramento está próximo de zero.
- [ ] O custo total do projeto foi calculado e registrado.

## Fora do escopo
- Novas funcionalidades.
