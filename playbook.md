# Playbook de Revisión de Pull Requests

Guía de referencia para que cualquier miembro del equipo revise Pull Requests con los mismos criterios. Cada punto incluye **qué revisar**, **por qué importa** y, cuando aporta, la **mejor solución** con ejemplo. Los ejemplos están en TypeScript/React y Python, pero los principios aplican a cualquier lenguaje.

> Cómo usarlo: no es un checklist para marcar mecánicamente. Lo primero es que el código sea correcto y legible; el resto son mejoras. Si un comentario no cambia el comportamiento ni la mantenibilidad, márcalo como *nit* (opcional) para no bloquear el merge.

---

## 1. Constantes y valores literales

### 1.1 No números mágicos
Todo número literal debe tener un nombre que explique para qué sirve. Un `86400` no dice nada; `SECONDS_IN_A_DAY` sí.

```ts
// ❌ Mal
if (retries > 3) { ... }
setTimeout(fn, 300000);

// ✅ Bien
const MAX_RETRIES = 3;
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 min, expresado de forma legible

if (retries > MAX_RETRIES) { ... }
setTimeout(fn, CACHE_TTL_MS);
```
Aplica también a strings "mágicos" (`"admin"`, `"PENDING"`, rutas, claves).

### 1.2 Dato repetido → variable / constante
Si un mismo valor aparece dos o más veces, extráelo. Evita el bug clásico de "lo cambié en un sitio pero no en el otro".

```ts
// ❌ Mal
fetch(`https://api.acme.com/v1/users`);
fetch(`https://api.acme.com/v1/invoices`);

// ✅ Bien
const API_BASE = "https://api.acme.com/v1";
fetch(`${API_BASE}/users`);
fetch(`${API_BASE}/invoices`);
```

### 1.3 Strings que se comparan mucho → enums
Si comparas repetidamente contra un mismo conjunto de strings, conviértelo en enum o union type. Ganas autocompletado, evitas typos silenciosos y el compilador te avisa de casos no contemplados.

```ts
// ❌ Mal
if (status === "pending") ...
if (status === "aproved") ... // typo que compila igual

// ✅ Bien
enum InvoiceStatus {
  Pending = "PENDING",
  Approved = "APPROVED",
  Rejected = "REJECTED",
}
if (status === InvoiceStatus.Pending) ...
```
En TypeScript, un `type Status = "PENDING" | "APPROVED"` suele ser preferible al `enum` (más ligero, sin runtime). Elige según convención del proyecto, pero sé consistente.

---

## 2. Funciones

### 2.1 No funciones duplicadas / procedimiento repetido → extraer
Si el mismo bloque lógico aparece más de una vez (regla práctica: **la tercera vez que copias, extrae**), muévelo a una función con nombre claro. Aplica DRY, pero sin sobre-abstraer: dos trozos que *parecen* iguales pero cambian por razones distintas deben seguir separados.

### 2.2 Funciones puras siempre que se pueda
Prefiere funciones sin efectos secundarios: misma entrada → misma salida, sin mutar argumentos ni estado global. Son triviales de testear y razonar. Aísla los efectos (I/O, red, fecha actual, aleatoriedad) en los bordes.

```ts
// ❌ Impura: muta el argumento y depende de Date.now()
function addTimestamp(order) {
  order.createdAt = Date.now();
  return order;
}

// ✅ Pura: no muta, la dependencia entra por parámetro
function withTimestamp(order: Order, now: number): Order {
  return { ...order, createdAt: now };
}
```

### 2.3 El tipo de retorno debe coincidir con la firma
Lo que promete el encabezado debe ser lo que devuelve **en todos los caminos**. Declara el tipo de retorno explícitamente para que el compilador lo verifique y no infiera algo distinto (p. ej. un `undefined` colado en una rama).

```ts
// ❌ Firma dice number, pero hay un camino que devuelve undefined
function total(items: Item[]): number {
  if (!items.length) return; // undefined
  return items.reduce((a, i) => a + i.price, 0);
}

// ✅
function total(items: Item[]): number {
  if (!items.length) return 0;
  return items.reduce((a, i) => a + i.price, 0);
}
```

### 2.4 Nombres claros de funciones y clases
El nombre debe describir *qué hace y qué devuelve*. Convenciones útiles:
- Verbo + sustantivo: `getInvoices`, `calculateTax`, `sendEmail`.
- Coherencia entre pares que devuelven distintas cosas: usa `getInvoices` si devuelve una colección completa; reserva otros verbos (`fetch`, `find`, `search`) para semánticas distintas. Lo importante es **un verbo consistente por tipo de operación en todo el repo**.
- Booleanos con prefijo de pregunta: `isActive`, `hasPermission`, `shouldRetry`.
- Sin abreviaturas ambiguas (`calc`, `proc`, `tmp`) salvo las universalmente aceptadas (`id`, `url`).

### 2.5 Baja complejidad ciclomática / menos `if` anidados
Muchos `if`/`else` anidados hacen el código difícil de seguir y testear. Técnicas de mejora, en orden de preferencia:

**a) Guard clauses (early return)** — aplana la anidación:
```ts
// ❌ Mal
function process(user) {
  if (user) {
    if (user.isActive) {
      if (user.hasCredit) {
        return doWork(user);
      }
    }
  }
  return null;
}

// ✅ Bien
function process(user: User): Result | null {
  if (!user) return null;
  if (!user.isActive) return null;
  if (!user.hasCredit) return null;
  return doWork(user);
}
```

**b) Extraer la condición o el cuerpo a funciones con nombre** cuando la lógica crece.

**c) Sustituir cadenas de `if/else if` sobre un mismo valor por un mapa/objeto de despacho:**
```ts
// ❌ Mal
function label(status) {
  if (status === "PENDING") return "Pendiente";
  else if (status === "APPROVED") return "Aprobado";
  else if (status === "REJECTED") return "Rechazado";
  else return "Desconocido";
}

// ✅ Bien
const STATUS_LABELS: Record<InvoiceStatus, string> = {
  [InvoiceStatus.Pending]: "Pendiente",
  [InvoiceStatus.Approved]: "Aprobado",
  [InvoiceStatus.Rejected]: "Rechazado",
};
const label = (s: InvoiceStatus) => STATUS_LABELS[s] ?? "Desconocido";
```

---

## 3. DRY aplicado a validaciones

Cuando hay que validar varios campos con la misma mecánica (parsear y, si falla, devolver un error), evita repetir un `if` por cada campo. Un patrón limpio es describir las validaciones como datos (una tabla de reglas) y recorrerlas con una **función pura reutilizable** que devuelve `null` cuando todo es válido (contrato explícito), en lugar de dejar el bucle suelto dentro del handler.

```ts
type Parser<T> = (value: unknown) => T | null;

interface ValidationRule {
  value: unknown;
  parser: Parser<unknown>;
  error: ErrorKey;
}

/**
 * Devuelve la clave del primer error encontrado, o null si todo es válido.
 * Pura: no lanza, no muta, no depende de estado externo.
 */
function firstValidationError(rules: readonly ValidationRule[]): ErrorKey | null {
  for (const { value, parser, error } of rules) {
    if (parser(value) === null) {
      return error;
    }
  }
  return null;
}

// Uso
const rules: readonly ValidationRule[] = [
  { value: values.idLicense,       parser: parsePositiveInteger, error: ID_LICENSE_INVALID_ERROR_KEY },
  { value: values.invoiceValue,    parser: parsePositiveNumber,  error: INVOICE_VALUE_INVALID_ERROR_KEY },
  { value: values.licenseQuantity, parser: parsePositiveInteger, error: LICENSE_QUANTITY_INVALID_ERROR_KEY },
];

const error = firstValidationError(rules);
if (error) return error;
```
Ventajas del patrón: la lógica del bucle es reutilizable y testeable de forma aislada, el contrato de retorno es explícito (`ErrorKey | null`), y el array es `readonly` para reforzar que no se muta. Si en el futuro se necesitan **todos** los errores en vez del primero, solo se cambia esta función (`rules.filter(...)`), no cada handler.

---

## 4. Normalización y helpers pequeños

Un helper de normalización como el siguiente es correcto, pero debe vivir en un módulo de utilidades compartido (no redefinido en cada archivo) y estar cubierto por tests.

```ts
/** Recorta espacios y convierte null/undefined en cadena vacía. Pura. */
export function normalizeString(value: string | null | undefined): string {
  return value?.trim() ?? "";
}
```
Se usa `?.` + `??` para el mismo comportamiento con menos ramas. Ojo: esto trata `""` y espacios como cadena vacía, pero **no** colapsa `"a   b"` internamente; si necesitas eso, documéntalo o crea un helper aparte (`collapseWhitespace`) en vez de sobrecargar este.

---

## 5. Convenciones de nombres (consistencia)

Cada tipo de identificador tiene una convención habitual. Lo importante es usar **una sola por cada capa** y respetarla en todo el proyecto. Los tres casos más comunes:

**camelCase** — variables, funciones, propiedades y parámetros en JavaScript/TypeScript, Java, C#, etc.
```ts
const invoiceTotal = 0;
function calculateInvoiceTotal() { ... }
const user = { firstName: "Ana", isActive: true };
```

**snake_case** — variables y funciones en Python, Ruby; y casi siempre columnas y tablas de base de datos (SQL).
```python
invoice_total = 0
def calculate_invoice_total(): ...
```
```sql
SELECT first_name, is_active FROM app_users WHERE person_id = 1;
```

**kebab-case** — nombres de ficheros/carpetas, rutas de URL, clases CSS, atributos HTML y a veces claves de configuración.
```
components/invoice-summary.tsx
GET /api/v1/person-invoices
<button data-invoice-id="42" class="invoice-summary__row">
```

Además del formato, cuida el **orden natural** en identificadores compuestos: el calificador va después del sustantivo. Por ejemplo `person-id` en vez de `id-person`, o `personId` en vez de `idPerson`. Aplicando esto, un `bulk-idPerson` debería renombrarse a `bulk-person-id`.

Regla final: si se cambia una convención, hay que cambiarla en todo el alcance del PR; no dejar el repositorio a medias.

---

## 6. React

### 6.1 `key` en listas: id único, nunca el índice
Usar el índice del `.map` como `key` provoca bugs de reconciliación (estado que "salta" de fila al reordenar, insertar o borrar) y renders incorrectos.

```tsx
// ❌ Mal
{items.map((item, index) => <Row key={index} {...item} />)}

// ✅ Bien
{items.map((item) => <Row key={item.id} {...item} />)}
```
Solo es aceptable el índice si la lista es **estática, nunca se reordena y no tiene estado propio** por fila.

### 6.2 Otras buenas prácticas de React
- No definir componentes ni funciones pesadas dentro del cuerpo del render sin `useCallback`/`useMemo` cuando afecte a hijos memoizados.
- Arrays de dependencias de hooks completos y correctos (respeta la regla del linter, no lo silencies sin justificar).
- Accesibilidad básica: labels en inputs, `alt` en imágenes, roles/aria donde toque, foco manejable por teclado.

---

## 7. Otros aspectos recomendados (lo que suele faltar)

### 7.1 Manejo de errores

**No silenciar errores.** "Capturar un error y no hacer nada con él" (a veces llamado *tragar* o *swallow* la excepción) significa atraparlo en un `catch` vacío. El programa sigue como si nada, pero el fallo real queda oculto y luego es imposible de depurar. Ante un error hay que hacer una de dos cosas: **registrarlo** (log) con contexto, o **propagarlo** para que lo maneje quien pueda.

```ts
// ❌ Mal: el error desaparece sin dejar rastro
try {
  await saveInvoice(invoice);
} catch (e) {
  // vacío: si falla, nadie se entera
}

// ✅ Bien: se registra con contexto y se propaga
try {
  await saveInvoice(invoice);
} catch (error) {
  logger.error(`No se pudo guardar la factura ${invoice.id}`, error);
  throw error; // o devolver un resultado de error controlado
}
```

**Mensajes de error accionables.** El mensaje debe decir *qué* falló y, cuando se sepa, *qué hacer* al respecto. Un mensaje genérico obliga a quien lo lee a adivinar.

```ts
// ❌ Mal: no dice qué campo ni qué se esperaba
throw new Error("Datos inválidos");

// ✅ Bien: identifica el dato y la condición esperada
throw new Error(`El campo 'edad' debe ser un entero positivo, se recibió: "${age}"`);
```

**No exponer detalles internos al cliente.** El *stack trace* (la traza técnica del error) y datos sensibles (rutas del servidor, consultas SQL, tokens) sirven para depurar en los logs internos, pero al usuario final solo se le devuelve un mensaje seguro y neutro.

```ts
// ❌ Mal: filtra internals al usuario
catch (error) {
  res.status(500).send(error.stack);
}

// ✅ Bien: detalle al log interno, mensaje genérico al cliente
catch (error) {
  logger.error("Error al procesar el pago", error);
  res.status(500).send({ message: "No se pudo procesar el pago. Inténtalo de nuevo." });
}
```

### 7.2 Inmutabilidad
- Prefiere `const`; evita mutar parámetros y arrays/objetos compartidos. Usa copias (`{...obj}`, `[...arr]`, `map`/`filter`) sobre mutación in-place. Conecta con 2.2 (pureza).

### 7.3 Single Responsibility
- Una función/clase, una razón para cambiar. Si el nombre necesita un "y" (`validateAndSave`), probablemente son dos funciones.

### 7.4 Seguridad
- Validar y sanear toda entrada externa (no confiar en el cliente).
- Nada de secretos/tokens/credenciales hardcodeados ni en logs.
- Consultas parametrizadas (evitar SQL injection); escape de salida (XSS).
- Revisar dependencias nuevas (licencia, mantenimiento, vulnerabilidades).

### 7.5 Async / concurrencia
- Toda promesa debe esperarse (`await`) o manejarse; una "promesa colgada" es una operación async que se lanza pero cuyo resultado (o error) nadie recoge.
- Manejo de errores en código async (try/catch o `.catch`).
- Si varias operaciones independientes se pueden lanzar a la vez, no las encadenes con `await` una tras otra dentro de un bucle: paralelízalas con `Promise.all`.

```ts
// ❌ Mal: promesa colgada (nadie espera ni captura su error)
saveInvoice(invoice); // sin await

// ❌ Lento: espera secuencial de operaciones independientes
for (const id of ids) {
  await sendEmail(id);
}

// ✅ Bien: se espera y se maneja el error
try {
  await saveInvoice(invoice);
} catch (error) {
  logger.error(`Fallo al guardar la factura ${invoice.id}`, error);
}

// ✅ Bien: operaciones independientes en paralelo
await Promise.all(ids.map((id) => sendEmail(id)));
```

### 7.6 Tipado
- Evita `any`; usa `unknown` + narrowing cuando el tipo no se conoce.
- Tipos explícitos en las fronteras públicas (params y retorno de funciones exportadas).

### 7.7 Comentarios y código muerto
- Comentarios que expliquen el **porqué**, no el **qué** (el qué lo dice el código).
- Elimina código comentado, imports sin usar, `console.log` de depuración y features flags obsoletas.

### 7.8 Documentación
- Actualiza README / docs / CHANGELOG si el PR cambia comportamiento público, config o API.

---

## 8. Tests

### 8.1 Fixtures y comparación por longitud
- Usa fixtures/factories para los datos de prueba en vez de construir objetos a mano en cada test (menos duplicación, más legible).
- Cuando validas colecciones, compara contra el `len`/`length` del resultado esperado además del contenido, para detectar de más y de menos.

```python
# Ejemplo (pytest)
from app.enums import InvoiceStatus  # el estado es un enum, no un string suelto

APPROVED_COUNT = 2
PENDING_COUNT = 1

@pytest.fixture
def invoices():
    # Composición conocida a partir de constantes con nombre (una sola fuente de verdad)
    return (
        [make_invoice(status=InvoiceStatus.APPROVED) for _ in range(APPROVED_COUNT)]
        + [make_invoice(status=InvoiceStatus.PENDING) for _ in range(PENDING_COUNT)]
    )

def test_get_approved_invoices_returns_only_approved(invoices):
    result = get_approved_invoices(invoices)

    assert len(result) == APPROVED_COUNT                                   # tamaño esperado
    assert all(inv.status == InvoiceStatus.APPROVED for inv in result)     # todas cumplen el filtro
    assert len(result) < len(invoices)                                     # se descartó al menos una
```
Detalles del ejemplo: el estado se compara contra el enum `InvoiceStatus.APPROVED`, no contra el string `"APPROVED"` (evita typos y sigue la regla 1.3). El tamaño esperado sale de las constantes que definen el fixture (`APPROVED_COUNT`), así que no hay un literal suelto que pueda quedar desincronizado si alguien edita el fixture. Y se comprueba la longitud por partida doble: contra el valor esperado y contra `len(invoices)`, para confirmar que el filtro descartó las que no correspondían y no dejó pasar de más.

### 8.2 Calidad de los tests
- Cubre **casos límite y de error**, no solo el happy path (vacío, null, límites, entradas inválidas).
- Un test = un comportamiento; nombres descriptivos (`test_devuelve_vacio_cuando_no_hay_facturas`).
- Tests deterministas: sin dependencia de fecha real, red o orden de ejecución (mockea el reloj/red).
- Los tests deben fallar por la razón correcta: si comentas la lógica de producción, el test debe romperse.
- **Compara contra una verdad conocida de forma independiente, no contra la propia lógica que pruebas.** Si el valor esperado se calcula re-implementando la función bajo prueba (p. ej. `expected = len([i for i in invoices if i.status == APPROVED])` para probar `get_approved_invoices`), el test se vuelve tautológico: pasaría aunque la función estuviera mal. El esperado debe venir de datos fijados de antemano (constantes del fixture), no de aplicar el mismo filtro.

---

## 9. Buenas prácticas del propio PR

- **PR pequeño y con un solo propósito**: más fácil de revisar, menos bugs. Separa refactors de cambios de comportamiento.
- **Descripción clara**: qué, por qué y cómo probarlo. Enlaza el ticket.
- **CI en verde**: lint, tipos, tests y build pasan antes de pedir review.
- **Un solo tema por PR**: no mezcles cambios ajenos al objetivo del PR, como reformatear archivos enteros o renombrar cosas "de paso". Si ese formateo o renombrado hace falta, hazlo en un PR aparte. Motivo: cuando el diff mezcla 3 líneas del cambio real con 200 de reformateo automático, el revisor no distingue lo importante y es fácil que se cuele un bug. La regla no es "no subir esos cambios", sino "subirlos por separado".
- **Autorevisión previa**: lee tu propio diff antes de asignar revisores.

---

## Resumen rápido (checklist)

| # | Criterio | Regla |
|---|----------|-------|
| 1 | Números/strings mágicos | Nombrar como constante |
| 2 | Dato repetido | Extraer a variable |
| 3 | Strings comparados | Enum / union type |
| 4 | Duplicación | DRY: extraer función (a la 3ª copia) |
| 5 | Pureza | Sin efectos secundarios cuando se pueda |
| 6 | Retorno | Coincide con la firma en todos los caminos |
| 7 | Nombres | Claros, verbo+sustantivo, consistentes |
| 8 | Complejidad | Guard clauses, extraer, mapas de despacho |
| 9 | Convención de nombres | Una sola por capa, respetarla |
| 10 | React keys | `id` único, nunca el índice |
| 11 | Errores | No silenciarlos; contexto y seguridad |
| 12 | Inmutabilidad | `const`, no mutar |
| 13 | Seguridad | Validar entrada, sin secretos hardcode |
| 14 | Async | Sin promesas colgadas, manejar errores |
| 15 | Tipado | Sin `any`, tipos en fronteras |
| 16 | Tests | Fixtures + comparar `len` + casos límite |
| 17 | PR | Pequeño, descrito, CI verde |