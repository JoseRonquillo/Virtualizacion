# Virtualizacion
# HW-04 - IPSec Site-to-Site

## Descripción

En esta práctica se configuró una VPN IPSec Site-to-Site entre dos redes diferentes utilizando un router intermedio para simular Internet.

La comunicación entre ambas redes se realiza mediante IPSec en modo túnel.

## Redes utilizadas

- Red A: 192.168.10.0/24
- Red B: 192.168.20.0/24
- R1-SEDE-A: 10.0.0.1
- R2-SEDE-B: 10.0.0.6
- Servidor Web: 192.168.20.10

## Prueba HTTPS

Desde PC-SEDE-A se realizó una solicitud HTTPS hacia:

https://192.168.20.10

La solicitud fue respondida correctamente por el servidor WEB-SERVER.

<img width="909" height="774" alt="image" src="https://github.com/user-attachments/assets/acbab37c-c2df-4a62-9a52-a747981de28f" />

## Verificación IPSec

Se verificó el funcionamiento del túnel IPSec mediante los comandos:

show crypto isakmp sa

show crypto ipsec sa

<img width="671" height="724" alt="image" src="https://github.com/user-attachments/assets/c2100c83-4284-4cfd-853e-5eaa545a3bf5" />

## Topología

<img width="753" height="485" alt="image" src="https://github.com/user-attachments/assets/bd6662b6-d65d-489d-85a3-9f449105cc35" />
