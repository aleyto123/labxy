// ignore: deprecated_member_use
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:laboratorio_7_8/main.dart';

Future<void> tocar(WidgetTester tester, String texto) async {
  final fila = find.widgetWithText(CupertinoListTile, texto);
  final control = fila.evaluate().length == 1 ? fila : find.text(texto);
  await tester.ensureVisible(control);
  await tester.tap(control);
  await tester.pumpAndSettle();
}

Future<void> entrar(WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.enterText(
    find.byType(CupertinoTextField).at(0),
    'rony@gmail.com',
  );
  await tester.enterText(find.byType(CupertinoTextField).at(1), '123');
  await tocar(tester, 'LOGIN');
  expect(find.text('Menú'), findsOneWidget);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    datos = Datos(await SharedPreferences.getInstance());
  });
  test(
    'Conserva altas, cambios, bajas y perfil al recargar almacenamiento',
    () async {
      final alumno = {
        'id': 'prueba',
        'nombre': 'Rony',
        'apellido': 'Bellido',
        'nota': 10.5,
      };
      await datos.guardarAlumno(alumno);
      await datos.guardarAlumno({...alumno, 'nota': 18.0});
      var recargados = Datos(datos.prefs);
      expect(recargados.alumnos.where((a) => a['id'] == 'prueba').length, 1);
      expect(recargados.alumnos.last['nota'], 18.0);
      await datos.guardarPerfil({
        ...datos.perfil,
        'nombre': 'Rony actualizado',
        'avatar': 'aW1hZ2Vu',
      });
      recargados = Datos(datos.prefs);
      expect(recargados.perfil['nombre'], 'Rony actualizado');
      expect(recargados.perfil['avatar'], 'aW1hZ2Vu');
      await datos.eliminar('prueba');
      expect(Datos(datos.prefs).alumnos.any((a) => a['id'] == 'prueba'), false);
    },
  );
  test('Valida notas límite, decimales, vacíos y números no finitos', () {
    for (final nota in ['0', '20', '10,5', '11.5']) {
      expect(validarNota(nota), isNull);
    }
    for (final nota in ['', '-1', '20.1', 'NaN', 'Infinity', 'texto']) {
      expect(validarNota(nota), isNotNull);
    }
  });
  testWidgets('Rechaza credenciales incorrectas y cierra la sesión', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.enterText(
      find.byType(CupertinoTextField).at(0),
      'rony@gmail.com',
    );
    await tester.enterText(find.byType(CupertinoTextField).at(1), 'incorrecta');
    await tocar(tester, 'LOGIN');
    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    await tocar(tester, 'Aceptar');
    await tester.enterText(find.byType(CupertinoTextField).at(1), '123');
    await tocar(tester, 'LOGIN');
    await tocar(tester, 'Logout');
    await tocar(tester, 'Cancelar');
    expect(datos.sesion, true);
    await tocar(tester, 'Logout');
    await tocar(tester, 'Salir');
    expect(datos.sesion, false);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
  testWidgets(
    'Registra, busca, edita y elimina un alumno con controles Cupertino',
    (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await entrar(tester);
      await tocar(tester, 'Registrar Alumnos');
      await tocar(tester, 'GUARDAR');
      expect(find.text('Campo obligatorio'), findsNWidgets(2));
      final campos = find.byType(CupertinoTextField);
      await tester.enterText(campos.at(0), 'Alumno');
      await tester.enterText(campos.at(1), 'Prueba');
      await tester.enterText(campos.at(2), '21');
      await tocar(tester, 'GUARDAR');
      expect(find.text('Ingresa una nota entre 0 y 20'), findsOneWidget);
      await tester.enterText(campos.at(2), '10,5');
      await tocar(tester, 'GUARDAR');
      await tester.enterText(find.byType(CupertinoTextField), 'Alumno Prueba');
      await tester.pumpAndSettle();
      expect(find.text('Nota: 10.5 · Desaprobado'), findsOneWidget);
      await tocar(tester, 'Alumno Prueba');
      await tocar(tester, 'Editar');
      await tester.enterText(find.byType(CupertinoTextField).at(2), '20');
      await tocar(tester, 'GUARDAR CAMBIOS');
      await tester.enterText(find.byType(CupertinoTextField), 'Alumno Prueba');
      await tester.pumpAndSettle();
      expect(find.text('Nota: 20 · Aprobado'), findsOneWidget);
      await tocar(tester, 'Alumno Prueba');
      await tocar(tester, 'Eliminar');
      await tocar(tester, 'Cancelar');
      expect(
        find.widgetWithText(CupertinoListTile, 'Alumno Prueba'),
        findsOneWidget,
      );
      await tocar(tester, 'Alumno Prueba');
      await tocar(tester, 'Eliminar');
      await tocar(tester, 'Eliminar');
      expect(find.text('No se encontraron alumnos'), findsOneWidget);
    },
  );
  testWidgets('Edita y conserva el perfil', (tester) async {
    await entrar(tester);
    await tocar(tester, 'Perfil');
    await tocar(tester, 'EDITAR PERFIL');
    await tester.enterText(
      find.byType(CupertinoTextField).at(0),
      'Rony editado',
    );
    await tester.enterText(find.byType(CupertinoTextField).at(1), '987654321');
    await tocar(tester, 'GUARDAR CAMBIOS');
    expect(find.text('Rony editado'), findsNWidgets(2));
    expect(Datos(datos.prefs).perfil['telefono'], '987654321');
  });
}
