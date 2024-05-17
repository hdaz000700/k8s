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

    echo "___ flux events ___ "
    _blank_line
    flux events
    _blank_line

    echo "___ flux helm ___ "
    _blank_line
    helm list --failed --all-namespaces
    _blank_line

    echo "___ constraints Enforcement-Action and Violations ___ "
    _blank_line
    kubectl get constraints
    _blank_line

    echo "___ istio gateway logs ___"
    kubectl -n istio-system logs $(kubectl -n istio-system get pods -listio=ingressgateway -o=jsonpath={.items[0].metadata.name}) --tail=1000
    _blank_line

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
    
