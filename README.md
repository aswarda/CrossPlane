# Crossplane Composition for AWS Aurora PostgreSQL Cluster

## Table of Contents
1. [Overview](#overview)
2. [Purpose](#purpose)
3. [Key Features](#key-features)
4. [Components of the Composition](#components-of-the-composition)
   - [4.1. AWS Aurora DataBase SecurityGroup](#41-aws-aurora-database-securitygroup)
   - [4.2. AWS Aurora DataBase SubnetGroup](#42-aws-aurora-database-subnetgroup)
   - [4.3. AWS Aurora DataBase Regional Cluster](#43-aws-aurora-database-regional-cluster)
   - [4.4. AWS Aurora DataBase SecurityGroup-Inbound-Rule](#44-aws-aurora-database-securitygroup-inbound-rule)
   - [4.5. AWS Aurora DataBase SecurityGroup-Outbound-Rule](#45-aws-aurora-database-securitygroup-outbound-rule)
   - [4.6. AWS Aurora DataBase cluster-parameter-group](#46-aws-aurora-database-cluster-parameter-group)
   - [4.7. AWS Aurora DataBase Instance-parameter-group](#47-aws-aurora-database-instance-parameter-group)
   - [4.8. AWS Aurora DataBase cluster-Option-group](#48-aws-aurora-database-cluster-option-group)
   - [4.9. AWS Aurora DataBase Monitoring-Role](#49-aws-aurora-database-monitoring-role)
   - [4.10. AWS Aurora DataBase Writer-Instance](#410-aws-aurora-database-writer-instance)
   - [4.11. AWS Aurora DataBase Reader-Instance](#411-aws-aurora-database-reader-instance)
5. [Benefits of Using Crossplane for Aurora PostgreSQL](#benefits-of-using-crossplane-for-aurora-postgresql)
6. [Usage Instructions](#usage-instructions)
7. [Conclusion](#conclusion)

## 1. Overview
This document provides details about the Crossplane composition used to create an AWS Aurora PostgreSQL cluster along with several AWS managed resources like security group, IAM role, subnet group, parameter group, etc. The composition defines an **XAuroradb** custom resource that enables declarative infrastructure management within a Kubernetes environment.

Getting started --> [https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/CHAP_GettingStartedAurora.html](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/CHAP_GettingStartedAurora.html)

## 2. Purpose
The purpose of this Crossplane composition is to provision and manage AWS Aurora PostgreSQL clusters using Kubernetes-native APIs. It enables automation, repeatability, and infrastructure-as-code (IaC) principles for managing database resources efficiently using Crossplane.

## 3. Key Features
- **Declarative Infrastructure:** Manage AWS Aurora PostgreSQL clusters using Kubernetes CRDs.
- **Multi-Resource Provisioning:** The composition creates multiple AWS resources, including:
    - Aurora PostgreSQL Cluster
    - Aurora Cluster Instances (Writer and Reader)
    - Subnet Group Configuration
    - Security Groups
    - Parameter Groups
    - Monitoring and Role Assignments
    - Pushing the DataBase metrics AWS CloudWatch log groups.
- **Security and Access Control:** Supports encryption, security groups, and CIDR-based access control.
- **Scalability and High Availability:** Supports read replicas, automatic failover, and writer instances to enhance performance and availability.
- **Enhanced Monitoring:** Allows deeper insights into database performance using CloudWatch metrics.

## 4. Components of the Composition

### 4.1. AWS Aurora DataBase SecurityGroup
- **Crossplane Kind:** `ec2.aws.upbound.io/v1beta1.SecurityGroup`
- **AWS Concept: Security Groups**
    - AWS Security Groups act as a virtual firewall for your EC2 instances and other AWS resources, including RDS instances within a VPC. They control inbound and outbound traffic at the instance level, operating at the protocol and port level. You define rules to specify which traffic is allowed. Security Groups are stateful, meaning that if you allow inbound traffic, the response traffic is automatically allowed outbound, and vice versa.
- **Purpose in Composition:** Creates a security group to control network access to the Aurora database cluster.
- **Key Configurations & AWS Links:**
    - `description`: A human-readable description of the security group. [AWS Docs: Security Group Descriptions](https://docs.aws.amazon.com/vpc/latest/userguide/working-with-security-groups.html#sg-description)
    - `region`: Specifies the AWS Region where the security group will be created. [AWS Docs: AWS Regions](https://aws.amazon.com/about-aws/global-infrastructure/regions_az/)
    - `vpcId`: The ID of the VPC in which to create the security group. [AWS Docs: Amazon VPCs](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)
    - `metadata.name` (derived from `spec.securityGroupName`): The name of the security group. [AWS Docs: Naming Restrictions](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-tags.html#tag-restrictions)
- **Patches:** The composition patches the `region`, `vpcId`, and `metadata.name` from the composite `XAuroradb` resource. It also exports the generated Security Group ID to the `status.securityGroupId` of the composite resource.
- **AWS Documentation:** [Amazon VPC Security Groups](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html)

### 4.2. AWS Aurora DataBase SubnetGroup
- **Crossplane Kind:** `rds.aws.upbound.io/v1beta1.SubnetGroup`
- **AWS Concept: DB Subnet Groups**
    - A DB subnet group is a collection of subnets (typically private) that you designate for your RDS DB instances in a VPC. Each DB subnet group should have at least one subnet for every Availability Zone in a given AWS Region. When you create a DB instance in a VPC, you must associate it with a DB subnet group. RDS then chooses a subnet within that DB subnet group and a corresponding IP address within that subnet to provision your DB instance. This ensures high availability by allowing RDS to provision instances in different AZs.
- **Purpose in Composition:** Defines the subnets within the VPC where the Aurora cluster instances can be launched.
- **Key Configurations & AWS Links:**
    - `description`: A human-readable description for the DB subnet group. [AWS Docs: DB Subnet Group Concepts](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_VPC.WorkingWithRDSInstanceinaVPC.html#USER_VPC.Subnets)
    - `region`: Specifies the AWS Region for the subnet group. [AWS Docs: AWS Regions](https://aws.amazon.com/about-aws/global-infrastructure/regions_az/)
    - `subnetIds`: A list of subnet IDs in your VPC. It's recommended to include subnets from multiple Availability Zones. [AWS Docs: VPC Subnets](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html)
- **Patches:** The composition patches the `region` and `subnetIds` from the composite `XAuroradb` resource. It also exports the generated DB Subnet Group Name to the `status.dbSubnetGroupName` of the composite resource.
- **AWS Documentation:** [Working with DB Subnet Groups](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_VPC.WorkingWithRDSInstanceinaVPC.html#USER_VPC.Subnets)

### 4.3. AWS Aurora DataBase Regional Cluster
- **Crossplane Kind:** `rds.aws.upbound.io/v1beta1.Cluster`
- **AWS Concept: Amazon Aurora Cluster**
    - An Amazon Aurora DB cluster consists of one or more DB instances and a cluster volume that manages the data for those instances. An Aurora cluster has one primary instance (writer) that supports read and write operations, and up to 15 Aurora Replicas (readers) that support only read operations. Aurora automatically replicates the data within the cluster volume across multiple Availability Zones, providing high availability and data durability.
- **Purpose in Composition:** Creates the core Aurora PostgreSQL database cluster.
- **Key Configurations & AWS Links:**
    - `region`: Specifies the AWS Region for the Aurora cluster. [AWS Docs: AWS Regions](https://aws.amazon.com/about-aws/global-infrastructure/regions_az/)
    - `dbSubnetGroupName`: The name of the DB subnet group to associate with the cluster (obtained from the `AWS-Aurora-DataBase-SubnetGroup` resource status). [AWS Docs: Associating Subnet Groups](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Managing.html#Aurora.Managing.SubnetGroup)
    - `vpcSecurityGroupIds`: A list of VPC security groups to associate with the cluster (initially a placeholder, then patched with the ID of the `AWS-Aurora-DataBase-SecurityGroup` resource). [AWS Docs: Security Groups for RDS](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/SecurityGroups.html)
    - `engine`: The name of the database engine to be used for this DB cluster (e.g., `aurora-postgresql`). [AWS Docs: Aurora Engines](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Overview.html#Aurora.Overview.DBEngines)
    - `engineVersion`: The version number of the database engine to use. [AWS Docs: Aurora Engine Versions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Updates.html)
    - `networkType`: Specifies the network type, such as `IPV4`. [AWS Docs: IP Addressing in VPC](https://docs.aws.amazon.com/vpc/latest/userguide/ip-addressing-ipv4.html)
    - `databaseName`: The name for the initial database in the DB cluster. [AWS Docs: Creating an Aurora Cluster](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.CreatingCluster.html)
    - `masterUsername`: The name of the master user for the DB cluster. [AWS Docs: Master User Account](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/security-db-user.html)
    - `masterPasswordSecretRef`: A reference to a Kubernetes Secret containing the master password. [Kubernetes Docs: Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
    - `copyTagsToSnapshot`: Indicates whether to copy all tags from the DB cluster to snapshots of the DB cluster. [AWS Docs: Tagging RDS Resources](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Tagging.html)
    - `engineMode`: Specifies the engine mode of the Aurora cluster (e.g., `provisioned`). [AWS Docs: Aurora Engine Modes](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless.html)
    - `port`: The port number on which the DB instances in the DB cluster accept connections (default PostgreSQL: 5432). [AWS Docs: RDS Instance Ports](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Overview.html#Aurora.Overview.DBPorts)
    - `backtrackWindow`: The target backtrack window, in seconds. Setting to 0 disables backtracking. [AWS Docs: Aurora Backtrack](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Managing.Backtracking.html)
    - `finalSnapshotIdentifier`: The identifier for the final snapshot to be created before deleting the cluster. [AWS Docs: Deleting an Aurora Cluster](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.DeletingCluster.html)
    - `backupRetentionPeriod`: The number of days for which automatic backups are retained. [AWS Docs: Working with Backups](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_WorkingWithAutomatedBackups.html)
    - `preferredBackupWindow`: The daily time range during which automated backups are created. [AWS Docs: Specifying Backup Window](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_WorkingWithAutomatedBackups.html#USER_WorkingWithAutomatedBackups.BackupWindow)
    - `preferredMaintenanceWindow`: The weekly time range during which system maintenance can occur. [AWS Docs: The Maintenance Window](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_UpgradeDBInstance.Maintenance.html)
    - `iamDatabaseAuthenticationEnabled`: Indicates whether to enable IAM database authentication. [AWS Docs: IAM Database Authentication](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/iam-authentication.html)
    - `storageEncrypted`: Indicates whether the DB cluster is encrypted at rest. [AWS Docs: Encrypting Aurora Resources](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Encrypt.html)
    - `autoGeneratePassword`: Indicates that the master password will not be automatically generated.
    - `manageMasterUserPassword`: Indicates that the master user password will not be managed by AWS.
    - `deleteAutomatedBackups`: Indicates whether to delete automated backups when the cluster is deleted.
    - `performanceInsightsEnabled`: Specifies whether Performance Insights are enabled. [AWS Docs: Amazon RDS Performance Insights](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/performance-insights.html)
    - `performanceInsightsRetentionPeriod`: The number of days to retain Performance Insights data. [AWS Docs: Performance Insights Data Retention](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/performance-insights.html#performance-insights-retention)
    - `allowMajorVersionUpgrade`: Indicates whether major version upgrades are allowed. [AWS Docs: Upgrading Aurora PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.PostgreSQL.MajorVersionUpgrades.html)
    - `applyImmediately`: Indicates that any modifications to the DB cluster are applied immediately. [AWS Docs: Applying Modifications](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_ApplyModifications.html)
    - `deletionProtection`: If set to true, prevents the DB cluster from being deleted. [AWS Docs: Enabling Deletion Protection](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/UsingWithDeletionProtection.html)
    - `enableHttpEndpoint`: Specifies whether the HTTP endpoint for the DB cluster is enabled. [AWS Docs: Aurora HTTP Endpoint](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/data-api.html)
    - `enableLocalWriteForwarding`: Enables local write forwarding to the primary instance from reader instances in the same AWS Region. [AWS Docs: Local Write Forwarding](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-global-database-write-forwarding.html)
    - `enableGlobalWriteForwarding`: Specifies whether to enable global write forwarding (for Global Aurora clusters). [AWS Docs: Global Write Forwarding](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-global-database-write-forwarding.html)
    - `engineLifecycleSupport`: Specifies the engine lifecycle support setting. [AWS Docs: RDS Extended Support](https://aws.amazon.com/rds/extended-support/)
    - `enabledCloudwatchLogsExports`: A list of log types to export to CloudWatch Logs. [AWS Docs: Publishing Aurora PostgreSQL Logs to Amazon CloudWatch Logs](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Managing.Common.LogFiles.html#AuroraPostgreSQL.Managing.Common.LogFiles.CloudWatch)
    - `dbClusterParameterGroupName`: The name of the DB cluster parameter group to associate with this DB cluster (obtained from the `AWS-Aurora-DataBase-cluster-parameter-group` resource status). [AWS Docs: Working with DB Cluster Parameter Groups](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_WorkingWithParamGroups.html#USER_WorkingWithClusterParamGroups)
    - `dbInstanceParameterGroupName`: The name of the DB instance parameter group to associate with all instances in the DB cluster (obtained from the `AWS-Aurora-DataBase-Instance-parameter-group` resource status). [AWS Docs: Working with DB Parameter Groups](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_WorkingWithParamGroups.html#USER_WorkingWithParamGroups.DBInstanceParamGroup)
- **Patches:** The composition patches various fields like `region`, `clusterName`, `engine`, `engineVersion`, `masterUsername`, and links the Security Group, Subnet Group, and Parameter Groups using `FromCompositeFieldPath`. It also exports the Cluster ID and Final Snapshot Identifier to the composite resource status.
- **AWS Documentation:** [Working with Aurora Clusters](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Managing.html)

### 4.4. AWS Aurora DataBase SecurityGroup-Inbound-Rule
- **Crossplane Kind:** `ec2.aws.upbound.io/v1beta1.SecurityGroupRule`
- **AWS Concept: Security Group Rules (Inbound)**
    - Inbound rules
