Configuration DscPrj01 {
    Node 'localhost' {
        WindowsFeature TelnetClient {
            Ensure = "Absent"
            Name   = "Telnet-Client"
        }
        Service PrintSpooler {
            Name = 'spooler'
            StartupType = "Disabled"
            State = "Stopped"
        }
        Environment EnvironmentExample {
            Ensure = "Present"
            Name = "LicenseServerName"
            Value = "LicenseServer02"
        }
    }
}