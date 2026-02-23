allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

tasks.register("prepareFirebaseConfig") {
    doLast {
        val scriptPath = rootProject.projectDir.parentFile.resolve("scripts/generate_firebase_config.js")
        if (!scriptPath.exists()) return@doLast
        try {
            exec {
                commandLine("node", scriptPath.absolutePath)
                isIgnoreExitValue = true
            }
        } catch (e: Exception) {
            // Node pode não estar no PATH quando o Gradle roda; build continua
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
