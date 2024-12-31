#!/usr/bin/env bash

# make sure we have decent error handling for bash scripts
# set -o errexit -o noglob -o nounset -o pipefail

function  _blank_line () {
    echo " "
}

#############
# List of programs to check and install
_programs=("curl" "git" "parallel")

# Function to check if a program is installed
function  _is_installed () {
    dpkg-query -W -f='${Status}' "${1}" 2>/dev/null | grep -c "ok installed"
}

# Function to install a program
function  _install_program () {
    sudo apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${1}"
}

# Iterate over the list of programs
for PROGRAM in "${_programs[@]}"; do
    # Check if the program is installed
    if [[ "$( _is_installed $PROGRAM )" -eq 0 ]]; then
        echo "$PROGRAM is not installed. Installing..."
        if ! _install_program "$PROGRAM"; then
            echo "Failed to install $PROGRAM. Exiting."
            exit 1
        fi
    fi
done
######

    _blank_line
    echo "___ date  ___"
    date +"%d %m %Y %H_%M"
    _blank_line
    echo "___ cluster info ___"
    _blank_line
    kubectl cluster-info
    _blank_line

    echo "___ Kubernetes API health endpoints ___"  #  https://kubernetes.io/docs/reference/using-api/health-checks
    # healthz deprecated  Kubernetes v1.16
    # should see ok(s) and livez / readyz check passed
    kubectl get --raw='/readyz?verbose'
    kubectl get --raw='/livez?verbose'

    echo "___ Cluster get-contexts ___"
    _blank_line
    kubectl config get-contexts
    _blank_line

    echo "___ Cluster Creation Date ___"
    _blank_line
    kubectl get namespace kube-system -o jsonpath='{.metadata.creationTimestamp}'
    _blank_line
    _blank_line

    echo "___ ingress ___"
    _blank_line
    kubectl get service --all-namespaces | grep --color=auto -i ingress
    _blank_line
    kubectl get pods --all-namespaces | grep --color=auto -i ingress
    _blank_line
    kubectl get ingress --all-namespaces
    # Traefik Ingress https://doc.traefik.io/traefik/providers/kubernetes-ingress
    #
    _blank_line

    # CRI-O
    # kubectl top pods -A | grep -i crio
    # crio config | grep enable_pod_events

    echo "___ network policies ___"
    _blank_line
    kubectl get networkpolicies --all-namespaces
    _blank_line

    # Network Policy Provider - Antrea - Calico - Cilium - Kube-router - Romana - Weave Net

    echo "___ cert-manager ___" # https://github.com/cert-manager/cert-manager   https://cert-manager.io/docs/troubleshooting
    _blank_line
    kubectl get certificate --all-namespaces
    _blank_line

    echo "___ configmaps ___"
    _blank_line
    kubectl get configmaps --all-namespaces
    _blank_line

    echo "___ configmap - appInsights ___"
    _blank_line
##  kubectl describe configmaps -A | grep -E "^Name:|AppInsights" | grep -E -B 2  "minlevel=\"Info\""
    kubectl describe configmaps -A | grep -E "^Name:|AppInsights" | grep -E -B 2  "minlevel=\"Info\""
    _blank_line

    echo "___ get deployments ___"
    _blank_line
    kubectl get deployments --all-namespaces -o wide
    _blank_line

    echo "___ get services ___"   # svc
    _blank_line
    kubectl get services --all-namespaces -o wide
    _blank_line

    echo "___ get endpoints ___"
    _blank_line
    kubectl get endpoints --all-namespaces
    _blank_line

    echo "___ get endpoints json ___"
    _blank_line
    kubectl get endpoints --all-namespaces -o json
    _blank_line

    echo "___ get nodes ___"
    _blank_line
    kubectl get nodes --all-namespaces -o wide
    _blank_line

    echo "___ top nodes cpu ___"
    kubectl top nodes --sort-by=cpu | head -20
    _blank_line

    echo "___ top nodes mem ___"
    kubectl top nodes --sort-by=memory | head -20
    _blank_line

    echo "___ get pods ___"
    _blank_line
    kubectl get pods --all-namespaces -o wide
    _blank_line

    echo "___ get pods env ___"
    _blank_line
   # namespaces=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' | grep -v -E "kube-system" )
    namespaces=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' )
    for ns in $namespaces; do
        pods=$( kubectl get pods -n "$ns" -o jsonpath='{.items[*].metadata.name}' )  ;
        for pod in $pods; do
            echo "---_" "$ns" "$pod" "_---" && kubectl exec -n "$ns" "$pod" -- env ;
            echo " "
        done;
    done
    _blank_line

    echo "___ top pods cpu ___"
    _blank_line
    kubectl top pods --all-namespaces --sort-by=cpu | head -20
    _blank_line

    echo "___ top pods mem ___"
    _blank_line
    kubectl top pods --all-namespaces --sort-by=memory | head -20
    _blank_line

    echo "___ pods on nodes ___"
    for node in $( kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}' ); do
        echo -e "\nNode: $node"
        _blank_line
        kubectl top node $node
        _blank_line
        kubectl get pods --all-namespaces --field-selector spec.nodeName=$node -o custom-columns="NAMESPACE:.metadata.namespace,POD:.metadata.name,CPU_REQUEST:.spec.containers[*].resources.requests.cpu,MEMORY_REQUEST:.spec.containers[*].resources.requests.memory,CPU_LIMIT:.spec.containers[*].resources.limits.cpu,MEMORY_LIMIT:.spec.containers[*].resources.limits.memory"
    done
    _blank_line

    echo "___ evicted pods ___"
    kubectl get pods --all-namespaces | awk '{ printf "%s,%s,%s\n", $1,$2,$4} ' | grep -i -E "Evicted"
    _blank_line

    echo "___ get pod labels ___"
    kubectl get pods --show-labels --all-namespaces
    _blank_line

    echo "___ get pod images ___"
    kubectl get pods -o json --all-namespaces | jq .items[].spec.containers[].image | sort | uniq
    _blank_line

    echo "___ poddisruptionbudget ___"
    _blank_line
    kubectl get poddisruptionbudget --all-namespaces
    _blank_line

    echo "___ horizontal pod autoscaler status - hpa status ___"
    _blank_line
    kubectl get hpa --all-namespaces
    _blank_line

    kubectl get jobs --all-namespaces

    echo "___ get cronjob ___"
    _blank_line
    kubectl get cronjob --all-namespaces
    _blank_line
    # kubectl describe cronjob -n

    # _blank_line
    # echo "___ get pod logs ___"
    #

    # echo "___ get pod logs coredns ___"
    kubectl get pods --all-namespaces | grep "coredns-" | while read line; do
        name_space=$( echo $line | awk '{print $1}' )
        pod_name=$( echo $line | awk '{print $2}' )
        _blank_line
        _GET_POD_LOGS=$( kubectl logs -n $name_space $pod_name )
        _printf "Total Logs for coredns- ---- " $pod_name $name_space
        echo "${_GET_POD_LOGS}" | wc -l
        _blank_line

        _printf "INFO LOGS for coredns- ---- " $pod_name $name_space
        echo "${_GET_POD_LOGS}" | grep -i info | sort | uniq -c
        _blank_line

        _printf "WARNING LOGS for coredns- ---- " $pod_name $name_space
        echo "${_GET_POD_LOGS}" | grep -i warn | sort | uniq -c
        _blank_line

        _printf "ERROR LOGS for coredns- ---- " $pod_name $name_space
        echo "${_GET_POD_LOGS}" | grep -i err | sort | uniq -c
        _blank_line

        _printf "ANYTHING ELSE for coredns- ---- " $pod_name $name_space
        echo "${_GET_POD_LOGS}" | grep -i -E -v "info|Warn|err" | sort | uniq -c
    done
    _blank_line

    #

    # KEDA Logs
    echo "___ get keda logs ___ "
    kubectl logs $( kubectl get pod -l=app=keda-operator -o jsonpath='{.items[0].metadata.name}' -n kube-system ) -n kube-system | grep -i error | wc -l
    _blank_line
    kubectl logs $( kubectl get pod -l=app=keda-operator -o jsonpath='{.items[0].metadata.name}' -n kube-system ) -n kube-system | grep -i error | tail -5
    _blank_line

    echo "___ List all storage classes ___ "
    _blank_line
    kubectl get storageclasse
    _blank_line

    # pv,pvc
    echo "___ get storage persistentvolumes ___"
    _blank_line
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
    kubectl get events --all-namespaces
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

    echo "___ namespaces ___ "
    _blank_line
    kubectl get namespaces --all-namespaces
    _blank_line

    echo "___ scaledobjects ___ "
    _blank_line
    kubectl get scaledobjects --all-namespaces
    _blank_line

    echo "___ flux ___ "
    _blank_line
    flux check
    flux stats
    flux get all
    flux get helmrelease --all-namespaces     # keeping both as kubectl has time and flux has SUSPENDED
    _blank_line

    echo "___ kubectl helmreleases ___" ### times
    _blank_line
    kubectl get helmreleases --all-namespaces
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

    echo "___ flux helm - failed ___"
    _blank_line
    helm list --failed --all-namespaces
    # helm ls -a --all-namespaces
    _blank_line

### helm

    echo "___ helm version ___ "
    _blank_line
    helm version
    _blank_line

    echo "___ helm list ___ "
    _blank_line
    helm list --all-namespaces
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

### ISTIO  ########################### https://istio.io/latest/docs/reference/commands/istioctl
    echo "___ istio version  ___ "
    _blank_line
    istioctl version
    _blank_line

    echo "___ istio logs  ___ "  #
    _blank_line
##    kubectl -n istio-system logs $(kubectl -n istio-system get pods -listio=ingressgateway -o=jsonpath={.items[0].metadata.name}) | grep -i error | tail -50
    kubectl -n istio-system logs $( kubectl -n istio-system get pods -listio=ingressgateway -o=jsonpath={.items[0].metadata.name} ) --tail=30
    _blank_line

    echo "___ istio pods  ___ "
    _blank_line
    kubectl get pod -n istio-system
    _blank_line

    echo "___ istio injection status  ___ "
    _blank_line
    kubectl get namespace -L istio-injection
    _blank_line

    echo "___ istio gateway ip and node port  ___ "
    _blank_line
    _GATEWAY_URL=$( kubectl get po -l istio=ingressgateway -n istio-system -o 'jsonpath={.items[0].status.hostIP}' ):$( kubectl get svc istio-ingressgateway -n istio-system -o 'jsonpath={.spec.ports[0].nodePort}' )
    echo "${_GATEWAY_URL}"
    _blank_line

    echo "___ istio gateway logs summary ___ "
    echo "10000 lines"
    _ISTIO_LOGS=$( kubectl -n istio-system logs $( kubectl -n istio-system get pods -listio=ingressgateway -o=jsonpath={.items[0].metadata.name}) --tail=10000 )
    echo "${_ISTIO_LOGS}" | head -1
    echo "${_ISTIO_LOGS}" | tail -1
    _blank_line
    echo "istio info messages"
    echo "${_ISTIO_LOGS}" | grep -i "info" | wc -l
    _blank_line
    echo "istio error messages"
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
    _INGRESS_GATEWAY=$( kubectl get pods -A | grep istio-system | grep gateway- | awk '{ print $2 }' )
    istioctl proxy-status "${_INGRESS_GATEWAY}".istio-system

    _blank_line
    istioctl proxy-status
    _blank_line

    echo "___ istio analyze count ___"
    _blank_line
    istioctl analyze --all-namespaces | sed 's/deployment-[^ ]*/deployment-/g' | grep "deployment-" | sort | uniq -c
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

    echo "___ istio describe virtualservices ___"
    _blank_line
    kubectl describe virtualservice --all-namespaces
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

    echo "___ get rolebindings, clusterroles, clusterrolebindings ___"
    _blank_line
    kubectl get rolebindings,clusterroles,clusterrolebindings --all-namespaces -o wide
    _blank_line

    echo "___ get default namespace  ___"
    if kubectl get pods --namespace | grep -i -E "default"; then
        _blank_line
        kubectl get pods --namespace default
        _blank_line
    fi

    echo "___ get all pods ___"
    _blank_line
    kubectl get pods --namespace
    _blank_line

    echo "___ mutatingwebhookconfigurations ___"
    _blank_line
    kubectl get mutatingwebhookconfigurations
    _blank_line

    echo "___ validatingwebhookconfigurations ___"
    _blank_line
    kubectl get validatingwebhookconfigurations
    _blank_line

    echo "___ redis ___"
    if kubectl get pods --namespace | grep -i -E "redis redis-cluster-0|redis redis-cluster-1"; then
        _blank_line
        kubectl exec -it -n redis redis-cluster-0 -c redis-cluster -- /opt/bitnami/redis/bin/redis-cli INFO
        _blank_line
    fi

    echo "___ check for port-forwards ___ "
    _blank_line
    kubectl get pod --all-namespaces -o json | jq -r '.items[] | select(.spec.containers[].command | contains(["port-forward"])) | .metadata.namespace + "/" + .metadata.name' 2>/dev/null || echo "No port-forwards found."
    _blank_line

    echo "___ check deprecated apis ___ "
    _blank_line
    kubectl get --raw /metrics | grep --color=auto apiserver_requested_deprecated_apis
    _blank_line

    echo "___ Azure Account ___"
    _blank_line
    az account show --output table
    _blank_line


    echo "Finished Date" $( date +'%d %b %Y %H:%M:%S' )
