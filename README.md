# ZTY CLI ⚡

ZTY é uma CLI open-source projetada para otimizar e automatizar rotinas no seu setup de desenvolvimento. Uma ferramenta indispensável para gerenciar múltiplos projetos simultaneamente, fazer limpezas profundas, gerar builds e manter seu código limpo.

## 📑 Sumário

- [Recursos](#-recursos)
- [Ecossistemas Suportados](#-ecossistemas-suportados)
- [Instalação](#-instalação)
- [Comandos](#-comandos)
- [Filtros Globais](#-filtros-globais)
- [Contribuição](#-contribuição)

## ✨ Recursos

- **Gestão em Lote:** Trabalhe com múltiplos repositórios ao mesmo tempo.
- **Git Smart:** Verificação de status e atualizações pendentes em todos os seus projetos de uma vez.
- **Deep Clean:** Limpeza inteligente de cache, `node_modules`, `builds` e pastas temporárias.
- **Build Manager:** Geração automatizada de bundles (APK, AAB, IPA) concentrados em uma pasta limpa (`.bundles/`).
- **Dead Code Finder:** Análise estática avançada para encontrar pacotes, assets e arquivos órfãos em projetos Flutter (com suporte a arquitetura Monorepo).
- **Self-Update:** Atualização da própria CLI com um único comando.

## 🛠 Ecossistemas Suportados

A CLI é capaz de identificar e interagir com os seguintes tipos de projeto:
- Flutter / Dart **FUNCIONAL
- Node.js (JavaScript / TypeScript) **Não Testado
- PHP **Não Testado

---

## 🚀 Instalação

A ZTY CLI é construída em Dart. 
> 💡 **Dica:** Se você já é um desenvolvedor Flutter, o Dart já está instalado na sua máquina. Você pode pular o "Passo 1" e ir direto para o "Passo 2".

### Passo 1: Instalar o Dart SDK

**🍎 macOS (via Homebrew)**
```bash
brew tap dart-lang/dart
brew install dart
```

**🪟 Windows (via Chocolatey)**
Abra o PowerShell como Administrador e execute:
```powershell
choco install dart-sdk
```

**🐧 Linux**
```bash
# Usando apt (Debian/Ubuntu)
sudo apt-get update
sudo apt-get install apt-transport-https
wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/dart.gpg
echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main' | sudo tee /etc/apt/sources.list.d/dart_stable.list
sudo apt-get update
sudo apt-get install dart

# Ou usando snap
sudo snap install dart --classic
```

### Passo 2: Clonar e Ativar a CLI (Todos os Sistemas)
Abra seu terminal e execute os comandos abaixo para baixar e ativar a CLI globalmente:

```bash
# 1. Clone o repositório
git clone https://github.com/GuilhermeZety/zty.git

# 2. Acesse a pasta
cd zty

# 3. Baixe as dependências
dart pub get

# 4. Ative a CLI globalmente
dart pub global activate --source path .
```

### Passo 3: Configurar o PATH
Para que o comando `zty` funcione de qualquer lugar do seu terminal, você precisa garantir que a pasta de cache do Dart esteja nas suas variáveis de ambiente (`PATH`).

**🍎 macOS / 🐧 Linux**
Adicione a linha abaixo no final do seu arquivo `~/.zshrc` (se usar ZSH) ou `~/.bashrc` (se usar Bash):
```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"
```
*Após adicionar, reinicie o terminal ou rode `source ~/.zshrc`.*

**🪟 Windows**
1. Pressione a tecla `Windows` e digite **"Variáveis de Ambiente"**.
2. Clique em **"Editar as variáveis de ambiente do sistema"**.
3. Clique no botão **"Variáveis de Ambiente..."**.
4. Na lista de "Variáveis do usuário", selecione `Path` e clique em **Editar**.
5. Clique em **Novo** e adicione o seguinte caminho:
   `%LOCALAPPDATA%\Pub\Cache\bin`
6. Clique em OK em todas as janelas e reinicie seu terminal.

---

## 💻 Comandos


### `convert-icons` *(Novo)*
Processa uma pasta inteira de SVGs exportados por designers. Ele usa o Inkscape para converter "Strokes" em "Fills" (Traços em Caminhos), limpa tags sujas (metadados, styles), padroniza preenchimentos para `black` e renomeia tudo para `snake_case`.

> 💡 **FlutterIcon Ready:** Essa conversão e limpeza extrema garantem que os seus SVGs sejam **100% suportados no site [FlutterIcon](https://www.fluttericon.com/)** para a geração de WebFonts customizadas (eliminando de vez os bugs de renderização ou ícones que ficam invisíveis).

```bash
zty convert-icons
```
*O comando varre o diretório atual e salva os arquivos finais dentro da pasta `converted_icons/`.*


### `find` *(Novo)*
Executa uma análise de código morto profunda no seu projeto Flutter. Diferente de outros comandos, o `find` **deve ser executado na raiz de um projeto Flutter específico**.
```bash
zty find
```
**O que ele analisa (Suporta Monorepos):**
- 📦 **Packages:** Cruza o `pubspec.yaml` com o código para achar dependências não importadas.
- 🖼️ **Assets:** Lê os arquivos de mídia reais no disco e cruza com Strings no seu código para achar imagens não utilizadas.
- 📄 **Arquivos Dart:** Analisa referências cruzadas em todas as pastas `lib/` do projeto e de seus sub-módulos locais para encontrar arquivos soltos/órfãos.

### `clean`
Inspeciona e limpa pastas de build, cache, `node_modules` e `vendor`.
```bash
zty clean            # Inspeciona e lista o que precisa de limpeza
zty clean --apply    # Executa a limpeza pesada nos projetos
```

### `build`
Gera os aplicativos compilados para Android e iOS. Funciona apenas na raiz de projetos Flutter.
```bash
zty build            # Gera AppBundle (.aab) para Android e IPA para iOS
zty build --apk      # Gera um .apk ao invés do AppBundle
```
*Dica: Os arquivos compilados serão organizados automaticamente dentro de uma pasta oculta `.bundles/` na raiz do seu projeto.*

### `verify`
Verifica se há commits pendentes no repositório remoto para todos os seus projetos locais.
```bash
zty verify
```

### `status`
Resume o status atual do Git (arquivos modificados, unstaged) de todos os projetos simultaneamente.
```bash
zty status
```

### `delete`
Ferramenta para envio seguro de projetos obsoletos para a lixeira do sistema.
```bash
zty delete           # Lista candidatos a exclusão
zty delete --apply   # Move os projetos selecionados para a lixeira
```

### `update`
Atualiza a sua própria CLI para a última versão disponível no Github.
```bash
zty update
```

---

## 🎯 Filtros Globais

Comandos que atuam em lote (como `clean`, `verify`, `status`) aceitam os seguintes modificadores para filtrar onde a ação será executada:

### `--only`
Restringe a execução apenas aos projetos especificados.
```bash
zty clean --apply --only app_mobile,backend_api
```

### `--ignore`
Executa em todos os projetos descobertos, **exceto** os especificados.
```bash
zty status --ignore projeto_legado,api_velha
```

---

## 🤝 Contribuição

A ZTY CLI é open-source e contribuições são sempre bem-vindas! Para contribuir:

1. Faça um *Fork* do projeto
2. Crie uma branch com a sua feature (`git checkout -b feature/minha-feature`)
3. Faça o commit das suas mudanças (`git commit -m 'feat: adicionando nova funcionalidade X'`)
4. Faça o push para a branch (`git push origin feature/minha-feature`)
5. Abra um **Pull Request** descrevendo o que foi alterado.

***
*Desenvolvido por Guilherme Zety.*
