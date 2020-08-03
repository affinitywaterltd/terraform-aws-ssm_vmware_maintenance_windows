locals {
  week_offset = 0
}

#
#
# Update Window
#
#

resource "aws_ssm_maintenance_window" "default" {
  count             = var.weeks
  name              = var.weeks > 1 ? "${var.type}_week-${count.index + 1}_${var.day}_${var.hour}00" : "${var.type}_week-${var.week}_${var.day}_${var.hour}00"
  schedule          = var.weeks > 1 ? "cron(00 ${var.hour} ? 1/3 ${var.day}#${count.index + 1} *)" : "cron(00 ${var.hour} ? 1/3 ${var.day}#${var.week + local.week_offset} *)"
  duration          = var.mw_duration
  cutoff            = var.mw_cutoff
  schedule_timezone = "Europe/London"
}

resource "aws_ssm_maintenance_window_target" "default" {
  count         = var.weeks
  window_id     = element(aws_ssm_maintenance_window.default.*.id, count.index)
  name          = "default"
  description   = "default"
  resource_type = "INSTANCE"

  targets {
    key    = "tag:ssmMaintenanceWindow"
    values = [var.weeks > 1 ? "${var.type}_week-${count.index + 1}_${var.day}_${var.hour}00" : "${var.type}_week-${var.week}_${var.day}_${var.hour}00"]
  }
}

resource "aws_ssm_maintenance_window_task" "default_task_enable" {
  count            = var.weeks
  window_id        = element(aws_ssm_maintenance_window.default.*.id, count.index)
  name             = "reset_wsus"
  description      = "Reset Windows Update Service"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunPowerShellScript"
  priority         = 10
  service_role_arn = var.role
  max_concurrency  = var.mw_concurrency
  max_errors       = var.mw_error_rate

  targets {
    key    = "WindowTargetIds"
    values = [element(aws_ssm_maintenance_window_target.default.*.id, count.index)]
  }

  task_invocation_parameters {
    run_command_parameters {
      output_s3_bucket     = var.s3_bucket
      output_s3_key_prefix = var.weeks > 1 ? "${var.type}_week-${count.index + 1}_${var.day}_${var.hour}00/${var.account}-${var.environment}" : "${var.type}_week-${var.week}_${var.day}_${var.hour}00/${var.account}-${var.environment}"
      service_role_arn     = var.role
      timeout_seconds      = 300

      parameter {
        name   = "commands"
        values = ["Stop-Service -Name 'wuauserv'", "Remove-Item -Path 'C:\\Windows\\SoftwareDistribution' -Recurse", "Set-Service -Name 'wuauserv' -StartupType Manual", "Start-Service -Name 'wuauserv'"]
      }
      parameter {
        name   = "executionTimeout"
        values = ["300"]
      }
    }
  }
}

resource "aws_ssm_maintenance_window_task" "default_task_snapshot" {
  count            = var.weeks
  window_id        = element(aws_ssm_maintenance_window.default.*.id, count.index)
  name             = "take_vmware_snapshot"
  description      = "Take Snapshot of vmware server"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWL-TakeVMwareSnapshot"
  priority         = 20
  service_role_arn = var.role
  max_concurrency  = var.mw_concurrency
  max_errors       = var.mw_error_rate

  targets {
    key    = "WindowTargetIds"
    values = [element(aws_ssm_maintenance_window_target.default.*.id, count.index)]
  }

  task_invocation_parameters {
    run_command_parameters {
      output_s3_bucket     = var.s3_bucket
      output_s3_key_prefix = var.weeks > 1 ? "${var.type}_week-${count.index + 1}_${var.day}_${var.hour}00/${var.account}-${var.environment}" : "${var.type}_week-${var.week}_${var.day}_${var.hour}00/${var.account}-${var.environment}"
      service_role_arn     = var.role
      timeout_seconds      = 3600
    }
  }
}

resource "aws_ssm_maintenance_window_task" "default_copy_aws_update_tools" {
  count            = var.weeks
  window_id        = element(aws_ssm_maintenance_window.default.*.id, count.index)
  name             = "copy_aws_update_tools"
  description      = "Copy AWS Patching tools from local share"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunPowerShellScript"
  priority         = 25
  service_role_arn = var.role
  max_concurrency  = var.mw_concurrency
  max_errors       = var.mw_error_rate

  targets {
    key    = "WindowTargetIds"
    values = [element(aws_ssm_maintenance_window_target.default.*.id, count.index)]
  }

  task_invocation_parameters {
    run_command_parameters {
      output_s3_bucket     = var.s3_bucket
      output_s3_key_prefix = var.weeks > 1 ? "${var.type}_week-${count.index + 1}_${var.day}_${var.hour}00/${var.account}-${var.environment}" : "${var.type}_week-${var.week}_${var.day}_${var.hour}00/${var.account}-${var.environment}"
      service_role_arn     = var.role
      timeout_seconds      = 300

      parameter {
        name   = "commands"
        values = ["$remoteBase = '\\\\' + $(Get-WmiObject Win32_ComputerSystem).Domain + '\\NETLOGON\\SSM_Scripts\\'", "$zipFilename = 'AWSUpdateWindowsInstance_1_4_4_0_customised.zip'", "$moduleName = 'AWSUpdateWindowsInstance'", "$tempPath = $env:TEMP", "$moduleDirectory = Join-Path $tempPath -ChildPath $moduleName", "$moduleZipFilePath = Join-Path $tempPath -ChildPath $zipFilename", "$remoteFilePath = Join-Path $remoteBase -ChildPath $zipFilename", "Copy-Item -Path $remoteFilePath -Destination $moduleZipFilePath -Confirm:$false"]
      }
      parameter {
        name   = "executionTimeout"
        values = ["300"]
      }
    }
  }
}

resource "aws_ssm_maintenance_window_task" "default_task_updates" {
  count            = var.weeks
  window_id        = element(aws_ssm_maintenance_window.default.*.id, count.index)
  name             = "install_windows_updates"
  description      = "Install Windows Updates"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWL-InstallWindowsUpdates"
  priority         = 30
  service_role_arn = var.role
  max_concurrency  = var.mw_concurrency
  max_errors       = var.mw_error_rate

  targets {
    key    = "WindowTargetIds"
    values = [element(aws_ssm_maintenance_window_target.default.*.id, count.index)]
  }

  task_invocation_parameters {
    run_command_parameters {
      output_s3_bucket     = var.s3_bucket
      output_s3_key_prefix = var.weeks > 1 ? "${var.type}_week-${count.index + 1}_${var.day}_${var.hour}00/${var.account}-${var.environment}" : "${var.type}_week-${var.week}_${var.day}_${var.hour}00/${var.account}-${var.environment}"
      service_role_arn     = var.role
      timeout_seconds      = 10800

      parameter {
        name   = "Action"
        values = ["Install"]
      }
      parameter {
        name   = "AllowReboot"
        values = ["True"]
      }
      parameter {
        name   = "Categories"
        values = ["CriticalUpdates,DefinitionUpdates,FeaturePacks,Microsoft,SecurityUpdates,Tools,UpdateRollups,Updates"]
      }
      parameter {
        name   = "SeverityLevels"
        values = ["Critical,Important,Low,Moderate,Unspecified"]
      }
      parameter {
        name   = "PublishedDaysOld"
        values = ["7"]
      }
    }
  }
}

resource "aws_ssm_maintenance_window_task" "default_task_disble" {
  count            = var.weeks
  window_id        = element(aws_ssm_maintenance_window.default.*.id, count.index)
  name             = "disable_wsus"
  description      = "Reset Windows Update Service"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunPowerShellScript"
  priority         = 40
  service_role_arn = var.role
  max_concurrency  = var.mw_concurrency
  max_errors       = var.mw_error_rate

  targets {
    key    = "WindowTargetIds"
    values = [element(aws_ssm_maintenance_window_target.default.*.id, count.index)]
  }

  task_invocation_parameters {
    run_command_parameters {
      output_s3_bucket     = var.s3_bucket
      output_s3_key_prefix = var.weeks > 1 ? "${var.type}_week-${count.index + 1}_${var.day}_${var.hour}00/${var.account}-${var.environment}" : "${var.type}_week-${var.week}_${var.day}_${var.hour}00/${var.account}-${var.environment}"
      service_role_arn     = var.role
      timeout_seconds      = 300

      parameter {
        name   = "commands"
        values = ["Stop-Service -Name 'wuauserv'", "Set-Service -Name 'wuauserv' -StartupType Disabled"]
      }
      parameter {
        name   = "executionTimeout"
        values = ["300"]
      }
    }
  }
}

resource "aws_ssm_maintenance_window_task" "default_task_email_notification" {
  count            = var.weeks
  window_id        = element(aws_ssm_maintenance_window.default.*.id, count.index)
  name             = "ssm_email_notification"
  description      = "Send email notification"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWL-SSMEmailNotification"
  priority         = 50
  service_role_arn = var.role
  max_concurrency  = var.mw_concurrency
  max_errors       = var.mw_error_rate

  targets {
    key    = "WindowTargetIds"
    values = [element(aws_ssm_maintenance_window_target.default.*.id, count.index)]
  }

  task_invocation_parameters {
    run_command_parameters {
      output_s3_bucket     = var.s3_bucket
      output_s3_key_prefix = var.weeks > 1 ? "${var.type}_week-${count.index + 1}_${var.day}_${var.hour}00/${var.account}-${var.environment}" : "${var.type}_week-${var.week}_${var.day}_${var.hour}00/${var.account}-${var.environment}"
      service_role_arn     = var.role
      timeout_seconds      = 300
    }
  }
}

resource "aws_ssm_maintenance_window_task" "default_task_ssmagent" {
  count            = var.weeks
  window_id        = element(aws_ssm_maintenance_window.default.*.id, count.index)
  name             = "update_ssm_agent"
  description      = "Update SSM Agent"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-UpdateSSMAgent"
  priority         = 60
  service_role_arn = var.role
  max_concurrency  = var.mw_concurrency
  max_errors       = var.mw_error_rate

  targets {
    key    = "WindowTargetIds"
    values = [element(aws_ssm_maintenance_window_target.default.*.id, count.index)]
  }

  task_invocation_parameters {
    run_command_parameters {
      output_s3_bucket     = var.s3_bucket
      output_s3_key_prefix = var.weeks > 1 ? "${var.type}_week-${count.index + 1}_${var.day}_${var.hour}00/${var.account}-${var.environment}" : "${var.type}_week-${var.week}_${var.day}_${var.hour}00/${var.account}-${var.environment}"
      service_role_arn     = var.role
      timeout_seconds      = 300

      parameter {
        name   = "allowDowngrade"
        values = ["false"]
      }
    }
  }
}

