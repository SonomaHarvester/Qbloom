[English](README.md) | [한국어](README-ko.md)

# qbloom

명령줄에서 Qt 6 / Qt Quick 데스크톱 앱을 생성하고 빌드, 실행, 테스트할 수 있습니다. 백엔드는 C++, Python, Rust, Go, Java, Swift, Kotlin 중에서 선택합니다. 생성된 앱의 인사말과 카운터 값은 선택한 백엔드가 제공하며, 버튼을 누르면 변경 알림을 통해 QML 화면이 갱신됩니다.

## 설치

프로젝트의 [릴리스 페이지](https://github.com/SonomaHarvester/Qbloom/releases)에 사용하는 OS와 아키텍처용 바이너리 압축 파일이 있으면 다운로드한 뒤 압축을 풉니다.

| OS | 압축을 푼 폴더에서 실행 |
| --- | --- |
| Windows x64 | PowerShell에서 `.\install.ps1`을 실행합니다. 설치가 끝나면 새 PowerShell을 열어 사용자 Path를 반영합니다. |
| macOS, Linux, FreeBSD | `sh install.sh`를 실행하고 `~/.local/bin`을 Path에 추가합니다. 영어와 한국어 매뉴얼도 함께 설치됩니다. |

CLI를 실행하려면 호환되는 Swift 런타임이 필요합니다. Windows에서 런타임 DLL이 없거나 호환되지 않는다는 메시지가 나오면 `.\install.ps1 -InstallSwift`를 실행하세요. WinGet으로 Swift 6.4.2 도구 체인을 설치한 뒤 실행을 다시 확인합니다. Unix 설치 스크립트는 파일을 복사하기 전에 바이너리가 실행되는지 확인합니다. 런타임 요구 사항과 소스 빌드 절차는 [설치 및 패키징 문서](docs/installation.md)를 참고하세요.

## 빠른 시작

```sh
qbloom init hello
cd hello
qbloom doctor --strict
qbloom build
qbloom run
qbloom test --headless
```

기본 백엔드는 C++입니다. 다른 언어로 시작하려면 새 디렉터리 이름을 사용하고 `--python`, `--rust`, `--go`, `--java`, `--swift`, `--kotlin` 중 하나를 지정하세요. 백엔드별 도구는 생성된 README에 나와 있습니다. 네이티브 Qt 템플릿에는 Qt 6.8 이상과 Qt Quick 개발 파일이 필요하며, Python 템플릿은 PySide6를 사용합니다.

`qbloom test --headless`는 Qt의 오프스크린 플랫폼 플러그인을 사용합니다. 스모크 테스트는 백엔드 인사말, 카운터 변화 `0 → 1 → 2 → 0`, 변경 알림을 확인합니다.

## 백엔드와 호환성

| 백엔드 | Qt 연동 방식 |
| --- | --- |
| C++ | 네이티브 QObject |
| Python | PySide6 QObject |
| Rust | CXX-Qt |
| Go | cgo 공유 라이브러리와 C++ QObject 파사드 |
| Java, Kotlin | 실험적 JNI와 C++ QObject 파사드 |
| Swift | 실험적 Swift C ABI와 C++ QObject 파사드 |

Windows 11 x64, macOS arm64, Fedora x86_64, FreeBSD x86_64의 검증 환경에서 7개 백엔드 모두 `init`과 `add` 빌드 및 Qt Quick 스모크 테스트를 통과했습니다. Ubuntu와 macOS CI 결과, 정확한 도구 버전, 플랫폼별 제약은 [호환성 표](docs/compatibility.md)에 정리했습니다.

## 프로젝트 명령

- `qbloom init`(`in`)은 새 디렉터리에 프로젝트를 생성합니다.
- `qbloom add <기존-디렉터리>`는 기존 CMake 프로젝트에 별도의 Qt Quick 타깃을 추가합니다. Qbloom 명령은 상위 프로젝트에서 실행합니다.
- `qbloom override`(`ovr`)는 확인을 받은 뒤 `init`으로 만든 프로젝트를 교체하고, 사용자 파일을 포함한 이전 프로젝트를 같은 상위 폴더에 백업합니다.
- `qbloom doctor --json`은 진단 결과를 JSON으로 출력합니다. 필수 도구가 없거나 호환되지 않을 때 실패하도록 하려면 `--strict`를 추가하세요.
- `qbloom build --release`는 릴리스 빌드를 요청합니다. 같은 구성으로 실행하거나 테스트하려면 `qbloom run --release` 또는 `qbloom test --release --headless`를 사용하세요. `qbloom clean`은 관리 대상 빌드 결과물을 지웁니다.

백엔드와 프로젝트 구성은 [`qbloom.toml`](docs/manifest.md)에 기록됩니다. 우선순위가 더 높은 로캘 설정이 없다면 `LANG=ko_KR.UTF-8`로 한국어 CLI 안내를 사용할 수 있습니다.

## 소스에서 빌드

CLI를 빌드하려면 Swift 6.4와 Git이 필요하며 Qt는 필요하지 않습니다. macOS, Linux, FreeBSD에서는 체크아웃에서 `make`와 `make install PREFIX="$HOME/.local"`을 실행하거나 `PREFIX="$HOME/.local" sh scripts/install.sh`를 사용하세요. Windows는 [PowerShell 절차](docs/installation.md#windows-x64)를 따르세요. CLI 테스트는 `swift test`로 실행합니다.

## 라이선스

Qbloom은 [BSD 2-Clause](LICENSE)로 배포합니다. 생성된 프로젝트에는 `QBLOOM_TEMPLATE_NOTICE.txt`가 포함되며 Qt와 백엔드 의존성에는 별도의 조건이 적용됩니다. 생성한 앱을 배포하기 전에 [라이선스 안내](docs/licensing.md)를 확인하세요.
