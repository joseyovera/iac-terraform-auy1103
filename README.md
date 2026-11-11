# Infraestructura como Código I (AUY1103)

Repositorio de práctica personal para el ramo **Infraestructura como Código I** de Duoc UC. Aquí guardo las guías, laboratorios y prácticas del ramo, cada una documentada paso a paso para poder repetirla cuando quiera estudiar o levantar de nuevo la infraestructura.

Todo se trabaja con **Terraform** sobre **AWS Academy Learner Lab**, usando VS Code, la AWS CLI y Git en Windows.

## Cómo está ordenado

El repositorio sigue el mismo orden del ramo, por Experiencias de Aprendizaje (EA). Cada EA tiene su propia carpeta, y dentro de ella hay una carpeta por actividad. Cada carpeta tiene un README que explica qué se hizo y cómo repetirlo.

```
EA1/   Fundamentos de la infraestructura como código
EA2/   (pendiente)
EA3/   (pendiente)
```

## Índice

**EA1: Fundamentos de la infraestructura como código**

- [Actividad 1.1: De la consola a Terraform](EA1/actividad-1.1/README.md)
- [Actividad 1.2: Primeros pasos de la infraestructura como código](EA1/actividad-1.2/README.md)

## Rutina de cada laboratorio

Cada laboratorio sigue el mismo ciclo: entender qué se va a construir, escribir o revisar el código, ejecutar `terraform init`, `plan` y `apply`, revisar el resultado en la consola de AWS, destruir todo con `terraform destroy` para no gastar crédito, y finalmente documentar y subir los cambios a GitHub.

## Ojo con la seguridad

El archivo `.gitignore` evita que se suban los archivos de estado de Terraform (`*.tfstate`), la carpeta `.terraform/` y cualquier archivo con credenciales. Las credenciales de AWS **nunca** se escriben dentro de los archivos `.tf`.
