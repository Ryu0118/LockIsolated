import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension LockIsolatedMacro {
    static func decodeExpansion(
        of attribute: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) -> ClassDeclSyntax? {
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            context.diagnose(LockIsolatedDiagnostic.requiresClass.diagnose(at: attribute))
            return nil
        }
        return classDecl
    }
}
