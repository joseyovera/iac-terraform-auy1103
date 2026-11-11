# Material original (solo referencia)

Estos son los archivos del material complementario `state-backend-configuration.zip`, guardados **sin cambios**. No se aplicaron en la práctica de backends (la razón está explicada en el [README de la Parte II](../README.md)).

Se guardan porque traen temas que se verán en unidades futuras: **módulos** (carpeta `modules`), **provisioners** (`local-exec` y `remote-exec`), llaves SSH generadas con el provider `tls` y security groups.

> No ejecutar `terraform apply` en esta carpeta tal como está: tiene errores de versiones, falla en Windows y crearía un NAT Gateway y cinco servidores EC2.

```
material-original/
├── terraform.tf          versiones de Terraform y providers
├── variables.tf          variables de la VPC
├── main.tf               VPC, NAT, 5 servidores EC2, llaves y security groups
└── modules/
    ├── server/           módulo de un servidor simple (main, variables, outputs)
    └── web_server/       módulo de un servidor web (server.tf)
```
