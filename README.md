# Ubiquity::LTS2

A library and utilities to interact with the EVault Long-Term Storage Service (LTS2).

## System Requirements
   
  - <a href="https://www.ruby-lang.org/en/installation/" target="_blank">Ruby 1.8.7 or Higher</a>
  - <a href="http://git-scm.com/book/en/Getting-Started-Installing-Git" target="_blank">Git</a> 
  - RubyGems
  - <a href="http://bundler.io/" target="_blank">Bundler</a>
    
## Prerequisites

  - An EVault Long-Term Storage Service (LTS2) Account

### CentOS 6.4 or higher

    yum install git
    yum install ruby-devel
    yum install rubygems
    gem install bundler

### Mac OS X
    
    gem install bundler
    
## Installation

    git clone https://github.com/XPlatform-Consulting/ubiquity-lts2.git
    cd ubiquity-lts2
    bundle update

## Setup

## Ubiquity LTS2 Upload Utility [bin/ubiquity_lts2_upload](./bin/ubiquity_lts2_upload)

An executable that facilitate the upload of files to LTS2

    Usage:
        ubiquity_lts2_upload -h | --help
        ubiquity_lts2_upload --username <username> --password <password> --file-to-upload <file_path> --container-name <container_name> 
    
    Options:
            --username USERNAME          The username to authenticate with.
            --password PASSWORD          The password to authenticate with.
            --container-name NAME        The name of the container to save the file to.
            --object-key KEY             The unique name to use when saving the file to the bucket.
            --file-to-upload PATH        The path of the file to upload.
            --metadata JSON              A JSON hash containing metadata to be set for the file.
        -h, --help                       Display this message.

#### Examples of Usage:

###### Accessing help.
  ubiquity_lts2_upload --help
  
###### Upload a file.
  ubiquity_lts2_upload --username \<username\> --password \<password\> --file-to-upload \<file_path\> --container-name <\container_name\> 


## Contributing

1. Fork it ( https://github.com/XPlatform-Consulting/ubiquity-lts2/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
