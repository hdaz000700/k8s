#!/usr/bin/env bash

# make sure we have decent error handling for bash scripts
# set -o errexit -o noglob -o nounset -o pipefail

function  _blank_line () {
    echo " "
}

    _blank_line
    echo "___ cluster info ___"
    _blank_line
    kubectl cluster-info
    _blank_line

    echo "___ ingress ___"
    _blank_line
    kubectl get service --all-namespaces | grep --color=auto -i ingress
    kubectl get pods --all-namespaces | grep --color=auto -i ingress
    # kubectl get ing --all-namespaces
    # Traefik Ingress https://doc.traefik.io/traefik/providers/kubernetes-ingress
    #
    _blank_line

    # CRI-O
    # kubectl top pods -A | grep -i crio
    # crio config | grep enable_pod_events

    echo "___ network ___"
    _blank_line
    kubectl get networkpolicies --all-namespaces
    _blank_line

    # Network Policy Provider - Antrea - Calico - Cilium - Kube-router - Romana - Weave Net

    echo "___ cert-manager ___" #https://github.com/cert-manager/cert-manager   https://cert-manager.io/docs/troubleshooting
    _blank_line
    kubectl get certificate --all-namespaces
    _blank_line

    echo "___ configmaps ___"
    _blank_line
    kubectl get configmaps --all-namespaces
    _blank_line

    echo "___ deployments ___"
    _blank_line
    kubectl get deployments --all-namespaces -o wide
    _blank_line

    echo "___ get services ___"
    _blank_line
    kubectl get services --all-namespaces -o wide
    _blank_line

    echo "___ get nodes ___"
    _blank_line
    kubectl get nodes --all-namespaces -o wide
    _blank_line

    echo "___ get pods ___"
    _blank_line
    kubectl get pods --all-namespaces -o wide
    _blank_line
    echo "___ top pods cpu ___"
    kubectl top pods --all-namespaces --sort-by=cpu | head -20
    _blank_line
    echo "___ top pods mem ___"
    kubectl top pods --all-namespaces --sort-by=memory | head -20
    _blank_line
    echo "___ evicted pods ___"
    kubectl get pods -A | awk '{ printf "%s,%s,%s\n", $1,$2,$4} ' | grep -i -E "Evicted"
    _blank_line
    echo "___ get pod labels ___"
    kubectl get pods --show-labels --all-namespaces
    _blank_line
    echo "___ get pod images ___"
    kubectl get pods -o json --all-namespaces | jq .items[].spec.containers[].image | sort | uniq

    _blank_line
    echo "__ get storage persistentvolumes ___"
    kubectl get persistentvolumes -o wide
    _blank_line
    echo "___ get storage persistentvolumeclaims ___"
    _blank_line
    kubectl get persistentvolumeclaims --all-namespaces -o wide
    _blank_line

    echo "___ get statefulsets ___"
    _blank_line
    kubectl get statefulsets --all-namespaces -o wide
    _blank_line

    echo "___ get daemonsets  ___"
    _blank_line
    kubectl get daemonsets --all-namespaces -o wide
    _blank_line

    echo "___ get crds ___"
    _blank_line
    kubectl get crds
    _blank_line

    echo "___ get events ___"
    _blank_line
    kubectl get events --all-namespaces --field-selector type!=Normal -o yaml
    _blank_line

    echo "___ get providers ___"
    _blank_line
    kubectl get providers -o wide --all-namespaces
    _blank_line

    echo "___ k8s gitops argo - flux - circle ___"
    _blank_line
    kubectl get pods --all-namespaces | grep --color=auto -i -E "flux|argo|circle"
    _blank_line

    echo "___ secrets ___ "
    _blank_line
    kubectl get secrets --all-namespaces
    _blank_line

    echo "___ virtualservices ___ "
    _blank_line
    kubectl get virtualservices --all-namespaces
    _blank_line

    echo "___ flux ___ "
    _blank_line
    flux stats
    flux get all
    flux get helmrelease --all-namespaces
    _blank_line

    echo "___ flux logs ___ "
    _blank_line
    flux logs --all-namespaces | grep -v "info "
    # flux logs --kind kustomization -A
    _blank_line

    echo "___ flux events  ___"
    _blank_line
    flux events
    _blank_line

    echo "___ flux helm  ___"
    _blank_line
    helm list --failed --all-namespaces
    # helm ls -a --all-namespaces
    _blank_line

    echo "___ helm manifests  ___"
    _blank_line
    namespaces=$( kubectl get namespaces -o=jsonpath='{.items[*].metadata.name}' )
    for namespace in $namespaces; do
        echo "Namespace: $namespace"
        releases=$( helm list -n $namespace -q )

        for release in $releases; do
            echo "Release: $release"
            helm history -n $namespace $release
        done
    done
    _blank_line

    echo "___ constraints Enforcement-Action and Violations ___ "
    _blank_line
    kubectl get constraints
    _blank_line

### ISTIO
    echo "___ istio pods  ___ "
    _blank_line
    kubectl get pod -n istio-system
    _blank_line

    echo "___ istio gateway ip and node port  ___ "
    _blank_line
    _GATEWAY_URL=$(kubectl get po -l istio=ingressgateway -n istio-system -o 'jsonpath={.items[0].status.hostIP}'):$(kubectl get svc istio-ingressgateway -n istio-system -o 'jsonpath={.spec.ports[0].nodePort}')
    echo "${_GATEWAY_URL}"
    _blank_line

    echo "___ istio gateway logs summary ___ "
    echo "10000 lines"
    _ISTIO_LOGS=$( kubectl -n istio-system logs $(kubectl -n istio-system get pods -listio=ingressgateway -o=jsonpath={.items[0].metadata.name}) --tail=10000 )
    echo "${_ISTIO_LOGS}" | head -1
    echo "${_ISTIO_LOGS}" | tail -1
    _blank_line
    echo "info messages"
    echo "${_ISTIO_LOGS}" | grep -i "info" | wc -l
    _blank_line
    echo "error messages"
    echo "${_ISTIO_LOGS}" | grep -i "error" | wc -l
    _blank_line

    echo "___ istio gateway logs ___"
    echo "${_ISTIO_LOGS}"
    _blank_line

    echo "___ istio analyze  ___ "
    _blank_line
    istioctl analyze --all-namespaces
    _blank_line

    echo "___ istio proxy-status ___"
    _blank_line
    istioctl proxy-status
    _blank_line

    echo "___ istio proxy-config cluster  ___"
    _ISTIO_GATEWAY=$( kubectl get pods -n istio-system | grep -i istio-ingressgateway | grep -i Running | awk '{ print $1 }' | head -1 )
    _blank_line
    istioctl proxy-config cluster -n istio-system "${_ISTIO_GATEWAY}"
    _blank_line

    echo "___ istio ingressgateway ps aux  ___"
    _blank_line
    kubectl -n istio-system exec "${_ISTIO_GATEWAY}" ps aux
    _blank_line

    echo "___ istio proxy-config cluster   ___"
    _blank_line
    istioctl -n istio-system proxy-config cluster "${_ISTIO_GATEWAY}"
    _blank_line

    echo "___ istio proxy-config endpoint   ___"
    _blank_line
    istioctl -n istio-system proxy-config endpoint "${_ISTIO_GATEWAY}"
    _blank_line

    echo "___ istio proxy-config listener  ___"
    _blank_line
    istioctl -n istio-system proxy-config listener "${_ISTIO_GATEWAY}"
    _blank_line

    echo "___ istio proxy-config route  ___"
    _blank_line
    istioctl -n istio-system proxy-config route "${_ISTIO_GATEWAY}"
    _blank_line

    echo "___ istio proxy-config secret  ___"
    _blank_line
    istioctl -n istio-system proxy-config secret "${_ISTIO_GATEWAY}"
    _blank_line

    echo "___ istio pods versions  ___"
    _blank_line
    _PODS=$( kubectl get pods --all-namespaces | grep -i Running | awk '{ print $1, $2 }' )
    echo "${_PODS}" | grep -v -i -E "aad-pod-identity|kube-system|calico-system|istio-system|istio-operator" | parallel -j10 --colsep ' ' '
    namespace={1}
    pod={2}
    echo " "
    echo "_____________ $namespace $pod _____________"
    echo " "
    kubectl describe pod $pod -n $namespace | grep -n -i "istio" | grep -i "Image:" '
    _blank_line

### ISTIO END

    echo "___ lists all published API kinds available ___ "
    _blank_line
    kubectl api-resources -o wide
    _blank_line

    echo "___ get roles ___"
    _blank_line
    kubectl get roles
    _blank_line

    echo "___ get rolebindings ___"
    _blank_line
    kubectl get rolebindings --all-namespaces -o wide
    _blank_line

    echo "___ get default namespace  ___"
    _blank_line
    kubectl get pods --namespace default
    _blank_line

    echo "___ check for port-forwards ___ "
    _blank_line
    kubectl get pod --all-namespaces -o json | jq -r '.items[] | select(.spec.containers[].command | contains(["port-forward"])) | .metadata.namespace + "/" + .metadata.name' 2>/dev/null || echo "No port-forwards found."
    _blank_line

    echo "___ check deprecated apis ___ "
    _blank_line
    kubectl get --raw /metrics | grep --color=auto apiserver_requested_deprecated_apis
    _blank_line
