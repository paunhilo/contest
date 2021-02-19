#On initialise le projet
terraform {
    #Configuration du provider
  required_providers { 
      digitalocean = {
          source = "digitalocean/digitalocean"
          version = "2.4.0"
        }
      scaleway = {
          source = "scaleway/scaleway"
          version = "1.17.2"
      }
    }
    required_version = ">= 0.14"
}

#Initialisation du token de connexion digitalocean
provider "digitalocean" {
  token = "85f67e09b5191ba0fcaa082ca60406865564310e07a7ec79ea62e6ef0c91102d"
}

#Provider du scaleway pour la BDD
provider "scaleway" {
  access_key      = "SCWJT3FZR0YCSB1WQ3MH"
  secret_key      = "1c04574d-b953-4d36-b16c-9949d61210ec"
  organization_id = "dbc4fc93-516c-413d-8d6c-cbbb7a76a9be"
  zone            = "fr-par-1"
  region          = "fr-par"
}

#Entrée DNS
resource "digitalocean_domain" "ca-angers" {
    name = "pcailleau.ca-ang.fabrique-it.fr"
}

#Ressource de la base de données scaleway MYSQL 8 sur le datacenter Frankfurt 1
resource "scaleway_rdb_instance_beta" "wp-contest" {
  name           = "rdb"
  engine         = "MySQL-8"
  node_type      = "db-dev-s"
  is_ha_cluster  = true
  disable_backup = true
  user_name      = "admin"
  password       = "PaulCa49!"
}

#On instancie la clé SSH
resource "digitalocean_ssh_key" "ssh" {
    name        = "SSH KEY"
    #On va chercher la clé dans le fichier correspondant
    public_key  = file("~/.ssh/authorized_keys.pub")
}

#Instance Ubuntu 20.04
resource "digitalocean_droplet" "ubuntu" {
  image     = "ubuntu-20-04-x64"
  name      = "Ubuntu2004"
  region    = "fra1"
  size      = "s-1vcpu-1gb"
  #On appel la clé SSH instanciée plus haut
  ssh_keys  = [digitalocean_ssh_key.ssh.fingerprint]
}

#Configuration du Firewall
resource "digitalocean_firewall" "ubuntu" {
  name = "ports 22-80-443 ouverts pour toute les hôtes"

  droplet_ids = [digitalocean_droplet.ubuntu.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
}

#Configuration de la sortie DNS
resource "digitalocean_record" "DNS" {
  name   = "pcailleau"
  domain = digitalocean_domain.ca-angers.name
  type   = "A"
  value  = "127.0.0.1"
}
output "domain" {
  value = digitalocean_record.DNS.value
}