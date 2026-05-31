# Harden-Linux

## Hardening
### Minimal level recommendations
- [ ] R30 - Removing the unused user accounts
- [ ] R31 - User password strength
- [ ] R53 - Avoiding files or directories without a known user or group
- [ ] R54 - Setting the sticky bit on the writable directories
- [ ] R56 - Avoiding using executables with setuid and setgid rights
- [ ] R58 - Installing only strictly necessary packages
- [ ] R59 - Using only official package repositories
- [ ] R61 - Updating regularly the system
- [ ] R62 - Disabling the non-necessary services
- [ ] R68 - Protecting the stored passwords
- [ ] R80 - Minimizing the attack surface of network services

### Intermediary level recommendations
- [ ] R2 - Configuring the BIOS/UEFI
- [ ] R3 - Activating the UEFI secure boot
- [ ] R5 - Configuring a password on the bootloader
- [ ] R8 - Configuring the memory options
- [ ] R9 - Configuring the kernel options
- [ ] R11 - Configuration option of the Yama LSM
- [ ] R12 - IPv4 configuration options
- [ ] R13 - Disabling IPv6
- [ ] R14 - File system configuration options
- [ ] R28 - Typical partitioning
- [ ] R32 - Configuring a timeout on local user sessions
- [ ] R33 - Ensuring the imputability of administration actions
- [ ] R34 - Disabling the service accounts
- [ ] R35 - Uniqueness and exclusivity of service accounts
- [ ] R39 - Sudo configuration guidelines
- [ ] R40 - Using unprivileged users as target for sudo commands
- [ ] R42 - Banishing the negations in sudo policies
- [ ] R43 - Defining the arguments in sudo specifications
- [ ] R44 - Editing files securely with sudo
- [ ] R50 - Limiting the rights to access sensitive files and directories
- [ ] R52 - Securing access for named sockets and pipes
- [ ] R55 - Dedicating temporary directories to users
- [ ] R63 - Disabling non-essential features of service
- [ ] R67 - Secure remote authentication with PAM
- [ ] R69 - Securing access to remote user databases
- [ ] R70 - Separating the system accounts and directory administrator
- [ ] R74 - Hardening the local messaging service
- [ ] R75 - Configuring aliases for service accounts
- [ ] R79 - Hardening and monitoring the exposed services

### Enhanced level recommendations
- [ ] R1 - Choosing and configuring the hardware
- [x] R7 - Activating the IOMMU
- [ ] R10 - Disabling kernel modules loading
- [ ] R29 - Access restrictions on /boot
- [ ] R36 - Changing the default value of UMASK
- [ ] R37 - Using Mandatory Access Control features
- [ ] R38 - Creating a group dedicated to the use of sudo
- [ ] R41 - Limiting the number of commands requiring the use of the EXEC directive
- [ ] R45 - Activating AppArmor security profiles
- [ ] R51 - Changing the secrets and access rights as soon as possible
- [ ] R57 - Avoiding using executables with setuid root and setgid root rights
- [ ] R60 - Using hardened package repositories
- [ ] R64 - Configuring the privileges of the services
- [ ] R65 - Partitioning the services
- [ ] R71 - Implementing a logging system
- [ ] R72 - Implementing dedicated service activity journals
- [ ] R73 - Logging the system activity with auditd
- [ ] R78 - Partitioning the network services

### High level recommendations
- [ ] R4 - Replacing of preloaded keys
- [ ] R6 - Protecting the kernel command line parameters and the initramfs
- [ ] R15 - Compile options for memory management
- [ ] R16 - Compile options for kernel data structures
- [ ] R17 - Compile options for the memory allocator
- [ ] R18 - Compile options for the management of kernel modules
- [ ] R19 - Compile options for abnormal situations
- [ ] R20 - Compile options for kernel security functions
- [ ] R21 - Compile options for the compiler plugins
- [ ] R22 - Compile options of the IP stack
- [ ] R23 - Compile options for various kernel behaviors
- [ ] R24 - Compile options for 32 bit architectures
- [ ] R25 - Compile options for x86_64 bit architectures
- [ ] R26 - Compile options for ARM architectures
- [ ] R27 - Compile options for ARM 64 bit architectures
- [ ] R46 - Activating SELinux with the targeted policy
- [ ] R47 - Containing the unprivileged interactive users
- [ ] R48 - Setting up the SELinux variables
- [ ] R49 - Uninstalling SELinux Policy Debugging Tools
- [ ] R66 - Hardening the partitioning components
- [ ] R76 - Sealing and checking files integrity
- [ ] R77 - Protecting the sealing database