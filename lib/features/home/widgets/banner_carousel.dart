import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class BannerCarousel extends StatelessWidget {
  const BannerCarousel({super.key});

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
      // Chỉ lấy những banner được Admin bật (isActive = true)
      stream: FirebaseFirestore.instance
          .collection('home_banners')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink(); // Ẩn hoàn toàn nếu không có tin nào
        }

        final banners = snapshot.data!.docs;

        return SizedBox(
          height: 180, // Chiều cao của khu vực Banner
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.9), // Giúp nhìn thấy lấp ló thẻ bên cạnh để gợi ý vuốt
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final data = banners[index].data() as Map<String, dynamic>;

              // Tùy biến màu viền dựa theo loại tin (type)
              Color borderColor = Colors.transparent;
              if (data['type'] == 'warning') borderColor = Colors.redAccent;
              if (data['type'] == 'ads') borderColor = Colors.amber;

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
        );
      },
    );
  }
}