data "aws_caller_identity" "this" {}

resource "aws_cloudformation_stack" "example" {
  name         = var.stack_name
  capabilities = ["CAPABILITY_IAM"]
  parameters = {
    AccountId          = data.aws_caller_identity.this.account_id
    BucketArn          = var.BucketArn
    DeliveryStreamName = var.delivery_stream_name
    DomainArn          = var.domain_arn
    IndexName          = var.index_name
    SecurityGroup      = var.security_group_ids
    SubnetIds          = var.subnet_ids

  }
  template_body = <<STACK

  {
    "AWSTemplateFormatVersion": "2010-09-09",
    "Description": "The AWS CloudFormation template for Kinesis Stream",
      "Parameters":{
        "SecurityGroup":{
          "Type": "List<AWS::EC2::SecurityGroup::Id>"
        },
        "SubnetIds": {
          "Type": "List<AWS::EC2::Subnet::Id>"
        },
        "BucketArn": {
          "Type": "String"
        },
        "DomainArn": {
          "Type": "String"
        },
        "IndexName": {
          "Type": "String"
        },
        "DeliveryStreamName": {
          "Type": "String"
        },
        "AccountId":{
          "Type": "String"
        }

      
      },
     
    "Resources": {
      "KinesisFirehoseDeliveryStream": {
          "Type": "AWS::KinesisFirehose::DeliveryStream",
          "Properties": {
            "DeliveryStreamName": {"Ref":"DeliveryStreamName"},
            "DeliveryStreamType": "DirectPut",
            "ElasticsearchDestinationConfiguration": {
              "DomainARN" : {"Ref": "DomainArn"},
              "IndexName" : {"Ref": "IndexName"},
              "RoleARN" : {"Fn::GetAtt": ["FirehoseDeliveryIAMRole", "Arn"]},
              "S3Configuration" : {
                "BucketARN" : {"Ref":"BucketArn"},
                "Prefix" : "es_Logs",
                "RoleARN" : {"Fn::GetAtt": ["FirehoseDeliveryIAMRole", "Arn"]}
              },
              
              "VpcConfiguration" : {
               "RoleARN" : {"Fn::GetAtt": ["FirehoseDeliveryIAMRole", "Arn"]},
               "SecurityGroupIds" : {"Ref":"SecurityGroup"},
               "SubnetIds" : {"Ref":"SubnetIds"}
  }
            }
          },
           "DependsOn": ["FirehoseDeliveryIAMPolicy"]
          
        },
        "FirehoseDeliveryIAMRole": {
          "Type": "AWS::IAM::Role",
          "Properties": {
            "AssumeRolePolicyDocument": {
              "Version": "2012-10-17",
              "Statement": [
                {
                  "Sid": "",
                  "Effect": "Allow",
                  "Principal": {
                    "Service": "firehose.amazonaws.com"
                  },
                  "Action": "sts:AssumeRole",
                  "Condition": {
                    "StringEquals": {
                      "sts:ExternalId": {"Ref": "AccountId"}
                    }
                  }
                }]
            }
          }
        },
        "FirehoseDeliveryIAMPolicy": {
          "Type": "AWS::IAM::Policy",
          "Properties": {
            "PolicyName": "firehose-role",
            "PolicyDocument": {
              "Version": "2012-10-17",
              "Statement": [
                {
                  "Effect": "Allow",
                  "Action": [
                    "s3:AbortMultipartUpload",
                    "s3:GetBucketLocation",
                    "s3:GetObject",
                    "s3:ListBucket",
                    "s3:ListBucketMultipartUploads",
                    "s3:PutObject"
                  ],
                  "Resource": [
                    "arn:aws:s3:::BucketArn*"
                  ]
                },
                
              {
               "Effect": "Allow",
               "Action": [
               "kms:*",
               "logs:*",
               "lambda:*",
               "es:*",
               "ec2:*"
               ],
               "Resource": "*"
               
              
              
              }]
            },
            "Roles": [{"Ref": "FirehoseDeliveryIAMRole"}]
          }
          
        }
      }
     
  }


  STACK
}
