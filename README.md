# Inviso - Screenshot Text Search App

This repository contains a **concise, production-ready skeleton** for a Flutter app that:
- Indexes local screenshots on first launch (on-device only — no upload).
- Uses on-device OCR (Google ML Kit) to extract text.
- Stores extracted text and paths in an SQLite database with indexed search for fast full-text search.
- Performs **incremental indexing** (only new screenshots after first run).
- Uses **pagination / infinite scroll** for lists (works with 1M+ images).
- Uses GetX for reactive state management to keep UI responsive.
- Optimized for Android & iOS.

## 🚀 Features

- **📱 Cross-Platform**: Android (MediaStore API) & iOS (PhotoKit) support
- **🔍 OCR Text Extraction**: Google ML Kit for on-device text recognition
- **💾 SQLite Database**: Efficient storage with indexed text search
- **⚡ Incremental Indexing**: Only processes new screenshots after first launch
- **📄 Pagination**: Handles 1M+ screenshots with infinite scroll
- **🎯 Reactive UI**: GetX state management with Obx for real-time updates
- **🔒 Privacy-First**: All processing happens on-device, no data upload

## 📁 Project Structure

```
lib/
├── main.dart                           # App entry point with GetX setup
├── controllers/
│   └── screenshot_controller.dart      # Main business logic & state management
├── database/
│   └── database_helper.dart           # SQLite operations with indexed search
├── services/
│   ├── ocr_service.dart              # Google ML Kit text recognition
│   └── photo_service.dart            # Cross-platform photo access
└── screens/
    └── home_screen.dart              # Main UI with search & results grid
```

## 🔄 App Flow

### First Launch
1. **Permission Request**: Requests photo library access
2. **Full Indexing**: Processes ALL screenshots with OCR
3. **Database Storage**: Saves `id`, `path`, `text_content`, timestamps

### Subsequent Launches
1. **Incremental Check**: Gets last indexed screenshot ID
2. **New Screenshots Only**: Processes only new screenshots since last run
3. **Background Processing**: Non-blocking indexing with progress updates

### Search & Results
1. **Real-time Search**: User types → instant database query
2. **Paginated Results**: Loads 20 results at a time
3. **Infinite Scroll**: Automatically loads more on scroll
4. **Reactive UI**: Updates automatically via GetX Obx

## 🛠️ Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  get: ^4.6.6                          # State management
  sqflite: ^2.3.0                     # SQLite database
  google_mlkit_text_recognition: ^0.13.0  # OCR
  photo_manager: ^3.0.0               # Photo access
  path_provider: ^2.1.1               # File paths
  permission_handler: ^11.0.1         # Permissions
```

## 🔧 Setup

1. **Clone & Install**:
   ```bash
   git clone <repository-url>
   cd inviso
   flutter pub get
   ```

2. **Android Setup**:
   - Minimum SDK: 21
   - Compile SDK: 35
   - Permissions: `READ_EXTERNAL_STORAGE`, `READ_MEDIA_IMAGES`

3. **iOS Setup**:
   - Add photo library usage descriptions in `Info.plist`
   - iOS 11.0+ required

4. **Run**:
   ```bash
   flutter run
   ```

## 📊 Performance Optimizations

- **Indexed Database**: Fast text search with SQLite indexes
- **Pagination**: Prevents memory issues with large datasets
- **Incremental Processing**: Only new screenshots processed
- **Efficient Queries**: LIKE-based search with proper indexing
- **Lazy Loading**: Images loaded on-demand in grid view

## 🏗️ Architecture

- **GetX Pattern**: Reactive state management with minimal boilerplate
- **Service Layer**: Separated concerns for OCR, database, and photo access
- **Clean Imports**: Package-based imports without aliases
- **Error Handling**: Graceful fallbacks for corrupted images
- **Cross-Platform**: Single codebase for Android & iOS

## 🔍 Key Components

### ScreenshotController
- Manages app state and business logic
- Handles indexing progress and search results
- Implements pagination with infinite scroll

### DatabaseHelper
- SQLite operations with indexed text search
- Incremental indexing support
- Efficient pagination queries

### OCRService
- Google ML Kit integration
- Text extraction from images
- Error handling for processing failures

### PhotoService
- Cross-platform screenshot access
- Incremental fetching based on last indexed ID
- Platform-specific optimizations

## 📱 UI Features

- **Search Bar**: Real-time text search with instant results
- **Grid Layout**: Responsive 2-column screenshot grid
- **Thumbnails**: Image previews with extracted text
- **Progress Indicator**: Indexing progress with count display
- **Infinite Scroll**: Automatic loading of more results
- **Error States**: Graceful handling of broken images

## 🚀 Production Ready

This skeleton is optimized for production use with:
- Proper error handling and edge cases
- Memory-efficient image loading
- Database optimization for large datasets
- Cross-platform compatibility
- Clean, maintainable code structure
- Scalable architecture for future enhancements

## 📄 License

MIT License - Feel free to use this skeleton for your projects.
