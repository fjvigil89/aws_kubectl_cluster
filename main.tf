module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name                    = local.cluster_name
  cluster_version                 = "1.21"
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  cluster_encryption_config = [{
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }]

  vpc_id = module.vpc.vpc_id
  #subnet_ids = ["subnet-abcde012", "subnet-bcde012a", "subnet-fghi345a"]
  subnet_ids = module.vpc.private_subnets
  # Self Managed Node Group(s)
  self_managed_node_group_defaults = {
    instance_type                          = "t2.micro"
    update_launch_template_default_version = true
    #iam_role_additional_policies           = [aws_iam_role.nodes.arn]
    iam_role_additional_policies = [
      "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
      "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
      "arn:aws:iam::aws:policy/AdministratorAccess",
      "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
      "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
      "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess",
      "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
      "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
    ]
  }

  self_managed_node_groups = {
    one = {
      name = "spot-1"

      public_ip    = true
      max_size     = 5
      desired_size = 2

      use_mixed_instances_policy = true
      mixed_instances_policy = {
        instances_distribution = {
          on_demand_base_capacity                  = 0
          on_demand_percentage_above_base_capacity = 10
          spot_allocation_strategy                 = "capacity-optimized"
        }

        override = [
          {
            instance_type     = "t2.micro"
            weighted_capacity = "1"
          },
          {
            instance_type     = "t2.small"
            weighted_capacity = "2"
          },
          {
            instance_type     = "t2.medium"
            weighted_capacity = "3"
          },
        ]
      }

      pre_bootstrap_user_data = <<-EOT
      echo "foo"
      export FOO=bar
      EOT

      bootstrap_extra_args = "--kubelet-extra-args '--node-labels=node.kubernetes.io/lifecycle=spot'"

      post_bootstrap_user_data = <<-EOT
      cd /tmp
      sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
      sudo systemctl enable amazon-ssm-agent
      sudo systemctl start amazon-ssm-agent
      EOT
    }
  }

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    ami_type               = "AL2_x86_64"
    disk_size              = 50
    instance_types         = ["t2.micro", "t2.small", "t2.medium", "t2.large"]
    vpc_security_group_ids = [aws_security_group.all_worker_mgmt.id]
  }

  eks_managed_node_groups = {
    red = {
      min_size     = 1
      max_size     = 10
      desired_size = 1

      instance_types = ["t2.micro"]
      labels = {
        Environment = "test"
        GithubRepo  = "terraform-aws-eks"
        GithubOrg   = "terraform-aws-modules"
      }
      tags = {
        ExtraTag = "On-Demand"
      }

    }
    green = {
      min_size     = 1
      max_size     = 10
      desired_size = 1

      instance_types = ["t2.micro"]
      capacity_type  = "SPOT"
      labels = {
        Environment = "test"
        GithubRepo  = "terraform-aws-eks"
        GithubOrg   = "terraform-aws-modules"
      }
      /* taints = {
        dedicated = {
          key    = "dedicated"
          value  = "gpuGroup"
          effect = "NO_SCHEDULE"
        }
      } */
      tags = {
        ExtraTag = "Sport"
      }
    }
  }

  # Fargate Profile(s)
  fargate_profiles = {
    default = {
      name = "default"
      selectors = [
        {
          namespace = "kube-system"
          labels = {
            k8s-app = "kube-dns"
          }
        },
        {
          namespace = "default"
        }
      ]

      tags = {
        Owner = "test"
      }

      timeouts = {
        create = "20m"
        delete = "20m"
      }
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

resource "null_resource" "kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ${var.region} --name ${local.cluster_name}"
  }
  depends_on = [
    module.eks
  ]
}

resource "null_resource" "kubernetes_config" {

  provisioner "local-exec" {
    command = "touch ./kubeconfig.yaml && cat ~/.kube/config >> ./kubeconfig.yaml"
  }
  depends_on = [
    null_resource.kubeconfig
  ]
}
resource "null_resource" "delete_kubernetes_config" {

  provisioner "local-exec" {
    when    = "destroy"
    command = "rm ./kubeconfig.yaml"
  }


}

