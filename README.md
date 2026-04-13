daklakagent

A new Flutter project for Daklak Agricultural Agent.

📄 TÀI LIỆU KỸ THUẬT TOÀN DIỆN DỰ ÁN DAKLAKAGENT

Tài liệu này cung cấp cái nhìn tổng thể và chi tiết về hệ thống "Agent Nông Nghiệp Đắk Lắk" (DaklakAgent), phục vụ cho việc báo cáo, phân tích sâu, bàn giao và đào tạo.

1. TỔNG QUAN DỰ ÁN

Tên dự án: Agent Nông Nghiệp Đắk Lắk (DaklakAgent).

Mục tiêu: Xây dựng một trợ lý ảo thông minh dựa trên AI để hỗ trợ nông dân Đắk Lắk (đặc biệt là vùng trồng sầu riêng và cà phê) trong việc theo dõi thời tiết, chẩn đoán - quản lý dịch bệnh và kết nối chuyên gia.

Bài toán giải quyết: Giải quyết tình trạng thiếu hụt thông tin kỹ thuật chính xác theo thời gian thực và khó khăn trong việc kết nối trực tiếp với các chuyên gia đầu ngành trong lĩnh vực nông nghiệp.

Nhóm thực hiện: Sinh viên Khoa Công nghệ Thông tin - Trường ĐH Nguyễn Tất Thành. (Cập nhật bởi Đăng Huy).

2. KIẾN TRÚC HỆ THỐNG & CÔNG NGHỆ

Dự án được xây dựng theo mô hình Cloud-Native và Microservices tinh gọn, đảm bảo hiệu năng và khả năng mở rộng.

2.1. Công nghệ sử dụng (Tech Stack)

Frontend: Flutter (Android/iOS) - Giao diện đồng nhất, Material 3, fl_chart, hiệu năng mượt mà (60 FPS).

Backend Cloud (Serverless): Firebase Core (Authentication, NoSQL Firestore, Cloud Storage, Cloud Messaging - FCM).

Backend AI (Python): FastAPI, LangChain (RAG Framework), Transformers (Vision AI/YOLOv9).

Bảo mật & Triển khai: Xác thực Google Auth, Firebase Security Rules, Ngrok Secure Tunneling (môi trường test).

2.2. Kiến trúc tổng thể & Phân rã chức năng

graph TD
    User((Người dùng)) --> FlutterApp[Flutter Mobile App]
    
    subgraph Google_Cloud_Firebase
        FlutterApp --> Auth[Firebase Auth]
        FlutterApp --> Firestore[(Cloud Firestore)]
        FlutterApp --> Storage[Firebase Storage]
        FlutterApp --> FCM[FCM Notifications]
    end
    
    subgraph AI_Backend_Python
        FlutterApp --> FastAPI[FastAPI Server]
        FastAPI --> RAG[RAG Engine]
        FastAPI --> Vision[Vision AI Service]
    end


Sơ đồ Tương tác theo Vai trò (User Roles Interaction):

flowchart LR
    Farmer((Farmer))
    Expert((Expert))
    AI((AI Backend))
    Firebase((Firebase))

    %% Farmer
    Farmer --> F1[Đăng nhập / Đăng ký]
    Farmer --> F2[Xem thời tiết thông minh]
    Farmer --> F3[Hỏi đáp AI Text/Voice]
    Farmer --> F4[Chẩn đoán bệnh bằng ảnh]
    Farmer --> F5[Tìm & đặt lịch chuyên gia]
    Farmer --> F6[Chat / Video Call]
    Farmer --> F7[Mua hàng / Voucher]
    Farmer --> F8[Đăng bài cộng đồng]

    %% Expert
    Expert --> E1[Đăng ký hồ sơ chuyên gia]
    Expert --> E2[Bật/Tắt Online]
    Expert --> E3[Quản lý lịch hẹn]
    Expert --> E4[Tư vấn khách hàng]
    Expert --> E5[Xem thống kê doanh thu]

    %% System interactions
    F3 --> AI
    F4 --> AI

    F1 --> Firebase
    F5 --> Firebase
    F6 --> Firebase
    F8 --> Firebase


3. MÔ HÌNH DỮ LIỆU (DATABASE)

Dữ liệu được quản lý đồng nhất trên NoSQL Firebase (Firestore) với cấu trúc tối ưu cho Realtime.

3.1. Cấu trúc Collection chính

users: Lưu thông tin cơ bản, vai trò (farmer hoặc expert), trạng thái online, đánh giá và doanh thu (đối với chuyên gia).

appointments: Quản lý ca tư vấn, trạng thái lịch hẹn (pending, confirmed, completed, cancelled).

posts: Lưu trữ bài viết, hình ảnh, hashtag diễn đàn cộng đồng.

notifications: Hệ thống thông báo đẩy (FCM) đồng bộ realtime.

3.2. Sơ đồ Lớp Dữ liệu (Class Diagram)

classDiagram
    class User {
        uid
        email
        role
        isOnline
    }

    class Farmer {
        ai_history
        cart
    }

    class Expert {
        rating
        radarStats
        availableSlots
    }

    class Appointment {
        id
        farmerId
        expertId
        status
        description
        images
    }

    class Post {
        postId
        authorId
        content
        hashtags
    }

    class ChatRoom {
        id
        participants
    }

    class Message {
        senderId
        content
        timestamp
    }

    User <|-- Farmer
    User <|-- Expert

    Farmer --> Appointment
    Expert --> Appointment

    Appointment --> ChatRoom
    ChatRoom --> Message

    Farmer --> Post


4. LUỒNG NGHIỆP VỤ CỐT LÕI (USER FLOWS)

4.1. Luồng Xác thực và Điều hướng phân quyền

sequenceDiagram
    participant User
    participant UI
    participant Auth
    participant Firestore
    participant RoleCheck

    User->>UI: Mở app
    UI->>Auth: Đăng nhập Google

    Auth-->>UI: UserCredential(uid)

    UI->>RoleCheck: Kiểm tra role
    RoleCheck->>Firestore: Get user(uid)

    Firestore-->>RoleCheck: role

    alt Farmer
        RoleCheck-->>UI: HomeScreen
        UI->>UI: Load Weather + AI Bot
    else Expert
        RoleCheck-->>UI: ExpertHomeScreen
        UI->>UI: Load Dashboard + Notifications
    end


4.2. Vòng đời của Trạng thái & Lịch hẹn (State Machine)

stateDiagram-v2
    %% Presence
    [*] --> Offline
    Offline --> Online : Toggle
    Online --> Offline : Toggle

    %% Appointment
    state Booking {
        [*] --> Draft
        Draft --> Pending : Submit

        Pending --> Cancelled : Reject
        Pending --> Confirmed : Accept

        Confirmed --> InProgress
        InProgress --> Completed

        Completed --> Rated
        Rated --> [*]
    }


5. TÍNH NĂNG CHI TIẾT & HƯỐNG DẪN SỬ DỤNG

5.1. Dành cho Nhà nông (Farmer)

Được cấp quyền mặc định khi đăng ký mới.

Trợ lý AI (Draggable AI Bot): Trợ lý robot bay luôn hiển thị trên màn hình. Hỗ trợ hỏi đáp kỹ thuật (VD: "Xử lý sầu riêng rụng bông?").

Thời tiết Thông minh (Smart Weather): Cảnh báo nguy cơ Lũ lụt, Nấm bệnh, Stress nhiệt (%) và đề xuất hành động (VD: Ngưng bón đạm).

Tiện ích 4.0: Lịch tưới tự động, tra cứu giá nông sản Đắk Lắk, ghi chép nhật ký nông nghiệp.

Chẩn đoán bệnh & Kết nối Chuyên gia: Xem chi tiết luồng tích hợp dưới đây.

Luồng nghiệp vụ: Chẩn đoán bằng ảnh -> Tự xử lý hoặc Đặt lịch Chuyên gia

flowchart TD
    A[Bắt đầu] --> B[Chụp ảnh lá bệnh]
    B --> C[Encode Base64]
    C --> D[Gửi API FastAPI]

    D --> E[YOLOv9 detect]
    E --> F[Gemini sinh phác đồ]

    F --> G[Hiển thị kết quả + TTS Voice]

    G --> H{Mức độ bệnh}

    H -->|Nhẹ| I[Tự xử lý]
    I --> J[Ghi nhật ký]
    J --> Z[Kết thúc]

    H -->|Nặng| K[Bấm hỏi chuyên gia]
    K --> L[Chuyển sang màn hình FindExpert]

    L --> M[Chọn expert đang Online]
    M --> N[Gửi booking yêu cầu]

    N --> O[Lưu Firebase + Bắn FCM]
    O --> P[Expert nhận yêu cầu]

    P --> Q{Phản hồi từ Expert}

    Q -->|Từ chối| R[Trạng thái Cancelled]
    R --> Z

    Q -->|Chấp nhận| S[Chat / Video Call trực tiếp]
    S --> T[Hoàn thành ca tư vấn]

    T --> U[Farmer đánh giá]
    U --> Z


5.2. Dành cho Chuyên gia (Expert)

Nhà nông cần nộp CV/Portfolio (PDF/Doc) qua app. Ban quản trị xét duyệt sẽ chuyển quyền tài khoản từ farmer sang expert.

Expert Dashboard:

Quản lý lịch hẹn (Chờ duyệt, Đã nhận).

Bật/Tắt trạng thái Online để nhận cuộc gọi/chat ngay lập tức.

Cập nhật doanh thu và xác nhận hình ảnh sau khi hoàn thành tư vấn.

Báo cáo & Phân tích Radar: Biểu đồ Radar đánh giá 5 chỉ số: Khối lượng, Thành công, Doanh thu, Khách quen, Đánh giá.

5.3. Tính năng Cộng đồng & Tương tác

Diễn đàn: Nông dân và Chuyên gia đăng bài kèm ảnh vườn. Sử dụng hashtag (VD: #saurieng, #benhla) để phân loại. Bình luận trực tiếp.

Hệ thống Push Notifications (FCM): Thông báo realtime cho booking mới, tin nhắn, và cảnh báo thiên tai khẩn cấp.

6. HỆ THỐNG TRÍ TUỆ NHÂN TẠO (AI CORE)

Sản phẩm tích hợp hàm lượng AI cao, chạy độc lập trên Python Backend:

Knowledge Consultant (RAG System): Ứng dụng kỹ thuật RAG (Retrieval-Augmented Generation) đảm bảo AI trả lời dựa trên kho tri thức nông nghiệp chuẩn của Đắk Lắk, hạn chế ảo giác (hallucination).

Vision AI: Tích hợp YOLOv9 và LLM Vision để nhận diện sâu bệnh qua hình ảnh thực tế của lá/trái.

Smart Weather AI Analysis: Xử lý dữ liệu thô (nhiệt độ, độ ẩm) thành tỷ lệ rủi ro nấm bệnh/stress nhiệt.

Expert Analytics AI: Đọc các chỉ số KPI của chuyên gia để tự động sinh ra các lời khuyên phát triển sự nghiệp cá nhân hóa.

7. CẤU TRÚC SOURCE CODE & API

7.1. Cấu trúc thư mục Flutter (features-based)

Dự án được phân chia module rõ ràng để dễ bảo trì:

lib/features/auth: Quản lý xác thực và phân quyền Role-based.

lib/features/home: Điều phối giao diện chính và tiện ích.

lib/features/ai: Giao diện Chatbot, Voice và xử lý API LLM.

lib/features/weather: Phân tích thời tiết và cảnh báo.

lib/features/expert: Logic dashboard, thống kê, radar chart cho chuyên gia.

lib/features/community: Quản lý Feed, Posts, Hashtags.

7.2. Danh sách API Backend (FastAPI)

Giao tiếp qua HTTP/HTTPS (sử dụng Ngrok cho môi trường Dev):

POST /chat: Giao tiếp với RAG LLM.

POST /analyze-disease: Gửi Base64 Image, nhận về phác đồ điều trị.

GET /api/phan-tich-sau-rieng: Nhận chỉ số cảnh báo rủi ro môi trường.

GET /api/expert-insights/<uid>: Lấy lời khuyên AI tự động cho chuyên gia.

8. GIAO DIỆN (UI/UX) & TRẠNG THÁI HIỆN TẠI

Phong cách thiết kế: Glassmorphism (hiệu ứng kính mờ), sử dụng tone màu Gradient Xanh lục - Vàng đất làm chủ đạo, thân thiện với thiên nhiên.

Trải nghiệm (UX): Tối giản hóa thao tác cho nông dân (nút to, hỗ trợ giọng nói TTS), tối ưu hóa dữ liệu số cho chuyên gia (biểu đồ trực quan).

Trạng thái dự án: Đã hoàn thiện UI/UX, tích hợp thành công Firebase và luồng AI Backend cơ bản. Sẵn sàng chạy môi trường test.

9. HƯỚNG PHÁT TRIỂN TƯƠNG LAI

Tích hợp API phần cứng từ các công ty IoT (Cảm biến độ ẩm đất, trạm thời tiết mini) trực tiếp vào app.

Hoàn thiện tính năng xuất báo cáo chuyên sâu (Excel/PDF) cho chuyên gia.

Mở rộng kết nối Ví điện tử để thanh toán phí tư vấn chuyên gia trực tiếp trên nền tảng.