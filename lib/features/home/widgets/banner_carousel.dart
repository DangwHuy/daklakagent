import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  // Bắt đầu từ một trang rất lớn để có thể lướt qua trái ngay từ đầu
  final PageController _pageController = PageController(viewportFraction: 0.9, initialPage: 5000);
  late final Stream<QuerySnapshot> _bannerStream;
  int _currentPage = 5000;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _bannerStream = FirebaseFirestore.instance
        .collection('home_banners')
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer(int itemCount) {
    _timer?.cancel(); // Hủy timer cũ nếu có
    if (itemCount <= 1) return; // Không cần tự lướt nếu chỉ có 1 banner

    // Thay đổi thời gian lên 6 giây theo yêu cầu
    _timer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // Hàm mở trình duyệt khi bấm vào Card
  Future<void> _launchUrl(String urlString) async {
    if (urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Không thể mở link: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Sử dụng stream đã được khởi tạo trong initState để tránh bị giật khi setState
      stream: _bannerStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink(); // Ẩn hoàn toàn nếu không có tin nào
        }

        final banners = snapshot.data!.docs;
        final int itemCount = banners.length;

        // Khởi tạo timer khi có dữ liệu và chưa có timer
        if (_timer == null && itemCount > 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startTimer(itemCount);
          });
        }

        return Column(
          children: [
            SizedBox(
              height: 180, // Chiều cao của khu vực Banner
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                // Sử dụng số lượng item cực lớn để giả lập vòng lặp vô tận
                itemCount: 10000,
                itemBuilder: (context, index) {
                  // Lấy dữ liệu theo vòng lặp (index % itemCount)
                  final data = banners[index % itemCount].data() as Map<String, dynamic>;

                  // Tùy biến màu viền dựa theo loại tin (type)
                  Color borderColor = Colors.transparent;
                  if (data['type'] == 'warning') borderColor = Colors.redAccent;

                  return GestureDetector(
                    onTap: () => _launchUrl(data['actionUrl'] ?? ''),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 2),
                        image: DecorationImage(
                          image: NetworkImage(data['imageUrl'] ?? ''),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken), // Làm tối ảnh để chữ nổi lên
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              data['title'] ?? '',
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['description'] ?? '',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // PAGE INDICATOR
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(itemCount, (index) {
                // Tính toán xem dot nào đang active dựa trên index % itemCount
                final bool isActive = (_currentPage % itemCount) == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: isActive ? 18 : 8,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}