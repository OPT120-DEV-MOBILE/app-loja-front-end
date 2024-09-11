# app_lojas

Este é um aplicativo Flutter desenvolvido com objetivo de gerenciamento de lojas de diversos setores,
realizando o controle de empresas, funcionários, clientes, produtos e estoque com controle de vendas.
Apresentação de relatórios simples para informações de vendas totais, por funcionários ou clientes com
filtro de data.

Em sequência as instruções sobre como configurar o ambiente de desenvolvimento, instalar as dependências e rodar o projeto.

## Requisitos

Antes de começar, certifique-se de ter os seguintes itens instalados:

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Editor de código com suporte para Flutter (recomendado: [Visual Studio Code](https://code.visualstudio.com/) ou [Android Studio](https://developer.android.com/studio))
- Emulador Android ou dispositivo físico conectado
- [Xcode](https://developer.apple.com/xcode/) (para desenvolvimento iOS)
  
## Passos para configurar o projeto

### 1. Instalar o Flutter

Faça o download e instale o Flutter SDK a partir do [site oficial do Flutter](https://flutter.dev), seguindo o tutorial disponível na página de "Docs" -> "Install Flutter".

#### Configurar o PATH no sistema

Adicione o Flutter ao PATH do sistema, permitindo o uso dos comandos `flutter` no terminal.

### 2. Configurar o ambiente de desenvolvimento

Android para desenvolvimento e utilização do simulador de android:
Instale o Android Studio e certifique-se de configurar o Android SDK. [site oficial do Android Studio](https://developer.android.com/studio)
Configure um emulador Android ou conecte um dispositivo Android físico.

Visual Studio Code 
Oferecem plugins de Flutter e Dart para facilitar o desenvolvimento e teste.

### 3. Verificação se instalação do Flutter e Emulador

Depois de instalar o Flutter, execute o seguinte comando via cmd para verificar se tudo está configurado corretamente:

flutter doctor

### 4. Instalar dependências
Dependências do projeto são gerenciadas no arquivo pubspec.yaml. Para instalar as dependências, use:

flutter pub get

### 5. Executar o aplicativo
Para rodar o aplicativo, use o comando:

flutter run

Após será possível escolher a execução via emulador android, navegadores, etc ...


Licença MIT
