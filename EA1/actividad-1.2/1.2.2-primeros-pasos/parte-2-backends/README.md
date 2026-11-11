# Guía 1.2.2, Parte II: Backends de Terraform

**EA1** · Actividad 1.2 · Individual

## La idea en simple

Terraform lleva una **libreta** (el archivo de estado, `terraform.tfstate`) donde anota todo lo que creó: qué recursos existen, con qué ID y con qué valores. Gracias a esa libreta sabe qué crear, qué cambiar y qué borrar. Sin ella no recuerda nada.

El **backend** es el lugar donde se guarda esa libreta. En esta parte se guarda primero en el PC (backend local) y después se muda a la nube, a un bucket de Amazon S3 (backend remoto). Es como pasar los apuntes de un cuaderno que está en la casa a una carpeta en la nube: los apuntes son los mismos, solo cambia dónde viven.

```
Etapa 1: libreta en el PC          Etapa 2: libreta en la nube
┌────────────────────┐             ┌──────────────────────────────┐
│ terraform.tfstate  │   ──────▶   │ s3://tf-state-joseyovera-... │
│ (carpeta local)    │   mudanza   │      prod/aws_infra          │
└────────────────────┘             └──────────────────────────────┘
 backend "local"                    backend "s3"
```

## Por qué no se usó el código completo del material

El material complementario (`state-backend-configuration.zip`) trae un proyecto grande: la VPC con NAT Gateway, cinco servidores EC2, llaves SSH, security groups y dos módulos. Ese código está guardado sin cambios en la carpeta [`material-original`](material-original/) como referencia para unidades futuras, donde se ven los módulos y los provisioners.

Para esta práctica se decidió no aplicarlo, por cuatro razones. Usa el comando `chmod`, que es de Linux y falla en Windows. Obliga a usar el provider de AWS 3.x, pero usa `domain = "vpc"`, que solo existe desde la versión 5, así que da error. Busca una imagen de Ubuntu 20.04, que ya no tiene soporte. Y crearía el NAT Gateway más cinco servidores solo para mirar un archivo de estado, gastando crédito del Learner Lab.

Como el tema de esta parte es **la libreta y no lo que se anota en ella**, se usó el recurso `random_string` de la Parte I. Con él se practica exactamente lo mismo sobre backends, sin costo y sin errores ajenos al tema.

## Archivos de esta carpeta

`main.tf` contiene solo la cadena aleatoria:

```hcl
resource "random_string" "random" {
  length = 16
}
```

`terraform.tf` es la configuración general del proyecto. Aquí se declara el provider por escrito con `required_providers` (en vez de dejar que Terraform lo deduzca) y aquí va el bloque `backend`, que es lo que se fue cambiando durante la práctica. Su versión final es la del backend S3.

## Etapa 1: Backend local

### Declarar el backend local

Por defecto Terraform guarda el estado en el PC aunque no se diga nada. En esta etapa se escribió de forma explícita:

```hcl
terraform {
  required_providers {
    random = {
      source = "hashicorp/random"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}
```

Luego se ejecutó `terraform init` y `terraform apply`, y se abrió la libreta con `cat terraform.tfstate`. Por dentro es un archivo JSON. Algunas partes importantes:

```
"terraform_version": "1.15.8"   versión de Terraform que la escribió
"serial": 1                     número de versión de la libreta, sube con cada cambio
"type": "random_string"         tipo de recurso
"name": "random"                nombre del recurso en el código
"result": "<=XUX-WOq)..."  la cadena generada (< es el símbolo <)
```

La libreta guarda **todos** los valores, incluidos los resultados. Si el recurso fuera una contraseña, quedaría escrita ahí en texto plano. Por eso el `.tfstate` nunca se sube a GitHub.

### Cambiar la ruta de la libreta

La guía pide cambiar `path = "terraform.tfstate"` por `path = "terraform-nuevo.tfstate"` y volver a ejecutar `terraform apply`. El resultado fue un error:

```
Error: Backend initialization required, please run "terraform init"
Reason: Backend configuration block has changed
```

**¿Por qué pasa esto?** Terraform detectó que cambió el lugar donde se guarda la libreta y se detiene antes de seguir. Si continuara sin preguntar, empezaría con una libreta nueva y vacía, olvidaría que la cadena ya existe e intentaría crearla otra vez. El error es una protección. La solución es volver a inicializar pidiéndole que mude la libreta:

```powershell
terraform init -migrate-state
```

Terraform pregunta si se quiere copiar el estado existente al nuevo lugar, y se responde `yes`. Después de esto aparecen dos archivos del mismo tamaño, `terraform.tfstate` y `terraform-nuevo.tfstate`: Terraform **copió** la libreta, no la movió, y desde ese momento solo usa la nueva.

Para comprobarlo se ejecutó `terraform plan`, que respondió `No changes. Your infrastructure matches the configuration.` Eso significa que Terraform leyó la libreta nueva y reconoció que la cadena ya existía.

## Etapa 2: Backend S3

### Preparar el bucket

Siguiendo la guía, primero se destruyó lo que existía con `terraform destroy`, para partir con la libreta vacía. Luego se creó el bucket desde la terminal:

```powershell
aws s3 mb s3://tf-state-joseyovera-auy1103 --region us-east-1
```

El nombre de un bucket tiene que ser único en todo AWS, en minúsculas y sin espacios. Por eso el nombre de ejemplo de la guía (`my-terraform-state-ghm`) no sirve: ya lo tiene otra persona. Se usó uno con el usuario de GitHub para que fuera único.

### Cambiar el backend a S3

En `terraform.tf` se reemplazó el bloque `backend "local"` por este:

```hcl
  backend "s3" {
    bucket = "tf-state-joseyovera-auy1103"
    key    = "prod/aws_infra"
    region = "us-east-1"
  }
```

El `bucket` es la carpeta en la nube, el `key` es la ruta y el nombre de la libreta dentro del bucket, y `region` es dónde está el bucket. Este bloque **no acepta variables**, así que los valores van escritos directamente.

Con el backend cambiado se ejecutó `terraform init -migrate-state`, que respondió `Successfully configured the backend "s3"!`. Luego `terraform apply` volvió a crear la cadena, y esta vez la libreta se guardó en la nube. Para comprobarlo:

```powershell
aws s3 ls s3://tf-state-joseyovera-auy1103 --recursive
```

Resultado: `prod/aws_infra`, de 974 bytes. También se puede ver en la consola de AWS, entrando a **S3**, abriendo el bucket y luego la carpeta `prod`.

### Credenciales en el Learner Lab

La guía usa variables de entorno con `export`, que es un comando de Linux. En Windows y con el Learner Lab no hizo falta: Terraform usó automáticamente el archivo de credenciales de la AWS CLI (`$HOME\.aws\credentials`), configurado con las credenciales temporales de **AWS Details**, igual que en la actividad 1.1.

### Probar el acceso con credenciales inválidas

Para demostrar que solo quien tiene credenciales puede leer la libreta, se definieron claves falsas en la terminal. En PowerShell, estas variables tienen prioridad sobre el archivo de credenciales:

```powershell
$Env:AWS_ACCESS_KEY_ID="notvalid"
$Env:AWS_SECRET_ACCESS_KEY="notvalid"
terraform state list
```

El resultado fue un error 403:

```
api error InvalidClientTokenId: The security token included in the request is invalid.
```

AWS rechazó las claves falsas y Terraform no pudo abrir la libreta. Para recuperar el acceso se borraron las variables falsas:

```powershell
Remove-Item Env:AWS_ACCESS_KEY_ID, Env:AWS_SECRET_ACCESS_KEY
terraform state list
```

Y Terraform volvió a responder `random_string.random`.

### Limpieza

Al terminar se ejecutó `terraform destroy`, que borra la cadena y deja la libreta en S3 vacía. El bucket **no se borró**, porque se reutiliza en el laboratorio de la App Web, que también guarda su estado en S3. Si en algún momento se quiere eliminar: `aws s3 rb s3://tf-state-joseyovera-auy1103 --force`.

## Preguntas de reflexión

**¿Cuáles son las principales diferencias entre un backend local y uno remoto, y cómo afectan la gestión del estado?**

Con un backend local, la libreta vive en el PC de una sola persona. Es simple y no requiere configuración, pero si el archivo se borra o el PC falla, Terraform pierde la memoria de lo que creó, y nadie más puede trabajar sobre esa infraestructura. Con un backend remoto, la libreta vive en un servicio en la nube como S3: no depende de un PC, se puede respaldar y versionar, y todo el equipo trabaja sobre la misma información.

**¿Qué consideraciones de seguridad hay que tener al elegir entre uno y otro?**

El estado guarda todos los valores de los recursos, incluso contraseñas o claves, en texto plano. En un backend local hay que cuidar que ese archivo no se suba a un repositorio ni se comparta por error, como se hace en este repo con el `.gitignore`. En un backend remoto hay que controlar quién tiene permisos sobre el bucket, activar el cifrado y nunca escribir credenciales dentro del código. La prueba con credenciales falsas mostró que, sin permisos válidos, nadie puede leer el estado.

**¿Cuándo conviene un backend local y cuándo uno remoto?**

El local conviene para aprender, hacer pruebas rápidas o proyectos personales que solo maneja una persona, como los ejercicios con `random_string`. El remoto conviene apenas hay un equipo, un ambiente real o producción, o cuando Terraform se ejecuta desde un pipeline automático. La regla práctica es: local para aprender, remoto en cuanto se trabaja en equipo o en producción.

**¿Cómo afecta un backend remoto a la escalabilidad y la colaboración?**

Con un backend remoto hay una sola fuente de verdad: todas las personas del equipo, y también los pipelines de CI/CD, leen y escriben la misma libreta. Así nadie trabaja con una versión desactualizada. Además, los backends remotos pueden **bloquear** el estado mientras alguien aplica cambios, para que dos personas no modifiquen la infraestructura al mismo tiempo y la libreta no quede corrupta. Con un backend local, cada persona tendría su propia libreta y rápidamente dejarían de coincidir con la realidad.

**¿Qué estrategias de migración se pueden usar para pasar de local a remoto, y qué desafíos tiene?**

La estrategia es la que se usó en esta práctica: crear primero el bucket, cambiar el bloque `backend` en el código y ejecutar `terraform init -migrate-state`, que copia la libreta al nuevo lugar. Antes conviene respaldar el archivo de estado local. Los desafíos son que el bucket tiene que existir antes del `init`, que hay que tener los permisos correctos, que nadie debe estar aplicando cambios durante la mudanza y que, después de migrar, hay que asegurarse de que todo el equipo use el backend nuevo y no las copias locales viejas, que quedan en la carpeta pero ya no se usan.

## Lo que aprendí

Entendí que Terraform no "recuerda" nada por sí mismo: todo lo que sabe está en su archivo de estado, y el backend decide dónde vive ese archivo. Vi que cambiar el backend no es algo que Terraform haga en silencio: se detiene, pide volver a inicializar y pregunta si se quiere mudar la libreta, para no perder información. También comprobé que guardar el estado en S3 permite tenerlo protegido y centralizado, y que sin credenciales válidas nadie puede leerlo. Para practicar me basta un backend local, pero en un trabajo real, con más personas, el estado tiene que estar en un backend remoto.
