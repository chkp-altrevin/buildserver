## Configuration
This provider exposes quite a few provider-specific configuration options:

access_key_id - The access key for accessing AWS

ami - The AMI id to boot, such as "ami-12345678"

availability_zone - The availability zone within the region to launch the instance. If nil, it will use the default set by Amazon.

aws_profile - AWS profile in your config files. Defaults to default.

aws_dir - AWS config and credentials location. Defaults to $HOME/.aws/.

instance_ready_timeout - The number of seconds to wait for the instance to become "ready" in AWS. Defaults to 120 seconds.

instance_check_interval - The number of seconds to wait to check the instance's state

instance_package_timeout - The number of seconds to wait for the instance to be burnt into an AMI during packaging. Defaults to 600 seconds.

instance_type - The type of instance, such as "m3.medium". The default value of this if not specified is "m3.medium". "m1.small" has been deprecated in "us-east-1" and "m3.medium" is the smallest instance type to support both paravirtualization and hvm AMIs

keypair_name - The name of the keypair to use to bootstrap AMIs which support it.

monitoring - Set to "true" to enable detailed monitoring.

session_token - The session token provided by STS

private_ip_address - The private IP address to assign to an instance within a VPC

elastic_ip - Can be set to 'true', or to an existing Elastic IP address. If true, allocate a new Elastic IP address to the instance. If set to an existing Elastic IP address, assign the address to the instance.

region - The region to start the instance in, such as "us-east-1"

secret_access_key - The secret access key for accessing AWS

security_groups - An array of security groups for the instance. If this instance will be launched in VPC, this must be a list of security group Name. For a nondefault VPC, you must use security group IDs instead (http://docs.aws.amazon.com/cli/latest/reference/ec2/run-instances.html).

iam_instance_profile_arn - The Amazon resource name (ARN) of the IAM Instance Profile to associate with the instance

iam_instance_profile_name - The name of the IAM Instance Profile to associate with the instance

subnet_id - The subnet to boot the instance into, for VPC.

associate_public_ip - If true, will associate a public IP address to an instance in a VPC.

ssh_host_attribute - If :public_ip_address, :dns_name, or :private_ip_address, will use the public IP address, DNS name, or private IP address, respectively, to SSH to the instance. By default Vagrant uses the first of these (in this order) that is known. However, this can lead to connection issues if, e.g., you are assigning a public IP address but your security groups prevent public SSH access and require you to SSH in via the private IP address; specify :private_ip_address in this case.

tenancy - When running in a VPC configure the tenancy of the instance. Supports 'default' and 'dedicated'.

tags - A hash of tags to set on the machine.

package_tags - A hash of tags to set on the ami generated during the package operation.

use_iam_profile - If true, will use IAM profiles for credentials.

block_device_mapping - Amazon EC2 Block Device Mapping Property

elb - The ELB name to attach to the instance.

unregister_elb_from_az - Removes the ELB from the AZ on removal of the last instance if true (default). In non default VPC this has to be false.

terminate_on_shutdown - Indicates whether an instance stops or terminates when you initiate shutdown from the instance.
endpoint - The endpoint URL for connecting to AWS (or an AWS-like service). Only required for non AWS clouds, such as eucalyptus.


These can be set like typical provider-specific configuration:

```
Vagrant.configure("2") do |config|
  # ... other stuff

  config.vm.provider :aws do |aws|
    aws.access_key_id = "foo"
    aws.secret_access_key = "bar"
  end
end
```

Note that you do not have to hard code your aws.access_key_id or aws.secret_access_key as they will be retrieved from the enviornment variables AWS_ACCESS_KEY and AWS_SECRET_KEY.

In addition to the above top-level configs, you can use the region_config method to specify region-specific overrides within your Vagrantfile. Note that the top-level region config must always be specified to choose which region you want to actually use, however. This looks like this:

```bash
Vagrant.configure("2") do |config|
  # ... other stuff

  config.vm.provider :aws do |aws|
    aws.access_key_id = "foo"
    aws.secret_access_key = "bar"
    aws.region = "us-east-1"

    # Simple region config
    aws.region_config "us-east-1", :ami => "ami-12345678"

    # More comprehensive region config
    aws.region_config "us-west-2" do |region|
      region.ami = "ami-87654321"
      region.keypair_name = "company-west"
    end
  end
end
```

The region-specific configurations will override the top-level configurations when that region is used. They otherwise inherit the top-level configurations, as you would probably expect.

### Networks
Networking features in the form of config.vm.network are not supported with vagrant-aws, currently. If any of these are specified, Vagrant will emit a warning, but will otherwise boot the AWS machine.

### Synced Folders
There is minimal support for synced folders. Upon vagrant up, vagrant reload, and vagrant provision, the AWS provider will use rsync (if available) to uni-directionally sync the folder to the remote machine over SSH.

**See Vagrant Synced folders: rsync**

## Other Examples
### Tags
To use tags, simply define a hash of key/value for the tags you want to associate to your instance, like:

```bash
Vagrant.configure("2") do |config|
  # ... other stuff

  config.vm.provider "aws" do |aws|
    aws.tags = {
	  'Name' => 'Some Name',
	  'Some Key' => 'Some Value'
    }
  end
end
```

### User data
You can specify user data for the instance being booted.

```bash
Vagrant.configure("2") do |config|
  # ... other stuff

  config.vm.provider "aws" do |aws|
    # Option 1: a single string
    aws.user_data = "#!/bin/bash\necho 'got user data' > /tmp/user_data.log\necho"

    # Option 2: use a file
    aws.user_data = File.read("user_data.txt")
  end
end
```

### Disk size
Need more space on your instance disk? Increase the disk size.

```bash
Vagrant.configure("2") do |config|
  # ... other stuff

  config.vm.provider "aws" do |aws|
    aws.block_device_mapping = [{ 'DeviceName' => '/dev/sda1', 'Ebs.VolumeSize' => 50 }]
  end
end
```

### ELB (Elastic Load Balancers)
You can automatically attach an instance to an ELB during boot and detach on destroy.

```bash
Vagrant.configure("2") do |config|
  # ... other stuff

  config.vm.provider "aws" do |aws|
    aws.elb = "production-web"
  end
end
```
