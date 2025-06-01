import 'dart:convert';
import 'dart:typed_data';
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
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if ((kIsWeb &&
                            (avatarWebFile == null || coverWebFile == null)) ||
                        (!kIsWeb &&
                            (avatarFile == null || coverFile == null))) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Please upload both images")),
                      );
                      return;
                    }

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

                    Navigator.pop(context);
                    await fetchCourses();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text('Create Course'),
                ),
              ],
            ),
      );
    }
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
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  Future<void> submitRating(String courseId, double rating) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/courses/$courseId/rate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rating': rating}),
      );

      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            final index = courses.indexWhere((c) => c['_id'] == courseId);
            if (index != -1) {
              // Ensure ratings array exists
              courses[index]['ratings'] ??= [];
              courses[index]['ratings'].add(rating);
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Thanks for rating the course!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception("Failed to submit rating");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error submitting rating: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void showCourseDetail(Map<String, dynamic> course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        // ✅ Declare here to persist between rebuilds
        bool showFullDescription = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      Text(
                        course['title'],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                      Text(
                        "By ${course['chefName']}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // ✅ More compact description with Read More
                      if (course['description'] != null &&
                          course['description'].toString().trim().isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course['description'],
                                maxLines: showFullDescription ? null : 2,
                                overflow: TextOverflow.fade,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              if (course['description'].length > 100)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    onPressed: () {
                                      setModalState(() {
                                        showFullDescription =
                                            !showFullDescription;
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.all(0),
                                    ),
                                    child: Text(
                                      showFullDescription
                                          ? "Show Less"
                                          : "Read More",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.green.shade800,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 3),
                      Divider(thickness: 1, color: Colors.grey.shade300),
                      const SizedBox(height: 3),

                      Text(
                        "Lessons",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 6),

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
                              margin: const EdgeInsets.symmetric(vertical: 5),
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
                          fontSize: 15,
                          color: Colors.green.shade900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
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
                            itemSize: 25, // ✅ Smaller stars
                            itemBuilder:
                                (context, _) =>
                                    const Icon(Icons.star, color: Colors.amber),
                            onRatingUpdate:
                                (rating) => submitRating(course['_id'], rating),
                          ),
                        ),
                      ),

                      const SizedBox(height: 5),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
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
              child:
                  course['image'] != null
                      ? Image.network(
                        course['image'],
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                      : Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: Icon(Icons.image_not_supported, size: 40),
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
                    children: [
                      if (course['chefAvatar'] != null)
                        CircleAvatar(
                          backgroundImage: NetworkImage(course['chefAvatar']),
                          radius: 16,
                        )
                      else
                        CircleAvatar(
                          backgroundColor: Colors.grey[300],
                          child: Icon(Icons.person, color: Colors.grey),
                          radius: 16,
                        ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          course['chefName'] ?? 'Unknown Chef',
                          style: TextStyle(color: Colors.grey[700]),
                          overflow: TextOverflow.ellipsis,
                        ),
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
                  if (course['ratings'] != null &&
                      course['ratings'].isNotEmpty) ...[
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        SizedBox(width: 4),
                        Text(
                          calculateAverageRating(
                            course['ratings'],
                          ).toStringAsFixed(1),
                          style: TextStyle(color: Colors.grey[800]),
                        ),
                      ],
                    ),
                  ],
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
              : ListView.builder(
                itemCount: courses.length,
                padding: EdgeInsets.symmetric(vertical: 12),
                itemBuilder: (_, index) => buildCourseCard(courses[index]),
              ),
    );
  }
}
