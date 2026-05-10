{ lib }:

rec {
  executableEnvNames = [
    "CAMOUFOX_EXECUTABLE"
    "CAMOUFOX_EXECUTABLE_PATH"
    "CAMOFOX_EXECUTABLE"
    "CAMOFOX_EXECUTABLE_PATH"
  ];

  executableEnvJs = "process.env.CAMOUFOX_EXECUTABLE || process.env.CAMOUFOX_EXECUTABLE_PATH || process.env.CAMOFOX_EXECUTABLE || process.env.CAMOFOX_EXECUTABLE_PATH";

  browserEnvScript = executable: ''
    _camoufox_executable="''${CAMOUFOX_EXECUTABLE:-''${CAMOUFOX_EXECUTABLE_PATH:-''${CAMOFOX_EXECUTABLE:-''${CAMOFOX_EXECUTABLE_PATH:-${executable}}}}}"
    export CAMOUFOX_EXECUTABLE="''${CAMOUFOX_EXECUTABLE:-$_camoufox_executable}"
    export CAMOUFOX_EXECUTABLE_PATH="''${CAMOUFOX_EXECUTABLE_PATH:-$_camoufox_executable}"
    export CAMOFOX_EXECUTABLE="''${CAMOFOX_EXECUTABLE:-$_camoufox_executable}"
    export CAMOFOX_EXECUTABLE_PATH="''${CAMOFOX_EXECUTABLE_PATH:-$_camoufox_executable}"
    unset _camoufox_executable
  '';

  wrapperBrowserArgs =
    browser:
    lib.optionalString (
      browser != null
    ) "--run ${lib.escapeShellArg (browserEnvScript (lib.getExe browser))}";

  patchCamoufoxJs = packageDir: ''
    if [ -f "${packageDir}/dist/pkgman.js" ]; then
      substituteInPlace ${packageDir}/dist/pkgman.js \
        --replace-fail 'export const INSTALL_DIR = userCacheDir("camoufox");' 'export const INSTALL_DIR = userCacheDir("camoufox");
    export function envExecutablePath() {
        const executable = ${executableEnvJs};
        return executable ? path.resolve(executable) : null;
    }
    function envExecutableDir() {
        const executable = envExecutablePath();
        return executable ? path.dirname(executable) : null;
    }' \
        --replace-fail 'export function installedVerStr() {
        return Version.fromPath().fullString;
    }' 'export function installedVerStr() {
        return Version.fromPath(envExecutableDir() ?? INSTALL_DIR).fullString;
    }' \
        --replace-fail 'export function camoufoxPath(downloadIfMissing = true) {
        // Ensure the directory exists and is not empty' 'export function camoufoxPath(downloadIfMissing = true) {
        const executableDir = envExecutableDir();
        if (executableDir) {
            return executableDir;
        }
        // Ensure the directory exists and is not empty' \
        --replace-fail 'export function launchPath() {
        const launchPath = getPath(LAUNCH_FILE[OS_NAME]);' 'export function launchPath() {
        const executable = envExecutablePath();
        if (executable) {
            if (!fs.existsSync(executable)) {
                throw new CamoufoxNotInstalled(`Camoufox executable not found at ''${executable}`);
            }
            return executable;
        }
        const launchPath = getPath(LAUNCH_FILE[OS_NAME]);'

      substituteInPlace ${packageDir}/dist/utils.js \
        --replace-fail 'import { getPath, installedVerStr, launchPath, OS_NAME } from "./pkgman.js";' 'import { envExecutablePath, getPath, installedVerStr, launchPath, OS_NAME } from "./pkgman.js";' \
        --replace-fail 'if (typeof executable_path === "string") {' 'if (!executable_path) {
            executable_path = envExecutablePath();
        }
        if (typeof executable_path === "string") {'

      substituteInPlace ${packageDir}/dist/__main__.js \
        --replace-fail 'import { CamoufoxFetcher, INSTALL_DIR, installedVerStr } from "./pkgman.js";' 'import { CamoufoxFetcher, INSTALL_DIR, envExecutablePath, installedVerStr, launchPath } from "./pkgman.js";' \
        --replace-fail 'program.command("fetch").action(async () => {
        const updater = await CamoufoxUpdate.create();' 'program.command("fetch").action(async () => {
        if (envExecutablePath()) {
            console.error("[camoufox-js] Browser managed by Nix wrapper.");
            return;
        }
        const updater = await CamoufoxUpdate.create();' \
        --replace-fail 'program.command("path").action(() => {
        console.log(INSTALL_DIR);
    });' 'program.command("path").action(() => {
        console.log(envExecutablePath() ?? INSTALL_DIR);
    });'
    fi
  '';
}
