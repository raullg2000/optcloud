# 🚀 Desplegament de Arquitectura Segura en AWS (VPC + Bastion Host)

Aquest projecte desplega una **infraestructura de xarxa segura i escalable** en Amazon Web Services (AWS) utilitzant **Terraform**. L'objectiu principal és crear una xarxa privada on resideixen els servidors d'aplicació, controlant l'accés extern únicament a través d'un servidor de salt o Bastion Host.

---

## 🏛️ Components Clau

### 1. 🌐 Xarxa (VPC)

* **VPC (10.0.0.0/16):** El contenidor lògic de tota la xarxa.
* **Subxarxa Pública:** Aloja el **Bastion Host** i el **NAT Gateway**. Es connecta a Internet a través de l'**Internet Gateway (IGW)**.
* **Subxarxes Privades (N):** Alojen les **Instàncies Privades**. Tenen accés de sortida a Internet (per a actualitzacions, etc.) gràcies al **NAT Gateway**, però **no** accepten connexions entrants des d'Internet.

### 2. 🛡️ Seguretat i Accés

* **Bastion Host (Servidor de Salt):** Una instància EC2 a la subxarxa pública amb una **IP Elàstica (EIP)** fixa. És l'**únic punt d'entrada** permès des d'Internet.
* **Security Group (Bastion SG):** Només permet **SSH (port 22)** entrant des de **la teva IP pública** (`allowed_ip`).
* **Security Group (Private SG):** Només permet **SSH (port