# Knife Podnix [![Build Status](https://travis-ci.org/indykish/knife-podnix.png?branch=master)](https://travis-ci.org/Podnix/knife-Podnix) [![Coverage Status](https://coveralls.io/repos/Podnix/knife-Podnix/badge.png)](https://coveralls.io/r/Podnix/knife-podnix)

* https://github.com/indykish/knife-Podnix

## DESCRIPTION:

This is a knife plugin to create, bootstrap and manage servers on the Podnix IaaS.

## INSTALLATION:

    gem install knife-podnix

If building the nokogiri C extension fails have a look at this wiki page: [Nokogiri-installation](https://github.com/Podnix/knife-Podnix/wiki/Nokogiri-installation)


## CONFIGURATION:

You need to provide your Podnix API_KEY, either via options(--podnix_api_key 'PODNIX_API_KEY') or add them to your knife.rb

    knife[:podnix_api_key] = "PODNIX_API_KEY"

or store them in environment variables

    export PODNIX_API_KEY=YOURAPIKEY


## SUBCOMMANDS:

This plugin provides the following Knife subcommands. Specific command options can be found by invoking the subcommand with a ``--help`` flag.

### knife Podnix server create

Provisions a new server and then perform a Chef bootstrap (using the SSH protocol). The goal of the bootstrap is to get Chef installed
on the target system so it can run Chef Client with a Chef Server.

During provisioning your password will be uploaded to the newly created server, thus you can ssh your server with that password.

The following knife-Podnix options are required:

    -N, --name SERVER_NAME           name for the newly created Server.
    -f, --flavor                     Specify the model of your server. This will define the amount of vCores 
                                     and RAM that your server will get. MODEL IN PODNIX(by vcore size) `1, 2, 4, 8`.
                                     RAM is double the size of VCORE.
    -P, --password PASSWORD          Specifies the root password (on Linux) or administrator password (on Windows).
                                     Must contain at least 9 chars and include a lower case char, an upper case char and a number.
                                     eg:-`Secret123`.
    -I, --image IMAGE_ID             Specify the image to base your server on. This will define operating system 
                                     and pre-installed software. Fot more `knife podnix image list`. eg:- `37`for Ubuntu 13.04 (64bit).


The following are optional options provided by knife:
        --storage SIZE               Specify the size (in GB) of the system drive. Valid size is 10-250. Default is 10.
        --ssd 1                      If this parameter is set to 1, the system drive will be located on a SSD drive.
        --[no-]bootstrap             Bootstrap the server with knife bootstrap


    -N, --node-name NAME             The Chef node name for your new node default is the name of the server.
    -s, --server-url URL             Chef Server URL
        --key KEY                    API Client Key
        --[no-]color                 Use colored output, defaults to enabled
    -c, --config CONFIG              The configuration file to use
        --defaults                   Accept default values for all questions
        --disable-editing            Do not open EDITOR, just accept the data as is
    -d, --distro DISTRO              Bootstrap a distro using a template; default is 'ubuntu12.04-gems'
    -e, --editor EDITOR              Set the editor to use for interactive commands
    -E, --environment ENVIRONMENT    Set the Chef environment
    -F, --format FORMAT              Which format to use for output
        --identity-file IDENTITY_FILE
                                     The SSH identity file used for authentication
        --print-after                Show the data after a destructive operation
    -r, --run-list RUN_LIST          Comma separated list of roles/recipes to apply
        --template-file TEMPLATE     Full path to location of template to use
    -V, --verbose                    More verbose output. Use twice for max verbosity
    -v, --version                    Show chef version
    -y, --yes                        Say yes to all prompts for confirmation
    -h, --help                       Show this message


### knife Podnix image list

Outputs a list of all images.

### knife Podnix server list

Outputs a list of all servers.

### knife Podnix server show SERVER_ID

Outputs the details of a  particular server.

### knife Podnix server start SERVER_ID

To start a server which is in stop stat. (Server which is created from UI, will be in stop stat)

### knife Podnix server stop SERVER_ID

To stop a server which is in started stat. (To delete a server, first it must be in stoped)

### knife Podnix server delete SERVER_ID

To delete a server which is in stoped stat. (Driver belongs to this server will `not` be deleted)

### knife podnix server create OPTIONS

Creats a server and a drive in podnix cloud.



## EXAMPLE

First you need an existing podnix cloud account, you can create it via the [UI console](https://cp.podnix.com/). 

You are now set up to create a new server:

    knife podnix server create -f 1 -P Secret123 -I 37 --storage 10 -r 'role[riak],recipe[redis]' -N POGO



# License

|                      |                                          |
|:---------------------|:-----------------------------------------|
| **Author:**          | Kishorekumar Neelamegam (<nkishore@megam.co.in>)
|                      | Thomas Alrin (<alrin@megam.co.in>)
| **Copyright:**       | Copyright (c) 2012-2013 Megam Systems.
| **License:**         | Apache License, Version 2.0

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
