$ export INGRESS_HOST=$(oc get pod -l app=vsphere-infra-vrrp -o yaml -n openshift-vsphere-infra | grep -i '\-\-ingress-vip' -A1 | grep -v '\-\-ingress-vip\|--' | uniq | awk '{print $2}')
export INGRESS_PORT=80
$ curl ${INGRESS_HOST}/api/catalog/items/1
$ curl ${GATEWAY_URL}/api/catalog/items/1


export H=catalog.istioinaction.io
curl -IH "Host: $H" --resolve "$H:${INGRESS_PORT}:${INGRESS_HOST}" "http://$H:${INGRESS_PORT}/items"


GATEWAY_URL=$(oc get route istio-ingressgateway -n ${SMCP_NAMESPACE} --template='http://{{.spec.host}}')
echo $GATEWAY_URL


## canary
export H=catalog.istioinaction.io
curl -H "Host: $H" --resolve "$H:${INGRESS_PORT}:${INGRESS_HOST}" "http://$H:${INGRESS_PORT}/items"


for in in {1..10}; do curl -H "Host: $H" --resolve "$H:${INGRESS_PORT}:${INGRESS_HOST}" "http://$H:${INGRESS_PORT}/items"; printf "\n\n"; done


while sleep .5; do curl -IH "Host: $H" --resolve "$H:${INGRESS_PORT}:${INGRESS_HOST}" "http://$H:${INGRESS_PORT}/items"; done
while sleep .5; do curl -IH "Host: $H" -H "x-istio-cohort: internal" --resolve "$H:${INGRESS_PORT}:${INGRESS_HOST}" "http://$H:${INGRESS_PORT}/items"; done
while sleep .5; do curl -IH "Host: $H" -H "x-istio-cohort: internal" --resolve "$H:${INGRESS_PORT}:${INGRESS_HOST}" "http://$H:${INGRESS_PORT}/items"; done


export H=webapp.istioinaction.io
curl -H "Host: $H" --resolve "$H:${INGRESS_PORT}:${INGRESS_HOST}" "http://$H:${INGRESS_PORT}/api/catalog"
curl -H "Host: $H" --resolve "$H:${INGRESS_PORT}:${INGRESS_HOST_SHARD}" "http://$H:${INGRESS_PORT}/api/catalog"

export S=webapp.shard.io
curl -H "Host: $S" --resolve "$S:${INGRESS_PORT}:${INGRESS_HOST_SHARD}" "http://$S:${INGRESS_PORT}/api/catalog"

for i in {1..100}; do curl -H "Host: $H" --resolve "$H:${INGRESS_PORT}:${INGRESS_HOST}" "http://$H:${INGRESS_PORT}/api/catalog" \ -H "Host: webapp.istioinaction.io" \
| grep -i imageUrl; done | wc -l


curl -H "Host: webapp.shard.io" --resolve "webapp.shard.io:80:10.36.5.100" "http://webapp.shard.io:${INGRESS_PORT}/api/catalog" -H "Host: webapp.shard.io"
###
# cleanup
oc delete deployment,svc,gateway,virtualservice,destinationrule --all -n istioinaction

f tmp/default/
p
## test using route default
export D=catalog.istioinaction.io
curl -H "Host: $D" --resolve "$D:${INGRESS_PORT}:${INGRESS_HOST}" "http://$D:${INGRESS_PORT}/items"

## test using route shard
f tmp/shard/
export S=catalog.shard.io
curl -H "Host: ${S}" --resolve "${S}:${INGRESS_PORT}:${INGRESS_HOST}" "http://${S}:${INGRESS_PORT}/items"
curl -H "Host: ${S}" --resolve "${S}:${INGRESS_PORT}:${INGRESS_HOST_SHARD}" "http://${S}:${INGRESS_PORT}/items"

## test using route shard WITH HTTPD
export T=httpd.shard.io
curl -IH "Host: ${T}" --resolve "${T}:${INGRESS_PORT}:${INGRESS_HOST}" "http://${T}"
curl -IH "Host: ${T}" --resolve "${T}:${INGRESS_PORT}:${INGRESS_HOST_SHARD}" "http://${T}"


oc policy add-role-to-user admin system:serviceaccount:${NS}:default -n app-shard
oc policy add-role-to-user view -z default
