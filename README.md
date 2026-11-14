# Laboratorio S11 S12 — Gestión de alumnos con Cupertino

Adaptación del laboratorio de semanas 7 y 8 de Rony Bellido Chambi, Sección A, Tecsup, periodo 2026-II. Docente: Hugo Felipe Torrico Marquez.

Se conserva el registro de alumnos y sus notas, el perfil docente y el almacenamiento local. La interfaz utiliza los widgets oficiales de `package:flutter/cupertino.dart`.

## Acceso de demostración

- Correo: `rony@gmail.com`
- Contraseña: `123`

La autenticación es local y de demostración, sin servidor. La recuperación solo muestra el acceso demo.

## Correspondencia con la consigna

| Contenido | Implementación S11 S12 |
|---|---|
| Cinco pantallas originales | Login, Menú, Alumnos, Registrar Alumno y Perfil |
| ListViews | ListView y ListView.builder en menú, formularios y alumnos |
| ListTiles | CupertinoListTile para opciones, alumnos y perfil |
| Listas y mapas | List<Map<String, dynamic>> para alumnos y Map para perfil |
| Rutas | CupertinoPageRoute y rutas con control de sesión |
| Tema global | CupertinoApp y CupertinoThemeData, color morado compartido |
| Cards | Tarjeta con Container redondeado, equivalente visual sin Material Card |
| Formularios | CupertinoTextFormFieldRow y CupertinoButton |
| Alertas y opciones | CupertinoAlertDialog y CupertinoActionSheet |
| Búsqueda | CupertinoSearchTextField |

El menú lateral Material se reemplaza por el menú de opciones y la navegación de regreso de iOS.

## Funciones conservadas

- Altas, búsqueda por nombre o apellido, edición y eliminación con confirmación.
- Nombre y apellido obligatorios; nota finita entre 0 y 20, con punto o coma decimal.
- Aprobación desde 11.
- Edición de nombre y teléfono de nueve dígitos del docente.
- Foto seleccionada con image_picker, limitada a 500 KB y almacenada en base64.
- Alumnos y perfil persistidos con shared_preferences; la sesión termina al cerrar la app.
- Logout limpia el historial de navegación.

## Ejecutar en VS Code o navegador

```powershell
flutter pub get
flutter run -d chrome --web-port 7357
```

En VS Code: F5 y seleccionar S11 S12 Cupertino. El puerto fijo conserva el origen del almacenamiento web. Los perfiles temporales de Chrome pueden eliminar sus datos al cerrar el navegador.

## Ejecutar en iOS

En un Mac con Flutter, Xcode y sus herramientas configuradas, conectar un iPhone o iniciar un simulador:

```bash
flutter pub get
flutter devices
flutter run -d <identificador-ios>
```

Para un iPhone físico se debe configurar la firma del proyecto Runner en Xcode con el equipo de desarrollo correspondiente. Info.plist incluye la descripción de acceso a fotos. La interfaz Cupertino puede probarse en Windows mediante Chrome; eso no verifica una compilación nativa de iOS.

## Comprobación

```bash
flutter analyze
flutter test
```

Las pruebas cubren credenciales, cierre de sesión, validación de notas, registro, búsqueda, edición, eliminación, persistencia y edición del perfil. La selección real de fotos y la compilación iOS requieren verificación manual en el dispositivo.

## Capturas para el informe

1. Iniciar Sesión.
2. Menú con las cuatro opciones.
3. Alumnos con notas y condición académica.
4. Registrar Alumno con los campos completos.
5. Perfil del docente.

Los comentarios EXTRA explican el guardado JSON, actualización por ChangeNotifier, validación decimal y avatar base64.

## Base del trabajo

https://github.com/aleyto123/semana_7_y_8_Bellido.git

Repositorio de la entrega S11 S12: https://github.com/aleyto123/labxy

El documento editable para las evidencias está en informes/lab1112.docx. Reemplaza los recuadros por tus capturas y completa los resultados antes de entregar.
