#cloud-config
groups:
  - ubuntu: [root,sys]
  - cloud-users
users:
  - default
  - name: ${username}
    gecos: New Relic Candidate
    sudo: ALL=(ALL) NOPASSWD:ALL
    expiredate: ${pw_expiration}
    passwd: ${password}
  - name: tomcat
    system: true
    sudo: ALL=(ALL) NOPASSWD:ALL
package_update: true
package_upgrade: true
runcmd:
  - reboot
  