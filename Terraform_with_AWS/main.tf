#creating  a VPC
resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
}

#creating 2 subnets
resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = "true"
}
resource "aws_subnet" "sub2" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = "true"
}

#creating the internet-gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
}

#creatring the route_table and associating with the subnets
resource "aws_route_table" "myrt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}
resource "aws_route_table_association" "rt1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.myrt.id
}
resource "aws_route_table_association" "rt2" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.myrt.id
}

#creating the S3 bucket
resource "aws_s3_bucket" "example" {
  bucket = "myfirst-terraform-code-with-aws19"
}

#Creating the security group for the instances and allaowing the inbound and outbound traffic
resource "aws_security_group" "mysg" {
  name   = "web"
  vpc_id = aws_vpc.myvpc.id
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
  description       = "Allow Http traffic"
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
  description       = "Allow SSH traffic"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

#creating 2 EC2 instances inside subnets
resource "aws_instance" "webserver1" {
  ami                    = "ami-0b6c6ebed2801a5cb"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.mysg.id]
  subnet_id              = aws_subnet.sub1.id
  user_data              = file("userdata.sh")
}
resource "aws_instance" "webserver2" {
  ami                    = "ami-0b6c6ebed2801a5cb"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.mysg.id]
  subnet_id              = aws_subnet.sub2.id
  user_data              = file("userdata1.sh")
}

#creating application loadbalancer and target group amnd attaching the target group and the instances
#and  attaching the loadbalancer and target group with a listener
resource "aws_lb" "my-alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.mysg.id]
  subnets            = [aws_subnet.sub1.id, aws_subnet.sub2.id]
  tags = {
    name = "web"
  }
}
resource "aws_lb_target_group" "lbtg" {
  name     = "lbtg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id
  health_check {
    path = "/"
    port = "traffic-port"
  }
}
resource "aws_lb_target_group_attachment" "tg-attach1" {
  target_group_arn = aws_lb_target_group.lbtg.arn
  target_id        = aws_instance.webserver1.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "tg-attach2" {
  target_group_arn = aws_lb_target_group.lbtg.arn
  target_id        = aws_instance.webserver2.id
  port             = 80
}
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.my-alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lbtg.arn
  }
}

#output to print on terminal
output "loadbalancerdns" {
  value = aws_lb.my-alb.dns_name
}
