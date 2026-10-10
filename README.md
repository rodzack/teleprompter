# Teleprompter

App Flutter para leer letras de canciones con desplazamiento automático.

## Funciones

- Importación múltiple de `.docx` y `.txt`; el título se toma del nombre del archivo.
- Biblioteca local con búsqueda y eliminación de canciones.
- Lector a pantalla completa con velocidad y tamaño de letra ajustables.
- Pausa/reanudación y desplazamiento manual con el dedo hacia arriba o abajo.
- Canciones guardadas en el dispositivo.

Los documentos Word antiguos `.doc` se deben abrir en Word o LibreOffice y guardar como `.docx` antes de importarlos.

## Ejecutar

Se requiere Flutter 3.27 o posterior. Desde la raíz del proyecto ejecuta `flutter pub get` y luego `flutter run`.

## Estructura del código

- `lib/app`: configuración y raíz de la aplicación.
- `lib/core/constants`: valores compartidos de configuración.
- `lib/models`: modelo de datos de canción.
- `lib/services`: persistencia local e importación de archivos.
- `lib/screens`: pantallas de biblioteca y lector.
- `lib/widgets`: componentes reutilizables de interfaz.
- `lib/main.dart`: punto de entrada de Flutter.
