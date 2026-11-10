# Parte I: Creando infraestructura en la nube (manual)

**Guía 1.1.1** · EA1 · 2 horas · Grupal · Indicadores IL1.1 al IL1.3

## Objetivo

Crear a mano, desde la consola de AWS, una red completa: una VPC con seis subredes, un Internet Gateway, un NAT Gateway y dos tablas de rutas. El propósito no es solo armarla, sino darse cuenta de cuántos pasos hay y lo fácil que es equivocarse, para después compararlo con Terraform en la Parte II.

## Antes de empezar

Entra a AWS Academy, abre el **Learner Lab**, haz clic en **Start Lab** y espera a que el círculo junto a "AWS" se ponga verde. Luego haz clic en **AWS** para abrir la consola. Revisa arriba a la derecha que la región sea **Norte de Virginia (us-east-1)**.

Para llegar a la sección de redes, escribe **VPC** en el buscador de la consola y entra al servicio.

## Paso 1: Crear la VPC

En el panel de VPC, haz clic en **Crear VPC**. Selecciona la opción **Solo la VPC** (si eliges "VPC y más", AWS crea subredes por su cuenta y no es lo que queremos). Ponle de nombre `demo-vpc` y en **Bloque de CIDR IPv4** escribe `10.0.0.0/16`. Deja todo lo demás como viene y haz clic en **Crear VPC**.

El `10.0.0.0/16` es el "terreno" completo del condominio: unas 65 mil direcciones IP que después repartiremos entre las subredes.

## Paso 2: Crear las seis subredes

En el menú de la izquierda entra a **Subredes** y haz clic en **Crear subred**. Elige `demo-vpc` como VPC y crea la primera subred con estos datos: nombre `private-subnet-1`, zona `us-east-1a` y bloque `10.0.0.0/24`.

Repite lo mismo para las otras cinco. Puedes usar el botón **Agregar nueva subred** para crearlas todas en una sola pantalla. Los datos completos son:

```
private-subnet-1   us-east-1a   10.0.0.0/24
private-subnet-2   us-east-1b   10.0.1.0/24
private-subnet-3   us-east-1c   10.0.2.0/24
public-subnet-1    us-east-1a   10.0.100.0/24
public-subnet-2    us-east-1b   10.0.101.0/24
public-subnet-3    us-east-1c   10.0.102.0/24
```

Fíjate en el patrón: cada zona tiene una subred privada y una pública, y las públicas usan los números desde el 100 para distinguirlas fácilmente.

## Paso 3: Crear el Internet Gateway y conectarlo a la VPC

Entra a **Gateways de Internet** y haz clic en **Crear gateway de Internet**. Ponle de nombre `demo-igw` y confirma.

Un Internet Gateway recién creado queda "suelto". Para conectarlo, selecciónalo, abre el menú **Acciones**, elige **Conectar a la VPC**, selecciona `demo-vpc` y confirma. Su estado debe cambiar a **Attached**.

## Paso 4: Crear el NAT Gateway

Entra a **Gateways NAT** y haz clic en **Crear gateway NAT**. Ponle de nombre `demo-nat-gateway`, elige la subred `public-subnet-2` y deja el tipo de conectividad en **Público**. Haz clic en **Asignar IP elástica** para que AWS le reserve una IP pública fija, y luego en **Crear gateway NAT**.

El NAT Gateway tarda un par de minutos en quedar disponible. Va en una subred **pública** porque necesita salida directa a Internet para poder prestarle esa salida a las subredes privadas.

## Paso 5: Crear las tablas de rutas y asociarlas

Entra a **Tablas de enrutamiento** y haz clic en **Crear tabla de enrutamiento**. Ponle de nombre `public-rtb`, elige `demo-vpc` y confirma. Repite para crear una segunda tabla llamada `private-rtb`.

Ahora hay que decirle a cada tabla qué subredes le corresponden. Selecciona `public-rtb`, abre la pestaña **Asociaciones de subredes**, haz clic en **Editar asociaciones de subredes**, marca las tres subredes públicas y guarda. Haz lo mismo con `private-rtb` y las tres privadas.

## Paso 6: Agregar las rutas hacia Internet

Selecciona `public-rtb`, abre la pestaña **Rutas** y haz clic en **Editar rutas**. Haz clic en **Agregar ruta**, en destino escribe `0.0.0.0/0`, en objetivo elige **Gateway de Internet** y selecciona `demo-igw`. Guarda los cambios.

Repite con `private-rtb`, pero esta vez el objetivo es **Gateway NAT** y eliges `demo-nat-gateway`.

El destino `0.0.0.0/0` significa "cualquier dirección de Internet". Esta ruta es el letrero que dice: "para salir a cualquier lado, usa este portón".

## Cómo comprobar que quedó bien

En el panel de VPC, selecciona `demo-vpc` y abre la pestaña **Mapa de recursos**. Ahí deberías ver las seis subredes, las dos tablas de rutas y las conexiones hacia el Internet Gateway y el NAT Gateway, muy parecido al diagrama de la actividad.

## Limpieza (importante)

El NAT Gateway y la IP elástica cobran por hora, así que conviene borrar todo al terminar. El orden importa:

1. En **Gateways NAT**, selecciona `demo-nat-gateway`, abre **Acciones** y elige **Eliminar gateway NAT**. Espera a que quede en estado *Deleted*.
2. En **IP elásticas**, selecciona la IP que se creó, abre **Acciones** y elige **Liberar direcciones IP elásticas**. Si no la liberas, sigue cobrando aunque no se use.
3. En **Sus VPC**, selecciona `demo-vpc`, abre **Acciones** y elige **Eliminar VPC**. Escribe la palabra de confirmación que pide y confirma. Esto borra también las subredes, tablas de rutas y el Internet Gateway.

## Lo que aprendí

Armar esta red a mano tomó muchos pasos y varias pantallas distintas, y en cada una hay que escribir nombres y rangos de IP sin equivocarse. Además, el orden importa tanto al crear como al borrar: por ejemplo, no se puede borrar la VPC mientras exista el NAT Gateway. Si hubiera que repetir esto para otro ambiente (desarrollo, pruebas, producción), sería lento y fácil de hacer distinto cada vez. Ese es justamente el problema que resuelve Terraform en la Parte II.
