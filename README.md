<img align="right" width="140" src="https://images.manning.com/360/480/resize/book/2/af4f618-f704-4bf5-9617-3e2db3e43e58/Psta-Istio-MEAP-HI.png">

# Istio in Action

This source code repository is a companion to the [Istio in Action](https://www.manning.com/books/istio-in-action?gclid=CjwKCAjwmK6IBhBqEiwAocMc8r1CbhNMku7SftXodMU3tmAOi0h665niLMkJF-4pQ0o6tiDaGGwUeBoCpLgQAvD_BwE) book available from Manning Publications.

## How to use this repository?

The files in this repository are used in the book to demonstrate the features of the service mesh. Each chapter's files are in their own directory, meanwhile, the services used across all the examples are in the `services` directory.

# Setup on Openshift 4x 
````shell
$ oc version
Client Version: 4.9.0-202112142229.p0.g96e95ce.assembly.stream-96e95ce
Server Version: 4.9.15
Kubernetes Version: v1.22.3+e790d7f

# install on mac
$ brew install istioctl

$ istioctl verify-install

1 Istio control planes detected, checking --revision "basic" only
error while fetching revision basic: the server could not find the requested resource
1 Istio injectors detected
Error: Istio present but verify-install needs an IstioOperator or manifest for comparison. Supply flag --filename <yaml>

````
# Deploying your first application in the service mesh
````shell script
$ export NS=istioinaction
$ export SMCP_NAMESPACE=istio-system
$ export SMCP_NAME=$(oc get smcp -n ${SMCP_NAMESPACE} -o jsonpath={.items..metadata.name})
$ export INGRESS_HOST_SHARD=10.36.5.10
$ export INGRESS_PORT=80
````


# Deploying your first application in the service mesh
````shell script
$ oc new-project ${NS}

# associate this project to controlPlane
$ cat <<EOF | oc apply -f -
apiVersion: maistra.io/v1
kind: ServiceMeshMember
metadata:
  name: default
spec:
  controlPlaneRef:
    name: ${SMCP_NAME}
    namespace: ${SMCP_NAMESPACE}
EOF

# view the association
$ oc get smmr -n ${SMCP_NAMESPACE} -o yaml | grep -A2 ${NS}

# Now let’s create the catalog deployment:
$ oc apply -f services/catalog/kubernetes/catalog.yaml -n ${NS}

$ oc get svc,pod

$ oc run -i -n ${NS} --rm --restart=Never curl --image=curlimages/curl --command -- sh -c 'curl -s http://catalog.istioinaction/items/1'

$ oc apply -f services/webapp/kubernetes/webapp.yaml -n ${NS}

$ oc run -i -n ${NS} --rm --restart=Never curl \
  --image=curlimages/curl --command -- \
  sh -c 'curl -s http://webapp.istioinaction/api/catalog/items/1'

$ oc port-forward deploy/webapp 8080:8080

$ oc apply -f ch2/ingress-gateway.yaml

$ curl http://localhost:8080/api/catalog/items/1

$ oc get route -n ${SMCP_NAMESPACE}
$ istioctl proxy-config routes deploy/istio-ingressgateway.istio-system -n ${NS}

$ GATEWAY_URL=$(oc get route istio-ingressgateway -n ${SMCP_NAMESPACE} --template='http://{{.spec.host}}')
$ echo ${GATEWAY_URL}
$ curl ${GATEWAY_URL}/api/catalog/items/1


$ while sleep .5; do curl http://localhost:8080/api/catalog; done
while true; do curl http://localhost:8080/api/catalog; sleep .5; done
````
