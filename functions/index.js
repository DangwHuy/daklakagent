const functions = require("firebase-functions/v1"); // <-- ĐÃ SỬA DÒNG NÀY THÊM /v1
const admin = require("firebase-admin");

// Khởi tạo Firebase Admin
admin.initializeApp();

// Lắng nghe sự kiện TẠO MỚI trong bảng 'appointments'
exports.sendNotificationOnNewAppointment = functions.firestore
  .document('appointments/{appointmentId}')
  .onCreate(async (snap, context) => {

    // Lấy dữ liệu của lịch hẹn vừa được tạo
    const appointmentData = snap.data();
    const expertId = appointmentData.expertId;
    const farmerName = appointmentData.farmerName || "Một nông dân";

    try {
      // 1. Vào bảng 'users' tìm chuyên gia bằng expertId
      const expertDoc = await admin.firestore().collection('users').doc(expertId).get();
      const expertData = expertDoc.data();

      // Nếu chuyên gia không tồn tại hoặc chưa có fcmToken thì dừng lại
      if (!expertData || !expertData.fcmToken) {
        console.log(`Chuyên gia ${expertId} chưa có fcmToken.`);
        return null;
      }

      // 2. Soạn nội dung thông báo
      const message = {
        notification: {
          title: 'Có lịch hẹn mới! 📅',
          body: `Bà con ${farmerName} vừa gửi yêu cầu đặt lịch tư vấn với bạn.`,
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'high_importance_channel', // Khớp với Manifest
          },
        },
        token: expertData.fcmToken, // Địa chỉ máy của chuyên gia
      };

      // 3. Bắn thông báo xuống điện thoại
      const response = await admin.messaging().send(message);
      console.log("Đã gửi thông báo thành công:", response);

      return null;

    } catch (error) {
      console.error("Lỗi khi gửi thông báo:", error);
      return null;
    }
  });

// Lắng nghe sự kiện CẬP NHẬT trong bảng 'expert_requests'
exports.sendNotificationOnExpertRequestUpdate = functions.firestore
  .document('expert_requests/{requestId}')
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();

    // Lấy trạng thái trước và sau khi update
    const previousStatus = beforeData.status;
    const currentStatus = afterData.status;

    // Chỉ thực hiện khi có sự thay đổi trạng thái
    if (previousStatus === currentStatus) {
      return null;
    }

    const userId = afterData.userId;
    if (!userId) return null;

    let title = "";
    let body = "";

    if (currentStatus === "approved" || currentStatus === "accepted") {
      title = "Trở thành chuyên gia thành công! 🎉";
      body = "Xin chúc mừng! Yêu cầu đăng ký chuyên gia của bạn đã được phê duyệt. Trải nghiệm ngay các tính năng cho chuyên gia.";
      
      try {
        // Tự động nâng cấp role của người dùng thành 'expert'
        await admin.firestore().collection('users').doc(userId).update({
          role: 'expert'
        });
      } catch (err) {
        console.error("Lỗi khi cập nhật role cho user:", err);
      }
    } else if (currentStatus === "rejected") {
      title = "Hồ sơ chuyên gia cần xem xét lại 😔";
      body = "Rất tiếc! Yêu cầu đăng ký chuyên gia của bạn chưa được duyệt. Vui lòng cập nhật lại hồ sơ năng lực hoặc liên hệ QTV.";
    } else {
       // Trạng thái khác thì bỏ qua
       return null;
    }

    try {
      // 1. Lưu thông báo vào bảng 'notifications' để hiện ở quả chuông (NotificationScreen)
      await admin.firestore().collection('notifications').add({
        receiverId: userId,
        title: title,
        body: body,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        type: 'expert_registration'
      });

      // 2. Tùy chọn: Bắn cả thông báo push về điện thoại nếu có token
      const userDoc = await admin.firestore().collection('users').doc(userId).get();
      const userData = userDoc.data();
      
      if (userData && userData.fcmToken) {
        const message = {
          notification: {
            title: title,
            body: body,
          },
          android: {
            priority: 'high',
            notification: {
              channelId: 'high_importance_channel',
            },
          },
          token: userData.fcmToken,
        };
        await admin.messaging().send(message);
        console.log("Đã gửi Push Notification báo kết quả chuyên gia.");
      }

      return null;
    } catch (error) {
      console.error("Lỗi khi gửi thông báo kết quả duyệt chuyên gia:", error);
      return null;
    }
  });