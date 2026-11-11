# Actividad 1.2: Primeros pasos de la infraestructura como código

Esta actividad profundiza en el ciclo de vida de Terraform. Primero se practican los comandos básicos con un recurso sencillo que no necesita nube, y después se estudia dónde guarda Terraform su "libreta de apuntes" (el estado) y cómo moverla a la nube.

## Guía 1.2.2: Primeros pasos de la infraestructura como código

**EA1** · 1 hora · Individual · Indicadores IL1.1 al IL1.3

- [Parte I: Comandos básicos de Terraform](1.2.2-primeros-pasos/parte-1-comandos-basicos/README.md). Ciclo completo `init → validate → plan → apply → destroy` usando el provider `random`.
- [Parte II: Backends de Terraform](1.2.2-primeros-pasos/parte-2-backends/README.md). Dónde se guarda el estado: primero en el PC y luego en un bucket S3.

## La idea central

```
 init       validate      plan          apply         destroy
 prepara →  revisa    →   muestra   →   crea      →   borra
 carpeta    escritura     vista         recursos      recursos
                          previa
```

`init` se ejecuta una vez por carpeta, o cuando cambian los providers. Después el ciclo normal es editar el código, validar, planificar y aplicar, repitiendo las veces que haga falta. Al terminar, siempre se destruye para no dejar recursos olvidados.
