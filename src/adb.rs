use anyhow::{Result, anyhow};
use regex::Regex;
use std::process::{Command, Stdio};

#[derive(Debug, Clone)]
pub struct AdbCommand {
    adb_path: String,
}

impl Default for AdbCommand {
    fn default() -> Self {
        Self {
            adb_path: "adb".to_string(),
        }
    }
}

impl AdbCommand {
    pub fn get_path(&self) -> String {
        self.adb_path.clone()
    }

    // 检查ADB是否可用
    fn check_adb_available(&self) -> Result<()> {
        let output = Command::new(&self.adb_path)
            .arg("version")
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .output()?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            return Err(anyhow!("ADB not available: {}", stderr));
        }

        Ok(())
    }

    // 执行ADB shell命令
    fn execute_shell_command(&self, device_id: &str, command: &str) -> Result<String> {
        self.check_adb_available()?;
        
        let mut cmd = Command::new(&self.adb_path);
        if !device_id.is_empty() {
            cmd.arg("-s").arg(device_id);
        }
        
        let output = cmd
            .arg("shell")
            .arg(command)
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .output()?;

        let stdout = String::from_utf8_lossy(&output.stdout).to_string();
        let stderr = String::from_utf8_lossy(&output.stderr).to_string();

        if !output.status.success() {
            return Err(anyhow!(
                "ADB command failed: {}. Error: {}",
                command,
                stderr.trim()
            ));
        }

        if stdout.trim().is_empty() && !stderr.trim().is_empty() {
            return Err(anyhow!("Command produced no output: {}", stderr.trim()));
        }

        Ok(stdout)
    }

    // 执行普通ADB命令
    fn execute_command(&self, device_id: &str, args: &[&str]) -> Result<String> {
        self.check_adb_available()?;
        
        let mut cmd = Command::new(&self.adb_path);
        if !device_id.is_empty() {
            cmd.arg("-s").arg(device_id);
        }
        
        let output = cmd
            .args(args)
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .output()?;

        let stdout = String::from_utf8_lossy(&output.stdout).to_string();
        let stderr = String::from_utf8_lossy(&output.stderr).to_string();

        if !output.status.success() {
            return Err(anyhow!(
                "ADB command failed: {}. Error: {}",
                args.join(" "),
                stderr.trim()
            ));
        }

        if stdout.trim().is_empty() && !stderr.trim().is_empty() {
            return Err(anyhow!("Command produced no output: {}", stderr.trim()));
        }

        Ok(stdout)
    }

    // 获取当前活动
    pub fn get_current_activity(&self, device_id: &str) -> Result<(String, String)> {
        // 如果是local设备ID，获取唯一连接的设备
        let effective_device_id = if device_id == "local" {
            let devices = self.get_connected_devices()?;
            if devices.is_empty() {
                return Err(anyhow!("No devices connected"));
            }
            if devices.len() > 1 {
                return Err(anyhow!("Multiple devices connected, please specify a device ID"));
            }
            devices[0].clone()
        } else {
            device_id.to_string()
        };

        if !self.check_device_connected(&effective_device_id) {
            return Err(anyhow!("Device not connected: {}", effective_device_id));
        }

        let output = self.execute_shell_command(&effective_device_id, "am stack list")?;
        println!("Raw output: {}", output);  // 添加调试日志
        
        if !output.trim().is_empty() {
            return self.parse_activity_output(&output);
        }
        
        Err(anyhow!("No visible activity found"))
    }

    fn parse_activity_output(&self, output: &str) -> Result<(String, String)> {
        println!("Parsing output: {}", output);  // 添加调试日志
        
        let re = Regex::new(r"topActivity=ComponentInfo\{([^/]+)/([^}]+)\}")?;
        
        if let Some(captures) = re.captures(output) {
            if captures.len() >= 3 {
                let package_name = captures.get(1).unwrap().as_str().to_string();
                let mut activity_name = captures.get(2).unwrap().as_str().to_string();
                
                // 处理activity名字，使其变为相对路径
                if activity_name.starts_with(&package_name) {
                    activity_name = activity_name[package_name.len()..].to_string();
                    if !activity_name.starts_with('.') {
                        activity_name = format!(".{}", activity_name);
                    }
                } else if !activity_name.starts_with('.') {
                    activity_name = format!(".{}", activity_name);
                }
                
                println!("Parsed: package={}, activity={}", package_name, activity_name);  // 添加调试日志
                return Ok((package_name, activity_name));
            }
        }

        Err(anyhow!("Failed to parse activity info from: {}", output))
    }

    // 检查设备连接状态
    pub fn check_device_connected(&self, device_id: &str) -> bool {
        match self.execute_command("", &["devices"]) {
            Ok(output) => {
                let devices = output.lines()
                    .skip(1)  // 跳过标题行
                    .filter(|line| !line.trim().is_empty())
                    .collect::<Vec<_>>();
                
                if device_id.is_empty() {
                    // 如果没有指定设备ID，只要有任何设备连接就返回true
                    !devices.is_empty()
                } else {
                    // 否则检查特定设备
                    devices.iter().any(|line| line.starts_with(device_id))
                }
            }
            Err(_) => false,
        }
    }

    // 获取所有已连接设备
    pub fn get_connected_devices(&self) -> Result<Vec<String>> {
        let output = self.execute_command("", &["devices"])?;
        
        Ok(output.lines()
            .skip(1)  // 跳过第一行（标题行）
            .filter(|line| !line.trim().is_empty())
            .map(|line| line.split_whitespace().next().unwrap_or("").to_string())
            .filter(|device_id| !device_id.is_empty())
            .collect())
    }
} 