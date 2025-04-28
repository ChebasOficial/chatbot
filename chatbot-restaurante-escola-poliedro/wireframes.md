# Wireframes do Chatbot para Restaurante da Escola Palidro

## Visão Geral
Este documento apresenta os wireframes para o chatbot interativo do restaurante da Escola Palidro. O chatbot será responsável por interagir com alunos e funcionários, auxiliando no processo de pedidos, fornecendo informações sobre o cardápio, horários de funcionamento, promoções e outras dúvidas comuns.

## Estrutura do Chatbot

### 1. Interface Principal
A interface principal do chatbot consiste em:
- **Cabeçalho**: Contém o logo da Escola Palidro e o nome do restaurante
- **Corpo do Chat**: Área onde as mensagens são exibidas
- **Rodapé**: Contém botões de opções rápidas e campo para digitação de mensagens

### 2. Fluxos de Interação

#### 2.1 Fluxo de Boas-vindas
```
[Bot]: Olá! Bem-vindo ao Restaurante da Escola Palidro.
       Como posso ajudar você hoje?
       
[Opções]: Ver Cardápio | Promoções | Horário de Funcionamento | Fazer Pedido
```

#### 2.2 Fluxo de Cardápio
```
[Usuário]: Ver Cardápio

[Bot]: 📋 Cardápio do Restaurante:

       Prato Executivo - R$ 15.90
       Arroz, feijão, salada e proteína do dia
       
       Salada Caesar - R$ 12.50
       Alface, croutons, frango e molho caesar
       
       Sanduíche Natural - R$ 8.90
       Pão integral, frango, alface, tomate e cenoura
       
       Suco Natural - R$ 5.00
       Laranja, maracujá ou abacaxi
       
       Sobremesa do dia - R$ 6.50
       Pudim ou mousse de chocolate
```

#### 2.3 Fluxo de Promoções
```
[Usuário]: Promoções

[Bot]: 🎉 Promoções Especiais:

       Combo Estudante - R$ 22.90
       Prato executivo + suco + sobremesa
       
       Combo Funcionário - R$ 12.90
       Sanduíche + suco
```

#### 2.4 Fluxo de Horário de Funcionamento
```
[Usuário]: Horário de Funcionamento

[Bot]: ⏰ Horário de Funcionamento:

       Segunda a Sexta: 07:00 às 19:00
       Sábados: 08:00 às 14:00
       Domingos: Fechado
```

#### 2.5 Fluxo de Pedido
```
[Usuário]: Fazer Pedido

[Bot]: Para fazer um pedido, por favor informe:
       1. O item que deseja pedir
       2. Quantidade
       3. Observações (se houver)
       
       Exemplo: "Quero 1 Prato Executivo e 1 Suco de Laranja"

[Usuário]: Quero 1 Prato Executivo e 1 Suco de Laranja

[Bot]: Obrigado pelo seu pedido! Vou registrá-lo para você.
       
       Por favor, confirme os dados do seu pedido:
       
       Itens solicitados: Quero 1 Prato Executivo e 1 Suco de Laranja
       
       Está correto? Se sim, digite "confirmar". Se não, você pode refazer o pedido.

[Usuário]: confirmar

[Bot]: Pedido confirmado! Seu número de pedido é #12345.
       
       Resumo do pedido:
       - 1x Prato Executivo: R$ 15.90
       - 1x Suco de Laranja: R$ 5.00
       
       Total: R$ 20.90
       
       Seu pedido estará pronto em aproximadamente 15 minutos.
       Você pode retirá-lo no balcão do restaurante.
       
       Deseja algo mais?
```

#### 2.6 Fluxo de Geração de Guia de Produção (Interno)
Após a confirmação do pedido, o sistema gera automaticamente uma guia de produção para a cozinha:

```
===== GUIA DE PRODUÇÃO =====
Pedido #12345
Data/Hora: 23/04/2025 12:30

Cliente: [Nome do Aluno/Funcionário]

Itens:
- 1x Prato Executivo
- 1x Suco de Laranja

Observações: Nenhuma

Forma de pagamento: A definir no balcão
===========================
```

## Elementos de Design

### Cores
- **Principal**: Verde (#4CAF50) - Representa frescor e alimentos saudáveis
- **Secundária**: Branco (#FFFFFF) - Proporciona clareza e limpeza visual
- **Fundo**: Cinza claro (#F5F5F5) - Cria contraste suave com o conteúdo
- **Texto**: Cinza escuro (#333333) - Garante boa legibilidade

### Tipografia
- **Fonte principal**: Segoe UI - Moderna e de fácil leitura
- **Tamanhos**:
  - Títulos: 18px
  - Texto normal: 14px
  - Texto secundário: 12px

### Ícones e Elementos Visuais
- Ícones para representar categorias (cardápio, promoções, horários)
- Avatar do bot personalizado com cores da escola
- Botões de opções rápidas para facilitar a navegação

## Responsividade
O chatbot será responsivo, adaptando-se a diferentes tamanhos de tela:
- **Desktop**: Exibido como uma janela flutuante no canto inferior direito
- **Mobile**: Ocupará toda a tela para melhor experiência em dispositivos móveis

## Considerações de Acessibilidade
- Contraste adequado entre texto e fundo
- Tamanho de fonte legível
- Estrutura semântica para leitores de tela
- Botões com áreas de toque adequadas para dispositivos móveis
