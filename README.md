# infstones-second-exercise
Second exercise for Infstones

You can run this exercise by installing the AWS CLI and terraform.  You need then setup your AWS credentials and likely modify the username.  The terraform module and userdata scripts assume that you already have the IAM user, IAM role, instance profile, S3 bucket w/ bootstrap scrip, and key pair setup.

Finally run `terraform apply` to setup the resources.  Then run `terraform destroy` to tear down the resources.
