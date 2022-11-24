resource "aws_vpc" "this" {
  cidr_block = var.cidr_block

  tags = {
    Name = local.project_prefix
  }
}

resource "aws_default_route_table" "this" {
  default_route_table_id = aws_vpc.this.default_route_table_id

  tags = {
    Name = "${local.project_prefix} default route table"
  }
}

resource "aws_default_network_acl" "this" {
  default_network_acl_id = aws_vpc.this.default_network_acl_id

  ingress {
    rule_no = 100
    cidr_block = "0.0.0.0/0"
    action = "allow"
    from_port = 0
    to_port = 0
    protocol = "all"
  }

  egress {
    rule_no = 100
    cidr_block = "0.0.0.0/0"
    action = "allow"
    from_port = 0
    to_port = 0
    protocol = "all"
  }

  tags = {
    Name = local.project_prefix
  }
}

resource "aws_subnet" "this" {
  count = length(var.subnet_names)

  availability_zone = data.aws_availability_zones.this.names[count.index]
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.cidr_block, 2, count.index)

  tags = {
    Name = "${local.project_prefix} ${var.subnet_names[count.index]} subnet"
  }
}

resource "aws_route_table" "this" {
  count = length(var.subnet_names)

  vpc_id = aws_vpc.this.id

  tags = {
    Name = aws_subnet.this[count.index].tags_all["Name"]
  }
}

resource "aws_route_table_association" "this" {
  count = length(var.subnet_names)

  route_table_id = aws_route_table.this[count.index].id
  subnet_id      = aws_subnet.this[count.index].id
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.project_prefix} InternetGateway"
  }
}

resource "aws_eip" "this" {
  vpc = true

  tags = {
    Name = "${local.project_prefix}  API EIP"
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id     = aws_eip.this.id
  subnet_id         = aws_subnet.this[0].id
  connectivity_type = "public"

  tags = {
    Name = "${local.project_prefix} NAT Gateway"
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.this[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route" "private" {
  route_table_id         = aws_route_table.this[1].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

resource "aws_vpc_endpoint" "this" {
  for_each = {
    ecr_api = "com.amazonaws.us-west-2.ecr.api"
    ecr_dkr = "com.amazonaws.us-west-2.ecr.dkr"
  }

  vpc_id              = aws_vpc.this.id
  service_name        = each.value
  subnet_ids          = [aws_subnet.this[1].id]
  vpc_endpoint_type   = "Interface"
  auto_accept         = true
  private_dns_enabled = true
  ip_address_type     = "ipv4"

  security_group_ids = [
    aws_security_group.this.id,
  ]

  dns_options {
    dns_record_ip_type = "ipv4"
  }
}