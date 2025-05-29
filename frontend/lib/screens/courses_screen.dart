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
            builder:
                (context, scrollController) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course['title'],
                        style: TextStyle(
                          fontSize: 22,
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
                      Divider(color: Colors.grey.shade400),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: course['episodes'].length,
                          itemBuilder: (_, index) {
                            final ep = course['episodes'][index];
                            return Card(
                              color: Colors.green.shade50,
                              margin: EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: Icon(
                                  Icons.video_library,
                                  color: Colors.green,
                                ),
                                title: Text(
                                  ep['title'],
                                  style: TextStyle(
                                    color: Colors.green.shade900,
                                  ),
                                ),
                                subtitle: Text("${ep['duration']} min"),
                                trailing: TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.green,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => VideoPlayerScreen(
                                              videoUrl: ep['videoUrl'],
                                            ),
                                      ),
                                    );
                                  },
                                  child: Text("Watch Now"),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Rate this course:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green.shade900,
                        ),
                      ),
                      RatingBar.builder(
                        initialRating: 0,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: false,
                        itemCount: 5,
                        itemSize: 30,
                        itemBuilder:
                            (context, _) =>
                                Icon(Icons.star, color: Colors.amber),
                        onRatingUpdate:
                            (rating) => submitRating(course['_id'], rating),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget buildCourseCard(course) {
    return InkWell(
      onTap: () => showCourseDetail(course),
      child: Card(
        margin: EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
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
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course['title'],
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "By ${course['chefName']}",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${course['episodes'].length} Lessons",
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      Text(
                        "${getTotalDuration(course['episodes'])} Min",
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.orange, size: 16),
                          Text(
                            calculateAverageRating(
                              course['ratings'],
                            ).toStringAsFixed(1),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: Text(
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
      appBar: AppBar(title: Text("Masterclasses"), backgroundColor: green),
      backgroundColor: Colors.grey.shade50,
      body: ListView(children: courses.map(buildCourseCard).toList()),
      floatingActionButton: FloatingActionButton(
        onPressed: isUploading ? null : pickAndUploadVideo,
        backgroundColor: green,
        child:
            isUploading
                ? CircularProgressIndicator(color: Colors.white)
                : Icon(Icons.upload_file),
        tooltip: 'Upload Course Episode',
      ),
    );
  }
}
