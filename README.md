# Virtualizacion
# Assessment 06: Argo CD y GitOps

**Alumno:** Jose Antonio Ronquillo Meza (JARM)
**Rama:** `assessment-06`

## Descripción

En esta actividad se instaló Argo CD en el clúster de Minikube, se expuso su interfaz web mediante Traefik con un nombre de dominio local y se desplegaron dos aplicaciones en el namespace `parcial-jarm` siguiendo el enfoque GitOps: el estado del clúster se define en Git y Argo CD lo sincroniza automáticamente.

## 1. Instalación de Argo CD

Argo CD se instaló con Helm en el namespace `argocd-jarm` (la palabra "argocd-" seguida de las iniciales JARM). Se usó Helm porque el manifiesto oficial trae el namespace `argocd` fijo en sus ClusterRoleBindings.

Archivo `argocd/values.yaml`:

```yaml
configs:
  params:
    server.insecure: true
```

El modo `server.insecure` hace que Argo CD sirva HTTP, y Traefik se encarga del acceso externo sin bucles de redirección TLS.

Comandos:

```powershell
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd -n argocd-jarm --create-namespace -f argocd/values.yaml --timeout 20m --wait
kubectl get pods -n argocd-jarm
```

Todos los pods quedaron en estado `Running`. La imagen principal tardó unos 8 minutos en descargarse por la velocidad de la red, por eso se usó `--timeout 20m`.

Contraseña inicial del usuario `admin`:

```powershell
kubectl -n argocd-jarm get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | % { [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_)) }
```

<img width="783" height="172" alt="image" src="https://github.com/user-attachments/assets/be98c827-467a-4f14-8d66-a423a2e144e8" />

## 2. Instalación de Traefik

Traefik se instaló con Helm en el namespace `traefik`.

Archivo `argocd/traefik-values.yaml`:

```yaml
service:
  type: LoadBalancer
  externalIPs:
    - 172.21.139.28
ingressClass:
  enabled: true
  isDefaultClass: true
```

Comandos:

```powershell
helm install traefik traefik/traefik -n traefik --create-namespace -f argocd/traefik-values.yaml --timeout 20m --wait
kubectl get svc -n traefik
```

Con el driver Hyper-V, `minikube tunnel` no asignaba una IP al LoadBalancer (quedaba en `<pending>`). Como solución se asignó la IP de la VM de Minikube (`minikube ip`) como `externalIPs` del servicio de Traefik, de modo que responde directamente en el puerto 80:

```powershell
kubectl patch svc traefik -n traefik --type merge --patch-file patch.json
```

donde `patch.json` contenía `{"spec":{"externalIPs":["172.21.139.28"]}}`.

<img width="760" height="84" alt="image" src="https://github.com/user-attachments/assets/303b3a9a-c141-488f-844e-9ee569bd0803" />

## 3. Exposición de Argo CD por medio de Traefik

El Ingress se define en `argocd/ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server
  namespace: argocd-jarm
spec:
  ingressClassName: traefik
  rules:
    - host: argocd.jarm.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: argocd-server
                port:
                  number: 80
```

```powershell
kubectl apply -f argocd/ingress.yaml
kubectl get ingress -n argocd-jarm
```

Para resolver el dominio se agregó esta línea al archivo `C:\Windows\System32\drivers\etc\hosts` (editado como Administrador), apuntando a la IP del LoadBalancer de Traefik:

```
172.21.139.28 argocd.jarm.local
```

```powershell
ipconfig /flushdns
```

Con esto la interfaz web es accesible en **http://argocd.jarm.local**.

<img width="1436" height="835" alt="Captura de pantalla 2026-10-20 224848" src="https://github.com/user-attachments/assets/431fd5e6-8631-435a-a0da-b08341026ced" />

## 4. Conexión al repositorio y creación de las Applications

El repositorio de GitHub es público, por lo que Argo CD puede leerlo sin credenciales. Las Applications apuntan a la rama `assessment-06`.

Archivo `argocd/application-app1.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app1-jarm
  namespace: argocd-jarm
spec:
  project: default
  source:
    repoURL: https://github.com/JoseRonquillo/Virtualizacion.git
    targetRevision: assessment-06
    path: apps/app1
  destination:
    server: https://kubernetes.default.svc
    namespace: parcial-jarm
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

El archivo `argocd/application-app2.yaml` es idéntico, con `name: app2-jarm` y `path: apps/app2`.

Las aplicaciones (`apps/app1/app1.yaml` y `apps/app2/app2.yaml`) son un Deployment de `nginx:alpine` y su Service, ambos en el namespace `parcial-jarm`.

```powershell
kubectl apply -f argocd/application-app1.yaml
kubectl apply -f argocd/application-app2.yaml
kubectl get applications -n argocd-jarm
kubectl get pods -n parcial-jarm
```

La sincronización automática (`automated`) con `prune` y `selfHeal` mantiene el clúster igual a lo definido en Git.

<img width="1435" height="858" alt="Captura de pantalla 2026-10-20 225429" src="https://github.com/user-attachments/assets/bf8a90bf-bb90-43ba-8cfa-56981013a2d9" />

## 5. Cambio en el repositorio y sincronización (GitOps)

Para demostrar GitOps se modificó el número de réplicas de `app1` en el repositorio, de 1 a 3, en el archivo `apps/app1/app1.yaml`:

```yaml
spec:
  replicas: 3
```

```powershell
git add apps/app1/app1.yaml
git commit -m "Cambio: app1 replicas de 1 a 3"
git push
```

No se tocó el clúster con `kubectl`: Argo CD detectó el nuevo commit (`3f844c7`) y lo sincronizó automáticamente. La verificación en el clúster muestra que `app1` pasó de 1 a 3 pods, mientras `app2` se mantuvo con 1:

```powershell
kubectl get pods -n parcial-jarm
```

<img width="1439" height="850" alt="Captura de pantalla 2026-10-20 225948" src="https://github.com/user-attachments/assets/3b982d35-2459-4d9b-bb33-2e57676ba604" />


## Conclusión

Argo CD quedó instalado en el namespace `argocd-jarm`, expuesto con Traefik en `argocd.jarm.local`, y conectado al repositorio de GitHub. Las dos Applications despliegan los manifiestos del repositorio en `parcial-jarm`, y un cambio hecho solo en Git (réplicas de 1 a 3) se reflejó automáticamente en el clúster, que es el principio de GitOps.
