# ZTY

CLI opensource para utilitários do seu setup Flutter e outros frameworks. Uma ferramenta poderosa para gerenciar seus projetos de desenvolvimento.

## Sumário

- [Recursos](#recursos)
- [Suporte](#suporte)
- [Instalação](#instalação)
- [Comandos](#comandos)
- [Opções Globais](#opções-globais)

## Recursos

- Verificação de atualizações pendentes nos projetos
- Verificação de status do Git em múltiplos projetos
- Limpeza automática de projetos
- Gerenciamento de projetos obsoletos
- Atualização automática da CLI

## Suporte

- Flutter
- Dart
- Node

## Instalação

1. Instale o Dart SDK:
   ```bash
   brew install dart-sdk
   ```

2. Clone o repositório:
   ```bash
   git clone https://github.com/GuilhermeZety/zty.git
   ```

3. Entre na pasta do projeto:
   ```bash
   cd zty
   ```

4. Instale as dependências:
   ```bash
   dart pub get
   ```

5. Ative a CLI globalmente:
   ```bash
   dart pub global activate --source path .
   ```

   **Nota**: Se necessário, adicione o path do Dart ao seu PATH:
   ```bash
   export PATH="$PATH":"$HOME/.pub-cache/bin"
   ```
   Para uso permanente, adicione esta linha ao seu arquivo de configuração do shell (.bashrc, .zshrc, etc).

## Comandos

### verify
Verifica se há atualizações pendentes no seu projeto.
```bash
zty verify
```

### status
Verifica se possui algum projeto com pendências para subir ao git.
```bash
zty status
```

### clean
Verifica e gerencia a limpeza dos projetos.
```bash
zty clean            # Verifica projetos que precisam de limpeza
zty clean --apply    # Executa a limpeza em todos os projetos
```

### delete
Gerencia projetos obsoletos.
```bash
zty delete           # Lista projetos que podem ser movidos para lixeira
zty delete --apply   # Move os projetos selecionados para a lixeira
```

### update
Atualiza a CLI ZTY para a versão mais recente.
```bash
zty update
```

## Opções Globais

### --only
Executa o comando apenas nos projetos especificados.
```bash
zty clean --only projeto1,projeto2
```

### --ignore
Executa o comando em todos os projetos, exceto os especificados.
```bash
zty clean --ignore projeto1,projeto2
```

### --help, -h
Exibe a mensagem de ajuda com todos os comandos disponíveis.
```bash
zty --help
zty -h
```
