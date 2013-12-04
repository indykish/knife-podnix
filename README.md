# Knife Podnix [![Build Status](https://travis-ci.org/indykish/knife-podnix.png?branch=master)](https://travis-ci.org/Podnix/knife-Podnix) [![Coverage Status](https://coveralls.io/repos/Podnix/knife-Podnix/badge.png)](https://coveralls.io/r/Podnix/knife-podnix)

* https://github.com/indykish/knife-Podnix

## DESCRIPTION:

This is a knife plugin to create, bootstrap and manage servers on the Podnix IaaS.

## INSTALLATION:

    gem install knife-podnix

If building the nokogiri C extension fails have a look at this wiki page: [Nokogiri-installation](https://github.com/Podnix/knife-Podnix/wiki/Nokogiri-installation)


## CONFIGURATION:

You need to provide you Podnix username and password, either add them to your knife.rb

    podnix_apikey = 'YOUR APIKEY'

or store them in environment variables

    export PODNIX_APIKEU=YOURAPIKEY


## SUBCOMMANDS:

This plugin provides the following Knife subcommands. Specific command options can be found by invoking the subcommand with a ``--help`` flag

### knife Podnix server create

Provisions a new server and then perform a Chef bootstrap (using the SSH protocol). The goal of the bootstrap is to get Chef installed
on the target system so it can run Chef Client with a Chef Server.

During provisioning your public SSH key will be uploaded to the newly created server, thus you should make sure a public key exists at `~/.ssh/id_rsa.pub` or provide a different key via the `--public-key-file` option.

The following knife-Podnix options are required:

    -D DATACENTER_NAME,              The datacenter where the server will be created
        --data-center
        --name SERVER_NAME           name for the newly created Server

These knife-Podnix options are optional:

        --cpus CPUS                  Amount of CPUs of the new Server
        --ram RAM                    Amount of Memory in MB of the new Server
        --hdd-size GB                Size of storage in GB
    -i, --image-name IMAGE_NAME      The image name which will be used to create the initial server 'template',
                                       default is 'Ubuntu-12.04-LTS-server-amd64-06.21.13.img'
    -S, --snaphot-name SNAPSHOT_NAME The snapshot name which will be used to create the server
                                       (can not be used with the image-name option)

    -k PUBLIC_KEY_FILE,              The SSH public key file to be added to the authorized_keys of the given user,
        --public-key-file              default is '~/.ssh/id_rsa.pub'

    -x, --ssh-user USERNAME          The ssh username

The following are optional options provided by knife:

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


### knife Podnix server list

Outputs a list of all servers.

### knife Podnix image list

Outputs a list of all images.

### knife Podnix server delete

Deletes the server running on podnix.

The following knife-Podnix options are required:

        --name SNAPSHOT_NAME         name for the newly created snapshot
        --server-id server_id        The server of which the snapshot will be taken

These knife-Podnix options are optional:

        --description description    description for the snapshot


## EXAMPLE

First you need an existing DataCenter, you can create it via the [DCD](https://my.Podnix.com/dashboard/dcd/) or just use the Podnix command which got installed via the [Podnix](https://github.com/dsander/Podnix) gem which is a dependency of knife-Podnix:

    Podnix data_center create name=demo

You are now set up to create a new server:

    knife Podnix server create --data-center demo --name test --ram 512 --cpus 1



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