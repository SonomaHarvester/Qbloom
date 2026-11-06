mod backend;

use cxx_qt_lib::{QGuiApplication, QQmlApplicationEngine, QUrl};

fn main() {
    let mut app = QGuiApplication::new();
    let mut engine = QQmlApplicationEngine::new();
    let Some(engine) = engine.as_mut() else {
        eprintln!("Cannot create Qt QML engine");
        std::process::exit(1);
    };
    engine.load(&QUrl::from("qrc:/qt/qml/Qbloom/Rust/qml/Main.qml"));
    let Some(app) = app.as_mut() else {
        eprintln!("Cannot create Qt GUI application");
        std::process::exit(1);
    };
    std::process::exit(app.exec());
}
