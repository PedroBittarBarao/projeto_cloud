resource "aws_key_pair" "key_pair" {
  key_name   = "my-key-pair"
  public_key = file("./id_mykey.pub")
}

resource "aws_launch_template" "launch_template" {
  name_prefix                 = "my-launch-template"
  image_id                    = var.ami_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.key_pair.key_name
  user_data = base64encode(templatefile("user_data.tftpl", {db_host=aws_db_instance.rds_instance.address, db_name = var.db_name, db_username = var.db_username, db_password = var.db_password}))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "my-launch-template"
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    subnet_id                   = module.vpc.public_subnets[0]
    security_groups             = [aws_security_group.ec2_sg.id]
  }
}

resource "aws_autoscaling_group" "asg" {
  name                 = "my-asg"
  desired_capacity     = 2
  min_size             = 2
  max_size             = 6
  vpc_zone_identifier  = module.vpc.public_subnets
  target_group_arns    = [aws_alb_target_group.alb_tg.arn]

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_policy" "scale_up_policy" {
  name                   = "my-scale-up-policy"
  scaling_adjustment     = 1
  adjustment_type        = var.adjustment_type # ChangeInCapacity
  cooldown               = var.cooldown # 5 minutes
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_autoscaling_policy" "scale_down_policy" {
  name                   = "my-scale-down-policy"
  scaling_adjustment     = -1
  adjustment_type        = var.adjustment_type # ChangeInCapacity
  cooldown               = var.cooldown # 5 minutes
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {
  alarm_name          = "my-high-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = var.metric_name
  namespace           = var.namespace
  period              = var.period
  statistic           = var.statistic
  threshold           = 70
  alarm_description   = "This metric monitors ec2 high cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_up_policy.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}

resource "aws_cloudwatch_metric_alarm" "low_cpu_alarm" {
  alarm_name          = "my-low-cpu-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = var.metric_name
  namespace           = var.namespace
  period              = var.period
  statistic           = var.statistic
  threshold           = 20
  alarm_description   = "This metric monitors ec2 low cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_down_policy.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.asg.name
  lb_target_group_arn   = aws_alb_target_group.alb_tg.arn
}
