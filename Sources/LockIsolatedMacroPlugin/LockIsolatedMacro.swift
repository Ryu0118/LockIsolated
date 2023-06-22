import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct LockIsolatedMacro: MemberMacro {
    public static func expansion<
        Declaration: DeclGroupSyntax, Context: MacroExpansionContext
    >(
        of node: AttributeSyntax,
        providingMembersOf declaration: Declaration,
        in context: Context
    ) throws -> [DeclSyntax] {
        guard let classDecl = decodeExpansion(
            of: node,
            attachedTo: declaration,
            in: context
        ) else {
            return []
        }

        var declSyntaxes = [DeclSyntax]()

        if !isContainLock(classDecl, in: context) {
            let recursiveLockDecl = recursiveLockDecl()
            declSyntaxes.append(recursiveLockDecl)
        }

        let functionNames = getFunctionNames(classDecl)
        let selectors = getSelectors(functionNames)
        let swizzlingDecl = try swizzlingDecl(selectors)
        let lockThreadDecl = try lockThreadDecl(functionNames)

        declSyntaxes.append(swizzlingDecl)
        declSyntaxes.append(contentsOf: lockThreadDecl)

        return declSyntaxes
    }

    private static func lockThreadDecl(_ functionNames: [String]) throws -> [DeclSyntax] {
        try functionNames.map { name in
            DeclSyntax(
                try FunctionDeclSyntax("@objc dynamic func \(raw: name)LockThread()") {
                    """
                    lock.lock()
                    defer { lock.unlock() }
                    self.\(raw: name)LockThread()
                    """
                }
            )
        }
    }

    private static func swizzlingDecl(_ selectors: String) throws -> DeclSyntax {
        DeclSyntax(
            try FunctionDeclSyntax("static func swizzling()") {
                """
                \(raw: selectors)
                    .forEach { original, swizzled in
                        guard let originalMethod = class_getInstanceMethod(Self.self, original),
                              let swizzledMethod = class_getInstanceMethod(Self.self, swizzled)
                        else { return }

                        method_exchangeImplementations(originalMethod, swizzledMethod)
                    }
                """
            }
        )
    }

    private static func getSelectors(_ functionNames: [String]) -> String {
        functionNames
            .map {
                "(#selector(\($0)), #selector(\($0)LockThread))"
            }
            .joined(separator: ", ")
            .inserting(first: "[", last: "]")
    }

    private static func getFunctionNames(_ classDecl: ClassDeclSyntax) -> [String] {
        classDecl.memberBlock.members
            .compactMap {
                $0.decl.as(FunctionDeclSyntax.self)
            }
            .map(\.functionName)
    }

    private static func isContainLock(
        _ classDecl: ClassDeclSyntax,
        in context: some MacroExpansionContext
    ) -> Bool {
        !classDecl.memberBlock.members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .map {
                (
                    decl: $0,
                    names: $0.bindings
                        .compactMap { $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text }
                )
            }
            .filter { $0.names.contains("lock") }
            .map { variableDecl, _ in
                context.diagnose(LockIsolatedDiagnostic.samePropertyName.diagnose(at: variableDecl))
            }
            .isEmpty
    }

    private static func recursiveLockDecl() -> DeclSyntax {
        DeclSyntax(
            VariableDeclSyntax(
                modifiers: ModifierListSyntax {
                    DeclModifierSyntax(name: "private")
                },
                bindingKeyword: "let",
                bindings: PatternBindingListSyntax {
                    PatternBindingSyntax(
                        pattern: IdentifierPatternSyntax(identifier: "lock"),
                        initializer: InitializerClauseSyntax(
                            equal: .equalToken(),
                            value: FunctionCallExprSyntax(
                                calledExpression: IdentifierExprSyntax(identifier: "NSRecursiveLock"),
                                leftParen: "(",
                                argumentList: [],
                                rightParen: ")"
                            )
                        )
                    )
                }
            )
        )
    }
}

extension LockIsolatedMacro: MemberAttributeMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        guard let funcDecl = member.as(FunctionDeclSyntax.self) else {
            return []
        }

        var attributeSyntaxes = [AttributeSyntax]()

        if !funcDecl.isObjc {
            attributeSyntaxes.append(.objc)
        }

        return attributeSyntaxes
    }
}
