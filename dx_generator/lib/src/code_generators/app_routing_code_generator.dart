import 'package:analyzer/dart/element/type.dart';
import 'package:dx_generator/src/code_generators/code_gen_abstract.dart';

import '../dx_route_class_visitor.dart';

class DxAppRoutingGenerator extends CodeGenerator {
  @override
  String generate(List<DxAnnotatedClass> dxAnnonatedClasses) {
    String topLevelCode = '''
$modifyComment

${annotatedClassImports(dxAnnonatedClasses)}
import 'package:flutter/material.dart';

import 'routes.dx.dart';

$routerPackageImport

class DxAppRouting {
  static final DxAppRouting _dxAppRouting = DxAppRouting._internal();

  factory DxAppRouting() => _dxAppRouting;

  DxAppRouting._internal();

  static Route generateAppRoute(RouteSettings routeSettings) {
    routeSettings = DxRouter().currRouteSetting(routeSettings,dxRouteConstructorMap);
    ${_generateSwitchCase(dxAnnonatedClasses)}
   }
 }

 ${_generateMap(dxAnnonatedClasses)}
''';
    return topLevelCode;
  }

  String _generateMap(List<DxAnnotatedClass> dxAnnonatedClasses) {
    StringBuffer mpBuffer = StringBuffer();
    mpBuffer
        .writeln('Map<String, DxRouteConstructor?> dxRouteConstructorMap = {');
    for (int idx = 0; idx < dxAnnonatedClasses.length; idx++) {
      String className = 'Dx${dxAnnonatedClasses[idx].className}';
      String val = dxAnnonatedClasses[idx].params != null &&
              dxAnnonatedClasses[idx].params!.isNotEmpty
          ? '$className.fromEnc'
          : 'null';
      mpBuffer.writeln('$className.path : $val,');
    }
    mpBuffer.writeln('};');
    return mpBuffer.toString();
  }

  String _generateSwitchCase(List<DxAnnotatedClass> dxAnnonatedClasses) {
    StringBuffer switchCaseCodeBuffer = StringBuffer();
    int initialRouteIdx = -1;
    switchCaseCodeBuffer.writeln('switch(routeSettings.name) {');
    for (int idx = 0; idx < dxAnnonatedClasses.length; idx++) {
      if (dxAnnonatedClasses[idx].isInitialRoute) {
        initialRouteIdx = idx;
      }
      switchCaseCodeBuffer
          .writeln('case Dx${dxAnnonatedClasses[idx].className}.path :');
      _generateCaseBlock(dxAnnonatedClasses[idx], switchCaseCodeBuffer);
    }
    if (initialRouteIdx == -1) {
      throw ('Please define a inital route!!!!');
    }
    switchCaseCodeBuffer.writeln('default :');
    _generateCaseBlock(
        dxAnnonatedClasses[initialRouteIdx], switchCaseCodeBuffer);
    switchCaseCodeBuffer.writeln('}');
    return switchCaseCodeBuffer.toString();
  }

  void _generateCaseBlock(
    DxAnnotatedClass annonatedClass,
    StringBuffer switchCaseCodeBuffer,
  ) {
    if (annonatedClass.params!.isEmpty) {
      switchCaseCodeBuffer.writeln('''
      return MaterialPageRoute(
          builder: (_) => const ${annonatedClass.className}(),
          settings: DxRouter().getCurrentRouteSetting(routeSettings),
        );
      ''');
    } else {
      String argumentNameVar =
          '${annonatedClass.className.toLowerCase()}Arguments';
      switchCaseCodeBuffer.writeln('''
      Dx${annonatedClass.className} $argumentNameVar = routeSettings.arguments as Dx${annonatedClass.className};
      return MaterialPageRoute(
          builder: (_) => ${annonatedClass.className}${_getArguments(annonatedClass.params, argumentNameVar)},
          settings: DxRouter().getCurrentRouteSetting(routeSettings),
        );
      ''');
    }
  }

  String? _getArguments(Map<String, DartType>? params, String argumentNameVar) {
    String mpStr = '(';
    params!.forEach((key, value) => mpStr += "$key : $argumentNameVar.$key,");
    return '$mpStr)';
  }
}
