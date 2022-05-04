list=( "foo" "bar" "legacy" )
for from in ${list[*]}; do \
    for to in ${list[*]}; do \
        oc exec "$(oc get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name})" -c sleep -n ${from} -- curl http://httpbin.${to}:8000/ip --max-time 1 -s -o /dev/null -w "sleep.${from} \tto httpbin.${to}: \t%{http_code}\n"; 
    done; 
done