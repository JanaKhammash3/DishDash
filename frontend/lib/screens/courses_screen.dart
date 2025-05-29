import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/colors.dart';
import 'package:frontend/screens/video_player_screen.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'dart:html' as html; // 👈 for web
import 'package:file_picker/file_picker.dart';

class CoursesScreen extends StatefulWidget {
  final String userId;
  const CoursesScreen({super.key, required this.userId});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  List<dynamic> courses = [];
  final String baseUrl = 'http://192.168.1.4:3000';
  bool isUploading = false;

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

  Future<void> createCourseWithEpisodes({
    required String title,
    required String description,
    required String chefName,
    required String chefAvatar,
    required String coverImageUrl,
    required List<Map<String, dynamic>> episodes,
  }) async {
    final uri = Uri.parse('$baseUrl/api/courses');

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "title": title,
        "description": description,
        "chefName": chefName,
        "chefAvatar": chefAvatar,
        "image": coverImageUrl,
        "episodes": episodes,
      }),
    );

    print('📦 Course Create Status: ${res.statusCode}');
    print('📦 Course Create Body: ${res.body}');

    if (res.statusCode == 201) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('✅ Course created')));
      await fetchCourses();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Failed to create course')));
    }
  }

  Future<void> pickAndUploadAndSplitVideo() async {
    setState(() => isUploading = true);

    final videoUrl = await uploadVideo();

    setState(() => isUploading = false);

    if (videoUrl != null && videoUrl.isNotEmpty) {
      final titleController = TextEditingController();
      final descriptionController = TextEditingController();
      final chefController = TextEditingController();
      final avatarController = TextEditingController();
      final imageController = TextEditingController();
      final durationController = TextEditingController(); // seconds

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              scrollable: true,
              title: Text('Auto-Split Course Details'),
              content: Column(
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: 'Course Title'),
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(labelText: 'Description'),
                  ),
                  TextField(
                    controller: chefController,
                    decoration: InputDecoration(labelText: 'Chef Name'),
                  ),
                  TextField(
                    controller: avatarController,
                    decoration: InputDecoration(labelText: 'Chef Avatar'),
                  ),
                  TextField(
                    controller: imageController,
                    decoration: InputDecoration(labelText: 'Cover Image URL'),
                  ),
                  TextField(
                    controller: durationController,
                    decoration: InputDecoration(
                      labelText: 'Full Video Duration (sec)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final uri = Uri.parse(
                      '$baseUrl/api/courses/create-from-single-video',
                    );
                    final response = await http.post(
                      uri,
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        "title": titleController.text.trim(),
                        "description": descriptionController.text.trim(),
                        "chefName": chefController.text.trim(),
                        "chefAvatar": avatarController.text.trim(),
                        "image": imageController.text.trim(),
                        "videoUrl": videoUrl,
                        "fullDuration":
                            int.tryParse(durationController.text.trim()) ?? 600,
                      }),
                    );

                    Navigator.pop(context);
                    await fetchCourses();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          response.statusCode == 201
                              ? "✅ Course created!"
                              : "❌ Failed to create course",
                        ),
                      ),
                    );
                  },
                  child: Text('Create Auto Lessons'),
                ),
              ],
            ),
      );
    }
  }

  Future<String?> pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;

    final uri = Uri.parse(
      '$baseUrl/api/upload-image',
    ); // You need this endpoint
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('image', picked.path));

    final res = await request.send();
    final response = await http.Response.fromStream(res);
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['url'];
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

                    Navigator.pop(context);
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
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  Future<void> submitRating(String courseId, double rating) async {
    await http.post(
      Uri.parse('$baseUrl/api/courses/$courseId/rate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'rating': rating}),
    );
    fetchCourses();
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
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
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
                                            (_) => VideoPlayerScreen(
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
                      Text(
                        "Rate this course:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green.shade900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: RatingBar.builder(
                            initialRating: 0,
                            minRating: 1,
                            direction: Axis.horizontal,
                            allowHalfRating: false,
                            itemCount: 5,
                            itemSize: 30,
                            itemBuilder:
                                (context, _) =>
                                    const Icon(Icons.star, color: Colors.amber),
                            onRatingUpdate:
                                (rating) => submitRating(course['_id'], rating),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget buildCourseCard(course) {
    return GestureDetector(
      onTap: () => showCourseDetail(course),
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                course['image'],
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course['title'],
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "👨‍🍳 ${course['chefName']}",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.orange, size: 16),
                          SizedBox(width: 4),
                          Text(
                            calculateAverageRating(
                              course['ratings'],
                            ).toStringAsFixed(1),
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("🎬 ${course['episodes'].length} Lessons"),
                      Text("⏱️ ${getTotalDuration(course['episodes'])} min"),
                    ],
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(
                        Icons.play_circle_outline,
                        color: Colors.white, // ✅ White icon
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      label: Text(
                        "View Lessons",
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () => showCourseDetail(course),
                    ),
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
            Navigator.pop(context); // ✅ Goes back to previous screen
          },
        ),
      ),

      backgroundColor: Colors.grey[100],
      body:
          courses.isEmpty
              ? Center(child: CircularProgressIndicator(color: green))
              : ListView.builder(
                itemCount: courses.length,
                padding: EdgeInsets.symmetric(vertical: 12),
                itemBuilder: (_, index) => buildCourseCard(courses[index]),
              ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'single',
            onPressed: isUploading ? null : pickAndUploadVideo,
            backgroundColor: green,
            icon: Icon(Icons.video_call, color: Colors.white),
            label: Text("Single Lesson", style: TextStyle(color: Colors.white)),
          ),
          SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'split',
            onPressed: isUploading ? null : pickAndUploadAndSplitVideo,
            backgroundColor: Colors.orange,
            icon: Icon(Icons.auto_fix_high, color: Colors.white),
            label: Text(
              "Auto-Split Lessons",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
