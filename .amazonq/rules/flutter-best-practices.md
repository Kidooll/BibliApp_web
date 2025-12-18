# Regras de Boas Práticas Flutter - BibliApp

## Widgets

### StatelessWidget vs StatefulWidget

#### Usar StatelessWidget quando:
- Widget não tem estado mutável
- Apenas renderiza dados recebidos
- Performance é crítica

#### Usar StatefulWidget quando:
- Precisa gerenciar estado local
- Tem animações
- Precisa de lifecycle methods

```dart
// ✅ StatelessWidget para UI pura
class UserCard extends StatelessWidget {
  final User user;
  const UserCard({required this.user});
  
  @override
  Widget build(BuildContext context) {
    return Card(child: Text(user.name));
  }
}

// ✅ StatefulWidget para estado
class CounterWidget extends StatefulWidget {
  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _counter = 0;
  
  @override
  Widget build(BuildContext context) {
    return Text('$_counter');
  }
}
```

### Keys

#### Quando Usar
- Listas dinâmicas (adicionar/remover items)
- Preservar estado em reordenação
- Widgets que mudam de posição

```dart
// ✅ Usar keys em listas
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ItemWidget(
      key: ValueKey(items[index].id),
      item: items[index],
    );
  },
);
```

### BuildContext

#### Regras
- NUNCA armazenar em variável de instância
- Usar apenas dentro de build() ou métodos síncronos
- Para async: verificar `mounted` antes de usar

```dart
// ❌ Evitar
class _MyScreenState extends State<MyScreen> {
  late BuildContext _context;
  
  @override
  Widget build(BuildContext context) {
    _context = context; // NUNCA fazer isso
    return Container();
  }
}

// ✅ Correto
Future<void> _loadData() async {
  await Future.delayed(Duration(seconds: 1));
  if (!mounted) return;
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Loaded')),
  );
}
```

## Gerenciamento de Estado

### Estado Local vs Global

#### Estado Local (setState)
- Contador de cliques
- Visibilidade de senha
- Estado de formulário
- Animações simples

#### Estado Global (Provider/Bloc)
- Autenticação
- Dados do usuário
- Carrinho de compras
- Configurações do app

```dart
// ✅ Estado local com setState
class _FormScreenState extends State<FormScreen> {
  bool _obscurePassword = true;
  
  void _togglePassword() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }
}

// ✅ Estado global com Provider
class AuthProvider extends ChangeNotifier {
  User? _user;
  
  User? get user => _user;
  
  Future<void> signIn(String email, String password) async {
    _user = await authService.signIn(email, password);
    notifyListeners();
  }
}
```

## Navegação

### Rotas Nomeadas
- Usar para navegação principal
- Facilita deep linking
- Melhor para grandes apps

```dart
// ✅ Definir rotas
MaterialApp(
  routes: {
    '/': (context) => HomeScreen(),
    '/login': (context) => LoginScreen(),
    '/profile': (context) => ProfileScreen(),
  },
);

// ✅ Navegar
Navigator.pushNamed(context, '/login');

// ✅ Passar argumentos
Navigator.pushNamed(
  context,
  '/profile',
  arguments: userId,
);
```

### Navegação Programática
- Usar para navegação condicional
- Melhor para fluxos complexos

```dart
// ✅ Push
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => DetailScreen(item: item)),
);

// ✅ Replace
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => HomeScreen()),
);

// ✅ Remove all and push
Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (context) => HomeScreen()),
  (route) => false,
);
```

## Async/Await

### Regras
- SEMPRE usar try-catch
- Verificar `mounted` antes de setState
- Usar FutureBuilder/StreamBuilder quando possível

```dart
// ✅ Correto
Future<void> _loadData() async {
  try {
    final data = await api.fetchData();
    if (!mounted) return;
    
    setState(() {
      _data = data;
    });
  } catch (e) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro: $e')),
    );
  }
}

// ✅ Ou usar FutureBuilder
FutureBuilder<Data>(
  future: api.fetchData(),
  builder: (context, snapshot) {
    if (snapshot.hasError) {
      return ErrorWidget(snapshot.error);
    }
    if (!snapshot.hasData) {
      return LoadingWidget();
    }
    return DataWidget(snapshot.data!);
  },
)
```

## Performance

### Otimizações Essenciais

#### 1. Const Constructors
```dart
// ✅ Usar const sempre que possível
const Text('Hello');
const SizedBox(height: 16);
const Padding(padding: EdgeInsets.all(8));
```

#### 2. ListView.builder
```dart
// ❌ Evitar para listas longas
ListView(
  children: items.map((item) => ItemWidget(item)).toList(),
);

// ✅ Usar builder
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
);
```

#### 3. RepaintBoundary
```dart
// ✅ Isolar widgets que mudam frequentemente
RepaintBoundary(
  child: AnimatedWidget(),
);
```

#### 4. Evitar Rebuilds
```dart
// ❌ Cria nova função a cada build
onPressed: () => _handlePress()

// ✅ Referência direta
onPressed: _handlePress
```

## Responsividade

### MediaQuery
```dart
// ✅ Usar para dimensões dinâmicas
final screenWidth = MediaQuery.of(context).size.width;
final isSmallScreen = screenWidth < 600;

Widget build(BuildContext context) {
  return Container(
    width: isSmallScreen ? screenWidth * 0.9 : 400,
    child: Content(),
  );
}
```

### LayoutBuilder
```dart
// ✅ Para layouts adaptativos
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < 600) {
      return MobileLayout();
    } else {
      return DesktopLayout();
    }
  },
);
```

## Formulários

### Validação
```dart
// ✅ Usar Form e TextFormField
class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
  
  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Processar formulário
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Campo obrigatório';
              }
              if (!value.contains('@')) {
                return 'Email inválido';
              }
              return null;
            },
          ),
          ElevatedButton(
            onPressed: _submit,
            child: Text('Enviar'),
          ),
        ],
      ),
    );
  }
}
```

## Imagens

### Otimização
```dart
// ✅ Usar cached_network_image
CachedNetworkImage(
  imageUrl: url,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
);

// ✅ Especificar dimensões
Image.network(
  url,
  width: 200,
  height: 200,
  fit: BoxFit.cover,
);

// ✅ Usar assets para imagens locais
Image.asset('assets/images/logo.png');
```

## Temas

### Centralização
```dart
// ✅ Definir tema global
MaterialApp(
  theme: ThemeData(
    primaryColor: AppColors.primary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  ),
);

// ✅ Usar tema no widget
Text(
  'Title',
  style: Theme.of(context).textTheme.headlineLarge,
);
```

## Acessibilidade

### Semântica
```dart
// ✅ Adicionar labels para screen readers
Semantics(
  label: 'Botão de login',
  button: true,
  child: ElevatedButton(
    onPressed: _login,
    child: Text('Login'),
  ),
);

// ✅ Usar Tooltip
Tooltip(
  message: 'Adicionar item',
  child: IconButton(
    icon: Icon(Icons.add),
    onPressed: _addItem,
  ),
);
```

## Internacionalização

### Setup
```dart
// pubspec.yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.18.0

// MaterialApp
MaterialApp(
  localizationsDelegates: [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: [
    Locale('pt', 'BR'),
    Locale('en', 'US'),
  ],
);

// Uso
Text(AppLocalizations.of(context)!.welcomeMessage);
```

## Debugging

### Ferramentas
```dart
// ✅ Debug prints
debugPrint('Value: $value');

// ✅ Assert para desenvolvimento
assert(user != null, 'User cannot be null');

// ✅ DevTools
// flutter pub global activate devtools
// flutter pub global run devtools

// ✅ Performance overlay
MaterialApp(
  showPerformanceOverlay: true,
);
```
