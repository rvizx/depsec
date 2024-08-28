
# DepSec - Automated Software Dependency Security Analysis Tool
DepSec - Automated Software Dependency Security Analysis Tool (DependencyCheck Wrapper)

<p align="center">
  <img src="https://www.zyenra.com/img/depsec-logo.png?raw=true" alt="alt text" width="420" />
</p>


# Introduction

The DepSec project is a **Automated Software Dependency Security Analysis tool**, the tool's core functionality is completely based on the DependencyCheck project. The DepSec application contains additional features and also it's developed to automate the dependency security analysis process using `cron`s. 

Main Functions and Features:
- `DepSec` installation with `DependencyCheck`.
- `DepSec` configuration file generation.
- Automated dependency installation for the project. (`npm` , `yarn` and `composer`)
- System packages and `DependencyCheck` Update.
- Scan and generate a report using `DependencyCheck`.
- Automatically email the report.
- ..and more

### Credits 

This project is completely based on the `DependencyCheck` project and `depsec` is a simple wrapper over the `DependencyCheck` application to automate it's process and  it also include some additional features. 

DependencyCheck : https://github.com/jeremylong/DependencyCheck
  


# Installation 

You can execute the following to install the `depsec` on your system.

```bash 
git clone https://github.com/rvizx/depsec
cd depsec
chmod +x depsec.sh
./depsec.sh --install 
```

**Note:** Currently the installation is configured only for **debian based** systems, `depsec` still can be used by installing followings manually based on your operating system. 

### Pre-requisites Installation

The following set of dependencies will be installed before the `DependencyCheck` installation. Currently the installation is configured only for **debian based** systems. 

**Note:** `depsec` still can be used by installing followings manually based on your operating system. 

```
git wget unzip curl maven nodejs npm composer yarn
```

**Note**: The current pre-requisites are configured based on the specific project `depsec` was initially planned to execute therefore it might not contain all the dependencies that might required by some other projects. 


### Installation and Setting-up DependencyCheck 

This will  automatically download  the latest version of the `DependencyCheck` compiled version and it will setup the binary in the `~/.local/share/dependency-check/` directory. 

exact location of the `DependencyCheck` binary would be:
`~/.local/share/dependency-check/bin/./dependency-check.sh`



# Configuration

### Configuring DepSec

1. Get a `NVD` API key from here - https://nvd.nist.gov/developers/request-an-api-key
2. Create a `MailTrap` Account and get the `MailTrap` API key - https://mailtrap.io/

Note: `depsec` is expected to be executed on a `bash` environment. (Mainly because it's configurations are based on the `environment varialbes` set through this. You can manually configure if you're using another environment)


```bash
./depsec.sh --config
```

the application will ask for you to above mentioned `api-key`s  it's format should be as follows 

| NVD API Key                        | MAILTRAP API  Key                 |
| ---------------------------------- | --------------------------------- |
| c3XXXXX-XXXX-XXXX-XXXX-XXXXXXXXXp0 | api:9aXXXXXXXXXXXXXXXXXXXXXXXXXX9 |


### Configuring Automation 

```bash
crontab -e 
```

For the automation, it's necessary to setup a `cron` job in the system. 

```
* * * * * /path/to/depsec.sh --scan
- - - - -
| | | | |
| | | | +----- Day of week (0 - 7) (Sunday is both 0 and 7)
| | | +------- Month (1 - 12)
| | +--------- Day of month (1 - 31)
| +----------- Hour (0 - 23)
+------------- Minute (0 - 59)

```


Example:
To set up a cron job to execute every Monday at 9:30 AM
```
30 9 * * 1 /path/to/depsec.sh --scan
```


# Scanning 

```bash
./depsec.sh --scan
```

The above command can be executed to scan the project folder. This will execute the `DependencyCheck` on the specified project folder during the `depsec --configure` .  After that the report will be generated at the `/tmp` directory as the `depsec-report.html`.  Later it will be compressed to a `.zip` file for emailing purposes. After that process the report and the compressed folder will be deleted from the `/tmp` directory for security reasons. 

### Changing the Project Folder 

If you want to change the `project-folder` that's need to scan, you can either execute the `--config` again (not recommended).  The following is the recommended way of reconfiguration. 

- Upadte the `.env` file's `DEPSEC_PROJECT` config.

```bash
cd /path/to/depsec/
nano .env 
```

edit the line with `DEPSEC_PROJECT` and configure a new project folder 

```bash
DEPSEC_PROJECT="/opt/new-project"
```


# Updating  


```bash 
./depsec.sh --update 
```


The above command can be executed to update the `depsec`, this will basically update the system dependencies that were previously installed as pre-requisites and also this will update the `DependencyCheck` binary to the latest version.



# Uninstall 

```bash
./depsec --uninstall 
```

By executing the above command it's possible to remove `depsec`  from your system. This will remove the `DependencyChek` binary downloaded to the `~/.local/share/dependency-check/` location and this will also remove the  cloned `depsec`  directory including the `.env`
