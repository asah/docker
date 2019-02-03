# run source $0, don't execute this.

export MASTER=`printf "%s\n" \`kubectl get pod -o jsonpath="{..metadata.name}"\`|grep master`
export MANAGER=`printf "%s\n" \`kubectl get pod -o jsonpath="{..metadata.name}"\`|grep manager`
export WORKERS=`printf "%s\n" \`kubectl get pod -o jsonpath="{..metadata.name}" \`|grep worker|xargs echo`
export FIRST_WORKER=`printf "%s\n" \`kubectl get pod -o jsonpath="{..metadata.name}" \`|grep worker|head -1|xargs echo`
export WORKER_IPS=`kubectl get pod -o wide | grep worker- | awk '{print $6}'`
export RS_MASTER=`printf "%s\n" \`kubectl get replicasets -o jsonpath="{..metadata.name}"\`|grep master`
export POD_INTERNAL_SUBNET=`kubectl get pods -o wide | grep worker|head -1|perl -ne 'm@\s+(\d+[.]\d+)[.]\d+[.]\d+\s+@ && print "$1.0.0/16"' `

export BASTION_IP=`kubectl get service/bastion -o wide |grep bastion | awk '{print $4}'`
export BASTION_INTERNAL_IP=`kubectl get service/bastion -o wide |grep bastion | awk '{print $3}'`

function kubemaster(){
    kubectl exec -it $MASTER -- ${1:-bash}
}
function kubemaster-postgres-psql(){
    kubectl exec -it $MASTER -- su - postgres -c "${1:-psql}"
}
function kyrix-psql(){
    kubectl exec -it $MASTER -- su - postgres -c "psql -U ${1:-kyrix} ${2:-kyrix}"
}
