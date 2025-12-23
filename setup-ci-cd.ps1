# -----------------------------
# setup-ci-cd.ps1
# -----------------------------
# This script creates a full Java + Docker + CI/CD + Argo CD scaffold
# -----------------------------

# Step 0: Set project root
$projectRoot = "D:\demo-app"

# Step 1: Create folders
$folders = @(
    "$projectRoot/src/main/java/com/example/app",
    "$projectRoot/src/main/resources",
    "$projectRoot/k8s",
    "$projectRoot/.github/workflows"
)
foreach ($f in $folders) {
    if (-not (Test-Path $f)) {
        New-Item -Path $f -ItemType Directory -Force | Out-Null
    }
}

Write-Output "✅ Project folders created."

# Step 2: Create sample Java Maven app
$pomContent = @"
<project xmlns="http://maven.apache.org/POM/4.0.0"
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
 xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                     http://maven.apache.org/xsd/maven-4.0.0.xsd">
 <modelVersion>4.0.0</modelVersion>
 <groupId>com.example</groupId>
 <artifactId>my-java-app</artifactId>
 <version>0.0.1-SNAPSHOT</version>
 <properties>
     <java.version>17</java.version>
 </properties>
 <dependencies>
     <dependency>
         <groupId>org.springframework.boot</groupId>
         <artifactId>spring-boot-starter-web</artifactId>
     </dependency>
 </dependencies>
 <build>
     <plugins>
         <plugin>
             <groupId>org.springframework.boot</groupId>
             <artifactId>spring-boot-maven-plugin</artifactId>
         </plugin>
     </plugins>
 </build>
</project>
"@

Set-Content -Path "$projectRoot/pom.xml" -Value $pomContent
Write-Output "✅ pom.xml created."

# Step 3: Create sample Application.java
$appJava = @"
package com.example.app;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class Application {

    @GetMapping("/")
    public String hello() {
        return "Hello from CI/CD setup!";
    }

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
"@
Set-Content -Path "$projectRoot/src/main/java/com/example/app/Application.java" -Value $appJava
Write-Output "✅ Sample Application.java created."

# Step 4: Create Dockerfile
$dockerfile = @"
# Use OpenJDK 17
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY target/my-java-app-0.0.1-SNAPSHOT.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","app.jar"]
"@
Set-Content -Path "$projectRoot/Dockerfile" -Value $dockerfile
Write-Output "✅ Dockerfile created."

# Step 5: Create Kubernetes deployment + service
$k8sDeploy = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-java-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-java-app
  template:
    metadata:
      labels:
        app: my-java-app
    spec:
      containers:
      - name: my-java-app
        image: <DOCKER_REGISTRY>/my-java-app:latest
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: my-java-app-service
spec:
  selector:
    app: my-java-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
  type: LoadBalancer
"@
Set-Content -Path "$projectRoot/k8s/deployment.yaml" -Value $k8sDeploy
Write-Output "✅ Kubernetes manifests created."

# Step 6: Create GitHub Actions workflow (CI)
$githubActions = @'
name: CI-CD

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3

    - name: Set up JDK 17
      uses: actions/setup-java@v3
      with:
        java-version: "17"
        distribution: "temurin"

    - name: Build with Maven
      run: mvn clean package -DskipTests

    - name: Build Docker image
      run: docker build -t my-java-app:latest .

    - name: Scan image with Trivy
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: my-java-app:latest

    - name: SonarQube scan
      uses: sonarsource/sonarcloud-github-action@v2
      with:
        args: >
          -Dsonar.login=${{ secrets.SONAR_TOKEN }}
'@
Set-Content -Path "$projectRoot/.github/workflows/ci-cd.yml" -Value $githubActions
Write-Output "✅ GitHub Actions workflow created."

Write-Output "🎉 Project scaffold is ready at $projectRoot"
