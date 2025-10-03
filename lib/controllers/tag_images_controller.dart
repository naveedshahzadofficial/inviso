import 'package:get/get.dart';
import 'package:inviso/database/database_helper.dart';

class TagImagesController extends GetxController {
  final String tagName;
  final RxList<Map<String, dynamic>> images = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  TagImagesController(this.tagName);

  @override
  void onInit() {
    super.onInit();
    loadImages();
  }

  Future<void> loadImages() async {
    isLoading.value = true;
    try {
      final taggedImages = await DatabaseHelper.getImagesByTag(tagName);
      images.value = List<Map<String, dynamic>>.from(taggedImages);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeTagFromAllImages() async {
    await DatabaseHelper.deleteTag(tagName);
    Get.snackbar('Success', 'Tag removed from all images');
  }
}
