import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

class EditImageScreen extends StatefulWidget {
  final List<File> images;
  const EditImageScreen({super.key, required this.images});

  @override
  _EditImageScreenState createState() => _EditImageScreenState();
}

class _EditImageScreenState extends State<EditImageScreen> {
  late List<File> imageList;

  @override
  void initState() {
    super.initState();
    imageList = List.from(widget.images);
  }

  // HÀM XỬ LÝ CẮT ẢNH (CROP) - ĐÃ SỬA THEO VERSION MỚI
  Future<void> _cropImage(int index) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageList[index].path,
      // Cấu hình UI và tính năng cho Android/iOS theo chuẩn mới
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Chỉnh sửa ảnh',
          toolbarColor: Colors.blue,
          toolbarWidgetColor: Colors.white,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
        IOSUiSettings(
          title: 'Chỉnh sửa ảnh',
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        imageList[index] = File(croppedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sắp xếp & Chỉnh sửa (${imageList.length})"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.pop(context, imageList),
          )
        ],
      ),
      body: ReorderableListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex -= 1;
            final item = imageList.removeAt(oldIndex);
            imageList.insert(newIndex, item);
          });
        },
        children: [
          for (int i = 0; i < imageList.length; i++)
            Card(
              key: ValueKey(imageList[i].path + i.toString()), // Đảm bảo key duy nhất
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(imageList[i], width: 50, height: 50, fit: BoxFit.cover),
                ),
                title: Text("Trang ${i + 1}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.crop_rotate, color: Colors.blue),
                      onPressed: () => _cropImage(i),
                    ),
                    const Icon(Icons.drag_handle, color: Colors.grey),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}