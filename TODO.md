# TODO — SDU Life Simulator

> File này là **bảng việc cần làm** của dự án. Thiết kế chi tiết nằm ở [GDD.md](GDD.md).
> Đánh dấu `[x]` khi xong. Làm từ trên xuống, đừng nhảy cóc.

---

## Giai đoạn 0 — Chuẩn bị (làm trước khi viết dòng code nào)

- [x] Cài **Godot 4.7 stable** (đang dùng `Godot_v4.7.2-stable_win64.exe`) — không dùng bản dev
- [x] Mở project `sdu-life-simulator`, chạy Godot để quét và tạo cache import
- [ ] Tạo tài khoản **GitHub**, đẩy project lên (đã có `.gitignore` sẵn) — commit mỗi khi xong 1 việc
- [x] Chốt **phạm vi MVP (Lát cắt dọc 1 tuần M0)**: 1 khu trường, 5 hoạt động cốt lõi (`study`, `sleep`, `eat`, `part_time`, `attend_lecture`). Rút `gym` (mở sau tuần 2) và `club` (cần vào Hội trường đăng ký) ra khỏi lát cắt 1 tuần.
- [x] Quyết định ngôn ngữ hiển thị trong game (**tiếng Việt có dấu**) — bắt buộc dùng font pixel hỗ trợ đầy đủ Unicode tiếng Việt (như Noto Sans Pixel / m5x7 việt hóa). Thử nghiệm trước bằng chuỗi dấu chồng phức tạp như "Ắ Ề Ổ Ữ Ự" trước khi dựng HUD.
- [ ] Song song với code M0: bắt đầu viết nội dung trong một bảng tính (6 môn học, 10 sự kiện ngẫu nhiên, kịch bản hội thoại cho 3 NPC chính) để tránh dồn ứ nút thắt cổ chai ở M2.
- [x] Cài addon: MVP chạy không cần addon nào, chỉ cài khi tới giai đoạn tương ứng (Dialogue Manager ở M2...).

**Cấu trúc thư mục đã chốt:**

```
sdu-life-simulator/
├── project.godot
├── art/            anh (sau này)
├── audio/          am thanh (sau này)
├── data/
│   └── activities/ moi hoat dong la 1 file .tres
├── docs/           GDD, ghi chu thiet ke
├── scenes/         man choi, nhan vat, UI
├── scripts/
│   ├── autoload/   singleton toan cuc
│   ├── data/       dinh nghia Resource
│   ├── player/     nhan vat
│   ├── ui/         HUD, menu
│   └── world/      ban do, vat tuong tac
└── tools/          script ho tro (sinh art placeholder...)
```

---

## Giai đoạn 1 — Khung chạy được (M0)

### 1.1 Nền tảng
- [x] Sửa `project.godot`: thêm `[autoload]`, `run/main_scene`, độ phân giải 1280×720
- [x] Tạo autoload cốt lõi: `EventBus`, `Balance`, `GameClock`, `Schedule`, `PlayerStats`, `DailyLog`, `ActivityDB`, `GameInput`, `Gameplay`, `ExamSystem`
- [x] `GameInput`: đăng ký phím bằng code (WASD + mũi tên, `E` tương tác, `F5` lưu, `F9` tải)
- [ ] `SaveSystem` (hiện `F5`/`F9` mới đăng ký phím, chưa nối logic lưu JSON)
- [ ] Tạo file tài nguyên `res://data/balance.tres` từ `BalanceConfig` (loại bỏ cảnh báo khởi động, chỉnh thông số trực tiếp trong Inspector)

### 1.2 Bản đồ ← **ƯU TIÊN SỐ 1**
- [x] `scripts/world/campus_map.gd` — lưới 64×36 ô, 17 công trình, 8 trục đường, 15 cửa, 3 cổng
- [x] `CampusMap.validate()` + `door_approach()` — **đã chạy thật, sạch lỗi** (15/15 cửa tới được)
- [x] `tools/check_map.gd` — chạy lại kiểm tra bất cứ lúc nào, có cả negative test
- [ ] Gắn `validate()` vào `_ready()` của scene campus khi `OS.is_debug_build()` → `push_error`
- [ ] Mở sơ đồ trường, đối chiếu lại toạ độ, chỉnh số nào thấy lệch — **chỉ sửa mảng, không sửa logic**
- [ ] Viết `campus_renderer.gd`: `_draw()` vẽ từng ô theo màu, để nhìn thấy bản đồ trước khi có art
- [ ] Sinh va chạm tường tự động: gộp các ô `#` liền nhau thành 1 hình chữ nhật (đừng tạo 1 collider cho mỗi ô)
- [ ] Giới hạn người chơi trong biên bản đồ

### 1.3 Người chơi
- [ ] `CharacterBody2D` đi 4 hướng bằng `Input.get_vector`, tốc độ ~120–150 px/s (chặng ngắn KTX -> Nhà A mất ~10–15 phút game; ngang toàn map 1024px mất ~40–45 phút)
- [ ] Vẽ nhân vật bằng `_draw()` (thân, đầu, tóc, mắt đổi theo hướng) — placeholder
- [ ] `Area2D` "InteractZone" quét vật thể xung quanh, chọn cái **gần nhất**
- [ ] Bấm `E` gọi `interact()` lên vật gần nhất

### 1.4 Vật thể tương tác
- [ ] `Interactable` = `StaticBody2D` + `@export activity_id` — thêm vật mới **không cần viết code**
- [ ] Đặt trong bản đồ lát cắt 1 tuần: Giường (ngủ), Bàn học (tự học), Căng tin (ăn), Nhà để xe (làm thêm trông xe), Bàn giảng đường (dự giờ `attend_lecture` ở phòng học T2 Nhà A tính chuyên cần). Các vật thể khác (CLB, Sân thể thao) sẽ mở ở các giai đoạn sau.

### 1.5 Cơ chế chính
- [x] `GameClock`: 1 giây thực = 6 phút game; có phút/giờ/**thứ**/tuần; `advance_minutes()` và `sleep_until()`
- [x] `PlayerStats` **7 chỉ số**: sức lực · sức khỏe · tinh thần · trí tuệ · học lực · kĩ năng chuyên ngành · tiền — kèm `apply_effects()`
- [x] `Activity` (Resource) + 4 file `.tres` đã có trong `data/activities/` (`study`, `sleep`, `eat`, `part_time`). File `attend_lecture.tres` cần tạo khi dựng scene phòng học T2 Nhà A.
- [x] `Gameplay.perform_activity(id)`: kiểm tra tiền/sức lực → trừ chi phí → cộng hiệu ứng → tốn thời gian → phát signal
- [ ] Ngủ = nhảy sang 6:30 hôm sau + hồi sức lực **theo mức sống của KTX** (A ×1.0 · B ×0.8 · C ×0.6) (hiện looptest đang tạm cố định x1.0)
- [ ] Bổ sung cơ chế phao cứu sinh chống bế tắc (khi hết tiền): hoạt động nấu mì gói KTX `eat_instant_noodle.tres` (10k), cơ chế gọi điện xin gia đình ứng viện trợ khi ví = 0đ (nhận 500k, -20 tinh thần)
- [ ] Quy định tốc độ tăng Trí tuệ theo diminishing returns (ngân sách 8–12 điểm/kỳ, cày 4 năm chạm 100)

### 1.6 HUD
- [ ] CanvasLayer: khung giờ + thứ + tuần, thanh năng lượng, thanh tinh thần, GPA, tiền
- [ ] Dòng gợi ý `[E] Ngủ` ở gần đáy màn hình
- [ ] Thông báo (toast) tự mờ sau 3 giây

### 1.7 Lưu / tải
- [ ] `SaveSystem` (autoload) ghi JSON vào `user://saves/slot_N.json`. **Đặt ngay sau `EventBus`** trong danh sách autoload để các hệ thống khác kịp gọi `register()` trong `_ready()`.
- [ ] Thêm trường `save_version: 1` ngay từ đầu để dễ migrate cấu trúc dữ liệu khi nâng cấp.
- [ ] **Mỗi hệ thống tự đăng ký**, `SaveSystem` không biết gì về chúng:
      `SaveSystem.register("player_stats", PlayerStats.to_dict, PlayerStats.from_dict)`
      → thêm hệ thống mới **không phải sửa `SaveSystem`**, và không thể quên lưu
- [ ] `F5` lưu, `F9` tải
- [ ] **Test ngay luật sàn qua Save/Load trong M0**: đạt mốc chỉ số -> save -> load -> thử tụt xem mốc sàn có được bảo toàn nguyên vẹn không

### 1.8 Nội thất & nhiều tầng
- [ ] Thêm autoload `SceneRouter`: chuyển scene có fade, nhớ cửa quay lại
- [ ] Làm **3 nội thất** cho lát cắt dọc: `ktx_a_t1.tscn` · `cang_tin.tscn` · `nha_a_t2.tscn` (phòng học T2 Nhà A để dự giờ `attend_lecture`)
- [ ] Cầu thang là `Interactable` gọi `SceneRouter` — không cần hệ thống camera nhiều tầng
- [ ] 14 công trình còn lại **cứ để mặt tiền**, chưa làm nội thất

### 1.9 Lát cắt dọc ← MỤC TIÊU THẬT CỦA M0

**Kết quả đã chạy thật** (`godot --headless --path <project> -- --looptest`):
```
A. Cham chi hoc (0 ca lam)  tien  -525.000 | prep 77% | diem 7.5 | 0 luot bi chan
B. Di lam nhieu (1 ca/ngay) tien  +875.000 | prep 25% | diem 5.0 | 0 luot bi chan
C. Chi di lam (3 ca/ngay)   tien +2.275.000| prep  0% | diem 4.0 | 7 luot bi chan
```

→ **"Học hay đi làm" ĐÃ là quyết định thật:** A được 7.5 nhưng âm tiền, B được 5.0 nhưng dư 875k, C đạt 4.0 (vừa vặn chạm ngưỡng đỗ 4.0, chỉ cần sơ suất là trượt). Đúng Trụ cột 1.

- [x] **1 tuần game, 1 môn, 1 bài thi** — `scripts/main.gd` chế độ `--looptest`
- [x] Công thức điểm ở GDD §3.4 chạy được — `--selftest` kiểm 3 ca: bỏ học (4.0) / học đủ (8.5) / học đủ + ốm (7.0), **cả 3 khớp dự đoán trong `exam_economy.md`**
- [x] Học lại hè: thi 10/10 nhưng bị chặn ở **8.0** — luật "tối đa 8" chạy đúng
- [ ] `data/balance.tres` — **chưa có**, hiện dùng giá trị mặc định trong `BalanceConfig`
- [x] Trả lời được câu hỏi M0 — xem kết quả ở trên

> ⚠️ **Một lỗi cân bằng đã bắt được nhờ looptest.** Với `required_minutes = 900`, lối chơi B **vừa bằng điểm A vừa kiếm được tiền** — B lấn át hoàn toàn A, tức là không có đánh đổi nào cả. Nguyên nhân: 900 phút là quá thấp cho một môn tích luỹ **cả học kỳ** — chỉ cần 15 lượt tự học là đầy, trong khi một tuần đã học được 42 lượt.
> **Đã sửa thành `3600`** và bảng kết quả ở trên là số sau khi sửa. Đây chính là phần "số liệu kinh tế" mà bản review nói còn thiếu — giờ đã có số thật để chỉnh.

**Bốn thứ vòng phản hồi (GDD §3.13) — thuộc lát cắt, KHÔNG hoãn:**
- [x] `Gameplay.preview(activity_id)` — tách khỏi `perform_activity()`, **không tác dụng phụ**. Đã chạy, trả về phút · sức lực · tiền · chỉ số đổi · phút còn lại của ngày
- [x] `ExamSystem.prep_ratio(course)` — tách khỏi `compute_score()`, HUD và công thức dùng chung
- [x] Hiện `Chuẩn bị thi it101: 62% (thiếu N phút)` trên HUD
- [x] `DailyLog` — phút học theo môn, tiền vào/ra, chênh lệch chỉ số. Thuần dữ liệu, reset mỗi ngày
- [x] Bảng tổng kết cuối ngày khi ngủ, kèm cảnh báo *"còn N ngày thi, bạn mới đạt X%"*
- [x] `PlayerStats.meals_today` — đếm 0–3 bữa; bảng phạt chạy đúng như GDD §3.13.4 (3→không phạt, 2→−3, 1→−8/−4, 0→−15/−10)

**Lộ trình thực hiện đề xuất cho phần còn lại của M0 (để chơi được bằng mắt):**
1. Gắn `CampusMap.validate()` vào `_ready()` của scene campus và viết `campus_renderer.gd` để nhìn thấy bản đồ.
2. Gộp va chạm tường tự động, làm nhân vật di chuyển (tốc độ ~120–150 px/s), cài đặt `Interactable` và `Area2D` InteractZone.
3. Gắn HUD hiện có vào scene campus.
4. Đặt tạm 5 vật thể cốt lõi ngay ngoài trời (giường, bàn học, căng tin, nhà để xe, bàn dự giờ IT101) để chơi trọn vẹn 1 tuần bằng mắt (chưa cần SceneRouter).
5. Xây dựng `SaveSystem` theo cơ chế `register()` (đặt ngay sau `EventBus`, kèm `save_version: 1`).
6. Tạo `data/balance.tres` và mức hồi sức lực theo KTX.
7. Hoàn thiện 3 scene nội thất (`ktx_a_t1.tscn`, `cang_tin.tscn`, `nha_a_t2.tscn`) và `SceneRouter`.
8. Trực tiếp playtest trọn vẹn 1 tuần để kiểm chứng cảm giác đánh đổi.

---

**Còn thiếu để chơi được bằng mắt:**
- [ ] `campus_renderer.gd` + va chạm tường tự động
- [ ] Nhân vật di chuyển + `Interactable`
- [ ] Gắn HUD vào scene thế giới
- [ ] `data/balance.tres` — gom hằng số ra khỏi code
- [ ] Collision cho `Interactable` (hiện chỉ có Area2D cha, đứng đè lên được)
- [ ] 3 scene nội thất `ktx_a_t1` / `cang_tin` / `nha_a_t2` (hiện bấm `E` ở cửa chạy thẳng hoạt động, chưa đổi scene)
- [ ] `SaveSystem` (`F5`/`F9` mới chỉ đăng ký phím, chưa có logic)
- [ ] Mức hồi sức lực theo KTX A/B/C (hiện tạm cố định ×1.0)
- [x] **Khung xem trước hiện "Còn 1 giờ 30 phút tới tiết it101"** — cần `Schedule` autoload + `Course.class_slots`
- [x] **Cảnh báo trễ tiết**: `misses_next_class` bật khi hoạt động dài hơn thời gian còn lại tới tiết. Kiểm chứng: Nghỉ 0' · Ăn 30' · Tự học 60' → `false`; **Làm thêm 240' → `true`** (chỉ còn 90' tới tiết)

**Ba lệnh kiểm tra tự động (đã chạy, đều sạch):**

```
godot --headless --path <project> -- --selftest   # công thức điểm · bản đồ · 4 tính năng
godot --headless --path <project> -- --looptest   # mô phỏng 1 tuần, 3 lối chơi
godot --headless --path <project> -- --hudtest    # HUD chạy thật: khung xem trước + bảng tổng kết
```

> `--hudtest` đáng giá: nó **bắt được 2 lỗi thật** mà `--looptest` không thấy (vì looptest thoát trước khi tạo HUD).
> 1. Bảng tổng kết luôn ghi `0/3 bữa` dù đã ăn — vì `meals_today` bị reset bởi `sleep_until()` **trước khi** HUD đọc.
> 2. Tiêu đề ghi `HẾT NGÀY 2` cho ngày 1 — cùng nguyên nhân: `GameClock.day` đã tăng trước khi HUD đọc.
> Cả hai đã sửa bằng cách chụp `meals` và `day` **trước** khi ngủ, rồi truyền vào `summary`.

> **Vì sao 4 thứ này thuộc lát cắt:** chúng là thứ biến "bấm nút" thành "quyết định". Không có chúng thì tiêu chí M0 — *"học hay đi làm có phải quyết định thật không"* — không thể trả lời được, vì người chơi không thấy được mình đang đánh đổi cái gì.

**M0 xong khi:** chơi hết 1 tuần game, thi 1 môn ra điểm, và câu trả lời ở trên là **"có"**.

> ⚠️ **Lưu ý kiểm thử playtest thực tế:**
> Kết luận "học hay đi làm là quyết định thật" ở trên mới dựa trên 3 bot chạy script (`--looptest`), chưa tính tiền thuê KTX, học phí và trợ cấp đầu kỳ, nên con số "B dư 875k" chưa phản ánh toàn bộ áp lực tiền bạc thật sự.
> Khi hoàn thiện nhân vật đi lại và HUD chơi được trực tiếp trên màn hình, **chính bạn (người phát triển) sẽ trực tiếp chơi thử (playtest) trọn vẹn 1 tuần game** để kiểm chứng xem người chơi có thực sự cảm nhận được áp lực đánh đổi giữa học tập, kiếm tiền và giữ sức khỏe hay không trước khi chính thức nghiệm thu M0 (không cần nhờ người ngoài test).

---

## Giai đoạn 2 — Học vụ (M1)

- [ ] `Course` (Resource): mã môn, tên, tín chỉ, giờ học trong tuần
- [ ] `Schedule`: bảng (thứ, giờ) → môn; nạp từ `data/courses/*.tres`
- [ ] Đến giờ vào lớp = cộng điểm chuyên cần; vắng quá 3 buổi = cấm thi
- [ ] Điểm môn = bài tập 30% + giữa kỳ 30% + cuối kỳ 40% — **thang 10** (ngân sách 3600' chia 3 đợt: BTL tuần 1–6 cần 1000', Giữa kỳ tuần 7–10 cần 1200', Cuối kỳ tuần 11–15 cần 1400'; khóa điểm từng đợt tránh cày dồn đầu kỳ)
- [ ] **Luật điểm**: chốt điểm là khoá vĩnh viễn · trượt < 4/10 thì hè học lại · **điểm học lại tối đa 8**
- [ ] **Mốc chỉ số**: lưu mốc cao nhất từng chỉ số, kẹp `apply_effects()` theo sàn (3 chỉ số kỹ năng)
- [ ] Màn **tổng kết học kỳ** sau tuần 15: điểm học tập, điểm rèn luyện, điểm tích luỹ, điểm trung bình, tiền, xếp loại
- [ ] Nút "Học kỳ mới" — tăng độ khó

## Giai đoạn 3 — Con người (M2)

- [ ] `CharacterData` (Resource): tên, lịch sinh hoạt theo giờ, sở thích, điểm thân thiết 0–10
- [ ] NPC đi lại bằng `NavigationRegion2D` + `NavigationAgent2D`
- [ ] Cài **Dialogue Manager** (nathanhoad) qua Asset Library
- [ ] Viết 3 NPC chính đầu tiên: bạn cùng phòng KTX, lớp trưởng, giảng viên cố vấn (xem GDD §8)
- [ ] Sự kiện mở khoá theo mốc thân thiết (kiểu heart event)

## Giai đoạn 4 — Minigame & áp lực (M3)

- [ ] Interface chung: `Minigame.play(kind: String, difficulty: float) -> Dictionary`
- [ ] Minigame 1: trắc nghiệm bấm nhanh (20–40 giây)
- [ ] Deadline bài tập: nếu không nộp đúng hạn thì trừ điểm
- [ ] Tuần thi: mọi hoạt động tốn gấp đôi năng lượng

## Giai đoạn 5 — Art, âm thanh, polish (M4)

- [ ] Mua/tải asset pack 2D hiện đại (**Modern Interiors / Modern Exteriors — LimeZu**)
- [ ] Thay renderer bằng `TileMapLayer` + `TileSet` terrain (autotile)
- [ ] Thay `_draw()` của nhân vật bằng `AnimatedSprite2D` 4 hướng × 4 frame
- [ ] Cài **Aseprite Wizard** nếu vẽ bằng Aseprite
- [ ] Cài **Phantom Camera** cho camera mượt, room-lock
- [ ] Nhạc nền đổi theo khu vực (**Sound Manager**)
- [ ] Hiệu ứng chuyển cảnh fade

## Giai đoạn 6 — Nội dung dài hơi (M5)

- [ ] Học kỳ 2, thêm môn và NPC
- [ ] Thêm 4 địa điểm: thư viện, sân thể thao, khu CLB, quán cà phê ngoài trường
- [ ] Ending tốt nghiệp (đủ 120 tín chỉ) + xếp hạng
- [ ] Cân bằng lại chỉ số sau khi có người chơi thật thử

---

## BẢN ĐỒ TRƯỜNG SDU (64×36 ô)

Dựng theo sơ đồ trường bạn gửi. Tỷ lệ có thể lệch nhưng **vị trí tương đối giữ đúng**.

- Lưới **64 × 36 ô**, mỗi ô 16×16 px → thế giới **1024 × 576 px**
- Camera zoom **2×** (nhìn được 640×360 px ≈ 40×22 ô)
- Người chơi xuất phát ở ô **(22, 6)**, ngay trục dọc từ cổng chính

**Cách làm:** KHÔNG vẽ tay từng ô. Khai báo công trình/đường/cửa bằng hình chữ nhật, rồi để code tự dựng lưới. Muốn dời nhà B sang trái 2 ô = sửa 1 số.

### ✅ QUYẾT ĐỊNH: ngoài trời = mặt tiền, trong nhà = scene riêng

Trước đây tài liệu này mâu thuẫn: mục A nói mỗi tầng là scene riêng, nhưng bảng vật thể lại đặt giường, kệ sách, cầu thang ngay trên lưới ngoài trời. **Đã chốt một cách duy nhất:**

| | Quy ước |
|---|---|
| **Ngoài trời** | Chỉ vẽ **mặt tiền**. Công trình là **khối đặc**, không có sàn bên trong |
| **Trong nhà** | Mỗi phòng/tầng là **một scene riêng**, kích thước tuỳ ý |
| **Cửa** | Một ô đánh dấu **trên tường**. Đứng ở ô ngoài kề bên, bấm `E` để vào scene |

**Vì sao chọn cách này:** nó giải quyết luôn lỗi "nội thất quá hẹp". Xưởng chỉ rộng 7×3 ô, KTX B và C chỉ 3 ô cao — nếu nhồi nội thất vào trong lưới ngoài trời thì hành lang KTX chỉ còn **1 hàng ô**, không đặt nổi 4 cửa phòng. Tách scene ra thì phòng KTX muốn rộng bao nhiêu cũng được, **không phải sửa toạ độ công trình nào**.

Đổi lại: nhiều scene hơn. Nhưng chỉ làm nội thất cho những chỗ lát cắt dọc cần (KTX A, Căng tin, 1 phòng học) — 14 công trình còn lại cứ để mặt tiền đã.

### Công trình

| Công trình | Ô gốc (x, y) | Rộng × Cao | Tầng | Chức năng |
|---|---|---|---|---|
| Nhà B | 1, 1 | 8 × 12 | T1–T2 hành chính · T3+ học & thi | Xử lý giấy tờ sinh viên · học môn liên quan · **thi trắc nghiệm** |
| Phòng bảo vệ | 17, 1 | 4 × 4 | 1 | Nhận thông báo, nhận thư |
| Nhà để xe | 32, 3 | 26 × 7 | 1 | Trông xe (làm thêm), nơi bắt đầu buổi sáng |
| Khu phòng các khoa | 2, 14 | 9 × 5 | 1–2 | Văn phòng khoa — đăng ký môn, xin giấy tờ |
| Nhà A — cánh trái | 14, 11 | 5 × 11 | 2+ | Phòng học lý thuyết |
| **Nhà A — thanh giữa** | 18, 15 | 14 × 4 | 1 | **Thư viện** (nằm ở giữa) + phòng quản trị server trường |
| Nhà A — cánh phải | 30, 11 | 5 × 11 | 2+ | Phòng học lý thuyết |
| Sân bóng | 38, 11 | 17 × 15 | — | Chạy bộ, bóng đá (sân trống, đi được) |
| Xưởng 1 | 2, 22 | 7 × 3 | 1 | Khoa thực hành · **làm bài tập lớn** |
| Xưởng 2 | 2, 26 | 7 × 3 | 1 | Khoa thực hành · làm bài tập lớn |
| Xưởng 3 | 2, 29 | 7 × 3 | 1 | Khoa thực hành · làm bài tập lớn |
| Xưởng 4 | 2, 32 | 7 × 3 | 1 | Khoa thực hành · làm bài tập lớn |
| Đài phun nước | 23, 22 | 2 × 2 | — | Vật cản, chỗ hẹn |
| Hội trường | 16, 26 | 16 × 5 | 1 | **Sự kiện lớn**: nhập học, tốt nghiệp, ngày lễ, cuộc thi, hội nghị · đăng ký CLB |
| Phòng thể thao | 16, 32 | 16 × 4 | 1 | Chạy bộ, bóng rổ |
| Kí túc xá A | 37, 26 | 9 × 4 | nhiều tầng | 4 người/phòng · **đắt nhất, tiện nghi nhất** |
| Kí túc xá B | 48, 27 | 9 × 3 | nhiều tầng | 4 người/phòng · giá vừa |
| Kí túc xá C | 49, 30 | 10 × 3 | nhiều tầng | 4 người/phòng · **rẻ nhất, xa nhất** |
| Căng tin + Phòng CTSV | 37, 30 | 10 × 4 | 1 | Ăn uống + **phòng công tác sinh viên** (việc lặt vặt) |
| Khu quy hoạch (trống) | 59, 25 | 4 × 10 | — | Để dành học kỳ sau |

### Đường đi

| Trục | Ô gốc | Rộng × Cao |
|---|---|---|
| Dọc từ cổng chính | 22, 1 | 2 × 14 |
| Ngang trái | 1, 19 | 13 × 2 |
| Dọc trái | 11, 19 | 2 × 16 |
| Dọc giữa (Nhà A → Hội trường) | 20, 21 | 2 × 5 |
| Dọc phải | 35, 19 | 2 × 16 |
| Ngang dưới | 35, 34 | 24 × 1 |
| Ngang phải | 55, 18 | 8 × 2 |
| Dọc KTX B | 56, 20 | 2 × 7 |

**Cổng:** chính ở trên (22–23, hàng 0) · phụ 1 bên trái (cột 0, hàng 19–20) · phụ 2 bên phải (cột 63, hàng 18–19)

**Điểm đặc biệt:** Nhà A nối 2 cánh đông và tây qua sảnh thư viện tầng 1, là điểm hội tụ trung tâm của trường và là nơi lý tưởng để đặt các sự kiện gặp gỡ NPC (người chơi vẫn có thể đi đường vòng quanh sân ngoài trời).

### Vật thể tương tác — theo quyết định ở trên

**Ngoài trời** (đặt trong `campus.tscn`, được `CampusMap.validate()` kiểm tra):

| Vật thể | Ô | Hoạt động |
|---|---|---|
| Sân bóng | 45, 18 | `exercise` |
| Ô kề đài phun nước | 23, 23 | chỗ hẹn, chưa cần tương tác |

**Trong nhà** — mỗi cái thuộc một **scene nội thất**, validator ngoài trời không kiểm tra:

| Scene nội thất | Vật thể | Hoạt động |
|---|---|---|
| `ktx_a_t1.tscn` | Giường · Bàn học · Máy bán nước | `sleep` · `study` · `snack` |
| `ktx_a_t1.tscn` | 4 cửa phòng (cần 2–4 tim mới vào) | `visit_room` |
| `cang_tin.tscn` | Khay cơm · Quầy công tác sinh viên | `eat` · `paperwork` |
| `nha_a_t1.tscn` | Kệ sách (thư viện) · Phòng quản trị server · Cầu thang | `study` · `it_job` · `go_upstairs` |

Ô đứng bấm `E` để vào mỗi công trình: xem `CampusMap.door_approach(door_id)` — nó tự tìm ô trống kề bên cửa, không cần nhớ tay.

### Code dựng lưới

> ✅ **Toàn bộ code bản đồ chính thức được lưu và bảo trì duy nhất tại [`scripts/world/campus_map.gd`](../scripts/world/campus_map.gd)** (đã kiểm tra validator chạy sạch 15/15 cửa). 
> Đã xoá bỏ khối code trùng lặp ở đây để tránh lệch phiên bản giữa file tài liệu và mã nguồn thật.
>
> Chạy kiểm tra bất cứ lúc nào bằng Godot:
> ```bash
> godot --headless --path <thu-muc-project> --script res://tools/check_map.gd
> ```

---

## CƠ CHẾ BỔ SUNG (từ chú thích của bạn)

Bạn chú thích 7 điều. **Ba điều đầu làm thay đổi kiến trúc**, còn lại chỉ là nội dung.

### A. Nhà nhiều tầng — THAY ĐỔI KIẾN TRÚC ⚠️

- **Nhà A**: tầng 1 = thư viện (ở giữa) + phòng quản trị server trường · tầng 2 trở lên = phòng học lý thuyết
- **Nhà B**: tầng 1–2 = xử lý giấy tờ sinh viên · tầng 3 trở lên = học môn liên quan + **thi trắc nghiệm**
- **Ký túc xá**: nhiều tầng, mỗi phòng 4 người

**Cách làm — mỗi tầng là MỘT SCENE RIÊNG.** Cầu thang là một `Interactable` gọi chuyển scene.

```
scenes/world/nha_a_t1.tscn   <- thư viện + server
scenes/world/nha_a_t2.tscn   <- phòng học lý thuyết
scenes/world/nha_b_t1.tscn   <- hành chính
scenes/world/ktx_a_t1.tscn   <- hành lang + 4 cửa phòng
```

- Đừng làm hệ thống camera nhiều tầng trong cùng một map — phức tạp gấp 5 lần mà nhìn không đẹp hơn.
- Quy ước: ô cầu thang lên và cầu thang xuống **đặt cùng toạ độ** ở hai scene, để quay lại là đứng đúng chỗ.
- `SceneRouter` cần nhớ "cửa quay lại" để khi xuống thang không bị teleport về cổng trường.

**Việc cần làm:** xem mục 1.8 ở Giai đoạn 1.

---

### B. Ký túc xá: tiền thuê theo tháng + 4 người/phòng

Tháng game = 4 tuần = 28 ngày. Ngày 1 mỗi tháng tự trừ tiền thuê.

| KTX | Giá/tháng | Mức sống | Hồi sức lực | Hồi tinh thần/ngày | Vị trí |
|---|---|---|---|---|---|
| A | 1.200.000 đ | Khu giàu | ×1.0 | +8 | Cạnh căng tin, sân bóng |
| B | 800.000 đ | Bình thường | ×0.8 | +4 | Giữa trường |
| C | 500.000 đ | Khu nghèo | ×0.6 | +1 | Sát KTX B, xa giảng đường nhất |

Cả ba đều **4 người/phòng**. Khác nhau ở **mức sống**, và mức sống ảnh hưởng thẳng tới tốc độ hồi sức lực + tinh thần.

- Không đủ tiền → **nợ 1 tuần**; quá hạn thì bị mời xuống KTX rẻ hơn (mất quan hệ với bạn cùng phòng).
- Ở KTX C lâu mà ăn uống qua loa thì **sức khỏe tụt** — áp lực thật của sinh viên nghèo.
- **Vào phòng người khác cần 2–4 tim** tuỳ người. Phòng mình thì vào thẳng.
- Người chơi **đổi được KTX** — đây là quyết định thật: đắt thì tiện nhưng cháy túi.

**Việc cần làm:**
- [ ] `HousingSystem` (autoload): KTX hiện tại, giá thuê, ngày trừ tiền, số ngày nợ
- [ ] Lưu phần này vào `SaveSystem`
- [ ] `DoorLock` kế thừa `Interactable`, thêm `@export var min_hearts: int = 2`
- [ ] Màn hình chọn KTX lúc nhập học (ngày đầu game)

---

### C. Tim & quan hệ (điều kiện mở cửa phòng)

- `RelationshipSystem` (autoload): điểm tim 0–10 cho mỗi NPC
- Nguồn tăng tim: nói chuyện hằng ngày · tặng quà đúng sở thích · cùng sinh hoạt CLB · giúp làm bài tập
- Ngưỡng gợi ý: **2 tim** = vào được phòng · **4 tim** = mở sự kiện riêng · **6 tim** = nhờ vả được (mượn đồ, nhờ chép bài)

**Việc cần làm:**
- [ ] `RelationshipSystem` + lưu vào save
- [ ] NPC bạn cùng phòng (3 người) là 3 NPC đầu tiên được làm

---

### D. Nội dung từng công trình — dùng lại cơ chế có sẵn

| Công trình | Làm gì | Cơ chế |
|---|---|---|
| Nhà A — thanh giữa, T1 | Thư viện | `study` — học hiệu quả cao hơn tự học ở phòng |
| Nhà A — thanh giữa, T1 | Phòng quản trị server | `it_job` — làm thêm lương cao, yêu cầu GPA ≥ 2.5 |
| Nhà A — T2+ | Phòng học lý thuyết | `attend_lecture` |
| Nhà B — T1, T2 | Xử lý giấy tờ sinh viên | `paperwork` — đăng ký môn, gia hạn thẻ, xin xác nhận |
| Nhà B — T3+ | **Thi trắc nghiệm** | `exam` — mở minigame trắc nghiệm |
| Hội trường | Sự kiện lớn + đăng ký CLB | `club` + sự kiện theo lịch (nhập học, tốt nghiệp, lễ, cuộc thi) |
| Xưởng 1–4 | Khoa thực hành, bài tập lớn | `project_work` — tốn nhiều giờ, điểm cao |
| Phòng CTSV | Việc lặt vặt | `paperwork` loại nhỏ (mượn thiết bị, xin xác nhận) |
| Căng tin | Ăn uống | `eat` |
| Ký túc xá | Ở, học, ngủ, thăm phòng | `sleep` · `study` · `snack` · `visit_room` |

**Hoạt động mới cần thêm vào `data/activities/`:** `paperwork`, `exam`, `it_job`, `project_work`, `visit_room`, `gym` — 6 file `.tres`, copy từ `study.tres` rồi sửa số.

**Hoạt động đánh đổi — tăng cái này phải giảm cái kia:**

| Hoạt động | Được | Mất |
|---|---|---|
| Ngủ sớm | +tinh thần, +sức khỏe | mất buổi tối để học |
| **Thức khuya** | +học lực, +trí tuệ | −sức khỏe, −tinh thần, sáng sau −sức lực |
| **Tập gym** (90 phút) | +sức khỏe | −sức lực nhiều, −thời gian |
| Nhịn ăn tiết kiệm | +tiền | −sức khỏe, −tinh thần |

Không có hoạt động đánh đổi thì người chơi chỉ cần bấm nút tối ưu — không cần suy nghĩ.

**Môn thi trắc nghiệm ở Nhà B chính là chỗ dùng minigame đầu tiên** — giai đoạn 4 làm minigame, giai đoạn 2 chỉ cần chỗ đặt.

**Quán gym** nằm **ngoài trường**, mở cùng lúc với cổng trường (sau tuần 2) — đây là lý do để người chơi ra ngoài.

---

### E. Câu lạc bộ — 4 CLB

| CLB | Tăng mạnh | Nhiệm vụ tuần (ví dụ) |
|---|---|---|
| Âm nhạc | Tinh thần, quan hệ | Tập nhạc, biểu diễn ở hội trường |
| Truyền thông | Trí tuệ, quan hệ | Chụp ảnh sự kiện, viết bài cho trường |
| Thể thao | Sức khỏe, sức lực | Giải bóng, chạy bộ |
| Thể thao điện tử | Tinh thần, trí tuệ | Giải đấu, luyện tập |

- Gia nhập **một CLB** ở Hội trường. Đổi CLB được nhưng **mất hết tiến độ** ở CLB cũ.
- **Mỗi tuần CLB giao nhiệm vụ.** Làm càng nhiều → càng nhiều **tim**, thưởng ít **tiền** hoặc **điểm rèn luyện**.
- Bỏ nhiệm vụ nhiều tuần liền → bị mời ra khỏi CLB.

**Việc cần làm:**
- [ ] `ClubSystem` (autoload): CLB hiện tại, danh sách nhiệm vụ tuần, số nhiệm vụ đã xong
- [ ] 4 file `data/clubs/*.tres` — tên CLB, buff, danh sách nhiệm vụ
- [ ] Bảng nhiệm vụ tuần hiển thị trong **điện thoại**
- [ ] Thưởng: cộng tim cho thành viên CLB + cộng điểm rèn luyện

---

### F. Điện thoại — màn hình trung tâm

Mở bằng `Tab`. **Làm sớm**, vì điểm rèn luyện / học phí / CLB / bản đồ đều cần chỗ hiển thị. Làm 8 menu rải rác sẽ tốn thời gian gấp nhiều lần.

| Tab | Nội dung |
|---|---|
| **Bản đồ** | Bản đồ trường + vị trí mình + phòng học kế tiếp |
| Điểm học tập | Điểm từng môn |
| Điểm rèn luyện | Điểm rèn luyện học kỳ này |
| Điểm tích luỹ | Số tín chỉ đã qua |
| Điểm trung bình | GPA |
| **Học phí** | Đóng học phí theo học kỳ — **trễ hạn thì bị cấm thi** |
| Đặt hàng online | Gọi đồ ăn giao tới, tốn thêm phí giao |
| Tin nhắn | NPC hẹn gặp, CLB nhắc nhiệm vụ, trường báo lịch thi |

**Việc cần làm:**
- [ ] `PhoneUI` (`CanvasLayer`): mở/đóng bằng `Tab`, khoá điều khiển người chơi khi mở
- [ ] Tab Bản đồ: vẽ lại `CampusMap` thu nhỏ + chấm vị trí người chơi
- [ ] Các tab còn lại: chỉ đọc số từ autoload, chưa cần logic
- [ ] `TuitionSystem`: học phí mỗi học kỳ, hạn đóng, hình phạt trễ hạn
- [ ] Đặt hàng online: chọn món → trừ tiền → hẹn giờ giao → nhận hàng

---

### G. Khu vực & nhiệm vụ theo khu

Người chơi đi lại tự do nhưng **giới hạn trong các khu đã mở**. Mỗi khu có nhiệm vụ riêng.

| Khu | Mở khi | Nhiệm vụ |
|---|---|---|
| Khu học (Nhà A, Nhà B, Xưởng 1–4) | Mặc định | Dự giờ, thi, bài tập lớn, giấy tờ |
| Khu ở (KTX A/B/C) | Mặc định | Ngủ, quan hệ bạn cùng phòng, thăm phòng |
| Khu ăn uống (Căng tin) | Mặc định | Ăn, làm thêm giờ cao điểm |
| Khu thể thao (Sân bóng, P. thể thao) | Mặc định | Chạy bộ, CLB thể thao |
| Khu hành chính (Nhà B T1–2, P. CTSV) | Mặc định | Giấy tờ, học phí |
| Khu sự kiện (Hội trường) | Mặc định | Sự kiện lớn theo lịch |
| **Cổng trường** | **Sau tuần 2** | Ra ngoài: quán cà phê, làm thêm, mua sắm |

Cổng trường mở sau tuần 2 là **van tiết chế nội dung** — làm quen trong trường trước, rồi mới mở thế giới ngoài.

**Việc cần làm:**
- [ ] `Zone` (`Area2D`) đặt ở lối vào từng khu, phát signal khi người chơi vào/ra
- [ ] `QuestSystem`: mỗi khu có danh sách nhiệm vụ riêng
- [ ] Cổng trường khoá bằng cờ `unlocked_zones` lưu trong save

---

### H. Mốc chỉ số, ngưỡng sàn & nhánh kỹ năng

| Mốc | Nhận được |
|---|---|
| 10, 20, 30, 40, 60, 70, 80, 90 | Thưởng nhỏ tự động — +5% hiệu quả hành động liên quan |
| **50** | **Chọn 1 trong 2 nhánh** (giống Stardew level 5) |
| **100** | **Chọn 1 trong 2 bậc thầy** trong nhánh đó (giống level 10) |

**Đừng cho chọn nhánh ở cả 10 mốc** — 5 chỉ số × 10 mốc = 50 lần chọn, người chơi sẽ bấm đại. Chỉ 50 và 100 mới cho chọn; các mốc còn lại thưởng tự động.

**Ngưỡng sàn:** đã chạm mốc 10 thì chỉ số **không tụt xuống dưới mốc đó nữa**.

> ⚠️ **Mốc ≠ sàn & Phân biệt Trạng thái vs EXP tích lũy (Cập nhật theo GDD 3.2c):**
> - Thanh **Sức khỏe** và **Tinh thần** trên HUD là **trạng thái sinh tồn hằng ngày** (khởi đầu 80, biến động liên tục, không có sàn, không gắn trực tiếp mốc chọn perk 50/100 để tránh nghịch lý max nhánh ngay tuần 1).
> - Hai nhánh perk lối sống tương ứng là **Thể chất (Fitness EXP)** và **Bản lĩnh (Resilience EXP)**, tích luỹ kinh nghiệm dài hạn từ 0/10 qua các hoạt động rèn luyện lâu dài (chạy bộ, tập gym, ăn đúng bữa, sinh hoạt CLB, vượt qua kỳ thi).

| Chỉ số | Có mốc 10? | Có sàn? | Lý do |
|---|---|---|---|
| Trí tuệ · Học lực · Kĩ năng chuyên ngành | **Có** | **Có** | Kỹ năng dài hạn, công sức bỏ ra không bao giờ bị xoá sạch |
| Thể chất · Bản lĩnh (Lifestyle EXP) | **Có** (nhánh 50/100) | **Có** | EXP tích luỹ dài hạn lối sống, không bị tụt mốc |
| Sức khỏe · Tinh thần (Thanh trạng thái) | Không | **Không** | Trạng thái ngắn hạn phải tụt tự do được — có sàn thì không bao giờ ốm nặng hay trầm cảm |
| **Sức lực** | Không | Không | Thanh tiêu hao **trong ngày**, hồi mỗi sáng. Có sàn thì không bao giờ hết sức để phải đi ngủ → vòng lặp ngày/đêm sụp đổ |
| Tiền | Không | Không | Không phải chỉ số 0–100 |

### ⚠️ CHÚ Ý KHI CODE — chỗ này dễ làm sai nhất

`PlayerStats.apply_effects()` **không được** chỉ làm `clampf(value, 0, 100)`. Phải kẹp theo **sàn động**:

```gdscript
# SAI — mất sạch luật sàn
stat = clampf(stat + delta, 0.0, 100.0)

# ĐÚNG — sàn = mốc 10 lớn nhất đã từng đạt
# Chú ý: phải ghi rõ kiểu int, đừng dùng := vì .get() trả về Variant
var floor_of_stat: int = highest_milestone.get(stat_name, 0)
stat = clampf(stat + delta, float(floor_of_stat), 100.0)
```

Nghĩa là `PlayerStats` phải nhớ thêm một Dictionary `highest_milestone` cho từng chỉ số.

Chỉ 3 chỉ số kỹ năng (trí tuệ, học lực, kĩ năng chuyên ngành) có sàn. Sức lực, sức khỏe, tinh thần, tiền tra `get()` không thấy key thì sàn = 0 — nên **đừng ghi key cho chúng**, để mặc định 0 là đúng.

> 🔴 **Và Dictionary đó BẮT BUỘC phải vào file save.**
>
> Nếu quên, luật sàn sẽ "chạy đúng" ở lần chơi đầu rồi **mất sạch sau khi tải game**. Đây là loại lỗi rất khó tìm: test nhanh trong editor thì không thấy gì, chỉ hiện ra sau khi save rồi load lại. Hãy thử ngay từ lúc làm `SaveSystem`, đừng để tới cuối dự án.

**Việc cần làm:**
- [ ] `StatMilestones` (autoload hoặc nằm trong `PlayerStats`): theo dõi mốc 10 lớn nhất từng chỉ số đã đạt
- [ ] `PlayerStats.apply_effects()` kẹp theo sàn động — **xem khối chú ý ngay trên**
- [ ] `highest_milestone` vào `to_dict()` / `from_dict()` của `PlayerStats`
- [ ] **Test ngay**: đạt mốc 20 → save → load → thử tụt xuống dưới 20 xem có bị chặn không
- [ ] `data/perks/*.tres`: mỗi nhánh một file — tên, mô tả, hiệu ứng, chỉ số yêu cầu
- [ ] Màn hình chọn nhánh khi đạt 50 / 100, **không cho đổi lại**
- [ ] Lưu `perk_choices` vào save

---

### I. Điểm môn — khoá vĩnh viễn, học lại hè tối đa 8

1. **Điểm môn không bao giờ đổi** sau khi đã có.
2. **Trượt** (dưới 4/10) thì **hè được học lại**.
3. **Điểm học lại tối đa 8/10**, dù thi được 10.

Thang điểm **10** (không phải 4). Điểm trung bình hiển thị cả hệ 10 và hệ 4.

Luật 3 khiến **một môn trượt kéo GPA xuống vĩnh viễn** — người chơi phải chọn học kỳ nào dồn sức, học kỳ nào hy sinh.

**Việc cần làm:**
- [ ] `ExamSystem`: chốt điểm cuối môn, khoá vĩnh viễn, không cho ghi đè
- [ ] `SummerRetake`: học lại hè, `min(diem_thi, 8.0)`
- [ ] Cờ `is_retake` trên môn để hiện dấu "học lại" trong bảng điểm điện thoại

---

### J. Ảnh hưởng tới lộ trình

| Giai đoạn | Thay đổi |
|---|---|
| 1 (khung) | `PlayerStats` **7 chỉ số** (sức lực là thanh trong ngày, 6 cái còn lại là chỉ số dài hạn) · thêm **1.8 Nhà nhiều tầng** (chỉ cần 2 tầng Nhà A để thử) |
| 2 (học vụ) | `HousingSystem` (tiền thuê + mức sống) · `TuitionSystem` (học phí) · **`ExamSystem` + luật điểm môn** |
| 2 (học vụ) | **Mốc chỉ số + ngưỡng sàn** — làm sớm, vì mọi hoạt động đều phải kẹp theo sàn |
| 3 (con người) | Tim là **điều kiện mở cửa phòng** → làm cùng lúc với NPC · **`PhoneUI`** |
| 4 (minigame) | Minigame thi trắc nghiệm (Nhà B T3+) · **`ClubSystem` + nhiệm vụ tuần** · **chọn nhánh ở mốc 50 và 100** |
| 5 (polish) | Tab Bản đồ trong điện thoại · `Zone` + `QuestSystem` · **quán gym ngoài trường** |

---

## Addon — trả lời câu hỏi "không có plugin nào giúp làm 2D dễ hơn à?"

**Có, nhưng không có cái nào làm hộ bạn game life-sim.** Godot cố tình không có "framework làm game" kiểu RPG Maker. Các addon chia làm 3 nhóm:

**Nhóm 1 — giúp thật, cài ngay khi tới phần đó:**

| Addon | Giúp được gì | Cài khi nào |
|---|---|---|
| **Dialogue Manager** (nathanhoad) | Hội thoại có nhánh, điều kiện, gõ chữ dần. Tự viết cái này mất 1–2 tuần | Giai đoạn 3 |
| **Phantom Camera** (ramokz) | Camera 2D mượt, giới hạn theo phòng, rung, zoom | Giai đoạn 5 |
| **Aseprite Wizard** | Kéo `.aseprite` vào là có animation, khỏi export tay | Khi bắt đầu vẽ art |
| **gloot** (peter-kish) | Inventory dạng ô, kéo thả, stack | Khi cần túi đồ |
| **Beehave** | Behavior tree cho NPC có lịch sinh hoạt | Giai đoạn 3 |
| **Sound Manager** (nathanhoad) | Quản lý bus âm thanh, nhạc chuyển theo khu vực | Giai đoạn 5 |
| **GUT** hoặc **gdUnit4** | Viết test tự động | Khi logic phức tạp |

**Nhóm 2 — Godot đã có sẵn, KHÔNG cần addon:**
`TileMapLayer` + TileSet terrain (autotile) · `NavigationRegion2D` (NPC tự tìm đường) · `AnimationTree` · `Resource` (làm database nội dung) · `Area2D` (tương tác) · `CanvasLayer` + Control (UI) · `AudioStreamPlayer`

**Nhóm 3 — thứ bạn đang tìm nhưng không tồn tại:**
Một addon kiểu "Stardew Valley framework". Không có, vì mỗi game life-sim có luật chơi khác nhau. Cái bạn cần là **asset pack** (đồ hoạ) chứ không phải plugin code.

**Kết luận:** 90% công sức nằm ở hệ thống thời gian + nội dung, không phải ở plugin. Giai đoạn 1 nên làm **không cần addon nào**.

---

## Nguồn học

- **Coding Quests** — series "Stardew Valley clone in Godot 4" trên YouTube: sát nhất với thứ bạn đang làm
- **Godot Docs** — mục "Your first 2D game" nếu chưa quen editor
- **GDQuest** — giải thích `Resource`, signal, autoload rất rõ

---

## Việc KHÔNG nên làm ở giai đoạn đầu

- Không làm 8 địa điểm ngay — chỉ 1 khu trường
- Không làm NPC trước khi xong đồng hồ + hoạt động
- Không vẽ art trước khi gameplay chạy được
- Không cài 7 addon cùng lúc — mỗi lúc cài 1 cái khi thật sự cần
- Không dùng bản Godot dev/unstable — addon sẽ không cài được
