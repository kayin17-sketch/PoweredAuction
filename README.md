# PoweredAuction

Addon para **World of Warcraft 1.12.1 (Turtle WoW)** que escanea la Casa de Subastas y recopila datos de precios y cantidades para su posterior análisis.

## Que hace

PoweredAuction te permite crear una lista de objetos (watchlist) y escanear la Casa de Subastas de forma automatizada para registrar el precio de compra directa (buyout) por unidad y la cantidad disponible de cada objeto. Los datos se almacenan en los SavedVariables del juego y pueden exportarse al dashboard web para visualizar graficos de precios, tendencias y estadisticas.

El objetivo es darte las herramientas para analizar el mercado del servidor Turtle WoW y tomar decisiones informadas sobre compra/venta.

## Como funciona

1. **Watchlist**: Creas una lista de objetos que quieres monitorizar
2. **Escaneo**: El addon consulta la Casa de Subastas por cada objeto de tu lista, iterando todas las paginas de resultados
3. **Registro**: Para cada resultado guarda el precio por unidad (buyout / cantidad), la cantidad disponible y la fecha/hora
4. **Almacenamiento**: Los datos se guardan en `SavedVariables/PoweredAuction.lua`
5. **Exportacion**: Subes ese archivo al dashboard web para ver graficos y estadisticas

### Datos capturados por cada escaneo

| Campo | Descripcion |
|-------|-------------|
| `itemId` | ID unico del objeto en WoW |
| `itemName` | Nombre del objeto |
| `timestamp` | Fecha y hora del escaneo (epoch) |
| `buyout` | Precio de compra directa por unidad (en cobre) |
| `quantity` | Cantidad disponible en la subasta |

### Estructura interna (SavedVariables)

```lua
PoweredAuctionDB = {
  ["watchList"] = { "Stranglekelp", "Iron Ore", "Mithril Bar" },
  ["scanHistory"] = {
    [3820] = {
      ["name"] = "Stranglekelp",
      ["scans"] = {
        { timestamp = 1712000000, buyout = 1500, quantity = 12 },
        { timestamp = 1712086400, buyout = 1800, quantity = 8 },
      }
    }
  }
}
```

## Instalacion

1. Descarga o clona este repositorio
2. Copia toda la carpeta `PoweredAuction` a tu instalacion de WoW:
   ```
   <ruta_turtle_wow>/Interface/AddOns/PoweredAuction/
   ```
3. Inicia el juego y activa el addon en la pantalla de seleccion de personaje

La estructura de archivos debe quedar asi:
```
Interface/AddOns/PoweredAuction/
├── PoweredAuction.toc
├── Core.lua
├── Database.lua
├── Scanner.lua
├── UI.lua
└── UI.xml
```

## Uso

### Comandos de chat

| Comando | Descripcion |
|---------|-------------|
| `/pa` | Abre el panel del addon |
| `/pa show` | Muestra el panel |
| `/pa hide` | Oculta el panel |
| `/pa add <nombre>` | Anade un objeto a la watchlist |
| `/pa remove <nombre>` | Elimina un objeto de la watchlist |
| `/pa list` | Muestra la lista actual de objetos |
| `/pa scan` | Inicia el escaneo de la AH (debe estar abierta) |
| `/pa clear` | Borra todo el historial de escaneos |
| `/pa help` | Muestra la ayuda |

### Panel de interfaz

1. Escribe `/pa` para abrir el panel
2. Escribe el nombre de un objeto en la caja de texto y pulsa "Add" o Enter
3. Tambien puedes **shift-click** un objeto desde tu inventario o el chat para anadirlo
4. Selecciona un objeto en la lista y pulsa "Remove" para eliminarlo
5. Con la Casa de Subastas abierta, pulsa "Scan AH" para iniciar el escaneo
6. El boton muestra el progreso y se convierte en "Cancel" durante el escaneo

### Flujo de escaneo completo

1. Anade los objetos que quieres monitorizar a la watchlist
2. Ve a la Casa de Subastas y abrela
3. Pulsa "Scan AH" en el panel (o escribe `/pa scan`)
4. El addon escanea cada objeto, iterando todas las paginas de resultados
5. Respeta el throttle del servidor (~1 query/segundo) para evitar desconexiones
6. Al finalizar muestra un resumen con los registros procesados
7. Los datos se guardan en disco al cerrar el juego o al hacer `/reload`

### Exportar datos para el dashboard web

El archivo de datos se encuentra en:
```
<rute_turtle_wow>/WTF/Account/<tu_cuenta>/SavedVariables/PoweredAuction.lua
```

Sube este archivo al dashboard web de [PoweredAuctionWeb](https://github.com/) para ver:
- Grafico de precios historicos con media movil de 7 dias
- Grafico de volumen (cantidad en subasta)
- Grafico de rango de precios (min/avg/max diario)
- Tabla de estadisticas completas

## Notas importantes

- Solo compatible con **Turtle WoW (patch 1.12.1)**. No funciona en versiones modernas de WoW.
- Los datos solo se escriben en disco al **cerrar el juego o hacer `/reload`**
- El escaneo respeta el limite de queries del servidor para evitar kicks
- Puedes escanear cuantas veces quieras; los datos se acumulan en el historial
- Los registros duplicados (mismo item + mismo timestamp) se descartan automaticamente
- El precio almacenado es **por unidad** (buyout total / cantidad), no el precio del lote

## Licencia

MIT
