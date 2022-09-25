CONTEXT=vault

errors=

configure_minikube() {
    minikube delete -p $CONTEXT
    minikube start --cpus=4 --memory=4096 -p $CONTEXT
}

configure_helm() {
    
    helm repo add hashicorp https://helm.releases.hashicorp.com
    helm search repo hashicorp/vault
    helm install vault hashicorp/vault --kube-context=$CONTEXT --version 0.21.0 --values helm-vault-values.yml

    helm repo add hashicorp https://helm.releases.hashicorp.com
    helm repo update
    helm install consul hashicorp/consul --kube-context=$CONTEXT --values helm-consul-values.yml

}

check_environment() {

    
    check "kubectl version --client=true" "kubectl" 
    check "helm version" "helm" 
    check "minikube version" "minikube" 
    check "jq --version" "jq" 

    echo $errors

    if [ ! -z "$errors" ]
        then
            echo "Operation aborted"
            exit 1
    fi
}

check() {

    echo "checking $2"

    eval $1>/dev/null
    if [ $? != 0 ]
        then
            
            errors+="\n$2 not found or errors has occurred"
    fi

}

wait_conditions () {
    watch kubectl --context=$CONTEXT get pods -A
}

port_forward () {
    
    vaultpidfile="/tmp/vault-pid-file"
    if test -f "$vaultpidfile"; then
        vaultpid=$(cat $vaultpidfile)
        kill $vaultpid
    fi
    kubectl  --context=$CONTEXT port-forward vault-0 8200:8200 & >/dev/null
    id=$!
    echo $id>$vaultpidfile

}

check_environment
configure_minikube
configure_helm
wait_conditions
port_forward