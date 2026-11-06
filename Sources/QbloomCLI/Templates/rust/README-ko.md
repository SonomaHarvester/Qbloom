[English](README.md) | [한국어](README-ko.md)

# {{NAME}}

qbloom이 생성한 Rust `QObject` 백엔드 기반 Qt Quick 애플리케이션입니다.

매니페스트, 명령, 스모크 테스트 계약은 `QBLOOM_PROJECT_GUIDE.md`를 참고하세요. qbloom은 `qbloom.toml`이 있는 디렉터리에서 실행하세요. `add`로 추가한 경우에는 기존 프로젝트의 루트 디렉터리입니다.

## 요구 사항

- Rust 1.85 이상과 Cargo
- Quick, QML, Quick Controls를 포함한 Qt 6.8 이상 개발 파일
- C++ 컴파일러와 `qmake6`

`qbloom doctor`, `qbloom build`, `qbloom run`, `qbloom test --headless`를 실행하세요. Cargo가 실제 빌드를 담당합니다. 최상위 CMake 타깃은 CMake 작업 흐름과 통합하기 위해 `cargo build --locked`를 호출합니다. 의존성은 프로젝트 생성 중이 아니라 빌드 중에 해결됩니다.

qbloom에서 파생된 시작 파일에는 BSD 2-Clause 라이선스가 적용됩니다. 재배포 시 `QBLOOM_TEMPLATE_NOTICE.txt`를 유지하세요. 직접 추가한 코드와 애플리케이션의 라이선스는 직접 선택하세요. 백엔드는 CXX-Qt 0.10.0(MIT 또는 Apache-2.0)을 사용합니다. Qt 모듈에는 별도의 LGPL/GPL/상용 조건이 적용되므로 재배포 전에 검토하세요.
