import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui_web' as ui;
import 'package:chewie/chewie.dart';
import 'package:dishdash_web/colors.dart';
import 'package:dishdash_web/pages/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'dart:html' as html; // 👈 for web
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';

class CoursesPage extends StatefulWidget {
  final String userId;
  const CoursesPage({super.key, required this.userId});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  List<dynamic> courses = [];
  final String baseUrl = 'http://192.168.68.61:3000';
  bool isUploading = false;
  // Controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController chefController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  html.File? avatarWebFile;
  html.File? coverWebFile;

  // Video URL
  String videoUrl = '';

  // Picked Images
  File? avatarFile;
  File? coverFile;

  // Dispose them later
  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    chefController.dispose();
    durationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    fetchCourses();
  }

  Future<String?> uploadVideo() async {
    final uri = Uri.parse('$baseUrl/api/courses/upload-video');

    if (kIsWeb) {
      final uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'video/*';
      uploadInput.click();

      await uploadInput.onChange.first;

      final file = uploadInput.files?.first;
      if (file == null) return null;

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);

      await reader.onLoad.first;

      final data = Uint8List.fromList(reader.result as List<int>);

      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        http.MultipartFile.fromBytes(
          'video',
          data,
          filename: file.name,
          contentType: MediaType('video', 'mp4'),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Response: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonRes = jsonDecode(response.body);
        return jsonRes['url'];
      } else {
        print('❌ Upload failed: ${response.statusCode}');
        return null;
      }
    } else {
      // ✅ Mobile path (ImagePicker is fine)
      final picker = ImagePicker();
      final picked = await picker.pickVideo(source: ImageSource.gallery);
      if (picked == null) return null;

      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath(
          'video',
          picked.path,
          contentType: MediaType('video', 'mp4'),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonRes = jsonDecode(response.body);
        return jsonRes['url'];
      } else {
        print('❌ Upload failed');
        return null;
      }
    }
  }

  Future<File?> _pickImageFile() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    return picked != null ? File(picked.path) : null;
  }

  Future<void> createCourseWithEpisodes({
    required String title,
    required String description,
    required String chefName,
    required String chefAvatar,
    required String coverImageUrl,
    required List<Map<String, dynamic>> episodes,
  }) async {
    final uri = Uri.parse('$baseUrl/api/courses');
    if (!kIsWeb && (avatarFile == null || coverFile == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please upload both avatar and cover images.")),
      );
      return;
    }
    await uploadCourseWithImages(
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      chefName: chefController.text.trim(),
      videoUrl: videoUrl,
      fullDuration: int.tryParse(durationController.text.trim()) ?? 600,
      avatarFileWeb: kIsWeb ? avatarWebFile : null,
      coverFileWeb: kIsWeb ? coverWebFile : null,
      chefAvatarMobile: kIsWeb ? null : avatarFile!,
      coverImageMobile: kIsWeb ? null : coverFile!,
    );
  }

  Future<void> pickAndUploadAndSplitVideo() async {
    setState(() => isUploading = true); // ✅ Begin full-page loading

    final videoUrl = await uploadVideo();

    if (videoUrl == null || videoUrl.isEmpty) {
      setState(() => isUploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Video upload failed")));
      return;
    }

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final chefController = TextEditingController();
    final durationController = TextEditingController(); // seconds

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            scrollable: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              '📽️ Auto-Split Course Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Course Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 12),
                TextField(
                  controller: chefController,
                  decoration: InputDecoration(
                    labelText: 'Chef Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (kIsWeb) {
                      final input =
                          html.FileUploadInputElement()..accept = 'image/*';
                      input.click();
                      await input.onChange.first;
                      final file = input.files?.first;
                      if (file != null) {
                        avatarWebFile = file;
                        print('✅ Avatar file selected: ${file.name}');
                      }
                    } else {
                      final file = await _pickImageFile();
                      if (file != null) {
                        setState(() {
                          avatarFile = file;
                        });
                      }
                    }
                  },
                  icon: Icon(Icons.person),
                  label: Text("Upload Chef Avatar"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (kIsWeb) {
                      final input =
                          html.FileUploadInputElement()..accept = 'image/*';
                      input.click();
                      await input.onChange.first;
                      final file = input.files?.first;
                      if (file != null) {
                        setState(() {
                          coverWebFile = file;
                        });
                      }
                    } else {
                      final file = await _pickImageFile();
                      if (file != null) {
                        setState(() {
                          coverFile = file;
                        });
                      }
                    }
                  },
                  icon: Icon(Icons.image),
                  label: Text("Upload Cover Image"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: durationController,
                  decoration: InputDecoration(
                    labelText: 'Full Video Duration (sec)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() => isUploading = false); // ❌ Cancel resets loader
                  Navigator.pop(context);
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if ((kIsWeb &&
                          (avatarWebFile == null || coverWebFile == null)) ||
                      (!kIsWeb && (avatarFile == null || coverFile == null))) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please upload both images"),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context); // ✅ Close dialog before uploading

                  await uploadCourseWithImages(
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    chefName: chefController.text.trim(),
                    videoUrl: videoUrl,
                    fullDuration:
                        int.tryParse(durationController.text.trim()) ?? 600,
                    avatarFileWeb: kIsWeb ? avatarWebFile : null,
                    coverFileWeb: kIsWeb ? coverWebFile : null,
                    chefAvatarMobile: kIsWeb ? null : avatarFile,
                    coverImageMobile: kIsWeb ? null : coverFile,
                  );

                  await fetchCourses();

                  setState(() => isUploading = false); // ✅ Done: reset loading
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Create Course'),
              ),
            ],
          ),
    );
  }

  Future<void> uploadCourseWithImages({
    required String title,
    required String description,
    required String chefName,
    required String videoUrl,
    required int fullDuration,
    html.File? avatarFileWeb,
    html.File? coverFileWeb,
    File? chefAvatarMobile,
    File? coverImageMobile,
  }) async {
    final uri = Uri.parse(
      'http://localhost:3000/api/courses/create-from-single-video',
    );
    final request = http.MultipartRequest('POST', uri);

    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['chefName'] = chefName;
    request.fields['videoUrl'] = videoUrl;
    request.fields['fullDuration'] = fullDuration.toString();

    if (kIsWeb) {
      final reader1 = html.FileReader();
      final reader2 = html.FileReader();

      reader1.readAsArrayBuffer(avatarFileWeb!);
      reader2.readAsArrayBuffer(coverFileWeb!);

      await reader1.onLoadEnd.first;
      await reader2.onLoadEnd.first;

      final avatarBytes = Uint8List.fromList(reader1.result as List<int>);
      final coverBytes = Uint8List.fromList(reader2.result as List<int>);

      request.files.add(
        http.MultipartFile.fromBytes(
          'chefAvatar',
          avatarBytes,
          filename: 'chef.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          coverBytes,
          filename: 'cover.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    } else {
      if (chefAvatarMobile == null || coverImageMobile == null) {
        print('❌ Error: avatar or cover image is null');
        return;
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'chefAvatar',
          chefAvatarMobile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          coverImageMobile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    final response = await request.send();
    final res = await http.Response.fromStream(response);

    print('📦 Status: ${res.statusCode}');
    print('📦 Body: ${res.body}');
  }

  Future<String?> pickAndUploadImage() async {
    final uri = Uri.parse('$baseUrl/api/upload-image');

    if (kIsWeb) {
      final uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      await uploadInput.onChange.first;

      final file = uploadInput.files?.first;
      if (file == null) return null;

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;

      final data = Uint8List.fromList(reader.result as List<int>);
      final request = http.MultipartRequest('POST', uri);

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          data,
          filename: file.name,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final res = await request.send();
      final response = await http.Response.fromStream(res);
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['url'];
      }
    } else {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return null;

      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          picked.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final res = await request.send();
      final response = await http.Response.fromStream(res);
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['url'];
      }
    }

    return null;
  }

  Future<void> pickAndUploadVideo() async {
    setState(() => isUploading = true); // ✅ Start loading

    final videoUrl = await uploadVideo();

    setState(() => isUploading = false); // ✅ End loading

    if (videoUrl != null && videoUrl.isNotEmpty) {
      final courseTitleController = TextEditingController();
      final descriptionController = TextEditingController();
      final chefNameController = TextEditingController();
      final chefAvatarController = TextEditingController();
      final coverImageController = TextEditingController();
      final episodeTitleController = TextEditingController();
      final durationController = TextEditingController();

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              scrollable: true,
              title: Text('Add Course and Episode'),
              content: Column(
                children: [
                  TextField(
                    controller: courseTitleController,
                    decoration: InputDecoration(labelText: 'Course Title'),
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Course Description',
                    ),
                  ),
                  TextField(
                    controller: chefNameController,
                    decoration: InputDecoration(labelText: 'Chef Name'),
                  ),
                  TextField(
                    controller: chefAvatarController,
                    decoration: InputDecoration(labelText: 'Chef Avatar URL'),
                  ),
                  TextField(
                    controller: coverImageController,
                    decoration: InputDecoration(labelText: 'Cover Image URL'),
                  ),
                  Divider(),
                  TextField(
                    controller: episodeTitleController,
                    decoration: InputDecoration(labelText: 'Episode Title'),
                  ),
                  TextField(
                    controller: durationController,
                    decoration: InputDecoration(
                      labelText: 'Episode Duration (min)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: Text('Submit'),
                  onPressed: () async {
                    final courseTitle = courseTitleController.text.trim();
                    final description = descriptionController.text.trim();
                    final chefName = chefNameController.text.trim();
                    final chefAvatar = chefAvatarController.text.trim();
                    final coverImageUrl = coverImageController.text.trim();
                    final episodeTitle = episodeTitleController.text.trim();
                    final duration =
                        double.tryParse(durationController.text.trim()) ?? 0;

                    await createCourseWithEpisodes(
                      title: courseTitle,
                      description: description,
                      chefName: chefName,
                      chefAvatar: chefAvatar,
                      coverImageUrl: coverImageUrl,
                      episodes: [
                        {
                          "title": episodeTitle,
                          "videoUrl": videoUrl,
                          "duration": duration,
                        },
                      ],
                    );

                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
      );
    }
  }

  Future<void> fetchCourses() async {
    final res = await http.get(Uri.parse('$baseUrl/api/courses'));
    if (res.statusCode == 200) {
      setState(() {
        courses = json.decode(res.body);
      });
    }
  }

  double getTotalDuration(List episodes) {
    return episodes.fold(0, (sum, ep) => sum + ep['duration']);
  }

  double calculateAverageRating(List ratings) {
    if (ratings.isEmpty) return 0.0;
    final total = ratings.fold(
      0.0,
      (sum, r) => sum + (r is int ? r.toDouble() : (r as num).toDouble()),
    );
    final avg = total / ratings.length;
    return avg.isNaN ? 0.0 : avg;
  }

  void showCourseDetail(Map<String, dynamic> course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min, // 🔐 Important to prevent overflow

                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        course['title'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: calculateAverageRating(
                              course['ratings'] ?? [],
                            ),
                            itemBuilder:
                                (context, _) =>
                                    Icon(Icons.star, color: Colors.amber),
                            itemCount: 5,
                            itemSize: 18.0,
                            direction: Axis.horizontal,
                          ),
                          SizedBox(width: 6),
                          Text(
                            calculateAverageRating(
                              course['ratings'] ?? [],
                            ).toStringAsFixed(1),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),

                      Text(
                        "By ${course['chefName']}",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Divider(thickness: 1, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text(
                        "Lessons",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: course['episodes'].length,
                          itemBuilder: (_, index) {
                            final ep = course['episodes'][index];
                            return Card(
                              elevation: 2,
                              shadowColor: Colors.green.shade100,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color: Colors.green.shade50,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                leading: Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.green.shade700,
                                  size: 32,
                                ),
                                title: Text(
                                  ep['title'],
                                  style: TextStyle(
                                    color: Colors.green.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text("${ep['duration']} min"),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => VideoPlayerPage(
                                              videoUrl: ep['videoUrl'],
                                              startTime: ep['startTime'],
                                              endTime: ep['endTime'],
                                            ),
                                      ),
                                    );
                                  },
                                  child: const Text("Watch"),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget buildCourseCard(course) {
    double avgRating = calculateAverageRating(course['ratings'] ?? []);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 450), // limits card width
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        clipBehavior: Clip.antiAlias, // prevents image bleed
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            course['image'] != null
                ? Image.network(
                  course['image'],
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
                : Container(
                  height: 160,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: Icon(Icons.image_not_supported, size: 40),
                ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min, // 🔐 Important to prevent overflow

                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    course['title'],
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),

                  // Chef Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage:
                            course['chefAvatar'] != null
                                ? NetworkImage(course['chefAvatar'])
                                : null,
                        backgroundColor: Colors.grey[300],
                        child:
                            course['chefAvatar'] == null
                                ? Icon(Icons.person, color: Colors.grey)
                                : null,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          course['chefName'] ?? 'Unknown Chef',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 8),

                  // Lessons & Duration
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "🎬 ${course['episodes'].length} Lessons",
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        "⏱️ ${getTotalDuration(course['episodes'])} min",
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),

                  SizedBox(height: 6),

                  // Rating
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: avgRating,
                        itemBuilder:
                            (context, _) =>
                                Icon(Icons.star, color: Colors.amber),
                        itemCount: 5,
                        itemSize: 18,
                        direction: Axis.horizontal,
                      ),
                      SizedBox(width: 6),
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),

                  SizedBox(height: 8),

                  // View Lessons Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(
                            Icons.play_circle_outline,
                            color: Colors.white,
                          ),
                          label: Text(
                            "Lessons",
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () => showCourseDetail(course),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: green,
                            padding: EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.delete, color: Colors.white),
                          label: Text(
                            "Delete Course",
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder:
                                  (ctx) => AlertDialog(
                                    title: Text("Confirm Deletion"),
                                    content: Text(
                                      "Are you sure you want to delete this course?",
                                    ),
                                    actions: [
                                      TextButton(
                                        child: Text(
                                          "Cancel",
                                          style: TextStyle(
                                            color: Colors.white,
                                          ), // 👈 Make text white
                                        ),
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              Colors
                                                  .white, // 👈 or use this (modern way)
                                          backgroundColor: Colors.grey.shade700,
                                        ),
                                        onPressed:
                                            () => Navigator.of(ctx).pop(false),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red.shade900,
                                          foregroundColor:
                                              Colors
                                                  .white, // 👈 Make text white
                                        ),
                                        onPressed:
                                            () => Navigator.of(ctx).pop(true),
                                        child: Text("Delete"),
                                      ),
                                    ],
                                  ),
                            );

                            if (confirm == true) {
                              final res = await http.delete(
                                Uri.parse(
                                  '$baseUrl/api/courses/${course['_id']}',
                                ),
                              );
                              if (res.statusCode == 200) {
                                if (mounted) {
                                  await fetchCourses();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Course deleted')),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to delete course'),
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            padding: EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: green,
        elevation: 0,
        title: const Text(
          "🍳 Cook Lessons", // ✅ More professional label
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded, // ✅ NY2-style back arrow
            color: Colors.white,
          ),
          onPressed: () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),

      backgroundColor: Colors.grey[100],
      body:
          courses.isEmpty
              ? Center(child: CircularProgressIndicator(color: green))
              : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: GridView.builder(
                  itemCount: courses.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 450,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: null, // Let it auto-size based on content
                  ),

                  itemBuilder: (_, index) => buildCourseCard(courses[index]),
                ),
              ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'split',
            onPressed: isUploading ? null : pickAndUploadAndSplitVideo,
            backgroundColor: isUploading ? Colors.grey[300] : Colors.white,
            elevation: 4,
            icon:
                isUploading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: green,
                      ),
                    )
                    : Icon(Icons.video_call, color: green),
            label: Text(
              isUploading ? "Uploading..." : "Import Lessons",
              style: TextStyle(color: green, fontWeight: FontWeight.w600),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: green),
            ),
          ),
        ],
      ),
    );
  }
}

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  final int startTime; // in seconds
  final int endTime; // in seconds

  const VideoPlayerPage({
    super.key,
    required this.videoUrl,
    required this.startTime,
    required this.endTime,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      if (kIsWeb) {
        print('🌐 Web mode: using HTML5 video element');
        setState(() => _hasError = false);
        return;
      }

      final optimizedUrl =
          widget.videoUrl.contains('/upload/')
              ? widget.videoUrl.replaceFirst(
                '/upload/',
                '/upload/f_auto,q_auto/',
              )
              : widget.videoUrl;

      _videoPlayerController = VideoPlayerController.network(optimizedUrl);
      await _videoPlayerController.initialize();
      await _videoPlayerController.seekTo(Duration(seconds: widget.startTime));

      _videoPlayerController.addListener(() {
        final pos = _videoPlayerController.value.position;
        if (pos.inSeconds >= widget.endTime) {
          _videoPlayerController.pause();
        }
      });

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio:
            _videoPlayerController.value.aspectRatio > 0
                ? _videoPlayerController.value.aspectRatio
                : 16 / 9,
        showControls: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
      );

      setState(() => _hasError = false);
    } catch (e) {
      print('❌ Error initializing video: $e');
      setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _videoPlayerController.dispose();
      _chewieController?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      final viewId = 'video-${DateTime.now().millisecondsSinceEpoch}';
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(viewId, (int _) {
        final video =
            html.VideoElement()
              ..src = widget.videoUrl
              ..autoplay = true
              ..controls = true
              ..style.border = 'none'
              ..style.width = '100%'
              ..style.height = '100%'
              ..setAttribute('playsinline', 'true');

        video.onCanPlay.first.then((_) {
          video.currentTime = widget.startTime.toDouble();
        });

        video.onTimeUpdate.listen((event) {
          if (video.currentTime >= widget.endTime) {
            video.pause();
          }
        });

        return video;
      });

      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text("🎥 Watch Episode"),
          backgroundColor: green,
          foregroundColor: Colors.white,
        ),
        body: HtmlElementView(viewType: viewId),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("🎥 Watch Episode"),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child:
            _hasError
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 50,
                    ),
                    SizedBox(height: 12),
                    Text(
                      '❌ Failed to load video',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: Icon(Icons.refresh),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _initializePlayer,
                      label: Text("Retry"),
                    ),
                  ],
                )
                : (_chewieController != null &&
                    _chewieController!
                        .videoPlayerController
                        .value
                        .isInitialized)
                ? AspectRatio(
                  aspectRatio: _videoPlayerController.value.aspectRatio,
                  child: Chewie(controller: _chewieController!),
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(color: Colors.green),
                    SizedBox(height: 12),
                    Text(
                      "Loading video...",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
      ),
    );
  }
}
