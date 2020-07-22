@Library('pipeline-lib') _
@Library('cve-monitor') __

def MAIN_BRANCH                    = 'master'
def DOCKER_REPOSITORY_NAME         = 'salemove/ephemeral-port-monitor'
def DOCKER_REGISTRY_URL            = 'https://registry.hub.docker.com'
def DOCKER_REGISTRY_CREDENTIALS_ID = '6992a9de-fab7-4932-9907-3aba4a70c4c0'

def generateTags = { version ->
  def major, minor, patch

  (major, minor, patch) = version.tokenize('.')

  [major, "${major}.${minor}", version]
}

withResultReporting(slackChannel: '#tm-engage') {
  inDockerAgent(containers: [imageScanner.container()]) {
    def image, version

    stage('Build') {
      checkout(scm)
      version = readFile('VERSION').trim()

      ansiColor('xterm') {
        image = docker.build(DOCKER_REPOSITORY_NAME)
      }
    }

    stage('Scan image') {
      imageScanner.scan(image)
    }

    if (BRANCH_NAME == MAIN_BRANCH) {
      stage('Publish docker image') {
        docker.withRegistry(DOCKER_REGISTRY_URL, DOCKER_REGISTRY_CREDENTIALS_ID) {
          generateTags(version).each { tag ->
            echo("Publishing docker image ${image.imageName()} with tag ${tag}")
            image.push(tag)
          }
        }
      }
    } else {
      echo("${BRANCH_NAME} is not the master branch. Not publishing the docker image.")
    }
  }
}
