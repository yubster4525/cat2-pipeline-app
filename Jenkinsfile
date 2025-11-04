pipeline {
  agent any

  parameters {
    string(name: 'IMAGE_NAME', defaultValue: 'cat2-pipeline-app', description: 'Docker image name to build and deploy.')
    string(name: 'IMAGE_TAG', defaultValue: '', description: 'Optional image tag (defaults to Jenkins build number).')
    booleanParam(name: 'AUTO_DEPLOY', defaultValue: true, description: 'Toggle automatic deployment stage.')
  }

  environment {
    AWS_REGION = 'ap-south-1'
    ECR_REPOSITORY = 'cat2-pipeline-app'
    AWS_ACCOUNT_ID = credentials('aws-account-id')
    CLUSTER_NAME = 'cat2-cluster'
    SERVICE_NAME = 'cat2-service'
    EXECUTION_ROLE_ARN = 'arn:aws:iam::639230722149:role/ecsTaskExecutionRole'
    TASK_ROLE_ARN = ''
    LOG_GROUP = '/ecs/cat2-pipeline-app'
  }

  options {
    timestamps()
  }

  stages {
    stage('Prepare') {
      steps {
        script {
          env.RESOLVED_IMAGE_NAME = params.IMAGE_NAME?.trim() ? params.IMAGE_NAME.trim() : 'cat2-pipeline-app'
          env.RESOLVED_IMAGE_TAG = params.IMAGE_TAG?.trim() ? params.IMAGE_TAG.trim() : env.BUILD_NUMBER
          echo "Using Docker tag ${env.RESOLVED_IMAGE_NAME}:${env.RESOLVED_IMAGE_TAG}"
        }
      }
    }

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Install Dependencies') {
      steps {
        dir('app') {
          sh '''
            set -e
            node -v
            npm ci || npm install
          '''
        }
      }
    }

    stage('Unit Tests') {
      steps {
        dir('app') {
          sh 'npm test'
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        sh 'docker build --platform=linux/amd64 -t ${RESOLVED_IMAGE_NAME}:${RESOLVED_IMAGE_TAG} .'
      }
    }

    stage('Push to Amazon ECR') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-jenkins-creds']]) {
          sh '''
            set -e
            IMAGE_NAME=${RESOLVED_IMAGE_NAME} \
            IMAGE_TAG=${RESOLVED_IMAGE_TAG} \
            AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID} \
            AWS_REGION=${AWS_REGION} \
            ECR_REPOSITORY=${ECR_REPOSITORY} \
            ./scripts/push_to_ecr.sh
          '''
        }
      }
    }

    stage('Deploy to Amazon ECS') {
      when {
        expression { return params.AUTO_DEPLOY }
      }
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-jenkins-creds']]) {
          sh '''
            set -e
            IMAGE_NAME=${RESOLVED_IMAGE_NAME} \
            IMAGE_TAG=${RESOLVED_IMAGE_TAG} \
            AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID} \
            AWS_REGION=${AWS_REGION} \
            ECR_REPOSITORY=${ECR_REPOSITORY} \
            CLUSTER_NAME=${CLUSTER_NAME} \
            SERVICE_NAME=${SERVICE_NAME} \
            EXECUTION_ROLE_ARN=${EXECUTION_ROLE_ARN} \
            TASK_ROLE_ARN=${TASK_ROLE_ARN} \
            LOG_GROUP=${LOG_GROUP} \
            ./scripts/deploy_to_ecs.sh
          '''
        }
      }
    }
  }

  post {
    success {
      echo "SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER} — deployed ${env.RESOLVED_IMAGE_NAME}:${env.RESOLVED_IMAGE_TAG}"
    }
    failure {
      echo "FAILURE: ${env.JOB_NAME} #${env.BUILD_NUMBER}. Check console output."
    }
  }
}
