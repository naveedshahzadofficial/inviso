import 'dart:io';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:inviso/database/database_helper.dart';
import 'package:inviso/services/ocr_service.dart';
import 'package:inviso/services/photo_service.dart';

class ScreenshotController extends GetxController {
  final RxList<Map<String, dynamic>> screenshots = <Map<String, dynamic>>[].obs;
  final RxBool isIndexing = false.obs;
  final RxBool isLoading = false.obs;
  final RxInt indexedCount = 0.obs;
  final RxInt totalCount = 0.obs;
  final RxString searchQuery = ''.obs;
  final RxBool needsFolderSelection = false.obs;
  
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMoreResults = true;
  
  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    final hasPermission = await PhotoService.requestPermissions();
    if (!hasPermission) return;

    // Only use custom path for Linux or when Android photo manager fails
    if (Platform.isLinux) {
      final screenshotsPath = await PhotoService.detectScreenshotsFolder();
      if (screenshotsPath == null) {
        needsFolderSelection.value = true;
        return;
      } else {
        PhotoService.setCustomScreenshotsPath(screenshotsPath);
      }
    }
    
    await _indexScreenshots();
    await _loadAllScreenshots();
  }
  
  Future<void> setCustomFolder(String path) async {
    PhotoService.setCustomScreenshotsPath(path);
    needsFolderSelection.value = false;
    await _indexScreenshots();
    await _loadAllScreenshots();
  }
  
  Future<void> _indexScreenshots() async {
    isIndexing.value = true;
    indexedCount.value = 0;
    
    try {
      if (Platform.isLinux && PhotoService.hasCustomPath()) {
        await _indexCustomFolderScreenshots();
      } else {
        await _indexPhotoManagerScreenshots();
      }
    } finally {
      isIndexing.value = false;
    }
  }
  
  Future<void> _indexPhotoManagerScreenshots() async {
    final lastIndexedId = await DatabaseHelper.getLastIndexedId();
    print('Last indexed ID: $lastIndexedId'); // Debug
    
    final screenshots = await PhotoService.getScreenshots(lastAssetId: lastIndexedId);
    print('New screenshots to index: ${screenshots.length}'); // Debug
    
    totalCount.value = screenshots.length;
    
    // Skip indexing if no new screenshots
    if (screenshots.isEmpty) {
      print('No new screenshots to index');
      return;
    }
    
    for (final asset in screenshots) {
      await _processScreenshot(asset);
      indexedCount.value++;
    }
  }
  
  Future<void> _indexCustomFolderScreenshots() async {
    final customPath = PhotoService.getCustomPath();
    if (customPath == null) return;
    
    final files = await PhotoService.getScreenshotsFromPath(customPath);
    final newFiles = <File>[];
    
    // Filter out already indexed files
    for (final file in files) {
      final fileId = file.path.hashCode.toString();
      final exists = await DatabaseHelper.screenshotExists(fileId);
      if (!exists) {
        newFiles.add(file);
      }
    }
    
    totalCount.value = newFiles.length;
    
    for (final file in newFiles) {
      await _processScreenshotFile(file);
      indexedCount.value++;
    }
  }
  
  Future<void> _processScreenshotFile(File file) async {
    final textContent = await OCRService.extractText(file.path);
    final stat = await file.stat();
    
    await DatabaseHelper.insertScreenshot({
      'id': file.path.hashCode.toString(),
      'path': file.path,
      'text_content': textContent,
      'created_date': stat.modified.millisecondsSinceEpoch,
      'modified_date': stat.modified.millisecondsSinceEpoch,
      'indexed_date': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  Future<void> _processScreenshot(AssetEntity asset) async {
    final file = await PhotoService.getAssetFile(asset);
    if (file == null) return;
    final textContent = await OCRService.extractText(file.path);
    
    await DatabaseHelper.insertScreenshot({
      'id': asset.id,
      'title': asset.title,
      'path': file.path,
      'sub_type': asset.subtype ?? 0,
      'type_int': asset.typeInt ?? 0,
      'duration': asset.duration ?? 0,
      'latitude': asset.latitude,
      'longitude': asset.longitude,
      'text_content': textContent,
      'width': asset.width ?? 0,
      'height': asset.height ?? 0,
      'orientation': asset.orientation ?? 0,
      'is_favorite': asset.isFavorite == true ? 1 : 0,
      'relative_path': asset.relativePath,
      'mime_type': asset.mimeType,
      'created_date': asset.createDateTime.millisecondsSinceEpoch,
      'modified_date': asset.modifiedDateTime.millisecondsSinceEpoch,
    });
  }
  
  Future<void> _loadAllScreenshots() async {
    _currentPage = 0;
    _hasMoreResults = true;
    isLoading.value = true;
    
    try {
      final results = await DatabaseHelper.getAllScreenshots(
        limit: _pageSize,
        offset: 0,
      );
      
      screenshots.value = List<Map<String, dynamic>>.from(results);
      _hasMoreResults = results.length == _pageSize;
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> search(String query) async {
    searchQuery.value = query;
    _currentPage = 0;
    _hasMoreResults = true;
    isLoading.value = true;
    
    try {
      final results = query.trim().isEmpty
          ? await DatabaseHelper.getAllScreenshots(limit: _pageSize, offset: 0)
          : await DatabaseHelper.searchScreenshots(query, limit: _pageSize, offset: 0);
      
      screenshots.value = List<Map<String, dynamic>>.from(results);
      _hasMoreResults = results.length == _pageSize;
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> loadMoreResults() async {
    if (!_hasMoreResults || isLoading.value) return;
    
    isLoading.value = true;
    _currentPage++;
    
    try {
      final results = searchQuery.value.trim().isEmpty
          ? await DatabaseHelper.getAllScreenshots(
              limit: _pageSize,
              offset: _currentPage * _pageSize,
            )
          : await DatabaseHelper.searchScreenshots(
              searchQuery.value,
              limit: _pageSize,
              offset: _currentPage * _pageSize,
            );
      
      if (results.isNotEmpty) {
        screenshots.addAll(List<Map<String, dynamic>>.from(results));
        _hasMoreResults = results.length == _pageSize;
      } else {
        _hasMoreResults = false;
      }
    } finally {
      isLoading.value = false;
    }
  }
  
  @override
  void onClose() {
    OCRService.dispose();
    super.onClose();
  }
}
