{
  lib,
  fetchFromGitHub,
  python3Packages,
}:
python3Packages.buildPythonApplication {
  pname = "slills-ref";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "agentskills";
    repo = "agentskills";
    rev = "2d3e01f590f68bee2cb76a3200823e93b2cc9eaa";
    hash = "sha256-ulh77OnTtEP2zEIw9wvuajh89Okg8ekI/7OE7ZKQ1Uk=";
  };

  sourceRoot = "source/skills-ref";

  pyproject = true;

  build-system = [python3Packages.hatchling];

  dependencies = with python3Packages; [
    click
    strictyaml
  ];

  pythonImportsCheck = ["skills_ref"];
  doCheck = false;

  meta = {
    description = "CLI tool for validating and converting Agent Skill definitions for Claude agents";
    homepage = "https://github.com/agentskills/agentskills";
    license = lib.licenses.asl20;
    mainProgram = "skills-ref";
  };
}
