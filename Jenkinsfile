pipeline {
    agent any
    environment {
        PROJECT_ID = 'growcast-458911'       //GCP 프로젝트 ID
        CLUSTER_NAME = 'growcast-cluster'                  //GKE 클러스터 이름
        LOCATION = 'asia-northeast3-a'         //클러스터 위치
        CREDENTIALS_ID = 'c196b68d-3cd1-4f73-a7aa-55cb25204902'     //GCP  인증 정보 (Jenkins에서 설정한 Google 서비스 계정 키 파일)
        DOCKER_IMAGE = 'jjwon0407/growcast:${BUILD_ID}'  //Docker 이미지  이름
        
        JAVA_HOME = '/usr/lib/jvm/java-17-openjdk-amd64'
        PATH = "$JAVA_HOME/bin:$PATH"
    }
    tools {
        jdk 'openjdk-17-jdk'
    }
    stages {
        stage("Checkout code") {
            steps {
                script {
                    //Git 리포지토리에서 코드를 체크아웃합니다.
                    git url: 'https://github.com/jjwon0407/growcast_cicd.git', branch: 'develop'
                }
            }
        }
        stage('Grant execute permission to gradlew') {
            steps {
                script {
                    sh 'chmod +x ./gradlew'  // 권한 부여
                }
            }
        }
        stage('Build JAR') {
            steps {
                script {
                    // credentials 환경 변수를 사용하여 application.properties 파일을 업데이트
                    withCredentials([string(credentialsId: 'DB_URL', variable: 'DB_URL'),
                                     string(credentialsId: 'DB_USERNAME', variable: 'DB_USERNAME'),
                                     string(credentialsId: 'DB_PASSWORD', variable: 'DB_PASSWORD'),
                                     string(credentialsId: 'GCS_NAME', variable: 'GCS_NAME'),
                                     file(credentialsId: 'GCS', variable: 'GCS_PATH')]) {
                        sh '''
                            echo "DB_URL: $DB_URL"
                            echo "DB_USERNAME: $DB_USERNAME"
                            echo "DB_PASSWORD: [HIDDEN]"
                            echo "GCS_NAME: $GCS_NAME"
                            echo "GCS_PATH: $GCS_PATH"
                        '''

                        sh '''
                            echo "Using DB_URL=$DB_URL"
                            echo "Using DB_USERNAME=$DB_USERNAME"
                            echo "Using DB_PASSWORD=$DB_PASSWORD"
                            echo "Using GCS_NAME=$GCS_NAME"
                            echo "Using GCS_PATH=$GCS_PATH"

                            ./gradlew clean build -x test \
                            -Dspring.datasource.url=$DB_URL \
                            -Dspring.datasource.username=$DB_USERNAME \
                            -Dspring.datasource.password=$DB_PASSWORD \
                            -Dspring.cloud.gcp.storage.bucket=$GCS_NAME \
                            -Dspring.cloud.gcp.storage.credentials.location=$GCS_PATH \
                            -Dspring.test.env=true
                        '''
                    }
                }
            }
        }
        stage('Verify JAR File') {
            steps {
                sh 'ls -l build/libs/' // backend 디렉토리 내의 JAR 파일 목록 확인
            }
        }

        stage("Build image") {
            steps {
                script {
                    //Docker 이미지를 빌드
                    echo "Attempting to build Docker image..."
                    myapp = docker.build("jjwon0407/growcast:${env.BUILD_ID}", "--no-cache .")
                }
            }
        }

        stage("Push Docker image") {
            steps {
                script {
                    //Docker Hub에 이미지를 푸시
                    echo "Attempting to push Docker image..."
                    docker.withRegistry('https://registry.hub.docker.com', 'dockerHub') {
                            myapp.push("latest")
                            echo "Inside Docker registry block"
                            myapp.push("${env.BUILD_ID}")
                    }
                }
            }
        }

        stage('Deploy to GKE') {
		    when {
			    branch 'develop'
		    }
		    steps {
                script {
                    sh "sed -i 's/growcast:latest/growcast:${BUILD_ID}/g' deployment.yaml"
                    // 배포 전에 deployment.yaml 파일의 이미지를 최신 빌드 ID로 교체합니다.	

                    // Kubernetes Engine에 배포합니다.
                    step([$class: 'KubernetesEngineBuilder',
                          projectId: env.PROJECT_ID,
                          clusterName: env.CLUSTER_NAME,
                          location: env.LOCATION,
                          manifestPattern: 'deployment.yaml',
                          credentialsId: env.CREDENTIALS_ID,
                          verifyDeployments: true])
                }
            }
        }
    }

	post {
        always {
            script {
                sh 'docker stop growcast_jenkins${BUILD_ID} || true'
                sh 'docker rm growcast_jenkins${BUILD_ID} || true'
            }
            echo 'Pipeline completed.'
        }
        failure {
            script {
                echo "Build failed. Deleting the Docker image."
                sh 'docker rmi $DOCKER_IMAGE || true'
            }
        }
        success {
            echo 'Pipeline succeeded!'
        }
    }

}