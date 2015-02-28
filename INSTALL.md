


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

```
install latest version from here : http://www.vagrantup.com/downloads.html
```

### 3) Ansible (latest tested version : 1.5.4)
```
  sudo easy_install pip
  sudo add-apt-repository ppa:rquillo/ansible
  sudo apt-get update
  sudo apt-get install ansible
```


## Création d'un environement "local" de DEV

Cloner le repo :

```
git clone git@bitbucket.org:jflucier/crispycrispr.git
 
cd crispycrispr

```

Créer la VM :


```
vagrant up
```


Au besoin exécuter le "playbook" de provisioning :

```
vagrant provision
```

Pour zapper la VM et repartir à zéro : 

```
vagrant destroy
```


