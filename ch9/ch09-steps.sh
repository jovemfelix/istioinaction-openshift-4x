
# VARIABLES
export INGRESS_HOST=10.36.5.2
export INGRESS_PORT=80
export INGRESS_HOST_SHARD=10.36.5.100

export NS_A=istioinaction
export NS_I=istio-system
export W=webapp.istioinaction.io

# Setup
alias p='oc get pods'
alias d='oc -n ${NS_A} delete deploy,svc,dr,gw,vs,smm --all'
alias a='oc -n ${NS_A} get gw,vs,dr,smm'
alias r='oc -n ${NS_I} get route --show-labels'
alias rg='oc -n ${NS_I} get route -l maistra.io/gateway-name=coolstore-gateway'

# oc new-project ${NS_A}
#oc apply -f ch5/catalog-gateway.yaml
#oc apply -f ch5/catalog-vs.yaml

oc -n ${NS_A} apply -f services/smm.yml
oc get smmr -n ${NS_I} -o yaml | grep -A 5 'configuredMembers'

oc -n ${NS_A} apply -f services/catalog/kubernetes/catalog.yaml
oc -n ${NS_A} apply -f services/webapp/kubernetes/webapp.yaml
oc -n ${NS_A} apply -f ch9/dummy.yaml
oc -n ${NS_A} apply -f ch9/sleep.yaml
oc -n default apply -f ch9/sleep.yaml
p

# Testing conectivity
oc get svc -n $NS_A
oc get svc -n default

# single test
# oc exec -it catalog-87c588888-5b2mt -c catalog -- curl --max-time 1 http://catalog:80/items
export DUMMY_POD=$(oc -n $NS_A get pod -l app=dummy -o jsonpath={.items..metadata.name})
export SLEEP_POD=$(oc -n $NS_A get pod -l app=sleep -o jsonpath={.items..metadata.name})
export SLEEP_POD_DEFAULT=$(oc -n default get pod -l app=sleep -o jsonpath={.items..metadata.name})
echo $SLEEP_POD
echo $SLEEP_POD_DEFAULT
echo $DUMMY_POD

oc apply -f ch9/meshwide-permissive-peer-authn.yaml

# all bellow works
oc -n $NS_A exec -it $DUMMY_POD -c dummy -- curl --max-time 1 http://catalog.$NS_A:80/items
oc -n $NS_A exec -it $SLEEP_POD -c sleep -- curl --max-time 1 http://catalog.$NS_A:80/items
oc -n $NS_A exec -it $SLEEP_POD -c sleep -- curl --max-time 1 http://webapp.$NS_A:80/api/catalog
oc -n default exec -it $SLEEP_POD_DEFAULT -c sleep -- curl --max-time 1 http://catalog.$NS_A:80/items
oc -n default exec -it $SLEEP_POD_DEFAULT -c sleep -- curl --max-time 1 http://webapp.$NS_A:80/api/catalog
oc -n $NS_A exec deploy/sleep -c sleep -- curl -s --max-time 1 webapp.istioinaction/api/catalog -o /dev/null -w "%{http_code}"
oc -n default exec deploy/sleep -c sleep -- curl -s --max-time 1 webapp.istioinaction/api/catalog -o /dev/null -w "%{http_code}"

# only works if has proxy...
oc apply -f ch9/meshwide-strict-peer-authn.yaml

oc -n $NS_A exec -it $DUMMY_POD -c dummy -- curl --max-time 1 http://catalog.$NS_A:80/items
oc -n $NS_A exec -it $SLEEP_POD -c sleep -- curl --max-time 1 http://catalog.$NS_A:80/items

oc -n ${NS_A} apply -f services/webapp/istio/webapp-catalog-gw-vs.yaml
rg

curl -sH 'Host: webapp.istioinaction.io' --resolve 'webapp.istioinaction.io:80:10.36.5.2' 'http://webapp.istioinaction.io:80/api/catalog'

oc -n default rsh deploy/sleep

oc -n default exec deploy/sleep -c sleep -- \
 curl -sH "Host: ${W}" --resolve "${W}:${INGRESS_PORT}:${INGRESS_HOST}" "http://${W}:${INGRESS_PORT}/api/catalog" \
 -o /dev/null -w "%{http_code}"


$ oc -n istio-system get PeerAuthentication default --template='{{.spec.mtls.mode}}'
PERMISSIVE


curl -sH "Host: ${W}" --resolve "${W}:${INGRESS_PORT}:${INGRESS_HOST_SHARD}" "http://${W}:${INGRESS_PORT}/api/catalog"
