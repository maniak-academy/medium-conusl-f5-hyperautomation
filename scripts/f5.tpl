#!/bin/bash
# Send output to log file and serial console
mkdir -p  /var/log/cloud /config/cloud /var/config/rest/downloads
LOG_FILE=/var/log/cloud/startup-script.log
[[ ! -f $LOG_FILE ]] && touch $LOG_FILE || { echo "Run Only Once. Exiting"; exit; }
npipe=/tmp/$$.tmp
trap "rm -f $npipe" EXIT
mknod $npipe p
tee <$npipe -a $LOG_FILE /dev/ttyS0 &
exec 1>&-
exec 1>$npipe
exec 2>&1

cat << 'EOF' > /config/cloud/runtime-init-conf.yaml
---
runtime_parameters: []
pre_onboard_enabled:
  - name: provision_rest
    type: inline
    commands:
      - /usr/bin/setdb provision.extramb 500
      - /usr/bin/setdb restjavad.useextramb true
      - /usr/bin/setdb setup.run false
extension_packages:
  install_operations:
    - extensionType: do
      extensionVersion: 1.29.0
      extensionUrl: file:///var/config/rest/downloads/f5-declarative-onboarding-1.29.0-8.noarch.rpm
    - extensionType: as3
      extensionVersion: 3.36.0 
      extensionUrl: file:///var/config/rest/downloads/f5-appsvcs-3.36.0-6.noarch.rpm
    - extensionType: fast
      extensionVersion: 1.8.0
      extensionUrl: file:///var/config/rest/downloads/f5-appsvcs-templates-1.8.1-1.noarch.rpm
extension_services:
    service_operations:
    - extensionType: do
      type: url
      value: https://raw.githubusercontent.com/maniak-academy/f5-do-templates/main/do.tpl
post_onboard_enabled:
    - name: custom-config
      type: inline
      commands:
        - bash /config/custom-config.sh

EOF
cat << 'EOF' > /config/custom-config.sh
#!/bin/bash

source /usr/lib/bigstart/bigip-ready-functions
wait_bigip_ready

tmsh modify /auth user admin encrypted-password '${encrypted_password}'
tmsh modify auth user admin shell bash

tmsh modify sys global-settings gui-setup disabled
tmsh modify sys global-settings gui-security-banner-text "Configured via Cloud-Init!"

tmsh save sys config
sleep 60
bigstart restart restnoded
EOF

source /usr/lib/bigstart/bigip-ready-functions
wait_bigip_ready

for i in {1..30}; do
    curl -fv --retry 1 --connect-timeout 5 -L "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.36.0/f5-appsvcs-3.36.0-6.noarch.rpm" -o "/var/config/rest/downloads/f5-appsvcs-3.36.0-6.noarch.rpm" && break || sleep 10
done

for i in {1..30}; do
    curl -fv --retry 1 --connect-timeout 5 -L "https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v1.4.1/dist/f5-bigip-runtime-init-1.4.1-1.gz.run" -o "/var/config/rest/downloads/f5-bigip-runtime-init-1.4.1-1.gz.run" && break || sleep 10
done

for i in {1..30}; do
    curl -fv --retry 1 --connect-timeout 5 -L "https://github.com/F5Networks/f5-appsvcs-templates/releases/download/v1.8.1/f5-appsvcs-templates-1.8.1-1.noarch.rpm" -o "/var/config/rest/downloads/f5-appsvcs-templates-1.8.1-1.noarch.rpm" && break || sleep 10
done

for i in {1..30}; do
    curl -fv --retry 1 --connect-timeout 5 -L "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.29.0/f5-declarative-onboarding-1.29.0-8.noarch.rpm" -o "/var/config/rest/downloads/f5-declarative-onboarding-1.29.0-8.noarch.rpm" && break || sleep 10
done


bash /var/config/rest/downloads/f5-bigip-runtime-init-1.4.1-1.gz.run -- '--cloud aws --skip-verify --skip-toolchain-metadata-sync'

f5-bigip-runtime-init --config-file /config/cloud/runtime-init-conf.yaml
