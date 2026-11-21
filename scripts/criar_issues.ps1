<#
.SYNOPSIS
  Cria as issues COL-001..COL-032 a partir de docs/backlog/issues-colheita.md
  e adiciona cada uma ao board do GitHub Projects, preenchendo Fase e Pontos.

.DESCRIPTION
  Idempotente: issue que ja existe (mesmo codigo COL-XXX no titulo) nao e criada de novo;
  so e adicionada/atualizada no board. Pode rodar quantas vezes quiser.

.EXAMPLE
  # Simulacao (nao cria nada, so mostra o que faria)
  .\scripts\criar_issues.ps1 -Owner SEU_USUARIO -Repo colheita -Projeto 1 -DryRun

  # Execucao real
  .\scripts\criar_issues.ps1 -Owner SEU_USUARIO -Repo colheita -Projeto 1
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $Owner,     # usuario ou organizacao dono do repo e do board
    [Parameter(Mandatory)] [string] $Repo,      # nome do repositorio, ex.: colheita
    [Parameter(Mandatory)] [int]    $Projeto,   # numero do board (aparece na URL .../projects/1)
    [string] $Arquivo = "docs/backlog/issues-colheita.md",
    [switch] $DryRun
)

$ErrorActionPreference = "Stop"
# Garante acentos corretos ao ler a saida do gh no Windows PowerShell 5.1
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = [Console]::OutputEncoding

# --- utilitarios ---------------------------------------------------------------

# Log estruturado em JSON (uma linha por evento)
function Write-Log([string]$Nivel, [string]$Msg, [hashtable]$Extra = @{}) {
    $evento = [ordered]@{ ts = (Get-Date).ToString("o"); nivel = $Nivel; msg = $Msg }
    foreach ($k in $Extra.Keys) { $evento[$k] = $Extra[$k] }
    Write-Host ($evento | ConvertTo-Json -Compress)
}

# Executa o gh e para o script se ele falhar
function Invoke-Gh([string[]]$Argumentos) {
    $saida = & gh @Argumentos
    if ($LASTEXITCODE -ne 0) { throw "gh falhou: gh $($Argumentos -join ' ')" }
    return $saida
}

# Le o Markdown e separa um bloco por issue (cada bloco comeca com "# COL-XXX ")
function Read-Issues([string]$Caminho) {
    $texto = [IO.File]::ReadAllText((Resolve-Path $Caminho), [Text.Encoding]::UTF8) -replace "`r`n", "`n"
    $blocos = [regex]::Split($texto, '(?m)^(?=# COL-\d{3} )') | Where-Object { $_ -match '^# COL-\d{3} ' }
    foreach ($bloco in $blocos) {
        $linhas = $bloco.Trim() -split "`n"
        $titulo = $linhas[0].Substring(2).Trim()
        if ($linhas[1] -notmatch 'fase:\s*(\d+)\s*\|\s*pontos:\s*(\d+)') { throw "Metadados ausentes em: $titulo" }
        $fase = [int]$Matches[1]; $pontos = [int]$Matches[2]
        $corpo = (($linhas[2..($linhas.Count - 1)]) -join "`n").Trim()
        $corpo = ($corpo -replace '(?s)\n---\s*$', '').Trim()   # remove o separador do fim
        [pscustomobject]@{
            Codigo = $titulo.Split(' ')[0]; Titulo = $titulo
            Fase = $fase; Pontos = $pontos; Corpo = $corpo
        }
    }
}

# --- 1. leitura e validacao ------------------------------------------------------

$issues = @(Read-Issues $Arquivo)
Write-Log "INFO" "issues lidas do arquivo" @{ quantidade = $issues.Count; arquivo = $Arquivo }
$validos = 1, 2, 3, 5, 8
foreach ($i in $issues) {
    if ($validos -notcontains $i.Pontos) { throw "$($i.Codigo): pontos invalidos ($($i.Pontos))" }
}

if ($DryRun) {
    $issues | Format-Table Codigo, Fase, Pontos, Titulo -AutoSize
    Write-Log "INFO" "dry run: nada foi criado"
    return
}

$repoCompleto = "$Owner/$Repo"
Invoke-Gh @("auth", "status") | Out-Null

# --- 2. labels fase-1..fase-10 (--force atualiza se ja existir) ------------------

foreach ($n in 1..10) {
    Invoke-Gh @("label", "create", "fase-$n", "-R", $repoCompleto, "--color", "1D76DB",
                "--description", "Fase $n do Projeto Colheita", "--force") | Out-Null
}
Write-Log "INFO" "labels de fase garantidas"

# --- 3. campos do board: Fase (selecao unica) e Pontos (numero) ------------------

function Get-Campos {
    (Invoke-Gh @("project", "field-list", "$Projeto", "--owner", $Owner,
                 "--format", "json", "--limit", "100") | Out-String | ConvertFrom-Json).fields
}

$campos = Get-Campos
if (-not ($campos | Where-Object name -eq "Fase")) {
    $opcoes = (1..10 | ForEach-Object { "Fase $_" }) -join ","
    Invoke-Gh @("project", "field-create", "$Projeto", "--owner", $Owner, "--name", "Fase",
                "--data-type", "SINGLE_SELECT", "--single-select-options", $opcoes) | Out-Null
    Write-Log "INFO" "campo Fase criado"
}
if (-not ($campos | Where-Object name -eq "Pontos")) {
    Invoke-Gh @("project", "field-create", "$Projeto", "--owner", $Owner, "--name", "Pontos",
                "--data-type", "NUMBER") | Out-Null
    Write-Log "INFO" "campo Pontos criado"
}
$campos       = Get-Campos
$campoFase    = $campos | Where-Object name -eq "Fase"
$campoPontos  = $campos | Where-Object name -eq "Pontos"
$campoStatus  = $campos | Where-Object name -eq "Status"
$opcaoBacklog = $null
if ($campoStatus) { $opcaoBacklog = $campoStatus.options | Where-Object name -eq "Backlog" }
$idProjeto = (Invoke-Gh @("project", "view", "$Projeto", "--owner", $Owner, "--format", "json") |
              Out-String | ConvertFrom-Json).id

# --- 4. issues existentes (para nao duplicar) ------------------------------------

$existentes = Invoke-Gh @("issue", "list", "-R", $repoCompleto, "--state", "all", "--limit", "500",
                          "--json", "number,title,url") | Out-String | ConvertFrom-Json

# --- 5. cria, adiciona ao board e preenche os campos -----------------------------

$tmp = Join-Path ([IO.Path]::GetTempPath()) "colheita_issue_corpo.md"
$criadas = 0; $puladas = 0

foreach ($i in $issues) {
    $achada = $existentes | Where-Object { $_.title -like "$($i.Codigo) *" } | Select-Object -First 1
    if ($achada) {
        $url = $achada.url; $puladas++
        Write-Log "INFO" "issue ja existe, pulando criacao" @{ codigo = $i.Codigo; url = $url }
    } else {
        # corpo vai por arquivo (UTF-8 sem BOM) para evitar problemas com aspas e quebras de linha
        [IO.File]::WriteAllText($tmp, $i.Corpo, (New-Object System.Text.UTF8Encoding($false)))
        $url = (Invoke-Gh @("issue", "create", "-R", $repoCompleto, "--title", $i.Titulo,
                            "--body-file", $tmp, "--label", "fase-$($i.Fase)") | Select-Object -Last 1).Trim()
        $criadas++
        Write-Log "INFO" "issue criada" @{ codigo = $i.Codigo; url = $url }
        Start-Sleep -Seconds 2   # evita o limite de criacao em sequencia do GitHub
    }

    # item-add devolve o item existente se a issue ja estiver no board
    $item = Invoke-Gh @("project", "item-add", "$Projeto", "--owner", $Owner, "--url", $url,
                        "--format", "json") | Out-String | ConvertFrom-Json

    $opcaoFase = $campoFase.options | Where-Object name -eq "Fase $($i.Fase)"
    Invoke-Gh @("project", "item-edit", "--id", $item.id, "--project-id", $idProjeto,
                "--field-id", $campoFase.id, "--single-select-option-id", $opcaoFase.id) | Out-Null
    Invoke-Gh @("project", "item-edit", "--id", $item.id, "--project-id", $idProjeto,
                "--field-id", $campoPontos.id, "--number", "$($i.Pontos)") | Out-Null
    # Status = Backlog so na criacao, para nao desfazer o andamento de issues antigas
    if ($opcaoBacklog -and -not $achada) {
        Invoke-Gh @("project", "item-edit", "--id", $item.id, "--project-id", $idProjeto,
                    "--field-id", $campoStatus.id, "--single-select-option-id", $opcaoBacklog.id) | Out-Null
    }
}

Remove-Item $tmp -ErrorAction SilentlyContinue
Write-Log "INFO" "concluido" @{ criadas = $criadas; ja_existiam = $puladas; total = $issues.Count }
