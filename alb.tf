resource "aws_alb" "alb" {
  name                             = "my-alb"
  internal                         = false
  load_balancer_type               = "application"
  security_groups                  = [aws_security_group.alb_sg.id]
  subnets                          = module.vpc.public_subnets
  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "my-alb"
  }
}

resource "aws_alb_target_group" "alb_tg" {
  name     = "my-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
  
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 20
    interval            = 60
    path                = "/docs"
  }

  tags = {
    Name = "my-alb-tg"
  }
}

resource "aws_alb_listener" "alb_listener" {
  load_balancer_arn = aws_alb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.alb_tg.arn
    type             = "forward"
  }
}
