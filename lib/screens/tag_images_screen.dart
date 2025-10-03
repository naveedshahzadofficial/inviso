import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:inviso/controllers/tag_images_controller.dart';
import 'package:inviso/screens/screenshot_detail_screen.dart';

class TagImagesScreen extends StatelessWidget {
  final String tagName;

  const TagImagesScreen({Key? key, required this.tagName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GetBuilder<TagImagesController>(
        init: TagImagesController(tagName),
        builder: (controller) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Tag: $tagName'),
              actions: [
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _showRemoveTagDialog(controller),
                ),
              ],
            ),
            body: Obx(() {
              if (controller.isLoading.value) {
                return Center(child: CircularProgressIndicator());
              }

              if (controller.images.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported, size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text('No images with this tag'),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.5,
                ),
                itemCount: controller.images.length,
                itemBuilder: (context, index) {
                  final image = controller.images[index];
                  return GestureDetector(
                    onTap: () => Get.to(() => ScreenshotDetailScreen(screenshot: image)),
                    child: Card(
                      child: Image.file(
                        File(image['path']),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Icon(Icons.broken_image, size: 50),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            }),
          );
        },
      ),
    );
  }

  void _showRemoveTagDialog(TagImagesController controller) {
    Get.dialog(
      AlertDialog(
        title: Text('Remove Tag'),
        content: Text('Remove "$tagName" tag from all these images?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.removeTagFromAllImages();
              Get.back();
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Remove'),
          ),
        ],
      ),
    );
  }
}
