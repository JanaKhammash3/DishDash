import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class AdminChallengesPage extends StatefulWidget {
  const AdminChallengesPage({super.key});

  @override
  State<AdminChallengesPage> createState() => _AdminChallengesPageState();
}

class _AdminChallengesPageState extends State<AdminChallengesPage> {
  final String baseUrl = 'http://192.168.68.60:3000/api/challenges';
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _rewardController = TextEditingController();
  String _selectedType = 'Meal Planning';
  DateTime? _startDate;
  DateTime? _endDate;
  List<dynamic> challenges = [];
  String? editingId;

  @override
  void initState() {
    super.initState();
    fetchChallenges();
  }

  Future<void> fetchChallenges() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      setState(() => challenges = jsonDecode(response.body));
    }
  }

  ImageProvider _getImageProvider(String? image) {
    if (image == null || image.isEmpty) {
      return const AssetImage('assets/placeholder.png');
    } else if (image.startsWith('http')) {
      return NetworkImage(image);
    } else if (image.startsWith('/9j')) {
      // Base64 JPEG prefix
      try {
        return MemoryImage(base64Decode(image));
      } catch (_) {
        return const AssetImage('assets/placeholder.png');
      }
    } else {
      return const AssetImage('assets/placeholder.png');
    }
  }

  Future<void> saveChallenge() async {
    final challengeData = {
      'title': _titleController.text,
      'description': _descController.text,
      'type': _selectedType,
      'startDate': _startDate?.toIso8601String(),
      'endDate': _endDate?.toIso8601String(),
      'reward': _rewardController.text,
    };

    final url = editingId != null ? '$baseUrl/$editingId' : baseUrl;
    final method = editingId != null ? http.put : http.post;
    final response = await method(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(challengeData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final challenge = jsonDecode(response.body);
      if (editingId == null) {
        await sendChallengeNotification(challenge['_id'], challenge['title']);
      }
      fetchChallenges();
      Navigator.pop(context);
    }
  }

  Future<void> _showParticipantsModal(String challengeId) async {
    final response = await http.get(
      Uri.parse('http://192.168.68.60:3000/api/challenges/$challengeId'),
    );

    if (response.statusCode == 200) {
      final challenge = jsonDecode(response.body);
      final participants = challenge['participants'] ?? [];

      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Participants'),
              content: SizedBox(
                width: 400,
                height: 400,
                child:
                    participants.isEmpty
                        ? const Center(child: Text('No participants yet.'))
                        : ListView.builder(
                          itemCount: participants.length,
                          itemBuilder: (context, index) {
                            final user = participants[index];
                            final avatar = user['avatar'];
                            final name = user['name'] ?? 'Unknown';

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: _getImageProvider(avatar),
                              ),

                              title: Text(name),
                            );
                          },
                        ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load participants')),
      );
    }
  }

  Future<void> sendChallengeNotification(
    String challengeId,
    String title,
  ) async {
    final res = await http.get(
      Uri.parse('http://192.168.68.60:3000/api/users'),
    ); // ✅ Get all users
    if (res.statusCode == 200) {
      final users = jsonDecode(res.body);
      for (var user in users) {
        await http.post(
          Uri.parse('http://192.168.68.60:3000/api/notifications'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'recipientId': user['_id'],
            'recipientModel': 'User',
            'senderModel': 'Admin', // keep this if you want senderModel context
            'type': 'challenge',
            'message': 'A new challenge "$title" has been posted!',
            'relatedId': challengeId,
          }),
        );
      }
    }
  }

  Future<void> deleteChallenge(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));
    if (response.statusCode == 200) {
      fetchChallenges();
    }
  }

  void _openChallengeDialog({Map<String, dynamic>? existingChallenge}) {
    if (existingChallenge != null) {
      editingId = existingChallenge['_id'];
      _titleController.text = existingChallenge['title'];
      _descController.text = existingChallenge['description'];
      _rewardController.text = existingChallenge['reward'];
      _selectedType = existingChallenge['type'];
      _startDate = DateTime.parse(existingChallenge['startDate']);
      _endDate = DateTime.parse(existingChallenge['endDate']);
    } else {
      editingId = null;
      _titleController.clear();
      _descController.clear();
      _rewardController.clear();
      _selectedType = 'Meal Planning';
      _startDate = null;
      _endDate = null;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              existingChallenge != null ? 'Edit Challenge' : 'New Challenge',
            ),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Required'
                                  : null,
                    ),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 3,
                    ),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items:
                          [
                                'Recipe Creation',
                                'Meal Planning',
                                'Grocery',
                                'Community Engagement',
                                'Health Tracking',
                                'Bookmarking',
                              ]
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                      onChanged: (val) => setState(() => _selectedType = val!),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2024),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null)
                                setState(() => _startDate = picked);
                            },
                            child: Text(
                              _startDate != null
                                  ? 'Start: ${DateFormat.yMd().format(_startDate!)}'
                                  : 'Select Start Date',
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2024),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null)
                                setState(() => _endDate = picked);
                            },
                            child: Text(
                              _endDate != null
                                  ? 'End: ${DateFormat.yMd().format(_endDate!)}'
                                  : 'Select End Date',
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: _rewardController,
                      decoration: const InputDecoration(labelText: 'Reward'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    saveChallenge();
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Challenges'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: () => _openChallengeDialog(),
              child: const Text('+ New Challenge'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            challenges.isEmpty
                ? const Center(child: Text('No challenges yet'))
                : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Title')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Start Date')),
                      DataColumn(label: Text('End Date')),
                      DataColumn(label: Text('Reward')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows:
                        challenges.map((challenge) {
                          return DataRow(
                            cells: [
                              DataCell(Text(challenge['title'])),
                              DataCell(Text(challenge['type'])),
                              DataCell(
                                Text(
                                  DateFormat.yMd().format(
                                    DateTime.parse(challenge['startDate']),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  DateFormat.yMd().format(
                                    DateTime.parse(challenge['endDate']),
                                  ),
                                ),
                              ),
                              DataCell(Text(challenge['reward'])),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed:
                                          () => _openChallengeDialog(
                                            existingChallenge: challenge,
                                          ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.people,
                                      ), // 👈 participants icon
                                      onPressed:
                                          () => _showParticipantsModal(
                                            challenge['_id'],
                                          ),
                                      tooltip: 'Participants',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed:
                                          () =>
                                              deleteChallenge(challenge['_id']),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                ),
      ),
    );
  }
}
