# Driver Brother HL-2240 / HL-2240D cho macOS (Apple Silicon)

Brother không còn driver cho HL-2240 trên macOS mới. Máy này dùng ngôn ngữ
**HBP** (host-based), không có PCL/PostScript, nên AirPrint/Generic không in được.

Project này build driver mã nguồn mở [brlaser](https://github.com/pdewacht/brlaser)
(GPL-2, bản copy trong `vendor/brlaser`) thành binary native arm64 + x86_64,
kèm PPD riêng cho HL-2240D (`hl2240d.drv`).

## Cách hoạt động

```
App → PDF → cgpdftoraster (macOS) → rastertobrlaser (driver này) → USB → máy in
```

- Filter: `/Library/Printers/Brother-HL2240-brlaser/rastertobrlaser`
  (`/usr/libexec/cups/filter` bị SIP khoá nên PPD trỏ đường dẫn tuyệt đối)
- PPD: `/Library/Printers/PPDs/Contents/Resources/Brother HL-2240D brlaser.gz`

## Cài đặt

Cần Xcode Command Line Tools (`xcode-select --install`). Cắm USB, bật máy in.

```bash
./build.sh
```

```bash
sudo ./install.sh
```

Sau đó in từ bất kỳ app nào, chọn **Brother HL-2240D**.

## Đóng gói cho máy khác

```bash
./make-pkg.sh
```

Ra `dist/Brother-HL2240D-Driver.zip` gồm file cài `.pkg` (bấm đúp để cài,
không cần Xcode), `uninstall.sh`, `HUONG-DAN-CAI-DAT.txt`, giấy phép GPL.
Gói chưa ký nên lần đầu mở phải vào Privacy & Security bấm "Open Anyway".

## Tuỳ chọn

- Độ phân giải: 600 dpi (mặc định) / 1200HQ
- Tiết kiệm mực: `Toner save mode`
- In 2 mặt: chỉ bản **HL-2240D** có bộ đảo mặt. Bản HL-2240 thường để tắt.

## Gỡ cài đặt

```bash
sudo ./uninstall.sh
```

## Xử lý sự cố

- Xem log: `log show --last 5m --predicate 'process == "cupsd"'` hoặc
  `/var/log/cups/error_log` (bật debug: `cupsctl --debug-logging`).
- Đèn Error nháy sau khi gửi lệnh in: thử bỏ chọn 1200HQ, in lại ở 600 dpi.
