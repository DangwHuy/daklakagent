import 'package:flutter/material.dart';

class ExpertHelpScreen extends StatefulWidget {
  const ExpertHelpScreen({super.key});

  @override
  State<ExpertHelpScreen> createState() => _ExpertHelpScreenState();
}

class _ExpertHelpScreenState extends State<ExpertHelpScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ── Màu sắc chủ đạo ──────────────────────────────────────────────────────────
  static const Color kPrimary = Color(0xFF2E7D32); // Xanh lá đậm chuyên gia
  static const Color kAccent = Color(0xFF81C784);
  static const Color kBg = Color(0xFFF4F6F8);

  final List<Map<String, dynamic>> _helpCategories = [
    {
      'icon': Icons.rocket_launch_rounded,
      'title': 'Bắt đầu',
      'desc': 'Cách thiết lập hồ sơ & trạng thái trực tuyến.',
      'color': Colors.blue,
    },
    {
      'icon': Icons.assignment_turned_in_rounded,
      'title': 'Quy trình',
      'desc': 'Xử lý lịch hẹn từ lúc đặt đến hoàn thành.',
      'color': Colors.green,
    },
    {
      'icon': Icons.account_balance_wallet_rounded,
      'title': 'Thu nhập',
      'desc': 'Chính sách thanh toán, hoa hồng & tiền mặt.',
      'color': Colors.orange,
    },
    {
      'icon': Icons.security_rounded,
      'title': 'Bảo mật',
      'desc': 'Quy tắc ứng xử và bảo mật thông tin vườn.',
      'color': Colors.red,
    },
  ];

  final List<Map<String, String>> _faqs = [
    {
      'q': 'Làm thế nào để thay đổi lịch hẹn khi có việc bận?',
      'a': 'Hiện tại, hệ thống khuyến khích bạn liên hệ trực tiếp với nông dân qua mục Chat để thỏa thuận lại thời gian. Sau đó, bạn có thể hướng dẫn nông dân hủy lịch cũ và đặt lại lịch mới nếu cần thiết.'
    },
    {
      'q': 'Tại sao tôi không nhận được thông báo đặt lịch?',
      'a': 'Hãy chắc chắn rằng bạn đã bật thông báo cho ứng dụng DaklakAgent trong cài đặt điện thoại và trạng thái của bạn đang là "Rảnh" trên màn hình chính.'
    },
    {
      'q': 'Phí nền tảng 10% được tính như thế nào?',
      'a': 'Khi bạn hoàn thành lịch hẹn, hệ thống sẽ tự động ghi nhận doanh thu. Phí 10% là phí duy trì hệ thống và hỗ trợ khách hàng, 90% còn lại sẽ là thu nhập thực tế của bạn.'
    },
    {
      'q': 'Tôi phải làm gì nếu nông dân không trả tiền mặt?',
      'a': 'Đối với các dịch vụ thanh toán tiền mặt trực tiếp tại vườn, bạn hãy xác nhận số tiền trước khi bắt đầu tư vấn. Nếu gặp sự cố, hãy dùng nút "Báo cáo nội dung" hoặc liên hệ Admin qua hotline.'
    },
    {
      'q': 'Yêu cầu về ảnh chứng minh hoàn thành là gì?',
      'a': 'Ảnh chụp cần rõ nét, thể hiện bạn đang tư vấn tại vườn hoặc tình trạng cây trồng đã được xử lý. Ảnh này là cơ sở để hệ thống phê duyệt thu nhập cho bạn.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildWelcomeHero()),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(child: _buildCategoryGrid()),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(child: _buildFAQSection()),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 40),
            sliver: SliverToBoxAdapter(child: _buildContactSupport()),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      backgroundColor: kBg,
      surfaceTintColor: Colors.transparent,
      leadingWidth: 70,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Center(
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
            ),
          ),
        ),
      ),
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
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 3)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Trung tâm Hỗ trợ',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHero() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chào bạn, chúng tôi có thể\ngiúp gì cho bạn?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1B3A2D),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm vấn đề bạn gặp phải...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: kPrimary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: _helpCategories.length,
      itemBuilder: (context, index) {
        final cat = _helpCategories[index];
        final color = cat['color'] as Color;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.1), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(cat['icon'] as IconData, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                cat['title'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                cat['desc'] as String,
                style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFAQSection() {
    final filteredFaqs = _faqs.where((f) => 
      f['q']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      f['a']!.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Câu hỏi Thường gặp',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B3A2D)),
          ),
        ),
        if (filteredFaqs.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('Không tìm thấy kết quả phù hợp'),
          ))
        else
          ...filteredFaqs.map((faq) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: const Icon(Icons.help_outline_rounded, color: kAccent),
              title: Text(
                faq['q']!,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    faq['a']!,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.5),
                  ),
                ),
              ],
            ),
          )),
      ],
    );
  }

  Widget _buildContactSupport() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1B3A2D),
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: const AssetImage('assets/images/pattern.png'), // Placeholder or subtle pattern
          opacity: 0.1,
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Vẫn cần trợ giúp?',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Đội ngũ hỗ trợ của chúng tôi luôn sẵn sàng 24/7 để trả lời mọi thắc mắc của bạn.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1B3A2D),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Liên hệ với Admin', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
