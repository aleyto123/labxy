import 'dart:convert';
// Mantiene compatibilidad con el SDK del laboratorio original.
// ignore: deprecated_member_use
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

const morado = Color(0xFF7139BA);
late Datos datos;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  datos = Datos(await SharedPreferences.getInstance());
  runApp(const MyApp());
}

// EXTRA: ChangeNotifier comunica cambios a las pantallas.
// JSON permite guardar listas y mapas como texto.
class Datos extends ChangeNotifier {
  final SharedPreferences prefs;
  bool sesion = false;
  late List<Map<String, dynamic>> alumnos;
  late Map<String, dynamic> perfil;

  Datos(this.prefs) {
    final listaGuardada = prefs.getString('alumnos');
    alumnos = listaGuardada == null
        ? [
            {'id': '1', 'nombre': 'Ana', 'apellido': 'Torres', 'nota': 18.0},
            {'id': '2', 'nombre': 'Luis', 'apellido': 'García', 'nota': 12.0},
            {'id': '3', 'nombre': 'María', 'apellido': 'López', 'nota': 9.0},
            {'id': '4', 'nombre': 'Carlos', 'apellido': 'Ruiz', 'nota': 15.0},
          ]
        : (jsonDecode(listaGuardada) as List)
              .map((a) => Map<String, dynamic>.from(a as Map))
              .toList();

    final perfilGuardado = prefs.getString('perfil');
    perfil = perfilGuardado == null
        ? {
            'nombre': 'Rony Bellido Chambi',
            'email': 'rony@gmail.com',
            'telefono': '912345678',
            'rol': 'Docente',
            'avatar': '',
          }
        : Map<String, dynamic>.from(jsonDecode(perfilGuardado) as Map);
  }

  Future<void> guardarAlumno(Map<String, dynamic> alumno) async {
    final nuevaLista = alumnos
        .map((a) => Map<String, dynamic>.from(a))
        .toList();
    final indice = nuevaLista.indexWhere((a) => a['id'] == alumno['id']);
    if (indice == -1) {
      nuevaLista.add(alumno);
    } else {
      nuevaLista[indice] = alumno;
    }
    if (!await prefs.setString('alumnos', jsonEncode(nuevaLista))) {
      throw Exception('No se pudo guardar');
    }
    alumnos = nuevaLista;
    notifyListeners();
  }

  Future<void> eliminar(String id) async {
    final nuevaLista = alumnos.where((a) => a['id'] != id).toList();
    if (!await prefs.setString('alumnos', jsonEncode(nuevaLista))) {
      throw Exception('No se pudo eliminar');
    }
    alumnos = nuevaLista;
    notifyListeners();
  }

  Future<void> guardarPerfil(Map<String, dynamic> nuevoPerfil) async {
    if (!await prefs.setString('perfil', jsonEncode(nuevoPerfil))) {
      throw Exception('No se pudo guardar el perfil');
    }
    perfil = nuevoPerfil;
    notifyListeners();
  }
}

Future<void> aviso(BuildContext context, String mensaje) =>
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Gestión de alumnos'),
        content: Text(mensaje),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

String? obligatorio(String? valor) =>
    valor == null || valor.trim().isEmpty ? 'Campo obligatorio' : null;
bool correoValido(String valor) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(valor.trim());
String notaTexto(num nota) => nota == nota.roundToDouble()
    ? nota.toInt().toString().padLeft(2, '0')
    : nota.toString();
String? validarNota(String? valor) {
  // EXTRA: admite coma o punto, rechaza valores no finitos y limita la nota.
  final numero = double.tryParse((valor ?? '').trim().replaceAll(',', '.'));
  return numero == null || !numero.isFinite || numero < 0 || numero > 20
      ? 'Ingresa una nota entre 0 y 20'
      : null;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => CupertinoApp(
    title: 'Laboratorio S11 S12',
    debugShowCheckedModeBanner: false,
    theme: const CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: morado,
      scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
      barBackgroundColor: CupertinoColors.systemGroupedBackground,
    ),
    // Conserva las rutas y el control de sesión de las semanas 7 y 8.
    onGenerateRoute: (settings) {
      Widget pantalla;
      if (settings.name == '/' || !datos.sesion) {
        pantalla = const LoginPage();
      } else {
        switch (settings.name) {
          case '/alumnos':
            pantalla = const AlumnosPage();
            break;
          case '/registro':
            pantalla = RegistroPage(
              alumno: settings.arguments as Map<String, dynamic>?,
            );
            break;
          case '/perfil':
            pantalla = const PerfilPage();
            break;
          default:
            pantalla = const MenuPage();
        }
      }
      return CupertinoPageRoute<void>(
        settings: settings,
        builder: (_) => pantalla,
      );
    },
  );
}

// Cupertino no tiene Card: una superficie redondeada cumple la misma función.
class Tarjeta extends StatelessWidget {
  const Tarjeta({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: CupertinoColors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );
}

class Pagina extends StatelessWidget {
  const Pagina({
    super.key,
    required this.titulo,
    required this.child,
    this.accion,
  });
  final String titulo;
  final Widget child;
  final Widget? accion;
  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    navigationBar: CupertinoNavigationBar(
      middle: Text(titulo),
      trailing: accion,
      previousPageTitle: 'Atrás',
    ),
    child: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: child,
        ),
      ),
    ),
  );
}

class Campo extends StatelessWidget {
  const Campo({
    super.key,
    required this.etiqueta,
    required this.controlador,
    this.validator = obligatorio,
    this.teclado,
    this.oculto = false,
    this.suffix,
  });
  final String etiqueta;
  final TextEditingController controlador;
  final String? Function(String?)? validator;
  final TextInputType? teclado;
  final bool oculto;
  final Widget? suffix;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 6),
          child: Text(
            etiqueta,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        Tarjeta(
          child: Row(
            children: [
              Expanded(
                child: CupertinoTextFormFieldRow(
                  controller: controlador,
                  placeholder: etiqueta,
                  validator: validator,
                  keyboardType: teclado,
                  obscureText: oculto,

                  autocorrect: !oculto && teclado != TextInputType.emailAddress,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              if (suffix != null) suffix!,
              const SizedBox(width: 8),
            ],
          ),
        ),
      ],
    ),
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formulario = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  bool ocultar = true;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void ingresar() {
    if (!formulario.currentState!.validate()) return;
    if (email.text.trim().toLowerCase() == 'rony@gmail.com' &&
        password.text == '123') {
      datos.sesion = true;
      Navigator.pushNamedAndRemoveUntil(context, '/menu', (_) => false);
    } else {
      aviso(context, 'Correo o contraseña incorrectos.');
    }
  }

  @override
  Widget build(BuildContext context) => Pagina(
    titulo: 'Sección A',
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 32),
        const Icon(CupertinoIcons.person_3_fill, size: 80, color: morado),
        const SizedBox(height: 22),
        const Text(
          'Iniciar Sesión',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Gestión de alumnos y notas',
          textAlign: TextAlign.center,
          style: TextStyle(color: CupertinoColors.secondaryLabel),
        ),
        const SizedBox(height: 32),
        Form(
          key: formulario,
          child: Column(
            children: [
              Campo(
                etiqueta: 'Email',
                controlador: email,
                teclado: TextInputType.emailAddress,
                validator: (v) =>
                    correoValido(v ?? '') ? null : 'Email no válido',
              ),
              Campo(
                etiqueta: 'Contraseña',
                controlador: password,
                oculto: ocultar,
                suffix: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => setState(() => ocultar = !ocultar),
                  child: Icon(
                    ocultar ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                    semanticLabel: 'Mostrar u ocultar contraseña',
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: ingresar,
                  child: const Text('LOGIN'),
                ),
              ),
              CupertinoButton(
                onPressed: () => aviso(
                  context,
                  'Acceso de demostración local: rony@gmail.com / 123. No se envían correos de recuperación.',
                ),
                child: const Text('¿Olvidaste tu contraseña?'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});
  Future<void> salir(BuildContext context) async {
    final confirmar = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas cerrar tu sesión?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (confirmar == true && context.mounted) {
      datos.sesion = false;
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final opciones = <Map<String, dynamic>>[
      {
        'texto': 'Registrar Alumnos',
        'icono': CupertinoIcons.person_add,
        'ruta': '/registro',
      },
      {
        'texto': 'Listar Alumnos',
        'icono': CupertinoIcons.list_bullet,
        'ruta': '/alumnos',
      },
      {
        'texto': 'Perfil',
        'icono': CupertinoIcons.person_crop_circle,
        'ruta': '/perfil',
      },
      {
        'texto': 'Logout',
        'icono': CupertinoIcons.square_arrow_right,
        'ruta': '/',
      },
    ];
    return Pagina(
      titulo: 'Menú',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Gestión de alumnos',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Laboratorio S11 S12 · Cupertino',
            style: TextStyle(color: CupertinoColors.secondaryLabel),
          ),
          const SizedBox(height: 24),
          ...opciones.map(
            (opcion) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Tarjeta(
                child: CupertinoListTile(
                  padding: const EdgeInsets.all(20),
                  leading: Icon(
                    opcion['icono'] as IconData,
                    color: opcion['ruta'] == '/'
                        ? CupertinoColors.systemRed
                        : morado,
                  ),
                  title: Text(opcion['texto'] as String),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => opcion['ruta'] == '/'
                      ? salir(context)
                      : Navigator.pushNamed(context, opcion['ruta'] as String),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AlumnosPage extends StatefulWidget {
  const AlumnosPage({super.key});
  @override
  State<AlumnosPage> createState() => _AlumnosPageState();
}

class _AlumnosPageState extends State<AlumnosPage> {
  String busqueda = '';
  Future<void> opciones(Map<String, dynamic> alumno) async {
    final accion = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('${alumno['nombre']} ${alumno['apellido']}'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'editar'),
            child: const Text('Editar'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, 'eliminar'),
            child: const Text('Eliminar'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ),
    );
    if (!mounted) return;
    if (accion == 'editar') {
      Navigator.pushNamed(context, '/registro', arguments: alumno);
    }
    if (accion == 'eliminar') {
      final confirmar = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Eliminar alumno'),
          content: Text(
            '¿Eliminar a ${alumno['nombre']} ${alumno['apellido']}?',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
      if (confirmar != true || !mounted) return;
      try {
        await datos.eliminar(alumno['id'] as String);
      } catch (_) {
        if (mounted) aviso(context, 'No se pudo eliminar. Intenta nuevamente.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => Pagina(
    titulo: 'Alumnos',
    accion: CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => Navigator.pushNamed(context, '/registro'),
      child: const Icon(CupertinoIcons.add, semanticLabel: 'Registrar alumno'),
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: CupertinoSearchTextField(
            placeholder: 'Buscar alumno...',
            onChanged: (v) => setState(() => busqueda = v),
          ),
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: datos,
            builder: (context, _) {
              final visibles = datos.alumnos
                  .where(
                    (a) => '${a['nombre']} ${a['apellido']}'
                        .toLowerCase()
                        .contains(busqueda.trim().toLowerCase()),
                  )
                  .toList();
              if (visibles.isEmpty) {
                return Center(
                  child: Text(
                    datos.alumnos.isEmpty
                        ? 'No hay alumnos registrados'
                        : 'No se encontraron alumnos',
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: visibles.length,
                itemBuilder: (context, index) {
                  final alumno = visibles[index];
                  final nota = alumno['nota'] as num;
                  final aprobado = nota >= 11;
                  final color = aprobado
                      ? CupertinoColors.systemGreen
                      : CupertinoColors.systemRed;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Tarjeta(
                      child: CupertinoListTile(
                        padding: const EdgeInsets.all(16),
                        leading: const Icon(
                          CupertinoIcons.person_fill,
                          color: morado,
                        ),
                        title: Text(
                          '${alumno['nombre']} ${alumno['apellido']}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Nota: ${notaTexto(nota)} · ${aprobado ? 'Aprobado' : 'Desaprobado'}',
                            style: TextStyle(color: color),
                          ),
                        ),
                        trailing: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => opciones(alumno),
                          child: Icon(
                            CupertinoIcons.ellipsis,
                            semanticLabel: 'Opciones de ${alumno['nombre']}',
                          ),
                        ),
                        onTap: () => opciones(alumno),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key, this.alumno});
  final Map<String, dynamic>? alumno;
  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final formulario = GlobalKey<FormState>();
  late final nombre = TextEditingController(
    text: widget.alumno?['nombre'] as String?,
  );
  late final apellido = TextEditingController(
    text: widget.alumno?['apellido'] as String?,
  );
  late final nota = TextEditingController(
    text: widget.alumno?['nota']?.toString(),
  );
  bool guardando = false;
  @override
  void dispose() {
    nombre.dispose();
    apellido.dispose();
    nota.dispose();
    super.dispose();
  }

  Future<void> guardar() async {
    if (guardando || !formulario.currentState!.validate()) return;
    setState(() => guardando = true);
    try {
      await datos.guardarAlumno({
        'id':
            widget.alumno?['id'] ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        'nombre': nombre.text.trim(),
        'apellido': apellido.text.trim(),
        'nota': double.parse(nota.text.trim().replaceAll(',', '.')),
      });
      if (!mounted) return;
      Navigator.popUntil(context, ModalRoute.withName('/menu'));
      Navigator.pushNamed(context, '/alumnos');
    } catch (_) {
      if (mounted) {
        setState(() => guardando = false);
        aviso(context, 'No se pudo guardar. Intenta nuevamente.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => Pagina(
    titulo: widget.alumno == null ? 'Registrar Alumno' : 'Editar Alumno',
    child: Form(
      key: formulario,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(CupertinoIcons.person_add, size: 64, color: morado),
          const SizedBox(height: 24),
          Campo(etiqueta: 'Nombre del alumno', controlador: nombre),
          Campo(etiqueta: 'Apellido', controlador: apellido),
          Campo(
            etiqueta: 'Nota (0 - 20)',
            controlador: nota,
            teclado: const TextInputType.numberWithOptions(decimal: true),
            validator: validarNota,
          ),
          const Text(
            'La nota mínima aprobatoria es 11.',
            style: TextStyle(
              color: CupertinoColors.secondaryLabel,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: guardando ? null : guardar,
            child: Text(
              guardando
                  ? 'GUARDANDO...'
                  : widget.alumno == null
                  ? 'GUARDAR'
                  : 'GUARDAR CAMBIOS',
            ),
          ),
        ],
      ),
    ),
  );
}

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});
  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  bool cambiandoAvatar = false;
  Future<void> cambiarAvatar() async {
    if (cambiandoAvatar) return;
    setState(() => cambiandoAvatar = true);
    try {
      final imagen = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 70,
      );
      if (imagen != null) {
        final bytes = await imagen.readAsBytes();
        if (bytes.length > 500000) {
          if (mounted) {
            await aviso(context, 'Elige una imagen menor de 500 KB.');
          }
          return;
        }
        // EXTRA: base64 conserva el avatar junto con los datos locales del perfil.
        await datos.guardarPerfil({
          ...datos.perfil,
          'avatar': base64Encode(bytes),
        });
      }
    } catch (_) {
      if (mounted) await aviso(context, 'No se pudo guardar la imagen.');
    } finally {
      if (mounted) setState(() => cambiandoAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) => Pagina(
    titulo: 'Perfil',
    child: AnimatedBuilder(
      animation: datos,
      builder: (context, _) {
        final perfil = datos.perfil;
        final avatar = perfil['avatar'] as String;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: ClipOval(
                child: Container(
                  width: 110,
                  height: 110,
                  color: const Color(0xFFF0E8FA),
                  child: avatar.isEmpty
                      ? const Icon(
                          CupertinoIcons.person_fill,
                          size: 64,
                          color: morado,
                        )
                      : Image.memory(base64Decode(avatar), fit: BoxFit.cover),
                ),
              ),
            ),
            CupertinoButton(
              onPressed: cambiandoAvatar ? null : cambiarAvatar,
              child: const Text('Cambiar foto'),
            ),
            Text(
              perfil['nombre'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Tarjeta(
              child: Column(
                children: [
                  for (final campo in [
                    ['Nombre', 'nombre', CupertinoIcons.person],
                    ['Email', 'email', CupertinoIcons.mail],
                    ['Teléfono', 'telefono', CupertinoIcons.phone],
                    ['Rol', 'rol', CupertinoIcons.person_crop_rectangle],
                  ])
                    CupertinoListTile(
                      padding: const EdgeInsets.all(16),
                      leading: Icon(campo[2] as IconData, color: morado),
                      title: Text(campo[0] as String),
                      subtitle: Text(perfil[campo[1]] as String),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: () => Navigator.push<void>(
                context,
                CupertinoPageRoute(builder: (_) => const EditarPerfilPage()),
              ),
              child: const Text('EDITAR PERFIL'),
            ),
          ],
        );
      },
    ),
  );
}

class EditarPerfilPage extends StatefulWidget {
  const EditarPerfilPage({super.key});
  @override
  State<EditarPerfilPage> createState() => _EditarPerfilPageState();
}

class _EditarPerfilPageState extends State<EditarPerfilPage> {
  final formulario = GlobalKey<FormState>();
  late final nombre = TextEditingController(
    text: datos.perfil['nombre'] as String,
  );
  late final telefono = TextEditingController(
    text: datos.perfil['telefono'] as String,
  );
  bool guardando = false;
  @override
  void dispose() {
    nombre.dispose();
    telefono.dispose();
    super.dispose();
  }

  Future<void> guardar() async {
    if (guardando || !formulario.currentState!.validate()) return;
    setState(() => guardando = true);
    try {
      await datos.guardarPerfil({
        ...datos.perfil,
        'nombre': nombre.text.trim(),
        'telefono': telefono.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => guardando = false);
        aviso(context, 'No se pudo guardar el perfil.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => Pagina(
    titulo: 'Editar perfil',
    child: Form(
      key: formulario,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Campo(etiqueta: 'Nombre', controlador: nombre),
          Campo(
            etiqueta: 'Teléfono',
            controlador: telefono,
            teclado: TextInputType.phone,
            validator: (v) => RegExp(r'^\d{9}$').hasMatch((v ?? '').trim())
                ? null
                : 'Ingresa un teléfono de 9 dígitos',
          ),
          CupertinoButton.filled(
            onPressed: guardando ? null : guardar,
            child: Text(guardando ? 'GUARDANDO...' : 'GUARDAR CAMBIOS'),
          ),
        ],
      ),
    ),
  );
}
