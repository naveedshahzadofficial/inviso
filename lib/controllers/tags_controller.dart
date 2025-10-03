import 'package:get/get.dart';
import 'package:inviso/database/database_helper.dart';

class TagsController extends GetxController {
  final RxList<Map<String, dynamic>> allTags = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredTags = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadTags();
  }

  Future<void> loadTags() async {
    isLoading.value = true;
    try {
      final tags = await DatabaseHelper.getAllTagsWithCount();
      allTags.value = List<Map<String, dynamic>>.from(tags);
      filteredTags.value = allTags;
    } finally {
      isLoading.value = false;
    }
  }

  void searchTags(String query) {
    searchQuery.value = query;
    if (query.trim().isEmpty) {
      filteredTags.value = allTags;
    } else {
      filteredTags.value = allTags.where((tag) {
        final tagName = tag['tag_name']?.toString().toLowerCase() ?? '';
        return tagName.contains(query.toLowerCase());
      }).toList();
    }
  }

  Future<void> editTag(String oldName, String newName) async {
    await DatabaseHelper.updateTagName(oldName, newName);
    await loadTags();
    Get.snackbar('Success', 'Tag updated successfully');
  }

  Future<void> deleteTag(String tagName) async {
    await DatabaseHelper.deleteTag(tagName);
    await loadTags();
    Get.snackbar('Success', 'Tag removed successfully');
  }
}
