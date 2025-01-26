# Terraform VPC Endpoint Demo

This repository provides a Terraform configuration for deploying a simple VPC setup, including public and private subnets, NAT and Internet gateways, security groups, and an EC2 instance with VPC endpoints. The goal is to demonstrate how to securely connect to instances within a private subnet using **VPC Endpoints**.

## 📌 Overview Diagram

```plaintext
                          +---------------------------+
                          |       AWS Cloud          |
                          +---------------------------+
                                   │
                 +-----------------+-----------------+
                 |                                     |
         +---------------+                     +---------------+
         |  Public Subnet |                     | Private Subnet |
         +---------------+                     +---------------+
                 │                                     │
        +---------------+                      +----------------+
        | Internet GW   |                      | NAT Gateway    |
        +---------------+                      +----------------+
                                                  │
                          +--------------------------------+
                          |  EC2 Instance (Jumphost)      |
                          +--------------------------------+
                                                  │
                     +--------------------------------------+
                     |      VPC Endpoints (SSM, Logs, etc.) |
                     +--------------------------------------+
```

## 🚀 Usage

### Prerequisites

Ensure you have the following installed:

- [Terraform](https://www.terraform.io/downloads)
- AWS CLI configured with appropriate credentials

### Deployment

1. Clone this repository:

   ```sh
   git clone git@github.com:jdevto/tf-aws-vpc-endpoint-demo.git
   ```

2. Initialize Terraform:

   ```sh
   terraform init
   ```

3. Plan the deployment:

   ```sh
   terraform plan
   ```

4. Apply the configuration:

   ```sh
   terraform apply -auto-approve
   ```

5. Retrieve the EC2 instance details:

   ```sh
   terraform output
   ```

## 🔌 VPC Endpoints

This deployment includes the following **VPC Endpoints**:

- **SSM Endpoint**: Enables Systems Manager (SSM) to manage instances in private subnets.
- **SSM Messages Endpoint**: Required for SSM Session Manager communication.
- **EC2 Messages Endpoint**: Used by AWS services to communicate with EC2 instances.
- **CloudWatch Logs Endpoint**: Allows instances to send logs to CloudWatch without internet access.

These endpoints ensure that EC2 instances in private subnets can access AWS services without requiring an internet gateway.

## 🛡️ Security Group Requirement

A dedicated **security group** is configured to allow **VPC traffic** for EC2 instances and VPC endpoints. This ensures private network communication between AWS services and instances without exposing them to the internet.

## 🔍 Troubleshooting Common Issues

### 1. Checking VPC Endpoint Connectivity

If an endpoint is not accessible, verify the network connectivity:

```sh
aws ec2 describe-vpc-endpoints --region <your-region>
```

For **CloudWatch Logs Endpoint**, check if the log URL is reachable:

```sh
curl -v https://logs.<your-region>.amazonaws.com
```

If the response is not `200 OK`, check the security group and subnet configuration.

### 2. Verifying EC2 Connectivity

Ensure your **EC2 instance** can communicate with required AWS services:

```sh
aws ssm describe-instance-information
```

If this fails, ensure the instance has the necessary IAM role and security group rules.

### 3. Checking Private DNS Resolution

If an endpoint is not resolving:

```sh
nc -zv logs.<your-region>.amazonaws.com 443
```

Ensure that **Private DNS** is enabled for the VPC Endpoint.

## 💡 Suggestions for Improvements

- **Enable Private DNS** for VPC endpoints to simplify service access.
- **Use IAM Roles** instead of public keys for authentication where possible.
- **Integrate an ALB** for controlled external access.

## 🧹 Cleanup

To destroy all resources, run:

```sh
terraform destroy -auto-approve
```

## 📜 License

This project is for demonstration purposes only.
