lazy val appSettings = Seq(
  organization := "org.noetl",
  name := "noetl-hadoop-tools",
  version := "1.0"
)

// Those settings should be the same as in alchemy!
lazy val scalaVersion_ = "2.10.5" // should be the same as spark
lazy val javaVersion = "1.7" // should be the same as spark
lazy val sparkVersion = "1.6.0"
lazy val hadoopVersion = "2.6.4"

lazy val scalaCheckVersion = "1.12.5"
lazy val scalaTestVersion = "2.2.5"

scalaVersion in Global := scalaVersion_

scalacOptions in Global ++= Seq(
  "-deprecation",
  "-feature",
  "-target:jvm-" + javaVersion,
  "-Xlint"
)

javacOptions in Global ++= Seq(
  "-encoding", "UTF-8",
  "-source", javaVersion,
  "-target", javaVersion
)

lazy val auxLib = Seq(
  "org.apache.hadoop" % "hadoop-common" % hadoopVersion % Provided withSources() withJavadoc(),
  "org.apache.hadoop" % "hadoop-mapreduce-client-core" % hadoopVersion % Provided withSources() withJavadoc()
)

//removes _2.10 auto suffix in artifact name
crossPaths in Global := false

lazy val root = (project in file("."))
  .settings(appSettings: _*)
  .settings(
    libraryDependencies ++= auxLib
  )

fork in Global := true
