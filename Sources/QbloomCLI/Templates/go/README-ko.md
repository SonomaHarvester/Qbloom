[English](README.md) | [한국어](README-ko.md)

# {{NAME}}

인사말과 카운터 로직을 Go가 소유하는 Qt Quick 애플리케이션입니다. C++ `QObject` 파사드가 Go의 값을 QML에 제공하고 Qt GUI 스레드에서 `countChanged`를 발생시킵니다.

매니페스트, 명령, 스모크 테스트 계약은 `QBLOOM_PROJECT_GUIDE.md`를 참고하세요.

## 요구 사항

- Quick, Qml, QuickControls2 개발 파일을 포함한 Qt 6.8 이상
- CMake 3.21 이상, C++17 컴파일러, Ninja(권장)
- Go 1.23 이상과 cgo용으로 동작하는 C 컴파일러(`go env CC`)

`go.mod`에는 외부 모듈이 없습니다. CMake 빌드는 `GOTOOLCHAIN=local`과 `GOPROXY=off`를 설정하므로 코드를 내려받지 않습니다. FreeBSD에서 생성된 라이브러리 `libqbloom_go.so`는 애플리케이션 옆에 있으며, 애플리케이션의 빌드 RPATH는 이 로컬 라이브러리를 가리킵니다. macOS에서는 실행 파일이 빌드 RPATH를 통해 `@rpath/libqbloom_go.dylib`를 찾습니다. 다른 환경에 배포하려면 Go 공유 라이브러리와 해당 Qt 런타임 및 플러그인을 함께 묶어야 합니다.

Windows x64에서는 x64 Visual Studio 개발자 셸에서 MSVC용 Qt 키트를 사용하세요. 이 셸의 `Path`에 Qt 키트의 `bin` 디렉터리와 MinGW 호환 C 컴파일러를 추가하세요. LLVM-MinGW를 사용하는 PowerShell에서는 `$env:CC = 'x86_64-w64-mingw32-clang.exe'`로 설정할 수 있습니다. CMake는 MSVC import 라이브러리를 통해 Go 심볼을 링크하고 실행 파일 옆에 `libqbloom_go.dll`을 배치합니다. 배포할 때 두 파일을 같은 디렉터리에 두세요.

## 명령

```sh
qbloom doctor --strict
qbloom build
qbloom run
qbloom test --headless
```

`qbloom test`는 `go test ./...`를 실행하고, 디스플레이가 있으면 QML 창 스모크 테스트도 실행합니다. `--headless`는 Qt의 offscreen 플랫폼 플러그인을 요청합니다. 플러그인을 사용할 수 없다면 스모크 테스트는 성공으로 처리하지 않고 실패합니다.

내보낸 C ABI는 새로 할당한 UTF-8 인사말을 반환합니다. C++ 파사드는 `GoFreeString`을 정확히 한 번 호출합니다. 상태는 정수 핸들로 참조하며 C++는 Go 포인터를 보관하지 않습니다. 카운터 함수는 성공 시 `0`, 잘못된 핸들이나 출력 포인터에는 `-1`을 반환합니다. 카운터 상태는 Go가 소유하며 파사드는 각 변경을 Qt GUI 스레드에서 신호로 알립니다. 작업자 스레드에서 파사드의 메서드를 직접 호출하지 마세요.

## 라이선스

qbloom에서 파생된 시작 파일에는 BSD 2-Clause 라이선스가 적용됩니다. 재배포 시 `QBLOOM_TEMPLATE_NOTICE.txt`를 유지하세요. 직접 추가한 코드와 애플리케이션의 라이선스는 직접 선택하세요. Qt에는 별도의 LGPL/GPL/상용 조건이 적용되며, 특히 Qt 플러그인과 동적 라이브러리 패키징 조건을 재배포 전에 검토해야 합니다. Go 도구 모음과 런타임에도 자체 라이선스가 있습니다. 배포하는 정확한 버전의 조건은 Qt와 Go의 공식 라이선스 고지를 참고하세요.
