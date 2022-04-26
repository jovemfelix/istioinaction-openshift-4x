export INGRESS_HOST=$(oc get pod -l app=vsphere-infra-vrrp -o yaml -n openshift-vsphere-infra | grep -i '\-\-ingress-vip' -A1 | grep -v '\-\-ingress-vip\|--' | uniq | awk '{print $2}')
export INGRESS_PORT=80
export INGRESS_HOST_SHARD=10.36.5.100


cat <<EOF | oc apply -f -
apiVersion: maistra.io/v1
kind: ServiceMeshMember
metadata:
  name: default
spec:
  controlPlaneRef:
    name: basic
    namespace: istio-system
EOF

# catalog
export H=catalog.istioinaction.io
curl -H "Host: $H" --resolve "$H:${INGRESS_PORT}:${INGRESS_HOST}" "http://$H:${INGRESS_PORT}/items"

oc apply -f default/catalog-deployment-v2.yaml
oc apply -f default/webapp.yaml
oc apply -f default/webapp-catalog-gw-vs.yaml
## canary
export H=catalog.istioinaction.io
curl -H "Host: $H" --resolve "$H:${INGRESS_PORT}:${INGRESS_HOST}" "http://$H:${INGRESS_PORT}/items"

for in in {1..100}; do curl -H "Host: $H" --resolve "$H:${INGRESS_PORT}:${INGRESS_HOST}" "http://$H:${INGRESS_PORT}/items"; printf "\n\n"; done

export W=webapp.istioinaction.io
export W=webapp.shard.io


while sleep .5; do \
  curl -H "Host: ${W}" --resolve "${W}:${INGRESS_PORT}:${INGRESS_HOST}" "http://${W}:${INGRESS_PORT}/api/catalog"; done


for i in {1..100}; do curl -s -H "Host: ${W}" --resolve "${W}:${INGRESS_PORT}:${INGRESS_HOST}" "http://${W}:${INGRESS_PORT}/api/catalog" \ -H "Host: ${W}" \
| grep -i imageUrl; done | wc -l

# 145
