allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

tasks.register("prepareFirebaseConfig") {
    doLast {
        val scriptPath = rootProject.projectDir.parentFile.resolve("scripts/generate_firebase_config.js")
        val nodeCommand = if (System.getProperty("os.name").lowercase().contains("win")) "node.cmd" else "node"
        
        exec {
            commandLine(nodeCommand, scriptPath.absolutePath)
        }
    }
}

tasks.named("preBuild").configure {
    dependsOn("prepareFirebaseConfig")
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
