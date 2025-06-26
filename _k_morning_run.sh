#!/usr/bin/env bash

### https://github.com/hdaz000700/k8s/blob/main/_k_morning_run.sh

# make sure we have decent error handling for bash scripts
# set -o errexit -o noglob -o nounset -o pipefail

function  _blank_line () {
    echo " "
}

function  _title () {
    local _INPUT_1="${1}"
    echo "___ ${_INPUT_1} ___"
}

#############
# List of programs to check and install
_programs=( "curl" "git" "parallel" "jq" )

# Function to check if a program is installed
function  apt_is_installed () {
    dpkg-query -W -f='${Status}' "${1}" 2>/dev/null | grep -c "ok installed"
}

# Function to install a program
function  apt_install_program () {
    sudo apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${1}"
}

# Iterate over the list of programs
for PROGRAM in "${_programs[@]}"; do
    # Check if the program is installed
    if [[ "$( apt_is_installed $PROGRAM )" -eq 0 ]]; then
        echo "$PROGRAM is not installed. Installing..."
        if ! apt_install_program "$PROGRAM"; then
            echo "Failed to install $PROGRAM. Exiting."
            exit 1
        fi
    fi
done

### requirements
# kubectl istioctl flux helm   ### I have all four versions within here
######
    _title "date"
    date +"%d %m %Y %H_%M"
    _blank_line

    _title "kubectl version"
    _blank_line
    kubectl version --output=yaml
    _blank_line

    _title "cluster info"
    _blank_line
    kubectl cluster-info
    _blank_line

    _title "Kubernetes API health endpoints"  #  https://kubernetes.io/docs/reference/using-api/health-checks
    _blank_line
    # healthz deprecated  Kubernetes v1.16
    # should see ok(s) and livez / readyz check passed
    echo "readyz checks are ok"
    kubectl get --raw='/readyz?verbose'
    _blank_line
    echo "livez checks are ok"
    kubectl get --raw='/livez?verbose'
    _blank_line

    _title "Cluster get-contexts"
    _blank_line
    kubectl config get-contexts
    _blank_line

    _title "Cluster Creation Date"
    _blank_line
    kubectl get namespace kube-system -o jsonpath='{.metadata.creationTimestamp}'
    _blank_line
    _blank_line

    _title "ingress"
    _blank_line
    kubectl get service --all-namespaces | grep --color=auto -i ingress
    _blank_line
    kubectl get pods --all-namespaces | grep --color=auto -i ingress
    _blank_line
    kubectl get ingress --all-namespaces
    # Traefik Ingress https://doc.traefik.io/traefik/providers/kubernetes-ingress
    #
    _blank_line

    # CRI-O - test namespace CRI-O
    # kubectl top pods -A | grep -i crio
    # crio config | grep enable_pod_events

    _title "network policies"   # kubectl get netpol -A
    _blank_line
    kubectl get networkpolicies --all-namespaces
    _blank_line

    # Network Policy Provider's - Antrea - Calico - Cilium - Kube-router - Romana - Weave Net

    _title "cert-manager" # https://github.com/cert-manager/cert-manager   https://cert-manager.io/docs/troubleshooting
    _blank_line
    kubectl get certificate --all-namespaces
    _blank_line

    _title "configmaps"
    _blank_line
    kubectl get configmaps --all-namespaces
    _blank_line

    _title "configmap - appInsights"
    _blank_line
##  kubectl describe configmaps -A | grep -E "^Name:|AppInsights" | grep -E -B 2  "minlevel=\"Info\""
    kubectl describe configmaps -A | grep -E "^Name:|AppInsights" | grep -E -B 2  "minlevel=\"Info\""
    _blank_line

    _title "get deployments"
    _blank_line
    kubectl get deployments --all-namespaces -o wide
    _blank_line

    _title "get services"   # svc
    _blank_line
    kubectl get services --all-namespaces -o wide
    _blank_line

    _title "get serviceaccounts"
    _blank_line
    kubectl get serviceaccounts --all-namespaces
    _blank_line

    _title "get endpoints"
    _blank_line
    kubectl get endpoints --all-namespaces
    _blank_line

    _title "get endpoints json"
    _blank_line
    kubectl get endpoints --all-namespaces -o json
    _blank_line

    _title "get nodes"
    _blank_line
    kubectl get nodes --all-namespaces -o wide
    _blank_line

    ##  kubectl describe node
    _title "describe nodes"
    _blank_line
    _NODES=$( kubectl get nodes | grep -i Ready | awk '{ print $1 }' )
    echo "${_NODES}" | parallel -j10 --colsep ' ' '
    node={1}
    echo " "
    echo "_____________ $node _____________"
    echo " "
    kubectl describe node $node '
    _blank_line

    _title "top nodes cpu"
    _blank_line
    kubectl top nodes --sort-by=cpu | head -20
    _blank_line

    _title "top nodes mem"
    _blank_line
    kubectl top nodes --sort-by=memory | head -20
    _blank_line

    _title "get nodes show labels"
    _blank_line
    ## kubectl get nodes --show-labels
    kubectl get nodes -o json | jq -r '.items[] | .metadata.name as $name | "\($name)" , (.metadata.labels | to_entries[] | "  \(.key)=\(.value)") , ""'
    _blank_line

    # kubectl describe pod
    _title "describe pods"
    _blank_line
    _PODS=$( kubectl get pods --all-namespaces | grep -i Running | awk '{ print $1, $2 }' )
    echo "${_PODS}" | grep -v -i -E "aad-pod-identity" | parallel -j10 --colsep ' ' '
    namespace={1}
    pod={2}
    echo " "
    echo "_____________ $namespace $pod _____________"
    echo " "
    kubectl describe pod $pod -n $namespace '
    _blank_line

    _title "count pods per node"
    _blank_line
    _PODS_COUNT=$( kubectl get pods -A -o jsonpath='{range .items[*]}{.spec.nodeName}{"\n"}{end}' | sort | uniq -c )
    _TOTAL_PODS_COUNT=$( echo "${_PODS_COUNT}" | awk '{ print $1 }' | awk '{sum += $1} END {print sum}' )
    _TOTAL_NODES_COUNT=$( echo "${_PODS_COUNT}" | awk '{ print $2 }' | sort | uniq | wc -l )

    echo "Total Pods = " "${_TOTAL_PODS_COUNT}""  Total Nodes =" "${_TOTAL_NODES_COUNT}"
    _blank_line
    echo "${_PODS_COUNT}"
    _blank_line

    _title "get pods"
    _blank_line
    kubectl get pods -o wide --all-namespaces
    _blank_line

    _title "pods by timestamp"
    _blank_line
    (echo "$( kubectl get pods -A --sort-by=.status.startTime | head -1 )     START TIME"; \
        paste <( kubectl get pods -A --sort-by=.status.startTime --no-headers=true ) \
              <( kubectl get pods -A -o json --sort-by=.status.startTime | jq -r '.items[] | [.metadata.namespace, .metadata.name, .status.startTime] | @tsv' | while IFS=$'\t' read -r ns pod time; do
                age=$(echo $(($(date +%s) - $(date -d "$time" +%s))) | awk '{printf "%dd%dh\n", $1/86400, ($1%86400)/3600}')
                printf "%-8s %s %s\n" "$age" "$time"
              done))
    _blank_line

    _title "get pods env"
    _blank_line
   # namespaces=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' | grep -v -E "kube-system" )
    namespaces=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' )
    for ns in $namespaces; do
        pods=$( kubectl get pods -n "$ns" -o jsonpath='{.items[*].metadata.name}' | grep -i "Running" )  ;
        for pod in $pods; do
            echo "---_" "$ns" "$pod" "_---" && kubectl exec -n "$ns" "$pod" -- env ;
            echo " "
        done;
    done
    _blank_line

    _title "top pods cpu"
    _blank_line
    kubectl top pods --all-namespaces --sort-by=cpu | head -20
    _blank_line

    _title "top pods mem"
    _blank_line
    kubectl top pods --all-namespaces --sort-by=memory | head -20
    _blank_line

    _title "pods on nodes"
    for node in $( kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}' ); do
        echo -e "\nNode: $node"
        _blank_line
        kubectl top node $node
        _blank_line
        kubectl get pods --all-namespaces --field-selector spec.nodeName=$node -o custom-columns="NAMESPACE:.metadata.namespace,POD:.metadata.name,CPU_REQUEST:.spec.containers[*].resources.requests.cpu,MEMORY_REQUEST:.spec.containers[*].resources.requests.memory,CPU_LIMIT:.spec.containers[*].resources.limits.cpu,MEMORY_LIMIT:.spec.containers[*].resources.limits.memory"
    done
    _blank_line

    _title "evicted pods"
    kubectl get pods --all-namespaces | awk '{ printf "%s,%s,%s\n", $1,$2,$4} ' | grep -i -E "Evicted"
    _blank_line

    _title "get pod labels"
    ## kubectl get pods --show-labels --all-namespaces
    kubectl get pods --all-namespaces -o json | jq -r '.items[] | [.metadata.namespace, .metadata.name] as $info | "\($info[0])/\($info[1])", (.metadata.labels | to_entries[]? | "  \(.key)=\(.value)"), ""'
    _blank_line

    _title "get pod images"
    ## kubectl get pods -o json --all-namespaces | jq .items[].spec.containers[].image | sort | uniq
    _blank_line
    kubectl get pods --all-namespaces -o custom-columns="NAMESPACE:.metadata.namespace,POD_NAME:.metadata.name,IMAGE:.spec.containers[*].image"
    _blank_line

    _title "get pod images blacklist"
    _blank_line
    kubectl get pods --all-namespaces -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name,IMAGE:.spec.containers[*].image" | grep -i -E docker
    _blank_line

    _title "pods ips with nodepools"
    _blank_line
    kubectl get pods --all-namespaces -o custom-columns=NAMESPACE:metadata.namespace,POD:metadata.name,IP:status.podIP,NODE:'{.spec.nodeName}'
    _blank_line

    _title "pod disruption budget - poddisruptionbudget"
    _blank_line
    kubectl get poddisruptionbudget --all-namespaces
    _blank_line

    _title "horizontal pod autoscaler status - hpa status"
    _blank_line
    kubectl get hpa --all-namespaces
    _blank_line

    _title "get pod restricted_np taints" ### restricted_np might not be generic
    _blank_line
    ## kubectl get pods -A -o json | jq -r '.items[] | select(.spec.tolerations[]?.key | test("restricted_np")) | "\(.metadata.namespace) \(.metadata.name)"'
    ( echo "NODEPOOL NAMESPACE POD TAINT"
     kubectl get pods -A -o jsonpath='{range .items[*]}{.spec.nodeName} {.metadata.namespace} {.metadata.name} {.spec.tolerations[*].key}{"\n"}{end}' | grep restricted_np | while read node ns pod taint; do
        nodepool=$(kubectl get node "$node" -o jsonpath='{.metadata.labels.agentpool}')
        echo "$nodepool $ns $pod $taint"
     done
    ) | column -t
    _blank_line

    _title "get jobs"
    _blank_line
    kubectl get jobs --all-namespaces
    _blank_line

    ## kubectl logs job/<job-name>
    ## kubectl describe job/<job-name>

    _title "get cronjob"
    _blank_line
    kubectl get cronjobs --all-namespaces
    _blank_line
    # kubectl describe cronjob -n

    ### TODO:
    #  _title "get pod logs"
    # _blank_line
    #
    # _blank_line

    ### CoreDNS - test namespace CoreDNS   TODO: repeat for everything that is not CoreDNS KEDA, Istio, Jobs
    _title "get coredns pod logs"
    kubectl get pods --all-namespaces | grep "coredns-" | while read line; do
        name_space=$( echo $line | awk '{print $1}' )
        pod_name=$( echo $line | awk '{print $2}' )
        _blank_line
        _GET_POD_LOGS=$( kubectl logs -n $name_space $pod_name )
        echo  "Total Logs for coredns ---- " $pod_name $name_space
        echo "${_GET_POD_LOGS}" | wc -l
        _blank_line

        echo  "INFO LOGS for coredns ---- " $pod_name $name_space
        echo "${_GET_POD_LOGS}" | grep -i "info" | sort | uniq -c
        _blank_line

        echo "WARNING LOGS for coredns ---- " $pod_name $name_space
        echo "${_GET_POD_LOGS}" | grep -i "warn" | sort | uniq -c
        _blank_line

        echo "ERROR LOGS for coredns ---- " $pod_name $name_space
        echo "${_GET_POD_LOGS}" | grep -i "err" | sort | uniq -c
        _blank_line

        echo  "ANYTHING ELSE for coredns ---- " $pod_name $name_space
        echo "${_GET_POD_LOGS}" | grep -i -E -v "info|Warn|err" | sort | uniq -c
    done
    _blank_line

    _title "List all storage classes"
    _blank_line
    kubectl get storageclass
    _blank_line

    # pv,pvc
    _title "get storage persistentvolumes"
    _blank_line
    kubectl get persistentvolumes -o wide
    _blank_line
    _title "get storage persistentvolumeclaims"
    _blank_line
    kubectl get persistentvolumeclaims --all-namespaces -o wide
    _blank_line

    _title "get statefulsets"
    _blank_line
    kubectl get statefulsets --all-namespaces -o wide
    _blank_line

    _title "get daemonsets"
    _blank_line
    kubectl get daemonsets --all-namespaces -o wide
    _blank_line

    ### kubectl describe ds <daemonset-name> -n <namespace>'

    _title "get replicasets"
    _blank_line
    kubectl get replicasets --all-namespaces -o wide
    _blank_line

    _title "get crds"
    _blank_line
    kubectl get crds
    _blank_line

    _title "get events"
    _blank_line
    # kubectl get events --all-namespaces
    kubectl get events --all-namespaces --sort-by='.metadata.creationTimestamp' -o custom-columns="NAMESPACE:.metadata.namespace,TIMESTAMP:.metadata.creationTimestamp,TYPE:.type,REASON:.reason,OBJECT:.involvedObject.name,MESSAGE:.message" | tac
    _blank_line
    _title "get failed events yaml"
    _blank_line
    kubectl get events --all-namespaces --sort-by='.metadata.creationTimestamp' --field-selector type!=Normal -o yaml
    _blank_line

    _title "get providers"
    _blank_line
    kubectl get providers -o wide --all-namespaces
    _blank_line

    _title "k8s gitops argo - flux - circle"
    _blank_line
    kubectl get pods --all-namespaces | grep --color=auto -i -E "flux|argo|circle"
    _blank_line

    _title "secrets"
    _blank_line
    kubectl get secrets --all-namespaces
    _blank_line

    _title "virtualservices"
    _blank_line
    kubectl get virtualservices --all-namespaces
    _blank_line

    _title "namespaces"
    _blank_line
    kubectl get namespaces --all-namespaces
    _blank_line

    _title "scaledobjects"
    _blank_line
    kubectl get scaledobjects --all-namespaces
    _blank_line

    ### FLUX - test namespace FLUX
    _title "flux check - flux versions"
    _blank_line
    _FLUX_VERSION=$( flux check 2>&1  )
    echo "${_FLUX_VERSION}"
    _blank_line

    _title "flux stats"
    flux stats
    # gitrepository helmrepository helmchart  helmrelease  kustomization
    flux get all
    flux get helmrelease --all-namespaces     # keeping both as kubectl has time and flux has SUSPENDED
    _blank_line

    _title "flux errors"
    _blank_line
    flux get all -A --status-selector Ready=false
    _blank_line

    _title "kubectl helmreleases" ### times
    _blank_line
    kubectl get helmreleases --all-namespaces
    _blank_line

    _title "flux logs"
    _blank_line
    ## must be one of: debug, info, error
    flux logs --all-namespaces --level=error
    # flux logs --all-namespaces | grep -v "info "
    # flux logs --kind kustomization -A
    _blank_line

    _title "flux events"
    _blank_line
    flux events
    _blank_line

### HELM - test namespace HELM

    _title "helm version"
    _blank_line
    helm version
    _blank_line

    _title "helm list"
    _blank_line
    helm list --all-namespaces
    _blank_line

    _title "flux helm - failed"
    _blank_line
    helm list --failed --all-namespaces
    # helm ls -a --all-namespaces
    _blank_line

    _title "helm manifests"
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


    _title "get constraints Enforcement-Action and Violations"
    _blank_line
    kubectl get constraints
    _blank_line

### KEDA - test namespace KEDA

    _title "keda version"
    _blank_line
    ## grep "/version:"
    kubectl get crd/scaledobjects.keda.sh -o yaml | grep app.kubernetes.io/version
    _blank_line

    # KEDA Logs
    _title "get keda logs"
    _total_keda_logs=$( kubectl logs $( kubectl get pod -l=app=keda-operator -o jsonpath='{.items[0].metadata.name}' -n kube-system ) -n kube-system | grep -i error | wc -l )
    echo "Total Keda Logs" "${_total_keda_logs}"
    _blank_line
    kubectl logs $( kubectl get pod -l=app=keda-operator -o jsonpath='{.items[0].metadata.name}' -n kube-system ) -n kube-system | grep -i error | tail -100
    _blank_line

### Karpenter

### ISTIO start - test namespace ISTIO
########################### https://istio.io/latest/docs/reference/commands/istioctl
    _title "istio version"
    _blank_line
    istioctl version
    _blank_line

    _title "istio precheck"
    _blank_line
    istioctl x precheck
    _blank_line

    _title "istio verify-install"
    _blank_line
    istioctl manifest generate | istioctl verify-install -f -
    _blank_line

    _title "istio envoyfilter"
    _blank_line
    kubectl get envoyfilter -A
    _blank_line

    _title "istioctl profile list"
    _blank_line
    istioctl profile list
    _blank_line

    _title "istioctl installed Istio components"
    _blank_line
    kubectl get all -n istio-system
    _blank_line

    _title "istioctl deployments"
    _blank_line
    echo "istiod"
    kubectl describe deployment istiod -n istio-system
    _blank_line

    _title "istio-ingressgateway"
    kubectl describe deployment istio-ingressgateway -n istio-system
    _blank_line

    _title "istioctl"
    _ISTIOCTL=$( which istioctl )
    if [[ -z "${_ISTIOCTL}" ]]; then echo "istioctl not installed"; else  echo "${_ISTIOCTL}"; fi

    _title "istio logs"  #
    _blank_line
##    kubectl -n istio-system logs $(kubectl -n istio-system get pods -listio=ingressgateway -o=jsonpath={.items[0].metadata.name}) | grep -i error | tail -50
    kubectl -n istio-system logs $( kubectl -n istio-system get pods -l istio=ingressgateway -o=jsonpath={.items[0].metadata.name} ) --tail=30
    _blank_line

    _title "istio pods"
    _blank_line
    kubectl get pod -n istio-system
    _blank_line

    _title "istio injection status"
    _blank_line
    kubectl get namespace -L istio-injection
    _blank_line

    _title "istio gateway ip and node port"
    _blank_line
    _GATEWAY_URL=$( kubectl get pods -l istio=ingressgateway -n istio-system -o 'jsonpath={.items[0].status.hostIP}' ):$( kubectl get svc istio-ingressgateway -n istio-system -o 'jsonpath={.spec.ports[0].nodePort}' )
    echo "${_GATEWAY_URL}"
    _blank_line

    _title "istio gateway logs summary"
    echo "10000 lines"
    _ISTIO_LOGS=$( kubectl logs -n istio-system $( kubectl -n istio-system get pods -l istio=ingressgateway -o=jsonpath={.items[0].metadata.name} ) --tail=100000 )

    ## TODO:
#   was going to count the number of lines and only output if they were lower than say 100 or 200
#    _ISTIO_LOGS_TAIL=$( echo "${_ISTIO_LOGS}" | cat -n | tail -1 |
#    if
    echo "${_ISTIO_LOGS}" | cat -n | head -1
    echo "${_ISTIO_LOGS}" | cat -n | tail -1

    _blank_line
    echo "istio info messages"
    echo "${_ISTIO_LOGS}" | grep -i "info" | wc -l
    _blank_line
    echo "istio error messages"
    echo "${_ISTIO_LOGS}" | grep -i "error" | wc -l
    _blank_line

    _title "istio gateway logs"
    echo "${_ISTIO_LOGS}"
    _blank_line

### covered by bug-report below and analyze count above
#   _title "istio analyze"
#   _blank_line
#   istioctl analyze --all-namespaces
#   _blank_line

    _title "istio analyze count"
    _blank_line
    istioctl analyze --all-namespaces | sed 's/deployment-[^ ]*/deployment-/g' | sort | uniq -c
    _blank_line

    _title "istio proxy-status"
    _blank_line
    _INGRESS_GATEWAY=$( kubectl get pods -A | grep istio-system | grep gateway- | awk '{ print $2 }' )

    istioctl proxy-status "${_INGRESS_GATEWAY}".istio-system
    _blank_line
    istioctl proxy-status
    _blank_line

    _title "istio proxy-config cluster"
    _ISTIO_GATEWAY=$( kubectl get pods -n istio-system | grep -i istio-ingressgateway | grep -i Running | awk '{ print $1 }' | head -1 )
    _blank_line
    istioctl proxy-config cluster -n istio-system "${_ISTIO_GATEWAY}"
    _blank_line

    _title "istio ingressgateway ps aux"
    _blank_line
    kubectl -n istio-system exec "${_ISTIO_GATEWAY}" ps aux
    _blank_line

    _title "istio proxy-config cluster"
    _blank_line
    istioctl -n istio-system proxy-config cluster "${_ISTIO_GATEWAY}"
    _blank_line

    _title "istio proxy-config endpoint"
    _blank_line
    istioctl -n istio-system proxy-config endpoint "${_ISTIO_GATEWAY}"
    _blank_line

    _title "istio proxy-config listener"
    _blank_line
    istioctl -n istio-system proxy-config listener "${_ISTIO_GATEWAY}"
    _blank_line

    _title "istio proxy-config route"
    _blank_line
    istioctl -n istio-system proxy-config route "${_ISTIO_GATEWAY}"
    _blank_line

    _title "istio proxy-config secret"
    _blank_line
    istioctl -n istio-system proxy-config secret "${_ISTIO_GATEWAY}"
    _blank_line

    _title "istio pods versions"
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

    _title "istio describe virtualservices"
    _blank_line
    kubectl describe virtualservice --all-namespaces
    _blank_line

    _title "istio crds backup"
    _blank_line
    kubectl get $(kubectl get crds | grep 'istio.io' | awk '{print $1}' | tr '\n' ',' | sed 's/,$//') --all-namespaces -o yaml
    _blank_line

    _title "istioctl manifest generate"
    _blank_line
    istioctl manifest generate
    _blank_line

    _title "istio bug report"
    _blank_line
    istioctl bug-report
    _blank_line

    _title "istio remote-clusters"
    _blank_line
    istioctl remote-clusters
    _blank_line

### ISTIO END

    _title "lists all published API kinds available"
    _blank_line
    kubectl api-resources -o wide
    _blank_line

    _title "get roles"
    _blank_line
    kubectl get roles --all-namespaces
    _blank_line

    _title "get rolebindings, clusterroles, clusterrolebindings"
    _blank_line
    kubectl get rolebindings,clusterroles,clusterrolebindings --all-namespaces -o wide
    _blank_line

    _title "get default namespace"
    if kubectl get pods --namespace | grep -i -E "default"; then
        _blank_line
        kubectl get pods --namespace default
        _blank_line
    fi

    _title "get all pods"
    _blank_line
    kubectl get pods --namespace
    _blank_line

    _title "mutatingwebhookconfigurations"
    _blank_line
    kubectl get mutatingwebhookconfigurations
    _blank_line

    _title "validatingwebhookconfigurations"
    _blank_line
    kubectl get validatingwebhookconfigurations
    _blank_line


## Redis Start - test namespace Redis
    if kubectl get namespace redis &>/dev/null; then

        _title "redis"
         _blank_line
         kubectl exec -n redis redis-cluster-0 -- redis-cli INFO 2>/dev/null
         _blank_line

        _title "redis nodes"
        _blank_line
        # Get Redis pod info dynamically
        ( declare -A pod_map
        while IFS=$'\t' read -r name ip node; do
          pod_map["$ip"]="$name $ip $node"
        done < <( kubectl get pods -n redis -o json | jq -r '.items[] | [.metadata.name, .status.podIP, .spec.nodeName] | @tsv' )

        # Define column widths (adjust as needed)
        FORMAT="%-20s %-16s %-35s %-42s %-24s %-20s %-50s %-6s %-20s %-5s %-10s\n"

        # Print header
        printf "$FORMAT" "Pod" "IP" "Node" "NodeID" "Address" "Role" "MasterID" "Ping" "Timestamp" "Slot" "State"

        # Execute redis-cli and match IPs
        kubectl exec -n redis redis-cluster-0 -- redis-cli cluster nodes 2>/dev/null | while read -r line; do
            fields=($line)  # Split line into array
            ip_port="${fields[1]}"
            ip="${ip_port%%:*}"  # Extract IP before the colon

            # Lookup pod info based on IP
            if [[ -n "${pod_map[$ip]}" ]]; then
                pod_info="${pod_map[$ip]}"
            else
              pod_info="N/A $ip N/A"
            fi

        # Handle variable column length in Redis output
        node_id="${fields[0]}"
        address="${fields[1]}"
        role="${fields[2]}"
        master_id="${fields[3]}"
        ping="${fields[4]}"
        timestamp="${fields[5]}"
        slot="${fields[6]:--}"  # Some lines may lack this
        state="${fields[7]:--}" # Some lines may lack this

        # Print formatted output
        printf "$FORMAT" "$pod_info" "$node_id" "$address" "$role" "$master_id" "$ping" "$timestamp" "$slot" "$state"
    done
    ) | column -t
    _blank_line
    fi

#### Redis End

    _title "check for port-forwards"
    _blank_line
    kubectl get pod --all-namespaces -o json | jq -r '.items[] | select(.spec.containers[].command | contains(["port-forward"])) | .metadata.namespace + "/" + .metadata.name' 2>/dev/null || echo "No port-forwards found."
    _blank_line

    _title "check deprecated apis"
    _blank_line
    kubectl get --raw /metrics | grep --color=auto apiserver_requested_deprecated_apis || echo "No K8s Deprecated APIs"
    _blank_line

    _title "Azure Account"
    _blank_line
    az account show --output table
    _blank_line

    _title "Finished Date" $( date +'%d %b %Y %H:%M:%S' )
