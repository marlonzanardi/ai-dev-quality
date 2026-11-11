# ai-dev-quality

Coleção de skills de IA para desenvolvimento, com quatro objetivos: menos código, mudanças pequenas, revisão rigorosa e código sem cara de IA. Funciona no Claude Code, Cursor, Codex e GitHub Copilot.

O repositório não copia as skills para dentro do Git. O `upstream.lock` guarda o repositório e o commit de cada uma, e o script baixa exatamente essa versão.

## Instalação

Requisitos: Git e Bash (no Windows, o Git Bash que vem com o Git for Windows). O Ponytail usa Node nos hooks do Claude Code. Se o Claude Code for escolhido e o comando `claude` não existir, o script instala o Claude Code pelo instalador oficial.

macOS, Linux ou Git Bash:

```bash
git clone https://github.com/marlonzanardi/ai-dev-quality.git
cd ai-dev-quality
bash install.sh
```

PowerShell (no Windows, `bash` costuma apontar para o WSL, por isso o caminho completo do Git Bash):

```powershell
git clone https://github.com/marlonzanardi/ai-dev-quality.git
cd ai-dev-quality
& "C:\Program Files\Git\bin\bash.exe" install.sh
```

O script pergunta para quais ferramentas instalar. Também dá para passar direto: `install.sh claude cursor`.

No fim, ele mostra o que foi instalado e um resumo de uso. Depois, reinicie a ferramenta.

Se o instalador do Claude Code avisar que `~/.local/bin` não está no PATH, adicione essa pasta ao PATH do usuário (no Windows: `%USERPROFILE%\.local\bin`) para usar o comando `claude` em terminais novos. A instalação dos plugins não depende disso.

## O que vem instalado

| Plugin | Origem | Para que serve |
|---|---|---|
| **ponytail** | [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) | Força a menor solução que funciona: primeiro pergunta se o código precisa existir, depois se já existe no projeto, na stdlib ou numa dependência. |
| **pstack** | [cursor/plugins/pstack](https://github.com/cursor/plugins/tree/main/pstack) | Skills e princípios do poteto. Remove comentários inúteis, tira cara de IA de texto, aplica TDD e boas práticas de TypeScript. |
| **thermos** | [cursor/plugins/thermos](https://github.com/cursor/plugins/tree/main/thermos) | Duas revisões severas em paralelo, uma de bugs e segurança e outra de qualidade de código, com os achados combinados no final. |
| **superpowers** | [obra/superpowers](https://github.com/obra/superpowers) | Fluxo de trabalho completo: brainstorming, plano, TDD, debug sistemático, verificação antes de dizer "pronto" e code review. |
| **karpathy** | [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) | Diretrizes curtas: pensar antes de codar, simplicidade, mudança cirúrgica e objetivo verificável. |

Os três primeiros vêm do vídeo que deu origem ao repositório. Superpowers e Karpathy são os conjuntos mais usados hoje para o mesmo objetivo.

## Como usar

### Automático

Estas skills a IA ativa sozinha quando o assunto da conversa bate com a descrição delas:

- **karpathy**: em qualquer escrita, revisão ou refatoração de código.
- **superpowers**: antes de criar algo (brainstorming), antes de implementar (plano e TDD), ao achar um bug (debug sistemático) e antes de concluir (verificação).
- **ponytail**: no Claude Code fica sempre ligado por um hook; nas outras ferramentas, entra quando o assunto bate.

### Sob demanda

| Comando | Quando usar |
|---|---|
| `/ponytail-review` | Antes do PR: revisa o diff procurando bugs, segurança, testes faltando e código a cortar. |
| `/ponytail-audit` | A mesma revisão no repositório inteiro. |
| `/no-comments` | Remove comentários desnecessários do diff. |
| `/unslop` | Tira cara de IA de **texto**, como descrição de PR, documentação e mensagens. |
| `/typescript-best-practices` | Ao mexer em `.ts`/`.tsx`. |
| `/tdd` | Bug com teste local barato: escreve primeiro o teste que falha. |
| `/blast-radius` | Descobre o que a mudança pode quebrar fora do diff. |
| `/poteto-mode` | Liga o modo completo do Pstack. |
| `/thermos` | Revisão final: bugs/segurança e qualidade em paralelo. |
| `/thermo-nuclear-review` | Só bugs, segurança e breaking changes. |
| `/thermo-nuclear-code-quality-review` | Só manutenibilidade: arquivos grandes, abstrações, código espaguete. |

No Claude Code, as skills de plugin aparecem com prefixo, por exemplo `/thermos:thermos` e `/pstack:no-comments`. Basta digitar `/` e o nome que o autocomplete encontra. No Codex, a skill é chamada com `$`, por exemplo `$thermos`.

### Fluxo sugerido por PR

1. Implementar. Karpathy, Superpowers e Ponytail atuam sozinhos.
2. `/no-comments` para limpar o diff.
3. `/ponytail-review` para cortar o que sobrou.
4. `/thermos` para a revisão final.
5. `/unslop` na descrição do PR.

## Como as skills funcionam

Uma skill é uma pasta com um `SKILL.md`. O arquivo começa com um cabeçalho (`name` e `description`) e o resto são instruções em Markdown.

```markdown
---
name: no-comments
description: Remove comentários desnecessários do diff.
disable-model-invocation: true
---

Instruções...
```

- No início da sessão, a ferramenta carrega só o `name` e a `description` de cada skill. O conteúdo completo entra no contexto apenas quando a skill é usada, então ter muitas skills instaladas custa pouco.
- A IA decide sozinha usar uma skill quando o pedido combina com a `description`. Você também pode chamar qualquer uma com `/nome`.
- Com `disable-model-invocation: true`, a skill só roda quando você chama. Todas as skills do Pstack são assim, exceto `setup-pstack`.

### Onde cada ferramenta procura

| Ferramenta | Todos os projetos (usuário) | Só um projeto |
|---|---|---|
| Claude Code | `~/.claude/skills/` ou plugins instalados com `--scope user` | `.claude/skills/` |
| Cursor | `~/.cursor/skills/` ou `~/.agents/skills/` | `.cursor/skills/` ou `.agents/skills/` |
| Codex | `~/.agents/skills/` | `.agents/skills/` |
| GitHub Copilot | `~/.copilot/skills/` ou `~/.agents/skills/` | `.github/skills/`, `.claude/skills/` ou `.agents/skills/` |

O `install.sh` usa:

- **Claude Code**: instala os 5 plugins no escopo do usuário, com o próprio repositório como marketplace local. Plugins também carregam subagentes e hooks, o que uma pasta de skills não faz. O Claude lê os plugins direto de `vendor/`, então não apague nem mova a pasta do repositório depois de instalar.
- **Cursor, Codex e Copilot**: copia as skills para `~/.agents/skills/`, a pasta que as três leem. Assim não há duplicata se você usar mais de uma.
- **Cursor**: copia também os subagentes do Pstack e do Thermos para `~/.cursor/agents/`.

O script anota em `~/.agents/skills/.ai-dev-quality` o que copiou. Ao reinstalar, remove só esses itens. Se você já tem uma skill com o mesmo nome, ela é mantida e o script avisa.

## Verificação de segurança

O `sync.sh` baixa cada plugin numa pasta temporária e pede ao Claude Code que leia o código antes de copiar para `vendor/`. A análise procura roubo de credenciais, execução de código remoto, ações destrutivas, persistência, ofuscação e instruções maliciosas nas skills. O relatório aparece no terminal e termina com `VEREDITO: APROVADO` ou `REPROVADO`. Se reprovar, `vendor/` não é alterado e a instalação para.

O Claude roda sem Bash, hooks, plugins nem MCP, só com Read, Grep e Glob. Assim, o código baixado não é executado durante a análise. Cada análise leva alguns minutos e consome uso da sua conta. Só os plugins cujo commit mudou são analisados de novo: os aprovados ficam anotados em `vendor/.verificado`.

A verificação exige o Claude Code instalado, mesmo para quem só instala no Cursor, Codex ou Copilot. Para pular por sua conta e risco: `SKIP_SCAN=1 bash install.sh`.

## Atualizar

```bash
bash sync.sh --update   # avança os commits do upstream.lock para a versão mais recente e verifica a segurança
git diff upstream.lock  # revise o que mudou
bash install.sh         # reinstala
```

No Claude Code, o `sync.sh` já basta, porque os plugins são lidos de `vendor/` e a mudança vale na próxima sessão (ou com `/reload-plugins`). Para Cursor, Codex e Copilot é preciso rodar o `install.sh`, que copia as skills de novo.

Quem só quer a versão já travada no repositório faz `git pull` e roda `bash install.sh`.

## Desativar um plugin

No Claude Code:

```bash
claude plugin disable superpowers@ai-dev-quality
```

Ou pelo painel `/plugin`. Nas outras ferramentas, apague a pasta da skill em `~/.agents/skills/`.

## Estrutura

```
.claude-plugin/marketplace.json   catálogo de plugins para o Claude Code
upstream.lock                     repositório e commit de cada plugin
sync.sh                           baixa os plugins, verifica a segurança e copia para vendor/ (ignorado pelo Git)
install.sh                        instala nas ferramentas escolhidas
```

## Licenças

Todos os plugins são de terceiros e mantêm a licença original, que é MIT em todos. O Ponytail, o Pstack, o Thermos e o Superpowers trazem o arquivo `LICENSE` na própria pasta dentro de `vendor/`. O do Karpathy declara MIT no `plugin.json`.
