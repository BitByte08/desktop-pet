# 🐾 Desktop Pet

A lightweight, native macOS desktop overlay app for Apple Silicon Macs.  
Import a GIF, APNG, PNG sequence, or video — it floats on your screen, loops forever, and stays visible across all Spaces. Run multiple pets at once, each with its own file and settings.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-Optimized-green)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

---

## ⬇️ 설치 방법

### 방법 1 — Homebrew (권장)

[Homebrew](https://brew.sh)가 설치되어 있다면 터미널에 아래 두 줄을 붙여넣으세요:

```bash
brew tap bssm-oss/desktop-pet https://github.com/bssm-oss/desktop-pet.git
brew install --cask bssm-oss/desktop-pet/desktop-pet
```

설치 후 **처음 실행 시 quarantine 해제**가 필요합니다:

```bash
xattr -cr /Applications/DesktopPet.app
open /Applications/DesktopPet.app
```

> 이 명령은 macOS가 인터넷에서 다운로드된 앱에 붙이는 격리 플래그를 제거합니다.  
> Apple 개발자 서명이 없는 앱은 이 과정 없이 "손상됨" 경고가 뜹니다.

업데이트:

```bash
brew upgrade --cask desktop-pet
xattr -cr /Applications/DesktopPet.app   # 업데이트 후에도 한 번 실행
```

삭제:

```bash
brew uninstall --cask desktop-pet
```

> **Homebrew가 없다면:** 터미널에서 아래 명령으로 먼저 설치하세요.
> ```bash
> /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
> ```

---

### 방법 2 — DMG 직접 다운로드

1. 이 페이지 오른쪽 **[Releases](https://github.com/bssm-oss/desktop-pet/releases)** 클릭
2. 최신 버전의 **`DesktopPet.dmg`** 다운로드
3. DMG 열기 → `DesktopPet.app`을 **Applications** 폴더로 드래그
4. 터미널에서 quarantine 해제 후 실행:

```bash
xattr -cr /Applications/DesktopPet.app
open /Applications/DesktopPet.app
```

> **왜 이 명령이 필요한가요?**  
> Apple은 앱스토어 외부에서 받은 앱에 격리(quarantine) 플래그를 붙입니다.  
> Apple Developer Program($99/년) 서명이 없는 오픈소스 앱은 이 플래그를 수동으로 제거해야 합니다.  
> `xattr -cr`은 앱 파일 자체를 수정하지 않으며, macOS의 메타데이터만 제거합니다.

또는 GUI로: **시스템 설정 → 개인 정보 보호 및 보안 → "확인 없이 열기"** 클릭

---

### 방법 3 — 소스에서 직접 빌드

요구사항: macOS 14+, Xcode Command Line Tools

```bash
# Command Line Tools 설치 (없다면)
xcode-select --install

git clone https://github.com/bssm-oss/desktop-pet.git
cd desktop-pet

SDK=$(xcrun --sdk macosx --show-sdk-path)
mkdir -p build/DesktopPet.app/Contents/{MacOS,Resources}

swiftc \
  -sdk "$SDK" -target arm64-apple-macosx14.0 -O \
  -framework AppKit -framework AVFoundation \
  -framework CoreGraphics -framework ServiceManagement \
  DesktopPet/App/main.swift \
  DesktopPet/App/AppDelegate.swift \
  DesktopPet/Settings/AppSettings.swift \
  DesktopPet/Settings/SettingsView.swift \
  DesktopPet/Playback/FrameSequence.swift \
  DesktopPet/Playback/GIFDecoder.swift \
  DesktopPet/Playback/APNGDecoder.swift \
  DesktopPet/Playback/PNGSequenceDecoder.swift \
  DesktopPet/Playback/AnimationPlayer.swift \
  DesktopPet/Playback/VideoPlayer.swift \
  DesktopPet/Utilities/PlaceholderAnimation.swift \
  DesktopPet/Utilities/SecurityScopedAccess.swift \
  DesktopPet/Window/OverlayWindow.swift \
  DesktopPet/Window/PetView.swift \
  DesktopPet/Window/OverlayWindowController.swift \
  DesktopPet/MenuBar/MenuBarController.swift \
  -o build/DesktopPet.app/Contents/MacOS/DesktopPet

cp DesktopPet/App/Info.plist build/DesktopPet.app/Contents/Info.plist
open build/DesktopPet.app
```

---

## 사용 방법

앱을 실행하면 독(Dock)에는 아이콘이 없고, **메뉴바에 🐾 아이콘**이 나타납니다.

### 펫 추가하기

1. 🐾 클릭 → **Add Pet…**
2. 파일 선택 창에서 GIF / APNG / PNG 폴더 / 영상 선택
3. 선택한 파일이 바로 화면에 떠오릅니다

### 여러 마리 동시에 띄우기

**Add Pet…** 을 반복하면 됩니다. 각 펫은 파일, 위치, 크기, 투명도가 모두 독립적입니다.

### 조작

| 동작 | 방법 |
|------|------|
| 위치 이동 | 캐릭터를 클릭하고 드래그 |
| 파일 바꾸기 | 파일을 캐릭터 위로 드래그 앤 드롭 |
| 설정 열기 | 🐾 클릭 → Pet N → Settings… |
| 빠른 조작 | 🐾 클릭 → Pet N → Import / Remove |
| 펫 제거 | Settings 패널 → Remove Pet |

### 각 펫별 설정 옵션

| 옵션 | 설명 |
|------|------|
| Name | 펫 이름 (메뉴에 표시) |
| Playing | 재생 / 일시정지 |
| Speed | 재생 속도 (0.1×~4.0×) |
| Opacity | 투명도 (10%~100%) |
| Scale | 크기 배율 (0.25×~4.0×) |
| Flip H | 좌우 반전 |
| Flip V | 상하 반전 |
| Always on Top | 항상 최상단 |
| Click-Through | 클릭이 아래 창으로 통과 |
| Lock Position | 드래그 잠금 |
| Start at Login | 로그인 시 자동 실행 |

---

## 지원 파일 형식

| 형식 | 투명 배경 | 비고 |
|------|----------|------|
| GIF | ✅ | 잔상 없이 정확한 disposal 처리 |
| APNG | ✅ | macOS 14 네이티브 지원 |
| PNG 시퀀스 (폴더) | ✅ | 파일명 순 정렬, 기본 24fps |
| MP4 / MOV (H.264/H.265) | ❌ | 투명 배경 없음 |
| ProRes 4444 (.mov) | ✅ | 투명 비디오, 하드웨어 디코딩 |
| HEVC with Alpha (.mov) | ✅ | macOS 13+, 작은 파일 크기 |

---

## 성능

- **CVDisplayLink** — 디스플레이 주사율 동기화, ProMotion 자동 지원
- **CALayer.contents** — CPU 픽셀 복사 없는 GPU 제로카피 업로드
- **ImageIO** — Apple Silicon 하드웨어 가속 디코딩
- **AVFoundation** — 하드웨어 비디오 디코딩 (Media Engine)

정적 상태 CPU 사용률: M 시리즈 기준 **< 1%**

---

## 프로젝트 구조

```
DesktopPet/
├── App/          # AppDelegate, main.swift, Info.plist
├── Window/       # OverlayWindow, PetView, OverlayWindowController
├── Playback/     # AnimationPlayer, GIFDecoder, APNGDecoder, PNGSequenceDecoder, VideoPlayer
├── MenuBar/      # MenuBarController
├── Settings/     # AppSettings, SettingsView
└── Utilities/    # PlaceholderAnimation, SecurityScopedAccess
Casks/
└── desktop-pet.rb   # Homebrew Cask formula
```

---

## Docs

- [Architecture](docs/architecture.md)
- [Build & Run](docs/build-and-run.md)
- [Supported Formats](docs/formats.md)
- [Performance](docs/performance.md)
- [Troubleshooting](docs/troubleshooting.md)

---

## License

MIT — see [LICENSE](LICENSE)
