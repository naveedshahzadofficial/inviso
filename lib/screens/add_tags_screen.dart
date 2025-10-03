import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:inviso/controllers/add_tags_controller.dart';

class AddTagsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GetBuilder<AddTagsController>(
        init: AddTagsController(),
        builder: (controller) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Add Tags'),
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => Get.back(),
              ),
            ),
            body: Column(
              children: [
                _buildSearchBar(controller),
                Expanded(child: _buildImageGrid(controller)),
              ],
            ),
            floatingActionButton: Obx(() => FloatingActionButton.extended(
              onPressed: controller.selectedImages.isNotEmpty 
                  ? () => _showTagDialog(controller)
                  : null,
              label: Text(controller.selectedImages.isNotEmpty ? 'Assign Tag' : 'Add Tags'),
              icon: Icon(Icons.local_offer),
              backgroundColor: controller.selectedImages.isNotEmpty 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey,
            )),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(AddTagsController controller) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search images...',
            prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            hintStyle: TextStyle(color: Colors.grey[600]),
          ),
          onChanged: (query) => controller.searchImages(query),
        ),
      ),
    );
  }

  Widget _buildImageGrid(AddTagsController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }

      if (controller.filteredImages.isEmpty) {
        return Center(child: Text('No images found'));
      }

      return NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo is ScrollEndNotification &&
              scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
            controller.loadMoreImages();
          }
          return false;
        },
        child: GridView.builder(
          padding: EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.6,
          ),
          itemCount: controller.filteredImages.length + (controller.isLoadingMore.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= controller.filteredImages.length) {
              return Center(child: CircularProgressIndicator());
            }
            
            final image = controller.filteredImages[index];
            final isSelected = controller.selectedImages.contains(image['id']);
            
            return GestureDetector(
              onTap: () => controller.toggleSelection(image['id']),
              child: Stack(
                children: [
                  Card(
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
                  if (isSelected)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.blue : Colors.white.withOpacity(0.9),
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey[400]!,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: isSelected 
                            ? Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }

  void _showTagDialog(AddTagsController controller) {
    final tagController = TextEditingController();
    controller.loadExistingTags();
    
    Get.dialog(
      AlertDialog(
        title: Text('Add Tags'),
        content: Container(
          width: double.maxFinite,
          child: Obx(() => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: tagController,
                decoration: InputDecoration(
                  labelText: 'Enter tag name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final tag = tagController.text.trim();
                  if (tag.isNotEmpty) {
                    controller.addTag(tag);
                    tagController.clear();
                  }
                },
                child: Text('Add to List'),
              ),
              SizedBox(height: 16),
              Text('Available Tags', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Container(
                height: 200,
                child: ListView.builder(
                  itemCount: controller.existingTags.length,
                  itemBuilder: (context, index) {
                    final tag = controller.existingTags[index];
                    final isSelected = controller.selectedTags.contains(tag);
                    
                    return ListTile(
                      dense: true,
                      leading: GestureDetector(
                        onTap: () => controller.toggleExistingTag(tag),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? Colors.blue : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.grey,
                              width: 2,
                            ),
                          ),
                          child: isSelected 
                              ? Icon(Icons.check, color: Colors.white, size: 14)
                              : null,
                        ),
                      ),
                      title: Text(tag),
                      onTap: () => controller.toggleExistingTag(tag),
                    );
                  },
                ),
              ),
              if (controller.selectedTags.isNotEmpty) ...[
                SizedBox(height: 16),
                Text('Selected Tags', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: controller.selectedTags.map((tag) => Chip(
                    label: Text(tag),
                    backgroundColor: Colors.blue[100],
                    deleteIcon: Icon(Icons.close, size: 18),
                    onDeleted: () => controller.removeTag(tag),
                  )).toList(),
                ),
              ],
            ],
          )),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.saveTags();
              Get.back();
              Get.back();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}
