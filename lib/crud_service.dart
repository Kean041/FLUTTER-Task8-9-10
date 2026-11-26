import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';

class CrudService {
  final CollectionReference items = FirebaseFirestore.instance.collection(
    'items',
  );

  final String preset = 'flutter_notes_present';

  Future<void> addItem(String name, int quantity, String? imageUrl) {
    //CREATE
    return items.add({
      'name': name,
      'quantity': quantity,
      'image_url': imageUrl,
      'isFavorite': false,
      'created_at': Timestamp.now(),
    });
  }

  Future<void> addItemWithImage(
    String name,
    int quantity,
    XFile? pickedFile,
  ) async {
    final imageUrl = pickedFile == null
        ? null
        : await uploadImageToCloudinary(pickedFile);

    await addItem(name, quantity, imageUrl);
  }

  //READ
  Stream<QuerySnapshot> getItems() {
    return items.orderBy('created_at', descending: true).snapshots();
  }

  Future<String> uploadImageToCloudinary(XFile pickedFile) async {
    final cloudinary = CloudinaryPublic('bbuxio67', preset, cache: false);

    final response = await cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        pickedFile.path,
        resourceType: CloudinaryResourceType.Image,
      ),
    );
    return response.secureUrl;
  }

  //UPDATE
  Future<void> updateItem(String id, String name, int quantity) {
    return items.doc(id).update({'name': name, 'quantity': quantity});
  }

  Future<void> updateFavorite(String id, bool isFavorite) {
    return items.doc(id).update({'isFavorite': isFavorite});
  }

  //DELETE
  Future<void> deleteItem(String id) {
    return items.doc(id).delete();
  }
}
