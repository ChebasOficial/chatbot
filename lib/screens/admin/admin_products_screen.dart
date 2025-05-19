import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:chatbot/providers/auth_provider.dart';
import 'package:chatbot/models/menu_item.dart';
import 'package:chatbot/widgets/custom_button.dart';
import 'package:uuid/uuid.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({Key? key}) : super(key: key);

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  
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
      
      // Buscar o item para verificar se tem imagem
      final item = _menuItems.firstWhere((item) => item.id == id);
      
      // Excluir do Firestore
      await _firestore.collection('menu_items').doc(id).delete();
      
      // Se tiver imagem, excluir do Storage
      if (item.imageUrl.isNotEmpty) {
        try {
          final ref = _storage.refFromURL(item.imageUrl);
          await ref.delete();
        } catch (e) {
          print('Erro ao excluir imagem: $e');
          // Não interromper o fluxo por causa desse erro
        }
      }
      
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
                              // Imagem do produto
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: item.imageUrl.isNotEmpty
                                    ? Image.network(
                                        item.imageUrl,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 80,
                                            height: 80,
                                            color: Colors.grey[300],
                                            child: const Icon(
                                              Icons.error,
                                              color: Colors.red,
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.image,
                                          color: Colors.grey,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 16),
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
                                    Row(
                                      children: [
                                        Text(
                                          r'R$ ${item.price.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          'Quantidade: ${item.quantity}',
                                          style: TextStyle(
                                            color: item.quantity > 0
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                      ],
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
  final _quantityController = TextEditingController();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  
  String _imageUrl = '';
  File? _imageFile;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    
    // Preencher campos se for edição
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _descriptionController.text = widget.item!.description;
      _priceController.text = widget.item!.price.toString();
      _quantityController.text = widget.item!.quantity.toString();
      _imageUrl = widget.item!.imageUrl;
    } else {
      // Valores padrão para novo item
      _quantityController.text = '0';
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Erro ao selecionar imagem: $e');
      
      // Mostrar erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<String> _uploadImage() async {
    if (_imageFile == null) {
      return _imageUrl; // Manter URL atual se não houver nova imagem
    }
    
    try {
      // Gerar nome único para o arquivo
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}.jpg';
      
      // Criar referência para o arquivo no Storage
      final ref = _storage.ref().child('menu_items').child(fileName);
      
      // Fazer upload
      final uploadTask = ref.putFile(_imageFile!);
      final snapshot = await uploadTask;
      
      // Obter URL de download
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Erro ao fazer upload da imagem: $e');
      
      // Se falhar o upload, retornar URL atual ou vazio
      if (_imageUrl.isNotEmpty) {
        return _imageUrl;
      }
      
      // Mostrar erro específico para o usuário
      if (e.toString().contains('permission-denied')) {
        throw Exception('Permissão negada para upload de imagem. Verifique as regras de segurança do Firebase Storage.');
      }
      
      throw Exception('Erro ao fazer upload da imagem. Tente novamente mais tarde.');
    }
  }
  
  Future<void> _saveMenuItem() async {
    // Validar formulário
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Obter dados do formulário
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final price = double.parse(_priceController.text.trim());
      final quantity = int.parse(_quantityController.text.trim());
      
      // Fazer upload da imagem se houver
      String imageUrl = _imageUrl;
      try {
        if (_imageFile != null) {
          imageUrl = await _uploadImage();
        }
      } catch (uploadError) {
        print('Erro no upload da imagem, continuando sem imagem: $uploadError');
        // Continuar sem imagem se o upload falhar
      }
      
      // Criar ou atualizar item no Firestore
      late MenuItem savedItem;
      
      try {
        if (widget.item == null) {
          // Criar novo item
          final docRef = await _firestore.collection('menu_items').add({
            'name': name,
            'description': description,
            'price': price,
            'quantity': quantity,
            'imageUrl': imageUrl,
            'createdAt': FieldValue.serverTimestamp(),
          });
          
          savedItem = MenuItem(
            id: docRef.id,
            name: name,
            description: description,
            price: price,
            quantity: quantity,
            imageUrl: imageUrl,
          );
        } else {
          // Atualizar item existente
          await _firestore.collection('menu_items').doc(widget.item!.id).update({
            'name': name,
            'description': description,
            'price': price,
            'quantity': quantity,
            'imageUrl': imageUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
          savedItem = MenuItem(
            id: widget.item!.id,
            name: name,
            description: description,
            price: price,
            quantity: quantity,
            imageUrl: imageUrl,
          );
        }
        
        // Chamar callback de salvamento
        widget.onSave(savedItem);
        
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
      } catch (firestoreError) {
        print('Erro ao salvar no Firestore: $firestoreError');
        
        // Tratar erro de permissão especificamente
        if (firestoreError.toString().contains('permission-denied')) {
          throw Exception(
            'Permissão negada para salvar item no cardápio. Verifique se você está logado como administrador e se as regras de segurança do Firestore permitem escrita na coleção "menu_items".'
          );
        }
        
        throw Exception('Erro ao salvar item no cardápio. Tente novamente mais tarde.');
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
              // Imagem
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : _imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      Icons.error,
                                      color: Colors.red,
                                    ),
                                  );
                                },
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Toque para selecionar uma imagem',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              // Nome
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do item',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
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
                  if (value == null || value.isEmpty) {
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
                  labelText: r'Preço (R$)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, informe o preço do item';
                  }
                  try {
                    final price = double.parse(value);
                    if (price <= 0) {
                      return 'O preço deve ser maior que zero';
                    }
                  } catch (e) {
                    return 'Por favor, informe um valor válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Quantidade
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantidade disponível',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, informe a quantidade disponível';
                  }
                  try {
                    final quantity = int.parse(value);
                    if (quantity < 0) {
                      return 'A quantidade não pode ser negativa';
                    }
                  } catch (e) {
                    return 'Por favor, informe um valor válido';
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveMenuItem,
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
