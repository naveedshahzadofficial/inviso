import 'package:get/get.dart';
import 'package:inviso/database/database_helper.dart';

class AddTagsController extends GetxController {
  final RxList<Map<String, dynamic>> allImages = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredImages = <Map<String, dynamic>>[].obs;
  final RxList<String> selectedImages = <String>[].obs;
  final RxList<String> selectedTags = <String>[].obs;
  final RxList<String> existingTags = <String>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString searchQuery = ''.obs;
  
  int _currentPage = 0;
  final int _pageSize = 30;
  bool _hasMoreResults = true;

  @override
  void onInit() {
    super.onInit();
    loadImages();
  }

  Future<void> loadImages() async {
    isLoading.value = true;
    _currentPage = 0;
    _hasMoreResults = true;
    
    try {
      final images = await DatabaseHelper.getAllScreenshots(limit: _pageSize, offset: 0);
      allImages.value = List<Map<String, dynamic>>.from(images);
      filteredImages.value = allImages;
      _hasMoreResults = images.length == _pageSize;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreImages() async {
    if (!_hasMoreResults || isLoadingMore.value) return;
    
    isLoadingMore.value = true;
    _currentPage++;
    
    try {
      final images = searchQuery.value.trim().isEmpty
          ? await DatabaseHelper.getAllScreenshots(
              limit: _pageSize,
              offset: _currentPage * _pageSize,
            )
          : await DatabaseHelper.searchScreenshots(
              searchQuery.value,
              limit: _pageSize,
              offset: _currentPage * _pageSize,
            );
      
      if (images.isNotEmpty) {
        final newImages = List<Map<String, dynamic>>.from(images);
        if (searchQuery.value.trim().isEmpty) {
          allImages.addAll(newImages);
          filteredImages.addAll(newImages);
        } else {
          filteredImages.addAll(newImages);
        }
        _hasMoreResults = images.length == _pageSize;
      } else {
        _hasMoreResults = false;
      }
    } finally {
      isLoadingMore.value = false;
    }
  }

  void searchImages(String query) async {
    searchQuery.value = query;
    _currentPage = 0;
    _hasMoreResults = true;
    
    if (query.trim().isEmpty) {
      filteredImages.value = allImages;
    } else {
      final results = await DatabaseHelper.searchScreenshots(query, limit: _pageSize, offset: 0);
      filteredImages.value = List<Map<String, dynamic>>.from(results);
      _hasMoreResults = results.length == _pageSize;
    }
  }

  void toggleSelection(String imageId) {
    if (selectedImages.contains(imageId)) {
      selectedImages.remove(imageId);
    } else {
      selectedImages.add(imageId);
    }
  }

  void addTag(String tag) {
    if (!selectedTags.contains(tag)) {
      selectedTags.add(tag);
    }
  }

  void removeTag(String tag) {
    selectedTags.remove(tag);
  }

  Future<void> loadExistingTags() async {
    final tags = await DatabaseHelper.getAllTags();
    existingTags.value = tags;
  }

  void toggleExistingTag(String tag) {
    if (selectedTags.contains(tag)) {
      selectedTags.remove(tag);
    } else {
      selectedTags.add(tag);
    }
  }

  Future<void> saveTags() async {
    if (selectedImages.isEmpty || selectedTags.isEmpty) return;
    
    for (final imageId in selectedImages) {
      for (final tag in selectedTags) {
        await DatabaseHelper.addImageTag(imageId, tag);
      }
    }
    
    // Clear selections
    selectedImages.clear();
    selectedTags.clear();
    
    Get.snackbar('Success', 'Tags added successfully');
  }
}
