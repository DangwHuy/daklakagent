import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/post_card.dart';
import 'create_post_screen.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  late Stream<QuerySnapshot> _postsStream;

  @override
  void initState() {
    super.initState();
    _postsStream = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6F8),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: const DecorationImage(
                  image: AssetImage('assets/images/ai_logo.png'),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 3)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Cộng đồng nông nghiệp",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Thanh tìm kiếm Premium
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Tìm kiếm bài viết hoặc #hashtag...",
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.green[600], size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ),
              
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _postsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: Colors.green[700]));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Lỗi: ${snapshot.error}"));
                    }
                    
                    var posts = snapshot.data?.docs ?? [];
    
                    // Lọc bài đăng dựa trên _searchQuery
                    if (_searchQuery.isNotEmpty) {
                      posts = posts.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final String content = (data['content'] ?? '').toString().toLowerCase();
                        final List hashtags = data['hashtags'] ?? [];
                        
                        if (_searchQuery.startsWith('#')) {
                          final tagToSearch = _searchQuery.substring(1);
                          return hashtags.any((tag) => tag.toString().toLowerCase().contains(tagToSearch));
                        }
                        
                        bool matchContent = content.contains(_searchQuery);
                        bool matchHashtag = hashtags.any((tag) => tag.toString().toLowerCase().contains(_searchQuery.replaceAll('#', '')));
                        
                        return matchContent || matchHashtag;
                      }).toList();
                    }
    
                    if (posts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty ? "Chưa có bài đăng nào" : "Không tìm thấy kết quả",
                              style: TextStyle(fontSize: 16, color: Colors.grey[500], fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }
    
                    return RefreshIndicator(
                      color: Colors.green[700],
                      onRefresh: () async {
                        setState(() {
                          _postsStream = FirebaseFirestore.instance
                              .collection('posts')
                              .orderBy('timestamp', descending: true)
                              .snapshots();
                        });
                        // Đợi một chút để người dùng thấy hiệu ứng loading
                        await Future.delayed(const Duration(milliseconds: 800));
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 100),
                        itemCount: posts.length,
                        itemBuilder: (context, index) => PostCard(post: posts[index]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          
          // Nút di chuyển được (Tách thành Widget riêng để tránh load lại trang khi kéo)
          const MovablePostButton(),
        ],
      ),
    );
  }
}

class MovablePostButton extends StatefulWidget {
  const MovablePostButton({super.key});

  @override
  State<MovablePostButton> createState() => _MovablePostButtonState();
}

class _MovablePostButtonState extends State<MovablePostButton> {
  Offset? position;

  @override
  Widget build(BuildContext context) {
    if (position == null) {
      final size = MediaQuery.of(context).size;
      // Vị trí khởi tạo mới: Giữa màn hình theo chiều dọc, cách lề phải 110px
      // Điều này giúp nút không xuất hiện ở khu vực thanh điều hướng
      position = Offset(size.width - 110, size.height / 2 - 50);
    }

    return Positioned(
      left: position!.dx,
      top: position!.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            // Di chuyển tự do hoàn toàn
            position = position! + details.delta;
          });
        },
        onTap: () {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => const CreatePostScreen())
          );
        },
        child: SizedBox(
          width: 110,
          height: 110,
          child: Image.asset(
            'assets/images/dang_bai_catnen.png',
            fit: BoxFit.contain, // Đảm bảo ảnh cắt nền hiển thị trọn vẹn
          ),
        ),
      ),
    );
  }
}
