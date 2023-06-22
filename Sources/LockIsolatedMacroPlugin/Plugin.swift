#if canImport(SwiftCompilerPlugin)
import SwiftSyntaxMacros
import SwiftCompilerPlugin

@main
struct LockIsolatedMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        LockIsolatedMacro.self
    ]
}
#endif
