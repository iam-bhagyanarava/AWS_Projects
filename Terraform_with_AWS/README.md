Avoid using the ingress and egress arguments of the aws_security_group resource to configure in-line rules, as they struggle with managing multiple CIDR blocks, and, due to the historical lack of unique IDs, tags and descriptions. 
To avoid these problems, use the current best practice of the aws_vpc_security_group_egress_rule and aws_vpc_security_group_ingress_rule resources with one CIDR block per rule.

# Old way (inline ingress / egress)
resource "aws_security_group" "webSg" {
  ingress { ... }
  ingress { ... }
}
## Terraform sees this as:
“This security group has a list of rules”
has no stable IDs
is order-sensitive
is managed as a whole
So Terraform cannot tell: which rule is “HTTP” which rule is “SSH” which CIDR inside a rule changed

# New way (rule resources)
resource "aws_vpc_security_group_ingress_rule" "http" { ... }
resource "aws_vpc_security_group_ingress_rule" "ssh"  { ... }

## Terraform now sees:
“This security group has distinct child resources, each with its own ID”

### Each rule becomes:
independently tracked
independently created / destroyed
independently diffed
That’s the key upgrade.
