buildscript {
    extra["kotlin_version"] = "2.0.0"
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    afterEvaluate {
        if (plugins.hasPlugin("com.android.library")) {
            val androidExt = extensions.findByName("android") as? com.android.build.gradle.LibraryExtension
            if (androidExt != null && androidExt.namespace == null) {
                androidExt.namespace = "com.example.${project.name.replace("-", "_")}"
            }
            // ponytail: force modern compileSdk on stale plugins (rich_clipboard
            // pins SDK 30, whose aapt can't resolve android:attr/lStar)
            androidExt?.compileSdkVersion(36)
        }
    }
    project.tasks.configureEach {
        if (name.startsWith("process") && name.endsWith("Manifest")) {
            doFirst {
                val manifestFile = file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val content = manifestFile.readText()
                    if (content.contains("package=")) {
                        val newContent = content.replace(Regex("""package="[^"]*""""), "")
                        manifestFile.writeText(newContent)
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
