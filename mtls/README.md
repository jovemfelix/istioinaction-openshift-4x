# Set up the cluster
> Create two namespaces, foo and bar, and deploy httpbin and sleep with sidecars on both of them:
````shell script
oc new-project foo
oc adm policy add-scc-to-user anyuid -z httpbin -n foo

# vinculate to service mesh
oc apply -f files/smm.yml -n bar
oc apply -f files/httpbin/httpbin.yml -n foo
oc apply -f files/sleep/sleep.yml -n foo

oc new-project bar
oc adm policy add-scc-to-user anyuid -z httpbin -n bar
oc apply -f files/smm.yml -n bar
oc apply -f files/httpbin/httpbin.yml -n bar
oc apply -f files/sleep/sleep.yml -n bar

````
> Create another namespace, legacy, and deploy sleep without a sidecar:
```shell
oc new-project legacy
oc apply -f files/sleep/sleep.yml -n legacy
```

> Verify the setup by sending http requests (using curl) from the sleep pods, in namespaces foo, bar and legacy, to httpbin.foo and httpbin.bar. All requests should succeed with return code 200.
  
```shell
# single test
export SLEEP_POD=$(oc get pod -l app=sleep -o jsonpath={.items..metadata.name})
oc exec -it $SLEEP_POD -c sleep -- curl http://httpbin.foo.svc.cluster.local:8000/ip

# full test
$ sh files/test-conectivity.sh
sleep.foo       to httpbin.foo:         200
sleep.foo       to httpbin.bar:         200
sleep.foo       to httpbin.legacy:      000
command terminated with exit code 6
sleep.bar       to httpbin.foo:         200
sleep.bar       to httpbin.bar:         200
sleep.bar       to httpbin.legacy:      000
command terminated with exit code 6
sleep.legacy    to httpbin.foo:         000
command terminated with exit code 28
sleep.legacy    to httpbin.bar:         000
command terminated with exit code 28
sleep.legacy    to httpbin.legacy:      000
command terminated with exit code 6
```

# Validation of HTTPBIN
```shell
oc run -i --rm --restart=Never dummy --image=dockerqa/curl:ubuntu-trusty --command -- curl --silent --head httpbin:8000/status/201
oc run -i --rm --restart=Never dummy --image=dockerqa/curl:ubuntu-trusty --command -- curl --silent httpbin:8000/ip
```
