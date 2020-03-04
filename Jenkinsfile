#!/usr/bin/env groovy

// Match environment branch name against enterprise name regex
def isEnterpriseBranch() {
    if ("${BRANCH_NAME}" ==~ /enterprise-[\d.]+/) {
        return true
    }
    return false
}

// Check if component was modified
def is_modified(String component){
    def modified = sh(
        script: "test/bin/git_diff.sh ${component}",
        returnStdout: true
    ).trim()

    return modified.toBoolean()
}

// Set build type based on branch
def get_build_type(){
    def build_type = "cloud"

    if (isEnterpriseBranch()) {
        build_type = "on-premises"
    }
    else if (env.BRANCH_NAME == 'local') {
        build_type = "dev"
    }
    else if (env.BRANCH_NAME == 'master' || env.BRANCH_NAME == 'canary'){
        build_type = "dev"
    }

    return build_type
}

// Which modified files/directories should trigger a build?
def should_run(){
    if ( env.JENKINSFILE_MODIFIED == "true" || env.TEST_MODIFIED == "true" || env.CHARTS_MODIFIED == "true"){
        return true
    }
    else {
        return false
    }
}

pipeline {
    options {
        skipDefaultCheckout true
    }

    agent {
        kubernetes {
            customWorkspace 'build'
            yamlFile 'test/build_pod.yaml'
        }
    }

    stages {
        stage ('Clone') {
            steps {
                script {
                    def scmVars = checkout([$class: 'GitSCM',
                        branches: [[name: "*/${BRANCH_NAME}"], [name: "master"]],
                        doGenerateSubmoduleConfigurations: false,
                        gitTool: 'autogit',
                        userRemoteConfigs: [[credentialsId: 'gitprime-infra-ops', refspec: '+refs/heads/master:refs/remotes/origin/master +refs/heads/*:refs/remotes/origin/*', url: 'https://github.com/Git-Prime/gphelm-chart-repo.git']]])
                    env.GIT_COMMIT="${scmVars.GIT_COMMIT}"
                    env.GIT_BRANCH = "${scmVars.GIT_BRANCH}"
                    env.GIT_PREVIOUS_COMMIT = "${scmVars.GIT_PREVIOUS_COMMIT}"
                    env.GIT_PREVIOUS_SUCCESSFUL_COMMIT = "${scmVars.GIT_PREVIOUS_SUCCESSFUL_COMMIT}"
                    env.CHARTS_MODIFIED=is_modified("charts")
                    env.JENKINSFILE_MODIFIED=is_modified("Jenkinsfile")
                    env.TEST_MODIFIED=is_modified('test')
                }
                sh 'export'
            }
        }
        stage('Run tests'){
            stages {
                stage('Shellcheck'){
                    when {
                        allOf {
                            expression { should_run() }
                        }
                    }
                    steps {
                        container('shellcheck'){
                            sh "#!/bin/sh \n"+
                               "shellcheck -x test/*.sh"
                        }
                    }
                }
                stage('Lint charts'){
                    when {
                        allOf {
                            expression { should_run() }
                        }
                    }
                    steps {
                        container('charts-ci'){
                            sh "#!/bin/sh \n"+
                               "ct lint --config test/ct.yaml"
                        }
                   }
                }
                stage('Charts e2e'){
                    when {
                        allOf {
                            expression { should_run() }
                        }
                    }
                    steps {
                        container('kind'){
                            sh 'test/e2e-kind.sh'
                        }
                    }
                }
            }//stages
        }//Run tests
    }//stages
}//pipeline
