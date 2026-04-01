import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

// ─────────────────────────────────────────────
//  DESIGN TOKENS — Nông nghiệp xanh tươi
// ─────────────────────────────────────────────
class _AgriColors {
  static const bg           = Color(0xFFF4F7F2);
  static const leafDark     = Color(0xFF2D6A4F);
  static const leafMid      = Color(0xFF40916C);
  static const leafLight    = Color(0xFF74C69D);
  static const mist         = Color(0xFFD8F3DC);
  static const soil         = Color(0xFF8B5E3C);
  static const wheat        = Color(0xFFFFD166);
  static const white        = Color(0xFFFFFFFF);
  static const textDark     = Color(0xFF1B3A2D);
  static const textGrey     = Color(0xFF7A9E8B);
  static const bubbleSelf   = Color(0xFF40916C);
  static const bubblePeer   = Color(0xFFFFFFFF);
  static const shadow       = Color(0x18000000);
  static const inputBg      = Color(0xFFECF4EE);
  static const divider      = Color(0xFFCDE8D6);
}

// ─────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────
class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String peerId;
  final String peerName;
  final String peerAvatar;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.peerId,
    required this.peerName,
    required this.peerAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _msgController  = TextEditingController();
  final ScrollController       _scrollCtrl    = ScrollController();
  final ImagePicker            _picker        = ImagePicker();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  bool _isUploading = false;
  bool _showAttachMenu = false;

  late final AnimationController _attachMenuCtrl;
  late final Animation<double>    _attachMenuAnim;

  @override
  void initState() {
    super.initState();
    _attachMenuCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _attachMenuAnim = CurvedAnimation(
        parent: _attachMenuCtrl, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollCtrl.dispose();
    _attachMenuCtrl.dispose();
    super.dispose();
  }

  // ── SEND TEXT ────────────────────────────────
  Future<void> _sendMessage() async {
    final msg = _msgController.text.trim();
    if (msg.isEmpty) return;
    _msgController.clear();
    await _saveMessage(text: msg);
  }

  // ── SEND IMAGE ───────────────────────────────
  Future<void> _pickAndSendImage(ImageSource source) async {
    _toggleAttachMenu(false);
    final XFile? file = await _picker.pickImage(
        source: source, imageQuality: 70, maxWidth: 1200);
    if (file == null) return;

    setState(() => _isUploading = true);

    try {
      final String fileName = '${const Uuid().v4()}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('chat_images/${widget.chatRoomId}/$fileName');

      await ref.putFile(File(file.path));
      final imageUrl = await ref.getDownloadURL();
      await _saveMessage(imageUrl: imageUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Không thể gửi ảnh, vui lòng thử lại'),
            backgroundColor: _AgriColors.soil,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ── SAVE TO FIRESTORE ────────────────────────
  Future<void> _saveMessage({String? text, String? imageUrl}) async {
    final timestamp = FieldValue.serverTimestamp();

    await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(widget.chatRoomId)
        .collection('messages')
        .add({
      'senderId' : currentUserId,
      if (text     != null) 'text'     : text,
      if (imageUrl != null) 'imageUrl' : imageUrl,
      'type'     : imageUrl != null ? 'image' : 'text',
      'createdAt': timestamp,
    });

    await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(widget.chatRoomId)
        .set({
      'chatRoomId'     : widget.chatRoomId,
      'lastMessage'    : imageUrl != null ? '📷 Hình ảnh' : text,
      'lastMessageTime': timestamp,
      'users'          : [currentUserId, widget.peerId],
    }, SetOptions(merge: true));
  }

  void _toggleAttachMenu(bool show) {
    setState(() => _showAttachMenu = show);
    if (show) _attachMenuCtrl.forward();
    else      _attachMenuCtrl.reverse();
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AgriColors.bg,
      body: Stack(
        children: [
          // Subtle leaf-pattern background
          _BackgroundDecor(),
          Column(
            children: [
              _buildAppBar(context),
              Expanded(child: _buildMessageList()),
              if (_isUploading) _buildUploadProgress(),
              _buildAttachMenuOverlay(),
              _buildInputBar(),
            ],
          ),
        ],
      ),
    );
  }

  // ── APP BAR ──────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: [Color(0xFF1B4D35), Color(0xFF2D6A4F)],
        ),
        boxShadow: [
          BoxShadow(
              color: _AgriColors.leafDark.withOpacity(0.35),
              blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              // Back button
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
              ),
              // Avatar with online ring
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _AgriColors.leafLight, width: 2.5),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 8,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: _AgriColors.mist,
                      backgroundImage: widget.peerAvatar.isNotEmpty
                          ? NetworkImage(widget.peerAvatar) : null,
                      child: widget.peerAvatar.isEmpty
                          ? Text(widget.peerName[0].toUpperCase(),
                          style: TextStyle(
                              color: _AgriColors.leafDark,
                              fontWeight: FontWeight.bold, fontSize: 18))
                          : null,
                    ),
                  ),
                  // Online dot
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: _AgriColors.wheat,
                        shape: BoxShape.circle,
                        border: Border.all(color: _AgriColors.leafDark, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Name + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.peerName,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                            width: 6, height: 6,
                            decoration: const BoxDecoration(
                                color: _AgriColors.wheat, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        const Text('Đang hoạt động',
                            style: TextStyle(
                                color: Color(0xFFB7DFC8), fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              // More options
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── MESSAGE LIST ─────────────────────────────
  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.chatRoomId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(
                  color: _AgriColors.leafMid, strokeWidth: 2.5));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final docs = snapshot.data!.docs;
        return ListView.builder(
          controller: _scrollCtrl,
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final isMe   = data['senderId'] == currentUserId;
            final isImg  = data['type'] == 'image';

            DateTime? time;
            if (data['createdAt'] != null) {
              time = (data['createdAt'] as Timestamp).toDate();
            }

            // Date divider
            bool showDateDivider = false;
            if (index < docs.length - 1) {
              final prevData = docs[index + 1].data() as Map<String, dynamic>;
              if (prevData['createdAt'] != null && data['createdAt'] != null) {
                final prevTime = (prevData['createdAt'] as Timestamp).toDate();
                final currTime = (data['createdAt'] as Timestamp).toDate();
                showDateDivider = !_isSameDay(prevTime, currTime);
              }
            }

            return Column(
              children: [
                if (showDateDivider && time != null)
                  _buildDateDivider(time),
                _buildMessageBubble(data, isMe, isImg, time),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _AgriColors.mist,
              shape: BoxShape.circle,
              border: Border.all(color: _AgriColors.divider, width: 2),
            ),
            child: const Text('🌾', style: TextStyle(fontSize: 44)),
          ),
          const SizedBox(height: 20),
          Text('Xin chào, ${widget.peerName}! 👋',
              style: const TextStyle(
                  color: _AgriColors.textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Hãy bắt đầu cuộc trò chuyện\nvề nông nghiệp hôm nay',
              textAlign: TextAlign.center,
              style: TextStyle(color: _AgriColors.textGrey, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildDateDivider(DateTime time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: _AgriColors.divider)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: _AgriColors.mist,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _AgriColors.divider),
            ),
            child: Text(
              _formatDateLabel(time),
              style: const TextStyle(
                  color: _AgriColors.textGrey, fontSize: 11,
                  fontWeight: FontWeight.w500),
            ),
          ),
          const Expanded(child: Divider(color: _AgriColors.divider)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      Map<String, dynamic> data, bool isMe, bool isImg, DateTime? time) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        child: Container(
          margin: EdgeInsets.only(
            bottom: 6,
            left:  isMe ? 48 : 0,
            right: isMe ? 0 : 48,
          ),
          decoration: BoxDecoration(
            color: isMe ? _AgriColors.bubbleSelf : _AgriColors.bubblePeer,
            borderRadius: BorderRadius.only(
              topLeft:     const Radius.circular(20),
              topRight:    const Radius.circular(20),
              bottomLeft:  Radius.circular(isMe ? 20 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 20),
            ),
            boxShadow: [
              BoxShadow(
                  color: _AgriColors.leafDark.withOpacity(0.08),
                  blurRadius: 8, offset: const Offset(0, 3)),
            ],
            // Subtle gradient for self bubble
            gradient: isMe
                ? const LinearGradient(
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
                colors: [Color(0xFF52A880), Color(0xFF2D6A4F)])
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft:     const Radius.circular(20),
              topRight:    const Radius.circular(20),
              bottomLeft:  Radius.circular(isMe ? 20 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isImg)
                  _buildImageMessage(data['imageUrl'] ?? '')
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                    child: Text(
                      data['text'] ?? '',
                      style: TextStyle(
                          color: isMe ? Colors.white : _AgriColors.textDark,
                          fontSize: 15, height: 1.4),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      isImg ? 0 : 14, isImg ? 0 : 0, 10, 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (time != null)
                        Text(
                          DateFormat('HH:mm').format(time),
                          style: TextStyle(
                              color: isMe
                                  ? Colors.white.withOpacity(0.65)
                                  : _AgriColors.textGrey,
                              fontSize: 10),
                        ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.done_all_rounded,
                            size: 13,
                            color: Colors.white.withOpacity(0.65)),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageMessage(String url) {
    if (url.isEmpty) return const SizedBox(height: 200);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black,
          pageBuilder: (_, __, ___) => _FullScreenImageViewer(imageUrl: url),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
      child: Hero(
        tag: url,
        child: Stack(
          children: [
            // Ảnh hiển thị trong bubble — tỷ lệ thực, không crop cứng
            ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 120,
                maxHeight: 280,
              ),
              child: Image.network(
                url,
                width: double.infinity,
                fit: BoxFit.contain,   // ← hiện toàn bộ ảnh, không cắt
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    width: double.infinity,
                    height: 200,
                    color: _AgriColors.mist,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                              : null,
                          color: _AgriColors.leafMid,
                          strokeWidth: 2.5,
                        ),
                        const SizedBox(height: 10),
                        const Text('Đang tải ảnh…',
                            style: TextStyle(
                                color: _AgriColors.textGrey, fontSize: 12)),
                      ],
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  width: double.infinity,
                  height: 120,
                  color: _AgriColors.mist,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image_outlined,
                            color: _AgriColors.textGrey, size: 36),
                        SizedBox(height: 6),
                        Text('Không tải được ảnh',
                            style: TextStyle(
                                color: _AgriColors.textGrey, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Gradient overlay phía dưới để timestamp dễ đọc
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 42,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0x99000000), Colors.transparent],
                  ),
                ),
              ),
            ),

            // Icon "phóng to" gợi ý có thể tap
            Positioned(
              top: 8, right: 8,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.zoom_out_map_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── UPLOAD PROGRESS ──────────────────────────
  Widget _buildUploadProgress() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _AgriColors.mist,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _AgriColors.divider),
      ),
      child: Row(
        children: [
          SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(
                  color: _AgriColors.leafMid, strokeWidth: 2)),
          const SizedBox(width: 12),
          const Text('Đang gửi ảnh…',
              style: TextStyle(
                  color: _AgriColors.leafDark, fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── ATTACH MENU OVERLAY ──────────────────────
  Widget _buildAttachMenuOverlay() {
    return ScaleTransition(
      scale: _attachMenuAnim,
      alignment: Alignment.bottomLeft,
      child: _showAttachMenu
          ? Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _AgriColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: _AgriColors.leafDark.withOpacity(0.12),
                blurRadius: 20, offset: const Offset(0, -4)),
          ],
        ),
        child: Row(
          children: [
            _attachBtn(
              icon: Icons.photo_library_rounded,
              label: 'Thư viện',
              color: _AgriColors.leafMid,
              onTap: () => _pickAndSendImage(ImageSource.gallery),
            ),
            const SizedBox(width: 12),
            _attachBtn(
              icon: Icons.camera_alt_rounded,
              label: 'Máy ảnh',
              color: _AgriColors.soil,
              onTap: () => _pickAndSendImage(ImageSource.camera),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _toggleAttachMenu(false),
              child: const Icon(Icons.close_rounded,
                  color: _AgriColors.textGrey, size: 22),
            ),
          ],
        ),
      )
          : const SizedBox.shrink(),
    );
  }

  Widget _attachBtn({
    required IconData icon,
    required String    label,
    required Color     color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 7),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── INPUT BAR ────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: _AgriColors.white,
        boxShadow: [
          BoxShadow(
              color: _AgriColors.shadow,
              blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Attach button
              GestureDetector(
                onTap: () => _toggleAttachMenu(!_showAttachMenu),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _showAttachMenu
                        ? _AgriColors.leafMid
                        : _AgriColors.inputBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _showAttachMenu
                        ? Icons.close_rounded
                        : Icons.add_photo_alternate_outlined,
                    color: _showAttachMenu
                        ? Colors.white
                        : _AgriColors.leafMid,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Text field
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: _AgriColors.inputBg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                        color: _AgriColors.divider, width: 1.2),
                  ),
                  child: TextField(
                    controller: _msgController,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                        color: _AgriColors.textDark, fontSize: 15),
                    decoration: const InputDecoration(
                      hintText: 'Nhập tin nhắn…',
                      hintStyle: TextStyle(
                          color: _AgriColors.textGrey, fontSize: 15),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 18, vertical: 11),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Send button
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _msgController,
                builder: (_, value, __) {
                  final hasText = value.text.trim().isNotEmpty;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      gradient: hasText
                          ? const LinearGradient(
                          colors: [Color(0xFF52A880), Color(0xFF2D6A4F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight)
                          : null,
                      color: hasText ? null : _AgriColors.inputBg,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: hasText
                          ? [BoxShadow(
                          color: _AgriColors.leafDark.withOpacity(0.3),
                          blurRadius: 8, offset: const Offset(0, 3))]
                          : null,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.send_rounded,
                        size: 20,
                        color: hasText ? Colors.white : _AgriColors.textGrey,
                      ),
                      onPressed: hasText ? _sendMessage : null,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── HELPERS ──────────────────────────────────
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDateLabel(DateTime d) {
    final now = DateTime.now();
    if (_isSameDay(d, now)) return 'Hôm nay';
    if (_isSameDay(d, now.subtract(const Duration(days: 1)))) return 'Hôm qua';
    return DateFormat('dd/MM/yyyy').format(d);
  }
}

// ─────────────────────────────────────────────
//  BACKGROUND DECOR — lá cây nhẹ nhàng
// ─────────────────────────────────────────────
class _BackgroundDecor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(painter: _LeafPatternPainter()),
    );
  }
}

class _LeafPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF74C69D).withOpacity(0.06)
      ..style = PaintingStyle.fill;

    // Top-right decorative blob
    final p1 = Path()
      ..moveTo(size.width * 0.65, 0)
      ..quadraticBezierTo(size.width, 0, size.width, size.height * 0.15)
      ..quadraticBezierTo(size.width * 0.9, size.height * 0.25,
          size.width * 0.7, size.height * 0.08)
      ..close();
    canvas.drawPath(p1, paint);

    // Bottom-left decorative blob
    final p2 = Path()
      ..moveTo(0, size.height * 0.82)
      ..quadraticBezierTo(0, size.height, size.width * 0.25, size.height)
      ..quadraticBezierTo(
          size.width * 0.18, size.height * 0.88, 0, size.height * 0.82)
      ..close();
    canvas.drawPath(p2, paint..color = const Color(0xFF40916C).withOpacity(0.05));
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────
//  FULL-SCREEN IMAGE VIEWER — pinch to zoom
// ─────────────────────────────────────────────
class _FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;
  const _FullScreenImageViewer({required this.imageUrl});

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformCtrl = TransformationController();
  late final AnimationController _animCtrl;
  Animation<Matrix4>? _resetAnim;

  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _animCtrl.addListener(() {
      if (_resetAnim != null) {
        _transformCtrl.value = _resetAnim!.value;
      }
    });
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    if (_isZoomed) {
      // Reset về fit
      _resetAnim = Matrix4Tween(
        begin: _transformCtrl.value,
        end: Matrix4.identity(),
      ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
      _animCtrl.forward(from: 0);
      setState(() => _isZoomed = false);
    } else {
      // Zoom 2.5×
      _resetAnim = Matrix4Tween(
        begin: _transformCtrl.value,
        end: Matrix4.diagonal3Values(2.5, 2.5, 1),
      ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
      _animCtrl.forward(from: 0);
      setState(() => _isZoomed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.close_rounded,
                color: Colors.white, size: 22),
          ),
        ),
        actions: [
          // Nút lưu ảnh (UI placeholder — tích hợp image_gallery_saver nếu cần)
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Tính năng lưu ảnh sắp ra mắt'),
                  backgroundColor: _AgriColors.leafDark,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.download_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 4),
                  Text('Lưu', style: TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onDoubleTap: _onDoubleTap,
        // Vuốt xuống để đóng
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 500 &&
              !_isZoomed) {
            Navigator.pop(context);
          }
        },
        child: Center(
          child: Hero(
            tag: widget.imageUrl,
            child: InteractiveViewer(
              transformationController: _transformCtrl,
              minScale: 0.8,
              maxScale: 5.0,
              onInteractionEnd: (details) {
                // Cập nhật trạng thái zoom
                final scale = _transformCtrl.value.getMaxScaleOnAxis();
                setState(() => _isZoomed = scale > 1.05);
              },
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                              : null,
                          color: _AgriColors.leafLight,
                          strokeWidth: 2,
                        ),
                        const SizedBox(height: 12),
                        const Text('Đang tải ảnh…',
                            style: TextStyle(color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.broken_image_outlined,
                        color: Colors.white38, size: 64),
                    SizedBox(height: 12),
                    Text('Không tải được ảnh',
                        style: TextStyle(color: Colors.white38)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),

      // Hint bar phía dưới
      bottomNavigationBar: AnimatedOpacity(
        opacity: _isZoomed ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.touch_app_rounded, color: Colors.white38, size: 16),
                SizedBox(width: 6),
                Text('Chạm 2 lần để phóng to • Vuốt xuống để đóng',
                    style: TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}