import 'dart:convert';
import 'package:dishdash_web/colors.dart';
import 'package:dishdash_web/pages/courses_page.dart';
import 'package:dishdash_web/pages/stores_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_home.dart';
import 'users_page.dart';
import 'recipes_page.dart';
import 'challenges_page.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui_web' as ui;
import 'dart:html' as html;

class DashboardPage extends StatefulWidget {
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int totalUsers = 0;
  int totalStores = 0;
  int totalRecipes = 0;
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> stores = [];
  Widget currentPage = const Center(child: CircularProgressIndicator());

  bool isSidebarExpanded = false;
  String activeTab = 'Dashboard';

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    try {
      final userRes = await http.get(
        Uri.parse('http://192.168.1.4:3000/api/users'),
      );
      final storeRes = await http.get(
        Uri.parse('http://192.168.1.4:3000/api/stores'),
      );
      final recipeRes = await http.get(
        Uri.parse('http://192.168.1.4:3000/api/recipes'),
      );

      if (userRes.statusCode == 200 &&
          storeRes.statusCode == 200 &&
          recipeRes.statusCode == 200) {
        setState(() {
          users = List<Map<String, dynamic>>.from(jsonDecode(userRes.body));
          stores = List<Map<String, dynamic>>.from(jsonDecode(storeRes.body));
          totalUsers = users.length;
          totalStores = stores.length;
          totalRecipes = jsonDecode(recipeRes.body).length;

          currentPage = DashboardHome(
            totalUsers: totalUsers,
            totalStores: totalStores,
            totalRecipes: totalRecipes,
            users: users,
            stores: stores,
          );
        });
      }
    } catch (e) {
      print('Error fetching stats: $e');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF304D30),
      drawer: isSmallScreen ? Drawer(child: buildSidebar(true)) : null,
      body: Row(
        children: [
          if (!isSmallScreen)
            MouseRegion(
              onEnter: (_) => setState(() => isSidebarExpanded = true),
              onExit: (_) => setState(() => isSidebarExpanded = false),
              child: buildSidebar(false),
            ),
          Expanded(child: currentPage),
        ],
      ),
    );
  }

  Widget buildSidebar(bool forceExpanded) {
    final expanded = forceExpanded || isSidebarExpanded;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: expanded ? 200 : 70,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3920), Color(0xFF304D30)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 30),
          if (expanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: [
                  Image.asset(
                    'assets/Login.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Admin Panel',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            const Icon(Icons.admin_panel_settings, color: Colors.white),
          const SizedBox(height: 30),
          SidebarItem(
            icon: Icons.dashboard,
            label: 'Dashboard',
            isExpanded: expanded,
            tooltip: 'Dashboard',
            isActive: activeTab == 'Dashboard',
            onTap: () {
              setState(() {
                activeTab = 'Dashboard';
                currentPage = DashboardHome(
                  totalUsers: totalUsers,
                  totalStores: totalStores,
                  totalRecipes: totalRecipes,
                  users: users,
                  stores: stores,
                );
              });
            },
          ),
          SidebarItem(
            icon: Icons.people,
            label: 'Users',
            isExpanded: expanded,
            tooltip: 'Users',
            isActive: activeTab == 'Users',
            onTap:
                () => setState(() {
                  activeTab = 'Users';
                  currentPage = UsersPage();
                }),
          ),
          SidebarItem(
            icon: Icons.store,
            label: 'Stores',
            isExpanded: expanded,
            tooltip: 'Stores',
            isActive: activeTab == 'Stores',
            onTap: () {
              setState(() {
                activeTab = 'Stores';
                currentPage = StoresPage();
              });
            },
          ),
          SidebarItem(
            icon: Icons.receipt_long,
            label: 'Recipes',
            isExpanded: expanded,
            tooltip: 'Recipes',
            isActive: activeTab == 'Recipes',
            onTap:
                () => setState(() {
                  activeTab = 'Recipes';
                  currentPage = RecipesPage();
                }),
          ),
          SidebarItem(
            icon: Icons.video_library,
            label: 'Lessons',
            isExpanded: expanded,
            tooltip: 'Lessons',
            isActive: activeTab == 'Lessons',
            onTap: () {
              setState(() {
                activeTab = 'Lessons';
                currentPage = CoursesPage(
                  userId: '',
                ); // ✅ Replace with your actual widget
              });
            },
          ),

          SidebarItem(
            icon: Icons.flag,
            label: 'Challenges',
            isExpanded: expanded,
            tooltip: 'Challenges',
            isActive: activeTab == 'Challenges',
            onTap:
                () => setState(() {
                  activeTab = 'Challenges';
                  currentPage = AdminChallengesPage();
                }),
          ),
          const Spacer(),
          SidebarItem(
            icon: Icons.logout,
            label: 'Logout',
            isExpanded: expanded,
            tooltip: 'Logout',
            isActive: false,
            onTap: logout,
            color: Colors.lightGreen,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isExpanded;
  final Color? color;
  final String? tooltip;
  final bool isActive;

  const SidebarItem({
    required this.icon,
    required this.label,
    this.onTap,
    required this.isExpanded,
    this.color,
    this.tooltip,
    this.isActive = false,
  });

  @override
  State<SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<SidebarItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bgColor =
        widget.isActive
            ? Colors.white.withOpacity(0.1)
            : isHovered
            ? const Color(0xFF3E5E3E)
            : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: Tooltip(
        message: widget.isExpanded ? '' : widget.tooltip ?? widget.label,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            color: bgColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              mainAxisAlignment:
                  widget.isExpanded
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: widget.color ?? Colors.white),
                if (widget.isExpanded) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.label,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: TextStyle(color: widget.color ?? Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
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
