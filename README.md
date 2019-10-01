# sdwan_build by Hank Yeomans
SDWAN builds within AWS

Use terraform apply to build
Use terraform destroy to remove everything from AWS

This terraform file takes AMIs which you will need to provide, and builds an SDWAN pod of the following:

Qty 1 vManage
Qty 2 vEdge 
Qty 1 vBond
Qty 1 vSmart

All of the subnets, interfaces, routing, internet gateway and the assignment of a public IP for VPN512 is taken care of.
Once this script completes you will be able to connect to the public IP address of each of these instances to complete the setup

At this time a separate configuration will need to be applied as will the certificates and basic setup.

Be aware that you will need to check and possibly change the following:

1. The AMI numbers which can be put into the AMI variables in the terraform script.
2. The connection section under the aws instance assumes a private key file that is located in $HOME/.ssh and ends with .pem
3. If you have a shared credentials file you can comment out the key and access variables noted in the script and uncomment out the
   shared credentials line.
4. key_name is the name of the private key you have created for accessing resources in AWS. At this time you'll have to create it
   ahead of time.
5. There is a provisioner that runs for the vManage that will take several minutes to connect and may time out.  This provisioner is
   an attempt to get past the intial boot where it asks to select the secondary disk, format it and reload.  Otherwise this will 
   have to be done manually. 
       To do manually ssh into the vManage and then select 1, then y (for yes) to format and let it reboot.



Future additions will include provisioning that will call ansible to create all of the certificates from the vMAnage host as well as an
ansible playbook to Configured the service VPN 1, some basic templates, and basic configuration.
