# EA1: Fundamentos de la infraestructura como código

En esta primera Experiencia de Aprendizaje se trabaja la idea central del ramo: pasar de crear infraestructura "a mano" en la consola de AWS a describirla en código con Terraform, para que se pueda repetir de forma rápida, igual cada vez y sin errores humanos.

## Actividades

- [Actividad 1.1: De la consola a Terraform](actividad-1.1/README.md). Se construye la misma red en AWS dos veces: primero a mano y después con Terraform, para comparar ambos enfoques.

## Conceptos clave de esta EA

**Infraestructura como Código (IaC)** significa describir servidores, redes y demás recursos en archivos de texto, en vez de crearlos con clics. Es como la diferencia entre armar un mueble de memoria y armarlo siguiendo un plano: con el plano cualquiera puede repetirlo y siempre sale igual.

**Terraform** es la herramienta que lee esos archivos (`.tf`) y se encarga de crear, modificar o borrar los recursos en la nube.

**Provider** es el "traductor" que Terraform usa para hablar con cada nube. Para AWS se usa el provider `hashicorp/aws`.

Los cuatro comandos básicos son `terraform init` (prepara la carpeta y descarga el provider), `terraform plan` (muestra qué va a hacer, sin tocar nada), `terraform apply` (crea los recursos) y `terraform destroy` (borra todo lo que creó).
