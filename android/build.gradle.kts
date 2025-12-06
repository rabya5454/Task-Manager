// ✅ Define repositories for all projects
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ Add Google Services Plugin (Firebase)
plugins {
    id("com.google.gms.google-services") version "4.4.4" apply false
}

// ✅ Define Kotlin & Gradle versions
buildscript {
    dependencies {
        classpath("com.android.tools.build:gradle:8.13.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.24")
    }
}

// ✅ Adjust Build Directory Path
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// ✅ Ensure app module is evaluated first
subprojects {
    project.evaluationDependsOn(":app")
}

// ✅ Clean Task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}