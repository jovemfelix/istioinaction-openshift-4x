export INGRESS_HOST=$(oc get pod -l app=vsphere-infra-vrrp -o yaml -n openshift-vsphere-infra | grep -i '\-\-ingress-vip' -A1 | grep -v '\-\-ingress-vip\|--' | uniq | awk '{print $2}')
export INGRESS_PORT=80

# catalog
export H=catalog.istioinaction.io
curl -H "Host: $H" --resolve "$H:${INGRESS_PORT}:${INGRESS_HOST}" "http://$H:${INGRESS_PORT}/items"

oc apply -f default/catalog-deployment-v2.yaml
oc apply -f default/webapp.yaml
oc apply -f default/webapp-catalog-gw-vs.yaml
## canary
export H=catalog.istioinaction.io
curl -H "Host: $H" --resolve "$H:${INGRESS_PORT}:${INGRESS_HOST}" "http://$H:${INGRESS_PORT}/items"

for in in {1..10}; do curl -H "Host: $H" --resolve "$H:${INGRESS_PORT}:${INGRESS_HOST}" "http://$H:${INGRESS_PORT}/items"; printf "\n\n"; done


while sleep .5; do curl -IH "Host: $H" --resolve "$H:${INGRESS_PORT}:${INGRESS_HOST}" "http://$H:${INGRESS_PORT}/items"; done
while sleep .5; do curl -IH "Host: $H" -H "x-istio-cohort: internal" --resolve "$H:${INGRESS_PORT}:${INGRESS_HOST}" "http://$H:${INGRESS_PORT}/items"; done
while sleep .5; do curl -IH "Host: $H" -H "x-istio-cohort: internal" --resolve "$H:${INGRESS_PORT}:${INGRESS_HOST}" "http://$H:${INGRESS_PORT}/items"; done


export W=webapp.istioinaction.io



while sleep .5; do \
  curl -H "Host: ${W}" --resolve "${W}:${INGRESS_PORT}:${INGRESS_HOST}" "http://${W}:${INGRESS_PORT}/api/catalog"; done
