import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  StreamSubscription? _settingsSubscription;

  // Dùng ValueNotifier để chỉ rebuild Indicator thay vì toàn bộ Widget khi chuyển trang
  final ValueNotifier<int> _currentIndexNotifier = ValueNotifier<int>(0);
  late final Stream<QuerySnapshot> _bannersStream;

  int _autoScrollInterval = 4; // Default fallback
  bool _isAutoScrolling = false;
  List<DocumentSnapshot> _banners = [];
  Timer? _cooldownTimer; // For manual swipe cooldown

  // Biến dùng để CHỐNG SPAM Firebase:
  final Set<String> _loggedViews = {}; // Ghi nhớ banner nào đã được tính view
  final Map<String, DateTime> _eventCooldowns = {}; // Ghi nhớ thời gian của các hành động lặp lại (như click)

  bool _hasLoggedInitialView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Khởi tạo Stream một lần duy nhất để tránh read Firestore liên tục khi setState
    _bannersStream = FirebaseFirestore.instance
        .collection('home_banners')
        .where('isActive', isEqualTo: true)
        .snapshots();

    _pageController = PageController(viewportFraction: 0.9);

    _progressController = AnimationController(
        vsync: this, duration: Duration(seconds: _autoScrollInterval));

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_banners.length > 1) {
          int nextPage = _currentIndexNotifier.value + 1;
          if (nextPage >= _banners.length) nextPage = 0;
          _isAutoScrolling = true;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          ).then((_) {
            _isAutoScrolling = false;
            if (mounted && _banners.length > 1) {
              _progressController.forward(from: 0.0);
            }
          });
        }
      }
    });

    // Remote Admin control setting auto scroll
    _settingsSubscription = FirebaseFirestore.instance
        .collection('system_settings')
        .doc('banner')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data.containsKey('auto_scroll_interval')) {
          int value = (data['auto_scroll_interval'] as num).toInt();
          // Clamp giá trị từ 2s -> 10s theo constraint
          if (value < 2) value = 2;
          if (value > 10) value = 10;

          if (_autoScrollInterval != value) {
            _autoScrollInterval = value;
            _progressController.duration = Duration(seconds: _autoScrollInterval);
            if (_progressController.isAnimating) {
              _progressController.forward();
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _settingsSubscription?.cancel();
    _cooldownTimer?.cancel();
    _progressController.dispose();
    _pageController.dispose();
    _currentIndexNotifier.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_banners.length > 1 && !_progressController.isAnimating && _cooldownTimer?.isActive != true) {
        _progressController.forward(); // Resume current progress
      }
    } else if (state == AppLifecycleState.paused) {
      _progressController.stop();
    }
  }

  void _onManualInteraction() {
    _cooldownTimer?.cancel();
    _progressController.stop();
    _progressController.value = 0.0;

    // Restart logic after 3s cooldown
    _cooldownTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _banners.length > 1) {
        _progressController.forward(from: 0.0);
      }
    });
  }

  Future<void> _logEvent(String eventType, String interactionType, String bannerId, int index) async {
    final now = DateTime.now();

    if (eventType == 'view') {
      // 1. CƠ CHẾ CHỈ GHI MỘT LẦN: Nếu là sự kiện 'view', chỉ tính 1 lượt xem cho mỗi banner trong cả phiên
      if (_loggedViews.contains(bannerId)) return;
      _loggedViews.add(bannerId);
    } else {
      // 2. CƠ CHẾ RATE-LIMITING (GIỚI HẠN THỜI GIAN): Cho các sự kiện lặp lại (ví dụ click)
      // Chặn việc người dùng bấm liên tục vào banner (chỉ cho phép ghi nhận 1 lần mỗi 60 giây)
      final String eventKey = '${eventType}_$bannerId';
      if (_eventCooldowns.containsKey(eventKey)) {
        final lastTimeLogged = _eventCooldowns[eventKey]!;
        if (now.difference(lastTimeLogged).inSeconds < 60) {
          return; // Bỏ qua sự kiện này nếu chưa qua 60 giây kể từ lần ghi trước
        }
      }
      _eventCooldowns[eventKey] = now; // Cập nhật lại thời điểm ghi nhận sự kiện
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;

    try {
      await FirebaseFirestore.instance.collection('banner_analytics_events').add({
        'event_type': eventType,
        'interaction_type': interactionType,
        'banner_id': bannerId,
        'banner_index': index,
        'user_id': uid, // null nếu chưa login
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error logging analytics: $e');
    }
  }

  Future<void> _launchUrl(String urlString, String bannerId, int index) async {
    // Tracking click (Sự kiện click sẽ đi qua cơ chế giới hạn thời gian ở hàm _logEvent)
    _logEvent('click', 'manual_swipe', bannerId, index);

    if (urlString.isEmpty) return;

    // Dùng tryParse để an toàn hơn, tránh crash nếu String URL bị lỗi định dạng
    final Uri? url = Uri.tryParse(urlString);
    if (url != null) {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint('Không thể mở link: $url');
      }
    } else {
      debugPrint('URL không hợp lệ: $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _bannersStream, // Sử dụng stream đã cache ở initState
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink(); // Ẩn hoàn toàn
        }

        final oldBannersLength = _banners.length;
        _banners = snapshot.data!.docs;

        if (oldBannersLength != _banners.length) {
          // Khởi động controller nếu có 2 banners trở lên, ngược lại dừng.
          if (_banners.length > 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_progressController.isAnimating && _cooldownTimer?.isActive != true) {
                _progressController.forward(from: 0.0);
              }
            });
          } else {
            _progressController.stop();
            _progressController.value = 0.0;
          }
        }

        // Tracking banner hiển thị lần đầu
        if (!_hasLoggedInitialView && _banners.isNotEmpty) {
          _hasLoggedInitialView = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _logEvent('view', 'auto_scroll', _banners[0].id, 0);
          });
        }

        return SizedBox(
          height: 180,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: _banners.length,
                onPageChanged: (index) {
                  final interaction = _isAutoScrolling ? 'auto_scroll' : 'manual_swipe';
                  if (!_isAutoScrolling) {
                    _onManualInteraction();
                  }

                  // Chỉ cập nhật ValueNotifier, KHÔNG dùng setState để tránh rebuild toàn bộ widget
                  _currentIndexNotifier.value = index;

                  _logEvent('view', interaction, _banners[index].id, index);
                },
                itemBuilder: (context, index) {
                  final bannerDoc = _banners[index];
                  final data = bannerDoc.data() as Map<String, dynamic>;

                  Color borderColor = Colors.transparent;
                  if (data['type'] == 'warning') borderColor = Colors.redAccent;
                  if (data['type'] == 'ads') borderColor = Colors.amber;

                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double offset = 0.0;
                      if (_pageController.position.haveDimensions) {
                        offset = (_pageController.page! - index).abs();
                      } else {
                        // Tính toán offset mặc định nếu chưa có dimension
                        offset = (_currentIndexNotifier.value - index).abs().toDouble();
                      }

                      double scale = 1.0 - (offset * 0.05).clamp(0.0, 0.05);
                      double opacity = 1.0 - (offset * 0.2).clamp(0.0, 0.2);

                      return Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: scale,
                          child: child,
                        ),
                      );
                    },
                    child: GestureDetector(
                      onTap: () => _launchUrl(data['actionUrl'] ?? '', bannerDoc.id, index),
                      child: Container(
                        // Căn đều lề để banner mở rộng hết cỡ nhưng vẫn chừa không gian giữa các thẻ
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor, width: 2),
                          image: DecorationImage(
                            image: NetworkImage(data['imageUrl'] ?? ''),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
                          ),
                        ),
                        child: Padding(
                          // Tăng padding bên dưới (bottom: 32) để phần text không bị thanh indicator đè lên
                          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 32.0),
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
                    ),
                  );
                },
              ),

              // Animated Indicator Row
              if (_banners.length > 1)
                Positioned(
                  bottom: 8, // Hạ thấp xuống (từ 16 xuống 8) để gần sát mép dưới banner hơn
                  left: 0,
                  right: 0,
                  // Chỉ bao bọc Row này với ValueListenableBuilder
                  child: ValueListenableBuilder<int>(
                      valueListenable: _currentIndexNotifier,
                      builder: (context, currentIndex, _) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_banners.length, (index) {
                            final isActive = currentIndex == index;

                            return GestureDetector(
                              behavior: HitTestBehavior.opaque, // Đảm bảo bấm vào khoảng trống padding vẫn nhận sự kiện
                              onTap: () {
                                if (!isActive) {
                                  _onManualInteraction();
                                  _pageController.animateToPage(
                                    index,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
                              child: Padding(
                                // Tăng vùng hit box (vùng nhận tap) lớn hơn để dễ bấm trên điện thoại
                                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 12.0),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeOutQuart, // Hiệu ứng co giãn pill mượt mà và tự nhiên hơn
                                  width: isActive ? 48.0 : 6.0, // Chấm active kéo dài thành dạng "pill" (48px)
                                  height: 6.0, // Thanh mảnh hơn, giống thanh progress của Instagram
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3), // Bo góc tương ứng
                                    color: isActive
                                        ? Colors.black.withOpacity(0.5) // Tối hơn chút để thanh màu sáng nổi lên
                                        : Colors.white.withOpacity(0.7), // Sáng hơn để dễ nhìn thấy các chấm còn lại
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26, // Bóng mờ giúp chống lóa trên nền ảnh trắng
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: isActive
                                      ? AnimatedBuilder(
                                    animation: _progressController,
                                    builder: (context, child) {
                                      // Dùng FractionallySizedBox giúp thanh progress lấp đầy phần trăm chính xác
                                      // kể cả khi Container mẹ đang trong animation thay đổi kích thước
                                      return FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: _progressController.value,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(3),
                                            color: Colors.white, // Chuyển thanh progress bar thành màu trắng
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                      : null,
                                ),
                              ),
                            );
                          }),
                        );
                      }
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}