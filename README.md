PAYPAL DONATION  
[![paypal](https://github.com/antoweb/DonateButtons/blob/master/Paypal-160.png?raw=true)](https://www.paypal.me/sistemistaitaliano/2)

BUY ME A COFFEE DONATION  
[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://buymeacoffee.com/sistemistaita)

# eks-lb-controller-install
This bash script is based on Official AWS Guide: https://docs.aws.amazon.com/it_it/eks/latest/userguide/aws-load-balancer-controller.html
Enable and install the Load balancer Controller on an existing EKS Cluster
Tested successfully on Amazon AMI Linux 2

Requirements: 
- kubectl installed and configured:
  For install kubectl launch following commands:
  Determine whether you already have kubectl installed on your device.

  kubectl version | grep Client | cut -d : -f 5
  If you have kubectl installed in the path of your device, the example output is as follows. If you want to update the version that you currently have installed with a later version, complete the next step, making sure to install the new version in the same location that your current version is in.

  "v1.22.6-eks-7d68063", GitCommit
  If you receive no output, then you either don't have kubectl installed, or it's not installed in a location that's in your device's path.

#For Kubernetes 1.23

    curl -o kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.23.7/2022-06-29/bin/linux/amd64/kubectl
    chmod +x ./kubectl
    mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$PATH:$HOME/bin
    echo 'export PATH=$PATH:$HOME/bin' >> ~/.bashrc
    kubectl version --short --client

-   aws cli installed e configured
Amazon AMI Linux comes already with aws cli installed for configure launch 

    aws configure --profile  >YOUR-PROFILE>
    
    The cli configuration must have permission to aws eks cluster
