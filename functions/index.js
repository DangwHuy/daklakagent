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