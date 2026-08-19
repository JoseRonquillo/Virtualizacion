# Tarea HW-03 — Modos de Red en Máquinas Virtuales

José Antonio Ronquillo Meza
**Hostname de la VM:** `Antonio-Ronquillo`
## Configuración del hostname

sudo hostnamectl set-hostname tu-nombre
sudo reboot

<img width="809" height="567" alt="image" src="https://github.com/user-attachments/assets/e7ede393-383c-40ca-8141-a81c05b47bc9" />


## Subred del hipervisor


<img width="811" height="309" alt="image" src="https://github.com/user-attachments/assets/71d5184d-f351-478b-96a2-99ef6fe7bf1f" />


---

## Escenario 1: Bridge + IP por DHCP


<img width="794" height="526" alt="image" src="https://github.com/user-attachments/assets/79c125b4-b624-4aaf-800a-517682de1329" />

<img width="796" height="512" alt="image" src="https://github.com/user-attachments/assets/595de3da-d150-4b3a-adda-e90f7c31c0e4" />


Comandos usados:
```bash
ip a
ping -c 4 google.com
```

---

## Escenario 2: Bridge + IP manual (misma subred)

<img width="794" height="539" alt="image" src="https://github.com/user-attachments/assets/ecc933af-2c00-4d8e-8419-a6597413309c" />

<img width="805" height="539" alt="image" src="https://github.com/user-attachments/assets/a704986f-7235-403e-b3f0-b84d0e4ef00e" />

Comandos usados:
```bash
sudo ip addr add 192.168.0.150/24 dev enpXsY
sudo ip route add default via 192.168.0.1
ping -c 4 google.com
```

---

## Escenario 3: Bridge + IP manual (fuera de la subred del hipervisor)

**IP asignada manualmente:** `10.0.0.50/24`
**Subred del hipervisor:** `192.168.0.0/24`


```bash
sudo ip addr add 10.0.0.50/24 dev enpXsY
sudo ip route add 192.168.0.1/32 dev enpXsY
sudo ip route add default via 192.168.0.1
```

<img width="771" height="546" alt="image" src="https://github.com/user-attachments/assets/ea68697f-d075-4ddc-b593-55403843697b" />

<img width="804" height="541" alt="image" src="https://github.com/user-attachments/assets/ef6b1558-5a97-49f4-9569-f300c233380c" />

