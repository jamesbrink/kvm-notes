# Linux KVM/Virsh Notes

This is just a dumping ground for some Linux KVM notes and scripts for later reference.  


## Creating guest instances

To create a Debian 9 instance. 

```shell
virt-install \
    --name debian9 \
    --ram 1024 \
    --disk path=./debian8.qcow2,size=9 \
    --vcpus 1 \
    --os-type linux \
    --os-variant debian8 \
    --network bridge=virbr10 \
    --console pty,target_type=serial \
    --graphics vnc,listen=0.0.0.0 --noautoconsole \
    --location 'http://ftp.nl.debian.org/debian/dists/stretch/main/installer-amd64/' \
    --extra-args 'console=ttyS0,115200n8 serial' \
```


Ubuntu 18.04 LTS with 4 vcpu and 8GB of mem

```shell
virt-install \
    --name ubuntu18.04 \
    --ram 8192 \
    --disk path=./ubuntu18.04.qcow2,size=40 \
    --vcpus 4 \
    --os-type linux \
    --os-variant ubuntu18.04 \
    --network bridge=virbr10 \
    --console pty,target_type=serial \
    --graphics vnc,listen=0.0.0.0 --noautoconsole \
    --location 'http://archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/' \
    --extra-args 'console=ttyS0,115200n8 serial' \
```

Windows 10

install virtio-win (`yay -S virtio-win`)

```shell
virt-install \
    --name=windows10 \
    --ram=8192 \
    --cpu=host \
    --vcpus=2 \
    --os-type=windows \
    --os-variant=win8.1 \
    --network=default \
    --graphics vnc,listen=0.0.0.0 \
    --disk windows10.qcow2,size=60,bus=virtio \
    --disk /usr/share/virtio/virtio-win.iso,device=cdrom,bus=ide \
    --cdrom windows10.iso
```

You can remove the `network` argument to use the default built in NAT.  

Be sure to get a terminal after install and run the following if you want to continue using tty console. *This does not cover grub support*

```shell
systemctl enable serial-getty@ttyS0.service
```

Adding vnc to an existing domain (guest)

```shell
virsh edit --domain debian9
```

```XML
<graphics type='vnc' port='-1' autoport='yes' listen='0.0.0.0'/>
```

## Create snaphosts with virsh

```shell
virsh snapshot-create-as --domain {VM-NAME} --name "{SNAPSHOT-NAME}"
```

## dnsmasq

Running dnsmasq in the foreground

```shell
sudo dnsmasq --conf-file=/var/lib/dnsmasq/virbr10/dnsmasq.conf -d
```

## Resetting virsh default network

To reset the virsh default network run the following

```shell
virsh net-define --file virsh-default-network.xml
virsh net-start default
virsh net-autostart default
```

## References

* [libvirt networking handbook](https://jamielinux.com/docs/libvirt-networking-handbook/)
* [virt-install one liners](https://raymii.org/s/articles/virt-install_introduction_and_copy_paste_distro_install_commands.html)