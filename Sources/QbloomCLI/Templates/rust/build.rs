use cxx_qt_build::{CxxQtBuilder, QmlModule};

fn main() {
    #[cfg(target_os = "freebsd")]
    println!("cargo:rustc-link-search=native=/usr/local/lib");
    CxxQtBuilder::new_qml_module(QmlModule::new("Qbloom.Rust").qml_file("qml/Main.qml"))
        .qt_module("Network")
        .files(["src/backend.rs"])
        .build();
}
