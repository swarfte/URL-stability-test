# URL 穩定性測試 App — Product & Technical Specification

**文件版本：**  1.0
**文件日期：**  2026-07-13
**目標平台優先次序：**  Android → Windows → macOS
**技術框架：**  Flutter / Dart
**UI 風格：**  Apple-inspired，以 Flutter Cupertino widgets 為主要元件
**文件用途：**  交付 Coding Agent 實作第一階段 MVP

---

## 1. 產品概述

### 1.1 產品目標

開發一款跨平台 URL 穩定性測試工具，讓用戶輸入指定的 HTTP/HTTPS URL，按指定次數順序發出 GET request，再顯示：

- 每次 request 的延遲
- 平均延遲
- 中位數
- 最快及最慢延遲
- P95
- Jitter
- 成功率
- Timeout 次數
- HTTP 錯誤
- 網絡及 TLS 錯誤
- 測試過程及延遲走勢

本階段只實作 URL 穩定性測試，不包含上傳／下載速度測試。

### 1.2 產品定位

此 App 是一般網絡診斷工具，測量：

> 從目前裝置到指定 URL 的完整 HTTP 回應時間及連線穩定性。

此 App 不等同：

- ICMP Ping 工具
- Traceroute 工具
- 電訊商級 Speedtest
- SLA 認證工具
- 網站壓力測試工具
- 安全掃描工具

---

## 2. 開發原則

### 2.1 純 Flutter 實作

本階段應以 Flutter／Dart 前端直接向用戶指定的 URL 發出 request：

```text
用戶裝置 → 目標 URL
```

不需要：

- 自建後端
- Proxy Server
- 用戶帳戶
- 雲端資料庫
- 遠端設定服務

Flutter 官方建議可透過 `package:http` 處理跨平台 HTTP request；Android 需要 Internet permission，macOS 需要 network client entitlement。 [\[docs.flutter.dev\]](https://docs.flutter.dev/cookbook/networking/fetch-data)

### 2.2 目標平台

第一階段正式支援：

1. Android
2. Windows
3. macOS

Web、iOS 和 Linux 不屬於本階段交付範圍。

### 2.3 UI 設計方向

整個 App 應使用 Apple-inspired 視覺風格，主要使用：

- `CupertinoApp`
- `CupertinoPageScaffold`
- `CupertinoNavigationBar`
- `CupertinoFormSection.insetGrouped`
- `CupertinoFormRow`
- `CupertinoTextFormFieldRow`
- `CupertinoButton`
- `CupertinoSlidingSegmentedControl`
- `CupertinoActivityIndicator`
- `CupertinoAlertDialog`
- `CupertinoIcons`

Flutter 的 Cupertino library 提供 Apple iOS 設計語言元件，而 Cupertino widget catalog 亦包含適用於 iOS 和 macOS 風格的表單、按鈕、分段選擇器及桌面文字選取元件。 [\[docs.flutter.dev\]](https://docs.flutter.dev/ui/widgets/cupertino), [\[docs.flutter.dev\]](https://docs.flutter.dev/ui/design/cupertino)

`CupertinoFormSection.insetGrouped` 應作為設定頁的主要表單容器，以建立圓角、分組和留白明確的 Apple-style 設定介面。 [\[api.flutter.dev\]](https://api.flutter.dev/flutter/cupertino/CupertinoFormSection-class.html)

---

## 3. Cupertino 跨平台設計決策

### 3.1 統一 Apple-inspired 外觀

Android、Windows 和 macOS 應維持一致的 Apple-inspired 外觀，不需要因 Android 而改用 Material Design。

但實作時必須保留各平台基本操作兼容性：

- Android 系統返回鍵必須正常運作
- Windows／macOS 支援滑鼠、鍵盤及視窗縮放
- 文字輸入必須支援滑鼠選取、複製和貼上
- 按鈕必須有 Hover、Pressed 及 Disabled 狀態
- Windows／macOS 不應依賴觸控手勢才能操作
- 所有功能必須能透過鍵盤完成

### 3.2 字體

不得硬性指定 Apple 的 SF Pro 字體，因為該字體在 Android 和 Windows 不一定存在。Flutter 官方亦指出，在 Android 使用 `CupertinoApp` 時，San Francisco 字體可能不可用並產生未定義的字體行為。 [\[api.flutter.dev\]](https://api.flutter.dev/flutter/cupertino/CupertinoApp-class.html)

字體策略：

- 跟隨各平台可用的系統字體
- 不將 SF Pro 字體打包進 App
- 數字結果可使用系統等寬字體或啟用 tabular figures
- 確保英文、繁體中文和數字均能正常顯示

### 3.3 頁面轉場

可以使用 Cupertino-style 頁面轉場，但必須確保：

- Android 系統返回鍵可返回上一頁
- Windows／macOS 可透過導覽列返回按鈕操作
- 不要求用戶使用 iOS edge-swipe 手勢
- 測試進行期間，返回操作必須觸發取消確認，不得直接遺失結果

`CupertinoApp` 會加入 iOS 風格的字體、滾動和頁面行為，因此 Coding Agent 必須特別測試 Android、Windows 和 macOS 的操作是否合適。 [\[api.flutter.dev\]](https://api.flutter.dev/flutter/cupertino/CupertinoApp-class.html)

---

# 4. 第一階段功能範圍

## 4.1 包含功能

MVP 必須包含：

- URL 輸入
- URL 格式驗證
- HTTPS 和 HTTP URL 支援
- 測試次數選擇
- 測試間隔選擇
- Timeout 選擇
- 正常連線模式
- 每次新連線模式
- Sequential request
- 取消測試
- 即時進度
- 暫時測試結果
- 完整測試結果
- Average、Median、Min、Max、P95、Jitter
- 成功率及錯誤分類
- 每次測試詳細資料
- 延遲走勢圖
- Light Mode
- Dark Mode
- Android／Windows／macOS 響應式介面
- 本機保存最近一次測試設定

## 4.2 不包含功能

本階段不得加入：

- 上傳速度測試
- 下載速度測試
- ICMP Ping
- Traceroute
- DNS-only 測試
- TCP-only 測試
- TLS-only 測試
- DNS、TCP、TLS、TTFB 分階段計時
- 多個 URL 同時測試
- 並發負載測試
- 後台定時測試
- 用戶帳戶
- 雲端同步
- 測試結果分享
- CSV、JSON 或 PDF 匯出
- 完整測試歷史
- Web 版本
- iOS 版本
- Linux 版本
- 自訂 HTTP Header
- Authentication
- Cookie 管理
- Proxy 設定
- 忽略無效 TLS 憑證
- App 內自動更新
- 「優秀／良好／差」主觀評級

---

# 5. 核心使用流程

```text
啟動 App
    ↓
進入「測試設定」頁
    ↓
輸入 URL
    ↓
選擇連線模式
    ↓
選擇測試次數、間隔和 Timeout
    ↓
按「開始測試」
    ↓
驗證設定
    ↓
進入「測試進行中」頁
    ↓
順序執行所有測試
    ↓
完成／取消／發生不可恢復錯誤
    ↓
進入「測試結果」頁
    ↓
再次測試／修改設定／返回首頁
```

---

# 6. 頁面與介面規格

## 6.1 頁面一：測試設定

### 6.1.1 頁面目的

讓用戶輸入 URL，並設定連線模式、測試次數、測試間隔及 Timeout。

### 6.1.2 導覽列

標題：

```text
URL 穩定性測試
```

右側可放置資訊按鈕：

```text
ⓘ
```

點擊後顯示 App 說明，包括：

- 本 App 使用 HTTP GET
- Delay 的定義
- 非 ICMP Ping
- 測試會對目標伺服器產生實際 request

### 6.1.3 頁面結構

```text
URL 穩定性測試

[測試目標]
測試 URL
https://example.com/health

[連線設定]
連線模式
[ 正常連線 | 每次新連線 ]

測試次數
[ 5 | 10 | 20 | 50 ]

測試間隔
1 秒 >

Timeout
10 秒 >

[開始測試]
```

### 6.1.4 URL 欄位

欄位標題：

```text
測試 URL
```

Placeholder：

```text
https://example.com/health
```

必須支援：

- 輸入
- 貼上
- 清除
- 複製
- 鍵盤 Enter
- 自動移除前後空格
- 顯示完整 URL
- 顯示 inline validation error

如果用戶輸入：

```text
example.com
```

App 應自動補充：

```text
https://example.com
```

但必須在畫面顯示轉換後的 URL。

如果用戶已輸入 `http://`，不得自動轉換成 `https://`。

### 6.1.5 URL 驗證規則

URL 必須：

- 可由 Dart `Uri` 正確解析
- Scheme 為 `http` 或 `https`
- 包含非空白 Host
- 不包含帳號密碼資訊
- 不接受 `file://`
- 不接受 `data:`
- 不接受 `ftp://`
- 不接受其他自訂 Scheme

錯誤訊息：

| 情況          | 顯示訊息                     |
| --------------- | ------------------------------ |
| 空白          | 請輸入測試 URL               |
| 無法解析      | URL 格式不正確               |
| 缺少 Host     | 請輸入完整 URL，例如[https://example.com](https://example.com/)         |
| Scheme 不支援 | 目前只支援 HTTP 和 HTTPS URL |
| 包含帳號密碼  | URL 不應包含帳號或密碼       |

### 6.1.6 HTTP URL 警告

用戶輸入 `http://` 時，顯示非阻擋式警告：

> 此 URL 使用未加密 HTTP 連線。部分平台或網絡可能會阻擋此連線。

用戶仍可嘗試開始測試。

---

## 6.2 連線模式

使用 `CupertinoSlidingSegmentedControl`，因為兩個模式互相排斥，而 Cupertino segmented control 專門用於互斥選項。 [\[api.flutter.dev\]](https://api.flutter.dev/flutter/cupertino/CupertinoSlidingSegmentedControl-class.html)

選項：

```text
正常連線
每次新連線
```

預設值：

```text
正常連線
```

### 6.2.1 正常連線模式

顯示說明：

> 整個測試共用同一個 HTTP Client，允許重用連線，較接近日常 App 或 API 使用情況。

行為：

- 測試開始時建立一個 HTTP Client
- 所有 request 共用該 Client
- 測試完成或取消後關閉 Client
- 第一次 request 可能包括 DNS、TCP 和 TLS 建立成本
- 後續 request 可能重用既有連線

內部 enum 建議名稱：

```text
ConnectionMode.reuseClient
```

### 6.2.2 每次新連線模式

顯示說明：

> 每次測試建立新的 HTTP Client，完成後立即關閉，盡量重新建立連線。

行為：

- 每次 request 前建立新的 Client
- request 完成、失敗或 Timeout 後關閉該 Client
- 下一次 request 使用新的 Client
- 不得宣稱此模式一定清除作業系統 DNS cache
- 不得宣稱一定建立全新的實體網絡路徑

內部 enum 建議名稱：

```text
ConnectionMode.newClientPerRequest
```

---

## 6.3 測試次數

使用 Cupertino segmented control。

選項：

```text
5
10
20
50
```

預設：

```text
10
```

本階段不提供自由輸入。

測試必須逐一順序執行，不得同時發出兩個或以上 request。

---

## 6.4 測試間隔

使用 `CupertinoPicker` 或 Cupertino-style popup selector。

選項：

```text
無間隔
0.5 秒
1 秒
2 秒
5 秒
```

預設：

```text
1 秒
```

間隔定義：

> 上一次 request 完成後，到下一次 request 開始前的等待時間。

如果 request 本身使用 3 秒，而間隔為 1 秒，則下一次 request 應在上一個 request 完成後再等待 1 秒，不是按照固定時鐘每 1 秒發出一次。

---

## 6.5 Timeout

使用 `CupertinoPicker` 或 Cupertino-style popup selector。

選項：

```text
3 秒
5 秒
10 秒
30 秒
```

預設：

```text
10 秒
```

Timeout 應套用至每一次獨立 request。

發生 Timeout 時：

- 將本次結果記錄為 `timeout`
- 停止／關閉本次 request 使用的 Client
- 不終止整個測試
- 等待指定測試間隔
- 繼續下一次測試

---

## 6.6 開始測試按鈕

文字：

```text
開始測試
```

按鈕狀態：

### Enabled

- URL 驗證通過
- 沒有正在進行測試

### Disabled

- URL 為空白
- URL 驗證失敗
- 測試正在進行

點擊後：

1. 收起鍵盤
2. 再次執行完整 URL 驗證
3. 保存本次設定
4. 建立測試 Session
5. 導航至測試進行中頁面
6. 開始第一個 request

---

# 7. 頁面二：測試進行中

## 7.1 導覽列

標題：

```text
測試進行中
```

測試期間不得提供普通返回操作直接離開。

如果用戶：

- 按 Android 返回鍵
- 點擊導覽列返回
- 關閉視窗
- 嘗試離開頁面

應顯示確認 Dialog：

```text
取消測試？

目前測試尚未完成。已完成的結果仍可保留。

[繼續測試] [取消測試]
```

Windows／macOS 關閉主視窗時，如無法可靠攔截視窗關閉事件，可直接終止測試並關閉資源；不得讓背景 request 繼續執行。

## 7.2 顯示內容

必須顯示：

- 測試 URL
- 連線模式
- 測試次數
- Timeout
- 已完成次數／總次數
- Progress bar
- 當前狀態
- 暫時統計
- 最近測試結果
- 取消按鈕

建議結構：

```text
https://example.com/health
正常連線 · 10 次 · Timeout 10 秒

6 / 10
[████████████░░░░░░░░]

正在等待下一次測試……

暫時結果
平均       86 ms
最快       62 ms
最慢      131 ms
成功率      83%

最近測試
#6  200  79 ms       成功
#5  200  102 ms      成功
#4  Timeout          超時

[取消測試]
```

## 7.3 當前狀態文字

狀態必須包含：

```text
準備測試……
正在執行第 1 次測試……
正在接收回應……
等待下一次測試……
正在取消……
測試完成
```

如果應用程式無法可靠分辨「正在連線」和「正在接收」，可統一顯示：

```text
正在執行第 N 次測試……
```

不得顯示無法真實判斷的 DNS、TCP 或 TLS 即時階段。

## 7.4 取消測試

按鈕文字：

```text
取消測試
```

點擊後顯示確認 Dialog。

確認取消後：

- 設定 cancellation flag
- 關閉目前可用的 HTTP Client
- 停止目前 request
- 取消等待中的 Timer
- 不再開始下一個 request
- 保留已完成的結果
- 導航到結果頁
- Session 狀態標記為 `cancelled`

如果沒有任何一次測試完成，結果頁仍須顯示：

```text
測試已取消，沒有可用結果。
```

---

# 8. HTTP 測試行為

## 8.1 Request Method

第一階段固定使用：

```http
GET
```

不提供 HEAD、POST、PUT、PATCH 或 DELETE。

## 8.2 Request Header

最少加入：

```http
Accept: */*
Cache-Control: no-cache
Pragma: no-cache
```

可設定清晰的 User-Agent，但必須符合各平台能力及套件限制。

若無法跨平台安全設定 User-Agent，可省略，不應因此阻擋測試。

## 8.3 Cache Busting

為減少代理層或伺服器快取對結果的影響，每次 request 可加入唯一 query parameter：

```text
_stability_test=<timestamp-or-uuid>
```

但這可能改變目標 URL 的伺服器行為，因此第一版應設計為：

- 預設不修改用戶 URL
- 只使用 `Cache-Control: no-cache`
- 結果頁記錄最終實際 URL

本階段不提供 Cache Busting UI 選項。

## 8.4 Redirect

允許自動跟隨 Redirect。

規則：

- 最多 5 次 Redirect
- 記錄 Redirect 次數
- 顯示最終 URL
- 超過 5 次分類為 `tooManyRedirects`
- Redirect 總時間計入本次 Delay

## 8.5 Delay 定義

本 App 的 Delay 定義為：

> 從 App 開始發出 HTTP GET request，到完整接收 Response Body，或確認 request 失敗為止的總經過時間。

計時必須使用 monotonic `Stopwatch` 類型機制，不得以系統時間差作為主要延遲計算方式。

計時開始點：

```text
即將送出 request 前
```

成功計時停止點：

```text
完整讀取 response stream 後
```

失敗計時停止點：

```text
Exception、Timeout 或取消被確認時
```

## 8.6 Response Body

Response Body 必須以 stream 方式讀取及計算 byte 數，不得為了計算大小而把完整 response 儲存在記憶體。

測試不需要：

- 解析 HTML
- 解析 JSON
- 顯示 Response Body
- 將 Response Body 寫入檔案

### 回應大小安全限制

單次 Response Body 最大接收：

```text
10 MiB
```

即：

```text
10 × 1,024 × 1,024 bytes
```

超過限制時：

- 停止讀取
- 關閉本次 Client
- 結果分類為 `responseTooLarge`
- 不將此結果計入成功延遲統計
- 詳細結果顯示已接收 bytes
- 繼續下一次測試

錯誤訊息：

> 回應內容超過 10 MiB 安全限制。建議使用輕量的 health-check URL。

---

# 9. 測試結果分類

每一次測試必須且只能屬於以下一個分類。

## 9.1 Success

條件：

- request 在 Timeout 前完成
- 完整 Response Body 已接收
- HTTP Status Code 為 `200–399`
- Response Body 未超過安全限制

結果欄位：

- `isSuccessful = true`
- 延遲納入統計

## 9.2 HTTP Error

條件：

- 已成功收到完整 HTTP Response
- Status Code 為 `400–599`

行為：

- 網絡連線視為已完成
- 產品成功率中視為失敗
- 延遲保留在詳細結果
- 延遲不納入主要成功延遲統計
- 顯示 HTTP Status Code

## 9.3 Timeout

條件：

- request 超過設定 Timeout

行為：

- 不納入延遲統計
- Timeout 計數加一
- 繼續下一次測試

## 9.4 DNS Error

條件：

- Host lookup 失敗
- 無法解析目標 Host

顯示：

```text
無法解析網域名稱
```

## 9.5 Connection Error

包括：

- Connection refused
- Network unreachable
- Connection reset
- Socket closed
- 沒有網絡連線

顯示通用訊息及可安全呈現的底層錯誤。

## 9.6 TLS Error

包括：

- TLS handshake 失敗
- 憑證過期
- 憑證 Host 不符
- 憑證鏈不受信任

不得加入「忽略 TLS 錯誤」功能。

## 9.7 Too Many Redirects

條件：

- Redirect 超過 5 次

## 9.8 Response Too Large

條件：

- Response Body 超過 10 MiB

## 9.9 Cancelled

條件：

- 用戶取消時正在進行的 request

被取消的 request 不計入已完成測試次數及所有統計。

## 9.10 Unknown Error

只用於不能分類的 Exception。

必須：

- 保留安全的技術錯誤描述
- 不顯示 Stack Trace 給一般用戶
- Debug build 可輸出完整 Stack Trace 至開發 Log

---

# 10. 統計規格

所有主要延遲統計只使用：

```text
TestResult.status == success
```

HTTP 4xx、5xx、Timeout、網絡錯誤及取消結果均不計入主要延遲統計。

延遲統一以：

```text
milliseconds
```

顯示。

內部應保留 microseconds，以避免過早捨入。

## 10.1 Average

```text
所有成功延遲總和 ÷ 成功次數
```

顯示為整數毫秒，四捨五入。

## 10.2 Minimum

所有成功結果中最小延遲。

## 10.3 Maximum

所有成功結果中最大延遲。

## 10.4 Median

先將成功延遲由小至大排列。

奇數筆：

```text
取中間值
```

偶數筆：

```text
取中間兩個值的平均
```

## 10.5 P95

使用 Nearest Rank 方法：

```text
rank = ceil(0.95 × N)
```

`N` 為成功結果數量。

將成功延遲由小至大排序後，取 `rank` 對應的值。

如果只有一個成功結果，P95 等於該結果。

## 10.6 Jitter

本版本將 Jitter 定義為：

> 按實際測試順序，所有相鄰成功結果延遲差的絕對值之平均。

公式：

```text
Jitter =
平均值(
  abs(success[1] - success[0]),
  abs(success[2] - success[1]),
  ...
)
```

失敗結果應從序列移除，再以相鄰的成功結果計算。

少於兩個成功結果時：

```text
Jitter = N/A
```

## 10.7 Success Rate

```text
成功次數 ÷ 已完成測試次數 × 100%
```

其中：

- 成功次數：HTTP 200–399 且完整接收 Body
- 已完成測試次數：不包括被取消而未完成的 request
- HTTP Error、Timeout、DNS、TLS 和連線錯誤均計入分母
- 如果沒有任何完成結果，顯示 `N/A`

## 10.8 無成功結果

如果沒有任何 Success：

```text
Average = N/A
Median = N/A
Minimum = N/A
Maximum = N/A
P95 = N/A
Jitter = N/A
```

不得顯示為 `0 ms`，因為 0 ms 會被誤解為實際測量結果。

---

# 11. 頁面三：測試結果

## 11.1 頁面狀態

Session 狀態：

```text
completed
cancelled
```

標題：

- 完成：`測試結果`
- 取消：`未完成的測試`

## 11.2 頂部摘要

顯示：

- 原始輸入 URL
- 最終 URL
- 測試完成時間
- 連線模式
- 已完成次數／設定總次數
- Session 狀態

範例：

```text
https://example.com/health
正常連線 · 完成 10 / 10 次
2026-07-13 11:30:42
```

日期及時間使用目前裝置的 Local Time。

## 11.3 主要指標

第一層顯示四個主要卡片：

```text
平均延遲
86 ms

成功率
90%

最快
62 ms

最慢
241 ms
```

第二層指標：

```text
Median     81 ms
P95       220 ms
Jitter     34 ms
成功       9 / 10
HTTP 錯誤  0
Timeout    1
其他錯誤   0
```

禁止根據延遲自動顯示：

```text
優秀
良好
一般
差
```

因為合理延遲視乎目標伺服器所在地及用途。

## 11.4 延遲走勢圖

本階段需要簡單折線圖。

X 軸：

```text
測試序號
```

Y 軸：

```text
延遲（ms）
```

圖表規則：

- Success：藍色實心點
- HTTP Error：橙色點
- Timeout：紅色叉號或缺口
- 其他網絡錯誤：紅色點
- 被取消的 request：不顯示
- 圖表必須有可辨識的軸標籤
- 不只依賴顏色表達狀態
- Hover 或點擊資料點可顯示 Tooltip
- Windows／macOS 支援滑鼠 Hover
- Android 支援點按

對於沒有可用延遲資料的結果，改為顯示：

```text
沒有可顯示的延遲資料
```

## 11.5 詳細結果列表

每一行顯示：

```text
#序號
狀態
HTTP Status
延遲
```

範例：

```text
#1  成功       200    72 ms
#2  成功       200    81 ms
#3  超時        —      —
#4  HTTP 錯誤  503    95 ms
#5  TLS 錯誤    —      —
```

點擊或按 Enter 展開詳細資料：

- 測試序號
- 開始時間
- 結束時間
- 經過時間
- 結果分類
- HTTP Status Code
- Response Size
- Redirect 次數
- 最終 URL
- 錯誤摘要
- 技術錯誤訊息

不得顯示：

- Response Body
- Cookie
- Authorization Header
- 其他敏感 Header
- Stack Trace

## 11.6 結果頁操作

頁面底部提供：

### 再次測試

```text
再次測試
```

行為：

- 使用完全相同設定
- 建立新 Session
- 不沿用之前的 Client
- 直接開始測試

### 修改設定

```text
修改設定
```

行為：

- 返回測試設定頁
- 保留目前 URL 和選項
- 不自動開始

---

# 12. 響應式介面

## 12.1 Android／窄視窗

當內容寬度小於約 720 logical pixels：

- 使用單欄排列
- 統計卡片使用 2 × 2 Grid
- 詳細結果置於圖表下方
- 主要按鈕接近全寬
- 表單保持適合觸控的高度

## 12.2 Windows／macOS／寬視窗

當內容寬度等於或大於約 720 logical pixels：

- 主內容限制最大寬度
- 設定頁最大寬度約 720 px
- 結果頁最大寬度約 1,200 px
- 結果頁可使用雙欄：

  - 左側：摘要及圖表
  - 右側：詳細結果
- 不得讓內容無限制延伸至整個超寬視窗
- 所有頁面應置中

## 12.3 最小視窗

Windows／macOS 建議最小視窗尺寸：

```text
寬度：700 px
高度：600 px
```

如果未使用視窗管理套件設定最小尺寸，介面至少要在：

```text
600 × 500
```

仍可滾動及操作，不得出現 overflow exception。

---

# 13. Theme 規格

## 13.1 Light Mode

建議使用：

- 頁面背景：`CupertinoColors.systemGroupedBackground`
- 卡片背景：`CupertinoColors.secondarySystemGroupedBackground`
- 主色：`CupertinoColors.activeBlue`
- 成功：`CupertinoColors.activeGreen`
- 警告：`CupertinoColors.systemOrange`
- 錯誤：`CupertinoColors.systemRed`
- 主要文字：`CupertinoColors.label`
- 次要文字：`CupertinoColors.secondaryLabel`

## 13.2 Dark Mode

必須使用 `CupertinoDynamicColor` 或可自動 resolve 的 Cupertino system colors，不應硬編碼只適合 Light Mode 的顏色。

Dark Mode 跟隨系統設定。

本階段不需要提供手動 Light／Dark 切換。

## 13.3 間距及圓角

建議：

- 頁面水平 Padding：16–24
- 桌面內容 Padding：24–32
- Section 間距：16–24
- 卡片圓角：10–14
- 主要按鈕高度：44–48
- 點擊區域最少：44 × 44

---

# 14. 鍵盤與桌面操作

Windows 和 macOS 必須支援：

| 操作                  | 鍵盤 |
| ----------------------- | ------ |
| 聚焦 URL 欄位         | `Ctrl+L`/`Cmd+L`    |
| 開始測試              | `Enter`     |
| 取消 Dialog／關閉詳情 | `Escape`     |
| 確認主要 Dialog       | `Enter`     |
| 控件導航              | `Tab`/`Shift+Tab`    |
| 操作聚焦項目          | `Space`/`Enter`    |
| 複製 URL              | `Ctrl+C`/`Cmd+C`    |
| 貼上 URL              | `Ctrl+V`/`Cmd+V`    |

要求：

- 所有可點擊元素必須可取得 Focus
- Focus 狀態必須可見
- 不得只支援 Hover 而不支援 Click
- Segmented control 必須支援鍵盤操作或提供等效 Focus 操作

---

# 15. Accessibility

必須支援：

- Android TalkBack
- macOS VoiceOver 基本朗讀
- Windows Narrator 基本朗讀
- 系統文字縮放
- 高對比下仍可辨識
- 不只依賴顏色顯示成功或失敗
- 進度更新提供合理 semantics
- 按鈕名稱清楚
- 圖表有文字摘要

當文字放大時：

- 表單不得截斷關鍵文字
- 統計卡片可增加高度
- 指標可換行
- 詳細結果列表可由單行改為雙行

---

# 16. 本機資料保存

本階段只保存最近一次測試設定：

- URL
- 連線模式
- 測試次數
- 測試間隔
- Timeout

不保存：

- Response Body
- Cookie
- Authentication 資料
- 完整測試歷史
- 錯誤 Stack Trace

App 再次開啟時，恢復上述最近設定。

第一個版本可以使用簡單 Key-Value local storage。

---

# 17. 資料模型

## 17.1 TestConfiguration

必須包含：

```text
url
connectionMode
testCount
interval
timeout
maxRedirects
maxResponseBytes
```

預設值：

```text
connectionMode = reuseClient
testCount = 10
interval = 1 second
timeout = 10 seconds
maxRedirects = 5
maxResponseBytes = 10 MiB
```

## 17.2 TestSession

必須包含：

```text
sessionId
configuration
startedAt
completedAt
status
results
```

Session Status：

```text
running
completed
cancelled
```

## 17.3 TestResult

必須包含：

```text
sequenceNumber
startedAt
completedAt
elapsedMicroseconds
status
httpStatusCode
responseBytes
redirectCount
originalUrl
finalUrl
errorType
errorMessage
```

`elapsedMicroseconds` 可為 null，例如 request 在開始前已被取消。

## 17.4 ResultStatus

```text
success
httpError
timeout
dnsError
connectionError
tlsError
tooManyRedirects
responseTooLarge
cancelled
unknownError
```

---

# 18. 建議程式架構

```text
lib/
├── app/
│   ├── app.dart
│   ├── routes.dart
│   └── theme.dart
│
├── features/
│   └── stability_test/
│       ├── models/
│       │   ├── connection_mode.dart
│       │   ├── test_configuration.dart
│       │   ├── test_result.dart
│       │   └── test_session.dart
│       │
│       ├── services/
│       │   ├── stability_test_service.dart
│       │   ├── statistics_service.dart
│       │   └── url_validation_service.dart
│       │
│       ├── controllers/
│       │   └── stability_test_controller.dart
│       │
│       ├── screens/
│       │   ├── test_setup_screen.dart
│       │   ├── test_progress_screen.dart
│       │   └── test_result_screen.dart
│       │
│       └── widgets/
│           ├── configuration_section.dart
│           ├── connection_mode_selector.dart
│           ├── progress_summary.dart
│           ├── statistics_cards.dart
│           ├── latency_chart.dart
│           └── result_list.dart
│
├── shared/
│   ├── storage/
│   ├── formatting/
│   ├── accessibility/
│   └── widgets/
│
└── main.dart
```

要求：

- UI 不得直接執行 HTTP request
- 統計計算不得寫在 Widget 中
- URL 驗證必須獨立
- HTTP 測試邏輯必須可進行 Unit Test
- Controller 管理 Session、Progress 和取消狀態
- Model 不得依賴 UI Widget

---

# 19. 狀態管理

本 Spec 不強制指定 Riverpod、Bloc 或其他狀態管理套件，但實作必須滿足：

- 單一明確的 Session State
- 防止重複開始測試
- UI 可即時接收每次 Result
- 支援取消
- Widget dispose 後不得繼續更新 UI
- 測試結束後正確釋放 Client、Timer 和 Stream
- 不得使用大量散落的 global variables

Coding Agent 可選擇：

- Riverpod
- Bloc/Cubit
- ChangeNotifier
- ValueNotifier

MVP 優先考慮可測試性和簡潔度。

---

# 20. 平台設定

## 20.1 Android

必須在 `AndroidManifest.xml` 加入：

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

Flutter 官方 networking recipe 明確要求 Android App 加入 Internet permission。 [\[docs.flutter.dev\]](https://docs.flutter.dev/cookbook/networking/fetch-data)

HTTP 明文連線可能受 Android Network Security Policy 影響。第一版應：

- 優先支援 HTTPS
- 不為所有 Domain 全域放寬明文安全設定
- 如 HTTP URL 被平台阻擋，顯示可理解錯誤
- 不關閉 TLS 驗證

## 20.2 Windows

要求：

- 可連接 HTTP／HTTPS URL
- Windows Firewall prompt 不應因普通 outbound request 而被主動要求
- 支援鍵盤及滑鼠
- 支援視窗縮放
- Release build 可正常運作

## 20.3 macOS

必須在 Debug 和 Release entitlement 加入：

```xml
<key>com.apple.security.network.client</key>
<true/>
```

Flutter 官方指出，Sandboxed macOS App 如需存取 Internet，必須設定相關 entitlement。 [\[docs.flutter.dev\]](https://docs.flutter.dev/platform-integration/macos/building/index.html.md), [\[docs.flutter.dev\]](https://docs.flutter.dev/cookbook/networking/fetch-data)

不得：

- 關閉 App Sandbox 以迴避問題
- 全域信任無效憑證
- 忽略 TLS 驗證

---

# 21. 錯誤訊息原則

一般用戶訊息必須：

- 清楚
- 簡短
- 可執行
- 不只顯示 Exception class name
- 不顯示 Stack Trace

範例：

| 技術情況           | 用戶訊息                                 |
| -------------------- | ------------------------------------------ |
| DNS lookup failed  | 無法解析網域名稱，請檢查 URL 或 DNS 連線 |
| Connection refused | 目標伺服器拒絕連線                       |
| No network         | 目前沒有可用的網絡連線                   |
| TLS failure        | 無法建立安全連線，目標憑證可能無效       |
| Timeout            | 連線超過設定的 Timeout                   |
| Too many redirects | URL 重新導向次數過多                     |
| Response too large | 回應內容超過 10 MiB 安全限制             |
| Unknown            | 測試時發生未預期錯誤                     |

詳細結果可額外顯示經過整理的技術訊息，但不得包含敏感資料。

---

# 22. 測試要求

## 22.1 Unit Tests

至少測試：

- URL 自動補上 HTTPS
- URL 空白
- 無效 Scheme
- 缺少 Host
- URL 包含帳號密碼
- Average
- Median 奇數
- Median 偶數
- Min／Max
- P95
- Jitter
- Success Rate
- 零成功結果
- 單一成功結果
- Timeout 分類
- HTTP 4xx／5xx 分類
- 取消狀態
- Response Body 大小限制

## 22.2 Service Tests

使用 Mock HTTP Client 測試：

- 正常連線共用 Client
- 每次新連線建立獨立 Client
- Sequential execution
- 指定測試間隔
- Timeout 後繼續下一次
- 錯誤後繼續下一次
- 取消後不再開始 request
- Redirect 上限
- Stream Body 完整讀取
- Response 超過 10 MiB
- Client 最終被關閉

## 22.3 Widget Tests

至少測試：

- URL 無效時按鈕 Disabled
- URL 有效時按鈕 Enabled
- 切換連線模式
- 選擇測試次數
- 進度更新
- 取消 Dialog
- 結果為空時顯示 N/A
- Result list 展開
- 窄屏沒有 overflow
- Dark Mode 主要內容可見

## 22.4 手動平台測試

在以下平台完成 Smoke Test：

- 實體 Android 裝置
- Windows 10 或 Windows 11
- macOS

測試 URL 場景：

- 正常 HTTPS URL
- HTTP 200
- HTTP 301／302
- HTTP 404
- HTTP 500
- 不存在 Domain
- Connection refused
- 無效 TLS
- 延遲超過 Timeout
- Response 超過 10 MiB
- 測試中途取消
- 測試中途斷網
- App 視窗縮放
- 系統 Dark Mode

---

# 23. 非功能要求

## 23.1 性能

- UI 在測試期間保持流暢
- HTTP stream 不得完整載入記憶體
- 50 次測試不應造成持續記憶體增長
- 測試完成後 Client 和 Timer 必須釋放
- 結果圖表在 50 個資料點時保持流暢

## 23.2 穩定性

- 單次 request 失敗不得令整個 App Crash
- 欄位錯誤不得導致 Exception
- 取消操作必須安全且可重複處理
- App 不得同時存在兩個運行中的 Session
- Widget dispose 後不得觸發 setState error

## 23.3 私隱

- URL 及測試結果只在本機處理
- 不傳送至開發者伺服器
- 不收集 Analytics
- 不收集 Response Body
- 不保存 Cookie
- 不記錄 Authentication 資料
- 本階段不要求任何裝置敏感權限

## 23.4 安全

- 不允許忽略 TLS 錯誤
- 不執行 Response Content
- 不渲染 HTML
- 不開啟 Response URL
- 不自動下載檔案
- 限制 Response Body 為 10 MiB
- 不支援 `file://` 等本機 Scheme
- 技術 Log 不得輸出 Response Body

---

# 24. MVP 驗收標準

Coding Agent 完成後，以下條件必須全部成立。

## 24.1 功能驗收

- [ ] 用戶可輸入 HTTP／HTTPS URL
- [ ] 無效 URL 不能開始測試
- [ ] 可選擇 5、10、20、50 次
- [ ] 可選擇正常連線或每次新連線
- [ ] 可選擇測試間隔
- [ ] 可選擇 Timeout
- [ ] 所有 request 順序執行
- [ ] 每次測試有獨立結果
- [ ] 單次失敗後可繼續下一次
- [ ] 用戶可取消測試
- [ ] 取消後不再發出新 request
- [ ] 結果顯示 Average、Median、Min、Max、P95、Jitter
- [ ] 結果顯示成功率
- [ ] 結果顯示各錯誤類型數量
- [ ] 結果顯示延遲圖表
- [ ] 可查看每一次詳細結果
- [ ] 可使用相同設定再次測試
- [ ] 可返回修改設定

## 24.2 平台驗收

- [ ] Android Debug／Release build 可執行
- [ ] Windows Debug／Release build 可執行
- [ ] macOS Debug／Release build 可執行
- [ ] Android Internet permission 已設定
- [ ] macOS network entitlement 已設定
- [ ] 三個平台均可完成 HTTPS 測試
- [ ] Windows／macOS 支援鍵盤和滑鼠
- [ ] Android 返回鍵運作正確

## 24.3 UI 驗收

- [ ] 主要 UI 使用 Cupertino widgets
- [ ] Light Mode 正常
- [ ] Dark Mode 正常
- [ ] 窄屏沒有 overflow
- [ ] 寬屏內容不會無限制延伸
- [ ] 所有按鈕有 Enabled／Disabled 狀態
- [ ] 測試期間設定不能被修改
- [ ] 錯誤訊息清晰
- [ ] 顏色不是唯一狀態提示
- [ ] 字體放大後主要功能仍可操作

---

# 25. Definition of Done

本階段只有在以下項目全部完成時，才視為 Done：

1. 所有 MVP 功能完成。
2. Android、Windows、macOS 均可建立及運行。
3. 核心統計有 Unit Test。
4. HTTP 測試 Service 有 Mock Test。
5. 沒有已知會導致 App Crash 的問題。
6. 沒有未釋放 HTTP Client 或 Timer。
7. 50 次測試完成後沒有明顯記憶體持續增長。
8. Light／Dark Mode 均通過基本測試。
9. README 包含：

   - 開發環境要求
   - 執行方式
   - 平台設定
   - 已知限制
   - 測試指令
10. 程式碼沒有包含第二階段上傳／下載測速功能。
11. App 介面清楚說明 Delay 是完整 HTTP 回應時間，而不是 ICMP Ping。
12. App 不會聲稱「每次新連線」可完全清除 DNS 或系統快取。

---

# 26. 實作優先次序

Coding Agent 應按以下順序實作：

1. 建立跨平台 Flutter 專案
2. 設定 `CupertinoApp` 及 Light／Dark Theme
3. 建立資料模型
4. 建立 URL Validation Service
5. 建立 Statistics Service 及 Unit Tests
6. 建立單次 HTTP Test Service
7. 實作正常連線模式
8. 實作每次新連線模式
9. 實作 Sequential Test Runner
10. 實作 Timeout 和取消
11. 實作測試設定頁
12. 實作測試進度頁
13. 實作測試結果頁
14. 實作延遲走勢圖
15. 實作最近設定保存
16. 完成 Android 平台設定及測試
17. 完成 Windows 平台測試
18. 完成 macOS entitlement 及測試
19. 補充 Widget Tests 和 Service Tests
20. 完成 README 及已知限制

---

## 27. 主要技術假設與限制

- App 量度的是完整 HTTP GET 回應時間，不是 ICMP Ping。
- 第一個 request 通常可能比後續 request 慢。
- 正常連線模式可能重用 TCP／TLS 連線。
- 每次新連線模式只保證建立新的 App-level HTTP Client，不保證清除作業系統 DNS cache。
- 測試結果會受裝置、Wi-Fi、VPN、ISP、Proxy、CDN、伺服器負載及地理距離影響。
- 任意 URL 可能返回大型內容，因此必須實施 10 MiB 限制。
- 某些伺服器可能拒絕非瀏覽器 request。
- 某些 HTTP URL 可能被平台安全政策阻擋。
- Cupertino widgets 原本主要為 Apple 設計語言而設，因此必須額外驗證 Android 和 Windows 的鍵盤、返回、字體、Hover 及滾動行為。Flutter 官方也提醒在非 Apple 平台使用 `CupertinoApp` 時可能出現用戶不預期的 iOS 行為。 [\[api.flutter.dev\]](https://api.flutter.dev/flutter/cupertino/), [\[api.flutter.dev\]](https://api.flutter.dev/flutter/cupertino/CupertinoApp-class.html)

以上 Spec 可直接交給 Coding Agent 作為第一階段的實作依據。