{
  lib,
  fetchFromGitHub,
  buildNpmPackage,
  nodejs,
}:
buildNpmPackage rec {
  pname = "playwright-cli";
  version = "0.1.13";

  src = fetchFromGitHub {
    owner = "microsoft";
    repo = "playwright-cli";
    rev = "3a1bafc8b4e973c72d0364eb5b427d1ce0aa8317";
    hash = "sha256-hHK/GR5Drlt+e0L9kyNmn+ht1PCrVH6WrVbxGB1Wsxg=";
  };

  npmDepsHash = "sha256-Ulp6IttsZcOOA7LaYDpVKkBYbe2j4RFG8lJARWifOSk=";

  inherit nodejs;

  # Skip the playwright-core postinstall browser download; users run
  # `playwright install` once at runtime (browsers land in ~/.cache/ms-playwright).
  PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
  PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "1";

  dontNpmBuild = true;

  passthru.updateScript = ./update.py;

  meta = {
    description = "Playwright CLI for coding agents - browser automation via concise commands";
    homepage = "https://github.com/microsoft/playwright-cli";
    license = lib.licenses.asl20;
    mainProgram = "playwright-cli";
  };
}
