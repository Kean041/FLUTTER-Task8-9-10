import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'auth_service.dart';
import 'crud_service.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CrudService service = CrudService();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController();
  bool showFavoritesOnly = false;
  XFile? selectedImage;
  Uint8List? selectedImageBytes;

  Future<void> _signOut() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase | Masaway'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            tooltip: showFavoritesOnly
                ? 'Show all items'
                : 'Show favorite items',
            icon: Icon(
              showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                showFavoritesOnly = !showFavoritesOnly;
              });
            },
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _signOut,
          ),
        ],
      ), // AppBar
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => openAddDialog(context),
      ), // FloatingActionButton
      body: StreamBuilder<QuerySnapshot>(
        stream: service.getItems(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs.where((item) {
            final data = item.data() as Map<String, dynamic>;
            return !showFavoritesOnly || data['isFavorite'] == true;
          }).toList();
          if (docs.isEmpty) {
            return Center(
              child: Text(
                showFavoritesOnly
                    ? 'No favorite items found'
                    : 'No Items found',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var item = docs[index];
              final data = item.data() as Map<String, dynamic>;
              final isFavorite = data['isFavorite'] == true;
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: data['image_url'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      data['image_url'],
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Quantity: ${data['quantity']}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            tooltip: isFavorite
                                ? 'Remove from favorites'
                                : 'Add to favorites',
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.grey,
                            ),
                            onPressed: () =>
                                service.updateFavorite(item.id, !isFavorite),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () => openEditDialog(context, item),
                          ), // IconButton
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => confirmDelete(context, item.id),
                          ), // IconButton
                        ],
                      ),
                    ],
                  ),
                ),
              ); // Card
            }, // ListTile.builder
          ); // ListView.builder
        }, // StreamBuilder
      ), // Scaffold
    );
  }

  //ADD UI
  void openAddDialog(BuildContext context) {
    nameCtrl.clear();
    qtyCtrl.clear();
    selectedImage = null;
    selectedImageBytes = null;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ), // TextField
              SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ), // TextField
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picked = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                      );
                      if (picked != null) {
                        final imageBytes = await picked.readAsBytes();
                        if (!context.mounted) return;
                        setState(() {
                          selectedImage = picked;
                          selectedImageBytes = imageBytes;
                        });
                      }
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Upload from Device'),
                  ),
                ],
              ),
              if (selectedImageBytes != null) ...[
                const SizedBox(height: 8),
                Image.memory(
                  selectedImageBytes!,
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
              ],
            ],
          ), // Column
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ), // TextButton
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Save'),
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty &&
                    qtyCtrl.text.isNotEmpty &&
                    int.tryParse(qtyCtrl.text) != null) {
                  try {
                    await service.addItemWithImage(
                      nameCtrl.text,
                      int.parse(qtyCtrl.text),
                      selectedImage,
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not save item: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    ); // AlertDialog
  }

  //EDIT UI
  void openEditDialog(BuildContext context, DocumentSnapshot item) {
    nameCtrl.text = item['name'];
    qtyCtrl.text = item['quantity'].toString();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ), // TextField
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ), // TextField
          ],
        ), // Column
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ), // TextButton
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Update'),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty &&
                  qtyCtrl.text.isNotEmpty &&
                  int.tryParse(qtyCtrl.text) != null) {
                service.updateItem(
                  item.id,
                  nameCtrl.text,
                  int.parse(qtyCtrl.text),
                );
                Navigator.pop(context);
              }
            },
          ), // ElevatedButton
        ],
      ), // AlertDialog
    );
  }

  //DELETE UI
  void confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () {
              service.deleteItem(id);
              Navigator.pop(context);
            },
          ),
        ],
      ), // AlertDialog
    );
  }
}
