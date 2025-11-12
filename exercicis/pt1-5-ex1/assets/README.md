El projecte desplega una infraestructura de xarxa aïllada (Virtual Private Cloud - VPC) amb recursos de còmput distribuïts en subxarxes públiques i privades.

VPC Única: Utilitza el bloc CIDR definit per la variable vpc_cidr.

Subxarxes: Es creen subxarxes públiques i privades. Les públiques tenen accés a Internet mitjançant un Internet Gateway.

Instàncies EC2: Creació d'instàncies EC2 tant a les subxarxes públiques com a les privades, utilitzant la variable instance_count.

Security Group (SG): S'aplica un SG comú que permet: HTTP (Port 80) des de qualsevol IP, SSH (Port 22) només des de la IP definida a la variable my_ip, i tot 
el tràfic intern dins de la VPC.

S3 Condicional: Inclou la creació d'un bucket S3, que es pot activar o desactivar mitjançant la variable booleana create_s3_bucket.