### Kế hoạch Refactor Giao diện Trang chủ (Home Screen) - Glassmorphism

Tôi sẽ thực hiện refactor toàn bộ các thành phần còn lại của màn hình Home để đồng bộ với phong cách Glassmorphism vừa áp dụng cho `WelcomeCard` và `ToolGrid`.

#### 1. Mục tiêu
*   Đồng bộ ngôn ngữ thiết kế: Frosted Glass (Kính mờ), Gradient, Depth (Chiều sâu).
*   Tối ưu trải nghiệm cuộn và tương tác.
*   Làm nổi bật các phần tử quan trọng (Header, History).

#### 2. Chi tiết thực hiện

**A. `history_list.dart` (Danh sách gần đây)**
*   **Hiện tại**: Card đơn giản, bóng đổ phẳng.
*   **Nâng cấp**:
    *   Chuyển mỗi item thành một **Glass Card** (nền trong suốt, viền sáng nhẹ).
    *   Thay đổi icon file thành dạng gradient trên nền kính tối (Dark Glass).
    *   Hiệu ứng `Tap` sẽ làm card sáng lên nhẹ.
    *   Trạng thái "Trống" (Empty State) sẽ dùng icon 3D/Glass mờ ảo.

**B. `app_header.dart` (Thanh tiêu đề)**
*   **Hiện tại**: SliverAppBar với gradient phẳng.
*   **Nâng cấp**:
    *   Giữ lại `SliverAppBar` nhưng thêm lớp `BackdropFilter` để nội dung bên dưới khi cuộn lên sẽ bị mờ đi (Frosted Glass Header).
    *   Tăng kích thước avatar/profile và icon settings.
    *   Làm icon VIP Crown trông cao cấp hơn (Gold Gradient + Glow).

**C. `home_widgets.dart` (Tiêu đề Section)**
*   **Nâng cấp `SectionTitle`**:
    *   Bỏ thanh dọc đơn điệu. Thay bằng chấm tròn **Glowing Dot** hoặc icon nhỏ.
    *   Font chữ tiêu đề đậm hơn, màu sắc tương phản tốt trên nền Glass.

**D. `home_screen.dart` (Background & Layout)**
*   **Background**: Điều chỉnh Gradient nền tổng thể để nó "đậm đà" hơn một chút, giúp hiệu ứng Glass của các card bên trên nổi bật hơn. (Glass cần background có chi tiết để thấy rõ hiệu ứng mờ).

#### 3. Các bước triển khai
1.  **Bước 1**: Cập nhật `home_widgets.dart` (SectionTitle, Loading).
2.  **Bước 2**: Refactor `history_list.dart` sang Glassmorphism.
3.  **Bước 3**: Cập nhật `app_header.dart` với hiệu ứng Blur khi cuộn.
4.  **Bước 4**: Tinh chỉnh `home_screen.dart` (Background gradient).

Bạn có đồng ý với kế hoạch này không? Nếu có, tôi sẽ bắt đầu ngay từ Bước 1.
