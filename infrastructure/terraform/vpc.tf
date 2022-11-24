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

  subnet_ids = concat(
    [for subnet in aws_subnet.public : subnet.id],
    [for subnet in aws_subnet.private : subnet.id],
  )

  ingress {
    rule_no    = 100
    cidr_block = "0.0.0.0/0"
    action     = "allow"
    from_port  = 0
    to_port    = 0
    protocol   = "all"
  }

  egress {
    rule_no    = 100
    cidr_block = "0.0.0.0/0"
    action     = "allow"
    from_port  = 0
    to_port    = 0
    protocol   = "all"
  }

  tags = {
    Name = local.project_prefix
  }
}

resource "aws_subnet" "public" {
  count = 2

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 2, count.index)
  availability_zone = data.aws_availability_zones.this.names[count.index]

  tags = {
    Name = "${local.project_prefix} public subnet"
  }
}

resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 2, count.index + 2)
  availability_zone = data.aws_availability_zones.this.names[count.index]

  tags = {
    Name = "${local.project_prefix} private subnet"
  }
}

resource "aws_route_table" "this" {
  for_each = {
    public  = aws_subnet.public[0].tags_all["Name"]
    private = aws_subnet.private[0].tags_all["Name"]
  }

  vpc_id = aws_vpc.this.id

  tags = {
    Name = each.value
  }
}

resource "aws_route_table_association" "public" {
  count = 2

  route_table_id = aws_route_table.this["public"].id
  subnet_id      = aws_subnet.public[count.index].id
}

resource "aws_route_table_association" "private" {
  count = 2

  route_table_id = aws_route_table.this["private"].id
  subnet_id      = aws_subnet.private[count.index].id
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
  subnet_id         = aws_subnet.public[0].id
  connectivity_type = "public"

  tags = {
    Name = "${local.project_prefix} NAT Gateway"
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.this["public"].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route" "private" {
  route_table_id         = aws_route_table.this["private"].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

resource "aws_security_group" "this" {
  for_each = {
    alb     = "${local.project_prefix}-ALB"
    service = "${local.project_prefix}-Service"
  }

  name   = each.value
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group_rule" "this" {
  for_each = {
    service_ingress = {
      source_security_group_id = aws_security_group.this["alb"].id
      cidr_blocks              = null
      from_port                = 1024
      to_port                  = 65535
      protocol                 = "tcp"
      type                     = "ingress"
      security_group_id        = aws_security_group.this["service"].id
    }
    service_egress = {
      source_security_group_id = null
      cidr_blocks              = ["0.0.0.0/0"]
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      type                     = "egress"
      security_group_id        = aws_security_group.this["service"].id
    }
    alb_ingress = {
      source_security_group_id = null
      cidr_blocks              = ["0.0.0.0/0"]
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      type                     = "ingress"
      security_group_id        = aws_security_group.this["alb"].id
    }
    alb_egress = {
      source_security_group_id = null
      cidr_blocks              = ["0.0.0.0/0"]
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      type                     = "egress"
      security_group_id        = aws_security_group.this["alb"].id
    }
  }

  security_group_id        = each.value.security_group_id
  type                     = each.value.type
  protocol                 = each.value.protocol
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  cidr_blocks              = each.value.cidr_blocks
  source_security_group_id = each.value.source_security_group_id
}