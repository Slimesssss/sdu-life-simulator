# GDD — SDU Life Simulator

*Game mô phỏng đời sống sinh viên. Cùng thể loại với Stardew Valley nhưng lấy **thời khoá biểu đại học** làm trục gameplay thay vì trồng trọt.*

| Hạng mục | Giá trị |
|---|---|
| Thể loại | Life sim / time management, 2D top-down |
| Engine | Godot 4.7 (Forward+), GDScript |
| Nền tảng | Windows trước, sau đó Web/Steam |
| Độ phân giải thiết kế | 1280×720, pixel art 16px, camera zoom 2× |
| Chế độ | Single player |
| Thời lượng 1 học kỳ (mục tiêu) | 15 tuần game ≈ 6–8 giờ chơi |

---

## 1. Trụ cột thiết kế

1. **Thời gian là tài nguyên khan hiếm nhất; tiền là áp lực vừa phải khiến người chơi phải đổi thời gian lấy tiền.** Một ca làm thêm = 4 tiếng game = đúng một buổi học. Đó là chỗ "thiếu giờ" gặp "thiếu tiền", và là quyết định thú vị nhất của game.
2. **Sự đánh đổi học – sống.** Học nhiều thì GPA cao nhưng tinh thần kiệt; chơi nhiều thì vui nhưng trượt môn.
3. **Trường học là một thế giới sống.** Giảng viên, bạn cùng phòng, CLB có lịch sinh hoạt riêng, không đứng chờ người chơi.
4. **Không thua đột ngột.** Hết học kỳ mới tổng kết; thất bại là "học lại / nợ môn", không phải game over.

---

## 2. Vòng lặp gameplay

**Vòng ngày** (6:30 → 24:00, ngủ để sang ngày)
> Thức dậy (năng lượng hồi theo giấc ngủ) → đi học / tự học / làm thêm → ăn uống → quan hệ, CLB → về phòng → ngủ.

**Vòng tuần**
> 5 ngày có tiết theo thời khoá biểu → cuối tuần rảnh: làm thêm, CLB, sự kiện trường, deadline bài tập.

**Vòng học kỳ** (15 tuần)
> Tuần 1–8 học bình thường → tuần 9–14 dồn bài tập, thi giữa kỳ → tuần 15 thi cuối kỳ → **bảng tổng kết GPA, tiền, quan hệ** → học kỳ sau (khó hơn, nhiều môn hơn).

---

## 3. Hệ thống

### 3.1 Thời gian (`GameClock`)
- 1 giây thực = 6 phút game (tinh chỉnh được, `minutes_per_real_second`).
- **Quy tắc trôi thời gian khi di chuyển vs tương tác:**
  - **Tương tác hoạt động**: Nhảy thời gian theo khối cố định (`advance_minutes()` như 60' học, 30' ăn, 240' làm thêm).
  - **Di chuyển ngoài trời / trong nhà**: Đồng hồ game trôi theo thời gian thực (1 giây thực = 6 phút game). Tốc độ di chuyển nhân vật (~120–150 px/s, chuẩn 135 px/s) được cân chỉnh để các **chặng ngắn thường nhật** (như KTX tới Căng tin, KTX tới Nhà A: ~150–250 px) tốn khoảng **10–15 phút game**. Đi ngang xuyên suốt toàn bộ bản đồ trường (1024 px) mất khoảng **40–45 phút game**, tạo cảm giác áp lực thời gian chạy tới lớp trước giờ điểm danh mà không làm vỡ cân bằng looptest.
  - **Menu / Điện thoại / Hội thoại**: Đồng hồ **tạm dừng hoàn toàn** (`GameClock.paused = true`).
- Mốc thời gian: phút → giờ → ngày → thứ (Thứ 2 … Chủ nhật) → tuần → học kỳ.
- Hành động **tốn thời gian**: đi học 90 phút, tự học 60 phút, làm thêm 240 phút, ngủ tới sáng.
- Sự kiện neo theo giờ: lớp học bắt đầu 7:30, căng tin đông 11:30, ký túc xá giới nghiêm 23:00.

### 3.2 Chỉ số người chơi (`PlayerStats`)

**7 chỉ số**, chia 2 nhóm. Giá trị khởi đầu được lưu trong `BalanceConfig`:

*Nhóm hao mòn hằng ngày — biến động liên tục, hồi khi ngủ/ăn:*

| Chỉ số | Khoảng | Khởi đầu | Ghi chú |
|---|---|---|---|
| **Sức lực** | 0–100 | 100.0 | Tiêu hao mỗi hành động. Hết thì buộc phải ngủ. Tốc độ hồi phụ thuộc **mức thoải mái của KTX** |
| **Sức khỏe** | 0–100 | 80.0 | Trạng thái sinh tồn hằng ngày. Tụt khi thức khuya, ăn kém, ốm. Dưới 30 thì hành động kém hiệu quả. **Không có sàn, không gắn trực tiếp mốc perk 50/100.** |
| **Tinh thần** | 0–100 | 80.0 | Trạng thái tâm lý hằng ngày. Tụt khi stress, thi trượt, nợ tiền. Tăng khi CLB, gặp bạn. **Không có sàn, không gắn trực tiếp mốc perk 50/100.** |

*Nhóm tích luỹ dài hạn — có mốc, có ngưỡng sàn bảo vệ:*

| Chỉ số | Khoảng | Khởi đầu | Ghi chú |
|---|---|---|---|
| **Trí tuệ** | 0–100 | 20.0 | Tăng chậm theo cơ chế exp suy giảm (diminishing returns, ngân sách 8–12 điểm/kỳ, cày 4 năm để đạt 100). Ảnh hưởng tốc độ học **mọi** môn |
| **Học lực** | 0–100 | 30.0 | Kết quả học hiện tại. Lên khi dự giờ, làm bài tập lớn. Có cơ chế mai một nếu bỏ học > 2 ngày |
| **Kĩ năng chuyên ngành** | 0–100 | 10.0 | Tăng ở xưởng thực hành và bài tập lớn. Quyết định lương việc làm IT phòng server |
| **Tiền** | VND | 5.000.000 | Học bổng, làm thêm, trợ cấp gia đình; chi ăn ở, **học phí**, tài liệu |

### 3.2b Bốn loại "điểm" của nhà trường (theo hệ đại học Việt Nam)

| Tên | Xem ở đâu | Ý nghĩa |
|---|---|---|
| **Điểm học tập** | Điện thoại | Điểm từng môn |
| **Điểm rèn luyện** | Điện thoại | 0–100 mỗi học kỳ. Tăng khi tham gia CLB, sự kiện trường; giảm khi vắng, đi trễ, vi phạm. **Dưới 50 thì không được xét tốt nghiệp** |
| **Điểm tích luỹ** | Điện thoại | Số tín chỉ đã qua. Đủ 120 để tốt nghiệp |
| **Điểm trung bình** | Điện thoại | GPA có trọng số tín chỉ, cập nhật khi có điểm môn |

### 3.2c Mốc chỉ số & nhánh kỹ năng (kiểu Stardew Valley)

| Mốc | Nhận được |
|---|---|
| 10, 20, 30, 40, 60, 70, 80, 90 | **Thưởng nhỏ tự động** — +5% hiệu quả hành động liên quan |
| **50** | **Chọn 1 trong 2 nhánh** — giống Stardew chọn nghề ở level 5 |
| **100** | **Chọn 1 trong 2 bậc thầy** trong nhánh đã chọn — giống level 10 |

Ví dụ nhánh:

| Chỉ số | Nhánh ở mốc 50 | Bậc thầy ở mốc 100 |
|---|---|---|
| **Trí tuệ** | *Mọt sách* (học nhanh hơn) / *Thực chiến* (thi tốt hơn) | *Học giả* (+50% điểm bài tập) / *Chiến thần phòng thi* (+50% điểm thi) |
| **Học lực** | *Chăm chỉ* (điểm rèn luyện cao) / *Tài năng* (GPA cao) | *Thủ khoa* / *Sinh viên 5 tốt* |
| **Kĩ năng chuyên ngành** | *Thợ giỏi* (làm thêm lương cao) / *Nhà nghiên cứu* (bài tập lớn tốt hơn) | *Kỹ sư trưởng* / *Giảng viên tập sự* |
| **Thể chất (Fitness EXP)** | *Dẻo dai* (sức lực tụt chậm) / *Đề kháng* (ít ốm) | *Vận động viên* / *Sống lành mạnh* |
| **Bản lĩnh (Resilience EXP)** | *Hướng ngoại* (tăng tim nhanh hơn) / *Hướng nội* (stress tụt chậm) | *Linh hồn của CLB* / *Người bình tĩnh* |

**Chọn rồi KHÔNG đổi được.** Đây là điểm mấu chốt: nó khiến mỗi lượt chơi là một nhân vật khác nhau, thay vì ai cũng max hết mọi chỉ số.

> ⚠️ **Quy tắc phân biệt Trạng thái ngắn hạn vs EXP Mốc dài hạn (Khắc phục mâu thuẫn Sức khỏe & Tinh thần):**
> - Thanh **Sức khỏe** và **Tinh thần** (0–100) trên HUD là **thanh trạng thái sinh tồn ngắn hạn** (khởi đầu 80.0, biến động theo ngày, không có sàn).
> - Hai cây nhánh kỹ năng tương ứng (**Thể chất** và **Bản lĩnh**) được tính theo **điểm kinh nghiệm tích luỹ dài hạn (Lifestyle EXP)** bắt đầu từ 0/10, tăng dần qua các hành động rèn luyện lâu dài (chạy bộ, tập gym, ăn đúng bữa, sinh hoạt CLB, vượt qua kỳ thi).
> - Điều này loại bỏ hoàn toàn nghịch lý người chơi vừa vào game đã vượt mốc 50 và chạm max mốc 100 ngay trong tuần đầu tiên chỉ nhờ ngủ đủ giấc.
> - **Sàn** (mục 3.2d) chỉ áp cho **các chỉ số kỹ năng / exp tích lũy** (trí tuệ · học lực · kĩ năng chuyên ngành · thể chất · bản lĩnh). Hai thanh trạng thái Sức khỏe và Tinh thần **tuyệt đối KHÔNG có sàn** để người chơi vẫn phải đối mặt với nguy cơ ốm/kiệt sức nếu bỏ bê.

### 3.2d Ngưỡng sàn — không mất tiến độ

Khi một chỉ số đã chạm mốc 10, nó **không bao giờ tụt xuống dưới mốc đó nữa**. Đã đạt 40 trí tuệ thì thức khuya, bỏ học thế nào trí tuệ cũng không xuống dưới 40.

**Áp dụng cho 3 chỉ số kỹ năng:** trí tuệ · học lực · kĩ năng chuyên ngành.

**KHÔNG áp cho:**
- **Sức lực** — đây là thanh tiêu hao **trong ngày**, hồi mỗi sáng, không phải chỉ số tích luỹ. Nếu có sàn thì không bao giờ hết sức để phải đi ngủ, cả vòng lặp ngày/đêm sụp đổ.
- **Sức khỏe và tinh thần** — để hai chỉ số này tụt tự do xuống 0. Có sàn thì sau khi đạt mốc cao bạn không bao giờ ốm nặng hay trầm cảm được nữa, và "thức khuya hại sức khỏe" thành lời nói suông.
- **Tiền** — không có mốc, không có sàn.

> ⚠️ **Chú ý khi code:** `apply_effects()` phải kẹp theo **sàn động** (`clampf(value, floor_of_stat, 100)`), và Dictionary `highest_milestone` **bắt buộc phải vào file save** — quên là luật sàn mất sạch sau khi load game. Chi tiết + đoạn code ở [TODO.md](../TODO.md) mục **H**.

### 3.2e Cơ chế phao cứu sinh chống bế tắc (Anti-Death Spiral / Bailout)

Game tuân thủ nghiêm ngặt Trụ cột 4: **Không thua đột ngột / Không Game Over ngang chừng**. Để tránh việc người chơi hết sạch tiền $\rightarrow$ nhịn ăn $\rightarrow$ kiệt sức $\rightarrow$ không đi làm nổi $\rightarrow$ rơi vào vòng xoáy bế tắc (soft-lock), game trang bị 3 tầng phao cứu sinh:
1. **Mì tôm sinh viên (`eat_instant_noodle`):** Nấu tại KTX với giá 10.000đ (`BalanceConfig.instant_noodle_cost`). Cứu đói khẩn cấp khi không đủ tiền ăn căng tin (hồi ít sức lực, trừ nhẹ sức khỏe nếu lạm dụng, nhưng triệt tiêu hình phạt đói nặng -15 Sức khỏe/-10 Tinh thần).
2. **Cứu trợ khẩn cấp từ gia đình (Bailout):** Khi số dư ví = 0đ và kiệt sức/đói, sinh viên có thể gọi điện về nhà xin ứng tiền khẩn cấp: nhận ngay 500.000đ nhưng bị mắng (-20 Tinh thần, gia tăng áp lực tâm lý).
3. **Lao động nhật trình khẩn cấp:** Làm tạp vụ tại Căng tin hoặc dọn dẹp vệ sinh KTX nhận tiền mặt tươi (30.000–50.000đ/giờ) mà không đòi hỏi thể lực cao, đủ mua 1–2 bữa ăn cứu đói.

### 3.3 Hoạt động (`Activity` resource)
Mọi hành động trong game là một `Activity`: `id`, tên, số phút, sức lực tiêu hao, tiền, hiệu ứng chỉ số. Thêm nội dung = **thêm file `.tres`**, không sửa code.

Ví dụ có sẵn: `study` (Tự học ở thư viện), `attend_lecture` (Dự giờ), `sleep` (Ngủ), `eat` (Ăn căng tin), `part_time` (Làm thêm), `club` (Sinh hoạt CLB), `exercise` (Chạy bộ), `gym` (Tập gym — mở sau khi cổng trường mở).

**Hoạt động đánh đổi — tăng cái này phải giảm cái kia:**

| Hoạt động | Được | Mất |
|---|---|---|
| Ngủ sớm | +tinh thần, +sức khỏe | mất buổi tối để học |
| **Thức khuya** | +học lực, +trí tuệ | −sức khỏe, −tinh thần, sáng hôm sau −sức lực |
| **Tập gym** (90 phút) | +sức khỏe | −sức lực nhiều, −thời gian |
| Nhịn ăn để tiết kiệm | +tiền | −sức khỏe, −tinh thần |

Không có hoạt động đánh đổi thì người chơi chỉ cần bấm nút tối ưu, không cần suy nghĩ. Đây là trái tim của gameplay.

### 3.4 Thời khoá biểu, môn học & điểm

- `Course`: mã môn, tên, số tín chỉ, giờ học cố định trong tuần, giảng viên, **`required_minutes`** (số phút tự học cần để đạt điểm tối đa).
- `Schedule`: ánh xạ (thứ, giờ) → môn học. Đến giờ mà không có mặt = **vắng**; quá số buổi thì **cấm thi**.
- **Thang điểm 10** (trượt = dưới 4/10). Điểm trung bình hiển thị cả hệ 10 và hệ 4.

#### Phân vai chỉ số — hết chồng chéo Trí tuệ / Học lực

| Chỉ số | Vai trò duy nhất |
|---|---|
| **Trí tuệ** | Hệ số nhân **hiệu quả giờ học** (học nhanh hay chậm) |
| **Học lực** | **Nền kiến thức** — cộng thẳng vào điểm, kể cả khi học ít |
| **Sức khỏe, Tinh thần** | Hệ số **phong độ** lúc thi |
| **Chuyên cần** (theo môn) | Tỉ lệ buổi có mặt, 0..1 |

Trí tuệ quyết định **học tốn bao nhiêu giờ**; Học lực quyết định **bắt đầu từ mức nào**. Hai cái không còn làm cùng một việc.

#### Công thức một bài thi / bài tập

```
effective_minutes = study_minutes_for_course * (1.0 + 0.5 * tri_tue / 100.0)
prep              = clampf(effective_minutes / required_minutes, 0.0, 1.0)

raw   = 0.45 * prep
      + 0.35 * minigame_score          # 0..1 từ Minigame.play()
      + 0.10 * (hoc_luc / 100.0)
      + 0.10 * attendance              # 0..1

form  = 0.8 + 0.2 * (minf(suc_khoe, tinh_than) / 100.0)   # 0.8..1.0

score = snappedf(10.0 * clampf(raw, 0.0, 1.0) * form, 0.5)
```

- `required_minutes` số phút tự học cần để đạt điểm chuẩn bị tối đa:
  - **Lát cắt 1 tuần (MVP M0 - 1 bài thi 1 môn như it101):** chuẩn hóa **3600** phút (đã cân bằng qua `--looptest` để kiểm tra độ căng thẳng giữa học và làm).
  - **Kế hoạch cả học kỳ (M1 trở đi - 15 tuần):** Tổng ngân sách trung bình 3600 phút/môn được phân bổ thành **3 giai đoạn độc lập** tương ứng 3 cột điểm:
    - **Bài tập lớn / Thường xuyên (Tuần 1–6):** Yêu cầu 1000 phút.
    - **Thi giữa kỳ (Tuần 7–10):** Yêu cầu 1200 phút (tính số phút tự học trong giai đoạn này).
    - **Thi cuối kỳ (Tuần 11–15):** Yêu cầu 1400 phút (tính số phút tự học trong giai đoạn này).
    - *Quy tắc:* Khi hoàn thành từng kỳ thi, điểm được khóa lại (`lock_score`), tránh việc cày dồn giờ học ở tuần đầu rồi ăn trọn điểm chuẩn bị cho cả học kỳ.
- **Tốc độ tăng Trí tuệ (Intelligence Growth Budget):**
  - Trí tuệ khởi đầu 20.0, tăng tối đa **8–12 điểm mỗi học kỳ** để đạt 100 điểm cần hành trình 4 năm (8 kỳ).
  - Áp dụng cơ chế **EXP suy giảm (Diminishing Returns)** khi tự học ở thư viện:
    - Trí tuệ < 40: +0.10 điểm / 60 phút tự học.
    - Trí tuệ 40–70: +0.05 điểm / 60 phút.
    - Trí tuệ > 70: +0.02 điểm / 60 phút (muốn bứt phá phải tham gia Nghiên cứu khoa học, đọc sách chuyên khảo, thi Olympic tại Nhà A).
- `snappedf(…, 0.5)` làm tròn 0.5 như bảng điểm Việt Nam.
- **Bỏ học hoàn toàn** (0 phút, minigame 0.8, chuyên cần 1, học lực 30, khoẻ): `0.28 + 0.03 + 0.10 = 0.41` → **~4.1, sát ngưỡng trượt 4.0**. Cố ý: bỏ học thì sống sót mong manh chứ không tự động trượt.
- **Học đủ giờ, thi tốt:** `0.45 + 0.28 + 0.03 + 0.10 = 0.86` → ~8.6 × form. Muốn 9–10 phải thêm Học lực/Trí tuệ, tức phải **tích luỹ qua nhiều kỳ**.
- Điểm môn = `0.3 * bài_tập + 0.3 * giữa_kỳ + 0.4 * cuối_kỳ`.
- Cố ý **không** có hệ số may mắn ngẫu nhiên — ngẫu nhiên đã nằm trong minigame.

#### Ba luật về điểm — luật số 3 là quan trọng nhất

1. **Điểm môn không bao giờ đổi** sau khi đã có. Không có chuyện học thêm rồi điểm tự lên.
2. **Trượt** thì **hè được học lại** để cải thiện.
3. **Điểm học lại tối đa 8/10**, dù thi được 10.

Luật 3 khiến **một môn trượt kéo GPA xuống vĩnh viễn** — không có đường sửa hoàn hảo. Người chơi buộc phải chọn học kỳ nào dồn sức, học kỳ nào chấp nhận hy sinh.

### 3.5 Quan hệ & hội thoại
- Mỗi NPC: lịch sinh hoạt theo giờ, sở thích, điểm thân thiết 0–10.
- Hội thoại bằng **Dialogue Manager**: nhánh lựa chọn, điều kiện dựa trên chỉ số, thân thiết.
- Sự kiện riêng mở khoá theo mốc thân thiết (kiểu heart event của Stardew).

### 3.6 Địa điểm & nhà nhiều tầng
**Nhà A** (T1: thư viện ở giữa + phòng quản trị server · T2+: phòng học lý thuyết) · **Nhà B** (T1–2: xử lý giấy tờ sinh viên · T3+: học môn liên quan + thi trắc nghiệm) · **Xưởng 1–4** (khoa thực hành, bài tập lớn) · **Hội trường** (nhập học, tốt nghiệp, ngày lễ, cuộc thi, hội nghị, đăng ký CLB) · **Căng tin** · **Phòng công tác sinh viên** · **Ký túc xá A/B/C** · **Sân bóng** · **Phòng thể thao** · **Nhà để xe** · **Phòng bảo vệ**.

Mỗi tầng là **một scene riêng**, cầu thang là vật thể tương tác chuyển scene. Bản đồ chi tiết (lưới 64×36 ô, toạ độ từng công trình, code dựng lưới) nằm ở [TODO.md](../TODO.md) mục *BẢN ĐỒ TRƯỜNG SDU*.

### 3.7 Nhà ở & tiền thuê

Cả ba ký túc xá đều **4 người/phòng**. Khác nhau ở **mức sống** — cái này ảnh hưởng trực tiếp tới tốc độ hồi sức lực và tinh thần.

| KTX | Giá/tháng | Mức sống | Hồi sức lực / giấc ngủ | Hồi tinh thần / ngày | Vị trí |
|---|---|---|---|---|---|
| **A** | 1.200.000 đ | Khu giàu | ×1.0 | +8 | Cạnh căng tin và sân bóng |
| **B** | 800.000 đ | Bình thường | ×0.8 | +4 | Giữa trường |
| **C** | 500.000 đ | Khu nghèo | ×0.6 | +1 | Sát KTX B, xa giảng đường nhất |

- Ngày 1 mỗi tháng (28 ngày game) tự trừ tiền thuê. Không đủ → **nợ 1 tuần**; quá hạn thì bị đẩy xuống KTX rẻ hơn.
- Ở KTX C lâu mà ăn uống qua loa thì **sức khỏe tụt** — đây là áp lực thật của sinh viên nghèo, không phải chỉ là con số trang trí.
- Vào phòng **người khác** cần **2–4 tim** tuỳ người; phòng mình vào thẳng. Hệ quan hệ nằm ngay trên bản đồ chứ không giấu trong menu.

### 3.7b Kinh tế (1 tháng = 28 ngày, 1 học kỳ ≈ 3.75 tháng)

> Mọi con số dưới đây là **điểm khởi đầu để playtest**, không phải số cuối. Gom hết vào `data/balance.tres` để chỉnh không cần sửa code.

**Thu**

| Nguồn | Số tiền | Ghi chú |
|---|---|---|
| Gia đình chuyển khoản | **3.000.000 đ / tháng** | Ngày 1 mỗi tháng |
| Làm thêm (`part_time`, 240 phút) | **200.000 đ / ca** | Tốn nhiều sức lực |
| Làm IT phòng server (`it_job`, 240 phút) | 350.000 đ / ca | Cần GPA ≥ 2.5, kĩ năng ≥ 30 |
| Học bổng | **3.000.000 đ / kỳ** | GPA kỳ trước ≥ 8.0 (hệ 10) |

**Chi**

| Khoản | Số tiền |
|---|---|
| Học phí | **9.000.000 đ / kỳ**, cho phép nộp làm 2 đợt: đợt 1 (4.500.000 đ) hạn **tuần 6**, đợt 2 hạn **tuần 12** (hoặc nộp trọn gói trước tuần 8). Đầu game người chơi được gia đình cấp ban đầu 5.000.000 đ tiền nhập học/chuẩn bị để giảm sốc kinh tế tuần đầu. |
| KTX A / B / C | 1.200.000 / 800.000 / 500.000 đ / tháng |
| Ăn căng tin | 25.000 đ / bữa → ~75.000 đ/ngày → **~2.100.000 đ / tháng** |
| Đặt đồ online | +15.000 đ phí giao mỗi đơn |

**Cân đối hàng tháng (ĐÃ TÍNH HỌC PHÍ ~2.400.000 đ/tháng)**

| KTX | Thu/tháng | Thuê + ăn | Học phí | **Còn/tháng** | Ca/tháng | Ca/kỳ (3.75 tháng) |
|---|---|---|---|---|---|---|
| **A** | 3.000.000 | 3.300.000 | 2.400.000 | **−2.700.000** | 14 | 51 ca (~3.4 ca/tuần) |
| **B** | 3.000.000 | 2.900.000 | 2.400.000 | **−2.300.000** | 12 | 44 ca (~2.9 ca/tuần) |
| **C** | 3.000.000 | 2.600.000 | 2.400.000 | **−2.000.000** | 10 | 38 ca (~2.5 ca/tuần) |

Cách đọc bảng:
- Khi tính đúng học phí, **cả 3 KTX đều âm tiền nếu không đi làm thêm**.
- Ở **A** thiếu hụt nặng nhất (−2.7tr/tháng), đòi hỏi ~3.4 ca/tuần.
- Ở **C** tiết kiệm được 700k/tháng so với A, nhưng vẫn âm 2tr/tháng và phải gánh bất lợi hồi sức lực ×0.6.
- **Học bổng 3.000.000 đ/kỳ** (GPA ≥ 8.0) tương đương **15 ca làm thêm** (~1 tháng làm việc) — là động lực cực kỳ lớn để giữ điểm cao thay vì chỉ cày tiền.

### 3.8 Minigame
Mỗi loại bài kiểm tra có minigame ngắn 20–40 giây, dùng chung một interface:

```
Minigame.play(kind: String, difficulty: float) -> Dictionary   # {"score": 0.0..1.0}
```

Ban đầu làm 1 minigame (trắc nghiệm bấm nhanh), sau mở rộng.

### 3.9 Câu lạc bộ — 4 CLB

| CLB | Tăng mạnh | Nhiệm vụ tuần (ví dụ) |
|---|---|---|
| **Âm nhạc** | Tinh thần, quan hệ | Tập nhạc, biểu diễn ở hội trường |
| **Truyền thông** | Trí tuệ, quan hệ | Chụp ảnh sự kiện, viết bài cho trường |
| **Thể thao** | Sức khỏe, sức lực | Giải bóng, chạy bộ |
| **Thể thao điện tử** | Tinh thần, trí tuệ | Giải đấu, luyện tập |

- Gia nhập **một CLB** tại Hội trường. Đổi CLB được nhưng **mất toàn bộ tiến độ** ở CLB cũ.
- **Mỗi tuần CLB giao nhiệm vụ.** Hoàn thành càng nhiều → càng nhiều **tim** với thành viên, kèm thưởng ít **tiền** hoặc **điểm rèn luyện**.
- Sinh hoạt CLB tăng gắn kết **giữa các thành viên với nhau**, không chỉ với người chơi.
- Bỏ nhiệm vụ nhiều tuần liền → bị mời ra khỏi CLB, mất điểm rèn luyện đã kiếm.

### 3.10 Điện thoại

Mở bằng phím `Tab`. Là **màn hình trung tâm** chứa mọi thứ người chơi cần tra cứu — thay vì làm 8 menu rải rác, chỉ cần một `CanvasLayer` với các tab.

| Tab | Nội dung |
|---|---|
| **Bản đồ** | Bản đồ trường + vị trí mình + phòng học kế tiếp |
| **Điểm học tập** | Điểm từng môn |
| **Điểm rèn luyện** | Điểm rèn luyện học kỳ này |
| **Điểm tích luỹ** | Số tín chỉ đã qua |
| **Điểm trung bình** | GPA |
| **Học phí** | Đóng học phí theo học kỳ — **trễ hạn thì bị cấm thi** |
| **Đặt hàng online** | Gọi đồ ăn/thức uống giao tới. Tốn thêm phí giao, nhưng tiện khi không muốn đi căng tin |
| **Tin nhắn** | NPC nhắn hẹn gặp, CLB nhắc nhiệm vụ, trường thông báo lịch thi |

### 3.11 Khu vực & nhiệm vụ theo khu

Người chơi đi lại tự do nhưng **bị giới hạn trong các khu đã mở**. Mỗi khu có nhiệm vụ riêng.

| Khu | Mở khi | Nhiệm vụ |
|---|---|---|
| Khu học (Nhà A, Nhà B, Xưởng 1–4) | Mặc định | Dự giờ, thi, bài tập lớn, giấy tờ |
| Khu ở (KTX A/B/C) | Mặc định | Ngủ, quan hệ bạn cùng phòng, thăm phòng |
| Khu ăn uống (Căng tin) | Mặc định | Ăn, làm thêm giờ cao điểm |
| Khu thể thao (Sân bóng, Phòng thể thao) | Mặc định | Chạy bộ, CLB thể thao |
| Khu hành chính (Nhà B T1–2, P. CTSV) | Mặc định | Giấy tờ, học phí |
| Khu sự kiện (Hội trường) | Mặc định | Sự kiện lớn theo lịch |
| **Cổng trường** | Sau tuần 2 | Ra ngoài: quán cà phê, làm thêm, mua sắm |

Cổng trường mở sau tuần 2 là **van tiết chế nội dung** — người chơi làm quen trong trường trước, rồi mới mở thế giới ngoài.

### 3.12 Kết thúc & tiến trình

Không có "thắng". Sau mỗi học kỳ có màn tổng kết; GPA và tín chỉ tích luỹ dần.

| Mốc | Nội dung |
|---|---|
| **Chương trình đầy đủ** | **8 học kỳ (4 năm)**, ~15 tín chỉ/kỳ → **120 tín chỉ** |
| **Ending tốt nghiệp** | Đủ 120 tín chỉ **và** điểm rèn luyện ≥ 50. Xếp hạng theo GPA + quan hệ + tiền |
| **Bản playtest đầu** | Chỉ **2 học kỳ** (~30 tín chỉ) — **chưa có ending**, kết thúc bằng màn tổng kết học kỳ 2 |

> ⚠️ **Đừng nhầm:** bản dọc ở M5 chỉ chơi 2 học kỳ ≈ 30 tín chỉ, **không thể** chạm ngưỡng 120. Ending tốt nghiệp là chuyện của bản đầy đủ. Sau học kỳ 2 sẽ có nút **"Tua nhanh học kỳ"** để nhảy tới năm cuối khi cần test.

---

### 3.13 Vòng phản hồi — bốn thứ làm vòng lặp "thấy được"

Bốn thứ rẻ nhất nhưng quyết định vòng lặp có vui hay không. Thiếu chúng thì người chơi bấm nút mà không hiểu mình vừa đánh đổi cái gì.

#### 1. Xem trước hậu quả trước khi làm

Đứng gần vật thể, bấm `E` → hiện khung nhỏ trước khi thực hiện:

```
┌─ Tự học ở thư viện ────────────┐
│ Tốn:  60 phút · 12 sức lực     │
│ Nhận: trí tuệ +1 · tinh thần −3│
│ ⏰ Còn 1 giờ 30 phút tới tiết   │
│    it101                       │
└────────────────────────────────┘
```

Nếu hoạt động dài hơn thời gian còn lại tới tiết, khung thêm một dòng cảnh báo:

```
!! Làm xong là TRỄ TIẾT / mất tiết
```

Ví dụ thật lấy từ `--hudtest`, lúc 06:00 Thứ 2 (còn 90 phút tới tiết):

| Hoạt động | Phút | Trễ tiết? |
|---|---|---|
| Nghỉ | 0 | không |
| Ăn ở căng tin | 30 | không |
| Tự học ở thư viện | 60 | không |
| **Làm thêm (trông xe)** | **240** | **CÓ** |

Đây chính là câu trả lời cho *"ca làm thêm hay buổi học"* — nhìn một bảng là thấy ngay.

`Activity` đã có đủ dữ liệu (`minutes`, `energy_cost`, `money_cost`, `money_gain`, `stat_effects`) nên gần như miễn phí.

**Vì sao quan trọng:** đây chính là thứ biến *"ca làm thêm hay buổi học"* từ bấm-cho-xong thành **quyết định có suy nghĩ** — đúng Trụ cột 1. Không có nó, người chơi chỉ khám phá bằng thử-sai rồi hoàn tác.

→ Cần `Gameplay.preview(activity_id) -> Dictionary` **tách riêng khỏi `perform_activity()`**, để xem trước không gây tác dụng phụ.

#### 2. Thanh tiến độ chuẩn bị thi

`prep = effective_minutes / required_minutes` hiện đang chạy ngầm. Phải hiện ra:

- Trên HUD khi đang học: `Chuẩn bị thi IT101: 62%`
- Hoặc ngay tại bàn học, trong khung xem trước ở mục 1

**Vì sao quan trọng:** người chơi không thể thấy áp lực nếu không biết mình còn thiếu bao nhiêu giờ. Đây là thứ biến "học" từ hành động vô nghĩa thành hành động có mục tiêu.

→ Tách `ExamSystem.prep_ratio(course) -> float` ra khỏi `compute_score()`, để HUD và công thức dùng **cùng một phép tính**. Nếu tính ở hai nơi, hai con số sẽ lệch nhau và người chơi mất tin vào HUD.

#### 3. Tổng kết cuối ngày

Khi ngủ, hiện bảng ngắn:

```
── Hết ngày 3, Thứ 4 ──────────────
Học:      90 phút  (IT101: 40%)
Tiền:     +200.000 làm thêm · −75.000 ăn uống
Chỉ số:   tinh thần −5 · sức khỏe −2
⚠ Thi IT101 sau 3 ngày, bạn mới đạt 40%
```

**Vì sao quan trọng:** đây là **vòng phản hồi rẻ nhất mà hiệu quả nhất**. Người chơi nhận ra sai lầm ngay đêm đó, chứ không phải sau 15 tuần. Dòng cảnh báo cuối là chỗ biến số liệu thành lời khuyên.

→ Cần `DailyLog` ghi trong ngày: phút học theo môn, tiền vào/ra, chênh lệch chỉ số. **Thuần dữ liệu — không thêm logic gameplay.** Reset khi sang ngày.

#### 4. Đếm bữa ăn trong ngày

GDD đã có "nhịn ăn để tiết kiệm" và "KTX C + ăn qua loa thì sức khỏe tụt" nhưng **chưa có cơ chế nào đứng sau**. Chỉ cần đếm số bữa đã ăn hôm nay (0–3), thiếu bữa thì tụt khi ngủ:

| Số bữa | Hậu quả khi ngủ |
|---|---|
| 3 | không phạt |
| 2 | −3 sức khỏe |
| 1 | −8 sức khỏe, −4 tinh thần |
| 0 | −15 sức khỏe, −10 tinh thần |

**Vì sao quan trọng:** không có luật này thì "nhịn ăn tiết kiệm" là lựa chọn **miễn phí** — ai cũng nhịn, và áp lực tiền biến mất. Đây là thứ khiến KTX C thật sự khó sống chứ không chỉ là con số trang trí.

→ `PlayerStats.meals_today`, reset khi sang ngày.

---

## 4. Phạm vi MVP (bản dọc đầu tiên)

**Có:**
- **1 tuần game, 1 môn, 1 bài thi** — lát cắt dọc, không phải cả trường
- Bản đồ ngoài trời **64×36 ô** (đã dựng xong ở `scripts/world/campus_map.gd`) + **3 scene nội thất**: KTX A (tầng 1), Căng tin, 1 phòng học Nhà A
- Đồng hồ chạy, ngủ sang ngày, HUD hiển thị giờ/thứ/sức lực/tiền
- **5 hoạt động cốt lõi cho lát cắt 1 tuần**: `study` (tự học), `sleep` (ngủ KTX), `eat` (ăn căng tin), `part_time` (trông xe ở nhà xe), và `attend_lecture` (dự giờ ở Nhà A - T2 tính chuyên cần). Tương tác bằng phím `E`. Các hoạt động `gym` (mở sau tuần 2), `club` (đăng ký Hội trường), `exercise` sẽ mở ở giai đoạn tiếp theo.
- Công thức điểm thi (mục 3.4) chạy được với **1 môn**
- Lưu / tải 1 slot

**Chưa có (làm sau):**
- Thời khoá biểu nhiều môn · NPC và hội thoại · Minigame · Điện thoại · Câu lạc bộ · Khu vực & nhiệm vụ · Nhánh kỹ năng ở mốc 50/100 · Nghệ thuật chính thức (đang dùng placeholder) · Âm thanh

> **Vì sao cắt xuống còn 1 tuần:** mục tiêu của bản dọc là chứng minh **vòng lặp học – sống thú vị**, không phải chứng minh làm được nhiều nội dung. Một tuần đủ để thấy "học hay đi làm" là quyết định thật.

---

## 5. Kiến trúc kỹ thuật

**Autoload (singleton)** — thứ tự nạp quan trọng, `EventBus` phải đầu tiên:

| Tên | Trách nhiệm |
|---|---|
| `EventBus` | Chỉ phát signal, không chứa logic. Mọi hệ thống nói chuyện qua đây |
| `SaveSystem` | Lưu/tải JSON vào `user://saves/slot_N.json` (đặt sớm để các hệ thống khác `register()` trong `_ready()`, có trường `save_version`) |
| `Balance` | Dữ liệu cấu hình kinh tế / cân bằng game (`data/balance.tres` hoặc mặc định) |
| `GameClock` | Thời gian game, ngủ, sang ngày |
| `Schedule` | Lịch học trong tuần, kiểm tra tiết học sắp tới |
| `PlayerStats` | **7 chỉ số** + Dictionary `highest_milestone` (sàn động) |
| `DailyLog` | Nhật ký hoạt động trong ngày (phút học, thu/chi, thay đổi chỉ số) |
| `ActivityDB` | Nạp toàn bộ `data/activities/*.tres` |
| `GameInput` | Đăng ký input action bằng code (khỏi khai báo trong Project Settings) |
| `Gameplay` | Luật chơi: kiểm tra điều kiện rồi thực thi một hoạt động |
| `ExamSystem` | Hệ thống tính điểm chuẩn bị thi và điểm số bài thi |

**Quy ước lưu game — mỗi hệ thống tự đăng ký, `SaveSystem` không biết gì về chúng:**

```gdscript
# Trong _ready() của từng hệ thống
SaveSystem.register("player_stats", PlayerStats.to_dict, PlayerStats.from_dict)
SaveSystem.register("game_clock",   GameClock.to_dict,   GameClock.from_dict)
```

`SaveSystem` chỉ duyệt danh sách đã đăng ký. Nhờ vậy **thêm hệ thống mới không phải sửa `SaveSystem`** — và không thể quên lưu, đúng cái lỗi đã cảnh báo ở 3.2d. Sẽ có khoảng 6–10 hệ thống cần lưu, làm thủ công kiểu gì cũng quên một cái.

**Scene:** `scenes/world/campus.tscn` (map + object tương tác) → instance `scenes/player/player.tscn` và `scenes/ui/hud.tscn`.

**Quy ước:** thêm một object tương tác mới = đặt node `StaticBody2D`, gán `scripts/world/interactable.gd`, điền `activity_id` trong Inspector. Không cần viết script mới.

---

## 6. Addon cần cài (Asset Library trong editor)

| Addon | Bắt buộc cho MVP | Việc |
|---|---|---|
| Dialogue Manager (nathanhoad) | Không | Hội thoại có nhánh, điều kiện |
| Phantom Camera (ramokz) | Không | Camera follow mượt, room-lock |
| Aseprite Wizard | Không | Import `.aseprite` thành animation |
| gloot (peter-kish) | Không | Inventory dạng grid |
| Beehave / LimboAI | Không | Lịch sinh hoạt NPC |
| Sound Manager (nathanhoad) | Không | Nhạc theo khu vực |

MVP chạy **không cần addon nào** — cài khi tới phần tương ứng.

---

## 7. Roadmap

| Mốc | Nội dung | Xong khi |
|---|---|---|
| **M0** | **Lát cắt dọc (Vertical Slice): 1 tuần, 1 môn (it101), 1 bài thi, 3 nội thất (`ktx_a_t1`, `cang_tin`, `nha_a_t2`)** | **Chơi hết 1 tuần, đi lại/tương tác được, có thể lên giảng đường Nhà A (T2) điểm danh/dự giờ và thấy "học hay đi làm" là quyết định thật** |
| M1 | Thời khoá biểu + môn học + điểm + màn tổng kết học kỳ | Qua được 1 học kỳ có GPA |
| M2 | NPC có lịch, hội thoại (Dialogue Manager), thân thiết | Nói chuyện được với 3 NPC |
| M3 | Minigame + bài tập/deadline | Có 1 minigame tính điểm |
| M4 | Art chính thức + âm thanh + polish (fade, hiệu ứng) | Nhìn không còn placeholder |
| M5 | Học kỳ 2, nhiều địa điểm, màn tổng kết | Chơi trọn 2 học kỳ |

**Trạng thái M0:** Nền tảng kỹ thuật và logic lõi đã hình thành — `project.godot` đã khai báo các autoload lõi (`EventBus`, `GameClock`, `PlayerStats`, `Gameplay`, `ExamSystem`...), scene kiểm thử `scenes/main.tscn` đã chạy được `--looptest`, `--selftest`, `--hudtest`. Tuy nhiên **chưa tick hoàn thành M0** cho tới khi hoàn thiện điều khiển nhân vật trực tiếp trên scene campus đồ hoạ và vòng lặp chơi bằng mắt.

**Hoãn tới sau M0:** nhánh kỹ năng ở mốc 50/100 · điện thoại 8 tab · `QuestSystem` + khu vực. Ba thứ này chưa cần cho tới khi vòng lặp học–sống chạy tốt.

---

## 8. Kế hoạch nội dung (Content Budget cho 1 học kỳ hoàn chỉnh)

Thay vì tham vọng 8 học kỳ ngay từ đầu, mốc mục tiêu khả thi nhất là **1 học kỳ hoàn chỉnh** trước khi mở rộng:

| Hạng mục | Số lượng mục tiêu | Chi tiết |
|---|---|---|
| **Môn học** | 6 môn | 3 dễ / 2 vừa / 1 khó (`required_minutes` từ 2400 đến 4800) |
| **NPC chính** | 3 nhân vật | Bạn cùng phòng KTX, Lớp trưởng, Giảng viên cố vấn |
| **Hội thoại & Sự kiện tim** | 3 NPC × 3 mốc (2, 4, 6 tim) | Tổng ~30 đoạn hội thoại nhánh (dùng Dialogue Manager) |
| **Sự kiện ngẫu nhiên** | 10 sự kiện | Ốm đột xuất, mưa bão hủy tiết, kiểm tra bất ngờ, bạn rủ đi net, xe hỏng... phá vỡ tính tất định của bảng tính |
| **Câu lạc bộ** | 1 CLB thử nghiệm | Triển khai 1 CLB trước để test vòng nhiệm vụ tuần |
| **Scene nội thất** | 3 scene | KTX A, Căng tin, 1 Giảng đường chính |

### Các quyết định kỹ thuật nền tảng cần chốt:
1. **Font tiếng Việt**: Bắt buộc chọn font pixel hỗ trợ đầy đủ Unicode tiếng Việt (như font Noto Sans Pixel / m5x7 việt hóa) ngay từ đầu để tránh vỡ giao diện HUD.
2. **Cơ chế dừng thời gian**: Đồng hồ game **tạm dừng (pause)** khi mở điện thoại, xem menu hoặc trong lúc hội thoại.
3. **Cơ chế học nhiều thời lượng**: Để tránh "bấm E hàng trăm lần", hành động tự học cho phép chọn 1h / 2h / 3h (tương đương 60 / 120 / 180 phút và tiêu hao sức lực tỉ lệ thuận).
4. **Cơ chế mai một (Decay) cho Học lực**: Nếu quá 2 ngày liên tiếp không học môn nào, `academic` sẽ tụt 1 điểm/ngày cho tới khi chạm sàn mốc đã đạt. Điều này giúp **luật sàn có ý nghĩa thực tế**.

---

## 9. Rủi ro đã biết

- **Phạm vi — rủi ro này ĐÃ xảy ra một lần.** GDD từng ghi MVP là "map 40×24, 1 giảng đường, 1 ký túc", nhưng bản đồ thật đã thành **64×36 với 17 công trình chính** (kèm sân bóng, đài phun nước, khu quy hoạch). Đây đúng là kiểu phình phạm vi đã tự cảnh báo. Cách chống: mọi thứ mới phải đi qua **lát cắt dọc** (1 tuần, 1 môn) trước khi được nhân ra.
- **Nội dung là vua.** Hệ thống xong sớm nhưng thiếu hội thoại/sự kiện thì game vẫn nhạt. Dành 50% thời gian cho nội dung.
- **Art.** Placeholder hiện tại cố tình xấu. Nếu không tự vẽ được, mua asset pack (Modern Interiors/Exteriors — LimeZu) thay vì cố vẽ từ đầu.
- **Kiểm tra bản đồ tự động.** Cửa bị bịt là lỗi đã xảy ra thật (2 cửa căng tin và KTX C không vào được). Từ nay `CampusMap.validate()` phải chạy trong `_ready()` khi debug — nó flood-fill từ điểm xuất phát và báo mọi cửa/vật thể không tới được. Đừng tin mắt thường khi bản đồ có hàng trăm ô.
