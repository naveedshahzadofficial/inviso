import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:inviso/controllers/screenshot_controller.dart';
import 'package:inviso/controllers/tags_controller.dart';
import 'package:inviso/screens/screenshot_detail_screen.dart';
import 'package:inviso/screens/add_tags_screen.dart';
import 'package:inviso/screens/tag_images_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GetBuilder<ScreenshotController>(
        init: ScreenshotController(),
        builder: (controller) {
          return Scaffold(
            appBar: AppBar(
              title: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search screenshots...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    hintStyle: TextStyle(color: Colors.grey[600]),
                  ),
                  style: TextStyle(color: Colors.black),
                  onChanged: (query) => controller.search(query),
                ),
              ),
              actions: [
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert),
                  onSelected: (value) {
                    // Handle menu actions
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'settings', child: Text('Settings')),
                    PopupMenuItem(value: 'about', child: Text('About')),
                    PopupMenuItem(value: 'help', child: Text('Help')),
                  ],
                ),
              ],
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                Stack(
                  children: [
                    _buildLibraryTab(controller),
                    Positioned(
                      right: 16,
                      bottom: 80,
                      child: FloatingActionButton(
                        onPressed: () => Get.to(() => AddTagsScreen()),
                        child: Icon(Icons.local_offer),
                        tooltip: 'Add Tags',
                      ),
                    ),
                  ],
                ),
                _buildTagsTab(),
                _buildSettingsTab(),
              ],
            ),
            bottomNavigationBar: Container(
              color: Theme.of(context).primaryColor,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: [
                  Tab(icon: Icon(Icons.photo_library), text: 'Library'),
                  Tab(icon: Icon(Icons.local_offer), text: 'Tags'),
                  Tab(icon: Icon(Icons.settings), text: 'Settings'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLibraryTab(ScreenshotController controller) {
    return Obx(() {
      // Show indexing dialog
      if (controller.isIndexing.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!Get.isDialogOpen!) {
            _showIndexingDialog(controller);
          }
        });
      } else if (!controller.isIndexing.value && Get.isDialogOpen!) {
        Get.back();
      }
      
      if (controller.needsFolderSelection.value) {
        return _buildFolderSelectionView(controller);
      }
      
      if (controller.isLoading.value && controller.screenshots.isEmpty) {
        return Center(child: CircularProgressIndicator());
      }
      
      if (controller.screenshots.isEmpty) {
        return Center(
          child: Text(
            'No screenshots found',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        );
      }
      
      return _buildResultsList(controller);
    });
  }

  void _showIndexingDialog(ScreenshotController controller) {
    Get.dialog(
      PopScope(
        canPop: false, // prevents dismissing
        child: AlertDialog(
          content: Obx(() => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              Icon(
                Icons.photo_library,
                size: 64,
                color: Theme.of(Get.context!).primaryColor,
              ),
              SizedBox(height: 24),

              // Title
              Text(
                'Indexing Screenshots',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),

              // Progress bar
              LinearProgressIndicator(
                value: controller.totalCount.value > 0
                    ? controller.indexedCount.value /
                    controller.totalCount.value
                    : 0,
              ),
              SizedBox(height: 8),

              // Progress count
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${controller.indexedCount.value}/${controller.totalCount.value}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Warning message
              Text(
                'Screenshots are being indexed. This may take a few seconds to complete. Do not close this application until the process is completed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          )),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildFolderSelectionView(ScreenshotController controller) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Screenshots Folder Not Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Please select your screenshots folder manually',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showFolderSelectionDialog(controller),
              child: Text('Select Folder'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFolderSelectionDialog(ScreenshotController controller) {
    final pathController = TextEditingController();
    final isLinux = Platform.isLinux;
    final hintText = isLinux 
        ? '/home/username/Pictures/Screenshots'
        : '/storage/emulated/0/DCIM/Screenshots';
    
    Get.dialog(
      AlertDialog(
        title: Text('Select Screenshots Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter the path to your screenshots folder:'),
            SizedBox(height: 16),
            TextField(
              controller: pathController,
              decoration: InputDecoration(
                hintText: hintText,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final path = pathController.text.trim();
              if (path.isNotEmpty) {
                Get.back();
                controller.setCustomFolder(path);
              }
            },
            child: Text('Select'),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsTab() {
    return GetBuilder<TagsController>(
      init: TagsController(),
      builder: (controller) {
        return Column(
          children: [
            _buildTagsSearchBar(controller),
            Expanded(child: _buildTagsList(controller)),
          ],
        );
      },
    );
  }

  Widget _buildTagsSearchBar(TagsController controller) {
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
            hintText: 'Search tags...',
            prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            hintStyle: TextStyle(color: Colors.grey[600]),
          ),
          onChanged: (query) => controller.searchTags(query),
        ),
      ),
    );
  }

  Widget _buildTagsList(TagsController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }

      if (controller.filteredTags.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_offer, size: 64, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'No Tags Found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Add tags to your screenshots to organize them',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: controller.filteredTags.length,
        itemBuilder: (context, index) {
          final tagData = controller.filteredTags[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.local_offer, color: Colors.white),
              ),
              title: Text(tagData['tag_name']),
              subtitle: Text('${tagData['count']} images'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditTagDialog(controller, tagData['tag_name']);
                      break;
                    case 'delete':
                      _showDeleteTagDialog(controller, tagData['tag_name']);
                      break;
                    case 'view':
                      Get.to(() => TagImagesScreen(tagName: tagData['tag_name']));
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'view', child: Text('View Images')),
                  PopupMenuItem(value: 'edit', child: Text('Edit Tag')),
                  PopupMenuItem(value: 'delete', child: Text('Remove Tag')),
                ],
              ),
              onTap: () => Get.to(() => TagImagesScreen(tagName: tagData['tag_name'])),
            ),
          );
        },
      );
    });
  }

  void _showEditTagDialog(TagsController controller, String oldTagName) {
    final textController = TextEditingController(text: oldTagName);
    
    Get.dialog(
      AlertDialog(
        title: Text('Edit Tag'),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(
            labelText: 'Tag name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = textController.text.trim();
              if (newName.isNotEmpty && newName != oldTagName) {
                controller.editTag(oldTagName, newName);
              }
              Get.back();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteTagDialog(TagsController controller, String tagName) {
    Get.dialog(
      AlertDialog(
        title: Text('Remove Tag'),
        content: Text('Are you sure you want to remove the tag "$tagName"? This will remove it from all images.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteTag(tagName);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Remove'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        ListTile(
          leading: Icon(Icons.storage),
          title: Text('Storage'),
          subtitle: Text('Manage indexed screenshots'),
          trailing: Icon(Icons.chevron_right),
        ),
        ListTile(
          leading: Icon(Icons.sync),
          title: Text('Re-index All'),
          subtitle: Text('Rebuild screenshot index'),
          trailing: Icon(Icons.chevron_right),
        ),
        ListTile(
          leading: Icon(Icons.info),
          title: Text('About'),
          subtitle: Text('App version and info'),
          trailing: Icon(Icons.chevron_right),
        ),
      ],
    );
  }
  
  Widget _buildIndexingView(ScreenshotController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Indexing screenshots...'),
          SizedBox(height: 8),
          Obx(() => Text(
            '${controller.indexedCount.value} / ${controller.totalCount.value}',
            style: TextStyle(fontWeight: FontWeight.bold),
          )),
        ],
      ),
    );
  }
  
  Widget _buildResultsList(ScreenshotController controller) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo is ScrollEndNotification &&
            scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
          controller.loadMoreResults();
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
        itemCount: controller.screenshots.length + (controller.isLoading.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= controller.screenshots.length) {
            return Center(child: CircularProgressIndicator());
          }
          final screenshot = controller.screenshots[index];
          return _buildScreenshotCard(screenshot);
        },
      ),
    );
  }
  
  Widget _buildScreenshotCard(Map<String, dynamic> screenshot) {
    return GestureDetector(
      onTap: () => Get.to(() => ScreenshotDetailScreen(screenshot: screenshot)),
      child: Card(
        child: Image.file(
          File(screenshot['path']),
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
  }
}
