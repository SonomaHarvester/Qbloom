[English](README.md) | [한국어](README-ko.md)

# {{NAME}}

인사말과 카운터 로직을 Kotlin이 소유하는 Qt Quick 애플리케이션입니다. 작은 JNI 브리지가 C++ `QObject`를 통해 Kotlin `Backend`를 노출합니다. 이 브리지는 실험적이며 FreeBSD 15.1 x86_64, Qt 6.11.2, OpenJDK 25, Gradle 9.8, Kotlin Gradle 플러그인 2.4.10 환경에서 스모크 테스트를 거쳤습니다.

새 `init` 프로젝트는 macOS 27.2 arm64, Qt 6.12.0, Homebrew OpenJDK 27, Gradle 9.8.2에서도 검증했습니다. macOS에서 `qtRun`은 AppKit을 위해 JVM 애플리케이션을 첫 스레드에서 시작합니다.

매니페스트, 명령, 스모크 테스트 계약은 `QBLOOM_PROJECT_GUIDE.md`를 참고하세요.

## 요구 사항과 명령

JDK 21 이상, Gradle 8.14.2 이상, CMake 3.21 이상, C++17 컴파일러, Quick·Qml·QuickControls2 개발 파일을 포함한 Qt 6.8 이상을 설치하세요. Java 자동 탐색이 실패한다면 `JAVA_HOME`이 `include/jni.h`를 포함한 JDK를 가리키도록 설정하세요. 표준 경로 밖에 설치한 Qt는 `CMAKE_PREFIX_PATH`로 찾을 수 있습니다.

```sh
qbloom doctor --strict
qbloom build
qbloom run
qbloom test --headless
```

Gradle은 Kotlin을 컴파일하고 테스트합니다. CMake는 Qt/JNI 라이브러리를 빌드하고 Gradle의 `classes` 작업을 호출합니다. `qbloom test`는 Kotlin 로직 테스트를 실행한 뒤 디스플레이를 사용할 수 있으면 실제 QML 창 스모크 테스트를 실행합니다. `--headless`는 Qt의 offscreen 플러그인을 요청합니다. 스모크 테스트는 Kotlin이 제공한 인사말, 버튼을 두 번 눌러 증가한 값, 초기화, 바인딩된 QML 텍스트, 세 차례의 변경 알림을 확인합니다. 첫 명시적 빌드에서 고정된 버전의 Kotlin Gradle 플러그인을 Maven Central에서 해결합니다. 이후 `run`과 `test` 명령은 Gradle의 로컬 캐시를 사용합니다.

JVM은 메인 스레드에서 JNI 라이브러리를 호출합니다. 라이브러리는 같은 스레드에서 Qt 이벤트 루프를 만들고 소유합니다. QML 엔진이 파괴될 때까지 Kotlin 백엔드의 전역 참조를 유지하며, JNI 호출 후 JVM 예외를 정리하고 Qt GUI 스레드에서만 알림을 발생시킵니다. 배포할 때는 네이티브 라이브러리와 Qt 런타임·플러그인을 함께 묶어야 합니다. 다른 OS/아키텍처 조합은 검증되지 않았습니다.

## 라이선스

qbloom에서 파생된 시작 파일에는 BSD 2-Clause 라이선스가 적용됩니다. 재배포 시 `QBLOOM_TEMPLATE_NOTICE.txt`를 유지하세요. 애플리케이션의 라이선스는 직접 선택하세요. Qt에는 별도의 LGPL/GPL/상용 조건이 적용됩니다. OpenJDK, Gradle, 의존성에도 자체 조건이 있으므로 배포 전에 검토하세요.
