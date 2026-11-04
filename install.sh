#!/usr/bin/env bash
# Baixa as skills e instala nas ferramentas escolhidas, para todos os projetos do usuário.
#
#   ./install.sh                          pergunta as ferramentas
#   ./install.sh claude cursor codex copilot
set -euo pipefail
shopt -s nullglob

cd "$(dirname "$0")"
root=$(pwd -W 2>/dev/null || pwd)
plugins=(ponytail pstack thermos superpowers karpathy)

g=$'\e[32m' y=$'\e[33m' c=$'\e[36m' b=$'\e[1m' d=$'\e[2m' r=$'\e[0m'
ok()    { echo "  ${g}✔${r} $*"; }
warn()  { echo "  ${y}!${r} $*"; }
title() { echo; echo "${b}${c}▸ $*${r}"; }

tools=("$@")
if (( ${#tools[@]} == 0 )); then
  title "Para quais ferramentas instalar?"
  cat <<EOF
  1) Claude Code     plugins completos (skills, subagentes, hooks)  ${d}→ ~/.claude${r}
  2) Cursor          skills e subagentes                            ${d}→ ~/.agents/skills, ~/.cursor/agents${r}
  3) Codex           skills                                         ${d}→ ~/.agents/skills${r}
  4) GitHub Copilot  skills                                         ${d}→ ~/.agents/skills${r}
  5) Todas
EOF
  while (( ${#tools[@]} == 0 )); do
    read -rp "  Escolha um ou mais números separados por espaço (ex.: 1 2): " picks
    for p in $picks; do
      case $p in
        1) tools+=(claude) ;;
        2) tools+=(cursor) ;;
        3) tools+=(codex) ;;
        4) tools+=(copilot) ;;
        5) tools=(claude cursor codex copilot) ;;
        *) warn "opção inválida: $p"; tools=(); break ;;
      esac
    done
  done
fi
echo "  Instalando para: ${b}${tools[*]}${r}"
has() { [[ " ${tools[*]} " == *" $1 "* ]]; }

title "Baixando skills nos commits do upstream.lock"
bash sync.sh

if has claude; then
  title "Claude Code  →  plugins no escopo do usuário"
  if ! command -v claude >/dev/null; then
    echo "  Instalando o Claude Code (instalador oficial)..."
    case "$(uname -s)" in
      MINGW* | MSYS* | CYGWIN*) powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "irm https://claude.ai/install.ps1 | iex" ;;
      *) curl -fsSL https://claude.ai/install.sh | bash ;;
    esac
    export PATH="$HOME/.local/bin:$PATH"
    ok "Claude Code $(claude --version)"
  fi

  claude plugin marketplace add "$root" >/dev/null
  for p in "${plugins[@]}"; do
    claude plugin install "$p@ai-dev-quality" --scope user >/dev/null
    ok "$p"
  done
fi

if has cursor || has codex || has copilot; then
  dir="$HOME/.agents/skills"
  list="$dir/.ai-dev-quality"
  title "Cursor / Codex / Copilot  →  ~/.agents/skills"
  mkdir -p "$dir"

  # Remove o que a instalação anterior copiou, sem tocar em skills do usuário.
  if [[ -f "$list" ]]; then
    while read -r s; do rm -rf "${dir:?}/$s"; done < "$list"
  fi
  : > "$list"

  for p in "${plugins[@]}"; do
    n=0
    for path in vendor/"$p"/skills/*/; do
      s=$(basename "$path")
      if [[ -e "$dir/$s" ]]; then
        warn "$s já existe em $dir, mantido o seu"
        continue
      fi
      cp -r "$path" "$dir/$s"
      echo "$s" >> "$list"
      n=$((n + 1))
    done
    ok "$p ${d}($n skills)${r}"
  done
fi

if has cursor; then
  mkdir -p "$HOME/.cursor/agents"
  agents=(vendor/*/agents/*.md)
  cp "${agents[@]}" "$HOME/.cursor/agents/"
  ok "subagentes ${d}(${#agents[@]} em ~/.cursor/agents)${r}"
fi

title "Como usar"
cat <<EOF
  ${b}Automático${r} ${d}(a IA aplica sozinha quando o assunto bate)${r}
    karpathy       pensar antes, solução simples, mudança cirúrgica
    superpowers    brainstorming → plano → TDD → debug → verificação → review
    ponytail       menor código que funciona ${d}(no Claude fica sempre ligado via hook)${r}

  ${b}Sob demanda${r}
    /ponytail-review                     revisa o diff: bugs, segurança, testes faltando, o que cortar
    /ponytail-audit                      a mesma revisão no repositório inteiro
    /no-comments                         remove comentários desnecessários do diff
    /unslop                              tira cara de IA de texto (descrição de PR, docs, mensagens)
    /typescript-best-practices           regras de TS/TSX
    /tdd                                 teste que falha primeiro, depois a correção
    /blast-radius                        o que a mudança pode quebrar fora do diff
    /poteto-mode                         modo completo do Pstack
    /thermos                             duas revisões em paralelo: bugs/segurança + qualidade
    /thermo-nuclear-review               só bugs, segurança e breaking changes
    /thermo-nuclear-code-quality-review  só manutenibilidade

  ${d}No Claude os comandos aparecem como /plugin:skill (ex.: /thermos:thermos). No Codex use \$skill.
  Reinicie a ferramenta para carregar as skills. Detalhes no README.md.${r}

${g}${b}✔ Pronto.${r}
EOF
