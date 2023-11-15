

## Image settings
1. can either set tag to `lts-jdk11` and leave tag blank to get the latest version or set the tag version
2. Plugins are only compatible with v2.4+, init container will fail due to plugin incompatibility if a lower version of jenkins if used
    `controller:
    componentName: "jenkins-controller"
    image: "jenkins/jenkins"
    tag: "2.414.3-lts-jdk11"
    #tagLabel: lts-jdk11
    imagePullPolicy: "Always"`

## Ingress settings 
1. Settings below will work with AWS load balancer controller
2. Ensure the cert arn and hostnames are added to https access


  `ingress:
    enabled: true
    paths:
    - path: /
      pathType: Prefix
      backend:
        service:
          name: ssl-redirect
          port:
            name: use-annotation       
    - path: /
      backend:
        service:
          name: >- 
            {{ template "jenkins.fullname" . }}
          port:
            number: 8080
      pathType: Prefix    
    apiVersion: "networking.k8s.io/v1"
    labels: {}
    annotations:
      kubernetes.io/ingress.class: alb
      alb.ingress.kubernetes.io/load-balancer-name: jenkins-alb
      alb.ingress.kubernetes.io/scheme: internet-facing
      alb.ingress.kubernetes.io/target-type: ip
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}, {"HTTP":80}]'
      alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig": { "Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}'
      alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-west-1:488144151286:certificate/82bbed52-083b-422b-abc9-4cd226ad6084
      alb.ingress.kubernetes.io/healthcheck-path: /login
      alb.ingress.kubernetes.io/healthcheck-interval-seconds: '15'
      alb.ingress.kubernetes.io/healthcheck-timeout-seconds: '5'
      alb.ingress.kubernetes.io/success-codes: 200,302
      alb.ingress.kubernetes.io/healthy-threshold-count: '2'
      alb.ingress.kubernetes.io/unhealthy-threshold-count: '2'      
    ingressClassName: alb
    hostName: jenkins.chainomi.link`

## Persistence settings - ebs

`persistence:
  enabled: true
  storageClass: 
  annotations: {}
  labels: {}
  accessMode: "ReadWriteOnce"
  size: "8Gi"
  volumes:
  mounts:`
  
# Helm chart template  
Changed helm values.yml into a template. Used extra dollar sign to escape the terraform templating existing values in the yaml file e.g. `${chart-admin-username}` is now `$${chart-admin-username}`

# Jenkins troubleshooting
kubectl logs jenkins-0 -c init

kubectl describe pods jenkins-0