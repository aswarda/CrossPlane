# Crossplane Composition for AWS Aurora PostgreSQL Cluster

## Overview
This document provides details about the Crossplane composition used to create an AWS Aurora PostgreSQL cluster along with few AWS managed resources like securitygroup, iam role, subnetgroup & parametergroup ..etc. The composition defines an **XAuroradb** custom resource that enables declarative infrastructure management within a Kubernetes environment.

Getting started --> https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/CHAP_GettingStartedAurora.html

## Purpose
The purpose of this Crossplane composition is to provision and manage AWS Aurora PostgreSQL clusters using Kubernetes-native APIs. It enables automation, repeatability, and infrastructure-as-code (IaC) principles for managing database resources efficiently using the crossplane.

## Key Features
- **Declarative Infrastructure:** Manage AWS Aurora PostgreSQL clusters using Kubernetes CRDs.
- **Multi-Resource Provisioning:** The composition creates multiple AWS resources, including:
  - Aurora PostgreSQL Cluster
  - Aurora Cluster Instances (Writer and Reader)
  - SubnetGroup Configuration
  - Security Groups
  - Parameter Groups
  - Monitoring and Role Assignments
  - Pushing the DataBase metrics AWS cloudwatch log groups.

- **Security and Access Control:** Supports encryption, security groups, and CIDR-based access control.
- **Scalability and High Availability:** Supports read replicas, automatic failover, and writer instances to enhance performance and availability.
- **Enhanced Monitoring:** Allows deeper insights into database performance using CloudWatch metrics.

## Components of the Composition
The composition defines the following key components:

### 1. **Region and Networking**
- The AWS region where the Aurora cluster will be deployed.
- VPC and subnets configuration to define the networking environment.
- Security groups to control access to the database.

### 2. **Aurora PostgreSQL Cluster Configuration**
- Database engine and version selection.
- Cluster and instance-level parameter groups for fine-grained configuration.
- Instance class definitions for primary and replica instances.

### 3. **Aurora Cluster Instances and Failover Mechanism**
- The cluster consists of at least one **writer instance** (primary) and **replica instances** for high availability.
- Automatic **failover** ensures that if the primary instance becomes unavailable, one of the replicas is promoted to the primary role.
- Read replicas help distribute the database load and improve performance for read-intensive applications.

AWS postgres Failover --> https://aws.amazon.com/blogs/database/failover-with-amazon-aurora-postgresql/

### 4. **Security and Access Management**
- Security groups for firewall protection.
- Ingress rules based on CIDR blocks.
- Storage encryption using AWS KMS.

### 5. **Enhanced Monitoring and Logging**
- **Enhanced Monitoring** is enabled using CloudWatch, providing detailed performance insights such as CPU, memory, and disk utilization.
- IAM role assignment for monitoring to ensure secure access to CloudWatch metrics.
- Final snapshot configuration for backup and restore purposes.

Enhanced Monitoring --> https://docs.aws.amazon.com/prescriptive-guidance/latest/amazon-rds-monitoring-alerting/enhanced-monitoring.html

### 6. **Database Administration**
- Master username for administrative access.
- Cluster identifier for easy management and tracking.
- Certificate expiry tracking for compliance.

## Benefits of Using Crossplane for Aurora PostgreSQL
- **Kubernetes-Native:** Seamless integration with Kubernetes workflows.
- **Automated Provisioning:** Reduces manual intervention and ensures consistency.
- **Scalability:** Easily scale instances and replicas based on demand.
- **Security Compliance:** Enforces best practices for access control and encryption.
- **High Availability with Failover:** Ensures minimal downtime by automatically promoting replicas during failures.
- **Enhanced Monitoring:** Helps track performance metrics and optimize database performance.

## Usage Instructions
1. Deploy Crossplane in your Kubernetes cluster.
2. Apply the **XAuroradb** CRD to register the custom resource.
3. Create an instance of the **XAuroradb** resource with desired specifications.
4. Apply the claim manifest like below

apiVersion: aws.caas.mercedes-benz.com/v1alpha1
kind: XAuroradbclaim 
metadata:
  name: caas-goldenpath-pi8
  namespace: crossplane-system
spec:
  region: eu-central-1
  vpcId: vpc-0cda6e7c1abe13aa4
  subnetIds:
    - subnet-01e1048d9aedda9d7
    - subnet-0103f82819b65a486
  engineVersion: "16.1"
  majorEngineVersion: "16"
  family: aurora-postgresql16
  masterUsername: c82p024admin
  replicainstanceclass: db.t3.medium
  ingressCidrBlock:
    - 10.0.16.0/20

5. Crossplane will automatically provision the AWS Aurora PostgreSQL cluster and associated resources.
6. Monitor the status of the provisioned resources using `kubectl get XAuroradb`.
7. Utilize CloudWatch monitoring dashboards for performance tracking.

## Conclusion
This Crossplane composition simplifies the provisioning and management of AWS Aurora PostgreSQL clusters using a declarative approach. It ensures best practices for security, scalability, high availability, and automation while integrating seamlessly with Kubernetes workflows. With built-in failover mechanisms and enhanced monitoring, the composition guarantees improved database reliability and performance.

