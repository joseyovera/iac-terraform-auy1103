# Guía 1.2.2, Parte I: Comandos básicos de Terraform

**EA1** · Actividad 1.2 · Individual

## Objetivo

Practicar los cinco comandos del ciclo de vida de Terraform (`init`, `validate`, `plan`, `apply` y `destroy`) con un recurso muy simple: una cadena de texto aleatoria. Se usa el provider `random` de HashiCorp, que **no necesita AWS ni credenciales**. Es como practicar a manejar en un estacionamiento vacío antes de salir a la calle: se puede experimentar sin costo y sin riesgo.

## Sobre los archivos de esta carpeta

El material complementario (`basicos-terraform.zip`) trae un `main.tf` y un `variables.tf`, pero son los mismos de la actividad 1.1 que crean la VPC de 18 recursos. La guía pide **reemplazar** el contenido de `main.tf` por el recurso `random_string`. Si se dejara el código de la VPC, el plan mostraría 19 recursos y el `apply` volvería a crear toda la red en AWS, con el NAT Gateway generando costos.

Por eso en esta carpeta solo hay un `main.tf` con el recurso aleatorio, y no se usa `variables.tf`, porque este recurso no necesita variables. El archivo quedó con `length = 10`, que es el valor del último cambio de la guía.

```hcl
resource "random_string" "random" {
  length = 16
}
```

## Paso 1: Verificar Terraform

```powershell
terraform -version
```

La versión utilizada fue **Terraform v1.15.8**. El comando `terraform -help` muestra la lista de comandos disponibles.

> **Cuidado al copiar desde la guía:** algunos comandos del Word están escritos con un guion largo (`–help`, `plan –destroy`) en vez del guion normal (`-`). La terminal no los reconoce, así que hay que escribirlos a mano.

## Paso 2: Inicializar con `terraform init`

Desde la carpeta del ejercicio:

```powershell
cd D:\IaC-Terraform\EA1\actividad-1.2\1.2.2-primeros-pasos\parte-1-comandos-basicos
terraform init
```

Terraform descargó el provider **`hashicorp/random` v3.9.1**. Llama la atención que el código no declara ningún provider: Terraform lo deduce del nombre del recurso, porque la primera palabra de `random_string` indica qué "traductor" necesita, igual que `aws_vpc` indica el provider de AWS.

Al terminar aparecen la carpeta oculta `.terraform` (donde queda guardado el provider) y el archivo `.terraform.lock.hcl` (que anota la versión exacta usada). La presencia de `.terraform` es la señal de que la carpeta quedó inicializada.

## Paso 3: Validar con `terraform validate`

```powershell
terraform validate
```

Respuesta: `Success! The configuration is valid.`

Este comando funciona como el corrector ortográfico de Word: revisa que el código esté bien escrito y que las referencias tengan sentido, pero no envía nada ni se conecta a ninguna nube. Por eso es muy rápido.

### Provocando un error a propósito

La guía pide reemplazar `length` por `largo` y validar de nuevo. El resultado fueron **dos errores**:

```
Error: Missing required argument
The argument "length" is required, but no definition was found.

Error: Unsupported argument
An argument named "largo" is not expected here.
```

El primero dice que falta un argumento obligatorio y el segundo que hay un argumento que Terraform no conoce. Es como un formulario donde se dejó vacío un campo obligatorio y se escribió en un campo que no existe. Además, Terraform indica el archivo y la línea exacta del problema (`main.tf line 2`), lo que ayuda mucho en códigos largos.

### Parámetros obligatorios y opcionales

El mismo error responde la pregunta de la guía: **`length` es el único parámetro obligatorio** de `random_string`. Algunos parámetros opcionales son `upper` (incluir mayúsculas), `lower` (minúsculas), `numeric` (números), `special` (símbolos) y `min_upper` (mínimo de mayúsculas). Todos tienen un valor por defecto, por eso no hace falta escribirlos. La lista completa está en el Terraform Registry, en la página del recurso `random_string`, secciones *Required* y *Optional*.

Después de la prueba se volvió a escribir `length` y `validate` dio `Success!` otra vez.

## Paso 4: Planificar con `terraform plan`

```powershell
terraform plan
```

Resultado: `Plan: 1 to add, 0 to change, 0 to destroy.`

El plan muestra todos los atributos del recurso, incluso los opcionales que no se escribieron, con su valor por defecto. El atributo `result` aparece como `(known after apply)` porque la cadena todavía no existe: se genera recién al aplicar.

Un detalle respecto de la guía: allí aparece el atributo `number = true`. En la versión 3.9.1 del provider aparecen tanto `number` como `numeric`. El nombre recomendado ahora es `numeric`, y `number` se mantiene para que las configuraciones antiguas sigan funcionando.

### Guardar el plan en un archivo

```powershell
terraform plan -out myplan
```

Esto guarda el plan en el archivo `myplan`. Es como pedir un presupuesto por escrito y firmado: después se aplica exactamente eso, ni más ni menos. Antes de ejecutarlo se agregaron `myplan` y `*.tfplan` al `.gitignore`, porque un plan guardado puede contener datos sensibles y no debe subirse a GitHub.

## Paso 5: Aplicar con `terraform apply`

### Aplicando el plan guardado

```powershell
terraform apply myplan
```

Resultado: `Apply complete! Resources: 1 added, 0 changed, 0 destroyed.`

Esta vez Terraform **no preguntó `yes`**: como el plan ya estaba revisado y guardado, lo ejecutó directamente. Para ver la cadena generada se consulta el estado:

```powershell
terraform state show random_string.random
```

La cadena obtenida fue `nL(4rCSvxSHe1#%_`, de 16 caracteres.

### Aplicando un cambio sin plan guardado

Se cambió `length = 16` por `length = 10` y se ejecutó `terraform apply` sin archivo de plan. Esta vez Terraform mostró el plan y pidió escribir `yes`. Lo más importante fue esta parte:

```
# random_string.random must be replaced
-/+ resource "random_string" "random" {
      ~ length = 16 -> 10 # forces replacement
    }

Plan: 1 to add, 0 to change, 1 to destroy.
```

El símbolo `-/+` y la nota `forces replacement` indican que el cambio **no se puede hacer sobre el recurso existente**: Terraform tiene que borrarlo y crear uno nuevo. Es como una torta ya horneada: se le puede cambiar la decoración (un cambio `~` en el lugar), pero para que sea más chica hay que hornear otra. La nueva cadena fue `LuAV9I)kMK`, de 10 caracteres y totalmente distinta a la anterior.

En este ejercicio no tiene consecuencias, pero en la vida real es clave: si un cambio fuerza el reemplazo de un servidor o una base de datos, se pierde lo que había adentro. Por eso siempre hay que leer el plan antes de escribir `yes`.

## Paso 6: Destruir con `terraform destroy`

Primero se revisó qué se iba a borrar, sin borrar nada todavía:

```powershell
terraform plan -destroy
```

Todos los atributos aparecen con `-` y terminan en `-> null`, que significa que van a dejar de existir. Resultado: `Plan: 0 to add, 0 to change, 1 to destroy.`

Luego se destruyó de verdad:

```powershell
terraform destroy
```

Resultado: `Destroy complete! Resources: 1 destroyed.`

El `destroy` borra los recursos, **no los archivos `.tf`**. El código queda intacto para volver a usarlo cuando se quiera.

## Símbolos del plan para recordar

```
+     se va a crear
-     se va a destruir
~     se modifica en el lugar
-/+   se destruye y se vuelve a crear (reemplazo)
```

## Lo que aprendí

Con un recurso tan simple como una cadena aleatoria pude recorrer todo el ciclo de Terraform sin gastar nada en AWS. Aprendí que `validate` revisa el código sin tocar la nube y que sus mensajes de error indican exactamente qué falta y en qué línea. También vi la diferencia entre aplicar un plan guardado, que no pide confirmación porque ya fue aprobado, y aplicar directamente, que muestra el plan y pide `yes`. Lo más importante fue entender que algunos cambios obligan a reemplazar el recurso completo, y que el plan lo avisa con `forces replacement`. Por eso leer el plan con calma antes de aplicar es una costumbre que vale la pena tener desde ahora.
