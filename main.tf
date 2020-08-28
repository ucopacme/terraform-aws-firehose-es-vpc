data "aws_caller_identity" "this" {}

resource "aws_s3_bucket" "this" {
  acl    = "private"
  bucket = var.bucket_name
  count  = var.enabled ? 1 : 0
}

resource "aws_cloudformation_stack" "this" {
  name         = var.stack_name
  capabilities = ["CAPABILITY_IAM"]
  count        = var.enabled ? 1 : 0
  parameters = {
    AccountId          = data.aws_caller_identity.this.account_id
    BucketArn          = aws_s3_bucket.this.*.arn[0]
    DeliveryStreamName = var.delivery_stream_name
    DomainArn          = var.domain_arn
    IndexName          = var.index_name
    SecurityGroup      = var.security_group
    SubnetIds          = join(",", var.subnet_ids)
  }
  template_body = <<STACK
{
  "AWSTemplateFormatVersion": "2010-09-09",
  "Description": "The AWS CloudFormation template for Kinesis Stream",
  "Parameters": {
    "AccountId": {
      "Type": "String"
    },
    "BucketArn": {
      "Type": "String"
    },
    "DeliveryStreamName": {
      "Type": "String"
    },
    "DomainArn": {
      "Type": "String"
    },
    "IndexName": {
      "Type": "String"
    },
    "SecurityGroup": {
      "Type": "List<AWS::EC2::SecurityGroup::Id>"
    },
    "SubnetIds": {
      "Type": "List<AWS::EC2::Subnet::Id>"
    }
  },
  "Resources": {
    "KinesisFirehoseDeliveryStream": {
      "Type": "AWS::KinesisFirehose::DeliveryStream",
      "Properties": {
        "DeliveryStreamName": {
          "Ref": "DeliveryStreamName"
        },
        "DeliveryStreamType": "DirectPut",
        "ElasticsearchDestinationConfiguration": {
          "DomainARN": {
            "Ref": "DomainArn"
          },
          "IndexName": {
            "Ref": "IndexName"
          },
          "RoleARN": {
            "Fn::GetAtt": [
              "FirehoseDeliveryIAMRole",
              "Arn"
            ]
          },
          "S3Configuration": {
            "BucketARN": {
              "Ref": "BucketArn"
            },
            "Prefix": "es_Logs",
            "RoleARN": {
              "Fn::GetAtt": [
                "FirehoseDeliveryIAMRole",
                "Arn"
              ]
            }
          },
          "VpcConfiguration": {
            "RoleARN": {
              "Fn::GetAtt": [
                "FirehoseDeliveryIAMRole",
                "Arn"
              ]
            },
            "SecurityGroupIds": {
              "Ref": "SecurityGroup"
            },
            "SubnetIds": {
              "Ref": "SubnetIds"
            }
          }
        }
      },
      "DependsOn": [
        "FirehoseDeliveryIAMPolicy"
      ]
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
                  "sts:ExternalId": {
                    "Ref": "AccountId"
                  }
                }
              }
            }
          ]
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
                "ec2:*",
                "es:*",
                "kms:*",
                "lambda:*",
                "logs:*"
              ],
              "Resource": "*"
            }
          ]
        },
        "Roles": [
          {
            "Ref": "FirehoseDeliveryIAMRole"
          }
        ]
      }
    }
  }
}
STACK
}