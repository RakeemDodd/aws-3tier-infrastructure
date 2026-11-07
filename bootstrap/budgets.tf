data "aws_caller_identity" "current" {}

import {
  to = aws_budgets_budget.monthly_cost_cap
  id = "${data.aws_caller_identity.current.account_id}:monthly-cost-cap"
}

import {
  to = aws_budgets_budget.daily_cost_tripwire
  id = "${data.aws_caller_identity.current.account_id}:daily-cost-tripwire"
}

resource "aws_budgets_budget" "monthly_cost_cap" {
  name         = "monthly-cost-cap"
  budget_type  = "COST"
  limit_amount = "25.0"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 10
    threshold_type             = "ABSOLUTE_VALUE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 20
    threshold_type             = "ABSOLUTE_VALUE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 25
    threshold_type             = "ABSOLUTE_VALUE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 25
    threshold_type             = "ABSOLUTE_VALUE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.budget_alert_email]
  }

  lifecycle {
    prevent_destroy = true
    # AWS sets metrics by default; this code doesn't manage it, so leave it as is
    ignore_changes = [metrics]
  }
}

resource "aws_budgets_budget" "daily_cost_tripwire" {
  name         = "daily-cost-tripwire"
  budget_type  = "COST"
  limit_amount = "2.0"
  limit_unit   = "USD"
  time_unit    = "DAILY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 2
    threshold_type             = "ABSOLUTE_VALUE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_alert_email]
  }

  lifecycle {
    prevent_destroy = true
    # AWS sets metrics by default; this code doesn't manage it, so leave it as is
    ignore_changes = [metrics]
  }
}
