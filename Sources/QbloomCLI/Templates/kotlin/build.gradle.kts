import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins { id("org.jetbrains.kotlin.jvm") version "2.4.10" }

repositories { mavenCentral() }

kotlin { compilerOptions { jvmTarget = JvmTarget.JVM_21 } }

java {
    sourceCompatibility = JavaVersion.VERSION_21
    targetCompatibility = JavaVersion.VERSION_21
}

tasks.register<JavaExec>("logicTest") {
    dependsOn(tasks.testClasses)
    classpath = sourceSets.test.get().runtimeClasspath
    mainClass = "qbloom.app.BackendTest"
}

tasks.register<JavaExec>("qtRun") {
    dependsOn(tasks.classes)
    classpath = sourceSets.main.get().runtimeClasspath
    mainClass = "qbloom.app.Main"
    jvmArgs("--enable-native-access=ALL-UNNAMED")
    if (System.getProperty("os.name").startsWith("Mac")) {
        jvmArgs("-XstartOnFirstThread")
    }
    environment("QBLOOM_NATIVE_LIBRARY", providers.gradleProperty("qbloomNativeLibrary").orNull ?: "")
    val appArgs = providers.gradleProperty("qbloomAppArgs").orNull
    if (!appArgs.isNullOrEmpty()) args(appArgs.split("\u001f"))
}
