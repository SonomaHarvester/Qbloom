[English](README.md) | [한국어](README-ko.md)

# {{NAME}}

이 Qt Quick 애플리케이션은 공식 PySide6 바인딩을 사용합니다. Python이 Qt 이벤트 루프를 소유하며, Python `QObject`가 `countChanged` 알림과 함께 `greeting`과 `count`를 QML에 제공합니다. C ABI나 임베딩 계층은 필요하지 않습니다.

매니페스트, 명령, 스모크 테스트 계약은 `QBLOOM_PROJECT_GUIDE.md`를 참고하세요.

`qbloom` 명령은 `qbloom.toml`이 있는 디렉터리에서 실행하세요. 기존 프로젝트에 이 예제를 추가했다면 그 디렉터리는 `qbloom_quick`의 상위 디렉터리입니다.

Python 3.10~3.14과 해당 플랫폼용 PySide6 6.11.2를 설치하세요. 공식 wheel이 제공되는 플랫폼에서는 다음을 실행합니다.

```sh
python3.12 -m venv .venv
.venv/bin/python -m pip install PySide6==6.11.2
qbloom doctor
qbloom build
qbloom run
qbloom test --headless
```

Windows에서는 가상 환경을 활성화하거나 `.venv\\Scripts\\python.exe`를 사용하세요. FreeBSD에서 호환되는 wheel이 없다면 버전이 맞는 시스템 `py*-pyside6` 패키지를 사용하세요.

`CMakeLists.txt`는 실행 타깃을 제공하는 CMake 통합 진입점입니다. `qbloom build`는 Python 소스를 직접 검사하며 CMake로 Python을 컴파일하지 않습니다.

qbloom에서 파생된 시작 파일에는 BSD 2-Clause 라이선스가 적용됩니다. 재배포 시 `QBLOOM_TEMPLATE_NOTICE.txt`를 유지하세요. 직접 추가한 코드와 애플리케이션의 라이선스는 직접 선택하세요. PySide6와 Qt에는 별도의 LGPL/GPL/상용 조건이 적용되므로 배포 전에 검토해야 합니다.
