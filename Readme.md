
# Kubernetes / OpenFaaS Deployment using Terraform and Civo

These config files will get you a 3 node kubernetes cluster with OpenFaaS up and running in under 5 minutes!

More information can be found at the Civo Learning guide:

https://www.civo.com/learn/kubernetes-and-openfaas-using-terraform
 
# Deployment

To build this environment:

1. Source the civo-env.sh and input your username / password from https://www.civo.com/api **Note:** You'll need to be logged into your Civo account to see the username/password.
2. Update the public_key variable with your SSH public key in cluster.tf.

   ```
   variable "public_key"   { default = "ssh-rsa ..." }
   ```

3. Set the access CIDR in the access_cidr to restrict SSH and OpenFaaS access. **Note:** Usually your public IP address/32 or 0.0.0.0/0 for everywhere.

    ```
    variable "access_cidr"  { default = "0.0.0.0/0" }

    ```
4. Initialise terraform - terraform init
5. Run terraform - terraform apply.

# Cleanup

You can leave your cluster running with OpenFaaS and keep experimenting, but if you want to clean-up the environment type in `terraform destroy`:

```
$ terraform destroy

...

openstack_networking_network_v2.network: Destruction complete

Destroy complete! Resources: 15 destroyed.
```
