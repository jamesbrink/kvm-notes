# Linux KVM/Virsh Notes

This is just a dumping ground for some Linux KVM notes and scripts for later reference.  


## Creating guest instances


### Debian 9
To create a Debian 9 instance connected to virtual bridge. 

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
    --extra-args 'console=ttyS0,115200n8 serial'
```


### Debian 10

```shell
virt-install \
    --name debian10 \
    --ram 4096 \
    --disk path=./debian10.qcow2,size=20 \
    --vcpus 2 \
    --os-type linux \
    --os-variant debiantesting \
    --network default \
    --console pty,target_type=serial \
    --graphics vnc,listen=0.0.0.0 --noautoconsole \
    --location 'http://ftp.nl.debian.org/debian/dists/buster/main/installer-amd64/' \
    --extra-args 'console=ttyS0,115200n8 serial'
```


Installing Docker on Debian/Ubuntu:  
```shell
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    software-properties-common; \
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -; \
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -; \
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"; \
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"; \
apt-get update; \
apt-get install -y docker-ce docker-ce-cli containerd.io;
```


### Ubuntu 18.04
Ubuntu 18.04 LTS with 4 vcpu and 8GB of mem

```shell
virt-install \
    --name ubuntu18.04 \
    --ram 8192 \
    --disk path=./ubuntu18.04.qcow2,size=40 \
    --vcpus 4 \
    --os-type linux \
    --os-variant ubuntu18.04 \
    --network default \
    --console pty,target_type=serial \
    --graphics vnc,listen=0.0.0.0 --noautoconsole \
    --location 'http://archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/' \
    --extra-args 'console=ttyS0,115200n8 serial'
```

### Alpine Linux

ISO install

```shell
wget http://dl-cdn.alpinelinux.org/alpine/v3.10/releases/x86_64/alpine-virt-3.10.1-x86_64.iso
```

```shell
virt-install \
    --name alpine \
    --ram 512 \
    --disk path=./alpine.qcow2,size=2 \
    --vcpus 1 \
    --os-type linux \
    --os-variant alpinelinux3.8 \
    --network default \
    --console pty,target_type=serial \
    --graphics vnc,listen=0.0.0.0 --noautoconsole \
    --cdrom alpine-virt-3.10.1-x86_64.iso
```

netboot method (not fully working)

```shell
wget http://dl-cdn.alpinelinux.org/alpine/v3.10/releases/x86_64/alpine-netboot-3.10.1-x86_64.tar.gz
mkdir -p alpine
tar xfv alpine-netboot-3.10.1-x86_64.tar.gz -C alpine
```

 TODO - add the modloop line `modloop=url`

```shell
virt-install \
    --name alpine \
    --ram 512 \
    --disk path=./alpine.qcow2,size=2 \
    --vcpus 1 \
    --os-type linux \
    --os-variant alpinelinux3.8 \
    --network default \
    --console pty,target_type=serial \
    --graphics vnc,listen=0.0.0.0 --noautoconsole \
    --boot kernel=alpine/boot/vmlinuz-vanilla,initrd=alpine/boot/initramfs-vanilla,kernel_args="console=ttyS0 ip=dhcp alpine_repo=http://dl-cdn.alpinelinux.org/alpine/v3.10/main/ modules=loop,squashfs,sd-mod,usb-storage"
```



### CentOS 7

**This boot tends to hang for a few moments before launching installer. I believe this is due to low entropy**

```shell
virt-install \
    --name centos7 \
    --ram 4096 \
    --disk path=./centos7.qcow2,size=40 \
    --vcpus 2 \
    --os-type linux \
    --os-variant centos7.0 \
    --network default \
    --console pty,target_type=serial \
    --graphics none \
    --location 'https://mirrors.mit.edu/centos/7/os/x86_64/' \
    --extra-args 'console=ttyS0,115200n8 serial'
```


### Windows 10

install virtio-win (`yay -S virtio-win`)
after install be sure to install / update drivers from virtio
and install spice client from website.

```shell
virt-install \
    --name=windows10 \
    --ram=8192 \
    --cpu=host \
    --vcpus=2 \
    --os-type=windows \
    --os-variant=win8.1 \
    --network=default \
    --graphics spice,listen=0.0.0.0 \
    --disk windows10.qcow2,size=60 \
    --disk /usr/share/virtio/virtio-win.iso,device=cdrom \
    --cdrom windows10.iso
```

You can remove the `network` argument to use the default built in NAT.  

Be sure to get a terminal after install and run the following if you want to continue using tty console. *This does not cover grub support*

```shell
chroot /target/
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
sudo virsh net-destroy default
sudo virsh net-undefine default
sudo virsh net-define --file virsh-default-network.xml
sudo virsh net-start default
sudo virsh net-autostart default
```

```shell
virsh net-destroy default
virsh net-undefine default
virsh net-define --file virsh-default-network.xml
virsh net-start default
virsh net-autostart default
```

## References

* [libvirt networking handbook](https://jamielinux.com/docs/libvirt-networking-handbook/)
* [virt-install one liners](https://raymii.org/s/articles/virt-install_introduction_and_copy_paste_distro_install_commands.html)