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
    echo "___ get storage pvc ___"
    _blank_line
    kubectl get pvc --all-namespaces -o wide
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
    kubectl api-resources
    echo " "

    echo "___ check for port-forwards ___ "
    echo " "
    _blank_line

    echo "___ check deprecated apis ___ "
    _blank_line
    kubectl get --raw /metrics | grep --color=auto apiserver_requested_deprecated_apis
    _blank_line
