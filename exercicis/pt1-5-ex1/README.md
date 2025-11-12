## 🏗️ Disseny de la Infraestructura de Xarxa Aïllada (VPC)

El projecte desplega una **Infraestructura de Xarxa Aïllada** (Virtual Private Cloud - **VPC**) amb recursos de còmput distribuïts en **subxarxes públiques** i **privades**.



---

### 🌐 Components Clau

* **VPC Única:**
    * Utilitza un únic bloc **CIDR** definit per la variable `$vpc\_cidr$`.
* **Subxarxes:**
    * Creació de **Subxarxes Públiques** (amb accés a Internet mitjançant un Internet Gateway).
    * Creació de **Subxarxes Privades** (aïllades d'Internet).
* **Instàncies EC2:**
    * Creació d'Instàncies **EC2** tant a les subxarxes **públiques** com a les **privades**.
    * El nombre d'instàncies es defineix mitjançant la variable `$instance\_count$`.

---

### 🛡️ Configuració de Seguretat (Security Group - SG)

S'aplica un **Security Group (SG)** comú a totes les instàncies amb les següents regles d'accés:

| Tràfic | Protocol / Port | Origen (Source) | Propòsit |
| :--- | :--- | :--- | :--- |
| **HTTP** | TCP / **80** | Qualsevol (`0.0.0.0/0`) | Accés web general. |
| **SSH** | TCP / **22** | Només `$my\_ip$` | Administració segura. |
| **Tràfic Intern** | Tot | Dins la **VPC** | Comunicació entre recursos. |

---

### 💾 Emmagatzematge Condicional (S3)

* **Bucket S3 Condicional:** Inclou la creació d'un bucket **S3**.
* Aquesta creació es pot **activar** o **desactivar** mitjançant la variable booleana `$create\_s3\_bucket$`.