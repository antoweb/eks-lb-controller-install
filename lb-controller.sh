#!/bin/bash

if [ -z "$1" ]; then
        echo "Occorre specificare come primo argomento il nome del clsuter e come secondo l'id account, es: lb-controller.sh miocluster 123617162579816"
        exit
fi

if [ -z "$2" ]; then
        echo "Occorre specificare come primo argomento il nome del clsuter e come secondo l'id account, es: lb-controller.sh miocluster 123617162579816"
        exit
fi

clustername=$1
idaccount=$2

#Riconfiguro kubectl col nuovo cluster
aws eks update-kubeconfig --region eu-west-1 --name $clustername


#Elimino le policy e i ruoli esistenti

aws iam detach-role-policy --role-name AmazonEKSLoadBalancerControllerRole --policy-arn arn:aws:iam::$idaccount:policy/AWSLoadBalancerControllerIAMPolicy
aws iam delete-role --role-name AmazonEKSLoadBalancerControllerRole
aws iam delete-policy --policy-arn arn:aws:iam::$idaccount:policy/AWSLoadBalancerControllerIAMPolicy

#Ricreo ruoli e policy
rm -f iam_policy.json
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.4/docs/install/iam_policy.json
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json

#Rilevo l'id del cluster
clusterid=$(aws eks describe-cluster --name $clustername --query "cluster.identity.oidc.issuer" --output text)
clusterid=$(echo "$clusterid" | cut -c 9-)

rm -f load-balancer-role-trust-policy.json

cat >load-balancer-role-trust-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::$idaccount:oidc-provider/$clusterid"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "$clusterid:aud": "sts.amazonaws.com",
                    "$clusterid:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
                }
            }
        }
    ]
}
EOF


aws iam create-role --role-name AmazonEKSLoadBalancerControllerRole --assume-role-policy-document file://"load-balancer-role-trust-policy.json"

aws iam attach-role-policy --policy-arn arn:aws:iam::$idaccount:policy/AWSLoadBalancerControllerIAMPolicy --role-name AmazonEKSLoadBalancerControllerRole

rm -f aws-load-balancer-controller-service-account.yaml

cat >aws-load-balancer-controller-service-account.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/name: aws-load-balancer-controller
  name: aws-load-balancer-controller
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::$idaccount:role/AmazonEKSLoadBalancerControllerRole
EOF

kubectl apply -f aws-load-balancer-controller-service-account.yaml

#Associo Openid Provider
oidc_id=$(aws eks describe-cluster --name $clustername --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
aws iam list-open-id-connect-providers | grep $oidc_id
eksctl utils associate-iam-oidc-provider --cluster $clustername --approve


#Cert manager

kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.5.4/cert-manager.yaml

#Installo controller
curl -Lo v2_4_4_full.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.4.4/v2_4_4_full.yaml
sed -i.bak -e '480,488d' ./v2_4_4_full.yaml
sed -i.bak -e 's|your-cluster-name|'"$clustername"'|' ./v2_4_4_full.yaml

sleep 180

kubectl apply -f v2_4_4_full.yaml
curl -Lo v2_4_4_ingclass.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.4.4/v2_4_4_ingclass.yaml
kubectl apply -f v2_4_4_ingclass.yaml

#Verifico che il controller sia installato

echo "Verifico se il controller è installato"
kubectl get deployment -n kube-system aws-load-balancer-controller

