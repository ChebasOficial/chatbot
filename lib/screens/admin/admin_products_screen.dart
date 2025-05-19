import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:chatbot/providers/auth_provider.dart';
import 'package:chatbot/models/menu_item.dart';
import 'package:chatbot/widgets/custom_button.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({Key? key}) : super(key: key);

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<MenuItem> _menuItems = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    
    // Verificar se o administrador está logado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<ChatbotAuthProvider>(context, listen: false);
      if (!authProvider.isAdminLoggedIn) {
        Navigator.pushReplacementNamed(context, '/admin-login');
        return;
      }
      
      // Carregar itens do cardápio
      _loadMenuItems();
    });
  }
  
  Future<void> _loadMenuItems() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final snapshot = await _firestore.collection('menu_items').get();
      
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        return MenuItem(
          id: doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          price: (data['price'] ?? 0).toDouble(),
          imageUrl: data['imageUrl'] ?? '',
          quantity: data['quantity'] ?? 0,
        );
      }).toList();
      
      setState(() {
        _menuItems = items;
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar itens do cardápio: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Mostrar erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar itens do cardápio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _deleteMenuItem(String id) async {
    try {
      // Mostrar diálogo de confirmação
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: const Text('Tem certeza que deseja excluir este item do cardápio?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
            ),
          ],
        ),
      );
      
      if (confirmed != true) {
        return;
      }
      
      // Excluir do Firestore
      await _firestore.collection('menu_items').doc(id).delete();
      
      // Atualizar lista local
      setState(() {
        _menuItems.removeWhere((item) => item.id == id);
      });
      
      // Mostrar mensagem de sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item excluído com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Erro ao excluir item: $e');
      
      // Mostrar erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showAddEditDialog({MenuItem? item}) {
    showDialog(
      context: context,
      builder: (context) => AddEditMenuItemDialog(
        item: item,
        onSave: (newItem) async {
          if (item == null) {
            // Adicionar novo item
            setState(() {
              _menuItems.add(newItem);
            });
          } else {
            // Atualizar item existente
            setState(() {
              final index = _menuItems.indexWhere((i) => i.id == item.id);
              if (index >= 0) {
                _menuItems[index] = newItem;
              }
            });
          }
          
          // Recarregar itens do cardápio para garantir sincronização
          await _loadMenuItems();
        },
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciamento de Produtos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              try {
                // Fazer logout
                await Provider.of<ChatbotAuthProvider>(context, listen: false).logout();
                
                // Redirecionar para a página inicial
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/');
                }
              } catch (e) {
                // Mostrar erro se ocorrer
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao fazer logout: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _menuItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Nenhum item no cardápio',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showAddEditDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar Item'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMenuItems,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      final item = _menuItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Informações do produto
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.description,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'R\$ ${item.price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Botões de ação
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _showAddEditDialog(item: item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    color: Colors.red,
                                    onPressed: () => _deleteMenuItem(item.id),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddEditMenuItemDialog extends StatefulWidget {
  final MenuItem? item;
  final Function(MenuItem) onSave;

  const AddEditMenuItemDialog({
    Key? key,
    this.item,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AddEditMenuItemDialog> createState() => _AddEditMenuItemDialogState();
}

class _AddEditMenuItemDialogState extends State<AddEditMenuItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    
    // Preencher campos se for edição
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _descriptionController.text = widget.item!.description;
      _priceController.text = widget.item!.price.toString();
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }
  
  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Preparar dados do item
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final price = double.tryParse(_priceController.text) ?? 0.0;
      
      // Dados para salvar no Firestore
      final Map<String, dynamic> itemData = {
        'name': name,
        'description': description,
        'price': price,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Se for novo item, adicionar data de criação
      if (widget.item == null) {
        itemData['createdAt'] = FieldValue.serverTimestamp();
      }
      
      // Salvar no Firestore
      String itemId;
      if (widget.item == null) {
        // Novo item
        final docRef = await _firestore.collection('menu_items').add(itemData);
        itemId = docRef.id;
      } else {
        // Atualizar item existente
        itemId = widget.item!.id;
        await _firestore.collection('menu_items').doc(itemId).update(itemData);
      }
      
      // Criar objeto MenuItem para retornar
      final newItem = MenuItem(
        id: itemId,
        name: name,
        description: description,
        price: price,
        imageUrl: widget.item?.imageUrl ?? '',
        quantity: widget.item?.quantity ?? 0,
      );
      
      // Chamar callback de salvamento
      widget.onSave(newItem);
      
      // Fechar diálogo
      if (mounted) {
        Navigator.pop(context);
        
        // Mostrar mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.item == null
                ? 'Item adicionado com sucesso!'
                : 'Item atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Erro ao salvar item: $e');
      
      // Mostrar erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Adicionar Item' : 'Editar Item'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nome
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, informe o nome do item';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Descrição
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, informe a descrição do item';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Preço
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Preço (R$)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, informe o preço do item';
                  }
                  
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Por favor, informe um preço válido';
                  }
                  
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveItem,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}
