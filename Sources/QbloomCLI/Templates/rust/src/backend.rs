#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
    }

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qproperty(QString, greeting, READ, CONSTANT)]
        #[qproperty(i32, count, READ, NOTIFY)]
        type Backend = super::BackendRust;

        #[qinvokable]
        fn increment(self: Pin<&mut Self>);

        #[qinvokable]
        fn reset(self: Pin<&mut Self>);
    }
}

use core::pin::Pin;
use cxx_qt::CxxQtType;
use cxx_qt_lib::QString;

pub struct BackendRust {
    greeting: QString,
    count: i32,
}

impl Default for BackendRust {
    fn default() -> Self {
        Self {
            greeting: QString::from("Hello, world!"),
            count: 0,
        }
    }
}

impl qobject::Backend {
    pub fn increment(self: Pin<&mut Self>) {
        let next = *self.count() + 1;
        let mut this = self;
        this.as_mut().rust_mut().get_mut().count = next;
        this.count_changed();
    }

    pub fn reset(self: Pin<&mut Self>) {
        if *self.count() != 0 {
            let mut this = self;
            this.as_mut().rust_mut().get_mut().count = 0;
            this.count_changed();
        }
    }
}

#[cfg(test)]
mod tests {
    use super::BackendRust;

    #[test]
    fn default_state_matches_qml_contract() {
        let backend = BackendRust::default();
        assert_eq!(backend.greeting.to_string(), "Hello, world!");
        assert_eq!(backend.count, 0);
    }
}
