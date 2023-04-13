# Assignment-ThoughtWorks

Using this repository one can deploy MediaWiki app using terraform and Ansible

Manual installation steps : https://www.mediawiki.org/wiki/Manual:Running_MediaWiki_on_Red_Hat_Linux 

I used Azure cloud shell to run the project which comes installed with most of the required tools such as git, terraform and ansible to run the project.

Steps to run the project:

1. Login to Azure cloud Bash shell
   1. Do _**az login**_ to login azure account using CLI just follow the process

2. Generate ssh key-value pair for login into azure vm which will be provisoned or created using terraform:
   1. To generate use: 
      - ssh-keygen (Hit enter till the process is completed no input is required)
      
3. clone the repository:
   1. git clone https://github.com/divyanshursahu/Assignment-ThoughtWorks.git
   2. cd Assignment-ThoughtWorks

4. Now we have all the files in one folder
   1. Use **_terraform init_** it will download all the plugins and files required by provider.
   2. Use **_terraform plan_** it will list out the plan of the resources to be created (optional)
   3. use _**terraform apply**_ it will list out the plan and ask for the confirmation to create resources. Hit **Yes** when ask for input. 
   You can use _**terraform apply**_ _**-auto-approve**_ alternatively it will skip confirmation.
	 4. When terraform completes the provision of resources it will output the **public-ip**. Replace the **public-ip** in the URL to access the application webpage
	    http://public-ip/mediawiki in browser. You can use **_terraform output_** to get **public-ip** again
			
			Outputs:
			public_ip_address = "40.87.59.17"
			
5. After opening the URL it will ask for wiki setup. Just follow the steps
   1. Database type: mariadb
   2. Db user: wiki
   3. Db name: wikidatabase
   4. Db pass for wiki: 12345
   Complete the setup

6. User **_terraform destroy_** to delete all the resources provisioned 
