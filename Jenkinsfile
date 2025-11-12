pipeline {
  agent any

  tools {
    nodejs 'Node18'
  }

  parameters {
    string(name: 'IMAGE_NAME', defaultValue: 'cat2-pipeline-app', description: 'Docker image name to build and deploy.')
    string(name: 'IMAGE_TAG', defaultValue: '', description: 'Optional image tag (defaults to Jenkins build number).')
    booleanParam(name: 'AUTO_DEPLOY', defaultValue: true, description: 'Toggle automatic deployment stage.')
  }

  environment {
    PATH = "/opt/homebrew/bin:/usr/local/bin:${env.PATH}"
    AWS_REGION = 'ap-south-1'
    ECR_REPOSITORY = 'cat2-pipeline-app'
    AWS_ACCOUNT_ID = credentials('aws-account-id')
    CLUSTER_NAME = 'cat2-cluster'
    SERVICE_NAME = 'cat2-service'
    EXECUTION_ROLE_ARN = 'arn:aws:iam::639230722149:role/ecsTaskExecutionRole'
    TASK_ROLE_ARN = 'arn:aws:iam::639230722149:role/ecsTaskExecutionRole'
    LOG_GROUP = '/ecs/cat2-pipeline-app'
    NOTIFY_RECIPIENTS = 'devops-team@example.com'
  }

  options {
    timestamps()
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Prepare Metadata') {
      steps {
        script {
          env.RESOLVED_IMAGE_NAME = params.IMAGE_NAME?.trim() ? params.IMAGE_NAME.trim() : 'cat2-pipeline-app'
          def gitShort = env.GIT_COMMIT?.take(7)
          env.RESOLVED_IMAGE_TAG = params.IMAGE_TAG?.trim() ? params.IMAGE_TAG.trim() : (gitShort ?: env.BUILD_NUMBER)
          echo "Using Docker tag ${env.RESOLVED_IMAGE_NAME}:${env.RESOLVED_IMAGE_TAG}"
        }
      }
    }

    stage('Install Dependencies') {
      steps {
        dir('app') {
          sh '''
            set -e
            node -v
            npm ci
          '''
        }
      }
    }

    stage('Lint') {
      steps {
        dir('app') {
          sh 'npm run lint'
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
        withCredentials([usernamePassword(
            credentialsId: 'aws-jenkins-creds',
            usernameVariable: 'AWS_ACCESS_KEY_ID',
            passwordVariable: 'AWS_SECRET_ACCESS_KEY'
        )]) {
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
        withCredentials([usernamePassword(
            credentialsId: 'aws-jenkins-creds',
            usernameVariable: 'AWS_ACCESS_KEY_ID',
            passwordVariable: 'AWS_SECRET_ACCESS_KEY'
        )]) {
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
      echo "✅ SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
      echo "Image ${env.RESOLVED_IMAGE_NAME}:${env.RESOLVED_IMAGE_TAG} deployed"
    }
    failure {
      echo "❌ FAILURE: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
    }
  }
}
