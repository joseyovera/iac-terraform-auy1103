# Parte II: Integrando Terraform en el mundo empresarial

**Guía 1.1.2** · EA1 · 3 horas · Individual · Indicadores IL1.1 al IL1.3

## Objetivo

Construir con Terraform la misma red que en la [Parte I](../parte-1-manual/README.md) se hizo a mano, y después borrarla con un solo comando. La guía no busca entender cada línea del código todavía (eso viene en las próximas sesiones), sino ver lo simple y rápido que es comparado con la consola.

## Archivos de esta carpeta

`main.tf` describe todos los recursos de la red. `variables.tf` guarda los valores que se pueden cambiar sin tocar el código principal, como el nombre de la VPC, su rango de IP y la lista de subredes. Ambos vienen en el material complementario del ramo (`terraform-1.1.2.zip`).

## Paso 1: Borrar lo que se creó en la Parte I

Si todavía existe la red de la Parte I, hay que borrarla primero. Sigue la sección **Limpieza** de la [Parte I](../parte-1-manual/README.md): eliminar el NAT Gateway, liberar la IP elástica y eliminar la VPC.

## Paso 2: Conectar Terraform con el Learner Lab

Aquí está la principal diferencia con la guía oficial. La guía dice que hay que crear un usuario IAM con claves de acceso, pero **en el Learner Lab no se pueden crear usuarios IAM**. En cambio, el laboratorio entrega credenciales temporales que duran mientras el lab está encendido (unas 4 horas). Por eso este paso se repite cada vez que inicias el lab.

Primero, en la página del Learner Lab haz clic en **Start Lab** y espera el círculo verde. Luego haz clic en **AWS Details** y, junto a **AWS CLI**, haz clic en **Show**. Aparece un bloque de texto que empieza con `[default]` y tiene tres líneas: `aws_access_key_id`, `aws_secret_access_key` y `aws_session_token`. Cópialo completo.

Ahora, en una terminal de VS Code (**Terminal → Nueva terminal**), crea la carpeta de credenciales (solo es necesario la primera vez):

```powershell
New-Item -ItemType Directory -Force $HOME\.aws
```

Y abre el archivo de credenciales con el Bloc de notas:

```powershell
notepad $HOME\.aws\credentials
```

Si te pregunta si quieres crear el archivo, responde que sí. Borra lo que tenga, pega el bloque que copiaste y guarda con **Ctrl + S**.

Para comprobar que funciona:

```powershell
aws sts get-caller-identity
```

Si responde con un `UserId`, un `Account` y un `Arn` que contiene `voclabs`, la conexión está lista. Terraform usa automáticamente este mismo archivo, así que no hay que configurar nada más.

> Este archivo está en tu carpeta de usuario, fuera del repositorio, así que nunca se sube a GitHub. Las credenciales jamás deben escribirse dentro de los archivos `.tf`.

## Paso 3: Inicializar la carpeta

En la terminal, entra a esta carpeta:

```powershell
cd D:\IaC-Terraform\EA1\actividad-1.1\parte-2-terraform
```

Y ejecuta:

```powershell
terraform init
```

Este comando lee los archivos `.tf`, ve que se necesita AWS y descarga el **provider** correspondiente dentro de una carpeta oculta llamada `.terraform`. También crea el archivo `.terraform.lock.hcl`, que anota la versión exacta del provider que se usó. Ese archivo **sí** se sube a GitHub, para que la próxima vez se use la misma versión.

## Paso 4: Revisar el plan

```powershell
terraform plan
```

El plan es como el presupuesto de un maestro antes de empezar la obra: te dice exactamente qué va a construir, sin tocar nada todavía. Al final debe aparecer la línea `Plan: 18 to add, 0 to change, 0 to destroy.`

## Paso 5: Crear la infraestructura

```powershell
terraform apply
```

Terraform vuelve a mostrar el plan y pregunta si quieres continuar. Escribe `yes` y presiona **Enter**. La guía usa `terraform apply -auto-approve`, que se salta esa pregunta, pero al principio conviene ver la confirmación para acostumbrarse a revisar antes de aplicar.

La creación toma unos minutos, sobre todo por el NAT Gateway. Al final aparece `Apply complete! Resources: 18 added, 0 changed, 0 destroyed.`

Con eso puedes ir a la consola de AWS, entrar a **VPC**, seleccionar `demo_vpc` y abrir la pestaña **Mapa de recursos** para ver la red completa.

## Paso 6: Destruir todo

```powershell
terraform destroy
```

Escribe `yes` cuando lo pida. Terraform borra los 18 recursos en el orden correcto, incluida la IP elástica, sin que tengas que recordar nada. Esto es justamente lo que en la Parte I había que hacer a mano y con cuidado.

## Respuestas a las preguntas de la guía

**¿Qué provider se está utilizando y cuál es su versión?**

Se usa el provider `hashicorp/aws`, que es el que permite a Terraform hablar con AWS. Como el código no fija una versión, `terraform init` descarga la más reciente disponible. En la guía aparece la 3.37.0 porque es un ejemplo antiguo; en mi caso la versión fue: _(completar con la que muestre `terraform init`)_.

**¿Cuántos tipos de recursos se pueden identificar en el plan?**

Hay **7 tipos de recursos**, que en total suman 18 recursos:

```
aws_vpc                        1   la red principal
aws_subnet                     6   3 públicas y 3 privadas
aws_route_table                2   una pública y una privada
aws_route_table_association    6   una por cada subred
aws_internet_gateway           1   salida a Internet
aws_eip                        1   la IP pública fija del NAT
aws_nat_gateway                1   salida a Internet para las privadas
```

Los bloques `data` (`aws_availability_zones` y `aws_region`) no cuentan como recursos, porque no crean nada: solo le preguntan a AWS información, como qué zonas de disponibilidad existen.

## Cómo está armado el código (vista rápida)

Cada recurso en Terraform sigue la misma forma:

```hcl
resource "tipo_de_recurso" "nombre_interno" {
  # configuración del recurso
}
```

El **tipo** dice qué se crea (por ejemplo `aws_vpc`) y el **nombre interno** es el apodo que se usa para referirse a él dentro del código. Por ejemplo, las subredes dicen `vpc_id = aws_vpc.vpc.id`, que se lee como "el id de la VPC que bauticé `vpc`". Así Terraform entiende que primero debe crear la VPC y después las subredes, sin que nadie le diga el orden.

Hay dos trucos que permiten crear seis subredes escribiendo solo dos bloques. El primero es `for_each`, que repite el recurso una vez por cada elemento de la lista definida en `variables.tf`. El segundo es la función `cidrsubnet`, que calcula los rangos de IP automáticamente a partir del rango de la VPC.

## Diferencias con la red de la Parte I

Aunque la red es la misma en forma, el código del ramo no produce exactamente los mismos valores que la guía manual. Vale la pena notarlo porque muestra que **el código manda**: Terraform crea lo que dice el código, no lo que uno tenía en mente.

Los nombres usan guion bajo en vez de guion (`demo_vpc`, `private_subnet_1`). Los rangos de IP calculados por `cidrsubnet` quedan en `10.0.1.0/24`, `10.0.2.0/24` y `10.0.3.0/24` para las privadas, y en `10.0.101.0/24`, `10.0.102.0/24` y `10.0.103.0/24` para las públicas. Las zonas de disponibilidad empiezan en `us-east-1b` y no en `us-east-1a`, porque las listas en Terraform se cuentan desde 0 y las subredes usan los números 1, 2 y 3. Por último, el NAT Gateway queda en `public_subnet_1` y no en la subred pública 2.

También se puede ver que `variables.tf` define una variable `aws_region`, pero `main.tf` no la usa: la región está escrita directamente en el bloque `provider`. No es un error que impida funcionar, pero es algo que se podría mejorar.

## Lo que aprendí

Con Terraform, la misma red que en la Parte I tomó muchos pasos y pantallas se creó con un solo comando y se borró con otro. Terraform además resolvió solo el orden correcto de creación y de borrado, algo que a mano había que tener en mente. Y como todo queda escrito en archivos, se puede guardar en GitHub, revisar, compartir y repetir las veces que haga falta, obteniendo siempre el mismo resultado.
