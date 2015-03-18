## Dépendances à installer sur le poste du dévelopeur

note: à part ces trois dépendances, tout le reste est installé sur les VM vagrant/virtualbox

### 1) Virtualbox (latest tested version : 4.3.12)

```
  sudo sh -c 'echo "deb http://download.virtualbox.org/virtualbox/debian saucy contrib" >> /etc/apt/sources.list'
  wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc -O- | sudo apt-key add -
  sudo apt-get update
  sudo apt-get install virtualbox-4.3
```

### 2) Vagrant (latest tested version : 1.5.1)


install latest version from here : http://www.vagrantup.com/downloads.html

```
sudo  dpkg -i <path vers le fichier .deb)

  # ensuite :
  vagrant plugin install vagrant-vbguest
```

### 3) Ansible (latest tested version : 1.8.2)
```
    $ sudo apt-get install software-properties-common
    $ sudo apt-add-repository ppa:ansible/ansible
    $ sudo apt-get update
    $ sudo apt-get install ansible
```


## Création d'un environement "local" de DEV

Cloner le repo :

```
git clone <<username>>@bitbucket.org:jflucier/crispycrispr.git
 
cd crispycrispr

```

Créer la VM :


```
vagrant up
```

Une fois terminé un site devrait apparaître au : http://192.168.78.29
(une adresse locale définie dans ./Vagrantfile


Au besoin exécuter le "playbook" de provisioning :

```
vagrant provision
```

Pour zapper la VM et repartir à zéro : 

```
vagrant destroy
```


# Pour Éditer le portail en "local", et voir les changements "live"


```
  vagrant ssh
  cd /vagrant/portal
  sudo jekyll build --watch --force_polling

```

jekyll "surveille" les modifs aux fichiers dans ./portal, et regénère le site après chaques modifs


# Déployer en prod

doc à venir...