[English](README.md) | [한국어](README-ko.md)

# {{NAME}}

인사말과 카운터 로직을 Swift가 소유하는 Qt Quick 애플리케이션입니다. 이 어댑터는 실험적 C ABI를 사용합니다. Swift의 밑줄 접두사가 붙은 `@_cdecl` 내보내기와 C++ `QObject` 파사드를 사용하며 Qt Bridge for Swift는 사용하지 않습니다.

매니페스트, 명령, 스모크 테스트 계약은 `QBLOOM_PROJECT_GUIDE.md`를 참고하세요.

## 요구 사항과 명령

- Swift 6.4, CMake 3.21, C++17, Quick·Qml·QuickControls2를 포함한 Qt 6.8 이상
- FreeBSD 15.1 x86_64에서 검증했습니다. 새 `init` 프로젝트는 macOS 27.2 arm64, Apple Swift 6.4.2, Qt 6.12.0에서도 검증했습니다.

```sh
qbloom doctor --strict
qbloom build
qbloom run
qbloom test --headless
```

SwiftPM은 외부 패키지 의존성 없이 동적 라이브러리를 빌드합니다. CMake는 Qt 애플리케이션을 빌드하고 해당 라이브러리를 링크합니다. `qbloom test`는 Swift 단위 테스트를 실행하고 디스플레이가 있으면 Qt Quick 스모크 테스트도 실행합니다. `--headless`는 Qt의 offscreen 플랫폼 플러그인을 요청합니다. 스모크 테스트는 Swift가 제공한 인사말, 버튼 두 번 누르기, 초기화, QML 바인딩과 변경 알림을 확인합니다.

C ABI는 불투명한 Swift 객체 핸들의 참조를 유지한 채 전달합니다. C++는 QML 엔진이 파사드 사용을 끝낸 뒤 핸들을 한 번 파괴합니다. 인사말은 호출자가 소유한 버퍼를 사용하므로 언어 간 할당을 해제할 필요가 없습니다. 호출과 Qt 알림은 GUI 스레드에서 이루어집니다. 배포할 때는 Swift 런타임, Qt 라이브러리, 플러그인을 애플리케이션과 함께 묶으세요.

## 라이선스

qbloom에서 파생된 시작 파일에는 BSD 2-Clause 라이선스가 적용됩니다. 재배포 시 `QBLOOM_TEMPLATE_NOTICE.txt`를 유지하세요. 애플리케이션의 라이선스는 직접 선택하세요. Qt에는 별도의 LGPL/GPL/상용 조건이 적용되고 Swift 도구 모음과 런타임에도 자체 라이선스가 있습니다.
