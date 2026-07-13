{
  lib,
  python3Packages,
  src,
}:

python3Packages.buildPythonApplication {
  pname = "echovault";
  version = "0.4.0";

  inherit src;

  pyproject = true;

  build-system = with python3Packages; [
    setuptools
  ];

  dependencies = with python3Packages; [
    click
    pyyaml
    sqlite-vec
    httpx
    mcp
  ];

  # В nixpkgs sqlite-vec рабочий, но wheel сообщает версию 0.0.0.
  # Ослабляем только проверку версии, сам пакет остаётся зависимостью.
  pythonRelaxDeps = [
    "sqlite-vec"
  ];

  # EchoVault умеет использовать встроенный sqlite3,
  # если pysqlite3 отсутствует.
  pythonRemoveDeps = [
    "pysqlite3"
  ];

  doCheck = false;

  pythonImportsCheck = [
    "memory"
  ];

  meta = {
    description = "Local-first persistent memory for coding agents";
    homepage = "https://github.com/mraza007/echovault";
    license = lib.licenses.mit;
    mainProgram = "memory";
    platforms = lib.platforms.linux;
  };
}