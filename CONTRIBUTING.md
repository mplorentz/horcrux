WIP 
Install uvx `curl -LsSf https://astral.sh/uv/install.sh | sh`
Install spec-kit
Install Nostrbook MCP
Install flutter

## Code Generation with Freezed

This project uses [Freezed](https://pub.dev/packages/freezed) for generating immutable data classes with value equality, `copyWith` methods, and more.

### When to Use Freezed

Use Freezed for model classes that:
- Need value equality (deep comparison of all properties)
- Are immutable (use `copyWith` for updates)
- Are used with Riverpod providers (ensures proper change detection)

### Running Code Generation

After modifying any `@freezed` class or `@GenerateMocks` annotation, run code generation:

**Using VS Code:**
- Press `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows/Linux)
- Type "Tasks: Run Task"
- Select "Codegen"

**Using Command Line:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### What Gets Generated

- **Freezed models**: `.freezed.dart` files containing `==`, `hashCode`, `copyWith`, `toString`
- **Mockito mocks**: `.mocks.dart` files containing mock implementations for testing

### Important Notes

- Always run codegen after modifying `@freezed` classes or `@GenerateMocks` annotations
- Generated files should be committed to git (they're part of the codebase)
- If you see "The getter 'copyWith' isn't defined", run codegen
- Use `--delete-conflicting-outputs` flag to avoid manual cleanup