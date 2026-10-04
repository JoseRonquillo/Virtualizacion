# Virtualizacion
# Assessment 02: Kubernetes con MetalLB y Traefik

Configuración de un clúster local de Minikube donde **MetalLB** entrega una única IP,
**Traefik** la usa como `LoadBalancer` y enruta por nombre de dominio hacia 4 aplicaciones web.

## Arquitectura

```
Navegador ──(app1..app4.parcial.local)──> 172.22.166.4 (IP de MetalLB)
                                              │
                                        Traefik (ns: traefik)
                                              │  Ingress (por host)
                    ┌──────────┬──────────┬───┴──────┬──────────┐
                  app1       app2       app3       app4
                (ns: parcial-jarm, cada una con su Deployment y Service)
```

## Herramientas utilizadas

- Windows, Minikube, kubectl y Helm
- MetalLB v0.14.9
- Traefik (Helm chart `traefik/traefik`)

## Paso 1: Iniciar Minikube

```powershell
minikube start --driver=hyperv
minikube ip
```

La IP de Minikube sirve como referencia para elegir la IP que MetalLB entregará
(misma red).

## Paso 2: Instalar MetalLB (namespace `metallb-system`)

```powershell
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml
kubectl wait -n metallb-system --for=condition=ready pod --selector=app=metallb --timeout=120s
```

MetalLB crea su propio namespace `metallb-system`. Después se configura un pool con
**una sola IP** (`/32`) y se anuncia en modo L2 con `metallb-config.yaml`:

```powershell
kubectl apply -f metallb-config.yaml
kubectl get pods -n metallb-system
```

## Paso 3: Instalar Traefik (namespace `traefik`)

```powershell
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm install traefik traefik/traefik -n traefik --create-namespace
kubectl get svc -n traefik
```

El Service `traefik` es de tipo `LoadBalancer` y MetalLB le asigna la IP del pool:
**172.22.166.4**.

<img width="983" height="514" alt="Captura de pantalla 2026-10-04 165027" src="https://github.com/user-attachments/assets/b05f8b57-496a-412c-a582-462fd9a690fc" />

## Paso 4: Aplicaciones (namespace `parcial-jarm`)

`apps.yaml` crea el namespace `parcial-jarm` y, dentro de él, 4 Deployments con su Service cada uno:

| App  | Imagen             | Service |
|------|--------------------|---------|
| app1 | `nginx:1.27`       | app1:80 |
| app2 | `httpd:2.4`        | app2:80 |
| app3 | `traefik/whoami`   | app3:80 |
| app4 | `nginxdemos/hello` | app4:80 |

```powershell
kubectl apply -f apps.yaml
kubectl apply -f ingress.yaml
kubectl get all,ingress -n parcial-jarm
```

## Paso 5: Ingress

`ingress.yaml` usa `ingressClassName: traefik` y define una regla por dominio, de modo
que Traefik envía cada host a su Service:

| Dominio              | Service |
|----------------------|---------|
| app1.parcial.local   | app1    |
| app2.parcial.local   | app2    |
| app3.parcial.local   | app3    |
| app4.parcial.local   | app4    |

## Paso 6: DNS local (archivo hosts)

Se editó `C:\Windows\System32\drivers\etc\hosts` (como administrador) agregando:

```
172.22.166.4 app1.parcial.local
172.22.166.4 app2.parcial.local
172.22.166.4 app3.parcial.local
172.22.166.4 app4.parcial.local
```

Los 4 dominios apuntan a la IP del LoadBalancer de Traefik.

## Evidencias: acceso desde el navegador

### app1.parcial.local
<img width="1414" height="772" alt="Captura de pantalla 2026-10-04 170015" src="https://github.com/user-attachments/assets/75f2e09c-1120-4595-b35c-51a2c5152502" />

### app2.parcial.local
<img width="1429" height="846" alt="Captura de pantalla 2026-10-04 170020" src="https://github.com/user-attachments/assets/a0fdee14-021d-4784-b0e5-547d3942ab82" />

### app3.parcial.local
<img width="1432" height="814" alt="Captura de pantalla 2026-10-04 170025" src="https://github.com/user-attachments/assets/59ee0dec-3cd7-4648-bf69-477bf57f95b2" />

### app4.parcial.local
<img width="1428" height="848" alt="Captura de pantalla 2026-10-04 170031" src="https://github.com/user-attachments/assets/2131e786-7133-40ab-b715-7b034a440404" />
