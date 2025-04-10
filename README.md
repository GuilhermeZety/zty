# ZTY

CLI opensource para utilitários do seu setup Flutter e outros frameworks. Uma ferramenta poderosa para gerenciar seus projetos de desenvolvimento de forma eficiente e automatizada.

## Sumário

- [Recursos](#recursos)
- [Suporte](#suporte)
- [Instalação](#instalação)
- [Comandos](#comandos)
- [Opções Globais](#opções-globais)
- [Contribuição](#contribuição)

## Recursos

- Verificação de atualizações pendentes nos projetos
- Verificação de status do Git em múltiplos projetos
- Limpeza automática de projetos (cache, builds, etc.)
- Gerenciamento de projetos obsoletos
- Atualização automática da CLI
- Suporte a múltiplos projetos simultaneamente
- Opções flexíveis de filtragem de projetos

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
Verifica se há atualizações pendentes em todos os seus projetos Git.
```bash
zty verify
```
Este comando verifica todas as branches de cada projeto e informa se existem commits para serem baixados do repositório remoto.

### status
Verifica o status do Git em todos os projetos, identificando alterações não commitadas.
```bash
zty status
```
Exibe um resumo detalhado de arquivos modificados, não rastreados e commits não enviados para cada projeto.

### clean
Gerencia a limpeza dos projetos, removendo arquivos de build e caches.
```bash
zty clean            # Verifica projetos que precisam de limpeza
zty clean --apply    # Executa a limpeza em todos os projetos
```
Opções específicas:
- `--apply`: Executa a limpeza automaticamente
- `--only projeto1,projeto2`: Limpa apenas os projetos especificados
- `--ignore projeto1,projeto2`: Ignora os projetos especificados

### delete
Gerencia projetos obsoletos, permitindo movê-los para a lixeira de forma segura.
```bash
zty delete           # Lista projetos que podem ser movidos para lixeira
zty delete --apply   # Move os projetos selecionados para a lixeira
```
Opções específicas:
- `--apply`: Executa a movimentação dos projetos selecionados para a lixeira

### update
Atualiza a CLI ZTY para a versão mais recente do repositório.
```bash
zty update
```
Verifica, baixa e instala automaticamente a última versão disponível da CLI.

## Opções Globais

### --only
Executa o comando apenas nos projetos especificados.
```bash
zty clean --only projeto1,projeto2
```
Útil para focar em projetos específicos quando você tem muitos repositórios.

### --ignore
Executa o comando em todos os projetos, exceto os especificados.
```bash
zty clean --ignore projeto1,projeto2
```
Permite excluir projetos específicos da execução do comando.

### --help, -h
Exibe a mensagem de ajuda com todos os comandos disponíveis.
```bash
zty --help
zty -h
```

## Contribuição

Contribuições são sempre bem-vindas! Se você encontrou um bug ou tem uma sugestão de melhoria:

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Faça commit das suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request
