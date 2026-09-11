# 온디바이스 한국어 음성 키보드 프로젝트 설정

작성일: 2026-09-11

## 현재 기준선

- 업스트림: `getdictus/dictus-ios`
- 기준 커밋: `6913573` (`v1.8.1`)
- 기본 브랜치: `main`
- 작업 브랜치: `feature/korean-stt-validation`
- 개발 환경: Xcode 26.6, Swift 6.3.3
- 최소 지원 버전: iOS 17.0
- 라이선스: MIT. 기존 `LICENSE`와 원저작자 고지를 유지한다.

## Git 원격 저장소 정책

```text
origin    https://github.com/kimmyeongji/dictus-ios.git
upstream  https://github.com/getdictus/dictus-ios.git
```

`origin`은 독립 제품용 포크, `upstream`은 Dictus 변경을 선택적으로 가져오기 위한 원본이다.

업스트림 동기화는 자동 병합보다 검토 후 cherry-pick을 기본으로 한다.

```bash
git fetch upstream
git log --oneline main..upstream/main
git cherry-pick <commit>
```

## 현재 아키텍처와 기획의 대응

| 기획 요구 | 기존 구현 위치 |
|---|---|
| 메인 앱, 온보딩, 모델 다운로드 | `DictusApp/` |
| 키보드 익스텐션, 텍스트 삽입, 키보드 전환 | `DictusKeyboard/` |
| App Group, 모델 정보, 공유 상태 | `DictusCore/` |
| WhisperKit 어댑터와 언어 토큰 | `DictusApp/Audio/SpeechModelProtocol.swift` |
| STT 언어 정책 | `DictusCore/Sources/DictusCore/TranscriptionLanguage.swift` |
| 키보드 언어 목록 | `DictusCore/Sources/DictusCore/SupportedLanguage.swift` |

WhisperKit 모델은 키보드 익스텐션이 아니라 메인 앱 프로세스에서 실행된다. 키보드 익스텐션의 메모리 한도를 피하기 위한 업스트림의 현재 설계이며 MVP에서도 유지한다.

STT 언어 카탈로그는 WhisperKit 0.18.0의 고유 언어 코드 100개를 제공한다.
언어 선택 화면은 자국어명·현재 로케일명·영문명·언어 코드 검색을 지원한다.
이는 음성 인식 범위이며 `SupportedLanguage`가 나타내는 자체 키보드 배열 범위와는 별개다.

## Phase 0 상태

- [x] 공개 원본 저장소 복제
- [x] `origin`과 `upstream` 역할 분리
- [x] 한국어 STT 검증 브랜치 생성
- [x] Xcode/Swift 버전 확인
- [x] 한국어 언어 토큰 전달 위치 확인
- [x] App Group 및 Full Access 설정 위치 확인
- [x] GitHub 원격 포크 생성 및 첫 push
- [x] iOS Simulator 기준 전체 앱 빌드
- [ ] 개발자 서명과 독립 Bundle ID/App Group 확정
- [ ] 실제 iPhone 설치 및 원본 동작 확인

원격 포크는 `https://github.com/kimmyeongji/dictus-ios`에 생성되어 있다.

```bash
gh auth login -h github.com
gh repo fork getdictus/dictus-ios --remote=false --clone=false
git push -u origin feature/korean-stt-validation
```

Xcode 26.6에서는 FluidAudio 0.12.4의 Swift 동시성 진단이 오류로 승격되어
시뮬레이터 빌드가 중단된다. FluidAudio의 해당 수정과 WhisperKit 의존성 충돌
제거가 포함된 0.13.4를 Xcode 프로젝트에 정확 버전으로 고정했다.

- 관련 이슈: <https://github.com/FluidInference/FluidAudio/issues/448>
- 의존성 충돌 제거 변경: <https://github.com/FluidInference/FluidAudio/pull/449>
- 확인 결과: `DictusApp.app`, `DictusKeyboard.appex`, `DictusWidgets.appex` 생성

## Phase 1 변경 원칙

첫 검증의 목적은 한국어 음성 인식 품질의 Go/No-Go 판단이다. 브랜딩, 전체 UI 번역, 한글 자판, 예측 사전은 이 검증에 섞지 않는다.

현재 `SupportedLanguage`는 키보드 레이아웃·스페이스바 라벨·자동수정 사전까지 결합한다. 따라서 한국어를 이 enum에 바로 추가하면 STT 실험보다 변경 범위가 커진다. Phase 1에서는 STT 언어 정책에만 `ko`를 추가하고 WhisperKit의 `DecodingOptions.language`에 `ko`가 전달되는지를 단위 테스트와 진단 로그로 확인한다.

## 로컬 확인 명령

```bash
./scripts/check-korean-dev-env.sh

cd DictusCore
swift test \
  --disable-sandbox \
  --scratch-path ../build/DictusCore \
  --cache-path ../build/SwiftPMCache
```

전체 앱 빌드는 Xcode의 Swift Package 의존성이 해석된 뒤 실행한다.

```bash
xcodebuild build \
  -project Dictus.xcodeproj \
  -scheme DictusApp \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO
```

마이크, App Group 핸드오프, 키보드 익스텐션의 실제 메모리 사용량은 시뮬레이터 결과로 승인하지 않고 iPhone 실기기에서 확인한다.

## 브랜딩 전 보류할 값

다음 값은 브랜드명과 Apple Developer Team이 확정될 때 한 번에 교체한다.

- `com.pivi.dictus`
- `com.pivi.dictus.keyboard`
- `com.pivi.dictus.widgets`
- `group.solutions.pivi.dictus`
- Xcode 프로젝트의 `DEVELOPMENT_TEAM`

기존 값을 그대로 서명해 배포하지 않는다.
