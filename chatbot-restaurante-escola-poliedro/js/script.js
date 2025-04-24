// Script para o chatbot do Restaurante Escola Palidro
document.addEventListener('DOMContentLoaded', function() {
    const chatBody = document.querySelector('.chat-body');
    const chatForm = document.querySelector('.chat-form');
    const messageInput = document.querySelector('.message-input');
    const optionButtons = document.querySelectorAll('.option-btn');
    const chatbotToggler = document.getElementById('chatbot-toggler');
    const chatbotContainer = document.querySelector('.chatbot-container');
    const closeChatbot = document.getElementById('close-chatbot');
    
    // Dados do cardápio
    const cardapio = {
        pratos: [
            { nome: "Prato Executivo", descricao: "Arroz, feijão, salada e proteína do dia", preco: 15.90 },
            { nome: "Salada Caesar", descricao: "Alface, croutons, frango e molho caesar", preco: 12.50 },
            { nome: "Sanduíche Natural", descricao: "Pão integral, frango, alface, tomate e cenoura", preco: 8.90 },
            { nome: "Suco Natural", descricao: "Laranja, maracujá ou abacaxi", preco: 5.00 },
            { nome: "Sobremesa do dia", descricao: "Pudim ou mousse de chocolate", preco: 6.50 }
        ],
        promocoes: [
            { nome: "Combo Estudante", descricao: "Prato executivo + suco + sobremesa", preco: 22.90 },
            { nome: "Combo Funcionário", descricao: "Sanduíche + suco", preco: 12.90 }
        ]
    };
    
    // Horário de funcionamento
    const horario = {
        diasUteis: "Segunda a Sexta: 07:00 às 19:00",
        sabados: "Sábados: 08:00 às 14:00",
        domingos: "Fechado"
    };
    
    // Toggle do chatbot
    chatbotToggler.addEventListener('click', function() {
        this.classList.toggle('active');
        chatbotContainer.classList.toggle('active');
    });
    
    // Fechar chatbot
    closeChatbot.addEventListener('click', function() {
        chatbotToggler.classList.remove('active');
        chatbotContainer.classList.remove('active');
    });
    
    // Função para adicionar mensagem ao chat
    function addMessage(message, isUser = false) {
        const messageDiv = document.createElement('div');
        messageDiv.classList.add('message');
        
        if (isUser) {
            messageDiv.classList.add('user-message');
            messageDiv.innerHTML = `
                <div class="message-text">${message}</div>
            `;
        } else {
            messageDiv.classList.add('bot-message');
            messageDiv.innerHTML = `
                <div class="bot-avatar">
                    <img src="img/bot-avatar.svg" alt="Bot Avatar">
                </div>
                <div class="message-text">${message}</div>
            `;
        }
        
        chatBody.appendChild(messageDiv);
        chatBody.scrollTop = chatBody.scrollHeight;
    }
    
    // Função para simular digitação
    function simulateTyping(callback) {
        const typingDiv = document.createElement('div');
        typingDiv.classList.add('message', 'bot-message', 'typing-indicator');
        typingDiv.innerHTML = `
            <div class="bot-avatar">
                <img src="img/bot-avatar.svg" alt="Bot Avatar">
            </div>
            <div class="message-text">
                <span class="typing-dot"></span>
                <span class="typing-dot"></span>
                <span class="typing-dot"></span>
            </div>
        `;
        
        chatBody.appendChild(typingDiv);
        chatBody.scrollTop = chatBody.scrollHeight;
        
        setTimeout(() => {
            chatBody.removeChild(typingDiv);
            if (callback) callback();
        }, 1500);
    }
    
    // Função para processar a opção selecionada
    function processOption(option) {
        switch(option) {
            case 'cardapio':
                let cardapioMsg = '<strong>📋 Cardápio do Restaurante:</strong><br><br>';
                cardapio.pratos.forEach(prato => {
                    cardapioMsg += `<strong>${prato.nome}</strong> - R$ ${prato.preco.toFixed(2)}<br>`;
                    cardapioMsg += `${prato.descricao}<br><br>`;
                });
                addMessage(cardapioMsg);
                break;
                
            case 'promocoes':
                let promocoesMsg = '<strong>🎉 Promoções Especiais:</strong><br><br>';
                cardapio.promocoes.forEach(promo => {
                    promocoesMsg += `<strong>${promo.nome}</strong> - R$ ${promo.preco.toFixed(2)}<br>`;
                    promocoesMsg += `${promo.descricao}<br><br>`;
                });
                addMessage(promocoesMsg);
                break;
                
            case 'horario':
                let horarioMsg = '<strong>⏰ Horário de Funcionamento:</strong><br><br>';
                horarioMsg += `${horario.diasUteis}<br>`;
                horarioMsg += `${horario.sabados}<br>`;
                horarioMsg += `${horario.domingos}`;
                addMessage(horarioMsg);
                break;
                
            case 'pedido':
                addMessage('Para fazer um pedido, por favor informe:<br>1. O item que deseja pedir<br>2. Quantidade<br>3. Observações (se houver)<br><br>Exemplo: "Quero 1 Prato Executivo e 1 Suco de Laranja"');
                break;
        }
    }
    
    // Event listener para os botões de opção
    optionButtons.forEach(button => {
        button.addEventListener('click', function() {
            const option = this.getAttribute('data-option');
            addMessage(this.textContent, true);
            
            // Simular "digitando..."
            simulateTyping(() => {
                processOption(option);
            });
        });
    });
    
    // Event listener para o formulário de mensagem
    chatForm.addEventListener('submit', function(e) {
        e.preventDefault();
        
        const message = messageInput.value.trim();
        if (!message) return;
        
        // Adicionar mensagem do usuário
        addMessage(message, true);
        messageInput.value = '';
        
        // Simular "digitando..."
        simulateTyping(() => {
            // Processar a mensagem do usuário
            if (message.toLowerCase().includes('confirmar') && document.querySelector('.message:last-child').previousElementSibling.textContent.includes('Está correto?')) {
                confirmarPedido();
            } else if (message.toLowerCase().includes('pedido') || message.toLowerCase().includes('pedir') || message.toLowerCase().includes('quero')) {
                processarPedido(message);
            } else if (message.toLowerCase().includes('cardápio') || message.toLowerCase().includes('menu')) {
                processOption('cardapio');
            } else if (message.toLowerCase().includes('promoção') || message.toLowerCase().includes('oferta')) {
                processOption('promocoes');
            } else if (message.toLowerCase().includes('horário') || message.toLowerCase().includes('funcionamento')) {
                processOption('horario');
            } else {
                addMessage('Desculpe, não entendi. Você pode escolher uma das opções abaixo ou perguntar sobre nosso cardápio, promoções ou horário de funcionamento.');
            }
        });
    });
    
    // Função para processar pedidos
    function processarPedido(mensagem) {
        // Simulação de processamento de pedido
        addMessage('Obrigado pelo seu pedido! Vou registrá-lo para você.<br><br>Por favor, confirme os dados do seu pedido:<br><br><strong>Itens solicitados:</strong> ' + mensagem + '<br><br>Está correto? Se sim, digite "confirmar". Se não, você pode refazer o pedido.');
    }
    
    // Função para confirmar pedido
    function confirmarPedido() {
        const pedidoNumero = Math.floor(10000 + Math.random() * 90000);
        
        let mensagemConfirmacao = `<strong>Pedido confirmado!</strong> Seu número de pedido é #${pedidoNumero}.<br><br>`;
        mensagemConfirmacao += '<strong>Resumo do pedido:</strong><br>';
        mensagemConfirmacao += '- 1x Prato Executivo: R$ 15.90<br>';
        mensagemConfirmacao += '- 1x Suco de Laranja: R$ 5.00<br><br>';
        mensagemConfirmacao += '<strong>Total: R$ 20.90</strong><br><br>';
        mensagemConfirmacao += 'Seu pedido estará pronto em aproximadamente 15 minutos.<br>';
        mensagemConfirmacao += 'Você pode retirá-lo no balcão do restaurante.<br><br>';
        mensagemConfirmacao += 'Deseja algo mais?';
        
        addMessage(mensagemConfirmacao);
        
        // Gerar guia de produção (simulação)
        console.log(`===== GUIA DE PRODUÇÃO =====
Pedido #${pedidoNumero}
Data/Hora: ${new Date().toLocaleString('pt-BR')}

Cliente: Aluno/Funcionário

Itens:
- 1x Prato Executivo
- 1x Suco de Laranja

Observações: Nenhuma

Forma de pagamento: A definir no balcão
===========================`);
    }
    
    // Adicionar CSS para animação de digitação
    const style = document.createElement('style');
    style.textContent = `
        .typing-indicator .message-text {
            display: flex;
            align-items: center;
            padding: 8px 15px;
        }
        
        .typing-dot {
            display: inline-block;
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background-color: #888;
            margin: 0 2px;
            animation: typingAnimation 1.5s infinite ease-in-out;
        }
        
        .typing-dot:nth-child(1) {
            animation-delay: 0s;
        }
        
        .typing-dot:nth-child(2) {
            animation-delay: 0.3s;
        }
        
        .typing-dot:nth-child(3) {
            animation-delay: 0.6s;
        }
        
        @keyframes typingAnimation {
            0%, 60%, 100% {
                transform: translateY(0);
                opacity: 0.6;
            }
            30% {
                transform: translateY(-5px);
                opacity: 1;
            }
        }
    `;
    document.head.appendChild(style);
    
    // Abrir chatbot automaticamente após 1 segundo
    setTimeout(() => {
        chatbotToggler.click();
    }, 1000);
});
