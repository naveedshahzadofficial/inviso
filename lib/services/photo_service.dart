import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

class PhotoService {
  static String? _customScreenshotsPath;

  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      if (Platform.operatingSystemVersion.contains("13") || // crude check
          Platform.operatingSystemVersion.contains("14") ||
          Platform.operatingSystemVersion.contains("15")
      ) {
        // Android 13+ requires READ_MEDIA_IMAGES
        final status = await Permission.photos.request();
        return status.isGranted;
      } else {
        // Android 12 and below
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } else if (Platform.isIOS) {
      // iOS permissions via PhotoManager
      final status = await PhotoManager.requestPermissionExtend();
      return status.isAuth;
    }
    // Linux and other desktop platforms don't need photo permissions
    return true;
  }
  
  static Future<String?> detectScreenshotsFolder() async {
    if (Platform.isAndroid) {
      return await detectAndroidScreenshotsFolder();
    } else if (Platform.isLinux) {
      return await detectLinuxScreenshotsFolder();
    }
    return null;
  }
  
  static Future<String?> detectAndroidScreenshotsFolder() async {
    final commonPaths = [
      '/storage/emulated/0/DCIM/Screenshots',
      '/storage/emulated/0/Pictures/Screenshots',
      '/sdcard/DCIM/Screenshots',
      '/sdcard/Pictures/Screenshots',
    ];
    
    for (final path in commonPaths) {
      if (await Directory(path).exists()) {
        return path;
      }
    }
    return null;
  }
  
  static Future<String?> detectLinuxScreenshotsFolder() async {
    final homeDir = Platform.environment['HOME'];
    if (homeDir == null) return null;
    
    final commonPaths = [
      '$homeDir/Pictures/Screenshots',
      '$homeDir/Desktop/Screenshots',
      '$homeDir/Screenshots',
      '$homeDir/Pictures',
    ];
    
    for (final path in commonPaths) {
      if (await Directory(path).exists()) {
        return path;
      }
    }
    return null;
  }
  
  static void setCustomScreenshotsPath(String path) {
    _customScreenshotsPath = path;
  }
  
  static bool hasCustomPath() {
    return _customScreenshotsPath != null;
  }
  
  static String? getCustomPath() {
    return _customScreenshotsPath;
  }
  
  static Future<List<AssetEntity>> getScreenshots({String? lastAssetId}) async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
      ),
    );
    
    if (albums.isEmpty) return [];
    
    // Find Screenshots album or use Camera Roll
    AssetPathEntity? screenshotAlbum;
    for (final album in albums) {
      if (album.name.toLowerCase().contains('screenshot')) {
        screenshotAlbum = album;
        break;
      }
    }
    screenshotAlbum ??= albums.first;
    
    final assets = await screenshotAlbum.getAssetListRange(
      start: 0,
      end: await screenshotAlbum.assetCountAsync,
    );
    
    // Filter for new assets if lastAssetId provided
    if (lastAssetId != null) {
      final lastIndex = assets.indexWhere((asset) => asset.id == lastAssetId);
      if (lastIndex >= 0) {
        // Return assets that come AFTER the last indexed one (newer assets)
        return assets.sublist(0, lastIndex);
      }
      // If lastAssetId not found, return all assets (they're all new)
      return assets;
    }
    
    return assets;
  }
  
  static Future<List<File>> getScreenshotsFromPath(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) return [];
    
    final files = await dir.list().where((entity) => 
      entity is File && 
      (entity.path.toLowerCase().endsWith('.jpg') ||
       entity.path.toLowerCase().endsWith('.png'))
    ).cast<File>().toList();
    
    return files;
  }
  
  static Future<File?> getAssetFile(AssetEntity asset) async {
    return await asset.file;
  }
}
