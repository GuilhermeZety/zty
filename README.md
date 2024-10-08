ZTY

CLI opensource para algus utilitários pro seu setup Flutter (Em breve outros framewors/linguagens)



## Sumário

- [Suporte](#suporte)
- [Configuração](#configuração)


### Suporte

- Flutter
- Dart
- Node


### Configuração

1. Instale o Dart com o brew ou alguma outra forma:

   `brew install dart-sdk`
   
2. Instale as dependências do projeto:

   `git clone https://github.com/GuilhermeZety/zty.git`

3. Entre na pasta

   `cd zty`
   
4. Instale as dependências do projeto:

   `dart pub get`
   
5. Ative a CLI:

   `dart pub global activate --source path .`

 * Pode ocorrer de dar problema nessa etapa onde será nessesário rodar o comando: 
   `export PATH="$PATH":"$HOME/.pub-cache/bin"`
 * Caso prefira utilizar com frequencia, recomendo colocar nas suas variaveis de ambiente :) 

<hr/>
Agora é só utilizar a CLI executando o comando no terminal:

   `zty -h`
