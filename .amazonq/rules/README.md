# Regras do Projeto BibliApp

Este diretório contém as regras e padrões que devem ser seguidos no desenvolvimento do BibliApp.

## 📚 Arquivos de Regras

### 🔒 [security.md](./security.md)
Regras de segurança e validação de dados:
- Validação de entrada (email, senha, IDs)
- Gerenciamento de credenciais
- Tratamento de erros
- Proteção contra SQL injection
- Armazenamento seguro de dados

### 🏗️ [architecture.md](./architecture.md)
Padrões de arquitetura e estrutura:
- Estrutura de pastas
- Separação de responsabilidades
- Dependency Injection
- Tamanho de widgets e classes
- Abstrações e interfaces

### ✨ [code-quality.md](./code-quality.md)
Qualidade e padrões de código:
- Nomenclatura
- Documentação
- Constantes e magic numbers
- Null safety
- Performance
- Testes

### 📱 [flutter-best-practices.md](./flutter-best-practices.md)
Boas práticas específicas do Flutter:
- Widgets (StatelessWidget vs StatefulWidget)
- Gerenciamento de estado
- Navegação
- Async/Await
- Performance
- Responsividade
- Acessibilidade

## 🎯 Como Usar

### Durante o Desenvolvimento
1. Consulte as regras antes de implementar novas features
2. Use como checklist durante code review
3. Configure seu IDE para seguir os padrões

### Com Amazon Q Developer
As regras são automaticamente carregadas pelo Amazon Q quando você:
- Faz perguntas sobre o projeto
- Pede para implementar features
- Solicita code review
- Pede refatoração de código

### Exemplo de Uso
```
Você: "Preciso criar um novo service para gerenciar notificações"

Amazon Q: *Consulta security.md e architecture.md*
"Vou criar o NotificationService seguindo os padrões do projeto:
1. Interface abstrata para facilitar testes
2. Dependency Injection via GetIt
3. Validação de entrada
4. Tratamento de erros com logging
5. Separação em camadas (data/domain/presentation)"
```

## 🔄 Atualização das Regras

As regras devem ser atualizadas quando:
- Novos padrões são adotados pela equipe
- Problemas recorrentes são identificados
- Tecnologias/packages são atualizados
- Feedback de code review sugere melhorias

## 📋 Checklist Rápido

Antes de commitar código, verifique:

### Segurança
- [ ] Validação de entrada implementada
- [ ] Sem credenciais hardcoded
- [ ] Tratamento de erros adequado
- [ ] Dados sensíveis protegidos

### Arquitetura
- [ ] Separação de responsabilidades
- [ ] Dependency Injection usado
- [ ] Widgets < 300 linhas
- [ ] Abstrações para services externos

### Qualidade
- [ ] Sem magic numbers
- [ ] Documentação presente
- [ ] Null safety correto
- [ ] Testes escritos

### Flutter
- [ ] Const constructors usados
- [ ] BuildContext usado corretamente
- [ ] Subscriptions canceladas em dispose()
- [ ] Performance otimizada

## 🚀 Próximos Passos

1. **Refatoração Gradual**: Aplicar regras ao código existente
2. **CI/CD**: Integrar verificações automáticas
3. **Treinamento**: Compartilhar regras com a equipe
4. **Monitoramento**: Acompanhar aderência às regras

## 📞 Suporte

Para dúvidas sobre as regras:
1. Consulte os arquivos de regras específicos
2. Pergunte ao Amazon Q Developer
3. Discuta com a equipe em code review
4. Proponha melhorias via pull request

---

**Última atualização:** 2024
**Versão:** 1.0.0
