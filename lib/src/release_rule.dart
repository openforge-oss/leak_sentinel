import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' show AnalysisError;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Shared implementation for every "you allocated a resource but never
/// released it inside `dispose()`" rule.
///
/// A concrete rule only supplies:
///  * the [LintCode] to report,
///  * the release method that must be called (e.g. `dispose`, `cancel`),
///  * the set of type names that are considered owned resources.
///
/// Detection is purely syntactic: it reads the field's declared type name and
/// the class's `extends` clause straight from the AST. That keeps the rule
/// resilient across analyzer element-model revisions, at the cost of only
/// seeing fields that carry an explicit type annotation.
abstract class ReleaseRule extends DartLintRule {
  const ReleaseRule({
    required super.code,
    required this.releaseMethod,
    required this.resourceTypes,
  });

  /// The method that must be invoked on the resource, e.g. `dispose`.
  final String releaseMethod;

  /// Type names that this rule treats as an owned resource.
  final Set<String> resourceTypes;

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      if (!_extendsState(node)) return;

      final released = _releasedTargets(node);

      for (final member in node.members) {
        if (member is! FieldDeclaration || member.isStatic) continue;
        final typeName = _typeName(member.fields.type);
        if (typeName == null || !resourceTypes.contains(typeName)) continue;

        for (final variable in member.fields.variables) {
          final name = variable.name.lexeme;
          if (released.contains(name)) continue;
          reporter.atToken(variable.name, code, arguments: [name]);
        }
      }
    });
  }

  @override
  List<Fix> getFixes() => [_AddReleaseCall(releaseMethod)];

  /// Names of fields on which [releaseMethod] is already called anywhere in
  /// the `dispose()` method body.
  Set<String> _releasedTargets(ClassDeclaration node) {
    final dispose = _disposeMethod(node);
    if (dispose == null) return const {};
    final collector = _ReleaseCallCollector(releaseMethod);
    dispose.body.visitChildren(collector);
    return collector.targets;
  }
}

/// The one-click fix: inject `field.<releaseMethod>()` into `dispose()`,
/// creating the method if the class does not override it yet.
class _AddReleaseCall extends DartFix {
  _AddReleaseCall(this.releaseMethod);

  final String releaseMethod;

  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addClassDeclaration((node) {
      final variable = _fieldAtOffset(node, analysisError.offset);
      if (variable == null) return;

      final name = variable.name.lexeme;
      final statement = '$name.$releaseMethod();';
      final dispose = _disposeMethod(node);

      final builder = reporter.createChangeBuilder(
        message: "Release '$name' in dispose()",
        priority: 80,
      );

      builder.addDartFileEdit((edit) {
        final body = dispose?.body;
        if (body is BlockFunctionBody) {
          // Insert just before `super.dispose();` when present, otherwise
          // at the end of the block. Owned resources should be released
          // before the superclass tears the State down.
          final superCall = _superDisposeCall(body.block);
          final offset = superCall?.offset ?? body.block.rightBracket.offset;
          edit.addSimpleInsertion(offset, '$statement\n    ');
        } else {
          // No dispose() override yet — create one.
          edit.addSimpleInsertion(
            node.rightBracket.offset,
            '\n  @override\n  void dispose() {\n'
            '    $statement\n    super.dispose();\n  }\n',
          );
        }
      });
    });
  }
}

// ---------------------------------------------------------------------------
// Shared, element-model-free AST helpers.
// ---------------------------------------------------------------------------

/// True when [node] directly `extends State<...>` — the overwhelmingly common
/// shape for a Flutter `StatefulWidget`'s companion state.
bool _extendsState(ClassDeclaration node) {
  final superclass = node.extendsClause?.superclass;
  return superclass != null && superclass.name2.lexeme == 'State';
}

/// The simple type name of a declared field, or null if it is not an explicit
/// named type (e.g. inferred with `var`/`final` and no annotation).
String? _typeName(TypeAnnotation? type) {
  if (type is NamedType) return type.name2.lexeme;
  return null;
}

MethodDeclaration? _disposeMethod(ClassDeclaration node) {
  for (final member in node.members) {
    if (member is MethodDeclaration && member.name.lexeme == 'dispose') {
      return member;
    }
  }
  return null;
}

VariableDeclaration? _fieldAtOffset(ClassDeclaration node, int offset) {
  for (final member in node.members) {
    if (member is! FieldDeclaration) continue;
    for (final variable in member.fields.variables) {
      if (variable.name.offset == offset) return variable;
    }
  }
  return null;
}

Statement? _superDisposeCall(Block block) {
  for (final statement in block.statements) {
    if (statement is ExpressionStatement) {
      final expression = statement.expression;
      if (expression is MethodInvocation &&
          expression.methodName.name == 'dispose' &&
          expression.target is SuperExpression) {
        return statement;
      }
    }
  }
  return null;
}

/// Collects the names of the identifiers that [methodName] is invoked on.
class _ReleaseCallCollector extends RecursiveAstVisitor<void> {
  _ReleaseCallCollector(this.methodName);

  final String methodName;
  final Set<String> targets = {};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == methodName) {
      final target = node.realTarget;
      if (target is SimpleIdentifier) {
        targets.add(target.name);
      } else if (target is PrefixedIdentifier) {
        targets.add(target.identifier.name);
      } else if (target is PropertyAccess) {
        targets.add(target.propertyName.name);
      }
    }
    super.visitMethodInvocation(node);
  }
}
