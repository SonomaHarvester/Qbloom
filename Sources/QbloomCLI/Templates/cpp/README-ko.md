[English](README.md) | [한국어](README-ko.md)

# {{NAME}}

qbloom이 생성한 Qt Quick 6 예제입니다. C++ `QObject`가 알림 신호와 함께 인사말과 카운터 값을 제공합니다.

매니페스트, 명령, 스모크 테스트 계약은 `QBLOOM_PROJECT_GUIDE.md`를 참고하세요.

`qbloom` 명령은 `qbloom.toml`이 있는 디렉터리에서 실행하세요. 기존 프로젝트에 이 예제를 추가했다면 그 디렉터리는 `qbloom_quick`의 상위 디렉터리입니다.

## 명령

```sh
qbloom doctor
qbloom build
qbloom run
qbloom test --headless
qbloom clean
```

Qt 6.8 이상(Quick, Qml, QuickControls2 포함), CMake, C++17 컴파일러가 필요합니다. `qbloom test --headless`는 Qt의 offscreen 플랫폼 플러그인을 사용하므로 동작하는 그래픽 환경 또는 플러그인이 필요합니다.

qbloom에서 파생된 시작 파일에는 BSD 2-Clause 라이선스가 적용됩니다. 재배포 시 `QBLOOM_TEMPLATE_NOTICE.txt`를 유지하세요. 직접 추가한 코드와 애플리케이션의 라이선스는 직접 선택하세요. Qt와 그 구성 요소에는 별도의 LGPL/GPL/상용 조건이 적용되므로 배포 방식에 맞게 검토해야 합니다.
