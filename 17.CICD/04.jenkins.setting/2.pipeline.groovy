//=======================================================================================
// 2020-06-15  Edit for AWS EKS, ECR
// 
// 변수처리 하려면 명령어를 "" 로 묶어야 한다. ''로 묶으면 PlainText 처리해버림
// env.GIT_CREDENTIAL	= Credential Username / Password
// env.GIT_URL          = http://gitlab-ce.infra.svc.cluster.local/skcc05599/restapi.git
// env.DOCKER_REGISTRY  = 847322629192.dkr.ecr.ap-northeast-2.amazonaws.com
// env.DOCKER_REPO		= restapi
// env.DOCKER_TAG		= 1.0
// imagetag				= 847322629192.dkr.ecr.ap-northeast-2.amazonaws.com/restapi:1.0
//=======================================================================================

def label    = "jenkins-slave-jnlp-${UUID.randomUUID().toString()}"
def imagetag = env.DOCKER_REGISTRY + "/" + DOCKER_REPO + ":" + env.DOCKER_TAG

def ecr_regi = "https://" + env.DOCKER_REGISTRY
def ecr_cred = "empty"

podTemplate(label: label, cloud: 'kubernetes', serviceAccount: 'jenkins',
     containers: [
        containerTemplate(name: 'jnlp', image: 'jenkins/jnlp-slave:3.27-1', args: '${computer.jnlpmac} ${computer.name}',
            envVars: [
                envVar(key: 'JVM_HEAP_MIN', value: '-Xmx192m'),
                envVar(key: 'JVM_HEAP_MAX', value: '-Xmx192m')
            ]
        ),
        containerTemplate(name: 'maven',    image: 'maven:3.6.1-jdk-8-alpine',          ttyEnabled: true, command: 'cat'),
		containerTemplate(name: 'awscli',   image: 'amazon/aws-cli:2.0.22',             ttyEnabled: true, command: 'cat'),		
        containerTemplate(name: 'docker',   image: 'docker:18.09',                      ttyEnabled: true, command: 'cat', resourceLimitMemory: '128Mi'),
        containerTemplate(name: 'kubectl',  image: 'lachlanevenson/k8s-kubectl:latest', ttyEnabled: true, command: 'cat', resourceLimitMemory: '256Mi')
    ],
    volumes:[
        hostPathVolume(mountPath: '/var/run/docker.sock',   hostPath: '/var/run/docker.sock'),
        persistentVolumeClaim(mountPath: '/home/jenkins/workspace', claimName: 'jenkins-workspace'),
        persistentVolumeClaim(mountPath: '/root/.m2',               claimName: 'jenkins-maven-repo'),
        // hostPathVolume(mountPath: '/etc/hosts',             hostPath: '/etc/hosts')
    ])
{
	node(label) {
		stage('CheckOut Source') { // gitLab API Plugin, gitLab Plugin
			git branch: "master", credentialsId: env.GIT_CREDENTIAL, url: env.GIT_URL
		}
            
		stage('Build Maven') {  // Maven Integration:3.3
			container('maven') {
				sh "mvn clean"
				// sh "wget https://maven.xwiki.org/externals/com/oracle/jdbc/ojdbc8/12.2.0.1/ojdbc8-12.2.0.1.jar"
				// sh 'mvn install:install-file -Dfile="ojdbc8-12.2.0.1.jar" -DgroupId=com.oracle -DartifactId=ojdbc8 -Dversion=12.2.0.1 -Dpackaging=jar'
				
				sh "mvn -f ./pom.xml -B -DskipTests package" // clean package
				sh "cp ./target/app-1.0.jar ."
			}
		}
			
		stage('ECR Login') {
			container('awscli') {
				script {
					sh "aws ecr get-login-password --region ap-northeast-2"
					ecr_cred = sh(script: 'aws ecr get-login-password --region ap-northeast-2', returnStdout: true)
				}
			}
		}
            
		stage('Build and Push Docker Image') {
			container('docker') {
				sh "docker build -t ${imagetag} -f ./docker/Dockerfile ."		
				sh "docker login -u AWS -p '${ecr_cred}' ${ecr_regi}"		
				sh "docker push ${imagetag}"		
				
				// docker.withRegistry("${ecr_regi}") {		
				// docker.withRegistry('https://847322629192.dkr.ecr.ap-northeast-2.a	mazonaws.com') {	
				// docker.withRegistry('https://847322629192.dkr.ecr.ap-northeast-2.a	mazonaws.com', 'ECR_CR	EDENTIAL') {
				// withDockerRegistry([url: "https://536703334988.dkr.ecr.ap-southeas	t-2.amazonaws.com/test	-repository",credentialsId: "ecr:ap-southeast-2:demo-ecr-credentials"])
				// docker.withRegistry('https://847322629192.dkr.ecr.ap-northeast-2.a	mazonaws.com') {	
				// withRegistry('https://847322629192.dkr.ecr.ap-northeast-2.amazonaw	s.com', 'ECR_CREDENTIA	L') {
				// withCredentials([usernameColonPassword(credentialsId: 'ECR_CREDENT	IAL', variable: 'USERP	ASS')]) {
				// withCredentials([UsernamePasswordMultiBinding(credentialsId: 'ECR_	CREDENTIAL', usernameV	ariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
				// withCredentials([usernamePassword(credentialsId: 'ECR_CREDENTIAL',	 usernameVariable: 'US	ERNAME', passwordVariable: 'PASSWORD')]) {                        
			
				// withCredentials([usernamePassword(credentialsId: 'ECR_CREDENTIAL',	 usernameVariable: 'US	ERNAME', passwordVariable: 'PASSWORD')]) {
				// sh "set +x; echo ${USERNAME}; echo ${PASSWORD}"		
				// sh "echo -u ${USERNAME}"		
				// sh "echo -p ${PASSWORD}"		
			
				// sh "docker login -u '${USERNAME}' -p '${PASSWORD}' ${ecr_regi}"		
				// => Error response from daemon: login attempt to https://8473226291	92.dkr.ecr.ap-northeas	t-2.amazonaws.com/v2/ failed with status: 400 Bad Request
			
				// sh "docker login -u '${USERNAME}' -p '${PASSWORD}' https://8473226	29192.dkr.ecr.ap-north	east-2.amazonaws.com"
				// => Error response from daemon: login attempt to https://847322629192.dkr.ecr.ap-northeast-2.amazonaws.com/v2/ failed with status: 400 Bad Request
			}
		}
				
		stage('k8s Update Deployment Image = ${imagetag}') {
			container('kubectl') {
				sh "kubectl delete -f ./kubernetes/deployment.yaml"
				sh "kubectl apply -f  ./kubernetes/deployment.yaml"
				sh "kubectl get deploy,pod -n infra -l app=restapi"
				
				// sh "kubectl apply -f ./kubernetes/service.yaml"  // service.yaml 은 초기 테스트시에 구성해야함 ( 그래야지 ㅡ_ㅡ )
				// sh "kubectl apply -f ./kubernetes/ingress.yaml"  // ingress.yaml 은 초기 테스트시에 구성해야함 ( 그래야지 ㅡ_ㅡ )
			}
		}
	}
}
